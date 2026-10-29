# obcmd — Usage Documentation

`obcmd` is a command-line client for the Openbridge APIs, designed so that both
people and AI agents can drive it without guessing.

These pages cover **using** the CLI. If you are changing the CLI itself, the
contributor documentation ships with the source repository, not the published
package.

| Page | What it covers |
|---|---|
| [Getting started](getting-started.md) | Install, authenticate, run your first command |
| [Authentication](authentication.md) | Refresh tokens, access tokens, build modes |
| [Output and exit codes](output-and-exit-codes.md) | JSON vs text, field masks, pagination, error shape |
| [Command reference](commands.md) | Every resource, verb and flag (generated) |
| [Recipes](recipes.md) | Short snippets for common tasks |
| [Examples](examples/README.md) | Step-by-step walkthroughs, one per task |
| [Troubleshooting](troubleshooting.md) | What each failure means and how to fix it |

## The one-paragraph version

Commands read `obcmd <resource> <verb> [flags]`. Verbs come from a fixed
vocabulary, so once you know `list` and `get` you can use them on any resource.
Output is a human table at a terminal and JSON when piped. Exit codes carry
meaning: `0` success, `2` you made a mistake, `3` not found, `4` re-authenticate,
`5` conflict. Every mutating command takes `--dry-run`.

```bash
export OBCMD_REFRESH_TOKEN="ory_at_..."
obcmd auth login
obcmd subscription list --status active
obcmd subscription list --status active --json | jq '.[].id'
```

## Discovery

You never have to read these docs to find a command:

```bash
obcmd describe --json              # the entire command tree, one call
obcmd subscription describe        # one resource
obcmd subscription create --help   # one command
obcmd subscription create --help --json   # machine-readable flags
```
