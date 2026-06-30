# Amazon Login with Amazon (LWA) Example

Example application demonstrating OAuth 2.0 authorization flows for Amazon Advertising, Seller Central, and Vendor Central APIs.

## Prerequisites

- Node.js 18+
- Angular CLI 19 (`npm install -g @angular/cli`)
- Amazon Developer Console credentials (see [docs/](docs/))

## Quick Start

### 1. Configure server credentials

```bash
cd example-app/server
cp .env.example .env
```

Edit `.env` with your Amazon LWA credentials:

- **Advertising**: `ADS_CLIENT_ID`, `ADS_CLIENT_SECRET` from your LWA security profile
- **Seller Central**: `SELLER_CLIENT_ID`, `SELLER_CLIENT_SECRET`, `SELLER_APPLICATION_ID` from Seller Central > Partner Network > Develop Apps
- **Vendor Central**: `VENDOR_CLIENT_ID`, `VENDOR_CLIENT_SECRET`, `VENDOR_APPLICATION_ID` from Vendor Central > Integration > API Integration
- **Private apps** (optional): Pre-generated refresh tokens from Seller/Vendor Central

### 2. Install dependencies

```bash
# Server
cd example-app/server
npm install

# Client
cd ../client
npm install
```

### 3. Run

```bash
# Terminal 1 — Express server (port 3000)
cd example-app/server
npm run dev

# Terminal 2 — Angular dev server (port 4300, SSL)
cd example-app/client
ng serve
```

Open https://localhost:4300 (accept the self-signed certificate warning).

## Authorization Flows

| Route | Service | Type |
|-------|---------|------|
| `/advertising` | Amazon Advertising API | OAuth 2.0 via LWA |
| `/seller` → Public tab | Seller Central (SP-API) | OAuth consent flow |
| `/seller` → Private tab | Seller Central (SP-API) | Self-authorization (refresh token) |
| `/vendor` → Public tab | Vendor Central (SP-API) | OAuth consent flow |
| `/vendor` → Private tab | Vendor Central (SP-API) | Self-authorization (refresh token) |

## Project Structure

```
docs/                  LWA documentation for each Amazon service
example-app/
  client/              Angular 19 frontend
  server/              Express.js backend
    .env.example       Credential template
    index.js           API routes and OAuth logic
```

## Documentation

- [Complete LWA Guide](docs/lwa-complete-guide.md) — all documentation in a single file with table of contents

Individual documents:
- [LWA Integration Guide](docs/lwa-integration-guide.md)
- [Amazon Advertising API](docs/lwa-amazon-advertising.md)
- [Seller Central](docs/lwa-seller-central.md)
- [Vendor Central](docs/lwa-vendor-central.md)
- [Regional Endpoints](docs/lwa-regional-endpoints.md)
- [State Parameter](docs/lwa-state-parameter.md)
- [Button Guidelines](docs/lwa-button-guidelines.md)
