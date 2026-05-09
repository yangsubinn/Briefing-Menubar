#!/bin/bash
# briefing_add.sh
# 폴더 선택 다이얼로그로 새 레포를 추가한다.

SELECTED=$(osascript -e 'set p to POSIX path of (choose folder with prompt "추가할 Git 레포 폴더를 선택해주세요")' 2>/dev/null)

[ -z "$SELECTED" ] && exit 0

# trailing slash 제거
SELECTED="${SELECTED%/}"

# git repo 확인
if [ ! -d "$SELECTED/.git" ]; then
  osascript -e "display dialog \"선택한 폴더가 Git 레포가 아닙니다.\" buttons {\"확인\"} default button 1" 2>/dev/null
  exit 1
fi

bash "$HOME/.briefing_switch.sh" "$SELECTED"
