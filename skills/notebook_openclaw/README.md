# NotebookLM × OpenClaw (Docs-first)

<p align="center">
  <b>Docs-first automation:</b> continuously sync OpenClaw docs into a NotebookLM notebook, then enforce “ask docs before changing configs”.
</p>

<p align="center">
  <a href="https://pypi.org/project/notebooklm-py/"><img alt="PyPI" src="https://img.shields.io/badge/notebooklm--py-PyPI-blue"></a>
  <a href="https://docs.openclaw.ai/"><img alt="OpenClaw Docs" src="https://img.shields.io/badge/OpenClaw-docs-green"></a>
  <img alt="Status" src="https://img.shields.io/badge/status-stable-brightgreen">
  <img alt="Security" src="https://img.shields.io/badge/security-no%20secrets%20in%20git-critical">
</p>

---

## 简介（ZH）

这个 skill 做两件事：

1. **把 OpenClaw 官方英文文档持续同步进 NotebookLM**（建议建一个笔记本：`OpenClaw_Doc`）。
2. **把“改配置前先查文档”变成可执行纪律**：先 `notebooklm ask` 找到准确字段路径/语义，再用 OpenClaw 官方 CLI 写入配置。

它适合：你在用 OpenClaw/Agent 做运维、自动化、配置治理，但又不想靠猜字段、猜默认值。

---

## Overview (EN)

This skill does two things:

1. **Continuously syncs OpenClaw English docs into a NotebookLM notebook** (recommended notebook name: `OpenClaw_Doc`).
2. Enforces a **docs-first discipline**: `notebooklm ask` to confirm exact config paths/semantics *before* applying changes via OpenClaw’s official CLI.

Use it when you want less guesswork and more evidence-backed configuration changes.

---

## ⚠️ Disclaimer & Security（必读 / MUST READ）

### Unofficial integration
- This skill depends on `notebooklm-py`, a **community / unofficial** project, and may break or be rate-limited without notice.  
  Upstream: https://pypi.org/project/notebooklm-py/

### Not affiliated
- Not affiliated with or endorsed by Google/NotebookLM/OpenClaw or the `notebooklm-py` maintainers.

### Sensitive files (DO NOT COMMIT)
- `storage_state.json` and any browser profile directory (e.g., `browser_profile/`) contain auth cookies/session state.  
  Treat them like a password: **never commit**, paste, upload, or log them.

> ✅ This repo includes a `gitignore.snippet` to help you block these files.

---

## Platform notes: login & auth state (multi-OS)

NotebookLM login is **browser-interactive**. Whether you can run `notebooklm login` directly depends on whether your environment has a usable browser UI.

### Strategy matrix / 策略矩阵

| Environment | Recommended login method | Auth state location | Notes |
|---|---|---|---|
| macOS (OpenClaw native) | Run `notebooklm login` locally | `$NOTEBOOKLM_HOME/storage_state.json` | Works with a GUI browser |
| Linux desktop (OpenClaw native) | Run `notebooklm login` locally | `$NOTEBOOKLM_HOME/storage_state.json` | Needs a GUI browser |
| Windows (OpenClaw native) | Run `notebooklm login` in PowerShell | `%NOTEBOOKLM_HOME%\storage_state.json` | Works with default browser |
| WSL2 headless (OpenClaw in WSL2) | **Reuse host auth** (Windows → WSL2) | Link/copy to `~/.notebooklm/storage_state.json` | Recommended when WSL2 has no GUI |
| Linux server / headless | Login on a GUI machine, then securely copy auth state | `$NOTEBOOKLM_HOME/storage_state.json` | Treat as secret; strict permissions |

### Standardize auth storage with NOTEBOOKLM_HOME
**ZH**：建议统一用 `NOTEBOOKLM_HOME`，便于迁移/复用/隔离不同账号。  
**EN**: Use `NOTEBOOKLM_HOME` to isolate and move auth state safely.

Linux/macOS:
```bash
export NOTEBOOKLM_HOME="$HOME/.notebooklm"
```

PowerShell:
```powershell
$env:NOTEBOOKLM_HOME = "$env:USERPROFILE\.notebooklm"
```

---

## WSL2 (headless) auth reuse: Windows → WSL2

**Why**: WSL2 is commonly headless and cannot finish a browser OAuth flow inside the distro.

**Steps**
1) Login on Windows:
```powershell
notebooklm login
```

2) In WSL2, link the auth state:
```bash
mkdir -p ~/.notebooklm
ln -sf /mnt/c/Users/<YOUR_WINDOWS_USER>/.notebooklm/storage_state.json ~/.notebooklm/storage_state.json
```

3) Verify:
```bash
notebooklm auth check --test --json
```

> If `auth check` shows 401/expired: re-run `notebooklm login` on Windows, then re-check in WSL2.

---

## Quickstart

### 1) Install notebooklm-py

> Prefer a virtualenv to avoid polluting system Python.

```bash
pip install -U notebooklm-py
```

For first-time login (recommended):
```bash
pip install -U "notebooklm-py[browser]"
playwright install chromium
```

### 2) Login

```bash
notebooklm login
```

### 3) Create and select the docs notebook

```bash
notebooklm create "OpenClaw_Doc"
notebooklm use <NOTEBOOK_ID>
```

> How to get `<NOTEBOOK_ID>` depends on your `notebooklm` CLI version. Use `notebooklm --help` to find the relevant list/show command.

### 4) Sync OpenClaw docs (English only)

```bash
bash tools/sync_openclaw_doc.sh
```

Artifacts:
- `reports/openclaw_doc_sync_report.md`
- `reports/oc_sync_fail.log`

### 5) Docs-first config change (example)

```bash
notebooklm ask "What is the documented config path for heartbeat cadence and target in OpenClaw?"
openclaw config set agents.defaults.heartbeat.every "1h"
openclaw config set agents.defaults.heartbeat.target "last"
```

---

## Automation (OpenClaw cron)

Schedule weekly sync:

```bash
openclaw cron add   --session isolated   --cron "0 5 * * 2"   --tz "Asia/Shanghai"   --description "Sync OpenClaw_Doc sources with docs.openclaw.ai (English only)"   --message "bash {baseDir}/tools/sync_openclaw_doc.sh"   --announce
```

---

## Repo layout

```text
skills/notebook_openclaw/
  SKILL.md
  README.md
  SECURITY.md
  gitignore.snippet
  INSTALL_NOTES.md
  tools/
    sync_openclaw_doc.sh
```

---

## License

Choose a license at the repo root (MIT/Apache-2.0 recommended).  
This skill is an integration recipe; upstream projects retain their own licenses.
