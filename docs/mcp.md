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

- An Openbridge account.
- A browser, to sign in the first time you connect. With a command-line client, that browser has to be on the same machine you run the client on.

You do not need any keys or credentials. Each client signs you in through your browser on first use.

!!! note "No API keys in config"
    Do not paste an Openbridge token into a client's configuration. Sign in through the browser instead — the client stores and renews the token for you.

---

## Claude (claude.ai and Claude Desktop)

Add the endpoint as a custom connector. Same steps in the web app and the desktop app:

1. Open **Customize → Connectors**.
2. Select **+ Add**, then **Add custom connector**.
3. Give it a name — `Openbridge` — and enter the URL `https://mcp.openbridge.com/mcp`.
4. Leave authentication on OAuth. For how Claude identifies itself, **Use Claude's published identity** or **Register automatically** both work; you do not need your own OAuth client.
5. Click **Add**, then complete the Openbridge sign-in.

Enable it per conversation with the **+** button in the chat composer → **Connectors** → **Openbridge**.

!!! note "Reachability"
    Connectors are fetched by Anthropic's servers, not your machine, so the endpoint must be reachable from the public internet on port 443. That is automatic for the hosted endpoint; a [self-hosted](#self-hosting) instance behind a VPN will not connect from claude.ai and needs a CLI client instead.

---

## ChatGPT

Custom MCP servers are added as plugins, in ChatGPT on the web:

1. Open **ChatGPT Plugins**.
2. Select **+**, then **Add custom MCP server**.
3. Enter a name — `Openbridge` — and the server URL `https://mcp.openbridge.com/mcp`.
4. Set authentication to **OAuth**.
5. Accept the risk warning, create the plugin, and install it.
6. Complete the Openbridge sign-in when prompted.

Call it in a conversation by typing `@` and selecting the plugin. Naming the tool explicitly helps — *"Use the Openbridge app's `search` tool to find subscription operations."*

Openbridge's `execute` tool is not marked read-only, so ChatGPT treats it as a write action and asks you to confirm each run. Read the call before confirming.

!!! note "Plan requirements"
    Custom MCP servers need a paid ChatGPT plan on the web. Business and Enterprise/Edu workspaces get full tool access, and only admins and owners can create or publish the connection; Pro is limited to read and fetch tools, which rules out the mutating Openbridge operations. Free and Go do not support custom MCP servers.

---

## Claude Code

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

---

## Codex CLI

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

## Antigravity

All three Antigravity surfaces — the desktop app, the IDE, and the CLI — read MCP servers from `mcp_config.json`, not from the Gemini CLI settings file. The global file is `~/.gemini/config/mcp_config.json`; the CLI also reads `<workspace>/.agents/mcp_config.json` for a single workspace.

The Openbridge entry looks the same everywhere:

```json
{
  "mcpServers": {
    "openbridge": {
      "serverUrl": "https://mcp.openbridge.com/mcp",
      "timeoutSeconds": 180
    }
  }
}
```

No credentials go in the file. Antigravity registers itself with the server and sends you to the browser to sign in.

!!! note "Use `serverUrl`"
    Antigravity does not accept Gemini CLI's `httpUrl` key, and its timeout is in seconds rather than milliseconds. Copying a Gemini CLI block across will load nothing.

### Antigravity app (desktop)

The **Add MCP Server** button lists servers Antigravity already knows about, and Openbridge is not one of them, so add it through the config file:

1. Click **Customizations** in the sidebar, click **Installed**, and scroll to **MCP Servers**.
2. Open the raw config and add the `openbridge` entry above to `~/.gemini/config/mcp_config.json`.
3. Back in **MCP Servers**, click **Refresh**. Openbridge appears in the list.
4. Click **Authenticate** next to it, sign in to Openbridge in the browser, copy the authorization code it gives you, paste it into **Enter authorization code**, and click **Submit**.

The server reconnects on its own once the code is accepted.

### Antigravity IDE

1. Click **…** at the top of the agent side panel and choose **MCP Servers**.
2. Click **Manage MCP Servers**, then **View raw config**.
3. Add the `openbridge` entry, save, and reload the server list.
4. Sign in when prompted.

**View raw config** also tells you which file your build is actually reading, which is worth checking if an entry seems to be ignored.

### Antigravity CLI

```bash
agy mcp add openbridge https://mcp.openbridge.com/mcp
```

Or edit the config file by hand and restart the CLI. Confirm with `agy mcp list`, or `/mcp` inside a session.

---

## Gemini CLI

!!! warning "Being retired"
    Google is retiring Gemini CLI and the Gemini Code Assist IDE extensions: they stop serving requests on **June 18, 2026** for free and consumer tiers. Enterprise customers on Gemini Code Assist Standard or Enterprise licenses keep access. New setups should use [Antigravity](#antigravity) instead.

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

Ask the agent to list the Openbridge tools it can see, or use the client's own command — `/mcp` in Claude Code and Gemini CLI, `codex mcp list` in Codex CLI, `agy mcp list` in Antigravity. In claude.ai, Claude Desktop, and ChatGPT, open the connector or plugin entry and check that it lists tools. A connected server reports its tools; a server stuck at authentication reports a connection or auth error instead.

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

**Client reports `401 Unauthorized`.** Authentication has not completed. Run the client's auth command (`/mcp` in Claude Code or Antigravity, `codex mcp login openbridge`, `/mcp auth openbridge` in Gemini CLI), or reconnect the connector in claude.ai, Claude Desktop, or ChatGPT, and finish the browser flow. The endpoint returns `401` with a `WWW-Authenticate` header to every unauthenticated request — that is the handshake, not an outage.

**Browser flow finishes but a CLI client still fails.** The redirect must reach the client's local callback listener. Complete the flow on the same machine as the client; an SSH session or container without browser access to the host loopback will not work.

**Tools never appear after adding the server.** Restart the client. Claude Code and Gemini CLI discover tools on session start; Codex CLI needs a fresh session after a `config.toml` change, and Antigravity needs one after an `mcp_config.json` edit. In claude.ai, Claude Desktop, and ChatGPT the connector is per conversation — enable it in a new chat (**+ → Connectors** in Claude, `@` in ChatGPT) rather than expecting it in an existing one.

**`403 Forbidden` on specific operations.** The authenticated account lacks access to that resource, or the operation is in the privileged profile. Confirm you authenticated as the intended account.

**Operations fail against a resource you expect to exist.** The MCP server is a view onto the same APIs as the rest of these docs. Reproduce the call with [obcmd](embed-cli/README.md) or `curl` to separate an MCP problem from a data or permissions problem — see [Diagnosing pipelines](tutorials/monitoring-healthchecks.md).

---

## Self-Hosting

`https://mcp.openbridge.com/mcp` is the hosted endpoint Openbridge operates, and it is the right choice for most integrations. The server is also open source, so you can run your own instance instead — typically to place it inside your own network, to control which tools are exposed, or to point an agent at a local build while developing.

Self-hosting requires a Premium, Business, or Enterprise Openbridge account. A self-hosted instance authenticates against the same Openbridge APIs as the hosted endpoint.

Client configuration is the same as above with your own URL in place of the hosted one. Setup, deployment topology, and the full environment reference live in the repository: [openbridge/openbridge-mcp](https://github.com/openbridge/openbridge-mcp).
