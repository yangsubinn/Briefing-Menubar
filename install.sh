#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "📋 Briefing Menubar — 설치 시작"
echo "================================"
echo ""

# ── 의존성 확인 ──────────────────────────────────────
echo "🔍 의존성 확인 중..."

if ! command -v brew &>/dev/null; then
  echo -e "${RED}✗ Homebrew가 설치되어 있지 않습니다.${NC}"
  echo "  https://brew.sh 에서 설치 후 다시 실행해주세요."
  exit 1
fi
echo -e "${GREEN}✓ Homebrew${NC}"

if ! command -v gh &>/dev/null; then
  echo -e "${YELLOW}! gh CLI가 없습니다. 설치합니다...${NC}"
  brew install gh
fi
echo -e "${GREEN}✓ gh CLI${NC}"

if ! command -v jq &>/dev/null; then
  echo -e "${YELLOW}! jq가 없습니다. 설치합니다...${NC}"
  brew install jq
fi
echo -e "${GREEN}✓ jq${NC}"

CLAUDE_PATH=$(which claude 2>/dev/null || echo "")
CLAUDE_AVAILABLE=false
if [ -z "$CLAUDE_PATH" ]; then
  echo -e "${YELLOW}! claude CLI를 찾을 수 없습니다. Claude 브리핑 기능은 비활성화됩니다.${NC}"
  echo "  설치 후 기능을 사용하려면: https://claude.ai/code"
else
  CLAUDE_AVAILABLE=true
  echo -e "${GREEN}✓ claude CLI ($CLAUDE_PATH)${NC}"
fi

if ! [ -d "/Applications/SwiftBar.app" ]; then
  echo -e "${YELLOW}! SwiftBar가 없습니다. 설치합니다...${NC}"
  brew install --cask swiftbar
  echo -e "${GREEN}✓ SwiftBar 설치 완료 — 앱을 실행하고 플러그인 폴더를 지정해주세요.${NC}"
  open /Applications/SwiftBar.app
  echo ""
  read -rp "SwiftBar 플러그인 폴더 지정 후 Enter를 눌러주세요..."
fi
echo -e "${GREEN}✓ SwiftBar${NC}"

echo ""

# ── 설정 입력 ──────────────────────────────────────
echo "⚙️  설정"
echo ""

read -rp "SwiftBar 플러그인 폴더 경로: " PLUGIN_DIR
PLUGIN_DIR="${PLUGIN_DIR/#\~/$HOME}"
if [ ! -d "$PLUGIN_DIR" ]; then
  echo -e "${RED}✗ 폴더가 존재하지 않습니다: $PLUGIN_DIR${NC}"
  exit 1
fi

read -rp "모니터링할 Git 레포 경로: " REPO_DIR
REPO_DIR="${REPO_DIR/#\~/$HOME}"
if [ ! -d "$REPO_DIR/.git" ]; then
  echo -e "${RED}✗ Git 레포가 아닙니다: $REPO_DIR${NC}"
  exit 1
fi

echo ""

# ── 설정 파일 저장 ────────────────────────────────────
ENV_FILE="$HOME/.briefing.env"
cat > "$ENV_FILE" <<EOF
REPO_DIR=$REPO_DIR
CLAUDE_PATH=$CLAUDE_PATH
EOF
echo -e "${GREEN}✓ 설정 저장: $ENV_FILE${NC}"

# ── 스크립트 복사 ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/briefing_update.sh" "$HOME/.briefing_update.sh"
chmod +x "$HOME/.briefing_update.sh"
echo -e "${GREEN}✓ ~/.briefing_update.sh 복사 완료${NC}"

cp "$SCRIPT_DIR/briefing_context.sh" "$HOME/.briefing_context.sh"
chmod +x "$HOME/.briefing_context.sh"
echo -e "${GREEN}✓ ~/.briefing_context.sh 복사 완료${NC}"

# 브리핑 스킬 설치 (Claude Code 있을 때만)
if [ "$CLAUDE_AVAILABLE" = true ]; then
  SKILL_DIR="$HOME/.claude/skills/briefing"
  mkdir -p "$SKILL_DIR"
  cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
  echo -e "${GREEN}✓ 브리핑 스킬 설치 완료 (~/.claude/skills/briefing/)${NC}"
fi

# ── 터미널 앱 선택 ───────────────────────────────────
echo "🖥️  사용할 터미널 앱을 선택해주세요:"
TERMINAL_OPTIONS=()
[ -d "/Applications/iTerm.app" ]            && TERMINAL_OPTIONS+=("iTerm2")
[ -d "/Applications/Warp.app" ]             && TERMINAL_OPTIONS+=("Warp")
[ -d "/System/Applications/Utilities/Terminal.app" ] && TERMINAL_OPTIONS+=("Terminal")

if [ ${#TERMINAL_OPTIONS[@]} -eq 0 ]; then
  TERMINAL_OPTIONS+=("Terminal")
fi

for i in "${!TERMINAL_OPTIONS[@]}"; do
  echo "  $((i+1)). ${TERMINAL_OPTIONS[$i]}"
done

read -rp "번호 입력 (기본값: 1): " TERMINAL_CHOICE
TERMINAL_CHOICE="${TERMINAL_CHOICE:-1}"
SELECTED_TERMINAL="${TERMINAL_OPTIONS[$((TERMINAL_CHOICE-1))]}"
echo -e "${GREEN}✓ 터미널: $SELECTED_TERMINAL${NC}"
echo ""

# 선택된 터미널에 맞게 열기 스크립트 생성
OPEN_SCRIPT="$HOME/.briefing_open.sh"
case "$SELECTED_TERMINAL" in
  iTerm2)
    cat > "$OPEN_SCRIPT" <<'EOF'
#!/bin/bash
osascript -e 'tell application "iTerm" to create window with default profile command "claude -p 브리핑해줘"'
EOF
    ;;
  Warp)
    cat > "$OPEN_SCRIPT" <<'EOF'
#!/bin/bash
osascript -e 'tell application "Warp" to activate'
sleep 0.5
osascript -e 'tell application "System Events" to keystroke "t" using command down'
sleep 0.3
osascript -e 'tell application "System Events" to keystroke "claude -p 브리핑해줘"'
osascript -e 'tell application "System Events" to key code 36'
EOF
    ;;
  *)
    cat > "$OPEN_SCRIPT" <<'EOF'
#!/bin/bash
osascript -e 'tell application "Terminal" to do script "claude -p 브리핑해줘"'
osascript -e 'tell application "Terminal" to activate'
EOF
    ;;
esac
chmod +x "$OPEN_SCRIPT"
echo -e "${GREEN}✓ ~/.briefing_open.sh 생성 완료 ($SELECTED_TERMINAL)${NC}"

cp "$SCRIPT_DIR/briefing.5m.sh" "$PLUGIN_DIR/briefing.5m.sh"
chmod +x "$PLUGIN_DIR/briefing.5m.sh"
echo -e "${GREEN}✓ SwiftBar 플러그인 복사 완료${NC}"

# ── cron 등록 (Claude Code 있을 때만) ────────────────
if [ "$CLAUDE_AVAILABLE" = true ]; then
  CRON_JOB="0 * * * * $HOME/.briefing_update.sh >> /tmp/briefing_update.log 2>&1"
  if crontab -l 2>/dev/null | grep -q ".briefing_update.sh"; then
    echo -e "${YELLOW}! cron이 이미 등록되어 있습니다. 건너뜁니다.${NC}"
  else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo -e "${GREEN}✓ cron 등록 완료 (매 정시 자동 갱신)${NC}"
  fi

  # ── 초기 캐시 생성 ──────────────────────────────────
  echo ""
  echo "🤖 초기 캐시 생성 중... (30초~1분 소요)"
  "$HOME/.briefing_update.sh"
  echo -e "${GREEN}✓ 캐시 생성 완료${NC}"
else
  echo -e "${YELLOW}! Claude Code 미설치 — 브리핑 기능은 Claude Code 설치 후 사용 가능합니다.${NC}"
fi

echo ""
echo "================================"
echo -e "${GREEN}✅ 설치 완료!${NC}"
echo ""
echo "SwiftBar에서 'Refresh All'을 눌러 위젯을 활성화하세요."
echo ""
