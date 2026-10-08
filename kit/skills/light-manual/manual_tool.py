#!/usr/bin/env python3
"""사용설명서 도우미 (AI 가 실행한다. 사용자가 직접 쓸 필요는 없음). 파이썬만 있으면 check·outline 은 바로 된다.

    python manual_tool.py check   manual/        # 규칙 점검: 페이지마다 그림·대본, 한 단계 = 한 페이지, 글자 수, 링크
    python manual_tool.py outline manual/ [장]   # 채팅에 보여 줄 개요 (페이지별 제목·핵심)
    python manual_tool.py pptx    manual/ out.pptx   # pptx: 페이지 = 슬라이드 한 장, 대본 = 발표자 노트
                                                     #  (pip install playwright python-pptx && python -m playwright install chromium)
"""
from __future__ import annotations
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

VISUAL_CLASSES = {"flow", "cards", "compare", "screen", "chat", "tree", "diagram", "big"}
VISUAL_TAGS = {"svg", "img", "table", "video"}
NEED = {"index": ["cover", "start-step", "chapters", "changes"], "feature": ["overview", "step"]}
MAX_CHARS, MIN_NOTES = 350, 30
VOID = {"meta", "link", "br", "img", "input", "hr", "source", "path", "rect", "circle", "line", "polyline", "polygon", "ellipse", "use"}


class Deck(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title, self.slides, self.links, self.assets = "", [], [], []
        self.stack, self.cur, self.in_title, self.head = [], None, False, 0

    def flags(self):
        return self.stack[-1][1:] if self.stack else (False, False)

    def handle_starttag(self, tag, attrs):
        a = {k: (v or "") for k, v in attrs}
        notes, hidden = self.flags()
        cls = set(a.get("class", "").split())
        self.in_title = self.in_title or tag == "title"
        if tag == "section" and "slide" in cls:
            self.cur = {"title": a.get("data-title", ""), "kind": a.get("data-kind", ""), "text": [], "notes": [], "head": [], "visual": False}
            self.slides.append(self.cur)
        if self.cur is not None and (tag in ("h1", "h2") or "lead" in cls):
            self.head = len(self.stack) + 1
        if self.cur is not None:
            notes = notes or (tag == "aside" and "notes" in cls)
            hidden = hidden or tag in ("script", "style")
            if not notes and (tag in VISUAL_TAGS or cls & VISUAL_CLASSES):
                self.cur["visual"] = True
        for k in ("href", "src"):
            if a.get(k):
                self.links.append(a[k])
        if (tag == "link" and "stylesheet" in a.get("rel", "")) or (tag == "script" and a.get("src")):
            self.assets.append(a.get("href") or a.get("src"))
        if tag not in VOID:
            self.stack.append((tag, notes, hidden))

    def handle_endtag(self, tag):
        self.in_title = False if tag == "title" else self.in_title
        while self.stack:
            if self.stack.pop()[0] == tag:
                break
        if self.head and len(self.stack) < self.head:
            self.head = 0
        if tag == "section" and not any(t[0] == "section" for t in self.stack):
            self.cur = None

    def handle_data(self, data):
        if self.in_title:
            self.title += data
        if self.cur is not None and not self.flags()[1]:
            (self.cur["notes"] if self.flags()[0] else self.cur["text"]).append(data)
            if self.head and not self.flags()[0]:
                self.cur["head"].append(data)


def parse(f: Path) -> Deck:
    d = Deck()
    d.feed(f.read_text(encoding="utf-8"))
    for s in d.slides:
        s["text"] = re.sub(r"\s+", " ", " ".join(s["text"])).strip()
        s["notes"] = re.sub(r"\s+", " ", " ".join(s["notes"])).strip()
        s["head"] = re.sub(r"\s+", " ", " ".join(s["head"])).strip()
    return d


def check(mdir: Path) -> list[str]:
    probs = []
    for a in ("manual.css", "manual.js"):
        if not (mdir / "assets" / a).is_file():
            probs.append(f"assets/{a} 없음 -- light-manual 스킬의 assets 를 복사")
    if not (mdir / "index.html").is_file():
        probs.append("index.html(목차) 없음")
    linked = set()
    for f in sorted(mdir.glob("*.html")):
        d = parse(f)
        raw = f.read_text(encoding="utf-8")
        if re.search(r"<!--\s*작성\s*:|\{\{[a-z_]+\}\}", raw):
            probs.append(f"{f.name}: 채우지 않은 자리표시가 남아 있음")
        for a in d.assets:
            if re.match(r"^(https?:)?//", a):
                probs.append(f"{f.name}: 인터넷 주소 사용 금지 ({a})")
        for u in d.links:
            if re.match(r"^[a-z][a-z0-9+.-]*:", u, re.I) or u.startswith(("#", "//")):
                continue
            if f.name == "index.html" and u.split("#")[0].endswith(".html"):
                linked.add(Path(u.split("#")[0]).name)
            if not (f.parent / u.split("#")[0].split("?")[0]).exists():
                probs.append(f"{f.name}: 깨진 링크 {u}")
        role = "index" if f.name == "index.html" else "feature"
        for i, s in enumerate(d.slides, 1):
            w = f"{f.name} #{i} '{s['title']}'"
            if not s["title"]:
                probs.append(f"{w}: data-title 없음")
            if len(s["notes"]) < MIN_NOTES:
                probs.append(f"{w}: 대본(aside.notes) 없음/짧음")
            if s["kind"] not in ("cover", "section") and not s["visual"]:
                probs.append(f"{w}: 그림 없음 (순서도·카드·비교·화면·표·svg)")
            if len(s["text"].replace(" ", "")) > MAX_CHARS:
                probs.append(f"{w}: 글이 너무 많음 -- 나누거나 그림으로")
        kinds = {s["kind"] for s in d.slides}
        probs += [f"{f.name}: 필요한 페이지 없음 data-kind=\"{k}\"" for k in NEED[role] if k not in kinds]
    for f in sorted(mdir.glob("*.html")):
        if f.name != "index.html" and f.name not in linked:
            probs.append(f"{f.name}: 목차(index.html)에서 연결되지 않음")
    return probs


def outline(mdir: Path, which: str | None) -> str:
    files = sorted(mdir.glob("*.html"), key=lambda p: (p.name != "index.html", p.name))
    if which:
        files = [f for f in files if which.lower() in (f.stem.lower(), parse(f).title.lower()) or which in parse(f).title]
    out = []
    for f in files:
        d = parse(f)
        out.append(f"### {d.title.split(' — ')[0]}  ·  `{f.as_posix()}`  ({len(d.slides)}쪽)")
        for i, s in enumerate(d.slides, 1):
            t = s["head"] or s["text"]
            out.append(f"{i}. **{s['title']}** — {t[:160]}")
        out.append("")
    out.append(f"열기: `{(mdir / 'index.html').as_posix()}` (브라우저 · P 발표 · N 대본 · 인쇄 = 16:9 PDF)")
    return "\n".join(out)


def pptx(mdir: Path, out: Path) -> int:
    from playwright.sync_api import sync_playwright
    from pptx import Presentation
    from pptx.util import Emu
    prs = Presentation()
    prs.slide_width, prs.slide_height = Emu(12192000), Emu(6858000)
    tmp = out.with_suffix(".pages"); tmp.mkdir(parents=True, exist_ok=True)
    n = 0
    with sync_playwright() as p:
        b = p.chromium.launch(); pg = b.new_page(viewport={"width": 1320, "height": 800}, device_scale_factor=1.5)
        for f in sorted(mdir.glob("*.html"), key=lambda p: (p.name != "index.html", p.name)):
            d = parse(f)
            pg.goto(f.resolve().as_uri() + "?export"); pg.wait_for_timeout(200)
            for i, el in enumerate(pg.query_selector_all("section.slide")):
                n += 1; img = tmp / f"{n:03d}.png"; el.screenshot(path=str(img))
                sl = prs.slides.add_slide(prs.slide_layouts[6])
                sl.shapes.add_picture(str(img), 0, 0, width=prs.slide_width, height=prs.slide_height)
                s = d.slides[i] if i < len(d.slides) else {"title": "", "notes": ""}
                sl.notes_slide.notes_text_frame.text = f"{s['title']}\n{s['notes']}".strip()
        b.close()
    prs.save(str(out))
    for x in tmp.iterdir():
        x.unlink()
    tmp.rmdir()
    return n


def main(argv: list[str]) -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:  # noqa: BLE001
        pass
    if len(argv) < 2 or argv[0] not in ("check", "outline", "pptx"):
        print(__doc__); return 2
    mdir = Path(argv[1])
    if argv[0] == "check":
        probs = check(mdir)
        print("\n".join(f"✗ {p}" for p in probs) or "✓ 사용설명서 규칙 통과")
        return 1 if probs else 0
    if argv[0] == "outline":
        print(outline(mdir, argv[2] if len(argv) > 2 else None)); return 0
    out = Path(argv[2] if len(argv) > 2 else "manual.pptx")
    print(f"pptx: {out} ({pptx(mdir, out)}쪽)"); return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
