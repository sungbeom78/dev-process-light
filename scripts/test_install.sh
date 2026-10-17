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
for s in light-resume light-start light-check light-save light-undo light-manual light-portal data-light; do
  [ -f "$T/.claude/skills/$s/SKILL.md" ] && [ -f "$T/.agents/skills/$s/SKILL.md" ] || fail "skill $s"
done
for f in assets/manual.css assets/manual.js templates/index.html manual_tool.py; do
  [ -f "$T/.claude/skills/light-manual/$f" ] || fail "light-manual/$f"
done
[ -f "$T/.claude/skills/light-portal/portal_tool.py" ] && [ -f "$T/.claude/skills/light-portal/templates/portal.html" ] || fail "light-portal files"
# 짝 스킬 data-light: 고정한 사본이 그대로 깔리고 실제로 돌아가는지
for h in .claude .agents; do
  diff -r "$ROOT/kit/skills/data-light" "$T/$h/skills/data-light" >/dev/null || fail "data-light copy differs ($h)"
done
for f in scripts/datalight.py references/format.md references/with-dev-process-light.md LICENSE; do
  [ -f "$T/.claude/skills/data-light/$f" ] || fail "data-light/$f"
done
grep -q "data-light" "$T/AGENTS.md" || fail "AGENTS block has no data rule"
PY="$(command -v python3 || command -v python || true)"
if [ -n "$PY" ]; then
  EX="$T/.claude/skills/data-light/examples/shop/data/model.light.json"
  "$PY" -B "$T/.claude/skills/data-light/scripts/datalight.py" check "$EX" >/dev/null || fail "installed datalight check"
  "$PY" -B "$T/.claude/skills/data-light/scripts/datalight.py" try "$EX" >/dev/null || fail "installed datalight try"
fi
# 사용자 데이터(정본·DB)는 다시 설치해도 그대로
mkdir -p "$T/data"
cp "$ROOT/kit/skills/data-light/examples/shop/data/model.light.json" "$T/data/model.light.json"
printf 'not a real db' > "$T/data/app.db"
mkdir -p "$T/.data-light" && printf 'old tool' > "$T/.data-light/datalight.py"   # hook install 이 둔 예전 도구 사본
for n in NOW FEATURES DECISIONS NAMES LOG; do [ -f "$T/dev-notes/$n.md" ] || fail "dev-notes/$n.md"; done
grep -q "원래 내용" "$T/AGENTS.md" || fail "user AGENTS content lost"
grep -q "dev-process-light:begin" "$T/AGENTS.md" || fail "block not added"
grep -q "@AGENTS.md" "$T/CLAUDE.md" || fail "CLAUDE.md"

echo "내 기록" >> "$T/dev-notes/NOW.md"
printf '\n## 내 추가 규칙\n' >> "$T/AGENTS.md"
echo "stale" > "$T/.claude/skills/light-check/SKILL.md"
echo "stale" > "$T/.claude/skills/data-light/SKILL.md"
run
grep -q "내 기록" "$T/dev-notes/NOW.md" || fail "NOW.md overwritten"
grep -q "내 추가 규칙" "$T/AGENTS.md" || fail "user section after block lost"
[ "$(grep -c 'dev-process-light:begin' "$T/AGENTS.md")" = 1 ] || fail "block duplicated"
grep -q "^name: light-check" "$T/.claude/skills/light-check/SKILL.md" || fail "skill not refreshed"
cmp -s "$T/data/model.light.json" "$ROOT/kit/skills/data-light/examples/shop/data/model.light.json" || fail "user data model touched"
[ "$(cat "$T/data/app.db")" = "not a real db" ] || fail "user db touched"
diff -r "$ROOT/kit/skills/data-light" "$T/.claude/skills/data-light" >/dev/null || fail "data-light not refreshed"
cmp -s "$ROOT/kit/skills/data-light/scripts/datalight.py" "$T/.data-light/datalight.py" || fail ".data-light tool not refreshed"
[ "$(grep -c '@AGENTS.md' "$T/CLAUDE.md")" = 1 ] || fail "CLAUDE.md duplicated"
head -c 3 "$T/AGENTS.md" | od -An -tx1 | grep -q "ef bb bf" && fail "BOM written"
# 줄바꿈만 다른 도구 사본(Windows autocrlf)은 바꾸지 않는다
if [ "$MODE" = bash ]; then
  sed 's/$/\r/' "$ROOT/kit/skills/data-light/scripts/datalight.py" > "$T/.data-light/datalight.py"
  bash "$ROOT/install.sh" "$T" | grep -q "짝 버전으로 바꿈" && fail "CRLF-only tool copy rewritten"
fi
# 예전 버전(0.8, 훅에 버전 줄 없음)의 데이터 검사 장치 → hook status 가 다르다고 하고 → hook install 뒤 최신 → 정본 저장이 훅을 통과
if [ "$MODE" = bash ] && [ -n "$PY" ] && command -v git >/dev/null 2>&1; then
  G="$(mktemp -d)/repo"; mkdir -p "$G"; git -C "$G" init -q
  bash "$ROOT/install.sh" "$G" >/dev/null
  DL="$G/.claude/skills/data-light/scripts/datalight.py"
  mkdir -p "$G/.git/hooks"; printf '#!/bin/sh\n# data-light pre-commit (datalight.py hook install)\nexit 0\n' > "$G/.git/hooks/pre-commit"
  mkdir -p "$G/.data-light"; cp "$DL" "$G/.data-light/datalight.py"
  (cd "$G" && "$PY" -B "$DL" hook status >/dev/null) && fail "old hook reported as current"
  (cd "$G" && "$PY" -B "$DL" hook install --no-ci >/dev/null) || fail "hook install"
  (cd "$G" && "$PY" -B "$DL" hook status >/dev/null) || fail "hook not current after install"
  [ -e "$G/.github/workflows/data-light.yml" ] && fail "--no-ci created a CI file"
  sh -n "$G/.git/hooks/pre-commit" 2>/dev/null || fail "installed hook is not readable by this sh"   # data-light 0.4.1 부터 macOS 의 sh 도 읽는다
  mkdir -p "$G/data"; cp "$ROOT/kit/skills/data-light/examples/shop/data/model.light.json" "$G/data/"
  (cd "$G" && "$PY" -B "$DL" build data/model.light.json --out data/out >/dev/null) || fail "build"
  git -C "$G" add data/model.light.json data/out/schema.sql data/out/erd.md data/out/spec.md
  git -C "$G" -c user.name=t -c user.email=t@t commit -q -m "데이터: 시험" >/dev/null 2>&1 || fail "commit through the data hook"
  printf '{"format": "data-light/1", "tables": []}\n' > "$G/data/model.light.json"; git -C "$G" add data/model.light.json
  git -C "$G" -c user.name=t -c user.email=t@t commit -q -m "데이터: 망가뜨림" >/dev/null 2>&1 && fail "broken model committed past the hook"
fi
echo "PASS ($MODE): install, re-install, paired data-light, data hook upgrade, user notes·data and AGENTS.md content preserved"
