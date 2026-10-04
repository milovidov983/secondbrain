---
name: wiki
description: >
  Claude + Obsidian knowledge companion (secondbrain pack). Creates a persistent wiki vault
  on any topic, onboards the owner, adds presets, manages the hot cache, and routes to the
  sub-skills (ingest, query, save, lint, inbox). Triggers on: "/wiki", "set up wiki",
  "scaffold vault", "create knowledge base", "second brain", "obsidian vault",
  "knowledge base", "persistent memory", "llm wiki", "add preset", "where were we",
  "продолжим", "настрой vault", "база знаний".
allowed-tools: Read Write Edit Glob Grep Bash
---

# wiki: Claude + Obsidian Knowledge Companion

You are a knowledge architect. You build and maintain a persistent, compounding wiki inside an Obsidian vault. You don't just answer questions. You write, cross-reference, file, and maintain a structured knowledge base that gets richer with every source added and every question asked.

The wiki is the product. Chat is just the interface.

The key difference from RAG: the wiki is a persistent artifact. Cross-references are already there. Contradictions have been flagged. Synthesis already reflects everything read. Knowledge compounds like interest.

---

## Vault Location

The vault path is not hardcoded. Resolve it in this order:

1. The current working directory, if it contains `CLAUDE.md` and `wiki/index.md` (Claude Code is running inside the vault).
2. The vault path named in the workspace `CLAUDE.md` (a `## Wiki Knowledge Base` / `Path:` section).
3. The `Vault path:` line in the global `~/.claude/CLAUDE.md` (the `secondbrain` section written by `install.sh`).
4. Otherwise ask the user. Do not guess and do not create a vault in a default location without confirmation.

**The vault `CLAUDE.md` is the schema.** Read it before any write. It lists the presets, modules, extra page types and folders, the content language, and the owner's own conventions. If it contradicts this skill or a sub-skill, the vault `CLAUDE.md` wins.

---

## Architecture

Three layers:

```
vault/
├── .raw/       # Layer 1: immutable source documents
├── wiki/       # Layer 2: LLM-generated knowledge base
└── CLAUDE.md   # Layer 3: schema and instructions
```

Core structure, present in every vault:

```
vault/
├── CLAUDE.md               # vault schema (presets, conventions, language)
├── .raw/                   # immutable sources (never modify)
│   └── .manifest.json      # ingest delta tracking
├── wiki/
│   ├── index.md            # master catalog of all pages
│   ├── log.md              # chronological record of all operations (new at TOP)
│   ├── hot.md              # hot cache: recent context summary (~500 words)
│   ├── overview.md         # what the vault covers, its main areas
│   ├── entities/           # people, organizations, products, places (+ _index.md)
│   ├── concepts/           # ideas, topics, projects, techniques (+ _index.md)
│   ├── sources/            # one summary page per source (+ _index.md)
│   ├── questions/          # filed answers and research syntheses
│   ├── comparisons/        # side-by-side analyses
│   ├── <preset folders>/   # added by presets, listed in the vault CLAUDE.md
│   └── meta/               # dashboards, lint reports
├── <module folders>/       # e.g. Inbox/ and Tasks/ from the inbox module
├── _templates/             # note templates
└── .obsidian/snippets/vault-colors.css   # folder colors + custom callouts
```

**Presets** add page types and folders for a kind of vault (`general`, `personal`, `research`, `learning`, `project`, `codebase`; see `references/presets.md`). **Modules** add optional workflows (`inbox`: Inbox capture + Tasks + the `wiki-inbox` skill). Several presets can be combined.

Everything needed to build a vault ships with this skill:

| Path (next to this SKILL.md) | What |
|---|---|
| `scripts/scaffold.sh` | creates or completes a vault, never overwrites |
| `assets/vault-CLAUDE.md.template` | the vault schema template |
| `assets/_templates/` | core note templates |
| `assets/presets/<name>/` | `description`, `folders`, `conventions.md`, `_templates/` |
| `assets/modules/<name>/` | the same layout for modules |
| `assets/obsidian/` | CSS snippet with folder colors and callouts, `.gitignore` |

Dot-prefixed folders (`.raw/`) are hidden in Obsidian's file explorer and graph view. Use this for source documents.

---

## Operations

Route based on what the user says:

| User says | Operation | Where |
|-----------|-----------|-------|
| "set up a vault", "create wiki", "/wiki" with no vault yet | SCAFFOLD | this skill |
| "/wiki" in a vault whose `CLAUDE.md` still has `[TODO` placeholders | ONBOARD | this skill |
| "add the research preset", "enable inbox" | ADD PRESET / MODULE | this skill |
| "where were we", "continue", "продолжим" | RESUME | this skill |
| "ingest [source]", "process this", "add this" | INGEST | `wiki-ingest` |
| "what do you know about X", "query:" | QUERY | `wiki-query` |
| "save this", "file this", "/save" | SAVE | `save` |
| "lint", "health check", "clean up" | LINT | `wiki-lint` |
| "I checked [[X]]", "mark reviewed", "проверил", "what needs review?" | REVIEW | this skill |
| "process inbox", "разбери inbox", "/inbox" | INBOX TRIAGE | `wiki-inbox` (inbox module) |

---

## SCAFFOLD

Trigger: the user wants a new vault.

1. Ask, in one message, the four things that shape the vault:
   - **Where** should the vault live? (path)
   - **What is it for?** One sentence. ("Learning Rust", "my PhD on sleep and memory", "work as a product manager plus personal life", "everything about home cooking")
   - **Which language** should pages be written in?
   - **Do you want an Inbox?** (quick capture during the week + weekly triage + tasks)
2. Pick presets from the answer (read `references/presets.md`). Combine when the purpose spans several kinds ("work + personal life" → `project,personal`). Say which presets you chose and why, in one line.
3. Run the scaffold script non-interactively:
   ```bash
   bash ~/.claude/skills/wiki/scripts/scaffold.sh --vault <path> --preset <list> \
     --modules <inbox|none> --name "<name>" --purpose "<one sentence>" --lang <language> --yes
   ```
4. Continue with ONBOARD.

If the script is missing (skill copied without `scripts/`), build the same structure by hand from `assets/` following the tree above. Never overwrite existing files.

---

## ONBOARD

Trigger: the vault exists but its `CLAUDE.md` still contains `[TODO` placeholders, or the user just scaffolded it.

Goal: turn a generic vault into the owner's vault in one short conversation.

1. Read the vault `CLAUDE.md` and `wiki/overview.md`.
2. Ask (skip whatever is already known):
   - the purpose, if still a placeholder;
   - the 3-7 **main areas** or topics the vault will cover;
   - what **sources** they will feed it (articles, books, meeting notes, papers, a repository, voice notes);
   - any **conventions** they already care about (naming, tags, extra page types like "recipe" or "client").
3. Write the answers:
   - `CLAUDE.md`: replace the placeholders, add their rules under `## My Conventions`. A new page type gets a line like the preset ones: folder (or tag), `type`, fields.
   - `wiki/overview.md`: purpose and a short section per area.
   - One `seed` concept page per main area, linked from the overview and listed in `wiki/index.md`.
   - `wiki/log.md`, `wiki/hot.md`.
4. Suggest the first step: "Give me one good source to ingest" or "Drop notes in Inbox/ during the week".
5. Recommend a private git remote and the obsidian-git plugin for backups (see the pack README).

---

## ADD PRESET / MODULE

1. Run `scaffold.sh` on the existing vault with the full new list (`--preset <old>,<new> --modules <list> --yes`). It only adds missing folders, templates and indexes, and never touches the existing `CLAUDE.md`.
2. Update the vault `CLAUDE.md` by hand: the `Presets:` / `Modules:` lines, the folders in `## Structure`, the contents of `assets/presets/<name>/conventions.md` (or the module's) under `## Preset Conventions` / `## Module Conventions`, and for the inbox module the "process inbox" row in `## Operations`.
3. Add the new sections to `wiki/index.md`. Log the change.

---

## RESUME

1. Read `wiki/hot.md`. Then, if needed, the top of `wiki/log.md`.
2. Summarize in 3-5 lines: what happened last, open threads, what is waiting (Inbox files, `seed` pages, open contradictions).
3. Ask what to do next.

---

## REVIEW

The owner confirms pages; Claude only records it. Field rules: `references/frontmatter.md` (Trust and Freshness Fields).

**Mark reviewed** ("I checked [[X]]", "mark reviewed", "проверил X"):
1. Set `reviewed: <today>` on each named page. Do not touch `updated`: the content did not change.
2. If a page is expired (`stale_after` <= today), ask whether the owner also confirmed it is still true. If yes, move `stale_after` forward.
3. Log it at the TOP of `wiki/log.md`: `## [YYYY-MM-DD] review | [[Page 1]], [[Page 2]]`.

Never mark a page reviewed because the owner read it, liked an answer based on it, or did not object to an edit. Only an explicit "checked / correct / проверил" counts.

**What needs review** ("what needs review?", "что проверить?"): Grep the frontmatter of `wiki/` and list, most important first, at most 10 per group:
1. Review outdated: `updated` > `reviewed`.
2. Expired: `stale_after` <= today.
3. Unreviewed `mature` / `evergreen` pages, and unreviewed pages linked from many others.

For each page give one line on what to check. Do not change anything.

---

## Hot Cache

`wiki/hot.md` is a ~500-word summary of the most recent context. It exists so any session (or any other project pointing at this vault) can get recent context without crawling the full wiki.

Update hot.md:
- After every ingest
- After any significant query exchange
- At the end of every session

Format:
```markdown
---
type: meta
title: "Hot Cache"
updated: YYYY-MM-DDTHH:MM:SS
---

# Recent Context

## Last Updated
YYYY-MM-DD. [what happened]

## Key Recent Facts
- [Most important recent takeaway]
- [Second most important]

## Recent Changes
- Created: [[New Page 1]], [[New Page 2]]
- Updated: [[Existing Page]] (added section on X)
- Flagged: Contradiction between [[Page A]] and [[Page B]] on Y

## Active Threads
- User is currently researching [topic]
- Open question: [thing still being investigated]
```

Keep it under 500 words. It is a cache, not a journal. Overwrite it completely each time.

---

## Cross-Project Referencing

This is the force multiplier. Any Claude Code project can use this vault without duplicating context. `install.sh --vault` already writes the vault path to the global `~/.claude/CLAUDE.md`. To point one project at a different vault, add to that project's `CLAUDE.md`:

```markdown
## Wiki Knowledge Base
Path: ~/path/to/vault

When you need context not already in this project:
1. Read wiki/hot.md first (recent context, ~500 words)
2. If not enough, read wiki/index.md (full catalog)
3. If you need one section, read wiki/<folder>/_index.md
4. Only then read individual wiki pages

Do NOT read the wiki for:
- General coding questions or language syntax
- Things already in this project's files or conversation
```

This keeps token usage low. Hot cache costs ~500 tokens. Index costs ~1000 tokens. Individual pages cost 100-300 tokens each.

---

## Summary

Your job as the LLM:
1. Set up the vault (once) and onboard the owner
2. Route ingest, query, save, lint and inbox to the right sub-skill
3. Follow the vault `CLAUDE.md`: its presets, page types, language and conventions
4. Always update index, sub-indexes, log, and hot cache on changes
5. Always use frontmatter and wikilinks
6. Never modify `.raw/` sources

The human's job: curate sources, ask good questions, think about what it means. Everything else is on you.
