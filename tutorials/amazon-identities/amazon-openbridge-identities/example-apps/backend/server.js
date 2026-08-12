require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors({ origin: process.env.CALLBACK_URL }));
app.use(express.json());

const { JWT_TOKEN, ACCOUNT_ID, USER_ID } = process.env;

const API_BASES = {
  state: 'https://state.api.dev.openbridge.io',
  oauth: 'https://oauth.api.dev.openbridge.io',
  service: 'https://service.api.dev.openbridge.io',
  ri: 'https://remote-identity.api.dev.openbridge.io',
};

const authHeaders = () => ({
  Authorization: `Bearer ${JWT_TOKEN}`,
  'Content-Type': 'application/json',
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', configured: JWT_TOKEN !== 'your_jwt_token_here' });
});

// Get config (account_id, user_id — no secrets)
app.get('/api/config', (req, res) => {
  res.json({ account_id: ACCOUNT_ID, user_id: USER_ID });
});

// ─── Path 1 & 2: Create state record ───────────────────────────────────────
app.post('/api/state', async (req, res) => {
  try {
    const { remote_identity_type_id, region, return_url, oauth_id, remote_identity_id } = req.body;
    const state = {
      remote_identity_type_id,
      user_id: USER_ID,
      region,
      return_url,
    };
    if (oauth_id) state.oauth_id = oauth_id;
    if (remote_identity_id) state.remote_identity_id = remote_identity_id;

    const response = await axios.post(
      `${API_BASES.state}/state/oauth`,
      { data: { type: 'ClientState', attributes: { state } } },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Path 2: Register OAuth app (BYOA) ─────────────────────────────────────
app.post('/api/oauth/apps', async (req, res) => {
  try {
    const { remote_identity_type, client_id, client_secret, app_id } = req.body;
    const response = await axios.post(
      `${API_BASES.oauth}/oauth/apps`,
      {
        data: {
          type: 'OAuth',
          attributes: {
            remote_identity_type,
            account: ACCOUNT_ID,
            user: USER_ID,
            client_id,
            client_secret,
            extra_params: JSON.stringify({ app_id }),
          },
        },
      },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// List OAuth apps
app.get('/api/oauth/apps', async (req, res) => {
  try {
    const { remote_identity_type_id } = req.query;
    const url = remote_identity_type_id
      ? `${API_BASES.oauth}/oauth/apps?remote_identity_type_id=${remote_identity_type_id}`
      : `${API_BASES.oauth}/oauth/apps`;
    const response = await axios.get(url, { headers: authHeaders() });
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// Delete OAuth app
app.delete('/api/oauth/apps/:id', async (req, res) => {
  try {
    await axios.delete(`${API_BASES.oauth}/oauth/apps/${req.params.id}`, { headers: authHeaders() });
    res.status(204).send();
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Path 3: Validate credentials (Selling Partner) ────────────────────────
app.post('/api/service/sp/sp-id', async (req, res) => {
  try {
    const { client_id, client_secret, region, refresh_token } = req.body;
    const response = await axios.post(
      `${API_BASES.service}/service/sp/sp-id`,
      {
        data: {
          type: 'Service',
          attributes: { client_id, client_secret, region, refresh_token },
        },
      },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Path 3: Validate credentials (Vendor Central) ─────────────────────────
app.post('/api/service/sp/validate-creds', async (req, res) => {
  try {
    const { client_id, client_secret, region, refresh_token } = req.body;
    const response = await axios.post(
      `${API_BASES.service}/service/sp/validate-creds`,
      {
        data: {
          type: 'Service',
          attributes: { client_id, client_secret, region, refresh_token },
        },
      },
      { headers: authHeaders() }
    );
    res.status(204).send();
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Path 3: Encrypt credentials ───────────────────────────────────────────
app.post('/api/service/encrypt', async (req, res) => {
  try {
    const { clientSecret, refreshToken } = req.body;
    const attributes = {};
    if (clientSecret) attributes.clientSecret = clientSecret;
    if (refreshToken) attributes.refreshToken = refreshToken;

    const response = await axios.post(
      `${API_BASES.service}/service/encrypt/encrypt`,
      { data: { attributes } },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Path 3: Create remote identity ────────────────────────────────────────
app.post('/api/ri', async (req, res) => {
  try {
    const { remote_identity_type, name, region, remote_identity_meta_attributes, remote_unique_id } = req.body;
    const response = await axios.post(
      `${API_BASES.ri}/ri`,
      {
        data: {
          type: 'RemoteIdentity',
          attributes: {
            remote_identity_type,
            name,
            account: ACCOUNT_ID,
            user: USER_ID,
            identity_hash: uuidv4(),
            remote_unique_id,
            region,
            is_private_app: true,
            remote_identity_meta_attributes,
          },
        },
      },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Query identities ──────────────────────────────────────────────────────
app.get('/api/identities', async (req, res) => {
  try {
    const { remote_identity_type, invalid_identity } = req.query;
    let url = `${API_BASES.ri}/sri`;
    const params = [];
    if (remote_identity_type) params.push(`remote_identity_type=${remote_identity_type}`);
    if (invalid_identity) params.push(`invalid_identity=${invalid_identity}`);
    if (params.length) url += '?' + params.join('&');

    const response = await axios.get(url, { headers: authHeaders() });
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// Get single identity
app.get('/api/identities/:id', async (req, res) => {
  try {
    const response = await axios.get(`${API_BASES.ri}/ri/${req.params.id}`, { headers: authHeaders() });
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// Get identity meta
app.get('/api/identities/:id/meta', async (req, res) => {
  try {
    const response = await axios.get(`${API_BASES.ri}/rim?remote_identity=${req.params.id}`, { headers: authHeaders() });
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Update Private App identity ───────────────────────────────────────────
app.patch('/api/ri/:id', async (req, res) => {
  try {
    const { remote_identity_type, name, region, identity_hash, remote_unique_id, remote_identity_meta_attributes } = req.body;
    const response = await axios.patch(
      `${API_BASES.ri}/ri/${req.params.id}`,
      {
        data: {
          type: 'RemoteIdentity',
          id: parseInt(req.params.id),
          attributes: {
            remote_identity_type,
            name,
            account: ACCOUNT_ID,
            user: USER_ID,
            identity_hash,
            remote_unique_id,
            region,
            remote_identity_meta_attributes,
          },
        },
      },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

// ─── Reauthorize OAuth identity ────────────────────────────────────────────
app.post('/api/reauth', async (req, res) => {
  try {
    const { remote_identity_type_id, region, return_url, remote_identity_id, oauth_id } = req.body;
    const state = {
      remote_identity_type_id,
      user_id: USER_ID,
      region,
      return_url,
      remote_identity_id,
    };
    if (oauth_id) state.oauth_id = oauth_id;

    const response = await axios.post(
      `${API_BASES.state}/state/oauth`,
      { data: { type: 'ClientState', attributes: { state } } },
      { headers: authHeaders() }
    );
    res.json(response.data);
  } catch (err) {
    res.status(err.response?.status || 500).json(err.response?.data || { error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
