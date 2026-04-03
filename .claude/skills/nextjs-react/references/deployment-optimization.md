# Deployment & Optimization

## Table of Contents

- [Self-Hosting: Standalone Output](#self-hosting-standalone-output)
- [Multi-Stage Dockerfile](#multi-stage-dockerfile)
- [Environment Variables: Build-Time vs Runtime](#environment-variables-build-time-vs-runtime)
- [Custom ISR Cache Handler (Redis)](#custom-isr-cache-handler-redis)
- [OpenNext for Serverless Self-Hosting](#opennext-for-serverless-self-hosting)
- [Metadata and OG Image Generation](#metadata-and-og-image-generation)
- [Route-Level OG Images](#route-level-og-images)
- [Sitemap and Robots](#sitemap-and-robots)
- [Font Optimization](#font-optimization)
- [Scripts and Third Parties](#scripts-and-third-parties)
- [Problematic Packages](#problematic-packages)
- [Turbopack](#turbopack)

---

## Self-Hosting: Standalone Output

Set `output: 'standalone'` in `next.config.ts` to produce a minimal, self-contained build that includes only the necessary `node_modules`. This dramatically reduces Docker image size.

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone', // Produces .next/standalone with minimal node_modules
};
export default nextConfig;
```

---

## Multi-Stage Dockerfile

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Stage 2: Build the application
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build-time env vars are baked into the bundle
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Stage 3: Production runner
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Required for Docker: listen on all interfaces
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy standalone output
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000

CMD ["node", "server.js"]
```

---

## Environment Variables: Build-Time vs Runtime

| Type | Prefix | Behavior |
|---|---|---|
| Server-only | No prefix (`DATABASE_URL`) | Available at runtime via `process.env` -- can differ per environment |
| Public (browser) | `NEXT_PUBLIC_` | **Inlined at build time** -- baked into JS bundle, cannot change at runtime |
| Docker runtime | `HOSTNAME=0.0.0.0` | Required for Docker to accept external connections |

**Key implication:** `NEXT_PUBLIC_*` variables are replaced at `next build` time. To use different values per environment with a single Docker image, use the App Router and read server-side env vars in Server Components or Route Handlers, then pass values to Client Components as props.

---

## Custom ISR Cache Handler (Redis)

When self-hosting, the default file-system cache is local to each container. For multi-pod deployments (Kubernetes, ECS), you need a shared cache backend like Redis.

```ts
// next.config.ts
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  cacheHandler: require.resolve('./cache-handler.js'),
  cacheMaxMemorySize: 0, // Disable in-memory cache -- use external store only
};
export default nextConfig;
```

```js
// cache-handler.js -- Redis-based ISR cache handler
const { createClient } = require('redis');

const client = createClient({ url: process.env.REDIS_URL });
client.connect();

module.exports = {
  async get(cacheKey) {
    const stored = await client.get(cacheKey);
    if (!stored) return undefined;

    const data = JSON.parse(stored);
    return {
      value: new ReadableStream({
        start(controller) {
          controller.enqueue(Buffer.from(data.value, 'base64'));
          controller.close();
        },
      }),
      tags: data.tags,
      stale: data.stale,
      timestamp: data.timestamp,
      expire: data.expire,
      revalidate: data.revalidate,
    };
  },

  async set(cacheKey, pendingEntry) {
    const entry = await pendingEntry;
    const reader = entry.value.getReader();
    const chunks = [];

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        chunks.push(value);
      }
    } finally {
      reader.releaseLock();
    }

    const data = Buffer.concat(chunks.map((chunk) => Buffer.from(chunk)));

    await client.set(
      cacheKey,
      JSON.stringify({
        value: data.toString('base64'),
        tags: entry.tags,
        stale: entry.stale,
        timestamp: entry.timestamp,
        expire: entry.expire,
        revalidate: entry.revalidate,
      }),
      { EX: entry.expire },
    );
  },

  async refreshTags() {
    // No-op for basic Redis -- implement tag syncing if needed
  },

  async getExpiration() {
    return 0;
  },

  async updateTags() {
    // Implement tag-based invalidation for revalidateTag() support
  },
};
```

---

## OpenNext for Serverless Self-Hosting

[OpenNext](https://open-next.js.org/) adapts Next.js for serverless platforms without Vercel:

- **AWS Lambda** -- deploys Next.js as Lambda functions with CloudFront CDN
- **Cloudflare Workers** -- edge-first deployment
- **SST (Serverless Stack)** -- uses OpenNext under the hood for AWS deployments

OpenNext handles ISR, image optimization, middleware, and other Vercel-specific features in a platform-agnostic way. Consider it when you need serverless but cannot use Vercel.

---

## Metadata and OG Image Generation

### Dynamic Metadata with generateMetadata

```tsx
// app/products/[id]/page.tsx
import type { Metadata } from 'next';

type Props = {
  params: Promise<{ id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = await getProduct(id);

  return {
    title: product.name,
    description: product.description,
    openGraph: {
      title: product.name,
      description: product.description,
      images: [`/api/og?title=${encodeURIComponent(product.name)}`],
    },
    twitter: {
      card: 'summary_large_image',
      title: product.name,
      description: product.description,
    },
  };
}

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = await getProduct(id);
  return <ProductDetail product={product} />;
}
```

### Dynamic OG Images with next/og

```tsx
// app/api/og/route.tsx
import { ImageResponse } from 'next/og';
import type { NextRequest } from 'next/server';

export const runtime = 'edge';

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const title = searchParams.get('title') ?? 'My Site';

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#0a0a0a',
          color: '#fafafa',
          fontFamily: 'Inter, sans-serif',
        }}
      >
        <h1 style={{ fontSize: 64, fontWeight: 700, margin: 0 }}>{title}</h1>
        <p style={{ fontSize: 28, color: '#a1a1aa', marginTop: 16 }}>
          mysite.com
        </p>
      </div>
    ),
    { width: 1200, height: 630 },
  );
}
```

---

## Route-Level OG Images

```tsx
// app/products/[id]/opengraph-image.tsx
// Automatically generates OG image for this route segment
import { ImageResponse } from 'next/og';

export const alt = 'Product image';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function Image({ params }: { params: { id: string } }) {
  const product = await getProduct(params.id);

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#000',
          color: '#fff',
          fontSize: 48,
        }}
      >
        {product.name}
      </div>
    ),
    { ...size },
  );
}
```

**File convention summary:**
- `opengraph-image.tsx` / `opengraph-image.png` -- OG image for route segment
- `twitter-image.tsx` / `twitter-image.png` -- Twitter card image for route segment
- `sitemap.ts` -- sitemap generation
- `robots.ts` -- robots.txt generation
- `manifest.ts` -- PWA manifest

---

## Sitemap and Robots

```tsx
// app/sitemap.ts -- static sitemap
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    { url: 'https://example.com', lastModified: new Date(), changeFrequency: 'yearly', priority: 1 },
    { url: 'https://example.com/about', lastModified: new Date(), changeFrequency: 'monthly', priority: 0.8 },
  ];
}

// app/sitemap.ts -- dynamic sitemap for large sites
export async function generateSitemaps() {
  const products = await getProducts();
  const sitemaps = [];
  for (let i = 0; i < products.length; i += 50000) {
    sitemaps.push({ id: i });
  }
  return sitemaps; // Creates /sitemap/0.xml, /sitemap/50000.xml, etc.
}

export default async function sitemap({ id }: { id: number }): Promise<MetadataRoute.Sitemap> {
  const products = await getProducts({ offset: id, limit: 50000 });
  return products.map((product) => ({
    url: `https://example.com/products/${product.id}`,
    lastModified: product.updatedAt,
  }));
}
```

```tsx
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/admin/', '/api/'],
    },
    sitemap: 'https://example.com/sitemap.xml',
  };
}
```

---

## Font Optimization

Load fonts with zero layout shift and no external network requests via `next/font`.

### Google Fonts

```tsx
// app/layout.tsx
import { Inter, JetBrains_Mono } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',        // Show fallback font immediately, swap when loaded
  variable: '--font-inter', // CSS variable for Tailwind
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-mono',
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable}`}>
      <body className={inter.className}>{children}</body>
    </html>
  );
}
```

### Local Fonts

```tsx
import localFont from 'next/font/local';

const geist = localFont({
  src: [
    { path: './fonts/Geist-Regular.woff2', weight: '400', style: 'normal' },
    { path: './fonts/Geist-Medium.woff2', weight: '500', style: 'normal' },
    { path: './fonts/Geist-Bold.woff2', weight: '700', style: 'normal' },
  ],
  display: 'swap',
  variable: '--font-geist',
});
```

### Using with Tailwind CSS

```css
/* app/globals.css (Tailwind v4) */
@theme {
  --font-sans: var(--font-inter);
  --font-mono: var(--font-mono);
}
```

```css
/* tailwind.config.ts (Tailwind v3) */
/* extend: { fontFamily: { sans: ['var(--font-inter)'], mono: ['var(--font-mono)'] } } */
```

### Display Strategies

| Strategy | Behavior | Use When |
|---|---|---|
| `'swap'` | Show fallback immediately, swap when font loads | Default choice -- good for body text |
| `'optional'` | Use font only if cached, never block rendering | Performance-critical pages, tolerate fallback |
| `'auto'` | Browser decides | Rarely needed |
| `'block'` | Hide text briefly until font loads | Icons, logo text (short invisible period) |
| `'fallback'` | Brief block, then fallback, swap if loaded quickly | Compromise between swap and block |

### Variable Fonts

Prefer variable fonts to reduce file count and bundle size. Instead of loading 4 weight-specific files, a single variable font file covers all weights:

```tsx
const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  // Variable font -- no need to specify individual weights
  // Automatically supports weight range 100-900
});
```

---

## Scripts and Third Parties

### next/script Loading Strategies

```tsx
import Script from 'next/script';

// beforeInteractive -- loads before page hydration (rare, use for critical polyfills)
<Script src="/polyfill.js" strategy="beforeInteractive" />

// afterInteractive (default) -- loads after page hydration
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="afterInteractive"
/>

// lazyOnload -- loads during browser idle time (lowest priority)
<Script src="https://widget.example.com/embed.js" strategy="lazyOnload" />

// worker -- offloads to web worker via Partytown (experimental)
<Script
  src="https://www.googletagmanager.com/gtag/js?id=G-XXXXX"
  strategy="worker"
/>
```

### @next/third-parties

Pre-built integrations for common third-party services with optimized loading:

```tsx
// Google Analytics
import { GoogleAnalytics } from '@next/third-parties/google';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
      <GoogleAnalytics gaId="G-XXXXX" />
    </html>
  );
}

// Google Tag Manager
import { GoogleTagManager } from '@next/third-parties/google';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <GoogleTagManager gtmId="GTM-XXXXX" />
      <body>{children}</body>
    </html>
  );
}

// YouTube Embed (lazy-loaded, facade pattern)
import { YouTubeEmbed } from '@next/third-parties/google';

export function VideoSection() {
  return <YouTubeEmbed videoid="dQw4w9WgXcQ" params="controls=0" />;
}
```

### Script Event Handlers

```tsx
<Script
  src="https://checkout.stripe.com/checkout.js"
  strategy="lazyOnload"
  onLoad={() => {
    console.log('Stripe script loaded');
  }}
  onError={(e) => {
    console.error('Failed to load Stripe script', e);
  }}
/>
```

---

## Problematic Packages

Packages known to cause issues with Next.js App Router and Server Components:

| Package | Issue | Workaround |
|---|---|---|
| `sharp` | Needs native binaries in Docker | `npm install --os=linux --cpu=x64 sharp` or use `output: 'standalone'` |
| `bcrypt` | Native module, breaks in Edge Runtime | Use `bcryptjs` (pure JS implementation) |
| `recharts` | Client-only, large bundle (~450kb) | `dynamic(() => import('...'), { ssr: false })` |
| `react-quill` | Accesses `window`/`document` at import | `dynamic(() => import('...'), { ssr: false })` |
| `node-canvas` | Native C++ module, complex build | Use `@napi-rs/canvas` or offload to API route |
| `dotenv` | Conflicts with Next.js built-in `.env` loading | Remove -- Next.js loads `.env` files natively |
| `moment` | Massive bundle, locale files included | Use `date-fns` or `dayjs` with tree-shaking |
| `lodash` | Full bundle imported by default | Use `lodash-es` + `optimizePackageImports`, or individual imports |
| `@aws-sdk/*` | Large, pulls in many sub-packages | Import only specific clients; use `optimizePackageImports` |
| `mongoose` | Cannot run in Edge Runtime | Use in API routes/Server Actions with Node.js runtime only |

```tsx
// Dynamic import pattern for client-only packages
import dynamic from 'next/dynamic';

const RichTextEditor = dynamic(() => import('react-quill'), {
  ssr: false,
  loading: () => <div className="h-64 animate-pulse rounded bg-gray-100" />,
});

const Chart = dynamic(() => import('recharts').then((mod) => mod.LineChart), {
  ssr: false,
});
```

---

## Turbopack

Turbopack is now the default dev bundler in Next.js 15. Faster HMR and cold starts than webpack.

```bash
# Turbopack is used automatically in dev (Next.js 15+)
next dev                # uses Turbopack by default
next dev --turbopack    # explicit flag (same behavior)
```

No configuration changes needed. Turbopack supports the same `next.config.ts` options as webpack for development. For production builds, webpack is still used (`next build`).
