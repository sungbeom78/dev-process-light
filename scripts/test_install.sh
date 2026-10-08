#!/usr/bin/env bash
# 설치기 회귀 점검 (CI): 새 폴더 설치 -> 사용자 수정 -> 재설치 -> 사용자 기록·내용이 보존되는지
#   bash scripts/test_install.sh [bash|pwsh]
set -euo pipefail
MODE="${1:-bash}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)/my project"          # 공백이 든 경로로 시험
mkdir -p "$T"
# PowerShell 에는 Windows 경로로 넘긴다 (Git Bash 의 /tmp/... 는 pwsh 가 모름)
winpath() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
run() {
  if [ "$MODE" = pwsh ]; then pwsh -NoProfile -ExecutionPolicy Bypass -File "$(winpath "$ROOT/install.ps1")" "$(winpath "$T")" >/dev/null
  else bash "$ROOT/install.sh" "$T" >/dev/null; fi
}
fail() { echo "FAIL: $*"; exit 1; }

printf '# 내 규칙\n원래 내용\n' > "$T/AGENTS.md"
run
for s in light-resume light-start light-check light-save light-undo light-manual; do
  [ -f "$T/.claude/skills/$s/SKILL.md" ] && [ -f "$T/.agents/skills/$s/SKILL.md" ] || fail "skill $s"
done
for n in NOW FEATURES DECISIONS NAMES; do [ -f "$T/dev-notes/$n.md" ] || fail "dev-notes/$n.md"; done
grep -q "원래 내용" "$T/AGENTS.md" || fail "user AGENTS content lost"
grep -q "dev-process-light:begin" "$T/AGENTS.md" || fail "block not added"
grep -q "@AGENTS.md" "$T/CLAUDE.md" || fail "CLAUDE.md"

echo "내 기록" >> "$T/dev-notes/NOW.md"
printf '\n## 내 추가 규칙\n' >> "$T/AGENTS.md"
echo "stale" > "$T/.claude/skills/light-check/SKILL.md"
run
grep -q "내 기록" "$T/dev-notes/NOW.md" || fail "NOW.md overwritten"
grep -q "내 추가 규칙" "$T/AGENTS.md" || fail "user section after block lost"
[ "$(grep -c 'dev-process-light:begin' "$T/AGENTS.md")" = 1 ] || fail "block duplicated"
grep -q "^name: light-check" "$T/.claude/skills/light-check/SKILL.md" || fail "skill not refreshed"
[ "$(grep -c '@AGENTS.md' "$T/CLAUDE.md")" = 1 ] || fail "CLAUDE.md duplicated"
head -c 3 "$T/AGENTS.md" | od -An -tx1 | grep -q "ef bb bf" && fail "BOM written"
echo "PASS ($MODE): install, re-install, user notes and AGENTS.md content preserved"
