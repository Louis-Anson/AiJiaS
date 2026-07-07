#!/bin/bash
# merge-env.sh — merge old .env values into new .env.example templates
# Run from repo root: bash scripts/merge-env.sh
# Output: .env.new per project + list of NEW variables needing manual input

set -euo pipefail
BASE="${1:-/share/File/project/AiJiaS}"

MISSING=0

for dir in "${DIRS[@]}"; do
  old="$BASE/$dir/.env"
  tpl="$BASE/$dir/.env.example"
  new="$BASE/$dir/.env.new"

  [ -f "$old" ] || { echo "SKIP $dir: no .env"; continue; }
  [ -f "$tpl" ] || { echo "SKIP $dir: no .env.example"; continue; }

  echo ""
  echo "=== $dir ==="
  cp "$tpl" "$new"

  while IFS='=' read -r key _; do
    [ -z "$key" ] && continue
    [[ "$key" =~ ^# ]] && continue
    old_line=$(grep "^${key}=" "$old" 2>/dev/null | head -1) || true
    if [ -n "$old_line" ]; then
      old_val="${old_line#*=}"
      sed -i "s|^${key}=.*|${key}=${old_val}|" "$new"
    else
      echo "  🔴 NEW: $key=***       # <<< 需要手动填"
      MISSING=$((MISSING + 1))
    fi
  done < <(grep '=' "$tpl" | grep -v '^#')

  echo "  ✅ $new 已生成"
done

echo ""
echo "========================================="
echo " 共 $MISSING 个新增参数需要手动填写"
echo " 确认后批量改名："
echo '  for f in $(find . -name ".env.new"); do mv "$f" "$(dirname "$f")/.env"; done'
