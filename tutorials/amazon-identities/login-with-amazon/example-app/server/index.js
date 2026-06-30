const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');
const cors = require('cors');
const crypto = require('crypto');
const session = require('express-session');
const axios = require('axios');

require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3443;

// SSL certs
const sslOptions = {
  key: fs.readFileSync(path.join(__dirname, '..', 'certs', 'key.pem')),
  cert: fs.readFileSync(path.join(__dirname, '..', 'certs', 'cert.pem')),
};

app.use(cors({
  origin: 'https://localhost:4300',
  credentials: true,
}));
app.use(express.json());
app.use(session({
  secret: process.env.SESSION_SECRET || 'dev-secret-change-me',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: true, sameSite: 'none', maxAge: 30 * 60 * 1000 },
}));

// ---------------------------------------------------------------------------
// Endpoint data from the LWA guide
// ---------------------------------------------------------------------------

const ADVERTISING_AUTH_URLS = {
  NA: 'https://www.amazon.com/ap/oa',
  EU: 'https://eu.account.amazon.com/ap/oa',
  FE: 'https://apac.account.amazon.com/ap/oa',
};

const TOKEN_ENDPOINTS = {
  NA: 'https://api.amazon.com/auth/o2/token',
  EU: 'https://api.amazon.co.uk/auth/o2/token',
  FE: 'https://api.amazon.co.jp/auth/o2/token',
};

const SELLER_CENTRAL_URLS = {
  US: 'https://sellercentral.amazon.com',
  CA: 'https://sellercentral.amazon.ca',
  MX: 'https://sellercentral.amazon.com.mx',
  BR: 'https://sellercentral.amazon.com.br',
  UK: 'https://sellercentral-europe.amazon.com',
  DE: 'https://sellercentral-europe.amazon.com',
  FR: 'https://sellercentral-europe.amazon.com',
  IT: 'https://sellercentral-europe.amazon.com',
  ES: 'https://sellercentral-europe.amazon.com',
  NL: 'https://sellercentral.amazon.nl',
  SE: 'https://sellercentral.amazon.se',
  PL: 'https://sellercentral.amazon.pl',
  BE: 'https://sellercentral.amazon.com.be',
  EG: 'https://sellercentral.amazon.eg',
  TR: 'https://sellercentral.amazon.com.tr',
  SA: 'https://sellercentral.amazon.sa',
  AE: 'https://sellercentral.amazon.ae',
  IN: 'https://sellercentral.amazon.in',
  SG: 'https://sellercentral.amazon.sg',
  AU: 'https://sellercentral.amazon.com.au',
  JP: 'https://sellercentral.amazon.co.jp',
};

const VENDOR_CENTRAL_URLS = {
  US: 'https://vendorcentral.amazon.com',
  CA: 'https://vendorcentral.amazon.ca',
  MX: 'https://vendorcentral.amazon.com.mx',
  BR: 'https://vendorcentral.amazon.com.br',
  UK: 'https://vendorcentral.amazon.co.uk',
  DE: 'https://vendorcentral.amazon.de',
  FR: 'https://vendorcentral.amazon.fr',
  IT: 'https://vendorcentral.amazon.it',
  ES: 'https://vendorcentral.amazon.es',
  NL: 'https://vendorcentral.amazon.nl',
  SE: 'https://vendorcentral.amazon.se',
  PL: 'https://vendorcentral.amazon.pl',
  BE: 'https://vendorcentral.amazon.com.be',
  EG: 'https://vendorcentral.amazon.me',
  TR: 'https://vendorcentral.amazon.com.tr',
  AE: 'https://vendorcentral.amazon.me',
  IN: 'https://vendorcentral.amazon.in',
  SG: 'https://vendorcentral.amazon.com.sg',
  AU: 'https://vendorcentral.amazon.com.au',
  JP: 'https://vendorcentral.amazon.co.jp',
};

const MARKETPLACE_REGIONS = {
  US: 'NA', CA: 'NA', MX: 'NA', BR: 'NA',
  UK: 'EU', DE: 'EU', FR: 'EU', IT: 'EU', ES: 'EU',
  NL: 'EU', SE: 'EU', PL: 'EU', BE: 'EU', EG: 'EU',
  TR: 'EU', SA: 'EU', AE: 'EU', IN: 'EU',
  SG: 'FE', AU: 'FE', JP: 'FE',
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function generateState() {
  return crypto.randomBytes(24).toString('hex');
}

function getTokenEndpoint(region) {
  return TOKEN_ENDPOINTS[region] || TOKEN_ENDPOINTS.NA;
}

// ---------------------------------------------------------------------------
// API: Reference data for the Angular frontend
// ---------------------------------------------------------------------------

app.get('/api/endpoints', (_req, res) => {
  res.json({
    advertisingAuthUrls: ADVERTISING_AUTH_URLS,
    tokenEndpoints: TOKEN_ENDPOINTS,
    sellerCentralUrls: SELLER_CENTRAL_URLS,
    vendorCentralUrls: VENDOR_CENTRAL_URLS,
    marketplaceRegions: MARKETPLACE_REGIONS,
  });
});

// ---------------------------------------------------------------------------
// Advertising API — Public OAuth
// ---------------------------------------------------------------------------

app.get('/auth/advertising/initiate', (req, res) => {
  const region = req.query.region || 'NA';
  const authUrl = ADVERTISING_AUTH_URLS[region];
  if (!authUrl) return res.status(400).json({ error: 'Invalid region' });

  const state = generateState();
  req.session.oauthState = state;
  req.session.oauthService = 'advertising';
  req.session.oauthRegion = region;

  const params = new URLSearchParams({
    client_id: process.env.ADS_CLIENT_ID,
    scope: 'advertising::campaign_management',
    response_type: 'code',
    redirect_uri: process.env.ADS_REDIRECT_URI,
    state,
  });

  res.json({ url: `${authUrl}?${params}` });
});

app.get('/auth/advertising/callback', async (req, res) => {
  const { code, state } = req.query;

  if (!state || !req.session.oauthState || !crypto.timingSafeEqual(
    Buffer.from(state), Buffer.from(req.session.oauthState)
  )) {
    return res.redirect('https://localhost:4300/result?error=invalid_state');
  }

  const region = req.session.oauthRegion || 'NA';
  delete req.session.oauthState;
  delete req.session.oauthService;
  delete req.session.oauthRegion;

  try {
    const tokenRes = await axios.post(getTokenEndpoint(region), new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      redirect_uri: process.env.ADS_REDIRECT_URI,
      client_id: process.env.ADS_CLIENT_ID,
      client_secret: process.env.ADS_CLIENT_SECRET,
    }).toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });

    const resultParams = new URLSearchParams({
      service: 'advertising',
      region,
      success: 'true',
      expires_in: tokenRes.data.expires_in,
    });
    res.redirect(`https://localhost:4300/result?${resultParams}`);
  } catch (err) {
    const msg = err.response?.data?.error_description || err.message;
    res.redirect(`https://localhost:4300/result?error=${encodeURIComponent(msg)}`);
  }
});

// ---------------------------------------------------------------------------
// Seller Central — Public App OAuth
// ---------------------------------------------------------------------------

app.get('/auth/seller/initiate', (req, res) => {
  const marketplace = req.query.marketplace || 'US';
  const baseUrl = SELLER_CENTRAL_URLS[marketplace];
  if (!baseUrl) return res.status(400).json({ error: 'Invalid marketplace' });

  const state = generateState();
  req.session.oauthState = state;
  req.session.oauthService = 'seller';
  req.session.oauthMarketplace = marketplace;

  const params = new URLSearchParams({
    application_id: process.env.SELLER_PUBLIC_APP_ID,
    state,
    redirect_uri: process.env.SELLER_PUBLIC_REDIRECT_URI,
  });

  res.json({ url: `${baseUrl}/apps/authorize/consent?${params}` });
});

app.get('/auth/seller/callback', async (req, res) => {
  const { spapi_oauth_code, state, selling_partner_id } = req.query;

  if (!state || !req.session.oauthState || !crypto.timingSafeEqual(
    Buffer.from(state), Buffer.from(req.session.oauthState)
  )) {
    return res.redirect('https://localhost:4300/result?error=invalid_state');
  }

  const marketplace = req.session.oauthMarketplace || 'US';
  const region = MARKETPLACE_REGIONS[marketplace] || 'NA';
  delete req.session.oauthState;
  delete req.session.oauthService;
  delete req.session.oauthMarketplace;

  try {
    const tokenRes = await axios.post(getTokenEndpoint(region), new URLSearchParams({
      grant_type: 'authorization_code',
      code: spapi_oauth_code,
      redirect_uri: process.env.SELLER_PUBLIC_REDIRECT_URI,
      client_id: process.env.SELLER_PUBLIC_CLIENT_ID,
      client_secret: process.env.SELLER_PUBLIC_CLIENT_SECRET,
    }).toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });

    const resultParams = new URLSearchParams({
      service: 'seller',
      marketplace,
      selling_partner_id: selling_partner_id || '',
      success: 'true',
      expires_in: tokenRes.data.expires_in,
    });
    res.redirect(`https://localhost:4300/result?${resultParams}`);
  } catch (err) {
    const msg = err.response?.data?.error_description || err.message;
    res.redirect(`https://localhost:4300/result?error=${encodeURIComponent(msg)}`);
  }
});

// ---------------------------------------------------------------------------
// Seller Central — Private App (token exchange with user-provided creds)
// ---------------------------------------------------------------------------

app.post('/auth/seller/private', async (req, res) => {
  const { client_id, client_secret, refresh_token, region } = req.body;
  if (!client_id || !client_secret || !refresh_token) {
    return res.status(400).json({ error: 'client_id, client_secret, and refresh_token are required' });
  }

  try {
    const tokenRes = await axios.post(getTokenEndpoint(region || 'NA'), new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token,
      client_id,
      client_secret,
    }).toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });

    res.json({
      success: true,
      service: 'seller-private',
      expires_in: tokenRes.data.expires_in,
      token_type: tokenRes.data.token_type,
    });
  } catch (err) {
    const msg = err.response?.data?.error_description || err.message;
    res.status(400).json({ error: msg });
  }
});

// ---------------------------------------------------------------------------
// Vendor Central — Public App OAuth
// ---------------------------------------------------------------------------

app.get('/auth/vendor/initiate', (req, res) => {
  const marketplace = req.query.marketplace || 'US';
  const baseUrl = VENDOR_CENTRAL_URLS[marketplace];
  if (!baseUrl) return res.status(400).json({ error: 'Invalid marketplace' });

  const state = generateState();
  req.session.oauthState = state;
  req.session.oauthService = 'vendor';
  req.session.oauthMarketplace = marketplace;

  const params = new URLSearchParams({
    application_id: process.env.VENDOR_PUBLIC_APP_ID,
    state,
    redirect_uri: process.env.VENDOR_PUBLIC_REDIRECT_URI,
  });

  res.json({ url: `${baseUrl}/apps/authorize/consent?${params}` });
});

app.get('/auth/vendor/callback', async (req, res) => {
  const { spapi_oauth_code, state, selling_partner_id } = req.query;

  if (!state || !req.session.oauthState || !crypto.timingSafeEqual(
    Buffer.from(state), Buffer.from(req.session.oauthState)
  )) {
    return res.redirect('https://localhost:4300/result?error=invalid_state');
  }

  const marketplace = req.session.oauthMarketplace || 'US';
  const region = MARKETPLACE_REGIONS[marketplace] || 'NA';
  delete req.session.oauthState;
  delete req.session.oauthService;
  delete req.session.oauthMarketplace;

  try {
    const tokenRes = await axios.post(getTokenEndpoint(region), new URLSearchParams({
      grant_type: 'authorization_code',
      code: spapi_oauth_code,
      redirect_uri: process.env.VENDOR_PUBLIC_REDIRECT_URI,
      client_id: process.env.VENDOR_PUBLIC_CLIENT_ID,
      client_secret: process.env.VENDOR_PUBLIC_CLIENT_SECRET,
    }).toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });

    const resultParams = new URLSearchParams({
      service: 'vendor',
      marketplace,
      selling_partner_id: selling_partner_id || '',
      success: 'true',
      expires_in: tokenRes.data.expires_in,
    });
    res.redirect(`https://localhost:4300/result?${resultParams}`);
  } catch (err) {
    const msg = err.response?.data?.error_description || err.message;
    res.redirect(`https://localhost:4300/result?error=${encodeURIComponent(msg)}`);
  }
});

// ---------------------------------------------------------------------------
// Vendor Central — Private App (token exchange with user-provided creds)
// ---------------------------------------------------------------------------

app.post('/auth/vendor/private', async (req, res) => {
  const { client_id, client_secret, refresh_token, region } = req.body;
  if (!client_id || !client_secret || !refresh_token) {
    return res.status(400).json({ error: 'client_id, client_secret, and refresh_token are required' });
  }

  try {
    const tokenRes = await axios.post(getTokenEndpoint(region || 'NA'), new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token,
      client_id,
      client_secret,
    }).toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });

    res.json({
      success: true,
      service: 'vendor-private',
      expires_in: tokenRes.data.expires_in,
      token_type: tokenRes.data.token_type,
    });
  } catch (err) {
    const msg = err.response?.data?.error_description || err.message;
    res.status(400).json({ error: msg });
  }
});

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

https.createServer(sslOptions, app).listen(PORT, () => {
  console.log(`Server running at https://localhost:${PORT}`);
});
