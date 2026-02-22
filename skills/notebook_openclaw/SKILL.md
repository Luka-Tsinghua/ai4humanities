---
name: notebook_openclaw
description: Maintain an OpenClaw documentation NotebookLM notebook via notebooklm-py using English docs.openclaw.ai sources, to ground OpenClaw config changes in documentation (docs-first workflow).
metadata: {"openclaw":{"emoji":"📚","title":"NotebookLM × OpenClaw (Docs-first)","homepage":"https://github.com/teng-lin/notebooklm-py"}}
---

# NotebookLM × OpenClaw (Docs-first)

## Purpose

This skill builds and maintains a **searchable OpenClaw official-docs knowledge base** in Google NotebookLM, then uses it to enforce a workflow rule:

> Ask docs first → write config second.

This reduces misconfiguration risk caused by guessing config paths or blindly applying AI-generated patches.

## Dependencies

- Python + pip
- `notebooklm-py` (community project): https://github.com/teng-lin/notebooklm-py
- Optional (first-time login): Playwright Chromium
- OpenClaw CLI (for cron scheduling and applying configs)

## Security (critical)

NotebookLM authentication artifacts (e.g. `storage_state.json`, browser profile directories) contain session cookies/state.

Treat them like passwords:

- never commit
- never paste
- never upload

If leakage is suspected, re-run `notebooklm login` to rotate the session.

## Setup

### 1) Install

```bash
pip install -U notebooklm-py
```

First-time login (recommended):

```bash
pip install -U "notebooklm-py[browser]"
playwright install chromium
```

### 2) Login

```bash
notebooklm login
```

Auth state is stored in:

- `~/.notebooklm/storage_state.json` (Linux/macOS)
- On Windows: under your user profile `.notebooklm/`

Standardize with `NOTEBOOKLM_HOME` (recommended):

```bash
export NOTEBOOKLM_HOME="$HOME/.notebooklm"
```

PowerShell:

```powershell
$env:NOTEBOOKLM_HOME = "$env:USERPROFILE\.notebooklm"
```

### 3) Create notebook + set default context

```bash
notebooklm create "OpenClaw_Doc"
echo '{"notebook_id":"<NOTEBOOK_ID>"}' > ~/.notebooklm/context.json
```

### 4) Sync sources (English-only)

```bash
bash tools/sync_openclaw_doc.sh
```

The script fetches `docs.openclaw.ai/sitemap.xml`, keeps **English pages only** (currently implemented by excluding `/zh-CN` URLs), and incrementally adds new sources.

### 5) Optional: schedule sync via OpenClaw cron

```bash
openclaw cron add --name "notebook_openclaw" \
  --cron "0 5 * * 2" --tz "<YOUR_TIMEZONE>" \
  --description "Incrementally sync OpenClaw_Doc sources (English-only) from docs.openclaw.ai sitemap" \
  --message "bash {baseDir}/tools/sync_openclaw_doc.sh" --announce
```

## Operational workflow (docs-first)

When changing OpenClaw configs (heartbeat/channels/gateway):

1) Query `OpenClaw_Doc` via NotebookLM
2) Extract exact config keys/paths and defaults
3) Apply changes using OpenClaw’s CLI

Example query:

```bash
notebooklm ask "What is the exact config path for showing OK heartbeats in Feishu?" --json
```

Example config write (paths must match your doc query results):

```bash
openclaw config set channels.feishu.heartbeat.showOk true
```

## Troubleshooting (fast)

- Auth expired (401): re-run `notebooklm login` on a browser-capable machine, then re-check `notebooklm auth check --test --json`
- Sources not searchable: wait for ingest, then check `notebooklm source list --json` for `ready`
- Rate limits: increase the sleep interval in the sync script
