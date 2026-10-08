"""관리자용 점검 (사용자는 필요 없음). CI 와 로컬에서: python scripts/check_kit.py

- 스킬: 폴더 이름 = frontmatter name, 필드는 name·description 만 (Agent Skills 표준), description 1024자 이하
- 스킬끼리 이름으로 서로 가리키는 것이 실제로 존재하는지
- AGENTS.md 블록 표시가 있고 한 쌍인지, 템플릿 4장이 있는지
- README·INSTALL·예시 문서의 상대 링크가 실제 파일을 가리키는지
- 모든 텍스트 파일이 BOM 없는 UTF-8 인지 (Windows 에서 깨지지 않게)
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "kit"
SKILLS = ["light-resume", "light-start", "light-check", "light-save", "light-undo", "light-manual"]
NOTES = ["NOW.md", "FEATURES.md", "DECISIONS.md", "NAMES.md"]
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
for name in SKILLS:
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

for doc in [ROOT / "README.md", ROOT / "README.en.md", ROOT / "INSTALL.md", *ROOT.glob("examples/**/*.md")]:
    for link in re.findall(r"\]\(([^)#]+)\)", doc.read_text(encoding="utf-8")):
        if link.startswith(("http://", "https://", "mailto:")):
            continue
        if not (doc.parent / link).exists():
            errors.append(f"{doc.relative_to(ROOT)}: 깨진 링크 {link}")

for f in ROOT.rglob("*"):
    if f.is_file() and ".git" not in f.parts and f.suffix in {".md", ".sh", ".ps1", ".py", ".yml", ".html", ".js", ".css", ""}:
        raw = f.read_bytes()
        if raw.startswith(b"\xef\xbb\xbf"):
            errors.append(f"{f.relative_to(ROOT)}: BOM")
        try:
            raw.decode("utf-8")
        except UnicodeDecodeError:
            errors.append(f"{f.relative_to(ROOT)}: UTF-8 아님")

if errors:
    print("FAIL")
    for e in errors:
        print("  -", e)
    sys.exit(1)
print(f"PASS -- 스킬 {len(SKILLS)}개, 기록 템플릿 {len(NOTES)}장, 링크·인코딩 정상")
