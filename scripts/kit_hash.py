#!/usr/bin/env python3
"""설치한 스킬 · 규칙 블록의 지문 -- install.sh / install.ps1 과 같은 셈법 (셋이 같은 값을 내야 한다).

설치기는 다시 설치할 때 이 지문으로 '직접 고쳤나'를 본다 (소유자 원칙 2026-10-20: 새 판 반영이 원칙, 다르면 사용자에게 묻는다):
  - 프로젝트의 것 == 새 판 · 지난번에 설치한 것 · 예전 판(kit/.history) 중 하나 -> 손대지 않았다: 새 판으로 바꾼다
  - 그 밖 -> 직접 고쳤다: 손대지 않고 물어볼 것으로 남긴다 (--update / --keep)

지문:
  스킬 폴더 = sha256( 줄마다 "<상대 경로>\\t<sha256(파일 바이트에서 \\r 를 뺀 것)>\\n", 경로 순(바이트 순) )[:16]
              (.light-kit* · __pycache__/ · *.pyc · .DS_Store · Thumbs.db · desktop.ini · 심링크는 뺀다)
  규칙 블록 = sha256( 시작 줄부터 끝 줄까지(둘 다 줄 머리), 줄마다 \\r 를 빼고 "\\n" 으로 이은 것 -- 맨 앞 BOM 은 뺀다 )[:16]

    python scripts/kit_hash.py dir <폴더>          # 폴더 지문
    python scripts/kit_hash.py block <AGENTS.md>   # 규칙 블록 지문
    python scripts/kit_hash.py history --write      # kit/.history 다시 만들기 (git 이력의 모든 판)
    python scripts/kit_hash.py history --check      # kit/.history 가 맞나 (얕은 clone 이면 지금 판만)
"""
from __future__ import annotations

import hashlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / "kit"
HISTORY = KIT / ".history"
BEGIN = "<!-- dev-process-light:begin -->"
END = "<!-- dev-process-light:end -->"
HEAD_LINE = "# dev-process-light 예전 판 지문 (scripts/kit_hash.py history --write) -- 설치기가 '손대지 않은 예전 판'을 알아본다"


JUNK = {".DS_Store", "Thumbs.db", "desktop.ini"}    # OS 가 만드는 파일 -- 직접 고친 것으로 보지 않는다


def _skip(rel: str) -> bool:
    name = rel.rsplit("/", 1)[-1]
    return name.startswith(".light-kit") or name.endswith(".pyc") or name in JUNK or "__pycache__" in rel.split("/")


def tree_hash(files: dict) -> str:
    rows = []
    for rel in sorted((r for r in files if not _skip(r)), key=lambda r: r.encode("utf-8")):
        digest = hashlib.sha256(files[rel].replace(b"\r", b"")).hexdigest()      # 3.9: f-string 안에 \ 를 쓰지 않는다
        rows.append(f"{rel}\t{digest}\n")
    return hashlib.sha256("".join(rows).encode("utf-8")).hexdigest()[:16]


def dir_hash(path: Path) -> str:
    path = Path(path)
    return tree_hash({p.relative_to(path).as_posix(): p.read_bytes() for p in path.rglob("*") if p.is_file() and not p.is_symlink()})


def block_hash(text: str) -> str | None:
    out, on = [], False
    for line in text.lstrip("\ufeff").replace("\r", "").split("\n"):
        if not on and line.startswith(BEGIN):
            on = True
        if on:
            out.append(line + "\n")
            if line.startswith(END):
                return hashlib.sha256("".join(out).encode("utf-8")).hexdigest()[:16]
    return None


def _git(*a: str) -> str:
    r = subprocess.run(["git", "-C", str(ROOT), *a], capture_output=True)
    return r.stdout.decode("utf-8", "replace") if r.returncode == 0 else ""


def _tree_at(commit: str, prefix: str) -> dict:
    out = {}
    for line in _git("ls-tree", "-r", "-z", commit, "--", prefix).split("\0"):
        if not line.strip():
            continue
        meta, path = line.split("\t", 1)
        if meta.split()[1] != "blob":
            continue
        blob = subprocess.run(["git", "-C", str(ROOT), "cat-file", "blob", meta.split()[2]], capture_output=True).stdout
        out[path[len(prefix):]] = blob
    return out


def history() -> list[str]:
    """git 이력의 모든 판 + 지금 작업 폴더의 판 -- 'skill <이름> <지문>' · 'block <지문>' (같은 줄은 한 번)."""
    rows: list[str] = []
    seen = set()

    def add(r: str):
        if r not in seen:
            seen.add(r)
            rows.append(r)
    for c in [x for x in _git("log", "--format=%H", "--", "kit").split() if x][::-1]:
        names = sorted({p.split("/")[2] for p in _git("ls-tree", "-r", "--name-only", c, "--", "kit/skills/").split() if p.count("/") >= 3})
        for n in names:
            add(f"skill {n} {tree_hash(_tree_at(c, f'kit/skills/{n}/'))}")
        b = block_hash(_git("show", f"{c}:kit/AGENTS.md"))
        if b:
            add(f"block {b}")
    for d in sorted(p for p in (KIT / "skills").iterdir() if p.is_dir()):
        add(f"skill {d.name} {dir_hash(d)}")
    b = block_hash((KIT / "AGENTS.md").read_text(encoding="utf-8"))
    if b:
        add(f"block {b}")
    return rows


def main(argv: list[str]) -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:  # noqa: BLE001
        pass
    if len(argv) >= 2 and argv[0] == "dir":
        print(dir_hash(Path(argv[1])))
        return 0
    if len(argv) >= 2 and argv[0] == "block":
        print(block_hash(Path(argv[1]).read_text(encoding="utf-8", errors="replace")) or "")
        return 0
    if argv[:1] == ["history"]:
        rows = history()
        body = HEAD_LINE + "\n" + "".join(r + "\n" for r in rows)
        if "--write" in argv:
            with open(HISTORY, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(body)
            print(f"kit/.history: {len(rows)}줄")
            return 0
        have = set(HISTORY.read_text(encoding="utf-8").splitlines()) if HISTORY.exists() else set()
        shallow = _git("rev-parse", "--is-shallow-repository").strip() == "true"
        need = rows if not shallow else [r for r in rows if r in history_now()]
        miss = [r for r in need if r not in have]
        if miss:
            print("kit/.history 가 낡았다 -- python scripts/kit_hash.py history --write: " + ", ".join(miss[:5]))
            return 1
        print("kit/.history: 맞음" + (" (얕은 clone -- 지금 판만 봄)" if shallow else ""))
        return 0
    print(__doc__)
    return 2


def history_now() -> set:
    rows = {f"skill {d.name} {dir_hash(d)}" for d in (KIT / "skills").iterdir() if d.is_dir()}
    b = block_hash((KIT / "AGENTS.md").read_text(encoding="utf-8"))
    return rows | ({f"block {b}"} if b else set())


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
