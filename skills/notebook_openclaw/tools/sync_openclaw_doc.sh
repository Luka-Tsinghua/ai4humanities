#!/usr/bin/env bash
set -euo pipefail

# Incrementally import OpenClaw official docs (English pages only) into NotebookLM.
# - Source of truth: https://docs.openclaw.ai/sitemap.xml
# - English-only rule: exclude non-English routes (currently implemented by dropping URLs containing "/zh-CN")
# - Writes a sync report under ./reports/

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[ERROR] Missing required command: $1" >&2
    exit 1
  }
}

require_cmd curl
require_cmd python3
require_cmd notebooklm

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$BASE_DIR/cache"
STATE="$BASE_DIR/state"
REPORTS="$BASE_DIR/reports"

mkdir -p "$CACHE" "$STATE" "$REPORTS"
touch "$STATE/ingested_urls.txt"

# Sanity check: ensure a default notebook context exists (recommended).
if [ ! -f "${HOME}/.notebooklm/context.json" ]; then
  echo "[WARN] ${HOME}/.notebooklm/context.json not found."
  echo "       If you did not set a default notebook_id, run:"
  echo "         notebooklm create "OpenClaw_Doc""
  echo "         echo '{"notebook_id":"<NOTEBOOK_ID>"}' > ~/.notebooklm/context.json"
fi

curl -fsSL https://docs.openclaw.ai/sitemap.xml > "$CACHE/oc_sitemap.xml"

python3 - <<PY
import re
from pathlib import Path

xml = Path("$CACHE/oc_sitemap.xml").read_text(encoding="utf-8", errors="ignore")
urls = re.findall(r"<loc>(.*?)</loc>", xml)

# English-only: exclude non-English routes (currently /zh-CN)
urls = [u.rstrip("/") for u in urls if "/zh-CN" not in u]

urls = sorted(set(urls))
Path("$CACHE/oc_urls.txt").write_text("\n".join(urls), encoding="utf-8")
print("URLs (English-only):", len(urls))
PY

# Compute new URLs not yet ingested
comm -13 <(sort "$STATE/ingested_urls.txt") <(sort "$CACHE/oc_urls.txt") > "$CACHE/oc_urls_new.txt" || true

added_ok=0
added_fail=0
new_total="$(wc -l < "$CACHE/oc_urls_new.txt" | tr -d ' ')"

while read -r url; do
  [ -z "$url" ] && continue
  if notebooklm source add "$url" >/dev/null 2>&1; then
    echo "$url" >> "$STATE/ingested_urls.txt"
    added_ok=$((added_ok+1))
    echo "[OK] $url"
  else
    added_fail=$((added_fail+1))
    echo "[FAIL] $url" | tee -a "$REPORTS/oc_sync_fail.log" >/dev/null
  fi
  # Throttle to reduce rate-limit risk
  sleep 0.4
done < "$CACHE/oc_urls_new.txt"

cat > "$REPORTS/openclaw_doc_sync_report.md" <<MD
# OpenClaw_Doc Sync Report

- Time: $(date -Is)
- English-only rule: exclude URLs containing "/zh-CN"
- New URLs detected: $new_total
- Added OK: $added_ok
- Added FAIL: $added_fail
- New URL list: $CACHE/oc_urls_new.txt
- Fail log: $REPORTS/oc_sync_fail.log
MD
