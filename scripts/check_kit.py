"""관리자용 점검 (사용자는 필요 없음). CI 와 로컬에서: python scripts/check_kit.py

- 스킬: 폴더 이름 = frontmatter name, 필드는 name·description 만 (Agent Skills 표준), description 1024자 이하
- 스킬끼리 이름으로 서로 가리키는 것이 실제로 존재하는지
- AGENTS.md 블록 표시가 있고 한 쌍인지, 템플릿 4장이 있는지
- README·INSTALL·예시 문서의 상대 링크가 실제 파일을 가리키는지
- 짝 스킬 data-light: 사본이 잠금 파일(data-light.lock.json)과 바이트 그대로인지, 실제로 돌아가는지(check·try·build),
  README 의 짝 버전, 규칙·템플릿의 연결(NOW 다섯 줄·FEATURES 데이터 절), 데이터 예시의 생성물이 정본과 맞는지
- 모든 텍스트 파일이 BOM 없는 UTF-8 인지 (Windows 에서 깨지지 않게) -- PowerShell 스크립트만 BOM 이 있어야 한다 (5.1)
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

try:   # Windows 콘솔(cp1252/cp949)에서 한글 출력이 깨지거나 멈추지 않게
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:  # noqa: BLE001
    pass

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "kit"
LIGHT = ["light-resume", "light-start", "light-check", "light-save", "light-undo", "light-manual", "light-portal"]
PAIRED = ["data-light"]          # 짝 스킬 -- 원본은 data-expert-framework-light, 여기서는 고정한 사본 (scripts/update_data_light.py)
SKILLS = LIGHT + PAIRED
DATA_EXAMPLES = [ROOT / "examples" / "club-dues"]
NOTES = ["NOW.md", "FEATURES.md", "DECISIONS.md", "NAMES.md", "LOG.md"]
errors: list[str] = []


def frontmatter(text: str) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return {}
    out = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith(" "):
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out


found = sorted(p.name for p in (KIT / "skills").iterdir() if p.is_dir())
if found != sorted(SKILLS):
    errors.append(f"스킬 폴더 {found} != {sorted(SKILLS)}")
for name in LIGHT:
    f = KIT / "skills" / name / "SKILL.md"
    if not f.exists():
        errors.append(f"{f} 없음"); continue
    text = f.read_text(encoding="utf-8")
    fm = frontmatter(text)
    if fm.get("name") != name:
        errors.append(f"{name}: frontmatter name={fm.get('name')!r}")
    if set(fm) != {"name", "description"}:
        errors.append(f"{name}: frontmatter 필드는 name, description 만 ({sorted(fm)})")
    if not (20 <= len(fm.get("description", "")) <= 1024):
        errors.append(f"{name}: description 길이 {len(fm.get('description', ''))}")
    for ref in set(re.findall(r"light-[a-z]+", text)):
        if ref not in SKILLS:
            errors.append(f"{name}: 없는 스킬 이름 {ref}")

agents = (KIT / "AGENTS.md").read_text(encoding="utf-8")
if agents.count("<!-- dev-process-light:begin -->") != 1 or agents.count("<!-- dev-process-light:end -->") != 1:
    errors.append("kit/AGENTS.md 블록 표시가 한 쌍이 아님")
for ref in set(re.findall(r"light-[a-z]+", agents)):
    if ref not in SKILLS:
        errors.append(f"AGENTS.md: 없는 스킬 이름 {ref}")
for n in NOTES:
    if not (KIT / "dev-notes" / n).exists():
        errors.append(f"kit/dev-notes/{n} 없음")

LM = KIT / "skills" / "light-manual"
for f in ("assets/manual.css", "assets/manual.js", "templates/index.html", "templates/chapter.html", "manual_tool.py"):
    if not (LM / f).is_file():
        errors.append(f"light-manual/{f} 없음")
LP = KIT / "skills" / "light-portal"
for f in ("portal_tool.py", "templates/portal.html"):
    if not (LP / f).is_file():
        errors.append(f"light-portal/{f} 없음")
if "## 설정" not in (KIT / "dev-notes" / "NOW.md").read_text(encoding="utf-8"):
    errors.append("kit/dev-notes/NOW.md 에 ## 설정 없음")
# 기록 보기 페이지: 템플릿 기록으로 실제로 만들어 본다 (git 없는 폴더에서도, 기록 속 </script> 가 페이지를 깨지 않게)
import json as _json, shutil as _shutil, tempfile as _tempfile  # noqa: E402
sys.dont_write_bytecode = True
sys.path.insert(0, str(LP))
import portal_tool  # noqa: E402
with _tempfile.TemporaryDirectory() as _d:
    _root = Path(_d) / "p"
    _shutil.copytree(KIT / "dev-notes", _root / "dev-notes")
    with open(_root / "dev-notes" / "LOG.md", "a", encoding="utf-8") as _f:
        _f.write("- 2026-10-11 10:00 · 확인 · 할 일 · </script><b>x</b> · 실패 · AI\n")
    (_root / "data").mkdir()
    _shutil.copy(KIT / "skills" / "data-light" / "examples" / "shop" / "data" / "model.light.json", _root / "data" / "model.light.json")
    (_root / "dev-notes" / "log" / "할-일").mkdir(parents=True)
    (_root / "dev-notes" / "log" / "할-일" / "2026-10-11.md").write_text(
        "# 할 일 -- 2026-10-11\n\n## 목록\n- #1 10:00 [확인] 새로고침 -- 실패\n\n## 자세히\n### #1 10:00 [확인]\n- 오류: x\n", encoding="utf-8")
    _rep = portal_tool.build(_root, Path("dev-notes/portal.html"))
    _html = (_root / "dev-notes" / "portal.html").read_text(encoding="utf-8")
    _m = re.search(r'<script type="application/json" id="data">(.*?)</script>', _html, re.S)
    if not _m or "__DATA__" in _html:
        errors.append("light-portal: 데이터가 페이지에 들어가지 않음")
    else:
        _data = _json.loads(_m.group(1))
        if "</script><b>x</b>" not in _data["notes"]["LOG"]:
            errors.append("light-portal: 기록 내용이 바뀜")
        if [(x["feature"], x["date"]) for x in _data.get("feature_logs", [])] != [("할-일", "2026-10-11")]:
            errors.append("light-portal: 기능별 기록 파일을 담지 못함")
        _dm = _data.get("data") or {}
        if sorted(t["name"] for t in _dm.get("tables", [])) != sorted(
                t["name"] for t in _json.loads((_root / "data" / "model.light.json").read_text(encoding="utf-8"))["tables"]):
            errors.append("light-portal: 데이터 설계(표 목록)를 담지 못함")
        if any("sample" in t or any("default" in c for c in t.get("columns", [])) for t in _dm.get("tables", [])):
            errors.append("light-portal: 데이터 설계의 샘플 값이 페이지에 들어감 (구조만 담는다)")
    if "dev-notes/portal.html" not in (_root / ".gitignore").read_text(encoding="utf-8"):
        errors.append("light-portal: .gitignore 에 넣지 않음")
ex = ROOT / "examples" / "my-homepage" / "manual"
for a in ("manual.css", "manual.js"):
    if (ex / "assets" / a).read_bytes() != (LM / "assets" / a).read_bytes():
        errors.append(f"예시 manual/assets/{a} 가 스킬 assets 와 다름")
sys.dont_write_bytecode = True   # kit 안에 __pycache__ 를 만들지 않는다 (설치될 때 같이 복사됨)
sys.path.insert(0, str(LM))
import manual_tool  # noqa: E402
errors += [f"예시 설명서: {p}" for p in manual_tool.check(ex)]

for doc in [ROOT / "README.md", ROOT / "README.en.md", ROOT / "INSTALL.md", *ROOT.glob("examples/**/*.md")]:
    for link in re.findall(r"\]\(([^)#]+)\)", doc.read_text(encoding="utf-8")):
        if link.startswith(("http://", "https://", "mailto:")):
            continue
        if not (doc.parent / link).exists():
            errors.append(f"{doc.relative_to(ROOT)}: 깨진 링크 {link}")

for f in ROOT.rglob("*"):
    if f.is_file() and ".git" not in f.parts and "__pycache__" not in f.parts and f.suffix in {".md", ".sh", ".ps1", ".py", ".yml", ".html", ".js", ".css", ""}:
        raw = f.read_bytes()
        if f.suffix == ".ps1":     # Windows PowerShell 5.1 은 BOM 이 없는 UTF-8 스크립트를 시스템 코드 페이지로 읽어 한글이 깨진다
            if not raw.startswith(b"\xef\xbb\xbf"):
                errors.append(f"{f.relative_to(ROOT)}: PowerShell 스크립트는 BOM 이 있는 UTF-8 이어야 함 (5.1 에서 한글)")
        elif raw.startswith(b"\xef\xbb\xbf"):
            errors.append(f"{f.relative_to(ROOT)}: BOM")
        try:
            raw.decode("utf-8")
        except UnicodeDecodeError:
            errors.append(f"{f.relative_to(ROOT)}: UTF-8 아님")

# ---- 짝 스킬 data-light ---------------------------------------------------------------------------
import subprocess as _sp  # noqa: E402
sys.path.insert(0, str(ROOT / "scripts"))
import update_data_light as _udl  # noqa: E402
errors += _udl.verify()
_lock = _json.loads((ROOT / "data-light.lock.json").read_text(encoding="utf-8")) if (ROOT / "data-light.lock.json").is_file() else {}
_dl = KIT / "skills" / "data-light"
_dl_fm = frontmatter((_dl / "SKILL.md").read_text(encoding="utf-8")) if (_dl / "SKILL.md").is_file() else {}
if _dl_fm.get("name") != "data-light":
    errors.append("data-light: SKILL.md 의 name 이 data-light 가 아님 (설치된 스킬 이름이 달라진다)")
for doc in ("README.md", "README.en.md"):
    _txt = (ROOT / doc).read_text(encoding="utf-8")
    if _lock and (f"data-light {_lock['version']}" not in _txt or f"`{_lock['commit'][:7]}`" not in _txt):
        errors.append(f"{doc}: 짝 버전 'data-light {_lock.get('version')}' · 커밋 `{_lock.get('commit', '')[:7]}` 이 없음 (data-light.lock.json 과 맞춘다)")
if "`data-light`" not in agents or "data/model.light.json" not in agents:
    errors.append("kit/AGENTS.md: 데이터 규칙(data-light, data/model.light.json)이 없음")
_now_t = (KIT / "dev-notes" / "NOW.md").read_text(encoding="utf-8")
FIVE = ["누가 쓰나", "로그인", "올리는 곳", "저장하는 데이터", "개인정보"]
for k in FIVE:
    if not re.search(rf"^- {k}: ", _now_t, re.M):
        errors.append(f"kit/dev-notes/NOW.md: '이 프로젝트는' 의 '- {k}:' 줄이 없음 (light·data-light 가 같이 쓰는 답)")
if "- 데이터 검사 장치:" not in _now_t:
    errors.append("kit/dev-notes/NOW.md: ## 설정 에 '- 데이터 검사 장치:' 줄이 없음 (light-start 가 한 번 묻는다)")
if "- 데이터:" not in _now_t:
    errors.append("kit/dev-notes/NOW.md: 작업 카드 형식에 '- 데이터:' 줄이 없음")
if "## 데이터 (표)" not in (KIT / "dev-notes" / "FEATURES.md").read_text(encoding="utf-8"):
    errors.append("kit/dev-notes/FEATURES.md: '## 데이터 (표)' 절이 없음")
for _sk in ("light-start", "light-check", "light-save", "light-undo", "light-resume"):
    if "data-light" not in (KIT / "skills" / _sk / "SKILL.md").read_text(encoding="utf-8"):
        errors.append(f"{_sk}: 짝 스킬 data-light 로 넘기는 곳이 없음")


def _datalight(*args: str, cwd: Path) -> tuple[int, str]:
    # Windows 파이프(cp1252)를 흉내 낸다 -- 도구가 한글을 ???? 로 깨뜨리면 AI 가 FAIL 이유를 읽지 못한다
    env = {k: v for k, v in __import__("os").environ.items() if k != "PYTHONUTF8"}
    env["PYTHONIOENCODING"] = "cp1252"
    r = _sp.run([sys.executable, "-B", str(_dl / "scripts" / "datalight.py"), *args], cwd=str(cwd), capture_output=True,
                text=True, encoding="utf-8", errors="replace", env=env)
    out = (r.stdout + r.stderr).strip()
    if "결과" not in out and args[0] in ("check", "try", "verify"):
        errors.append(f"datalight {args[0]}: 한글 출력이 깨짐 (cp1252 파이프) -- {out[-120:]!r}")
    return r.returncode, out


def _features_tables(text: str) -> set[str]:
    m = re.search(r"^## 데이터[^\n]*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    out = set()
    for line in (m.group(1) if m else "").splitlines():
        cells = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
        if line.lstrip().startswith("|") and len(cells) >= 3 and cells[0] not in ("표", "") and not set(cells[0]) <= set(":- ") \
                and "(예)" not in line:
            out.add(cells[0])
    return out


_shop = _dl / "examples" / "shop"
for ex in [_shop, *DATA_EXAMPLES]:
    name = ex.relative_to(ROOT).as_posix()
    model = ex / "data" / "model.light.json"
    if not model.is_file():
        errors.append(f"{name}: data/model.light.json 없음"); continue
    with _tempfile.TemporaryDirectory() as _d:
        work = Path(_d) / "p"
        _shutil.copytree(ex / "data", work / "data")
        for cmd in (["check", "data/model.light.json"], ["try", "data/model.light.json"], ["verify", "data/model.light.json", "--no-db"]):
            rc, out = _datalight(*cmd, cwd=work)
            if rc != 0:
                errors.append(f"{name}: datalight {cmd[0]} 실패 (rc={rc}): {out[-300:]}")
        db = _json.loads(model.read_text(encoding="utf-8")).get("db", "sqlite")
        rc, out = _datalight("build", "data/model.light.json", "--out", "fresh", "--db", db, cwd=work)
        if rc != 0:
            errors.append(f"{name}: datalight build 실패: {out[-300:]}")
        else:
            for f in ("schema.sql", "erd.md", "spec.md"):
                have, fresh = ex / "data" / "out" / f, work / "fresh" / f
                if not have.is_file() or have.read_bytes().replace(b"\r\n", b"\n") != fresh.read_bytes().replace(b"\r\n", b"\n"):
                    errors.append(f"{name}: data/out/{f} 가 정본에서 다시 만든 것과 다름 (build 를 다시 돌린다)")
    if ex in DATA_EXAMPLES:
        notes = ex / "dev-notes"
        tables = {t["name"] for t in _json.loads(model.read_text(encoding="utf-8"))["tables"]}
        feat = _features_tables((notes / "FEATURES.md").read_text(encoding="utf-8"))
        if feat != tables:
            errors.append(f"{name}: FEATURES.md 데이터 절의 표 {sorted(feat)} != 정본의 표 {sorted(tables)}")
        now = (notes / "NOW.md").read_text(encoding="utf-8")
        for k in FIVE:
            m = re.search(rf"^- {k}: (.*)$", now, re.M)
            if not m or "(아직 모름)" in m.group(1):
                errors.append(f"{name}: NOW.md '- {k}:' 가 비어 있음")
        if not re.search(r"^- 저장하는 데이터: data-light", now, re.M):
            errors.append(f"{name}: NOW.md 저장하는 데이터가 data-light 설계가 아님")
        gi = (ex / ".gitignore").read_text(encoding="utf-8").split() if (ex / ".gitignore").is_file() else []
        for line in ("data/app.db", "data/backup/", "data/*.csv", "data/*.xlsx", "data/out/spec.xlsx", "data/import_plan*.json", "import_plan*.json", ".env"):
            if line not in gi:
                errors.append(f"{name}: .gitignore 에 {line} 없음")
        if not re.search(r"^- \d{4}-\d{2}-\d{2} \d{1,2}:\d{2} · 기획 · 데이터 · ", (notes / "LOG.md").read_text(encoding="utf-8"), re.M):
            errors.append(f"{name}: LOG.md 에 '· 기획 · 데이터 ·' 흐름 줄이 없음")
        if not list((notes / "log" / "데이터").glob("*.md")):
            errors.append(f"{name}: dev-notes/log/데이터/<날짜>.md 없음")
# 짝 사본 안에 실행 흔적이 생기지 않았는지 (설치 때 같이 복사된다)
if [p for p in _dl.rglob("__pycache__")] or list(_dl.rglob("*.db")):
    errors.append("kit/skills/data-light 안에 __pycache__ 나 .db 가 생김 -- 지운다")

if errors:
    print("FAIL")
    for e in errors:
        print("  -", e)
    sys.exit(1)
print(f"PASS -- 스킬 {len(SKILLS)}개(짝 data-light {_lock.get('version', '?')} 포함), 기록 템플릿 {len(NOTES)}장, 데이터 예시 {len(DATA_EXAMPLES)}개, 링크·인코딩 정상")
