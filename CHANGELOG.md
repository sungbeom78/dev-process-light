# CHANGELOG

## 0.12.3 -- 2026-10-18
- 짝 스킬 data-light 를 **0.6.3** (data-expert-framework-light `3c7a9ec`) 으로 -- `view` 의 모든 보기에 표시 상한, 되돌리기 경쟁 수정. 정본 형식·명령은 그대로

## 0.12.2 -- 2026-10-18
- 짝 스킬 data-light 를 **0.6.2** (data-expert-framework-light `7361f26`) 으로 -- `view` 첫 화면 즉시·큰 모델 그리기 상한. 정본 형식·명령은 그대로

## 0.12.1 -- 2026-10-17
- 짝 스킬 data-light 를 **0.6.1** (data-expert-framework-light `92a4340`) 으로 -- 웹 ERD 그림(`view`)의 뷰어 사본 갱신:
  관계를 따라 선이 덜 엇갈리는 자동 배치(계산 1초 상한), 표 고정·되돌리기·초기화, 표를 누르면 설명, 설명으로 찾기, '내 화면에만' 위치.
  위치 파일은 2판(0.6.0 파일도 그대로 읽음). 정본 형식·명령은 그대로

## 0.12.0 -- 2026-10-17
- 짝 스킬 data-light 를 **0.6.0** (data-expert-framework-light `9008720`) 으로 -- 웹 ERD 그림 `datalight.py view` (보기 전용, MIT 사본).
  `light-start` 4: 표가 여럿이면 사용자와 웹 그림을 띄워 함께 보고, 옮긴 위치 파일(`data/model.light.json.layout.json`)도 저장

## 0.11.0 -- 2026-10-17
- 짝 스킬 data-light 를 **0.5.0** (data-expert-framework-light `c77bb7c`, 태그 `v0.5.0`) 으로 (소유자 결정 2026-10-17 "올려").
  0.4.1(이 저장소의 0.10 3차 요청 V1~V6)과 0.5.0(만드는 것 `product`)이 함께 들어온다.
- **만드는 것(`product`)을 정본에** -- 0.5.0 부터 정본에 `product` 가 없으면 `verify` 가 **유형 미정**으로 실패한다.
  `light-start` 4: 사용자가 이미 말한 "무엇을 만드나"(처음 답·카드)를 `kinds`(설계까지·파일 넣기·데이터 관리·분석)와 `said`(**말 그대로**)로 옮기고,
  여럿이면 주 목적을 한 번 묻는다(`main`·`main_said`), 말한 것이 없으면 한 번 묻는다. `analyze` 면 성공 기준이 있어야 한다.
  `light-resume` 3: 새 kit 로 올린 예전 프로젝트에서 `verify` 가 유형 미정이면 기록에 있는 사용자 말을 옮기거나 한 번 묻는다.
  `light-check`: `said` 가 사용자 말 그대로인지, 유형 미정을 AI 가 혼자 채우지 않는지
- 0.10.1 임시 조치를 걷어 냄: 훅을 이 컴퓨터의 sh 가 못 읽는 문제는 data-light `hook install` 이 스스로 확인한다(`sh -n`, 못 읽으면 우리 블록을 빼고 알림) --
  `light-start` 5·`light-resume`·`light-check` 의 손 확인 지시와 `test_install.sh` 의 0.4.0 예외를 지움 (이제 못 읽으면 시험 실패).
  "표마다 샘플 행 하나 이상"(0.4.1 V4 로 고쳐짐), "`split --write` 뒤 `pi_` 에 access 를 손으로"(V2 로 옮겨 줌) 지시도 지움
- `access` 두 개 목록: 게시판 `["read", "own"]` · 공지 `["read", "members"]` (V3) -- `light-start` 4 의 "정본만으로 못 적어 읽기 규칙을 손으로" 를 이것으로 바꿈
- `light-portal` 데이터 메뉴에 **만드는 것**(종류·주 목적·사용자 말)과 두 개 목록 `access`("읽기 누구나 · 쓰기 만든 사람만"). `check_kit.py` 가 확인
- 예시 `club-dues`: 정본에 `product`(처음 답 그대로) 를 더하고 `data/out` 을 0.5.0 으로 다시 만듦 (Supabase SQL 의 가입·익명 로그인 안내가 늘어남)

## 0.10.1 -- 2026-10-15
- **macOS 에서 짝 data-light 0.4.0 의 검사 장치가 모든 저장을 막는 문제**에 대한 임시 조치. 0.4.0 의 pre-commit 훅은 `$( … )` 안에
  `case` 를 쓰는데, macOS 의 `/bin/sh`(bash 3.2)는 이것을 읽지 못해(`syntax error near unexpected token ';;'`) 정본과 상관없이 모든 커밋이 멈춘다.
  0.10.0 의 CI 가 macOS 두 곳에서 실패해 알았고, 소스에서 빌드한 bash 3.2.57 로 재현했다. 원본에 고칠 방법(패턴 앞에 `(` -- bash 3.2·dash·bash 5 에서 확인)과 함께 요청했다
  - `light-start` 5: `hook install` 뒤 `sh -n <훅>` 으로 이 컴퓨터의 sh 가 훅을 읽는지 확인. `syntax error` 면 사용자에게 알리고 우리 블록만 빼고
    `안 함 (이 컴퓨터의 sh 가 훅을 못 읽음 -- 짝 버전이 오르면 다시)`, 그동안 `light-check` 가 `verify` 를 직접. `light-resume`·`light-check` 도 같은 확인
  - `light-start` 4: 표마다 샘플 행 하나 이상 (샘플도 필수 칸도 없는 표는 0.4.0 의 `verify` 가 SQL 오류로 실패 -- 원본에 요청)
  - `test_install.sh`: 설치된 훅을 이 컴퓨터의 sh 가 못 읽고 짝 버전이 0.4.0 이면 알려진 문제로 적고 훅을 거치는 저장 시험만 건너뜀
    (짝 버전이 바뀌면 이 예외는 저절로 없어진다). 전체를 bash 3.2 로 돌려도 설치는 통과

## 0.10.0 -- 2026-10-15
- 짝 스킬 data-light 를 **0.4.0** (data-expert-framework-light `2ad0c15`, 태그 `v0.4.0`) 으로. 0.9 가 원본에 요청한 U1~U8 이 반영되어
  light 쪽 임시 지시를 걷어 냈다 (원본 기능은 이 저장소에서 다시 실행해 확인):
  - **누가 볼 수 있나를 정본에**: `"signup": "open"|"closed"`, 표마다 `"access": "members"|"own"|"read"`, 칸 자료형 `"type": "owner"`
    (Supabase 에서 `uuid NOT NULL DEFAULT auth.uid()`) → `build --db postgresql` 이 실제 규칙(`CREATE POLICY`)을 만든다.
    `members` 는 `signup: closed` 일 때만 `check` 통과, `pi_` 표는 `read` 금지, `pi_` 의 `own` 은 짝 표의 주인을 따른다.
    → `light-start` 4에 "누가 쓰나 → 정본" 표(정해진 사람끼리 · 아무나 가입 · 누구나 보는 목록). 6의 Supabase 는 "틀을 골라 손으로 실행" 대신
    "정본대로 만든 SQL 을, 새 가입을 끈 것을 확인한 뒤에 적용"으로. `owner_id` 칸을 따로 더하던 SQL 우회와 `light-check` 의 코드 이름 예외를 지움.
    `signup: closed` 는 약속일 뿐이라 Supabase 의 가입 설정은 사용자에게 확인받는다 (`light-check`). 손으로 쓴 틀이 남는 경우만 `data/supabase-policies.sql`
  - **정본 밖에 둘 표** `"outside": ["log"]` -- 데이터가 든 표도 `verify` 의 데이터 보호 검사에서 뺄 수 있다 → "비어 있는 표만" 제한을 지우고,
    `light-check` 의 "정본에서 빠졌습니다"와 `light-undo` 의 선택지에 "설계 밖에 두기"(데이터 유지)를 더함
  - `import apply` 는 정본이 PostgreSQL 이면 백업 전에 멈춘다 (`--force-sqlite` 는 쓰지 않는다), Supabase 는 Table Editor 의 CSV 가져오기로.
    `import schema` 가 개인정보로 보이는 칸을 `확인:` 줄로 알린다 → AI 가 혼자 표시하던 것을 "사용자에게 묻고 `personal`" 로
  - 검사 장치: 한글 경로의 정본·`out/` 만 바뀐 저장도 검사, 설치된 예제(`.claude/skills`·`.agents/skills`)는 건너뜀, 다른 훅 뒤에 덧붙인
    블록이 그 뒤 내용을 끊지 않음(괄호로 감싸고 `# data-light end`), git worktree·`core.hooksPath` 위치 표시 -- light 쪽 지시는 그대로
  - `split --write` 는 `access` 를 `pi_` 표로 옮겨 주지 않는다 -- 나눈 뒤 `pi_` 표에도 `access` 를 적으라고 `light-start` 에 적음 (원본에 요청)
- `light-portal` 데이터 메뉴가 누가 볼 수 있나(`signup`)·표마다 쓰는 사람(`access`, Supabase 인데 없으면 "규칙 없음")·정본 밖에 둔 표·`owner` 자료형을 보여 준다.
  `check_kit.py` 가 이것을 페이지에 담는지 확인
- 독립 검토 반영 (0.4.0 동작은 검토자가 Supabase 역할을 흉내 낸 PostgreSQL 에서 `own`·`read`·`members` 를 실제로 시험):
  - **가입을 끈 사이트의 계정 만들기** -- 계정은 사용자가 Supabase 의 Authentication → Users → Add user(만들기·초대)로, 사이트에는 로그인 화면만
    (가입 화면·`signUp` 없음), 사람을 더할 때도 가입을 켜지 않는다. 안내가 없으면 가입을 잠깐 켜는 길로 빠져 `members` 규칙이 모두에게 열린다
  - 익명 로그인("Allow anonymous sign-ins")도 꺼졌는지 확인 -- 익명 사용자도 로그인한 사람으로 친다. 보안 점검의 익명 로그인 경고도 0 이어야
  - "누구나 읽고 쓰기는 자기 것만·임원만" 은 `access` 하나로 못 적는다 -- 쓰는 쪽을 정본에, 읽기 규칙은 `data/supabase-policies.sql` 에 손으로.
    `pi_` 표의 `access` 는 짝 표와 같게(짝 표가 `read` 면 `own` 또는 비워 두기), `read` 표는 사이트에서 쓸 수 없다
  - Supabase 에 CSV 넣기: 자동 번호 칸은 넣을 수 없어 본 표 → 매겨진 번호 확인 → 그 번호로 `pi_` CSV 순서
  - `light-undo`: 설계가 걸린 되돌리기는 `git revert --no-commit` 바로 다음에 `verify` -- 기록을 고친 뒤 막혀 `--abort` 하면 고친 기록도 지워진다
  - 이미 있는 DB: 정본 밖에 둘 표는 초안의 `tables` 에서 빼고 `outside` 에 (둘 다 있으면 `check` 가 막는다)
  - `light-resume`: 손으로 고른 틀을 정본으로 옮길 때 규칙 이름이 같아 대개 다시 실행할 것이 없음, 비어도 되는 `owner_id` 를 바꿀지 묻기,
    `data/supabase-policies.sql` 에는 정본으로 못 옮긴 것만
  - 기록 보기 페이지: `signup` 없이 `own`·`read` 만 있을 때 "아무 표도 못 씁니다" 라고 하던 것, `outside` 가 글자 하나씩 나뉘던 것, 알 수 없는 `access` 값 표시를 고침.
    "쓰는 사람" 은 Supabase 정본에서만
- `light-resume` "다시 설치한 뒤": 손으로 고른 Supabase 틀로 남긴 예전 결정을 정본의 `signup`·`access`·`owner` 로 옮기는 카드를 제안
- README 에 "누가 볼 수 있나도 정본에"
- 예시 `examples/club-dues` 를 0.4.0 으로 다시 수행 -- 임원 셋만: `signup: closed` + 세 표 `access: members`, `schema.sql` 에 실제 규칙 3개,
  `split` 뒤 `pi_member` 에 `access` 를 직접 적는 단계까지

## 0.9.0 -- 2026-10-15
- 짝 스킬 data-light 를 **0.3.0** (data-expert-framework-light `e84d857`, 태그 `v0.3.0`) 으로. 0.8 이 원본에 요청한 A1~C3 가 반영되어
  light 쪽 임시 지시를 걷어 냈다:
  - 가져오기: `import plan` 이 계획을 `data/import_plan.json` 에, 경로는 프로젝트 기준으로, 개인정보 칸 값은 가려 적는다 → AI 가 `"file"` 을 고치던 지시 삭제
  - `.gitignore` 데이터 줄은 `hook install` 이 넣는다 (장치를 안 깔면 AI 가 같은 줄을 넣는다)
  - Supabase: `build --db postgresql` 이 모든 표에 RLS 를 켜고 규칙 틀을 단다 → light 는 "누가 쓰나" 답으로 틀을 고르고, 생성물은 고치지 않고
    Supabase 에서 따로 실행, 고른 것을 결정 기록에 (`pi_` 의 정해진 사람끼리 틀·`owner_id` 칸은 아직 없어 안내)
  - 두 칸을 묶은 중복 금지 `"unique": [[…]]` 를 정본에 -- 화면 코드에 맡기던 것을 정본으로
  - 이미 있는 SQLite 는 `import schema` 가 정본 초안을 만든다 (`확인:` 줄은 사용자와)
  - 검사 장치: `hook status`(설치된 훅·도구 사본 버전) -- `light-resume`·`light-check` 가 이것으로 판단하고 버전이 다르거나 없을 때만 `hook install`.
    `light-start` 는 인터넷 저장소에 올리지 않는 프로젝트에 `--no-ci`(도구가 기억), 다른 훅이 있으면 사용자에게 묻고 `--append`.
    `core.hooksPath` 는 도구가 따른다. 올리기로 정하면 `light-save` 가 GitHub 검사를 켤지(`--ci`) 한 번 묻는다
  - 훅이 "python 을 찾지 못해 검사를 건너뜁니다" 를 내면 검사되지 않은 저장으로 보고 (`light-save`·`light-check`)
- 독립 검토(0.3.0 연동) 반영:
  - **정해진 사람끼리의 Supabase 규칙은 새 가입을 꺼야만 안전** -- 끈 것을 확인한 뒤에만 그 틀(과 `pi_` 표에 같은 틀), 아니면 `pi_` 는 본인·관리자만.
    실행한 규칙 SQL 은 `data/supabase-policies.sql` 에 저장, `schema.sql` 의 "주석을 지우고" 는 SQL 편집기에 붙여 넣은 다음의 일, 이미 만든
    Supabase 에는 바뀐 부분만 실행. 보안 점검은 RLS·키 경고 0
  - `import apply` 는 SQLite 에만 넣는다 -- Supabase·브라우저 저장 프로젝트에서는 쓰지 않는다 (실제 값만 남는 파일을 만들지 않게), 확인 뒤 계획의 `approved`
  - 이미 있는 DB: 정본 밖에 둘 수 있는 것은 **비어 있는 표만** (데이터가 든 표를 빼면 `verify` 가 계속 막는다), 초안에 개인정보 표시는 AI 가 하고 옮기기는 확인 후
  - 브라우저 저장이면 같은 값·묶음 중복 금지도 화면 코드의 완료 기준으로, 백업(내보내기)은 만든다고 알리고 기준에
  - "다시 설치한 뒤": `훅: 없음`·"이미 있어 건드리지 않았습니다"(core.hooksPath) 처리, GitHub 검사 파일이 없으면 `--no-ci`(지운 것을 되살리지 않음),
    생성물은 장치 결과와 상관없이 늘 다시 만들고 verify, 예전 한계로 남긴 결정은 정본으로 옮길지 제안
  - `git add` 는 있는 경로만, 데이터 저장에 `.gitignore`·`data/supabase-policies.sql`, 코드 이름 검사의 예외(`owner_id` 처럼 결정 기록에 적힌 칸),
    `datalight.py` 는 스킬 경로로 부른다(`.data-light/` 사본은 커밋 검사용)
  - 기록 보기 페이지가 표의 묶음 중복 금지를 보여 준다
- `light-resume` "다시 설치한 뒤": 새 도구로 `build` 하기 전에는 `verify`·(검사 파일이 있으면) GitHub 검사가 실패한다는 것과, 바뀐 생성물(예: RLS)을
  이미 만든 DB 에도 적용할지 따로 묻는 것을 적음 (0.8 → 0.9 로 올린 Supabase 프로젝트는 `schema.sql` 에 RLS 줄이 더해진다)
- `check_kit.py`: `datalight.py --version` 이 잠금 파일의 버전과 같은지. `test_install.sh`: 예전 검사 장치(버전 줄 없는 훅) → `hook status` 다름 →
  `hook install --no-ci` → 최신 → 정본 저장이 훅을 통과하고 망가진 정본은 막히는지
- 예시 `examples/club-dues` 를 0.3.0 으로 다시 수행 (묶음 중복 금지, `hook install --no-ci`·`hook status`)

## 0.8.1 -- 2026-10-14
- 짝 스킬 data-light 를 **0.2.1** (data-expert-framework-light `828c5ba`, 태그 `v0.2.1`) 로. 0.2.1 은 0.8.0 이 담은 `cbbd258`
  (Windows·Python 3.9 수정)에 릴리스 이름을 붙인 것이라 `kit/skills/data-light` 의 파일은 그대로이고 잠금 파일의 커밋·버전만 바뀐다.
  원본은 "0.2.0(태그 `v0.2.0` = `a11aca3`)은 Windows·Python 3.9 에서 일부 기능이 실패하니 0.2.1 을 쓰라"고 안내한다 -- dev-process-light 는
  0.8.0 부터 이미 고친 코드를 담아 왔으므로 설치된 프로젝트는 할 일이 없다 (다시 설치하면 버전 표시만 바뀐다)

## 0.8.0 -- 2026-10-14
- **짝 스킬 `data-light`** ([data-expert-framework-light](https://github.com/sungbeom78/data-expert-framework-light) 0.2.0, `cbbd258`) --
  dev-process-framework ↔ data-expert-framework 처럼 가벼운 판도 짝을 맞춘다. 저장할 데이터가 생기면 데이터부터 설계하고 돌아온다
  - 함께 설치: `kit/skills/data-light` 에 원본 커밋을 **바이트 그대로** 담는다 (ZIP·파일 직접 만들기 설치에서도 빠지지 않게 서브모듈 대신 사본).
    `data-light.lock.json`(저장소·커밋·버전·파일 해시), `scripts/update_data_light.py`(`--ref`·`--from`·`--check`·`--upstream`),
    `.gitattributes` 로 줄바꿈 변환 막음. CI 가 원본 저장소의 그 커밋과 대조한다
  - 규칙 12 **데이터부터** (표가 이어짐·여럿이 로그인·엑셀/CSV·개인정보 → `data-light` 로 정본 `data/model.light.json` 을 먼저 확인받음,
    DB 만들기·바꾸기·지우기·파일 넣기는 확인 후). 예전 규칙 12(고치지 않음)는 13 으로, `data-light` 도 고치지 않는다
  - **질문은 한 번만**: `NOW.md` "이 프로젝트는" 아래 다섯 줄(누가 쓰나·로그인·올리는 곳·저장하는 데이터·개인정보)을 light 스킬과
    data-light 가 같이 쓴다. 이미 답이 있으면 묻지 않고, 새로 물은 답은 그 줄과 `DECISIONS.md` 양쪽에
  - 작업 카드 `데이터:` 줄(없음·브라우저에만·새 표·표 바꿈·읽기만), `FEATURES.md` "데이터 (표)" 절(표 → 쓰는 기능 -- 표를 바꾸면 모두 점검),
    `NAMES.md` 는 데이터 이름을 옮겨 적지 않고 정본의 이름표를 따른다(브라우저 저장 이름은 적는다)
  - `light-start` 넘겨주기 순서 -- 카드·할 일에서 이미 정한 것은 data-light 의 성공 기준(`goals`)·만들지 않을 것(`not_doing`)으로 옮겨 적고 다시 묻지 않음,
    데이터 검사 장치(`datalight.py hook install`: 정본이 바뀐 저장은 `verify` 통과해야)를 처음 한 번 묻고 `## 설정` 에
  - `light-check` 데이터 확인은 `verify` 한 관문(설계 검사·성공 기준·규칙 시험·생성물·데이터 보호) + 처음엔 `--mutate`, 코드 이름·Supabase·올리면 안 되는 것 ·
    `light-save` 저장 종류 `데이터:`·데이터 기록(`dev-notes/log/데이터/`)·장치가 멈추면 `--no-verify` 금지 · `light-undo` 설계를 되돌려도 DB 는 그대로임을 먼저 알림·백업 ·
    `light-resume` 데이터 한 줄·짝 스킬과 검사 장치 설치 확인·예전 프로젝트 칸 채우기 · `light-manual` "데이터는 어디에" 페이지
  - `light-portal` **데이터** 메뉴: 성공 기준·이번엔 안 할 것·표·칸(이름표·자료형·필수·개인정보)·표 사이 연결·쓰는 기능·관계 그림/정의서 바로 가기.
    구조만 담고 샘플 값·기대 결과는 담지 않는다.
    '지금' 의 기능 수가 데이터 절의 줄까지 세던 것을 고침
  - 설치기: 짝 스킬 버전을 알리고, 검사 장치의 도구 사본(`.data-light/datalight.py`)이 있으면 짝 버전으로 맞추고, 파이썬이 없으면 무엇이 안 되는지 알림.
    `data/` 는 건드리지 않는다
  - 예시 [`examples/club-dues/`](examples/club-dues/WALKTHROUGH.md): 동아리 회비 사이트 1단계(데이터 설계)를 실제로 수행한 기록.
    `check_kit.py` 가 예시의 정본·생성물·기록(다섯 줄·데이터 절·흐름)을 실제 도구로 검사한다
  - **실제로 어디에 저장하나**: 누가 쓰나·올리는 곳으로 정한다 (혼자·정적 호스팅 → 브라우저 저장소, 내 컴퓨터만 → SQLite + 작은 서버,
    여럿이 로그인 → Supabase). 설계는 어느 경우든 data-light. 브라우저 저장이면 규칙(필수·선택값)은 화면 코드의 완료 기준으로
  - **Supabase 보안**: 모든 표에 행 접근 규칙(RLS)과 규칙(policy), 보안 점검(Security Advisor), 코드에는 공개용 키만·관리자 키(service_role)는 절대 안 됨 (규칙 8)
  - **실제 값은 올리지 않는다**: 샘플·기대 결과는 만든 값, 가져오기 계획(`import_plan*.json` -- 실제 값이 들어 있다)을 `.gitignore` 에,
    가져올 파일은 `data/` 안에서 상대 경로로
  - **데이터가 걸린 되돌리기**: 빠지는 표·칸에 데이터가 있는지 먼저 보고 고르게 한다(설계에 남기기 / 백업 후 빼기 / 취소).
    `verify` 의 "정본에서 빠졌습니다" 는 AI 가 혼자 고치지 않는다 (`light-check`)
  - **이미 DB 가 있는 프로젝트**: 있는 표·칸을 읽어 정본을 만들고 실제 DB 와 비교해 확인받는다
  - **다시 설치한 뒤**(`light-resume`): 설치로 바뀐 파일만 있으면 묻지 않고 맞춘다 -- 검사 장치 다시 설치, `build`·`verify`, `정리:` 저장
- 기록 보기 페이지를 처음 만들 때 `.gitignore` 에 넣은 줄이 저장되지 않고 남던 문제: 첫 저장 전에 만들고(`light-resume`), 그 뒤에 생기면 바로 저장(`light-save`)
- `install.ps1` 을 BOM 이 있는 UTF-8 로 (Windows PowerShell 5.1 에서 한글이 깨지지 않게, `check_kit.py` 가 확인). 설치기는 파이썬을 실제로 실행해 보고
  찾는다 (Windows 의 가짜 python3 를 건너뜀)
- CI: Python 3.9·3.12 × Ubuntu·Windows·macOS. `check_kit.py` 는 데이터 도구를 cp1252 파이프로 돌려 한글이 깨지지 않는지, README 의 짝 버전·커밋이 잠금 파일과 같은지 본다

## 0.7.0 -- 2026-10-11
- **작업 기록 세 층** -- 기록이 많아져도 AI 가 전부 읽지 않게: ① 흐름 `dev-notes/LOG.md` (단계·**기능**·무엇을·결과·누가 한 줄)
  ② `dev-notes/log/<기능>/<날짜>.md` 의 `## 목록` ③ 같은 파일 `## 자세히`. 지난 일은 ①→②→③ 순서로 필요한 것만 읽는다
- 단계: 기획 · 만들기 · 확인 · 운영 · 평가 (+ 준비 · 결정 · 되돌리기). 자세히: 만들기는 고친 파일·클래스·함수·변수,
  확인은 한 일·결과(통과·실패·확인 못 함)·오류·해결, 운영은 관련 기획·파일·한 일·결과·오류, 평가는 좋았던 점·불편한 점·다음 할 일
- 지난달 흐름은 `dev-notes/log/_흐름/<연-월>.md`. 기록 보기 페이지: 기능 고르기, 흐름 줄을 누르면 그 기능·날짜 파일, '기능별 기록' 메뉴

## 0.6.0 -- 2026-10-11
- **작업 기록** `dev-notes/LOG.md`: 단계(준비·합의·만들기·확인·저장·되돌리기·문제·결정·배움)가 끝날 때마다 한 줄
  (언제 · 단계 · 무엇을 · 결과 · 누가). 300줄이 넘으면 달별로 `dev-notes/log/`. 비밀번호·키·개인정보는 적지 않는다
- **단계마다 저장**: 합의·만들기 한 덩어리마다 `중간 저장:`, 확인 뒤 `기능:` 등. 인터넷 저장소에 올리기(push)는 처음 한 번 묻고
  `NOW.md` `## 설정` 에 적은 대로
- **결정 기록에 누가 정했는지**: `[사용자]` 답 그대로 / `[AI]` 이유와 다른 안. AI 가 고른 기술은 사용자에게 한두 줄로 알려 준다
- 새 스킬 `light-portal`: 기록을 한 화면에서 보는 HTML 파일 하나 (서버·로그인 없음). 위치는 처음에 묻는다(추천 `dev-notes/portal.html`),
  `.gitignore` 에 넣고 저장할 때마다 다시 만든다
- 규칙 5 를 "단계마다 기록하고 저장한다"로. 예전 버전 프로젝트는 `light-resume` 이 `LOG.md`·`## 설정` 을 채운다

## 0.5.0 -- 2026-10-10
- 규칙 6 · light-check: "3번 실패하면 멈춤" 대신 **원인별 처리** -- 내 수정 탓이면 고쳐서 재확인(3번 안 되면 다른 방법),
  잠깐의 오류면 30초·2분·10분 기다렸다 다시, 다른 서비스·사용자 조치가 필요하면 할 일을 말하고 기다림,
  모두 안 되면 되돌리기 / 기능 빼기 / 나중에 할 일로 적기 중 사용자가 고른다. 덮어두고 넘어가지 않는다
- 원인을 먼저 알아본다(오류·상태·최근 변경·데이터·검색), 같은 방법 연달아 금지, 플랜 B 2번·기다리기 3번까지,
  다른 서비스 문제는 지켜보기·부탁·(묻고) 직접 고치기
- 설명서 검토: 터미널 상자가 줄어들어 글이 잘리던 문제 수정(`flex-shrink: 0`), `review` 가 상자 안 잘림도 잡는다

## 0.4.0 -- 2026-10-08
- 사용설명서 완성도 바닥선: 목차 6쪽·기능 장 5쪽 이상(표지·흐름·단계마다 한 쪽), 따라 하기 페이지에 화면 흉내·캡처,
  순서도 칸마다 설명, 대본 60자 이상 -- `manual_tool.py check` 가 잡는다
- `manual_tool.py review`: 모든 페이지를 그려 글 넘침·제목 겹침을 찾고 장별 미리보기 그림(`.manual-review/`)을 만든다.
  기록(`manual/.review.json`)이 있으면 그 뒤 바뀌었는지도 확인
- 그림 부품 추가(터미널·레인·계층·타임라인·체크리스트·배지), 템플릿을 바닥선에 맞게 확장, 예시 설명서 보강

## 0.3.0 -- 2026-10-08
- 사용설명서 형식: Markdown → **HTML 슬라이드** (웹페이지 기본, 페이지 = 16:9 한 장 = pptx 한 장)
  - 글보다 그림(순서도·화면 흉내·카드·비교), 한 단계 = 한 페이지, 페이지마다 강의 대본(유튜브 녹화용)
  - 발표 모드(P)·대본(N)·16:9 인쇄, 외부 주소 없이 동작 (`assets/manual.css`, `manual.js`)
  - `templates/`(목차·기능 장), `manual_tool.py`(check · outline · pptx)
- 예시: my-homepage 설명서를 HTML 슬라이드 4장(26쪽)으로 다시 만듦

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
