# Supply Chain Security Reference

Image signing, SBOM generation, attestations, provenance, and verification. Covers Cosign/Sigstore, BuildKit attestations, Docker Scout, and policy enforcement.

---

## The Supply Chain Lifecycle

```
Build → Generate SBOM → Sign Image → Attach Attestations → Push
                                                              ↓
Deploy ← Verify Signature ← Verify Provenance ← Check Policy ←
```

Every production image should have:
1. **SBOM** — what's inside (package inventory)
2. **Provenance** — where/when/how it was built
3. **Signature** — cryptographic proof of authenticity
4. **Attestations** — signed statements tying SBOM + provenance to the image digest

---

## Image Signing with Cosign

Cosign (Sigstore project) is the industry standard. Keyless mode is preferred — uses OIDC identity (GitHub, Google, Microsoft), no key management needed.

### Keyless Signing (Recommended for CI/CD)

```bash
# Sign — identity comes from CI OIDC token
cosign sign ghcr.io/myorg/app@sha256:<DIGEST>

# Verify
cosign verify \
  --certificate-identity "https://github.com/myorg/repo/.github/workflows/build.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/myorg/app@sha256:<DIGEST>
```

### Key-Pair Signing (Air-Gapped Environments)

```bash
# Generate key pair
cosign generate-key-pair

# Sign with key
cosign sign --key cosign.key ghcr.io/myorg/app@sha256:<DIGEST>

# Verify with public key
cosign verify --key cosign.pub ghcr.io/myorg/app@sha256:<DIGEST>
```

### GitHub Actions Integration

```yaml
      - name: Sign image with Cosign
        uses: sigstore/cosign-installer@v3

      - name: Sign the image
        env:
          DIGEST: ${{ steps.build.outputs.digest }}
        run: cosign sign --yes ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${DIGEST}
```

BuildKit can also generate provenance and SBOM attestations automatically:

```yaml
      - name: Build and push with attestations
        uses: docker/build-push-action@v6
        with:
          push: true
          sbom: true               # auto-generate SBOM attestation
          provenance: mode=max     # full SLSA provenance
```

---

## SBOM Generation

### At Build Time (Recommended)

```bash
# Generate SBOM with Syft
syft ghcr.io/myorg/app:v1.2.3 -o cyclonedx-json=sbom.cdx.json

# Or SPDX format
syft ghcr.io/myorg/app:v1.2.3 -o spdx-json=sbom.spdx.json

# Docker native SBOM
docker sbom ghcr.io/myorg/app:v1.2.3
```

### Attach as Attestation

```bash
# Sign and attach SBOM as an in-toto attestation
cosign attest --predicate sbom.cdx.json --type cyclonedx \
  ghcr.io/myorg/app@sha256:<DIGEST>

# Verify the attestation
cosign verify-attestation --type cyclonedx \
  ghcr.io/myorg/app@sha256:<DIGEST>
```

### Scan the Attested SBOM

```bash
# Verify SBOM attestation, then scan for CVEs
cosign verify-attestation --key cosign.pub --type cyclonedx \
  ghcr.io/myorg/app@sha256:<DIGEST> | \
  jq -r .payload | base64 -d | jq .predicate | \
  grype
```

---

## Docker Hardened Images — Verification

DHI images come pre-signed with Cosign and include SBOM + provenance attestations.

```bash
# List all attestations on a DHI
docker scout attest list dhi.io/python:3.13

# Verify SBOM attestation
docker scout attest get \
  --predicate-type https://cyclonedx.org/bom \
  --verify \
  dhi.io/python:3.13

# Verify VEX (vulnerability exploitability)
docker scout attest get \
  --predicate-type https://openvex.dev/ns/v0.2.0 \
  --verify \
  dhi.io/python:3.13

# Verify with Cosign directly
cosign verify dhi.io/python:3.13

# View the SBOM
docker scout sbom dhi.io/python:3.13
```

---

## Image Digest Pinning

Tags are mutable — they can be pointed to a different image at any time. Digests are immutable.

```dockerfile
# Mutable (risky)
FROM node:22-slim

# Immutable (safe, reproducible)
FROM node:22-slim@sha256:35531c52ce27b6575d69755c73e65d4468dba93a25f2cfd88b227f63ace435cc
```

### Lock Digests in compose.yaml

```yaml
services:
  app:
    image: ghcr.io/myorg/app@sha256:abc123def456...
```

### Seal Compose with `--resolve-image-digests`

```bash
# Resolve all tags to digests and publish
docker compose --resolve-image-digests config > compose-locked.yaml
```

---

## SLSA Provenance Levels

| Level | Requirement | How to Achieve |
|---|---|---|
| 1 | Build process documented | Dockerfile + build scripts in VCS |
| 2 | Signed provenance, hosted build | GitHub Actions + `provenance: true` |
| 3 | Hardened build platform, non-falsifiable | `provenance: mode=max` + keyless signing |

Docker Hardened Images claim SLSA Build Level 3.

---

## Policy Enforcement

### Docker Scout Policies

```bash
# Check if image meets policy requirements
docker scout policy ghcr.io/myorg/app:v1.2.3

# Available policies:
# - No critical vulnerabilities
# - No high vulnerabilities without fix
# - Base images up to date
# - Supply chain attestations present
# - No copyleft licenses
```

### Admission Control (Kubernetes)

```yaml
# Kyverno policy: only allow signed images
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  rules:
    - name: verify-cosign
      match:
        resources:
          kinds: [Pod]
      verifyImages:
        - imageReferences: ["ghcr.io/myorg/*"]
          attestors:
            - entries:
                - keyless:
                    issuer: "https://token.actions.githubusercontent.com"
                    subject: "https://github.com/myorg/*"
```

---

## Complete Supply Chain Checklist

- [ ] Images signed with Cosign (keyless in CI, key-pair for air-gapped)
- [ ] SBOM generated at build time (CycloneDX or SPDX)
- [ ] SBOM attached as signed attestation
- [ ] Build provenance at SLSA Level 3 (`provenance: mode=max`)
- [ ] Base images from trusted sources (DHI, official, verified publisher)
- [ ] Base image signatures verified before building
- [ ] Production deploys pin to digest, not tag
- [ ] Weekly automated rebuilds to pick up base image patches
- [ ] CVE scan gate in CI (fail on CRITICAL/HIGH)
- [ ] Docker Scout policy evaluation
- [ ] OCI labels for source, revision, created date
- [ ] Docker Content Trust enabled: `DOCKER_CONTENT_TRUST=1`
