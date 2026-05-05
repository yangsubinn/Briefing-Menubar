#!/bin/bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

ENV_FILE="$HOME/.briefing.env"
CACHE_FILE="$HOME/.briefing_cache.txt"

[ -f "$ENV_FILE" ] && source "$ENV_FILE"

if [ -z "$REPO_DIR" ]; then
  echo "REPO_DIR not set. Run install.sh first." >&2
  exit 1
fi

cd "$REPO_DIR" || exit 1

GIT_BRANCH=$(git branch --show-current 2>/dev/null)
GIT_STATUS=$(git status --short 2>/dev/null | head -10)
STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

PROMPT="아래 컨텍스트를 바탕으로 가장 최근/중요한 진행 중인 작업 1개와 지금 바로 해야 할 일 1개만 정리해줘.

[브랜치]: $GIT_BRANCH
[미커밋 파일]:
$GIT_STATUS
[stash 개수]: $STASH_COUNT

출력 형식 — 딱 2줄만, 마크다운/헤더/부연설명 없이:
📁 [가장 중요한 진행 중인 작업 한줄, 40자 이내]
✔️ [지금 바로 해야 할 일 한줄, 40자 이내]"

OUTPUT=$(claude -p "$PROMPT" 2>/dev/null)

{
  echo "UPDATED:$(date '+%Y-%m-%d %H:%M')"
  echo "$OUTPUT"
} > "$CACHE_FILE"
