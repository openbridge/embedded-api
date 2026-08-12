# Amazon LWA Integration Example App

Angular 19 frontend + Express.js backend demonstrating Login with Amazon (LWA) OAuth flows for all three Amazon API surfaces.

## What It Demonstrates

### Public OAuth Apps (consent flow)
- **Advertising API** — 3 regional auth URLs (NA, EU, FE), scope `advertising::campaign_management`
- **Seller Central** — marketplace-specific Seller Central URLs, returns `spapi_oauth_code` + `selling_partner_id`
- **Vendor Central** — unique URL per marketplace (no shared EU URL), returns `spapi_oauth_code` + `selling_partner_id`

### Private Apps (self-authorized, Seller/Vendor only)
- User provides their own LWA Client ID, Client Secret, and Refresh Token at runtime
- Credentials are per-account and per-marketplace (not app-level config)
- Server exchanges refresh token for access token via the regional token endpoint

## Setup

### 1. Install dependencies

```bash
cd example-app/client && npm install
cd ../server && npm install
```

### 2. Configure credentials

```bash
cp server/.env.example server/.env
# Edit server/.env with your actual Amazon credentials
```

### 3. SSL certificates

Self-signed certs are pre-generated in `certs/`. Your browser will show a security warning — accept it for local development.

### 4. Start

```bash
chmod +x start.sh
./start.sh
```

Or start individually:

```bash
# Terminal 1: Express server
cd server && node index.js

# Terminal 2: Angular dev server
cd client && npx ng serve
```

- Frontend: https://localhost:4300
- Backend: https://localhost:3443

## Architecture

```
example-app/
├── certs/              # Self-signed SSL certs (localhost)
├── client/             # Angular 19 app (port 4300, SSL)
│   └── src/app/
│       ├── components/
│       │   ├── home/           # Service selection landing page
│       │   ├── advertising/    # Advertising API public OAuth
│       │   ├── seller/         # Seller Central public + private auth
│       │   ├── vendor/         # Vendor Central public + private auth
│       │   └── result/         # OAuth callback result display
│       └── services/
│           └── auth.service.ts # HTTP client for backend API
├── server/             # Express.js backend (port 3443, SSL)
│   └── index.js        # OAuth initiation, callbacks, token exchange
└── start.sh            # Starts both servers
```

## Key Implementation Details

- **State parameter**: Cryptographically random 48-char hex, stored in server-side session, validated with timing-safe comparison on callback
- **Token exchange**: Authorization codes exchanged server-side within 5-minute window, secrets never exposed to client
- **Regional routing**: Token endpoints vary by region (NA/EU/FE), marketplace determines region automatically
- **Separate credentials**: Public and private apps use different Client ID / Client Secret pairs (per Amazon requirements)
