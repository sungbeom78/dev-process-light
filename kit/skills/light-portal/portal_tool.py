"""기록 보기 페이지 만들기 -- dev-notes 기록과 저장(git) 목록, 데이터 설계(data-light 정본이 있으면)를 한 화면에서 보는 HTML 파일 한 개.

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
KINDS = ["기능", "수정", "모양", "정리", "데이터", "중간 저장", "되돌리기", "준비"]
DEFAULT_OUT = "dev-notes/portal.html"
MAX_FEATURE_FILES = 400
MODEL = "data/model.light.json"          # 짝 스킬 data-light 의 정본
COL_KEYS = ("name", "label", "type", "required", "unique", "choices", "ref", "on_delete", "key", "personal", "about")


def _git(root: Path, *args: str) -> str:
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    try:
        r = subprocess.run(["git", "-c", "core.quotepath=false", "-C", str(root), *args], capture_output=True, text=True, encoding="utf-8",
                           errors="replace", env=env)
    except FileNotFoundError:
        return ""
    return r.stdout.rstrip() if r.returncode == 0 else ""      # 앞 공백은 남긴다 (git status 의 " M 파일")


def _project_name(now: str, root: Path) -> str:
    m = re.search(r"## 이 프로젝트는\s*\n+([^\n#<][^\n]*)", now or "")
    line = (m.group(1).strip() if m else "") or root.name
    return line if len(line) <= 60 else line[:58] + "…"


def _rel(target: Path, out: Path) -> str:
    try:
        return Path(os.path.relpath(target, out.parent)).as_posix()
    except ValueError:            # Windows 에서 드라이브가 다르면
        return target.resolve().as_uri()


def data_summary(root: Path, out: Path) -> dict | None:
    """data-light 정본의 구조만 (샘플 행·기본값 밖의 값은 담지 않는다 -- 페이지는 구조를 보여 주는 곳)."""
    p = root / MODEL
    if not p.is_file():
        return None
    try:
        m = json.loads(p.read_text(encoding="utf-8"))
        tables = []
        for t in m.get("tables") or []:
            cols = [{k: c[k] for k in COL_KEYS if k in c} for c in (t.get("columns") or []) if isinstance(c, dict)]
            uniq = [[str(x) for x in u] for u in (t.get("unique") or []) if isinstance(u, list)]   # 두 칸 이상 묶은 중복 금지
            tables.append({"name": t.get("name", ""), "label": t.get("label", ""), "about": t.get("about", ""),
                           "timestamps": t.get("timestamps", True) is not False, "columns": cols, "unique": uniq})
        goals = [{"say": g.get("say", ""), "sql": g.get("sql", "")} for g in (m.get("goals") or []) if isinstance(g, dict)]
        info = {"file": MODEL, "project": m.get("project", ""), "db": m.get("db", "sqlite"), "tables": tables,
                "goals": goals, "not_doing": [str(x) for x in (m.get("not_doing") or [])]}   # 성공 기준의 기대 결과(샘플 값)는 담지 않는다
    except (ValueError, AttributeError, TypeError) as e:
        info = {"file": MODEL, "error": f"정본을 읽지 못함: {e}", "tables": []}
    info["links"] = {n: _rel(root / "data" / "out" / n, out) for n in ("erd.md", "spec.md", "schema.sql")
                     if (root / "data" / "out" / n).is_file()}
    return info


def collect(root: Path, out: Path) -> dict:
    notes = {}
    for n in NOTES:
        p = root / "dev-notes" / f"{n}.md"
        notes[n] = p.read_text(encoding="utf-8") if p.is_file() else None
    logdir = root / "dev-notes" / "log"
    archive = sorted([*logdir.glob("_흐름/*.md"), *logdir.glob("*.md")], key=lambda p: p.stem, reverse=True) if logdir.is_dir() else []
    feature_logs = []
    if logdir.is_dir():
        for p in sorted(logdir.glob("*/*.md"), key=lambda p: (p.stem, p.parent.name), reverse=True)[:MAX_FEATURE_FILES]:
            if p.parent.name.startswith("_"):
                continue
            text = p.read_text(encoding="utf-8", errors="replace")
            feature_logs.append({"feature": p.parent.name, "date": p.stem,
                                 "text": text if len(text) <= 60000 else text[:60000] + "\n\n… (잘림 -- 파일을 열어 본다)"})
    saves = []
    for line in _git(root, "log", "-80", "--format=%h%x00%cI%x00%s").splitlines():
        h, when, msg = (line.split("\x00") + ["", ""])[:3]
        kind = next((k for k in KINDS if msg.startswith(k + ":")), "")
        saves.append({"hash": h, "at": when, "msg": msg, "kind": kind})
    dirty = [ln[3:] for ln in _git(root, "status", "--porcelain").splitlines() if ln[3:] and not ln[3:].startswith("dev-notes/portal")]
    manual = root / "manual" / "index.html"
    manual_href = _rel(manual, out) if manual.is_file() else None
    return {"project": _project_name(notes["NOW"], root), "folder": str(root), "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
            "notes": notes, "archive": [{"name": p.stem, "text": p.read_text(encoding="utf-8")} for p in archive[:24]],
            "feature_logs": feature_logs,
            "saves": saves, "dirty": dirty, "remote": bool(_git(root, "remote")), "manual": manual_href,
            "data": data_summary(root, out)}


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
