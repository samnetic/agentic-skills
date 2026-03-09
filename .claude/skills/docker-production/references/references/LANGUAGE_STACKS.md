# Language Stack Patterns

Production-ready Dockerfile templates for every major runtime. Each template implements all OWASP security rules. Current base image versions as of early 2026.

---

## Node.js

```dockerfile
# syntax=docker/dockerfile:1

FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:22-slim AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build --chown=10001:10001 /app/dist ./dist
COPY --from=build --chown=10001:10001 /app/node_modules ./node_modules
COPY --from=build --chown=10001:10001 /app/package.json ./

ENV NODE_ENV=production
USER 10001:10001
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/health').then(r=>{if(!r.ok)throw r})" || exit 1

CMD ["node", "dist/index.js"]
```

**Notes:**
- `node:22-slim` over alpine — native modules work without musl issues
- `npm ci --ignore-scripts` prevents install-time script attacks
- `npm prune --omit=dev` removes devDependencies before copying
- Native `fetch()` for healthcheck (built-in since Node 18)
- `NODE_ENV=production` enables framework optimizations
- For TypeScript: build outputs to `dist/`, only copy that
- For DHI: `FROM docker.io/docker/node:22` (when available)

---

## Python (pip)

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS build
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.13-slim AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build /install /usr/local
COPY --chown=10001:10001 . .

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
USER 10001:10001
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--graceful-timeout", "30", "app.wsgi:application"]
```

**Notes:**
- `python:3.13-slim` NOT alpine — musl breaks many C-extension wheels
- `--prefix=/install` isolates pip output for clean multi-stage COPY
- `PYTHONUNBUFFERED=1` ensures logs aren't buffered (critical for containers)
- `PYTHONDONTWRITEBYTECODE=1` avoids .pyc in read-only filesystem
- Use gunicorn/uvicorn as production server, never `python app.py`

---

## Python (Poetry)

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS build
WORKDIR /app

RUN pip install --no-cache-dir poetry
COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false && \
    poetry install --no-interaction --no-ansi --only main --no-root
COPY . .
RUN poetry install --no-interaction --no-ansi --only main

FROM python:3.13-slim AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build --chown=10001:10001 /app .

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
USER 10001:10001
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app.wsgi:application"]
```

---

## Python (uv — Fast Modern Installer)

```dockerfile
# syntax=docker/dockerfile:1

FROM python:3.13-slim AS build
WORKDIR /app
RUN pip install --no-cache-dir uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable
COPY . .

FROM python:3.13-slim AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build /app/.venv /app/.venv
COPY --from=build --chown=10001:10001 /app .

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
USER 10001:10001
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Go

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.23-bookworm AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -o /app/server ./cmd/server

FROM gcr.io/distroless/static-debian12 AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

COPY --from=build /app/server /server

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/server", "--healthcheck"]

ENTRYPOINT ["/server"]
```

**Notes:**
- `CGO_ENABLED=0` → static binary → `distroless/static` (< 2MB)
- `-ldflags="-s -w"` strips debug info, ~30% smaller
- Distroless: no shell, no pkg manager — minimal attack surface
- Health check must be a binary (no shell for CMD-SHELL)
- Alternative: `FROM scratch` for absolute minimum (but no TLS certs — copy ca-certificates)

---

## Rust

```dockerfile
# syntax=docker/dockerfile:1

FROM rust:1.84-slim-bookworm AS build
WORKDIR /app

# Dependency cache trick
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main(){}" > src/main.rs && \
    cargo build --release && \
    rm -rf src target/release/.fingerprint/app-*

COPY . .
RUN cargo build --release

FROM debian:bookworm-slim AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/target/release/myapp /usr/local/bin/myapp

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["myapp", "--healthcheck"]

CMD ["myapp"]
```

**Notes:**
- Dummy `main.rs` trick caches dependency compilation
- For musl static: `FROM rust:1.84-alpine` + `rustup target add x86_64-unknown-linux-musl` → use `scratch`

---

## Java (Spring Boot)

```dockerfile
# syntax=docker/dockerfile:1

FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app

COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

COPY src ./src
RUN ./mvnw package -DskipTests -B
RUN java -Djarmode=tools -jar target/*.jar extract --destination /extracted

FROM eclipse-temurin:21-jre-jammy AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build --chown=10001:10001 /extracted ./

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD ["java", "-cp", "application", "org.springframework.boot.loader.launch.ProbeHealthCommand"]

CMD ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", \
     "-jar", "application/myapp.jar"]
```

**Notes:**
- JRE not JDK in production
- Spring Boot layered extraction for better Docker caching
- `-XX:+UseContainerSupport` respects container memory limits
- `-XX:MaxRAMPercentage=75.0` leaves headroom for OS
- Longer `start_period` (60s) — JVM startup is slow

---

## .NET (ASP.NET Core)

```dockerfile
# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY *.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:9.0-noble-chiseled AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

WORKDIR /app
COPY --from=build /app .

USER $APP_UID
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["dotnet", "MyApp.dll", "--healthcheck"]

ENTRYPOINT ["dotnet", "MyApp.dll"]
```

**Notes:**
- `noble-chiseled` = Ubuntu chiseled (distroless-like, no shell)
- `$APP_UID` pre-defined in Microsoft base images
- Separate restore from publish for layer caching

---

## PHP (Laravel / Symfony)

```dockerfile
# syntax=docker/dockerfile:1

FROM composer:2 AS deps
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist

FROM php:8.4-fpm-alpine AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN apk add --no-cache libpq-dev && \
    docker-php-ext-install pdo_pgsql opcache

RUN addgroup -g 10001 -S app && adduser -u 10001 -S -G app -s /sbin/nologin app
WORKDIR /app

COPY --from=deps --chown=10001:10001 /app/vendor ./vendor
COPY --chown=10001:10001 . .
RUN composer dump-autoload --optimize --no-dev

USER 10001:10001
EXPOSE 9000

CMD ["php-fpm"]
```

---

## Ruby (Rails)

```dockerfile
# syntax=docker/dockerfile:1

FROM ruby:3.3-slim AS build
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without 'development test' && \
    bundle install

COPY . .
RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile

FROM ruby:3.3-slim AS production
LABEL org.opencontainers.image.source="https://github.com/org/repo"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 app && useradd -u 10001 -g app -s /bin/false -M app
WORKDIR /app

COPY --from=build --chown=10001:10001 /app .

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1
USER 10001:10001
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["ruby", "-e", "require 'net/http'; Net::HTTP.get(URI('http://localhost:3000/health'))"]

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

---

## Dependency Install Patterns (Cache-Friendly)

| Language | Copy First | Install Command |
|---|---|---|
| Node (npm) | `package.json package-lock.json` | `npm ci --omit=dev --ignore-scripts` |
| Node (yarn) | `package.json yarn.lock` | `yarn install --frozen-lockfile --production` |
| Node (pnpm) | `package.json pnpm-lock.yaml` | `pnpm install --frozen-lockfile --prod` |
| Python (pip) | `requirements.txt` | `pip install --no-cache-dir -r requirements.txt` |
| Python (poetry) | `pyproject.toml poetry.lock` | `poetry install --only main` |
| Python (uv) | `pyproject.toml uv.lock` | `uv sync --frozen --no-dev` |
| Go | `go.mod go.sum` | `go mod download && go mod verify` |
| Rust | `Cargo.toml Cargo.lock` | dummy main trick + `cargo build --release` |
| Java (Maven) | `pom.xml` | `mvn dependency:go-offline -B` |
| Java (Gradle) | `build.gradle.kts gradle/` | `gradle dependencies --no-daemon` |
| .NET | `*.csproj` | `dotnet restore` |
| PHP | `composer.json composer.lock` | `composer install --no-dev --prefer-dist` |
| Ruby | `Gemfile Gemfile.lock` | `bundle install` with deployment config |
