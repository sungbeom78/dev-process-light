#!/usr/bin/env bash
# dev-process-light 설치 -- macOS / Linux / Windows(Git Bash)
#   bash install.sh [프로젝트 폴더] [--update <이름>[,<이름>]|all] [--keep <이름>[,<이름>]|all]      (폴더를 생략하면 현재 폴더)
# 하는 일:
#   - 스킬 8개(light-* 7개 + 짝 데이터 설계 스킬 data-light)를 .claude/skills (Claude Code) 와
#     .agents/skills (Codex) 에 복사 (있으면 새 버전으로 갱신). data-light 는 data-light.lock.json 에 고정한 버전이다
#   - dev-notes/ 기록 파일은 없을 때만 만든다 (이미 쓰던 기록은 절대 덮어쓰지 않는다)
#   - AGENTS.md 에 규칙 블록을 넣거나 갱신한다 (내가 쓴 다른 내용은 그대로 둔다)
#   - CLAUDE.md 가 AGENTS.md 를 읽게 한다
# 새 판 반영이 원칙, 다만 직접 고치거나 지운 스킬 · 규칙 블록은 말없이 덮거나 되살리지 않는다 (소유자 원칙 2026-10-20 -- 어느 쪽을 둘지는 사용자가 정한다):
#   지난번에 설치한 그대로(또는 손대지 않은 예전 판, kit/.history)면 새 판으로 바꾸고, 고치거나 지운 것이면 손대지 않고 '물어볼 것'으로 알린 뒤 3 으로 끝난다.
#   사용자가 고르면: --update <이름|all> 새 판으로 (지금 것은 .claude/skills/.light-backup/ 에) · --keep <이름|all> 지금 것을 둔다
#   <이름> = 스킬 이름(light-check 등) 또는 AGENTS (규칙 블록). 기록: .claude/skills/.light-kit ('ask' 줄 = 아직 묻지 않은 것)
#   고른 것은 그 판에 대한 것이다 -- 새 판이 그 스킬 · 블록을 또 바꾸면 다시 묻는다
set -euo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install.sh"
KIT="$(dirname "$SELF")/kit"
TARGET=""
UPDATE=" "
KEEP=" "
BEGIN="<!-- dev-process-light:begin -->"
END="<!-- dev-process-light:end -->"
BOM="$(printf '\357\273\277')"

if [ ! -d "$KIT/skills" ]; then
  echo "[실패] kit 폴더를 찾을 수 없습니다: $KIT" >&2; exit 1
fi
NAMES=" AGENTS all "
for s in "$KIT"/skills/*/; do NAMES="$NAMES$(basename "$s") "; done
pick() {   # --update · --keep 의 값 -- 쉼표로 여럿, '.claude/skills/<이름>' 모양도 받는다
  local v n out=""
  for v in $(printf '%s' "$1" | tr ',' ' '); do
    n="${v##*/}"
    case "$NAMES" in (*" $n "*) out="$out$n ";; (*) echo "[실패] 모르는 이름: $v (스킬 이름 · AGENTS · all 중에서)" >&2; exit 2;; esac
  done
  printf '%s' "$out"
}
while [ $# -gt 0 ]; do
  case "$1" in
    (--update|--keep)
      if [ $# -lt 2 ] || [ -z "$2" ]; then echo "[실패] $1 다음에 이름을 줍니다 (스킬 이름 · AGENTS · all)" >&2; exit 2; fi
      v="$(pick "$2")"
      if [ "$1" = "--update" ]; then UPDATE="$UPDATE$v"; else KEEP="$KEEP$v"; fi
      shift 2;;
    (-*) echo "[실패] 알 수 없는 인자: $1" >&2; exit 2;;
    (*) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else echo "[실패] 폴더는 하나만: $1" >&2; exit 2; fi;;
  esac
done
TARGET="${TARGET:-.}"
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
echo "dev-process-light 설치 -> $TARGET"

# ---- 지문 (scripts/kit_hash.py · install.ps1 과 같은 셈법)
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-64; else shasum -a 256 | cut -c1-64; fi; }
tree_hash() {
  ( cd "$1" && find . -type f ! -name '.light-kit*' ! -name '*.pyc' ! -name '.DS_Store' ! -name 'Thumbs.db' ! -name 'desktop.ini' \
      ! -path '*/__pycache__/*' | sed 's|^\./||' | LC_ALL=C sort |
      while IFS= read -r f; do printf '%s\t%s\n' "$f" "$(tr -d '\r' < "$f" | sha)"; done ) | sha | cut -c1-16
}
block_text() {   # 시작 줄부터 끝 줄(줄 머리)까지 -- \r · 맨 앞 BOM 은 뺀다. 끝 줄이 없으면 아무것도 내지 않는다
  [ -f "$1" ] || return 0
  tr -d '\r' < "$1" | awk -v b="$BEGIN" -v e="$END" -v bom="$BOM" '
    NR == 1 && index($0, bom) == 1 { $0 = substr($0, length(bom) + 1) }
    !done && !on && index($0, b) == 1 { on = 1 }
    !done && on { buf = buf $0 "\n"; if (index($0, e) == 1) { done = 1; on = 0 } }
    END { if (done) printf "%s", buf }'
}
block_hash() { local t; t="$(block_text "$1")"; if [ -n "$t" ]; then printf '%s\n' "$t" | sha | cut -c1-16; fi; }
STATE="$TARGET/.claude/skills/.light-kit"
OLD_STATE=""
[ -f "$STATE" ] && OLD_STATE="$(tr -d '\r' < "$STATE")"
NEW_STATE=""
HIST=""
[ -f "$KIT/.history" ] && HIST="$(tr -d '\r' < "$KIT/.history")"
state_get() { printf '%s\n' "$OLD_STATE" | awk -v k="$1" -v n="$2" -v i="${3:-3}" '$1 == k && $2 == n && !got { print $i; got = 1 }'; }
known_old() { printf '%s\n' "$HIST" | grep -qx "$1"; }
wants() { case "$2" in (*" all "*|*" $1 "*) return 0;; esac; return 1; }
put() { NEW_STATE="$NEW_STATE$*
"; }
kept() { [ "$(state_get keep "$1" 3)" = "$2" ] && [ "$(state_get keep "$1" 4)" = "$3" ]; }   # 같은 판에 대해 '지금 것을 둠' 으로 골랐다
STAMP="$(date +%Y%m%d-%H%M%S)"
BK=".claude/skills/.light-backup/$STAMP"         # 설치된 스킬 자리 안 -- 데이터 검사 · CI 가 보지 않는 곳
ASK=""
backup() {   # backup <원본> <이름> -- 실패하면 1 (지우기 전에 확인한다)
  local d="$TARGET/$BK/$2"
  mkdir -p "$(dirname "$d")" || return 1
  cp -R "$1" "$d" || return 1
  [ -e "$d" ] || return 1
  printf '%s' "$BK/$2"
}
ask() { ASK="$ASK  - $1
"; put ask "$2" "$3" "$4"; }

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
    prev="$(state_get installed "$key")"
    if [ ! -e "$dst" ]; then
      if [ -z "$prev" ] || wants "$name" "$UPDATE"; then
        cp -R "$skill" "$dst"; put installed "$key" "$want"; continue
      fi
      put installed "$key" "$prev"                                  # 전에 설치했는데 지웠다 -- 말없이 되살리지 않는다
      if wants "$name" "$KEEP" || kept "$key" - "$want"; then put keep "$key" - "$want"; echo "  [유지] $key 없음 (지운 채로 두기로 함 -- 사용자 결정)"
      else ask "$key (스킬 $name -- 지웠음)" "$key" - "$want"; fi
      continue
    fi
    have="$(tree_hash "$dst")"
    if [ "$have" = "$want" ]; then put installed "$key" "$want"; continue; fi
    if [ "$prev" = "$have" ] || known_old "skill $name $have"; then
      rm -rf "$dst"; cp -R "$skill" "$dst"; put installed "$key" "$want"; continue          # 손대지 않은 예전 판 -> 새 판
    fi
    if wants "$name" "$UPDATE"; then
      if ! b="$(backup "$dst" "$key")"; then
        echo "[실패] $key 를 백업하지 못해 바꾸지 않았습니다 (자리 · 권한 확인)" >&2; exit 1
      fi
      rm -rf "$dst"; cp -R "$skill" "$dst"; put installed "$key" "$want"
      echo "  [OK] $key: 새 판으로 바꿈 (사용자 결정 -- 예전 것은 $b)"; continue
    fi
    [ -n "$prev" ] && put installed "$key" "$prev"
    if wants "$name" "$KEEP" || kept "$key" "$have" "$want"; then
      put keep "$key" "$have" "$want"; echo "  [유지] $key (직접 고친 것을 두기로 함 -- 사용자 결정)"; continue
    fi
    ask "$key (스킬 $name)" "$key" "$have" "$want"
  done
  echo "  [OK] 스킬 ${n}개 -> $host"
done
LOCK="$(dirname "$KIT")/data-light.lock.json"
if [ -f "$LOCK" ]; then
  DLV="$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$LOCK" | head -n 1)"
  DLC="$(sed -n 's/^ *"commit": *"\([0-9a-f]\{7\}\).*/\1/p' "$LOCK" | head -n 1)"
  echo "  [OK] 짝 스킬 data-light ${DLV:-?} (data-expert-framework-light ${DLC:-?}) -- 저장할 데이터가 생기면 씁니다"
fi
# 데이터 검사 장치(datalight.py hook install)가 프로젝트에 둔 도구 사본도 짝 버전으로 맞춘다 (커밋 검사·CI 가 같은 도구로 --
#   도구 사본은 고치는 곳이 아니다). 줄바꿈(CRLF)만 다른 것은 같은 것으로 본다. 커밋 검사 훅 자체는 light-resume 이 `hook install` 로 다시 맞춘다
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
prev="$(state_get installed AGENTS)"
replace_block() {   # 첫 블록(시작 줄 머리 ~ 끝 줄 머리)만 새 판으로 -- 나머지 줄은 바이트 그대로
  local tmp; tmp="$(mktemp)"
  awk -v b="$BEGIN" -v e="$END" -v kit="$KIT/AGENTS.md" -v bom="$BOM" '
    { l = $0; sub(/\r$/, "", l); if (NR == 1 && index(l, bom) == 1) l = substr(l, length(bom) + 1) }
    index(l, b) == 1 && !done && !skip { while ((getline line < kit) > 0) print line; skip = 1; next }
    skip && index(l, e) == 1 { skip = 0; done = 1; next }
    !skip { print }' "$A" > "$tmp"
  mv "$tmp" "$A"
}
append_block() { { printf '\n'; cat "$KIT/AGENTS.md"; } >> "$A"; }
if [ ! -e "$A" ] && [ -z "$prev" ]; then
  cp "$KIT/AGENTS.md" "$A"; put installed AGENTS "$want"; echo "  [OK] AGENTS.md 만듦"
else
  have="$(block_hash "$A")"
  if [ -z "$have" ]; then
    if [ -z "$prev" ] || wants AGENTS "$UPDATE"; then
      if [ -e "$A" ]; then append_block; else cp "$KIT/AGENTS.md" "$A"; fi
      put installed AGENTS "$want"; echo "  [OK] AGENTS.md 에 규칙 블록 넣음"
    else
      put installed AGENTS "$prev"                                  # 전에 넣었는데 지웠다 -- 말없이 되살리지 않는다
      if wants AGENTS "$KEEP" || kept AGENTS - "$want"; then put keep AGENTS - "$want"; echo "  [유지] AGENTS.md 규칙 블록 없음 (지운 채로 두기로 함 -- 사용자 결정)"
      else ask "AGENTS (AGENTS.md 의 규칙 블록 -- 지웠음)" AGENTS - "$want"; fi
    fi
  elif [ "$have" = "$want" ]; then
    put installed AGENTS "$want"; echo "  [유지] AGENTS.md 규칙 블록 (새 판과 같음)"
  elif [ "$prev" = "$have" ] || known_old "block $have"; then
    replace_block; put installed AGENTS "$want"; echo "  [OK] AGENTS.md 규칙 블록 갱신 (다른 내용은 그대로)"
  elif wants AGENTS "$UPDATE"; then
    mkdir -p "$TARGET/$BK" && block_text "$A" > "$TARGET/$BK/AGENTS.block.md" && [ -s "$TARGET/$BK/AGENTS.block.md" ] \
      || { echo "[실패] 규칙 블록을 백업하지 못해 바꾸지 않았습니다" >&2; exit 1; }
    replace_block; put installed AGENTS "$want"
    echo "  [OK] AGENTS.md 규칙 블록: 새 판으로 바꿈 (사용자 결정 -- 예전 블록은 $BK/AGENTS.block.md)"
  else
    [ -n "$prev" ] && put installed AGENTS "$prev"
    if wants AGENTS "$KEEP" || kept AGENTS "$have" "$want"; then
      put keep AGENTS "$have" "$want"; echo "  [유지] AGENTS.md 규칙 블록 (직접 고친 것을 두기로 함 -- 사용자 결정)"
    else
      ask "AGENTS (AGENTS.md 의 규칙 블록)" AGENTS "$have" "$want"
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

# 설치 기록 (다음 설치가 '직접 고쳤나'를 알아본다 · ask 줄은 아직 묻지 않은 것 -- light-resume 이 본다)
{ echo "# dev-process-light 설치 기록 -- 다음 설치가 직접 고친 것을 알아보려고 (지우면 다음 설치가 한 번 더 묻는다)"
  printf '%s' "$NEW_STATE"; } > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"

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

[물어볼 것] 아래는 새 판과 다릅니다 (직접 고쳤거나 지웠음, 또는 예전 설치 기록이 없어 알 수 없음) -- 손대지 않았습니다:
$ASK  사용자에게 물어보고 그 답대로 다시 설치합니다 (권장: 새 판으로 -- 고친 내용이 필요하면 백업에서 다시 옮긴다):
    새 판으로:      bash "$SELF" "$TARGET" --update <이름|all>   (지금 것은 .claude/skills/.light-backup/ 에 남김)
    지금 것을 둠:   bash "$SELF" "$TARGET" --keep <이름|all>
  <이름> 은 스킬 이름(light-check 등)이나 AGENTS, 여럿은 쉼표로. 사용자의 답은 dev-notes/DECISIONS.md 에 [사용자] 로 적습니다.
MSG
  exit 3
fi

cat << 'MSG'

설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:
  "light-resume 으로 시작해 줘"
MSG
