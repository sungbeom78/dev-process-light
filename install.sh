#!/usr/bin/env bash
# dev-process-light 설치 -- macOS / Linux / Windows(Git Bash)
#   bash install.sh [프로젝트 폴더]      (생략하면 현재 폴더)
# 하는 일:
#   - 스킬 5개를 .claude/skills (Claude Code) 와 .agents/skills (Codex) 에 복사 (있으면 새 버전으로 갱신)
#   - dev-notes/ 기록 파일은 없을 때만 만든다 (이미 쓰던 기록은 절대 덮어쓰지 않는다)
#   - AGENTS.md 에 규칙 블록을 넣거나 갱신한다 (내가 쓴 다른 내용은 그대로 둔다)
#   - CLAUDE.md 가 AGENTS.md 를 읽게 한다
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kit"
TARGET="${1:-.}"
BEGIN="<!-- dev-process-light:begin -->"
END="<!-- dev-process-light:end -->"

if [ ! -d "$KIT/skills" ]; then
  echo "[실패] kit 폴더를 찾을 수 없습니다: $KIT" >&2; exit 1
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"
echo "dev-process-light 설치 -> $TARGET"

# 1) 스킬
for host in .claude/skills .agents/skills; do
  mkdir -p "$TARGET/$host"
  for skill in "$KIT"/skills/*/; do
    name="$(basename "$skill")"
    rm -rf "$TARGET/$host/$name"
    cp -R "$skill" "$TARGET/$host/$name"
  done
  echo "  [OK] 스킬 5개 -> $host"
done

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
if [ ! -e "$A" ]; then
  cp "$KIT/AGENTS.md" "$A"; echo "  [OK] AGENTS.md 만듦"
elif grep -qF "$BEGIN" "$A" && grep -qF "$END" "$A"; then
  tmp="$(mktemp)"
  awk -v b="$BEGIN" -v e="$END" -v kit="$KIT/AGENTS.md" '
    $0==b { while ((getline line < kit) > 0) print line; skip=1; next }
    $0==e { skip=0; next }
    !skip { print }' "$A" > "$tmp"
  mv "$tmp" "$A"; echo "  [OK] AGENTS.md 규칙 블록 갱신 (다른 내용은 그대로)"
else
  { printf '\n'; cat "$KIT/AGENTS.md"; } >> "$A"; echo "  [OK] AGENTS.md 끝에 규칙 블록 추가"
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

cat << 'MSG'

설치 끝. 이제 이 폴더에서 Claude Code(또는 Codex)를 열고 이렇게 말하세요:
  "light-resume 으로 시작해 줘"
MSG
