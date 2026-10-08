# dev-process-light

**A lightweight working agreement for building your own multi-feature website with an AI coding agent -- so it doesn't break as it grows.**
Six Agent Skills for Claude Code and Codex, four plain-Markdown notes, and a user manual that grows with the site. Nothing to install besides git.

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
| `light-save` | after checking | commits only this task's files and updates the notes -- a point you can return to |
| `light-undo` | when something broke | shows saves in plain words and reverts the chosen one **without deleting history**, then re-checks |
| `light-manual` | first build, new feature, changed usage | creates or updates the user manual in `manual/` in the same save, then **shows it in the chat**; "show me the manual" any time |

`AGENTS.md` adds twelve rules (the skills and the rule block are never edited inside a project -- put project rules outside the block); the two that matter most: *say so before touching another feature's files*, and
*after three failed attempts at the same problem, stop and explain in plain words*.
Notes live in `dev-notes/`: `NOW.md` (current state), `FEATURES.md` (feature map: status, files, one-line check),
`DECISIONS.md`, `NAMES.md` (screen words ↔ code names).

## Install
Easiest: open your project in Claude Code or Codex and say
*"Read INSTALL.md at https://github.com/sungbeom78/dev-process-light and install it into this project."*

Or with git:
```bash
git clone --depth 1 https://github.com/sungbeom78/dev-process-light.git ~/dev-process-light
bash ~/dev-process-light/install.sh <your-project>
# Windows PowerShell: powershell -ExecutionPolicy Bypass -File $HOME\dev-process-light\install.ps1 <your-project>
```
The installer never overwrites existing `dev-notes/` or your own `AGENTS.md` content; re-running only updates the skills.
Then tell the agent: *"Start with light-resume."* Walkthrough: [`examples/my-homepage/`](examples/my-homepage/WALKTHROUGH.md) (Korean).

The skills and notes are written in Korean; agents follow them in any language. Translations are welcome.

## License
MIT
