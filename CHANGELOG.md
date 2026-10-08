# CHANGELOG

## 0.2.0 -- 2026-10-08
- 스킬 `light-manual` 추가: 처음 만들 때·새 기능·사용 방법이 바뀔 때 `manual/` 사용설명서를 만들거나 고쳐
  같은 저장에 넣고, 저장 후 채팅에 그대로 보여 준다. "사용설명서 보여 줘"로 언제든 조회
- 규칙 11번(사용설명서), 작업 카드에 `설명서:` 줄, light-check 에 '설명서 따라 하기', light-save 저장 전 확인
- 규칙 12번: `light-*` 스킬과 규칙 블록은 프로젝트에서 고치지 않는다 (프로젝트 규칙은 블록 밖에)
- 기능 지도 템플릿에 `설명서` 칸 (이미 쓰던 FEATURES.md 는 설치기가 바꾸지 않는다 -- 다음 저장 때 AI가 칸을 더한다)
- 예시: my-homepage 에 사용설명서(`manual/`)와 사용 방법 변경 장면 추가

## 0.1.0 -- 2026-10-08
- 첫 공개: 스킬 5개(light-resume·start·check·save·undo), 규칙 10줄(AGENTS.md), 기록 템플릿 4장(dev-notes)
- 설치기: install.sh(macOS·Linux·Git Bash), install.ps1(Windows PowerShell), INSTALL.md(AI에게 설치 맡기기)
- 예시: 나만의 홈페이지 (메모 → 할 일 → 가계부, 확인 단계가 데이터 유실을 잡은 장면과 되돌리기 포함 -- 실제 수행 기록)
