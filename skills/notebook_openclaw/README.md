# NotebookLM × OpenClaw (Docs-first) — `notebook_openclaw`

[English](README.md) · [Chinese](README_ZH.md)

<p align="center">
  <b>Stop guessing OpenClaw config paths.</b><br/>
  Build a searchable OpenClaw docs knowledge base in NotebookLM, then enforce <i>docs-first</i> changes.
</p>

<p align="center">
  <a href="https://github.com/teng-lin/notebooklm-py"><img alt="notebooklm-py" src="https://img.shields.io/badge/notebooklm--py-community-blue"></a>
  <a href="https://docs.openclaw.ai/"><img alt="OpenClaw Docs" src="https://img.shields.io/badge/OpenClaw-docs-green"></a>
  <img alt="English-only" src="https://img.shields.io/badge/sources-English--only-success">
  <img alt="Security" src="https://img.shields.io/badge/security-no%20secrets%20in%20git-critical">
</p>

---

## Why this exists

When you use OpenClaw day-to-day, you eventually hit questions like:

- “What’s the *exact* config path for heartbeat?”
- “Which CLI arguments does this gateway command actually accept?”
- “What are the defaults for a new feature?”

Throwing raw demands at an AI agent is a great way to **silently write the wrong key** and **break your gateway**. ❌

OpenClaw’s direction is explicit (from `VISION.md` in the official GitHub repo):

> Long term, we want easier onboarding flows as hardening matures.  
> We do not want convenience wrappers that hide critical security decisions from users.

**AI agents are not wish machines.** 🤖  
If you want them to behave, give them (1) constraints *and* (2) a fast, searchable **official-docs knowledge base**.

That’s what this skill does.

---

## What this skill does

- Creates/uses a NotebookLM notebook (recommended name: `OpenClaw_Doc`)
- Imports OpenClaw docs from `docs.openclaw.ai` via sitemap
- Keeps **English pages only** (excludes non-English routes such as `/zh-CN`)
- Provides an incremental sync script: `tools/sync_openclaw_doc.sh`
- Optionally schedules automatic sync via OpenClaw cron
- Promotes a strict workflow: **ask docs first → then write config**

---

## Security (read this)

NotebookLM auth state is stored in `storage_state.json` (and sometimes a browser profile directory). Treat it like a password:

- **Never commit** it to git
- **Never paste** it into issues/chats
- **Never upload** it to public storage

This folder includes `gitignore.snippet` to help you block sensitive files.

---

## Quickstart

### 1) Install `notebooklm-py`

```bash
pip install -U notebooklm-py
```

First-time login (recommended):

```bash
pip install -U "notebooklm-py[browser]"
playwright install chromium
```

### 2) Login (requires a browser)

```bash
notebooklm login
```

Auth is stored under:

- `~/.notebooklm/storage_state.json` (Linux/macOS)
- On Windows: under your user profile `.notebooklm/` (path varies)

**Recommended:** standardize with `NOTEBOOKLM_HOME`

Linux/macOS:

```bash
export NOTEBOOKLM_HOME="$HOME/.notebooklm"
```

PowerShell:

```powershell
$env:NOTEBOOKLM_HOME = "$env:USERPROFILE\.notebooklm"
```

---

## WSL2 (Windows + WSL2 only): cross-OS auth reuse

WSL2 is often **headless** (no GUI browser), so OAuth login cannot complete inside WSL2.

**Solution:** login on Windows → reuse auth in WSL2 via symlink.

1) On Windows (PowerShell):

```powershell
notebooklm login
```

2) In WSL2:

```bash
mkdir -p ~/.notebooklm
ln -sf /mnt/c/Users/<YOUR_WINDOWS_USER>/.notebooklm/storage_state.json ~/.notebooklm/storage_state.json
notebooklm auth check --test --json
```

If auth expires: re-run `notebooklm login` on Windows. WSL2 will pick up the updated file via the symlink.

---

## Create the docs notebook + import sources (English-only)

Create a notebook:

```bash
notebooklm create "OpenClaw_Doc"
```

Set default context:

```bash
echo '{"notebook_id":"<NOTEBOOK_ID>"}' > ~/.notebooklm/context.json
```

Sync sources:

```bash
bash tools/sync_openclaw_doc.sh
```

---

## Schedule automatic sync (recommended)

OpenClaw docs evolve. Keep your NotebookLM knowledge base aligned via **incremental** sync:

```bash
openclaw cron add --name "notebook_openclaw" \
  --cron "0 5 * * 2" --tz "<YOUR_TIMEZONE>" \
  --description "Incrementally sync OpenClaw_Doc sources (English-only) from docs.openclaw.ai sitemap" \
  --message "bash {baseDir}/tools/sync_openclaw_doc.sh" --announce
```

Manual validation run:

```bash
openclaw cron run --name "notebook_openclaw"
```

Operational notes:

- Weekly is usually enough (avoid unnecessary rate-limit pain)
- Prefer idempotent, incremental updates (add missing, log failures)
- Keep reports; don’t trust “it ran” without evidence

---

## Docs-first querying

Fast query:

```bash
notebooklm ask "How to configure Feishu heartbeat? Provide exact config paths and defaults." --json
```

Markdown output:

```bash
notebooklm ask "Explain heartbeat configuration and defaults" --format markdown
```

---

## Practical example: hourly heartbeat + show `heartbeat_OK`

Important detail: **`heartbeat_OK` is often not displayed by default** (to reduce noise).  
If you want visible “OK/healthy” heartbeats, you must explicitly enable “show OK” behavior.

✅ Discipline:

1) Agent **asks docs first** (NotebookLM)
2) Agent writes config **only after confirming the exact path**
3) Apply/reload as required

Example (Feishu channel):

```bash
openclaw config set agents.defaults.heartbeat.every "1h"
openclaw config set agents.defaults.heartbeat.target "feishu"

# IMPORTANT: make OK heartbeats visible (default is typically false)
openclaw config set channels.feishu.heartbeat.showOk true
```

---

## Folder layout

```text
skills/notebook_openclaw/
  README.md
  README_ZH.md
  SKILL.md
  SECURITY.md
  INSTALL_NOTES.md
  gitignore.snippet
  tools/
    sync_openclaw_doc.sh
```

---

## Disclaimers

- `notebooklm-py` is a community / unofficial project, and may break without notice.
- This skill is not affiliated with Google, NotebookLM, OpenClaw, or the `notebooklm-py` maintainers.
- You are responsible for complying with platform terms and respecting rate limits.
