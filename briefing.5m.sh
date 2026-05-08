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
CHANGES=$(git status --short 2>/dev/null | grep -c '')
LAST_COMMIT=$(git log --oneline -1 2>/dev/null | cut -c 9-)
REPO_NAME=$(basename "$REPO_DIR")
OWNER_REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//')

# 메뉴바 타이틀
MENU_EMOJI=$(cat "$EMOJI_FILE" 2>/dev/null || echo "📋")
echo "$MENU_EMOJI"

echo "---"

# ── 섹션 0: 레포 & 브랜치 ─────────────────────────────
echo "$REPO_NAME · 🌿 $BRANCH"
[ "$CHANGES" -gt 0 ] && echo "-- 미커밋 변경사항 ${CHANGES}개 파일 | color=orange"
[ -n "$LAST_COMMIT" ] && echo "-- 최근 커밋: ${LAST_COMMIT:0:50} | color=gray"

echo "---"

# ── 섹션 1: GitHub ────────────────────────────────────
echo "GITHUB | color=#888888 size=11"
if [ -n "$OWNER_REPO" ]; then
  PR_LIST=$(gh pr list --repo "$OWNER_REPO" --author "@me" --state open --json number,title,url,isDraft 2>/dev/null)
  PR_COUNT=$(echo "$PR_LIST" | jq 'length' 2>/dev/null)

  if [ -n "$PR_COUNT" ] && [ "$PR_COUNT" -gt 0 ]; then
    while IFS= read -r row; do
      num=$(echo "$row" | jq -r '.number')
      title=$(echo "$row" | jq -r '.title' | cut -c1-40)
      url=$(echo "$row" | jq -r '.url')
      is_draft=$(echo "$row" | jq -r '.isDraft')

      rd=$(gh pr view "$num" -R "$OWNER_REPO" --json reviewDecision 2>/dev/null | jq -r '.reviewDecision')

      if [ "$is_draft" = "true" ]; then
        status="📝 Draft"
      elif [ "$rd" = "APPROVED" ]; then
        status="✅ Approved"
      elif [ "$rd" = "CHANGES_REQUESTED" ]; then
        status="⚠️ Changes Requested"
      else
        status="🔄 In Review"
      fi

      echo "$status  #$num · $title | href=$url"
    done < <(echo "$PR_LIST" | jq -c '.[]')
  else
    echo "오픈 PR 없음 | color=gray"
  fi
else
  echo "원격 저장소 없음 | color=gray"
fi

echo "---"

# ── 섹션 2: 진행 상황 ────────────────────────────────
echo "진행 상황 | color=#888888 size=11"
if [ -f "$CACHE_FILE" ]; then
  UPDATED=$(grep "^UPDATED:" "$CACHE_FILE" | sed 's/UPDATED://')
  CACHE_LINES=$(grep -v "^UPDATED:" "$CACHE_FILE" | grep -v '^$')

  if [ -n "$CACHE_LINES" ]; then
    while IFS= read -r line; do
      echo "$line | color=black"
    done <<< "$CACHE_LINES"
  else
    echo "캐시가 비어 있습니다 | color=gray"
  fi
else
  echo "캐시 없음 — 아래에서 갱신해주세요 | color=gray"
fi

echo "---"

# ── 섹션 3: 도움 ─────────────────────────────────────
echo "도움 | color=#888888 size=11"
CLAUDE_AVAILABLE=$(command -v claude &>/dev/null && echo "yes" || echo "no")
if [ "$CLAUDE_AVAILABLE" = "yes" ]; then
  echo "🤖 브리핑 실행하기 | bash=$HOME/.briefing_update.sh refresh=true terminal=false"
  echo "백그라운드 실행 — 결과 반영까지 약 1분 소요 | color=gray size=11"
  echo "💻 터미널 열기 | bash=$HOME/.briefing_open.sh terminal=false"
  echo "🔄 캐시 갱신 | bash=$HOME/.briefing_update.sh refresh=true terminal=false"
  echo "마지막 갱신: $UPDATED | color=gray size=11"
else
  echo "⚠️ Claude Code 미설치 — 브리핑 기능 비활성 | color=gray"
  echo "💻 터미널 열기 | bash=$HOME/.briefing_open.sh terminal=false"
fi

echo "---"

# ── 섹션 4: 설정 ─────────────────────────────────────
echo "설정 | color=#888888 size=11"
echo "🎨 메뉴바 이모지 변경"
for emoji in "📋" "🚀" "💻" "🎯" "⚡" "🔧" "🌟" "🎮" "🧑‍💻" "👩‍💻" "🐛" "🐟" "🍀" "👾" "👻" "🐰" "🐶" "🏠" "🍻" "📮" "💌"; do
  echo "-- $emoji | bash=/bin/sh param1=-c param2=\"printf '$emoji' > $EMOJI_FILE\" refresh=true terminal=false"
done
