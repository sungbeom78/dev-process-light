# AI에게 설치를 맡길 때 (AI가 읽는 문서)

사용자가 "dev-process-light 를 이 프로젝트에 설치해 줘"라고 하면, 아래를 그대로 수행한다.

## 방법 A -- git 이 있으면 (권장)
```bash
git clone --depth 1 https://github.com/sungbeom78/dev-process-light.git <임시폴더>/dev-process-light
bash <임시폴더>/dev-process-light/install.sh <프로젝트 폴더>          # macOS·Linux·Git Bash
# Windows PowerShell: powershell -ExecutionPolicy Bypass -File <임시폴더>\dev-process-light\install.ps1 <프로젝트 폴더>
```
설치가 끝나면 임시 폴더는 지워도 된다 (사용자에게 묻고).
설치기가 `[물어볼 것]` 을 내고 3 으로 끝나면(직접 고친 스킬 · 규칙 블록 -- 말없이 덮지 않는다) 그 목록을 사용자에게 그대로 보이고 묻는다
(권장: 새 판으로). 답대로 다시 실행: 새 판으로 `--update <이름|all>`(지금 것은 `.light-backup/` 에) · 그대로 `--keep <이름|all>`
(PowerShell 은 `-Update` · `-Keep`). 사용자의 답은 `dev-notes/DECISIONS.md` 에 `[사용자]` 로 적는다.

## 방법 B -- 명령을 실행할 수 없으면 파일을 직접 만든다
저장소의 `kit/` 아래 파일을 프로젝트에 아래처럼 만든다 (원문 그대로):

| 저장소 파일 | 프로젝트에 만들 위치 | 이미 있으면 |
|---|---|---|
| `kit/skills/<이름>/` 폴더 (8개 -- light-* 7개와 짝 스킬 data-light. SKILL.md 와 light-manual·light-portal 의 도구·템플릿, data-light 의 scripts·references·examples·LICENSE) | `.claude/skills/<이름>/` 와 `.agents/skills/<이름>/` | 새 버전으로 바꾼다 (파일 내용은 원문 그대로 -- data-light 는 한 글자도 바꾸지 않는다). 다만 직접 고친 흔적(저장소의 어느 판과도 다른 내용)이 있으면 바꾸기 전에 사용자에게 묻는다 |
| `kit/dev-notes/*.md` (5개) | `dev-notes/*.md` | **건드리지 않는다** (사용자 기록). 없는 파일만 만든다 |
| (없음) | `data/` | **건드리지 않는다** (사용자 데이터 설계·DB) |
| `kit/AGENTS.md` | `AGENTS.md` | `<!-- dev-process-light:begin -->` ~ `end` 블록만 바꾸고, 블록이 없으면 끝에 붙인다 (블록 안을 직접 고쳤으면 바꾸기 전에 묻는다) |
| `kit/CLAUDE.md` | `CLAUDE.md` | `@AGENTS.md` 줄이 없을 때만 끝에 붙인다 |

짝 스킬 `data-light` 는 원문을 다시 쓰지 말고 **파일 그대로 받는다** (`scripts/datalight.py` 는 60KB 가 넘는다):
저장소의 raw 주소(`https://raw.githubusercontent.com/sungbeom78/dev-process-light/main/kit/skills/data-light/<파일>`)에서 바이트 그대로 받아
[`data-light.lock.json`](data-light.lock.json) 의 `files` 에 적힌 sha256 과 같은지 확인한다. 프로젝트에 `.data-light/datalight.py`
(데이터 검사 장치의 도구 사본)가 있으면 그것도 받은 `scripts/datalight.py` 로 바꾼다.
바이트 그대로 받거나 해시를 확인할 수 없으면(웹 읽기 도구는 글을 가공한다) data-light 는 설치하지 말고 멈춘 뒤, 사용자에게
방법 A(설치기)나 ZIP 으로 받아 설치기를 실행해 달라고 부탁한다 -- 나머지 light 스킬은 그대로 설치해도 된다.

## 설치 후
1. 무엇을 만들고 무엇을 유지했는지 사용자에게 짧게 알린다 (짝 스킬 data-light 의 버전 -- 저장소의 `data-light.lock.json` -- 도 함께).
2. `light-resume` 을 실행해 첫 준비(git 시작, 기능 지도)를 한다.
