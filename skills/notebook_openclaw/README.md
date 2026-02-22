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
  SKILL.md                # Skill entry (ZH/EN)
  README.md               # This file
  SECURITY.md             # Security policy (ZH/EN)
  gitignore.snippet       # Copy into repo root .gitignore
  tools/
    sync_openclaw_doc.sh  # Sitemap-based incremental importer + report generator
```

---

## Contributing

PRs are welcome, especially for:
- Better rate-limit handling / retry strategies
- More robust sitemap parsing
- Improved docs-first examples

**Rules**
- Never include credentials/cookies/session files in issues/PRs.
- Keep changes fully redacted and reproducible.

---

## License

Choose a license at the repo root (MIT/Apache-2.0 recommended).  
This skill is an integration recipe; upstream projects retain their own licenses.

---

## Credits

- `notebooklm-py` (community project): https://pypi.org/project/notebooklm-py/
- OpenClaw documentation: https://docs.openclaw.ai/
