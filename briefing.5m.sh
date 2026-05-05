#!/bin/bash

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

ENV_FILE="$HOME/.briefing.env"
CACHE_FILE="$HOME/.briefing_cache.txt"
EMOJI_FILE="$HOME/.briefing_emoji"

[ -f "$ENV_FILE" ] && source "$ENV_FILE"

if [ -z "$REPO_DIR" ]; then
  echo "⚠️ 설정 필요"
  echo "---"
  echo "install.sh를 먼저 실행해주세요 | color=red"
  exit 1
fi

cd "$REPO_DIR" || { echo "❌ No Repo"; exit 1; }

BRANCH=$(git branch --show-current 2>/dev/null)
TICKET=$(echo "$BRANCH" | grep -oE '[A-Z]+-[0-9]+' | head -1)
CHANGES=$(git status --short 2>/dev/null | grep -c '')

# 메뉴바 타이틀
MENU_EMOJI=$(cat "$EMOJI_FILE" 2>/dev/null || echo "📋")
if [ -n "$TICKET" ]; then
  echo "$MENU_EMOJI $TICKET"
else
  echo "$MENU_EMOJI 브리핑"
fi

echo "---"

# ── 레포 이름 ─────────────────────────────────────────
REPO_NAME=$(basename "$REPO_DIR")
echo "$REPO_NAME | color=gray size=11"

# ── 진행 중 작업 & 할 일 (캐시) ──────────────────────
if [ -f "$CACHE_FILE" ]; then
  UPDATED=$(grep "^UPDATED:" "$CACHE_FILE" | sed 's/UPDATED://')

  while IFS= read -r line; do
    [[ "$line" == UPDATED:* ]] && continue
    [ -z "$line" ] && continue
    echo "$line | color=black"
  done < "$CACHE_FILE"
else
  echo "⚠️ 캐시 없음 — 아래에서 갱신해주세요 | color=gray"
fi

echo "---"

# ── 오픈 PR ──────────────────────────────────────────
OWNER_REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//')

if [ -n "$OWNER_REPO" ]; then
  PR_LIST=$(gh pr list --repo "$OWNER_REPO" --author "@me" --state open --json number,title,url,isDraft 2>/dev/null)
  PR_COUNT=$(echo "$PR_LIST" | jq 'length' 2>/dev/null)

  if [ -n "$PR_COUNT" ] && [ "$PR_COUNT" -gt 0 ]; then
    echo "🔀 오픈 PR (${PR_COUNT}개)"

    while IFS= read -r row; do
      num=$(echo "$row" | jq -r '.number')
      title=$(echo "$row" | jq -r '.title' | cut -c1-40)
      url=$(echo "$row" | jq -r '.url')
      is_draft=$(echo "$row" | jq -r '.isDraft')

      rd=$(gh pr view "$num" -R "$OWNER_REPO" --json reviewDecision 2>/dev/null | jq -r '.reviewDecision')

      if [ "$is_draft" = "true" ]; then
        status="📝"
      elif [ "$rd" = "APPROVED" ]; then
        status="✅"
      elif [ "$rd" = "CHANGES_REQUESTED" ]; then
        status="⚠️"
      else
        status="🔄"
      fi

      echo "-- $status #$num · $title | href=$url"
    done < <(echo "$PR_LIST" | jq -c '.[]')

    echo "---"
  fi
fi

# ── 현재 브랜치 ───────────────────────────────────────
echo "🌿 $BRANCH"
[ "$CHANGES" -gt 0 ] && echo "-- 미커밋 변경사항 ${CHANGES}개 파일"
LAST_COMMIT=$(git log --oneline -1 2>/dev/null | cut -c 9-)
[ -n "$LAST_COMMIT" ] && echo "-- 최근 커밋: ${LAST_COMMIT:0:45}"

echo "---"

# ── 액션 ─────────────────────────────────────────────
echo "🤖 브리핑 실행하기 | bash=$HOME/.briefing_update.sh refresh=true terminal=false"
echo "-- ⏱ 백그라운드 실행 — 결과 반영까지 약 1분 소요 | color=gray"
echo "💻 터미널 열기 | bash=$HOME/.briefing_open.sh terminal=false"
echo "🔄 캐시 갱신 | bash=$HOME/.briefing_update.sh refresh=true terminal=false"
echo "🕖 갱신: $UPDATED | color=gray size=11"
echo "---"
echo "🎨 메뉴바 이모지 변경"
for emoji in "📋" "🚀" "💻" "🎯" "⚡" "🔧" "🌟" "🎮" "🧑‍💻" "🐛" "🐟" "🍀" "👾" "👻" "🐰" "🐶" "🏠" "🍻" "📮" "💌"; do
  echo "-- $emoji | bash=/bin/sh param1=-c param2=\"printf '$emoji' > $EMOJI_FILE\" refresh=true terminal=false"
done
