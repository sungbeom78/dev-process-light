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
PWSH="${PWSH:-pwsh}"
run() {   # run [--update X] [--keep X] -- 끝난 코드를 그대로 (3 = 물어볼 것)
  local rc=0
  if [ "$MODE" = pwsh ]; then
    local extra=()
    while [ $# -gt 0 ]; do
      if [ "$1" = "--update" ]; then extra+=(-Update "$2"); fi
      if [ "$1" = "--keep" ]; then extra+=(-Keep "$2"); fi
      shift 2
    done
    "$PWSH" -NoProfile -ExecutionPolicy Bypass -File "$(winpath "$ROOT/install.ps1")" "$(winpath "$T")" ${extra[@]+"${extra[@]}"} > "$T.out" 2>&1 || rc=$?
  else bash "$ROOT/install.sh" "$T" "$@" > "$T.out" 2>&1 || rc=$?; fi
  return $rc
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

# 설치 기록: 셋(bash · PowerShell · kit_hash.py)이 같은 지문을 낸다
ST="$T/.claude/skills/.light-kit"
[ -f "$ST" ] || fail "no install record"
if [ -n "$PY" ]; then
  [ "$(grep '^installed .claude/skills/light-check ' "$ST" | cut -d' ' -f3)" = "$("$PY" -B "$ROOT/scripts/kit_hash.py" dir "$ROOT/kit/skills/light-check")" ] || fail "skill hash differs from kit_hash.py"
  [ "$(grep '^installed AGENTS ' "$ST" | cut -d' ' -f3)" = "$("$PY" -B "$ROOT/scripts/kit_hash.py" block "$ROOT/kit/AGENTS.md")" ] || fail "block hash differs from kit_hash.py"
fi

echo "내 기록" >> "$T/dev-notes/NOW.md"
printf '\n## 내 추가 규칙\n' >> "$T/AGENTS.md"
echo "stale" > "$T/.claude/skills/light-check/SKILL.md"           # 직접 고친 스킬 -- 말없이 덮지 않는다 (소유자 원칙 2026-10-20)
echo "stale" > "$T/.claude/skills/data-light/SKILL.md"
rc=0; run || rc=$?
[ "$rc" = 3 ] || { cat "$T.out"; fail "edited skills were not asked about (exit $rc)"; }
grep -q "^ask .claude/skills/light-check " "$ST" && grep -q "^ask .claude/skills/data-light " "$ST" || fail "ask lines not recorded"   # 출력 말이 아닌 기록으로 (Windows 콘솔 글자)
[ "$(cat "$T/.claude/skills/light-check/SKILL.md")" = "stale" ] || fail "edited skill overwritten without asking"
grep -q "내 기록" "$T/dev-notes/NOW.md" || fail "NOW.md overwritten"
grep -q "내 추가 규칙" "$T/AGENTS.md" || fail "user section after block lost"
[ "$(grep -c 'dev-process-light:begin' "$T/AGENTS.md")" = 1 ] || fail "block duplicated"
rc=0; run --update light-check || rc=$?                            # 사용자: light-check 는 새 판으로
[ "$rc" = 3 ] || fail "data-light still differs -- should still ask (exit $rc)"
grep -q "^name: light-check" "$T/.claude/skills/light-check/SKILL.md" || fail "skill not refreshed after --update"
ls "$T"/.claude/skills/.light-backup/*/.claude/skills/light-check/SKILL.md >/dev/null 2>&1 || fail "no backup of the edited skill"
[ -e "$T/.light-backup" ] && fail "backup at the project root (data hook · CI would check it)"
rc=0; run --keep data-light || rc=$?                               # 사용자: data-light 는 지금 것을 둠
[ "$rc" = 0 ] || { cat "$T.out"; fail "keep did not settle the difference (exit $rc)"; }
[ "$(cat "$T/.claude/skills/data-light/SKILL.md")" = "stale" ] || fail "kept skill overwritten"
rc=0; run || rc=$?
[ "$rc" = 0 ] || fail "kept choice asked again (exit $rc)"
grep -q "^ask " "$ST" && fail "ask line left after the choice"
# 고른 것은 그 판에 대한 것 -- 새 판이 그 스킬을 또 바꾸면 다시 묻는다 (기록의 '그때 새 판' 지문을 옛것으로 바꿔 흉내)
sed 's/^\(keep .claude\/skills\/data-light [0-9a-f-]*\) [0-9a-f]*$/\1 0000000000000000/' "$ST" > "$ST.x" && mv "$ST.x" "$ST"
rc=0; run || rc=$?
[ "$rc" = 3 ] || { cat "$T.out"; fail "keep for an older kit was not asked again (exit $rc)"; }
rc=0; run --keep data-light || rc=$?
[ "$rc" = 0 ] || fail "keep again"
rc=0; run --update data-light || rc=$?                              # 다시 새 판으로 (뒤의 시험은 새 판 그대로를 본다)
[ "$rc" = 0 ] && grep -q "^name: data-light" "$T/.claude/skills/data-light/SKILL.md" || fail "update back to the kit"
# 지난번에 설치한 그대로인 예전 판은 묻지 않고 새 판으로 (기록의 지문 = 지금 폴더)
echo "old kit" >> "$T/.agents/skills/light-start/SKILL.md"
if [ -n "$PY" ]; then
  OLD="$("$PY" -B "$ROOT/scripts/kit_hash.py" dir "$T/.agents/skills/light-start")"
  "$PY" - "$ST" "$OLD" <<'PYX'
import sys
p, h = sys.argv[1], sys.argv[2]
lines = open(p, encoding="utf-8").read().splitlines()
out = [(" ".join(l.split()[:2] + [h]) if l.startswith("installed .agents/skills/light-start ") else l) for l in lines]
open(p, "w", encoding="utf-8", newline="\n").write("\n".join(out) + "\n")
PYX
  rc=0; run || rc=$?
  [ "$rc" = 0 ] || { cat "$T.out"; fail "untouched old version was asked about (exit $rc)"; }
  grep -q "old kit" "$T/.agents/skills/light-start/SKILL.md" && fail "untouched old version not refreshed"
else
  rc=0; run --update light-start || rc=$?
fi
# 규칙 블록 안을 고치면 묻는다
"${PY:-python3}" - "$T/AGENTS.md" <<'PYX' 2>/dev/null || sed -i.bak 's/^## 작업 규칙: dev-process-light$/## 작업 규칙: dev-process-light (우리 규칙)/' "$T/AGENTS.md"
import sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8", newline="\n").write(t.replace("## 작업 규칙: dev-process-light\n", "## 작업 규칙: dev-process-light (우리 규칙)\n", 1))
PYX
rc=0; run || rc=$?
[ "$rc" = 3 ] && grep -q "AGENTS (AGENTS.md" "$T.out" && grep -q "(우리 규칙)" "$T/AGENTS.md" || fail "edited rule block not asked about"
rc=0; run --update AGENTS || rc=$?
[ "$rc" = 0 ] && ! grep -q "(우리 규칙)" "$T/AGENTS.md" && grep -q "내 추가 규칙" "$T/AGENTS.md" || fail "rule block update"
ls "$T"/.claude/skills/.light-backup/*/AGENTS.block.md >/dev/null 2>&1 || fail "no backup of the edited block"
# 지운 스킬 · 지운 규칙 블록은 말없이 되살리지 않는다
rm -rf "$T/.claude/skills/light-undo"
rc=0; run || rc=$?
[ "$rc" = 3 ] && [ ! -e "$T/.claude/skills/light-undo" ] && grep -q "^ask .claude/skills/light-undo - " "$ST" || { cat "$T.out"; fail "deleted skill not asked about (exit $rc)"; }
rc=0; run --keep light-undo || rc=$?
[ "$rc" = 0 ] && [ ! -e "$T/.claude/skills/light-undo" ] || fail "keep deleted skill"
rc=0; run --update light-undo,light-save || rc=$?                    # 여럿은 쉼표로
[ "$rc" = 0 ] && [ -f "$T/.claude/skills/light-undo/SKILL.md" ] || fail "update deleted skill back (comma list)"
rc=0; run --update light-nope || rc=$?
[ "$rc" = 2 ] || fail "unknown name accepted (exit $rc)"
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
# 줄바꿈이 CRLF 로 바뀐 · BOM 이 붙은 AGENTS.md (Windows 편집기) 도 블록을 알아본다 -- 하나 더 붙이지 않는다
if [ "$MODE" = bash ]; then
  { printf '\357\273\277'; cat "$T/AGENTS.md"; } > "$T/AGENTS.bom" && mv "$T/AGENTS.bom" "$T/AGENTS.md"
  rc=0; run || rc=$?
  [ "$rc" = 0 ] || { cat "$T.out"; fail "BOM AGENTS.md asked about (exit $rc)"; }
  [ "$(grep -c 'dev-process-light:begin' "$T/AGENTS.md")" = 1 ] || fail "BOM AGENTS.md got a second block"
  sed 's/$/\r/' "$T/AGENTS.md" > "$T/AGENTS.crlf" && mv "$T/AGENTS.crlf" "$T/AGENTS.md"
  rc=0; run || rc=$?
  [ "$rc" = 0 ] || { cat "$T.out"; fail "CRLF AGENTS.md asked about (exit $rc)"; }
  [ "$(grep -c 'dev-process-light:begin' "$T/AGENTS.md")" = 1 ] || fail "CRLF AGENTS.md got a second block"
fi
# 예전 버전(0.8, 훅에 버전 줄 없음 · .gitignore 줄은 넣어 두었다)의 데이터 검사 장치 → hook status 가 다르다고 하고 → hook install 뒤 최신 → 정본 저장이 훅을 통과
if [ "$MODE" = bash ] && [ -n "$PY" ] && command -v git >/dev/null 2>&1; then
  G="$(mktemp -d)/repo"; mkdir -p "$G"; git -C "$G" init -q
  bash "$ROOT/install.sh" "$G" >/dev/null
  DL="$G/.claude/skills/data-light/scripts/datalight.py"
  mkdir -p "$G/.git/hooks"; printf '#!/bin/sh\n# data-light pre-commit (datalight.py hook install)\nexit 0\n' > "$G/.git/hooks/pre-commit"
  mkdir -p "$G/.data-light"; cp "$DL" "$G/.data-light/datalight.py"
  "$PY" -B - "$DL" > "$G/.gitignore" <<'PYEOF'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("dl", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
print("\n".join(m.GITIGNORE_LINES))
PYEOF
  (cd "$G" && "$PY" -B "$DL" hook status >/dev/null) && fail "old hook reported as current"
  (cd "$G" && "$PY" -B "$DL" hook install --no-ci >/dev/null) || fail "hook install"
  (cd "$G" && "$PY" -B "$DL" hook status >/dev/null) || fail "hook not current after install"
  [ -e "$G/.github/workflows/data-light.yml" ] && fail "--no-ci created a CI file"
  sh -n "$G/.git/hooks/pre-commit" 2>/dev/null || fail "installed hook is not readable by this sh"   # data-light 0.4.1 부터 macOS 의 sh 도 읽는다
  mkdir -p "$G/data"; cp "$ROOT/kit/skills/data-light/examples/shop/data/model.light.json" "$G/data/"
  (cd "$G" && "$PY" -B "$DL" build data/model.light.json --out data/out >/dev/null) || fail "build"
  git -C "$G" add data/model.light.json data/out/schema.sql data/out/erd.md data/out/spec.md data/out/book.html
  git -C "$G" -c user.name=t -c user.email=t@t commit -q -m "데이터: 시험" >/dev/null 2>&1 || fail "commit through the data hook"
  printf '{"format": "data-light/1", "tables": []}\n' > "$G/data/model.light.json"; git -C "$G" add data/model.light.json
  git -C "$G" -c user.name=t -c user.email=t@t commit -q -m "데이터: 망가뜨림" >/dev/null 2>&1 && fail "broken model committed past the hook"
fi
echo "PASS ($MODE): install, re-install, paired data-light, data hook upgrade, user notes·data and AGENTS.md content preserved"
