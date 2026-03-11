# Password Handling and MFA

## Table of Contents

- [Password Handling](#password-handling)
  - [Argon2id Configuration](#argon2id-configuration-recommended)
  - [Bcrypt Fallback](#bcrypt-fallback)
  - [NIST 800-63B Password Rules](#nist-800-63b-password-rules)
  - [Password Reset Flow](#password-reset-flow)
- [Passkeys / WebAuthn](#passkeys--webauthn)
  - [Registration Flow](#registration-flow)
  - [Authentication Flow](#authentication-flow)
  - [Client-Side](#client-side)
  - [Passkey Best Practices](#passkey-best-practices)
- [MFA / 2FA](#mfa--2fa)
  - [TOTP Setup](#totp-setup)
  - [Backup Codes](#backup-codes)
  - [MFA Method Decision Tree](#mfa-method-decision-tree)

---

## Password Handling

### Argon2id Configuration (Recommended)

Argon2id is the winner of the Password Hashing Competition. It combines resistance to
GPU attacks (memory-hard) and side-channel attacks.

```typescript
// Node.js — argon2 library
import argon2 from 'argon2';

const ARGON2_OPTIONS: argon2.Options = {
  type: argon2.argon2id,         // Argon2id — hybrid (GPU + side-channel resistant)
  memoryCost: 65536,             // 64 MB memory
  timeCost: 3,                   // 3 iterations
  parallelism: 4,                // 4 parallel threads
  hashLength: 32,                // 256-bit output
};

async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, ARGON2_OPTIONS);
}

async function verifyPassword(hash: string, password: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false; // Fail closed — invalid hash format = rejection
  }
}

async function needsRehash(hash: string): Promise<boolean> {
  return argon2.needsRehash(hash, ARGON2_OPTIONS);
}
```

```python
# Python — passlib with argon2
from passlib.hash import argon2

hasher = argon2.using(
    type="ID",              # Argon2id
    memory_cost=65536,      # 64 MB
    time_cost=3,            # 3 iterations
    parallelism=4,          # 4 threads
    digest_size=32,         # 256-bit output
)

hashed = hasher.hash("user_password")
is_valid = hasher.verify("user_password", hashed)

if hasher.needs_update(hashed):
    new_hash = hasher.hash("user_password")
```

### Bcrypt Fallback

```typescript
import bcrypt from 'bcrypt';
const SALT_ROUNDS = 12; // Minimum 10 (OWASP), prefer 12+

const hash = await bcrypt.hash(password, SALT_ROUNDS);
const isValid = await bcrypt.compare(password, hash);
```

> **Note**: Bcrypt has a 72-byte input limit. Longer passwords are silently truncated.
> Pre-hash with SHA-256 if needed: `bcrypt.hash(sha256(password), SALT_ROUNDS)`.

### NIST 800-63B Password Rules

```
Password Policy (NIST 800-63B):
├─ Minimum length: 8 characters (allow up to 64+)
├─ NO complexity rules (no "must include uppercase/number/symbol")
│  └─ Complexity rules produce predictable patterns: Password1!
├─ Check against breach databases (HaveIBeenPwned API)
├─ Block common passwords (dictionary of 100K+ known bad passwords)
├─ NO periodic password rotation (only rotate after breach)
├─ Allow paste in password fields (enables password managers)
└─ Show password strength meter (zxcvbn library)
```

```typescript
// Check password against HaveIBeenPwned using k-anonymity
import crypto from 'crypto';

async function isPasswordPwned(password: string): Promise<boolean> {
  const sha1 = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = sha1.slice(0, 5);
  const suffix = sha1.slice(5);

  const response = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`);
  const text = await response.text();
  return text.split('\n').some(line => line.startsWith(suffix));
}
```

### Password Reset Flow

```
Password Reset (Secure):
├─ 1. User submits email address
│     └─ Always respond "If that email exists, we sent a reset link"
│        (prevent email enumeration)
├─ 2. Generate cryptographically random token
│     ├─ 32 bytes minimum (crypto.randomBytes(32))
│     ├─ Hash token before storing (SHA-256)
│     └─ Set expiry: 1 hour maximum
├─ 3. Send email with one-time link
├─ 4. User clicks link, submits new password
│     ├─ Verify token hash matches stored hash
│     ├─ Check expiry, validate new password
│     └─ Hash new password with Argon2id
├─ 5. Invalidate token after use (one-time only)
├─ 6. Invalidate all existing sessions
└─ 7. Send confirmation email
```

---

## Passkeys / WebAuthn

Passkeys replace passwords with phishing-resistant, public-key cryptography.
The private key never leaves the user's device.

### Registration Flow

```typescript
import {
  generateRegistrationOptions,
  verifyRegistrationResponse,
} from '@simplewebauthn/server';

const RP_NAME = 'My App';
const RP_ID = 'example.com';
const ORIGIN = 'https://example.com';

async function startRegistration(userId: string, userEmail: string) {
  const existingCredentials = await db.credential.findMany({
    where: { userId },
    select: { credentialId: true, transports: true },
  });

  const options = await generateRegistrationOptions({
    rpName: RP_NAME,
    rpID: RP_ID,
    userID: new TextEncoder().encode(userId),
    userName: userEmail,
    attestationType: 'none',
    excludeCredentials: existingCredentials.map(c => ({
      id: c.credentialId, transports: c.transports,
    })),
    authenticatorSelection: {
      residentKey: 'preferred',        // Discoverable credentials (passkeys)
      userVerification: 'preferred',   // Biometric / PIN
    },
  });

  await setSessionChallenge(userId, options.challenge);
  return options;
}

async function finishRegistration(userId: string, response: RegistrationResponseJSON) {
  const expectedChallenge = await getSessionChallenge(userId);
  const verification = await verifyRegistrationResponse({
    response,
    expectedChallenge,
    expectedOrigin: ORIGIN,
    expectedRPID: RP_ID,
  });

  if (verification.verified && verification.registrationInfo) {
    const { credential, credentialDeviceType, credentialBackedUp } = verification.registrationInfo;
    await db.credential.create({
      data: {
        userId,
        credentialId: credential.id,
        publicKey: Buffer.from(credential.publicKey),
        counter: credential.counter,
        transports: response.response.transports ?? [],
        deviceType: credentialDeviceType,
        backedUp: credentialBackedUp,
      },
    });
  }
  return verification.verified;
}
```

### Authentication Flow

```typescript
import {
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from '@simplewebauthn/server';

async function startAuthentication() {
  const options = await generateAuthenticationOptions({
    rpID: RP_ID,
    allowCredentials: [],              // Empty = discoverable credentials (passkey autofill)
    userVerification: 'preferred',
  });
  return options;
}

async function finishAuthentication(response: AuthenticationResponseJSON) {
  const credential = await db.credential.findUnique({ where: { credentialId: response.id } });
  if (!credential) throw new Error('Credential not found');

  const verification = await verifyAuthenticationResponse({
    response,
    expectedChallenge: await getSessionChallenge(credential.userId),
    expectedOrigin: ORIGIN,
    expectedRPID: RP_ID,
    credential: {
      id: credential.credentialId,
      publicKey: credential.publicKey,
      counter: credential.counter,
    },
  });

  if (verification.verified) {
    await db.credential.update({
      where: { credentialId: response.id },
      data: { counter: verification.authenticationInfo.newCounter },
    });
  }
  return { verified: verification.verified, userId: credential.userId };
}
```

### Client-Side

```html
<!-- Conditional UI — browser autofill suggests passkeys -->
<input type="text" name="username" autocomplete="username webauthn" />
```

```typescript
import { startRegistration, startAuthentication } from '@simplewebauthn/browser';

// Registration
const options = await fetch('/api/passkey/register/start').then(r => r.json());
const result = await startRegistration({ optionsJSON: options });
await fetch('/api/passkey/register/finish', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(result),
});

// Authentication
const authOptions = await fetch('/api/passkey/login/start').then(r => r.json());
const authResult = await startAuthentication({ optionsJSON: authOptions });
await fetch('/api/passkey/login/finish', {
  method: 'POST', headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(authResult),
});
```

### Passkey Best Practices

```
Passkey Implementation:
├─ HTTPS is mandatory (WebAuthn requires secure context)
├─ Store: credentialId, publicKey, counter, transports, deviceType
│  └─ NEVER store the private key (it never leaves the device)
├─ Track signCount to detect cloned authenticators
├─ Support multiple passkeys per account (phone + laptop + security key)
├─ Offer passkey creation during: signup, login, post-recovery
├─ Keep password fallback during transition period
├─ Platform authenticators: Touch ID, Face ID, Windows Hello
└─ Roaming authenticators: YubiKey, Titan Security Key
```

---

## MFA / 2FA

### TOTP Setup

```typescript
import { authenticator } from 'otplib';
import QRCode from 'qrcode';

async function setupTOTP(userId: string, userEmail: string) {
  const secret = authenticator.generateSecret();

  await db.user.update({
    where: { id: userId },
    data: { totpSecret: encrypt(secret), totpEnabled: false },
  });

  const otpauthUrl = authenticator.keyuri(userEmail, 'MyApp', secret);
  const qrCodeDataUrl = await QRCode.toDataURL(otpauthUrl);
  return { qrCodeDataUrl, secret };
}

async function verifyTOTPSetup(userId: string, code: string): Promise<boolean> {
  const user = await db.user.findUnique({ where: { id: userId } });
  const secret = decrypt(user.totpSecret);
  const isValid = authenticator.verify({ token: code, secret });

  if (isValid) {
    const backupCodes = await generateBackupCodes(userId);
    await db.user.update({ where: { id: userId }, data: { totpEnabled: true } });
    return true;
  }
  return false;
}

function verifyTOTP(secret: string, code: string): boolean {
  return authenticator.verify({ token: code, secret });
}
```

```python
# Python — pyotp
import pyotp
import qrcode
import io, base64

def setup_mfa(user_email: str) -> dict:
    secret = pyotp.random_base32()
    totp = pyotp.TOTP(secret)
    uri = totp.provisioning_uri(user_email, issuer_name="MyApp")
    img = qrcode.make(uri)
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    qr_b64 = base64.b64encode(buffer.getvalue()).decode()
    return {"secret": secret, "qr_code": f"data:image/png;base64,{qr_b64}"}

def verify_totp(secret: str, code: str) -> bool:
    return pyotp.TOTP(secret).verify(code, valid_window=1)
```

### Backup Codes

```typescript
import crypto from 'crypto';
import bcrypt from 'bcrypt';

async function generateBackupCodes(userId: string): Promise<string[]> {
  const codes: string[] = [];
  const hashedCodes: string[] = [];

  for (let i = 0; i < 10; i++) {
    const code = `${crypto.randomBytes(2).toString('hex')}-${crypto.randomBytes(2).toString('hex')}`;
    codes.push(code);
    hashedCodes.push(await bcrypt.hash(code, 10));
  }

  await db.backupCode.createMany({
    data: hashedCodes.map(hash => ({ userId, codeHash: hash, used: false })),
  });

  return codes; // Show ONCE to the user
}

async function verifyBackupCode(userId: string, code: string): Promise<boolean> {
  const storedCodes = await db.backupCode.findMany({ where: { userId, used: false } });
  for (const stored of storedCodes) {
    if (await bcrypt.compare(code, stored.codeHash)) {
      await db.backupCode.update({ where: { id: stored.id }, data: { used: true, usedAt: new Date() } });
      return true;
    }
  }
  return false;
}
```

### MFA Method Decision Tree

```
Which MFA method?
├─ Highest security (phishing-resistant)?
│  └─ Passkeys / WebAuthn (security keys, platform authenticators)
│     └─ Best for: admin accounts, financial apps
├─ Good security, broad compatibility?
│  └─ TOTP (Google Authenticator, Authy, 1Password)
│     └─ Best for: most applications
├─ User convenience priority?
│  └─ Push notifications (via auth provider)
│     └─ Best for: consumer apps with mobile focus
├─ Fallback / recovery?
│  └─ Backup codes (one-time, hashed, stored securely)
│     └─ ALWAYS provide alongside primary MFA method
└─ Avoid if possible:
   └─ SMS OTP — vulnerable to SIM swap, SS7 attacks
      └─ Only use if no alternative (regulatory requirement)
```
