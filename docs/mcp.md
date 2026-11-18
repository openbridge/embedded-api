# Openbridge MCP

The Openbridge MCP server exposes the Openbridge platform to AI agents and chat clients that speak the [Model Context Protocol](https://modelcontextprotocol.io). Once connected, an agent can discover products, inspect remote identities, create and manage subscriptions, check pipeline health, and request historical data — the same operations covered by the [Embedded API](api-usage-docs/getting-started.md) and [obcmd](embed-cli/README.md), driven by the model instead of by hand.

| | |
|---|---|
| **Endpoint** | `https://mcp.openbridge.com/mcp` |
| **Transport** | Streamable HTTP |
| **Authentication** | OAuth 2.1 (authorization code + PKCE, dynamic client registration) |
| **Source** | [openbridge/openbridge-mcp](https://github.com/openbridge/openbridge-mcp) |

---

## Before You Begin

- An Openbridge account with API access enabled by the Openbridge team.
- The account owner must have the `api-user` role.
- A browser on the machine running the client, for the OAuth consent step.

You do **not** need a refresh token, API credential, or client ID. The server advertises its OAuth metadata at `/.well-known/oauth-protected-resource/mcp` and supports dynamic client registration, so every client below registers itself and opens a browser window on first use.

!!! note "No API keys in config"
    Do not paste an Openbridge JWT or `account_id:token` credential into client configuration for the hosted endpoint. Let the OAuth flow run — tokens are stored and refreshed by the client's own credential store.

---

## Claude

### Claude Code (CLI)

Add the server, then authenticate:

```bash
claude mcp add --transport http openbridge https://mcp.openbridge.com/mcp
```

By default this registers the server at **local** scope (current project, your user only). To change that:

```bash
# available to you in every project
claude mcp add --transport http openbridge --scope user https://mcp.openbridge.com/mcp

# checked into the repo in .mcp.json, shared with the team
claude mcp add --transport http openbridge --scope project https://mcp.openbridge.com/mcp
```

Then authenticate. Inside a Claude Code session run:

```
/mcp
```

Select **openbridge** and follow the browser prompts. Or do it from the shell:

```bash
claude mcp login openbridge
```

Verify and manage:

```bash
claude mcp list
claude mcp get openbridge
claude mcp remove openbridge
```

Project scope writes a `.mcp.json` at the repo root:

```json
{
  "mcpServers": {
    "openbridge": {
      "type": "http",
      "url": "https://mcp.openbridge.com/mcp"
    }
  }
}
```

### Claude Desktop and Claude web

Add the endpoint as a custom connector:

1. Open **Settings → Connectors**.
2. Choose **Add custom connector**.
3. Enter `https://mcp.openbridge.com/mcp` as the URL and give it a name.
4. Click **Connect** and complete the browser sign-in.

The connector appears in the tools menu of new conversations once connected.

---

## Codex

Codex CLI reads MCP servers from `~/.codex/config.toml`. Add the server with:

```bash
codex mcp add openbridge --url https://mcp.openbridge.com/mcp
```

Codex detects the server's OAuth metadata and starts the sign-in flow. If you skip or cancel it, authenticate later with:

```bash
codex mcp login openbridge
```

Equivalent manual configuration in `~/.codex/config.toml`:

```toml
[mcp_servers.openbridge]
url = "https://mcp.openbridge.com/mcp"
auth = "oauth"
```

Confirm registration and auth state:

```bash
codex mcp list
```

!!! warning "Older Codex versions"
    Remote (HTTP) MCP servers were behind an experimental flag in earlier releases. If `codex mcp list` shows the server but Codex never loads its tools, upgrade Codex. On a version you cannot upgrade, enable the RMCP client in `~/.codex/config.toml`:

    ```toml
    [features]
    experimental_use_rmcp_client = true
    ```

---

## Gemini

Gemini CLI uses `httpUrl` for streamable HTTP servers (`url` means SSE). Add it with:

```bash
gemini mcp add --transport http openbridge https://mcp.openbridge.com/mcp
```

Or edit `~/.gemini/settings.json` (user-wide) or `.gemini/settings.json` (project):

```json
{
  "mcpServers": {
    "openbridge": {
      "httpUrl": "https://mcp.openbridge.com/mcp",
      "timeout": 30000
    }
  }
}
```

No `oauth` block is needed. Gemini CLI's default `authProviderType` is `dynamic_discovery`: it sees the `401`, reads the server's OAuth metadata, registers dynamically, and prompts you in the browser.

Authenticate and inspect from inside a session:

```
/mcp
/mcp auth openbridge
```

`/mcp auth` with no argument lists the servers that need authentication. Tokens are stored and refreshed automatically; re-run `/mcp auth openbridge` if a token is revoked.

---

## Verify the Connection

Ask the agent to list the Openbridge tools it can see, or use the client's own command — `/mcp` in Claude Code and Gemini CLI, `codex mcp list` in Codex. A connected server reports its tools; a server stuck at authentication reports a connection or auth error instead.

A good first prompt once connected:

> List the Openbridge products available to my account.

---

## What the Agent Sees

The server runs in **Code Mode**, which is the recommended surface for agent clients. Instead of exposing every Openbridge operation as a separate tool, it presents a small set of meta-tools:

| Tool | Purpose |
|---|---|
| `tags` | List the categories of available operations |
| `search` | Find operations by intent |
| `get_schema` | Read the input and output schema of an operation |
| `execute` | Run Python in a sandbox that calls the operations |

This keeps the tool list short regardless of how many Openbridge operations exist, and lets the model compose several calls in one step rather than round-tripping through the client for each one.

Credential-returning and mutating operations — creating or cancelling subscriptions, creating jobs, updating history status, and issuing Amazon API access tokens — belong to a privileged profile that is off unless enabled for your deployment. If an agent reports that one of those operations is unavailable, contact Openbridge support rather than working around it.

---

## Troubleshooting

**Client reports `401 Unauthorized`.** Authentication has not completed. Run the client's auth command (`/mcp` in Claude Code, `codex mcp login openbridge`, `/mcp auth openbridge` in Gemini CLI) and finish the browser flow. The endpoint returns `401` with a `WWW-Authenticate` header to every unauthenticated request — that is the handshake, not an outage.

**Browser flow finishes but the client still fails.** The redirect must reach the client's local callback listener. Complete the flow on the same machine as the client; an SSH session or container without browser access to the host loopback will not work.

**Tools never appear after adding the server.** Restart the client. Claude Code and Gemini CLI discover tools on session start; Codex needs a fresh session after a `config.toml` change.

**`403 Forbidden` on specific operations.** The authenticated account lacks access to that resource, or the operation is in the privileged profile. Confirm the account has the `api-user` role and that you authenticated as the intended account.

**Operations fail against a resource you expect to exist.** The MCP server is a view onto the same APIs as the rest of these docs. Reproduce the call with [obcmd](embed-cli/README.md) or `curl` to separate an MCP problem from a data or permissions problem — see [Diagnosing pipelines](tutorials/monitoring-healthchecks.md).

---

## Related

- [Getting Started](api-usage-docs/getting-started.md) — the underlying subscription workflow
- [Authentication API](api-usage-docs/authentication-api.md) — refresh tokens and JWTs for direct API access
- [obcmd CLI](embed-cli/README.md) — the same operations from a terminal
- [openbridge/openbridge-mcp](https://github.com/openbridge/openbridge-mcp) — server source, self-hosting, and environment reference
