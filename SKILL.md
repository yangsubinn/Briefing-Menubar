---
name: briefing
description: >
  작업 복귀 브리핑 스킬. 자리를 비운 후 돌아오거나, 여러 작업을 병렬로 진행하다 맥락을 잃었을 때 "지금 나 뭐 하면 돼?", "뭐 하다 말았지?", "브리핑해줘", "어디까지 했어?", "복귀했어", "오늘 뭐 해야 해?", "연휴 끝났어", "뭐부터 시작하지?" 등의 말로 발동. 현재 git 상태, 열린 PR 리뷰 현황, 메모리 파일 기반 진행 중 작업 컨텍스트를 모아 한 번에 요약 브리핑한다. 꼭 이 스킬을 사용하여 브리핑을 수행할 것.
---

# 작업 복귀 브리핑

사용자가 돌아와서 지금 뭘 해야 할지 파악하고 싶을 때 쓰는 스킬. 흩어진 컨텍스트(git, PR, 메모리)를 한 번에 모아서 간결하게 보여준다.

## 브리핑 순서

아래 4단계를 순서대로 실행한 뒤, 결과를 **하나의 응답**으로 출력한다. 단계별로 중간 결과를 출력하지 말 것.

---

### 1단계: 메모리 읽기

`MEMORY.md`를 읽어서 진행 중인 프로젝트 메모리 파일 경로들을 파악한다.
그 중 `project_` prefix가 붙은 파일들(진행 중 작업)과 관련성 높은 파일들을 읽어 컨텍스트를 수집한다.

```bash
cat ~/.claude/projects/$(pwd | tr '/' '-' | sed 's/^-//')/memory/MEMORY.md
```

MEMORY.md에 명시된 "진행 상태" 관련 파일들도 읽을 것.

---

### 2단계: Git 상태 파악

```bash
# 현재 브랜치 및 미커밋 변경사항
git status --short
git branch --show-current

# 현재 브랜치의 최근 커밋 (최대 5개)
git log --oneline -5

# 로컬에 존재하는 내 작업 브랜치 목록 (feature/bryn/* 패턴)
git branch | grep "$(git config user.name | tr '[:upper:]' '[:lower:]' | cut -d' ' -f1)\|bryn" | head -10
```

브랜치명에서 티켓 ID를 추출한다 (예: `feature/bryn/GRW-271` → `GRW-271`).

---

### 3단계: GitHub PR 상태 조회

현재 레포의 origin URL에서 `owner/repo`를 추출한다:

```bash
git remote get-url origin
# 예: https://github.com/virtualcare/VirtualCare-iOS.git → virtualcare/VirtualCare-iOS
```

해당 레포에서만 내 오픈 PR을 조회한다:

```bash
gh pr list --repo <owner/repo> --author "@me" --state open --json number,title,url,commentsCount,isDraft
```

각 PR에 대해 리뷰 상세 정보를 조회한다:

```bash
gh pr view <number> -R <owner/repo> --json reviewDecision,reviews,reviewRequests,comments
```

reviews 배열에서:
- `state == "APPROVED"` → 승인 수
- `state == "CHANGES_REQUESTED"` → 변경 요청 수
- `state == "COMMENTED"` → 리뷰 코멘트 수

`reviewDecision`은 전체 승인 상태 (`APPROVED`, `CHANGES_REQUESTED`, `REVIEW_REQUIRED`, 또는 빈 문자열).

---

### 4단계: Linear 티켓 조회 (선택적)

2단계에서 추출한 티켓 ID들에 대해 Linear MCP로 제목 조회를 시도한다.
MCP가 인증되지 않았거나 실패하면 티켓 ID만 표시하고 넘어간다. 실패해도 브리핑 출력을 막지 말 것.

---

## 출력 형식

아래 형식으로 출력한다. 섹션이 비어있으면 해당 섹션은 생략한다.

```
## 📋 작업 브리핑

### 🔀 오픈 PR
| PR | 제목 | 상태 | 승인 | 코멘트 |
|---|---|---|---|---|
| [#N](url) | 제목 | ✅ 승인됨 / 🔄 리뷰 대기 / ⚠️ 변경 요청 / 📝 드래프트 | N명 | N개 |

### 🌿 현재 작업 브랜치
- `브랜치명` — 미커밋 변경사항 N개 파일
  - 최근 커밋: "커밋 메시지"
  - 관련 티켓: GRW-XXX (티켓 제목 — Linear 조회 성공 시)

### 📌 진행 중인 작업
(메모리에서 읽은 project_ 파일들 기반으로, 각 작업의 현재 상태와 다음 할 일을 1-2줄로 요약)

### ✅ 지금 뭐 하면 돼?
우선순위 순으로 1-3개 항목을 제시한다. 각 항목은 아래를 포함한다:
- 무엇을 해야 하는지 (파일명, 함수명 등 구체적인 대상)
- 어떻게 시작하면 되는지 (예: stash pop, 특정 메서드 수정 등)
- 왜 이게 지금 중요한지 또는 어디서 멈췄는지

항목 우선순위 기준:
1. PR에 변경 요청(CHANGES_REQUESTED)이 있으면 최우선
2. 승인은 됐지만 머지 안 된 PR
3. stash 보관 중인 진행 중 작업
4. 메모리 기반 미완료 작업
```

## 주의사항

- PR이 하나도 없으면 PR 섹션 생략
- git 명령이 실패하면 (git repo가 아닌 경우 등) 해당 섹션 생략
- Linear 조회 실패는 조용히 처리 — 에러 메시지를 브리핑에 포함하지 말 것
- 전체 출력은 스크롤 없이 볼 수 있게 간결하게. 항목당 1-2줄이 적당
- 한국어로 출력
