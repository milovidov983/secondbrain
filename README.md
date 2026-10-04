# secondbrain

**A second brain that maintains itself.** An Obsidian vault on any topic, written, linked and kept tidy by Claude Code. You curate; Claude does the bookkeeping.

[Русская версия](README.ru.md)

Based on Andrej Karpathy's *LLM Wiki* pattern: instead of re-reading your documents on every question (RAG), the LLM compiles them once into a persistent wiki of linked pages. Cross-references are already there, contradictions are already flagged, and every new source or question makes the wiki richer.

```
 you                          Claude Code                         Obsidian vault
 ───                          ───────────                         ──────────────
 drop a source  ──ingest──▶   reads it, writes a summary,   ──▶   .raw/   (originals, never edited)
 ask a question ──query───▶   updates 5-15 related pages,   ──▶   wiki/   (linked pages + index,
 "save this"    ──/save───▶   flags contradictions,                        log, hot cache)
 jot in Inbox/  ──triage──▶   keeps index, log, cache       ──▶   CLAUDE.md (the vault's schema)
```

Works for any subject: a hobby, a research question, learning a language, your job, your whole life, a codebase.

## Quick start

Requirements: [Claude Code](https://claude.com/claude-code), git, bash. [Obsidian](https://obsidian.md) to browse the vault (optional but recommended).

```bash
git clone https://github.com/milovidov983/secondbrain.git
cd secondbrain
./install.sh --vault ~/vault          # asks: presets, inbox, name, purpose, language
```

Then:

```bash
cd ~/vault && claude
> /wiki                                # Claude finishes onboarding: areas, sources, your conventions
> ingest https://example.com/some-article
```

Open `~/vault` in Obsidian (Open folder as vault) and enable the `vault-colors` CSS snippet (Settings → Appearance → CSS snippets).

Prefer to let Claude do everything? Run `./install.sh` without `--vault`, start `claude` anywhere and say "set up a second brain".

## What `install.sh` does

1. **Skills.** Copies the skills from `skills/` to `~/.claude/skills/`. A changed installed skill is first moved to `~/.claude/skills-backup/<timestamp>/`.
2. **Global instructions.** Adds a short section to `~/.claude/CLAUDE.md` (between `secondbrain:begin` / `secondbrain:end` markers) so Claude knows about your vault from any project. Re-running with `--vault` updates the path; a backup of the file is kept.
3. **Vault (with `--vault`).** Creates only the missing parts, never overwrites: folders, templates, `CLAUDE.md`, starter `index` / `log` / `hot` / `overview` pages, Obsidian settings, `.gitignore`, `git init`.

Safe to re-run. `--dry-run` shows what would happen. Non-interactive example:

```bash
./install.sh --vault ~/vault --preset learning --modules inbox \
  --name "Spanish" --purpose "Learning Spanish to B2" --lang English --yes
```

## Presets: what the vault is about

The core (sources, entities, concepts, questions, comparisons) fits any topic. Presets add page types, folders and templates for a kind of vault. Combine them with commas.

| Preset | For | Adds |
|---|---|---|
| `general` | a topic you explore: cooking, history, investing | nothing, core only |
| `personal` | your life: goals, health, finance, people | `goals/`, `areas/`, `reviews/` |
| `research` | papers, claims, an evolving thesis | `papers/`, `theses/` |
| `learning` | a subject or skill: books, courses, exercises | `resources/`, `practice/` |
| `project` | work, a team, a business | `decisions/`, `meetings/` |
| `codebase` | understanding a codebase or system | `modules/`, `flows/`, `decisions/` |

`./install.sh --list` prints them. Details: [skills/wiki/references/presets.md](skills/wiki/references/presets.md). A preset can be added later: ask Claude "add the research preset". Your own page types (recipes, clients, plants...) go to `## My Conventions` in the vault `CLAUDE.md`, see [examples/](examples/).

**Modules** are optional workflows:

| Module | Adds |
|---|---|
| `inbox` | `Inbox/` for free-form daily capture, `Tasks/`, and weekly triage ("process inbox") |

## Everyday use

| I want to | Say |
|---|---|
| Add an article, PDF, meeting notes, image | `ingest <path or URL>` (files can be dropped into `.raw/` first) |
| Ask the vault | `query: ...`, `what do we know about X`, `query deep: ...` |
| Keep a good answer or discussion | `/save` |
| Continue where I left off | `where were we` |
| Jot something down quickly (inbox module) | write in `Inbox/YYYY-MM-DD.md`, any format |
| Sort the inbox (weekly) | `process inbox` |
| Check health (every few weeks) | `lint the wiki` |
| Confirm a page is correct | `I checked [[Page]]` |
| See what is worth checking | `what needs review?` |
| Use the vault from another project | nothing: Claude reads `wiki/hot.md`, then `wiki/index.md` |

Why it works this way and in what rhythm: [METHODOLOGY.md](METHODOLOGY.md).

## What's inside

```
secondbrain/
├── install.sh              installs skills + global section, creates a vault
├── global-CLAUDE.md        the section added to ~/.claude/CLAUDE.md
├── METHODOLOGY.md          the method: knowledge lifecycle, rhythm, migration
├── examples/               worked examples of custom conventions
└── skills/
    ├── wiki/               setup, onboarding, routing, hot cache
    │   ├── scripts/scaffold.sh      creates or completes a vault
    │   ├── references/              frontmatter schema, presets
    │   └── assets/                  vault template, core templates, presets/, modules/, Obsidian CSS
    ├── wiki-ingest/        sources → wiki pages (files, URLs, images, batches, git repos)
    ├── wiki-query/         answers with citations (quick / standard / deep)
    ├── save/               conversation → wiki page
    ├── wiki-lint/          orphans, dead links, contradictions, dashboard
    └── wiki-inbox/         Inbox triage (inbox module)
```

A vault looks like this:

```
vault/
├── CLAUDE.md        schema: purpose, presets, language, conventions (yours to edit)
├── .raw/            immutable originals (hidden in Obsidian)
├── wiki/
│   ├── index.md     catalog         ├── entities/   ├── questions/
│   ├── log.md       history         ├── concepts/   ├── comparisons/
│   ├── hot.md       recent context  ├── sources/    ├── <preset folders>/
│   └── overview.md                  └── meta/
├── Inbox/, Tasks/   (inbox module)
└── _templates/
```

## Key rules

- **`.raw/` is never edited.** It is the evidence wiki pages can be checked against.
- **Frontmatter on every wiki page**, links as `[[wikilinks]]`, unique file names.
- **`wiki/index.md`** is updated on every new or deleted page; **`wiki/log.md`** is append-only, newest on top; **`wiki/hot.md`** (~500 words) is rewritten after every operation.
- **Contradictions are flagged**, not overwritten: `> [!contradiction]` on both pages.
- **Trust and freshness are visible.** Every page has a one-line `description`. Only you set `reviewed`, when you have checked a page; a later edit shows the review is out of date. Pages with facts that expire (prices, versions, plans) get `stale_after`, and Claude warns when it relies on an expired one.
- **The vault `CLAUDE.md` wins** over the skills. Change it to change how Claude works in your vault.

## Backup and sync

The vault is a plain folder of markdown files in git.

1. Create a **private** repository (GitHub, GitLab, any git host) and push: `git remote add origin <url> && git push -u origin main`.
2. In Obsidian, install the community plugin **obsidian-git** for automatic commits and pushes.
3. Obsidian and Claude Code commit to the same repository, so always `git pull --rebase` before `git push`.

On a new machine: install Claude Code and Obsidian, clone this pack and run `./install.sh --vault <path>` against your cloned vault. It only adds what is missing, and your `CLAUDE.md` and pages stay untouched. All working context (hot cache, index, log) lives in the vault, so nothing important is lost with Claude Code's local history.

## Updating

The pack is the source of truth for the skills. `git pull` here, then `./install.sh`. If you changed a skill directly in `~/.claude/skills/`, the old copy goes to `~/.claude/skills-backup/`. To keep your changes, fork this repository and edit the skills in the fork.

## Troubleshooting

- **Claude does not use the vault from other projects.** Check the `secondbrain` section in `~/.claude/CLAUDE.md` and its `Vault path:` (`./install.sh --vault <path>` fixes it).
- **A skill does not trigger.** Check that `~/.claude/skills/<skill>/SKILL.md` exists and restart Claude Code.
- **`git push` rejected (fetch first).** obsidian-git committed meanwhile: `git pull --rebase`, then push.
- **A new session does not remember context.** `wiki/hot.md` was not updated last time; say "where were we" and Claude will rebuild it from the log.
- **Callouts and folder colors look plain.** Enable the `vault-colors` snippet in Obsidian (Appearance → CSS snippets).

## Credits

- Andrej Karpathy, *LLM Wiki* (the pattern this pack implements).
- Built as [Claude Code](https://claude.com/claude-code) skills.

License: MIT.
