#!/bin/bash
# briefing_context.sh
# 브리핑에 필요한 모든 컨텍스트를 수집해서 출력한다.
# Claude는 이 스크립트 결과를 받아 해석만 한다.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

ENV_FILE="$HOME/.briefing.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

if [ -z "$REPO_DIR" ]; then
  echo "[ERROR] REPO_DIR not set. Run install.sh first."
  exit 1
fi

cd "$REPO_DIR" || { echo "[ERROR] Cannot cd to $REPO_DIR"; exit 1; }

OWNER_REPO=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]//' | sed 's/\.git$//')

# ── Memory ──────────────────────────────────────────────────
echo "=== MEMORY ==="
MEMORY_DIR="$HOME/.claude/projects/$(pwd | tr '/' '-' | sed 's/^-//')/memory"
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  cat "$MEMORY_DIR/MEMORY.md"
  echo ""
  # project_ prefix 파일들 읽기
  for f in "$MEMORY_DIR"/project_*.md; do
    [ -f "$f" ] || continue
    echo "--- $(basename "$f") ---"
    cat "$f"
    echo ""
  done
else
  echo "(메모리 없음)"
fi

# ── Git 상태 ────────────────────────────────────────────────
echo ""
echo "=== GIT ==="
echo "BRANCH: $(git branch --show-current 2>/dev/null)"
echo ""
echo "STATUS:"
git status --short 2>/dev/null || echo "(없음)"
echo ""
echo "RECENT COMMITS (최근 5개):"
git log --oneline -5 2>/dev/null || echo "(없음)"
echo ""
echo "MY BRANCHES:"
git branch 2>/dev/null | grep -i "bryn\|$(git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | cut -d' ' -f1)" | head -10 || echo "(없음)"

# ── Stash ────────────────────────────────────────────────────
echo ""
echo "=== STASH ==="
STASH_LIST=$(git stash list 2>/dev/null)
if [ -n "$STASH_LIST" ]; then
  echo "$STASH_LIST"
else
  echo "(없음)"
fi

# ── GitHub PR ────────────────────────────────────────────────
echo ""
echo "=== GITHUB PR ==="
if [ -z "$OWNER_REPO" ]; then
  echo "(원격 저장소 없음)"
else
  PR_LIST=$(gh pr list --repo "$OWNER_REPO" --author "@me" --state open --json number,title,url,isDraft 2>/dev/null)
  PR_COUNT=$(echo "$PR_LIST" | jq 'length' 2>/dev/null)

  if [ -z "$PR_COUNT" ] || [ "$PR_COUNT" -eq 0 ]; then
    echo "(오픈 PR 없음)"
  else
    echo "$PR_LIST" | jq -c '.[]' | while IFS= read -r row; do
      num=$(echo "$row" | jq -r '.number')
      title=$(echo "$row" | jq -r '.title')
      url=$(echo "$row" | jq -r '.url')
      is_draft=$(echo "$row" | jq -r '.isDraft')

      detail=$(gh pr view "$num" -R "$OWNER_REPO" --json reviewDecision,reviews,comments 2>/dev/null)
      rd=$(echo "$detail" | jq -r '.reviewDecision')
      approved=$(echo "$detail" | jq '[.reviews[]? | select(.state=="APPROVED")] | length' 2>/dev/null)
      changes=$(echo "$detail" | jq '[.reviews[]? | select(.state=="CHANGES_REQUESTED")] | length' 2>/dev/null)
      comments=$(echo "$detail" | jq '.comments | length' 2>/dev/null)

      echo "PR #$num: $title"
      echo "  URL: $url"
      echo "  isDraft: $is_draft"
      echo "  reviewDecision: $rd"
      echo "  approved: $approved / changesRequested: $changes / comments: $comments"
    done
  fi
fi
