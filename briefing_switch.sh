#!/bin/bash
# briefing_switch.sh <repo_path>
# 추적 레포를 전환하고 최근 목록을 업데이트한다.

NEW_REPO="$1"
ENV_FILE="$HOME/.briefing.env"
REPOS_FILE="$HOME/.briefing_repos.txt"

[ -z "$NEW_REPO" ] && exit 1

# REPO_DIR 업데이트
if grep -q "^REPO_DIR=" "$ENV_FILE" 2>/dev/null; then
  sed -i '' "s|^REPO_DIR=.*|REPO_DIR=$NEW_REPO|" "$ENV_FILE"
else
  echo "REPO_DIR=$NEW_REPO" >> "$ENV_FILE"
fi

# 최근 목록 업데이트 (최신 우선, 중복 제거, 최대 5개)
TEMP=$(mktemp)
echo "$NEW_REPO" > "$TEMP"
[ -f "$REPOS_FILE" ] && grep -v "^${NEW_REPO}$" "$REPOS_FILE" | head -4 >> "$TEMP"
mv "$TEMP" "$REPOS_FILE"

# SwiftBar 전체 갱신
open -g "swiftbar://refreshallplugins"
