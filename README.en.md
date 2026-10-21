# dev-process-light

**A lightweight working agreement for building your own multi-feature website with an AI coding agent -- so it doesn't break as it grows.**
Seven Agent Skills for Claude Code and Codex, five plain-Markdown notes, a user manual that grows with the site, a local page to browse the records,
and a **paired data-design skill, `data-light`** ([data-expert-framework-light](https://github.com/edubeom/data-expert-framework-light)), that takes over when the site starts storing data.
Nothing to install besides git (Python only for the data checks, the manual review and the records page).

[한국어](README.md)

## Who it's for
Non-developers building a personal site with several features (notes, to-dos, budget, gallery...) with Claude Code or Codex,
who have hit these problems: adding a feature breaks an old one; the next day the AI doesn't know where things stand;
the AI says "done" but it doesn't work; there's no easy way back; the AI keeps retrying the same failed fix.

## What's inside
| Skill | When | What it does |
|---|---|---|
| `light-resume` | start of every session | reads the notes and git log, summarizes where things stand in 5 lines; sets up a new project |
| `light-start` | before building | writes a task card (goal, done-criteria, features touched) and **asks for confirmation**; splits big requests |
| `light-check` | before saying "done" | the AI **actually runs and opens** things; reports ✅ verified (and how) / 👀 please look / ❓ couldn't check; re-checks every other feature |
| `light-save` | after every step (agreement, a chunk of work, check, undo) | adds a line to the work log, commits only this task's files (unfinished work as `중간 저장:` work-in-progress) and updates the notes -- a point you can return to; pushes if you said so once |
| `light-undo` | when something broke | shows saves in plain words and reverts the chosen one **without deleting history**, then re-checks |
| `light-manual` | first build, new feature, changed usage | creates or updates the user manual in `manual/` -- HTML slides (a 16:9 page per step, a diagram and a narration script on every page; present, print to PDF or export to pptx) -- in the same save, then **shows it in the chat** |
| `light-portal` | after each save, "show me the records", "how far along are we?", or when something breaks | the development site with the same pages and addresses as dev-process-framework, light edition (5 pages): 1 overview (to-dos, progress bars) · 2 business (features, works) · 4 data · 9 progress (acceptance criteria, work log, per-feature logs, decisions by you / by the AI, saves) · 10 files (feature → files → tables, parts, tools and their versions). Open `dev-notes/outputs/site/index.html` as a file -- no server, no login, no port. When something breaks, `where` finds the place to fix (feature · files · tables) first |
| `data-light` (paired) | when data needs storing (linked tables, several users logging in, Excel/CSV, personal info) | designs the tables from a few plain questions, **confirms them with you as a diagram (ERD) and a table**, then checks, rule-tests (SQLite), and builds the spec and SQL (SQLite or Supabase). Personal info goes to separate `pi_` tables; creating a DB or importing files only after you say yes |

`AGENTS.md` adds thirteen rules (the skills and the rule block are never edited inside a project -- put project rules outside the block); the two that matter most: *say so before touching another feature's files*, and
*when something fails, look at the cause first (fix, wait and retry, ask the user, or try another way) and see it through -- if nothing works, let the user choose: undo, drop the feature, or note it for later*.
Notes live in `dev-notes/`: `NOW.md` (current state, plus five answers every skill shares -- who uses it, login, hosting, stored data, personal info), `FEATURES.md` (feature map: status, files, one-line check -- also the map for finding what to fix; a setup section says where each part runs and what it uses; a data section maps each table to the features that use it),
`DECISIONS.md` (`[사용자]` you, quoted / `[AI]` with reason and alternatives), `LOG.md` (the flow: one line per step -- planning, building, checking, operating, reviewing -- when · step · feature · what · result · who) and `log/<feature>/<date>.md` (that day's item list plus details: files/classes/functions/variables changed, check results, errors and fixes, review notes) -- the agent reads flow → list → details, only what it needs, `NAMES.md` (screen words ↔ code names).

## When the site starts storing data -- the paired `data-light` skill
Linked tables (members → dues), several people logging in, Excel/CSV imports or personal info → the data is designed **before** any screen,
by `data-light`, and then the light flow continues. The installer installs both.

| | development flow | data design |
|---|---|---|
| light (public) | **dev-process-light** (this repo) | **data-expert-framework-light** -- skill `data-light` |
| full | dev-process-framework | data-expert-framework |
| how the pair is pinned | this repo ships `data-light` **byte-for-byte at a pinned commit** in `kit/skills/data-light` ([`data-light.lock.json`](data-light.lock.json), updated with `scripts/update_data_light.py`) | git submodule |

Current pair: **data-light 0.10.1** (data-expert-framework-light `6f371af`).
Questions are asked once (the five lines in `NOW.md`), task cards carry a `데이터:` (data) line, one canonical file `data/model.light.json`
feeds the ERD/spec/SQL (for Supabase including real row-level-security policies from `signup` and per-table `access`), `light-check` runs the `datalight.py verify` gate (design check, success goals, rule tests, fresh outputs, data-loss guard), `light-save` commits it as `데이터:`, and real data (`data/app.db`,
source spreadsheets, `.env`) is never committed. Walkthrough: [`examples/club-dues/`](examples/club-dues/WALKTHROUGH.md) (Korean).

## Install
Easiest: open your project in Claude Code or Codex and say
*"Read INSTALL.md at https://github.com/edubeom/dev-process-light and install it into this project."*

Or with git:
```bash
git clone --depth 1 https://github.com/edubeom/dev-process-light.git ~/dev-process-light
bash ~/dev-process-light/install.sh <your-project>
# Windows PowerShell: powershell -ExecutionPolicy Bypass -File $HOME\dev-process-light\install.ps1 <your-project>
```
The installer never overwrites existing `dev-notes/`, `data/` or your own `AGENTS.md` content; re-running updates the skills (including the paired `data-light`) and the rule block.
If you edited or deleted one of them, it is not overwritten or restored silently: the installer lists it under `[물어볼 것]` and exits 3 --
re-run with `--update <name|all>` (old copy kept in `.claude/skills/.light-backup/`) or `--keep <name|all>` (PowerShell: `-Update` / `-Keep`).
Then tell the agent: *"Start with light-resume."* Walkthrough: [`examples/my-homepage/`](examples/my-homepage/WALKTHROUGH.md) (Korean).

The skills and notes are written in Korean; agents follow them in any language. Translations are welcome.

## License
MIT
