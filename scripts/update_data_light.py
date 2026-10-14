"""data-light 짝 버전 관리 (관리자용 -- 사용자는 필요 없음).

dev-process-light 는 데이터 설계 스킬 data-light(sungbeom78/data-expert-framework-light)를 **정해 둔 커밋 그대로**
kit/skills/data-light 에 담아 함께 설치한다. dev-process-framework 가 data-expert-framework 를 서브모듈로 고정하는 것과
같은 짝이다. 서브모듈 대신 사본을 담는 이유: ZIP 으로 받거나(서브모듈이 빠진다) AI 가 파일을 직접 만드는 설치(INSTALL.md
방법 B)에서도 빠짐없이 깔리게.

이 사본은 고치지 않는다. 원본 저장소에서 고치고 이 도구로 다시 받는다. 무엇을 담았는지는 data-light.lock.json 에 있다.

    python scripts/update_data_light.py --check              # 사본이 잠금 파일과 같은지 (인터넷 필요 없음)
    python scripts/update_data_light.py --check --upstream   # + 원본의 그 커밋과 같은지, 원본에 새 버전이 있는지
    python scripts/update_data_light.py --ref main           # 원본 main(또는 커밋·태그)으로 바꾸기
    python scripts/update_data_light.py --ref <커밋> --from ../data-expert-framework-light   # 내려받지 않고 가진 clone 에서

파이썬 표준 라이브러리와 git 만 쓴다 (Windows·macOS·Linux).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:   # Windows 콘솔(cp1252/cp949)에서 한글 출력이 깨지지 않게
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:  # noqa: BLE001
    pass

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "kit" / "skills" / "data-light"
LOCK = ROOT / "data-light.lock.json"
REPO = "https://github.com/sungbeom78/data-expert-framework-light"
SRC_DIR = "skills/data-light"
ABOUT = ("kit/skills/data-light 는 아래 커밋의 skills/data-light 와 LICENSE 를 바이트 그대로 담은 사본이다. "
         "고치지 않는다 -- 원본(data-expert-framework-light)에서 고치고 scripts/update_data_light.py 로만 바꾼다.")
IGNORED_PARTS = {"__pycache__", ".pytest_cache"}
IGNORED_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini"}      # 운영체제가 저절로 만드는 파일


class PinError(Exception):
    pass


def sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def _git(repo: Path, *args: str, binary: bool = False):
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
    env["GIT_TERMINAL_PROMPT"] = "0"
    try:
        r = subprocess.run(["git", "-c", "core.quotepath=false", "-C", str(repo), *args], capture_output=True, env=env)
    except FileNotFoundError:
        raise PinError("git 이 없다 -- git 을 설치한 뒤 다시") from None
    if r.returncode != 0:
        raise PinError(f"git {' '.join(args)} 실패: {r.stderr.decode('utf-8', 'replace').strip()}")
    return r.stdout if binary else r.stdout.decode("utf-8", "replace")


def snapshot(repo: Path, ref: str) -> dict:
    """원본 저장소의 커밋에서 담을 파일을 읽는다 (작업 폴더가 아니라 저장된 내용 그대로)."""
    sha = _git(repo, "rev-parse", "--verify", f"{ref}^{{commit}}").strip()
    names = [n for n in _git(repo, "ls-tree", "-r", "-z", "--name-only", sha, "--", SRC_DIR).split("\0") if n]
    if not any(n == f"{SRC_DIR}/SKILL.md" for n in names):
        raise PinError(f"{ref} ({sha[:7]}) 에 {SRC_DIR}/SKILL.md 가 없다 -- data-expert-framework-light 저장소가 맞는지 확인")
    files: dict[str, bytes] = {}
    for n in names:
        rel = n[len(SRC_DIR) + 1:]
        if set(Path(rel).parts) & IGNORED_PARTS or rel.endswith(".pyc") or Path(rel).name in IGNORED_NAMES:
            continue
        files[rel] = _git(repo, "cat-file", "blob", f"{sha}:{n}", binary=True)
    if "LICENSE" not in files:        # 스킬만 따로 깔려도 라이선스가 같이 가게 (원본 package_skill.py 와 같다)
        files["LICENSE"] = _git(repo, "cat-file", "blob", f"{sha}:LICENSE", binary=True)
    try:
        version = _git(repo, "cat-file", "blob", f"{sha}:VERSION").strip()
    except PinError:
        version = "?"
    return {"commit": sha, "version": version, "files": files}


def clone(url: str, into: Path) -> Path:
    try:
        r = subprocess.run(["git", "clone", "--quiet", "--bare", url, str(into)], capture_output=True,
                           env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})
    except FileNotFoundError:
        raise PinError("git 이 없다 -- git 을 설치한 뒤 다시") from None
    if r.returncode != 0:
        raise PinError(f"원본을 받지 못함 ({url}): {r.stderr.decode('utf-8', 'replace').strip()} -- 인터넷·주소 확인")
    return into


def read_lock() -> dict:
    if not LOCK.is_file():
        raise PinError("data-light.lock.json 이 없다 -- `python scripts/update_data_light.py --ref <커밋>` 으로 만든다")
    lock = json.loads(LOCK.read_text(encoding="utf-8"))
    for k in ("repo", "commit", "version", "files"):
        if k not in lock:
            raise PinError(f"data-light.lock.json 에 {k} 가 없다")
    return lock


def local_files() -> dict[str, bytes]:
    out = {}
    if DEST.is_dir():
        for p in sorted(DEST.rglob("*")):
            rel = p.relative_to(DEST).as_posix()
            if p.is_file() and not (set(p.relative_to(DEST).parts) & IGNORED_PARTS) and not rel.endswith(".pyc") \
                    and p.name not in IGNORED_NAMES:
                out[rel] = p.read_bytes()
    return out


def verify() -> list[str]:
    """사본(kit/skills/data-light)이 잠금 파일과 바이트 그대로 같은지. 문제 목록을 돌려준다 (빈 목록 = 같다)."""
    try:
        lock = read_lock()
    except (PinError, ValueError) as e:
        return [str(e)]
    have = local_files()
    errs = []
    for rel, h in sorted(lock["files"].items()):
        if rel not in have:
            errs.append(f"data-light 사본에 {rel} 이 없다")
        elif sha256(have[rel]) != h:
            errs.append(f"data-light 사본의 {rel} 이 원본({lock['commit'][:7]})과 다르다 -- 사본은 고치지 않는다 "
                        "(원본에서 고치고 update_data_light.py 로 받는다)")
    for rel in sorted(set(have) - set(lock["files"])):
        errs.append(f"data-light 사본에 원본에 없는 파일 {rel}")
    return errs


def write(snap: dict, repo_url: str) -> dict:
    old = read_lock() if LOCK.is_file() else {"files": {}, "version": "-", "commit": ""}
    if DEST.exists():
        shutil.rmtree(DEST)
    for rel, b in snap["files"].items():
        p = DEST / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(b)
    new_files = {rel: sha256(b) for rel, b in sorted(snap["files"].items())}
    lock = {"about": ABOUT, "repo": repo_url, "commit": snap["commit"], "version": snap["version"], "files": new_files}
    LOCK.write_text(json.dumps(lock, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {"old_version": old.get("version"), "old_commit": old.get("commit", ""),
            "added": sorted(set(new_files) - set(old["files"])),
            "changed": sorted(k for k in set(new_files) & set(old["files"]) if new_files[k] != old["files"][k]),
            "removed": sorted(set(old["files"]) - set(new_files))}


def upstream_check(lock: dict, repo: Path) -> tuple[list[str], str]:
    errs, note = [], ""
    snap = snapshot(repo, lock["commit"])
    want = {rel: sha256(b) for rel, b in snap["files"].items()}
    if want != lock["files"]:
        errs.append(f"잠금 파일의 해시가 원본 {lock['commit'][:7]} 의 내용과 다르다 -- update_data_light.py --ref {lock['commit'][:7]} 로 다시 받는다")
    if snap["version"] != lock["version"]:
        errs.append(f"잠금 파일 version {lock['version']} != 원본 {lock['commit'][:7]} 의 VERSION {snap['version']}")
    try:       # 내려받은 원본은 기본 가지, --from 으로 준 저장소는 지금 가지의 끝
        tip = snapshot(repo, "HEAD")
    except PinError:
        tip = None
    if tip and tip["commit"] != lock["commit"]:
        note = (f"원본 기본 가지는 {tip['version']} ({tip['commit'][:7]}) -- 짝 버전은 {lock['version']} ({lock['commit'][:7]}). "
                f"올리려면: python scripts/update_data_light.py --ref {tip['commit'][:7]}")
    return errs, note


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="data-light 짝 버전 관리 (kit/skills/data-light)")
    ap.add_argument("--check", action="store_true", help="사본이 잠금 파일과 같은지 확인")
    ap.add_argument("--upstream", action="store_true", help="--check 와 함께: 원본 저장소의 그 커밋과도 대조 (인터넷)")
    ap.add_argument("--ref", help="담을 원본 커밋·가지·태그 (예: main, d6ee447)")
    ap.add_argument("--from", dest="src", help="원본을 내려받지 않고 이 git 저장소에서 읽는다 (커밋된 내용만)")
    ap.add_argument("--repo", default=None, help=f"원본 주소 (기본: 잠금 파일의 repo 또는 {REPO})")
    a = ap.parse_args(argv)
    if bool(a.check) == bool(a.ref):
        ap.error("--check 와 --ref 중 하나만")
    if a.upstream and not a.check:
        ap.error("--upstream 은 --check 와 함께")
    try:
        if a.check:
            errs = verify()
            note = ""
            if a.upstream and not errs:
                lock = read_lock()
                with tempfile.TemporaryDirectory() as d:
                    repo = Path(a.src).resolve() if a.src else clone(a.repo or lock["repo"], Path(d) / "src.git")
                    e2, note = upstream_check(lock, repo)
                    errs += e2
            if errs:
                print("FAIL -- data-light 짝")
                for e in errs:
                    print("  -", e)
                return 1
            lock = read_lock()
            print(f"PASS -- data-light {lock['version']} ({lock['commit'][:7]}) 사본 {len(lock['files'])}개 파일이 잠금과 같음"
                  + (" · 원본과도 같음" if a.upstream else ""))
            if note:
                print("  참고:", note)
            return 0
        url = a.repo or (read_lock()["repo"] if LOCK.is_file() else REPO)
        with tempfile.TemporaryDirectory() as d:
            repo = Path(a.src).resolve() if a.src else clone(url, Path(d) / "src.git")
            snap = snapshot(repo, a.ref)
        rep = write(snap, url)
        print(f"[OK] data-light {rep['old_version']} → {snap['version']} ({snap['commit'][:7]}) 를 kit/skills/data-light 에 담음")
        for k, label in (("added", "추가"), ("changed", "바뀜"), ("removed", "빠짐")):
            if rep[k]:
                print(f"  {label}: " + ", ".join(rep[k]))
        if not (rep["added"] or rep["changed"] or rep["removed"]):
            print("  파일 변화 없음")
        print("다음: README·README.en 의 짝 버전, CHANGELOG 를 고치고 `python scripts/check_kit.py` 를 돌린다.")
        return 0
    except (PinError, ValueError, KeyError) as e:     # ValueError: 잠금 파일이 JSON 이 아님
        print(f"[실패] {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
