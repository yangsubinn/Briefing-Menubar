# 📋 Briefing Menubar

Claude Code로 개발하는 사람들을 위한 macOS 메뉴바 위젯입니다.
현재 작업 브랜치, PR 상태, 진행 중인 작업과 다음 할 일을 메뉴바에서 바로 확인할 수 있습니다.

## 왜 만들었나요?

개발 중에 자리를 비우거나 다른 작업을 하다 돌아오면 "내가 뭐 하고 있었지?" 하는 순간이 생깁니다.
Claude Code의 브리핑 기능을 매번 직접 실행하는 대신, 메뉴바에 항상 요약된 상태를 띄워두고
필요할 때 터미널을 열어 더 자세한 브리핑을 받을 수 있도록 만들었습니다.

## 미리보기

```
📋 GRW-271                        ← 메뉴바 (현재 브랜치 티켓)
│
├── VirtualCare-iOS                ← 레포 이름 (gray)
├── 📁 GRW-271 Step2 stash 보관 중  ← 진행 중인 작업 (Claude 분석)
├── ✔️ stash pop 후 작업 재개        ← 지금 해야 할 일 (Claude 분석)
│
├── 🔀 오픈 PR (2개)
│   ├── ✅ #45 · [GRW-271] SettingConnect...
│   └── ⚠️ #43 · [GRW-256] SettingSection...
│
├── 🌿 feature/bryn/GRW-271
│   ├── 미커밋 변경사항 5개 파일
│   └── 최근 커밋: SettingConnectGroupUIModel 제거...
│
├── 🤖 터미널에서 브리핑 열기
├── 🔄 캐시 갱신
├── 🕖 갱신: 2026-05-05 14:00
│
└── 🎨 메뉴바 이모지 변경
    └── 📋 🚀 💻 🎯 ⚡ 🐟 🍀 👾 ...
```

## 동작 방식

| 항목 | 방식 | 설명 |
|---|---|---|
| 레포 이름 / 브랜치 / PR | 실시간 | `git`, `gh` CLI 직접 조회. Claude 불필요 |
| 진행 중인 작업 / 할 일 | 캐시 | Claude가 1시간마다 분석 후 저장 |
| 메뉴바 자동 갱신 | 5분마다 | SwiftBar가 스크립트 자동 실행 |

## 요구사항

- macOS
- [Homebrew](https://brew.sh)
- [Claude Code](https://claude.ai/code) (로그인 상태)
- `gh` CLI — GitHub 인증 완료 상태

나머지 의존성(`jq`, `SwiftBar`)은 `install.sh`가 자동으로 설치합니다.

## 설치

```bash
git clone https://github.com/bryn-yang/Briefing-Menubar.git
cd Briefing-Menubar
bash install.sh
```

설치 과정에서 아래 항목을 입력하거나 선택합니다:

1. **SwiftBar 플러그인 폴더 경로** — SwiftBar 앱 실행 후 지정한 폴더
2. **모니터링할 Git 레포 경로** — 브리핑을 받고 싶은 프로젝트 경로
3. **사용할 터미널 앱** — 설치된 터미널 중 선택 (iTerm2 / Warp / Terminal)

설치가 끝나면 SwiftBar에서 **Refresh All**을 눌러 위젯을 활성화하세요.

## 주요 기능

### 진행 중인 작업 & 할 일
Claude가 현재 브랜치, 미커밋 파일, stash 정보를 분석해서 가장 중요한 항목 하나씩 요약합니다.
1시간마다 자동 갱신되며, 드롭다운에서 **🔄 캐시 갱신**을 눌러 즉시 업데이트할 수 있습니다.

### 터미널에서 브리핑 열기
**🤖 터미널에서 브리핑 열기**를 클릭하면 설치 시 선택한 터미널이 열리면서
`claude -p 브리핑해줘`가 자동으로 실행됩니다. PR 코멘트, 메모리 파일 기반 상세 브리핑을 확인할 수 있습니다.

### PR 상태
현재 레포의 내 오픈 PR 목록과 리뷰 상태를 실시간으로 표시합니다.
- ✅ 승인됨
- ⚠️ 변경 요청
- 🔄 리뷰 대기
- 📝 드래프트

### 메뉴바 이모지 변경
드롭다운 하단 **🎨 메뉴바 이모지 변경**에서 원하는 이모지를 클릭하면 메뉴바 아이콘이 즉시 바뀝니다.

## 파일 구조

```
~/.briefing.env          # 설정 (레포 경로 등)
~/.briefing_cache.txt    # Claude 분석 캐시
~/.briefing_emoji        # 선택한 메뉴바 이모지
~/.briefing_update.sh    # 캐시 갱신 스크립트 (cron으로 1시간마다 실행)
~/.briefing_open.sh      # 터미널 열기 스크립트
```
