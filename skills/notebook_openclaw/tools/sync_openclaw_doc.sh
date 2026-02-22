#!/usr/bin/env bash
set -euo pipefail

# ZH: 通过 sitemap 增量导入 docs.openclaw.ai 英文页面；生成同步报告。
# EN: Incrementally import English docs.openclaw.ai pages from sitemap; write a sync report.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE="$BASE_DIR/cache"
STATE="$BASE_DIR/state"
REPORTS="$BASE_DIR/reports"

mkdir -p "$CACHE" "$STATE" "$REPORTS"
touch "$STATE/ingested_urls.txt"

curl -fsSL https://docs.openclaw.ai/sitemap.xml > "$CACHE/oc_sitemap.xml"

python3 - <<PY
import re
from pathlib import Path

xml = Path("$CACHE/oc_sitemap.xml").read_text(encoding="utf-8", errors="ignore")
urls = re.findall(r"<loc>(.*?)</loc>", xml)
urls = [u.rstrip("/") for u in urls if "/zh-CN" not in u]
urls = sorted(set(urls))
Path("$CACHE/oc_urls.txt").write_text("\n".join(urls), encoding="utf-8")
print("URLs:", len(urls))
PY

comm -13 <(sort "$STATE/ingested_urls.txt") <(sort "$CACHE/oc_urls.txt") \
  > "$CACHE/oc_urls_new.txt"

added_ok=0
added_fail=0

while read -r url; do
  [ -z "$url" ] && continue
  if notebooklm source add "$url" >/dev/null 2>&1; then
    echo "$url" >> "$STATE/ingested_urls.txt"
    added_ok=$((added_ok+1))
    echo "[OK] $url"
  else
    added_fail=$((added_fail+1))
    echo "[FAIL] $url" | tee -a "$REPORTS/oc_sync_fail.log"
  fi
  sleep 0.4
done < "$CACHE/oc_urls_new.txt"

cat > "$REPORTS/openclaw_doc_sync_report.md" <<MD
# OpenClaw_Doc Sync Report

- Time: $(date -Is)
- Added OK: $added_ok
- Added FAIL: $added_fail
- New URL list: $CACHE/oc_urls_new.txt
- Fail log: $REPORTS/oc_sync_fail.log
MD
