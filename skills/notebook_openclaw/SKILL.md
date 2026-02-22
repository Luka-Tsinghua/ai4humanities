---
name: notebook_openclaw
description: (ZH/EN) 用 notebooklm-py 维护 OpenClaw 文档笔记本，并以 docs.openclaw.ai 英文站点为 source；用于 OpenClaw 配置变更前的“先查文档再改配置”。 / Maintain an OpenClaw documentation NotebookLM notebook via notebooklm-py using English docs.openclaw.ai sources, to ground OpenClaw config changes in documentation.
metadata: {"openclaw":{"emoji":"📚","title":"NotebookLM × OpenClaw (Docs-first)","homepage":"https://pypi.org/project/notebooklm-py/"}}
---

# NotebookLM × OpenClaw (Docs-first)

## 0) 免责声明与安全声明 / Disclaimer & Security (MUST READ)

**ZH（重要）**
- 本 skill 依赖 `notebooklm-py`（非 Google 官方），使用 **未公开/未文档化** 的 NotebookLM 接口，可能随时失效或被限流；使用风险自担。
- 本 skill 与 Google/NotebookLM/OpenClaw 及 `notebooklm-py` 维护者 **无任何隶属或背书关系**。
- `storage_state.json` 与任何浏览器 profile 目录（如 `browser_profile/`）等同“会话钥匙/cookie”。**绝对不要**提交到 Git、粘贴到 issue/日志/聊天，也不要截图泄露路径。怀疑泄露请立刻重新登录以轮换会话。

**EN (critical)**
- This skill depends on `notebooklm-py` (community / unofficial). It uses **undocumented** NotebookLM APIs and may break or be rate-limited without notice. Use at your own risk.
- Not affiliated with or endorsed by Google/NotebookLM/OpenClaw or the `notebooklm-py` maintainers.
- `storage_state.json` and any browser profile directory (e.g., `browser_profile/`) contains auth cookies/session state. Treat it like a password: **never commit**, paste, upload, or log it. Re-login if leakage is suspected.

---

## 1) 适用范围 / Scope

**ZH**
- 目标：维护一个 NotebookLM 笔记本（建议命名 `OpenClaw_Doc`），批量导入 `docs.openclaw.ai` 的英文页面，并用 `notebooklm ask` 在改 OpenClaw 配置前检索“正确的配置路径/字段名/CLI 语义”。

**EN**
- Goal: Maintain a NotebookLM notebook (recommended name `OpenClaw_Doc`) populated with English `docs.openclaw.ai` pages, so you can ask docs-first for exact config paths/field names/CLI semantics before editing OpenClaw.

---

## 2) 安装 / Install (aligned with notebooklm-py)

> 建议在虚拟环境中安装，避免污染系统 Python。 / Prefer a virtualenv to avoid polluting system Python.

### 2.1 Basic install
```bash
pip install -U notebooklm-py
```

### 2.2 Browser login support (recommended for first-time setup)
```bash
pip install -U "notebooklm-py[browser]"
playwright install chromium
```

### 2.3 Sanity check
```bash
notebooklm --help
```

---

## 3) 认证 / Authentication

### 3.1 Login (interactive)
```bash
notebooklm login
```

### 3.2 (Recommended) Isolate auth state per agent/user using NOTEBOOKLM_HOME

### 3.3 多平台登录策略 / Multi-platform login strategy

**ZH**
- `notebooklm login` 需要浏览器交互。若环境无 GUI（例如常见的 WSL2 headless / 纯 Linux server），请在有 GUI 的主机/机器上完成登录，然后 **安全复用** `NOTEBOOKLM_HOME` 下的 `storage_state.json` 到目标环境。
- WSL2（OpenClaw 安装在 WSL2）推荐：**Windows 主机侧登录 → WSL2 软链接复用**（README 有完整步骤）。

**EN**
- `notebooklm login` requires browser interaction. In headless environments (common WSL2 / Linux servers), complete login on a machine with a GUI browser, then securely reuse the `storage_state.json` under `NOTEBOOKLM_HOME`.
- For WSL2 (OpenClaw in WSL2), recommended: **login on Windows host → symlink reuse in WSL2** (see README).

**ZH**：避免多个 agent/多个账号互相覆盖凭据。  
**EN**: Avoid multiple agents/accounts clobbering each other.

```bash
export NOTEBOOKLM_HOME="$HOME/.notebooklm"
```

PowerShell:
```powershell
$env:NOTEBOOKLM_HOME = "$env:USERPROFILE\.notebooklm"
```

> ⚠️ 不要把 `$NOTEBOOKLM_HOME` 目录纳入 Git。 / Do not commit anything under `$NOTEBOOKLM_HOME`.

---

## 4) 创建并选择 OpenClaw_Doc / Create & select OpenClaw_Doc

```bash
notebooklm create "OpenClaw_Doc"
# Get the notebook id (see `notebooklm --help` for the list/show command in your version),
# then select it:
notebooklm use <NOTEBOOK_ID>
```

---

## 5) 批量导入 docs.openclaw.ai（英文）/ Bulk import English docs.openclaw.ai sources

OpenClaw skill docs recommend referencing the skill folder path as `{baseDir}`.

### 5.1 Fetch sitemap + build URL list (filter /zh-CN)
```bash
mkdir -p "{baseDir}/cache"
curl -fsSL https://docs.openclaw.ai/sitemap.xml > "{baseDir}/cache/oc_sitemap.xml"

python3 - <<'PY'
import re
from pathlib import Path
xml = Path("{baseDir}/cache/oc_sitemap.xml").read_text(encoding="utf-8", errors="ignore")
urls = re.findall(r"<loc>(.*?)</loc>", xml)
urls = [u.rstrip("/") for u in urls if "/zh-CN" not in u]
urls = sorted(set(urls))
Path("{baseDir}/cache/oc_urls.txt").write_text("\n".join(urls), encoding="utf-8")
print("URLs:", len(urls))
PY
```

### 5.2 Incremental import using a local ledger (open-source friendly; avoids CLI version drift)
```bash
mkdir -p "{baseDir}/state" "{baseDir}/reports"
touch "{baseDir}/state/ingested_urls.txt"

comm -13 <(sort "{baseDir}/state/ingested_urls.txt") <(sort "{baseDir}/cache/oc_urls.txt") \
  > "{baseDir}/cache/oc_urls_new.txt"

while read -r url; do
  [ -z "$url" ] && continue
  if notebooklm source add "$url" >/dev/null 2>&1; then
    echo "$url" >> "{baseDir}/state/ingested_urls.txt"
    echo "[OK] $url"
  else
    echo "[FAIL] $url" | tee -a "{baseDir}/reports/oc_import_fail.log"
  fi
  sleep 0.4
done < "{baseDir}/cache/oc_urls_new.txt"
```

---

## 6) 同步脚本 / Sync script

Use the bundled script:

- Path: `{baseDir}/tools/sync_openclaw_doc.sh`
- Output:
  - `{baseDir}/reports/openclaw_doc_sync_report.md`
  - `{baseDir}/reports/oc_sync_fail.log`

Run manually:
```bash
bash "{baseDir}/tools/sync_openclaw_doc.sh"
```

---

## 7) OpenClaw cron 示例 / OpenClaw cron example

```bash
openclaw cron add \
  --session isolated \
  --cron "0 5 * * 2" \
  --tz "Asia/Shanghai" \
  --description "Sync OpenClaw_Doc sources with docs.openclaw.ai (English only)" \
  --message "bash {baseDir}/tools/sync_openclaw_doc.sh" \
  --announce
```

List / Run:
```bash
openclaw cron list
openclaw cron run <JOB_ID>
```

---

## 8) “先查文档再改配置”工作纪律 / Docs-first discipline

**ZH**
1) 任何 OpenClaw 配置变更之前先问：  
   `notebooklm ask "..."`  
2) 从答案中提取“精确字段路径/默认值/注意事项”。  
3) 再用 OpenClaw 官方命令写入，例如 heartbeat：
```bash
openclaw config set agents.defaults.heartbeat.every "1h"
openclaw config set agents.defaults.heartbeat.target "last"
```

**EN**
1) Before any OpenClaw config change, ask the docs notebook.  
2) Extract exact paths/defaults/notes.  
3) Then apply via official OpenClaw commands, e.g. heartbeat:
```bash
openclaw config set agents.defaults.heartbeat.every "1h"
openclaw config set agents.defaults.heartbeat.target "last"
```

---

## 9) Git hygiene（强烈建议）/ Git hygiene (strongly recommended)

Add these to your repo `.gitignore`:

```gitignore
# NotebookLM auth/session (DO NOT COMMIT)
.notebooklm/
**/.notebooklm/
**/storage_state.json
**/browser_profile/

# Skill runtime files
skills/notebook_openclaw/cache/
skills/notebook_openclaw/state/
skills/notebook_openclaw/reports/
skills/notebook_openclaw/*.log
```
