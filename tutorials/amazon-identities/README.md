# Amazon Identities

Reference implementations for Amazon OAuth identity flows — covering **Advertising**, **Selling Partner**, and **Vendor Central** APIs.

---

## What's Inside

```
amazon-openbridge-identities/    Openbridge API integration (3 identity paths)
├── amazon-identity-configuration.md   Full API reference
└── example-apps/
    ├── backend/                 Express.js — port 3000
    ├── frontend/                Angular 19 — port 4300 (SSL)
    └── start.sh

login-with-amazon/               Standalone LWA OAuth 2.0 flows
├── lwa-complete-guide.md        Complete integration guide
└── example-app/
    ├── server/                  Express.js — port 3443 (HTTPS)
    ├── client/                  Angular 19 — port 4300 (SSL)
    └── start.sh
```

---

## Openbridge Identity Paths

Three ways to create Amazon identities through Openbridge:

| Path | Flow | Redirect? | Supported Types |
|------|------|:---------:|-----------------|
| **1 — Openbridge OAuth** | Openbridge manages the OAuth app | Yes | Advertising, Seller, Vendor |
| **2 — BYOA** | Your own SP-API OAuth credentials | Yes | Seller, Vendor |
| **3 — Private App** | Direct credential registration | No | Seller, Vendor |

> **Docs:** [`amazon-identity-configuration.md`](amazon-openbridge-identities/amazon-identity-configuration.md)

---

## LWA Authorization Flows

Direct Amazon OAuth flows without Openbridge:

| Route | Service | Flow |
|-------|---------|------|
| `/advertising` | Advertising API | OAuth 2.0 via LWA |
| `/seller` → Public | Seller Central (SP-API) | OAuth consent |
| `/seller` → Private | Seller Central (SP-API) | Self-authorization |
| `/vendor` → Public | Vendor Central (SP-API) | OAuth consent |
| `/vendor` → Private | Vendor Central (SP-API) | Self-authorization |

> **Docs:** [`lwa-complete-guide.md`](login-with-amazon/lwa-complete-guide.md)

---

## Quick Start

### 1. Install dependencies

```bash
# Openbridge identity flows
cd amazon-openbridge-identities/example-apps
(cd backend && npm install)
(cd frontend && npm install)

# Standalone LWA flows
cd ../../login-with-amazon/example-app
(cd server && npm install)
(cd client && npm install)
```

### 2. Configure credentials

Copy `.env.example` to `.env` in each server/backend directory and fill in your Amazon credentials.

### 3. Start

```bash
# Openbridge identity flows
cd amazon-openbridge-identities/example-apps && ./start.sh

# Standalone LWA flows
cd login-with-amazon/example-app && ./start.sh
```

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Angular 19, TypeScript |
| Backend | Express.js 5, Node.js 18+ |
| Auth | Amazon LWA OAuth 2.0, Openbridge JWT |
