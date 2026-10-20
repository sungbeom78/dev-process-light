#!/usr/bin/env bash
# dev-process-light 설치 -- macOS / Linux / Windows(Git Bash)
#   bash install.sh [프로젝트 폴더] [--update <이름>|all] [--keep <이름>|all]      (폴더를 생략하면 현재 폴더)
# 하는 일:
#   - 스킬 8개(light-* 7개 + 짝 데이터 설계 스킬 data-light)를 .claude/skills (Claude Code) 와
#     .agents/skills (Codex) 에 복사 (있으면 새 버전으로 갱신). data-light 는 data-light.lock.json 에 고정한 버전이다
#   - dev-notes/ 기록 파일은 없을 때만 만든다 (이미 쓰던 기록은 절대 덮어쓰지 않는다)
#   - AGENTS.md 에 규칙 블록을 넣거나 갱신한다 (내가 쓴 다른 내용은 그대로 둔다)
#   - CLAUDE.md 가 AGENTS.md 를 읽게 한다
# 새 판 반영이 원칙, 다만 직접 고친 스킬 · 규칙 블록은 말없이 덮지 않는다 (소유자 원칙 2026-10-20 -- 어느 쪽을 둘지는 사용자가 정한다):
#   지난번에 설치한 그대로(또는 손대지 않은 예전 판)면 새 판으로 바꾸고, 직접 고친 것이면 손대지 않고 '물어볼 것'으로 알린 뒤 3 으로 끝난다.
#   사용자가 고르면: --update <이름|all> 새 판으로 (지금 것은 .light-backup/ 에 남김) · --keep <이름|all> 지금 것을 둔다
#   <이름> = 스킬 이름(light-check 등) 또는 AGENTS (규칙 블록). 기록: .claude/skills/.light-kit
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kit"
TARGET=""
UPDATE=" "
KEEP=" "
while [ $# -gt 0 ]; do
  if [ "$1" = "--update" ] && [ $# -ge 2 ]; then UPDATE="$UPDATE$2 "; shift 2; continue; fi
  if [ "$1" = "--keep" ] && [ $# -ge 2 ]; then KEEP="$KEEP$2 "; shift 2; continue; fi
  if [ -z "$TARGET" ]; then TARGET="$1"; shift; continue; fi
  echo "[실패] 알 수 없는 인자: $1" >&2; exit 2
done
TARGET="${TARGET:-.}"
BEGIN="<!-- dev-process-light:begin -->"
END="<!-- dev-process-light:end -->"

if [ ! -d "$KIT/skills" ]; then
  echo "[실패] kit 폴더를 찾을 수 없습니다: $KIT" >&2; exit 1
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
echo "dev-process-light 설치 -> $TARGET"

# ---- 지문 (scripts/kit_hash.py · install.ps1 과 같은 셈법)
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-64; else shasum -a 256 | cut -c1-64; fi; }
tree_hash() {
  ( cd "$1" && find . -type f ! -name '.light-kit*' ! -name '*.pyc' ! -path '*/__pycache__/*' | sed 's|^\./||' | LC_ALL=C sort |
      while IFS= read -r f; do printf '%s\t%s\n' "$f" "$(tr -d '\r' < "$f" | sha)"; done ) | sha | cut -c1-16
}
block_text() {   # 시작 줄부터 끝 줄까지 (\r 뺌)
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk -v b="$BEGIN" -v e="$END" 'index($0, b) == 1 { on = 1 } on { print } on && index($0, e) == 1 { exit }'
}
block_hash() { local t; t="$(block_text "$1")"; if [ -n "$t" ] && printf '%s\n' "$t" | grep -qF "$END"; then printf '%s\n' "$t" | sha | cut -c1-16; fi; }
STATE="$TARGET/.claude/skills/.light-kit"
OLD_STATE=""
[ -f "$STATE" ] && OLD_STATE="$(tr -d '\r' < "$STATE")"
NEW_STATE=""
HIST=""
[ -f "$KIT/.history" ] && HIST="$(tr -d '\r' < "$KIT/.history")"
state_get() { printf '%s\n' "$OLD_STATE" | awk -v k="$1" -v n="$2" '$1 == k && $2 == n { print $3; exit }'; }
known_old() { printf '%s\n' "$HIST" | grep -qx "$1"; }
wants() { case "$2" in (*" all "*|*" $1 "*) return 0;; esac; return 1; }
put() { NEW_STATE="$NEW_STATE$1 $2 $3
"; }
STAMP="$(date +%Y%m%d-%H%M%S)"
ASK=""
backup() { local d="$TARGET/.light-backup/$STAMP/$2"; mkdir -p "$(dirname "$d")"; cp -R "$1" "$d"; printf '%s' ".light-backup/$STAMP/$2"; }

# 1) 스킬
for host in .claude/skills .agents/skills; do
  mkdir -p "$TARGET/$host"
  n=0
  for skill in "$KIT"/skills/*/; do
    name="$(basename "$skill")"
    dst="$TARGET/$host/$name"
    key="$host/$name"
    want="$(tree_hash "$skill")"
    n=$((n + 1))
    if [ ! -e "$dst" ]; then
      cp -R "$skill" "$dst"; put installed "$key" "$want"; continue
    fi
    have="$(tree_hash "$dst")"
    if [ "$have" = "$want" ]; then put installed "$key" "$want"; continue; fi
    if [ "$(state_get installed "$key")" = "$have" ] || known_old "skill $name $have"; then
      rm -rf "$dst"; cp -R "$skill" "$dst"; put installed "$key" "$want"; continue          # 손대지 않은 예전 판 -> 새 판
    fi
    if wants "$name" "$UPDATE"; then
      b="$(backup "$dst" "$key")"; rm -rf "$dst"; cp -R "$skill" "$dst"; put installed "$key" "$want"
      echo "  [OK] $key: 새 판으로 바꿈 (사용자 결정 -- 예전 것은 $b)"; continue
    fi
    prev="$(state_get installed "$key")"; [ -n "$prev" ] && put installed "$key" "$prev"
    if wants "$name" "$KEEP" || [ "$(state_get keep "$key")" = "$have" ]; then
      put keep "$key" "$have"; echo "  [유지] $key (직접 고친 것을 두기로 함 -- 사용자 결정)"; continue
    fi
    ASK="$ASK  - $key (스킬 $name)
"
  done
  echo "  [OK] 스킬 ${n}개 -> $host"
done
LOCK="$(dirname "$KIT")/data-light.lock.json"
if [ -f "$LOCK" ]; then
  DLV="$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$LOCK" | head -n 1)"
  DLC="$(sed -n 's/^ *"commit": *"\([0-9a-f]\{7\}\).*/\1/p' "$LOCK" | head -n 1)"
  echo "  [OK] 짝 스킬 data-light ${DLV:-?} (data-expert-framework-light ${DLC:-?}) -- 저장할 데이터가 생기면 씁니다"
fi
# 데이터 검사 장치(datalight.py hook install)가 프로젝트에 둔 도구 사본도 짝 버전으로 맞춘다 (커밋 검사·CI 가 같은 도구로)
#   줄바꿈(CRLF)만 다른 것은 같은 것으로 본다. 커밋 검사 훅 자체는 light-resume 이 `hook install` 로 다시 맞춘다
DLT="$KIT/skills/data-light/scripts/datalight.py"
if [ -f "$TARGET/.data-light/datalight.py" ] && ! tr -d '\r' < "$TARGET/.data-light/datalight.py" | cmp -s - "$DLT"; then
  cp "$DLT" "$TARGET/.data-light/datalight.py"
  echo "  [OK] .data-light/datalight.py 도 짝 버전으로 바꿈 -- light-resume 이 커밋 검사 훅도 다시 맞추고 저장합니다"
fi

# 2) 기록 파일 (없을 때만)
mkdir -p "$TARGET/dev-notes"
for f in "$KIT"/dev-notes/*.md; do
  name="$(basename "$f")"
  if [ -e "$TARGET/dev-notes/$name" ]; then
    echo "  [유지] dev-notes/$name (이미 있음)"
  else
    cp "$f" "$TARGET/dev-notes/$name"
    echo "  [OK] dev-notes/$name"
  fi
done

# 3) AGENTS.md 규칙 블록
A="$TARGET/AGENTS.md"
want="$(block_hash "$KIT/AGENTS.md")"
replace_block() {
  local tmp; tmp="$(mktemp)"
  awk -v b="$BEGIN" -v e="$END" -v kit="$KIT/AGENTS.md" '
    { l = $0; sub(/\r$/, "", l) }
    index(l, b) == 1 && !done { while ((getline line < kit) > 0) print line; skip = 1; next }
    skip && index(l, e) == 1 { skip = 0; done = 1; next }
    !skip { print }' "$A" > "$tmp"
  mv "$tmp" "$A"
}
if [ ! -e "$A" ]; then
  cp "$KIT/AGENTS.md" "$A"; put installed AGENTS "$want"; echo "  [OK] AGENTS.md 만듦"
else
  have="$(block_hash "$A")"
  if [ -z "$have" ]; then
    { printf '\n'; cat "$KIT/AGENTS.md"; } >> "$A"; put installed AGENTS "$want"; echo "  [OK] AGENTS.md 끝에 규칙 블록 추가"
  elif [ "$have" = "$want" ]; then
    put installed AGENTS "$want"; echo "  [유지] AGENTS.md 규칙 블록 (새 판과 같음)"
  elif [ "$(state_get installed AGENTS)" = "$have" ] || known_old "block $have"; then
    replace_block; put installed AGENTS "$want"; echo "  [OK] AGENTS.md 규칙 블록 갱신 (다른 내용은 그대로)"
  elif wants AGENTS "$UPDATE"; then
    mkdir -p "$TARGET/.light-backup/$STAMP"; block_text "$A" > "$TARGET/.light-backup/$STAMP/AGENTS.block.md"
    replace_block; put installed AGENTS "$want"
    echo "  [OK] AGENTS.md 규칙 블록: 새 판으로 바꿈 (사용자 결정 -- 예전 블록은 .light-backup/$STAMP/AGENTS.block.md)"
  else
    prev="$(state_get installed AGENTS)"; [ -n "$prev" ] && put installed AGENTS "$prev"
    if wants AGENTS "$KEEP" || [ "$(state_get keep AGENTS)" = "$have" ]; then
      put keep AGENTS "$have"; echo "  [유지] AGENTS.md 규칙 블록 (직접 고친 것을 두기로 함 -- 사용자 결정)"
    else
      ASK="$ASK  - AGENTS (AGENTS.md 의 규칙 블록)
"
    fi
  fi
fi

# 4) CLAUDE.md
C="$TARGET/CLAUDE.md"
if [ ! -e "$C" ]; then
  cp "$KIT/CLAUDE.md" "$C"; echo "  [OK] CLAUDE.md 만듦 (@AGENTS.md)"
elif ! grep -qF "@AGENTS.md" "$C"; then
  printf '\n@AGENTS.md\n' >> "$C"; echo "  [OK] CLAUDE.md 에 @AGENTS.md 추가"
else
  echo "  [유지] CLAUDE.md"
fi

# 설치 기록 (다음 설치가 '직접 고쳤나'를 알아본다)
{ echo "# dev-process-light 설치 기록 -- 다음 설치가 직접 고친 것을 알아보려고 (지우면 다음 설치가 한 번 더 묻는다)"
  printf '%s' "$NEW_STATE"; } > "$STATE"

# 쓸 수 있는 파이썬인지 실제로 실행해 본다 (Windows 의 가짜 python3 -- 스토어 안내 -- 는 여기서 걸러진다)
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c "import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)" >/dev/null 2>&1; then
    PY="$c"; break
  fi
done
if [ -z "$PY" ]; then
  echo "  [참고] 파이썬이 없습니다 -- 데이터 설계 검사(data-light)·기록 보기 페이지·설명서 검토에만 필요합니다 (3.9 이상, 나머지는 그대로 동작)"
fi

if [ -n "$ASK" ]; then
  cat << MSG

[물어볼 것] 아래는 새 판과 다릅니다 (직접 고쳤거나, 예전 설치 기록이 없어 알 수 없음) -- 손대지 않았습니다:
$ASK  사용자에게 물어보고 그 답대로 다시 설치합니다 (권장: 새 판으로 -- 고친 내용이 필요하면 백업에서 다시 옮긴다):
    새 판으로:      bash install.sh "$TARGET" --update <이름|all>   (지금 것은 .light-backup/ 에 남김)
    지금 것을 둠:   bash install.sh "$TARGET" --keep <이름|all>
  사용자의 답은 dev-notes/DECISIONS.md 에 [사용자] 로 적습니다.
MSG
  exit 3
fi

cat << 'MSG'

설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:
  "light-resume 으로 시작해 줘"
MSG
