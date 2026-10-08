# AI에게 설치를 맡길 때 (AI가 읽는 문서)

사용자가 "dev-process-light 를 이 프로젝트에 설치해 줘"라고 하면, 아래를 그대로 수행한다.

## 방법 A -- git 이 있으면 (권장)
```bash
git clone --depth 1 https://github.com/sungbeom78/dev-process-light.git <임시폴더>/dev-process-light
bash <임시폴더>/dev-process-light/install.sh <프로젝트 폴더>          # macOS·Linux·Git Bash
# Windows PowerShell: powershell -ExecutionPolicy Bypass -File <임시폴더>\dev-process-light\install.ps1 <프로젝트 폴더>
```
설치가 끝나면 임시 폴더는 지워도 된다 (사용자에게 묻고).

## 방법 B -- 명령을 실행할 수 없으면 파일을 직접 만든다
저장소의 `kit/` 아래 파일을 프로젝트에 아래처럼 만든다 (원문 그대로):

| 저장소 파일 | 프로젝트에 만들 위치 | 이미 있으면 |
|---|---|---|
| `kit/skills/<이름>/SKILL.md` (5개) | `.claude/skills/<이름>/SKILL.md` 와 `.agents/skills/<이름>/SKILL.md` | 새 버전으로 바꾼다 |
| `kit/dev-notes/*.md` (4개) | `dev-notes/*.md` | **건드리지 않는다** (사용자 기록) |
| `kit/AGENTS.md` | `AGENTS.md` | `<!-- dev-process-light:begin -->` ~ `end` 블록만 바꾸고, 블록이 없으면 끝에 붙인다 |
| `kit/CLAUDE.md` | `CLAUDE.md` | `@AGENTS.md` 줄이 없을 때만 끝에 붙인다 |

## 설치 후
1. 무엇을 만들고 무엇을 유지했는지 사용자에게 짧게 알린다.
2. `light-resume` 을 실행해 첫 준비(git 시작, 기능 지도)를 한다.
