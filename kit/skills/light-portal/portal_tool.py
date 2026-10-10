"""기록 보기 페이지 만들기 -- dev-notes 기록과 저장(git) 목록을 한 화면에서 보는 HTML 파일 한 개.

    python portal_tool.py build [--root .] [--out dev-notes/portal.html]

- 서버·로그인 없이 브라우저로 파일을 연다. 인터넷에 올리지 않는다.
- 프로젝트 안에 만들면 .gitignore 에 넣는다 (기록에서 다시 만들 수 있는 파일이라 저장할 필요가 없다).
- 파이썬 표준 라이브러리만 쓴다 (Windows·macOS·Linux).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

try:   # Windows 콘솔에서 한글이 깨지지 않게
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:  # noqa: BLE001
    pass

HERE = Path(__file__).resolve().parent
NOTES = ["NOW", "FEATURES", "DECISIONS", "LOG", "NAMES", "LEARNED"]
KINDS = ["기능", "수정", "모양", "정리", "중간 저장", "되돌리기", "준비"]
DEFAULT_OUT = "dev-notes/portal.html"


def _git(root: Path, *args: str) -> str:
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    try:
        r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8",
                           errors="replace", env=env)
    except FileNotFoundError:
        return ""
    return r.stdout.rstrip() if r.returncode == 0 else ""      # 앞 공백은 남긴다 (git status 의 " M 파일")


def _project_name(now: str, root: Path) -> str:
    m = re.search(r"## 이 프로젝트는\s*\n+([^\n#<][^\n]*)", now or "")
    line = (m.group(1).strip() if m else "") or root.name
    return line if len(line) <= 60 else line[:58] + "…"


def collect(root: Path, out: Path) -> dict:
    notes = {}
    for n in NOTES:
        p = root / "dev-notes" / f"{n}.md"
        notes[n] = p.read_text(encoding="utf-8") if p.is_file() else None
    archive = sorted((root / "dev-notes" / "log").glob("*.md"), reverse=True) if (root / "dev-notes" / "log").is_dir() else []
    saves = []
    for line in _git(root, "log", "-80", "--format=%h%x00%cI%x00%s").splitlines():
        h, when, msg = (line.split("\x00") + ["", ""])[:3]
        kind = next((k for k in KINDS if msg.startswith(k + ":")), "")
        saves.append({"hash": h, "at": when, "msg": msg, "kind": kind})
    dirty = [ln[3:] for ln in _git(root, "status", "--porcelain").splitlines() if ln[3:] and not ln[3:].startswith("dev-notes/portal")]
    manual = root / "manual" / "index.html"
    try:
        manual_href = Path(os.path.relpath(manual, out.parent)).as_posix() if manual.is_file() else None
    except ValueError:
        manual_href = manual.resolve().as_uri()
    return {"project": _project_name(notes["NOW"], root), "folder": str(root), "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
            "notes": notes, "archive": [{"name": p.stem, "text": p.read_text(encoding="utf-8")} for p in archive[:24]],
            "saves": saves, "dirty": dirty, "remote": bool(_git(root, "remote")), "manual": manual_href}


def _ensure_ignored(root: Path, out: Path) -> str | None:
    try:
        rel = out.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return None
    gi = root / ".gitignore"
    have = gi.read_text(encoding="utf-8").splitlines() if gi.is_file() else []
    if rel in have or "/" + rel in have:
        return None
    gi.write_text("\n".join([*have, "# 기록 보기 페이지 (dev-notes 에서 다시 만든다)", rel]) + "\n", encoding="utf-8")
    return rel


def build(root: Path, out: Path) -> dict:
    root, out = root.resolve(), (out if out.is_absolute() else root / out).resolve()
    data = collect(root, out)
    html = (HERE / "templates" / "portal.html").read_text(encoding="utf-8")
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c")
    title = (data["project"] + " -- 기록").replace("&", "&amp;").replace("<", "&lt;")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html.replace("__TITLE__", title).replace("__DATA__", blob), encoding="utf-8")
    return {"out": str(out), "uri": out.as_uri(), "ignored": _ensure_ignored(root, out), "saves": len(data["saves"])}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="기록 보기 페이지 만들기")
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("--root", default=".")
    b.add_argument("--out", default=DEFAULT_OUT)
    a = ap.parse_args(argv)
    rep = build(Path(a.root), Path(a.out))
    print(f"[OK] 기록 보기 페이지: {rep['out']}")
    print(f"     브라우저로 열기: {rep['uri']}")
    if rep["ignored"]:
        print(f"[OK] .gitignore 에 {rep['ignored']} 추가 (저장하지 않는 파일)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
