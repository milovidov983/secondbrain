# The Method

How to live with a secondbrain vault day to day: where knowledge comes from, what happens to it, how to move an old vault in, and the rhythm that keeps it alive.

## The core idea

Second brains rarely die because of a bad structure. They die because of the **cost of maintaining it by hand**: frontmatter, links, folders, indexes. When a more convenient tool comes along, the vault degrades into a diary and is abandoned.

In an LLM Wiki the human only **curates**: drops in sources, writes free-form notes, asks questions. Claude maintains frontmatter, links, indexes, the hot cache and the list of contradictions. Restructuring is cheap too: Claude can rename folders and fix every link in one go. Fixing the structure no longer means starting a new vault.

## The knowledge lifecycle

```
Inbox/ ──triage──▶ .raw/ ──ingest──▶ wiki/
(anything)  (weekly)   (only what's worth it)   (knowledge)
              │
              └──▶ Tasks/ or deleted
```

Without the inbox module the flow is shorter: source → `.raw/` → ingest → `wiki/`.

**Junk is filtered at the entrance**, not by cleaning `.raw/` later.

### Inbox: the capture layer (inbox module)

- Write into `Inbox/YYYY-MM-DD.md` like a diary: links, todos, thoughts, scraps. No frontmatter, no structure.
- Once a week say "process inbox". Claude shows a plan; you confirm or edit it. Then Claude routes every item:
  - open todos → `Tasks/`;
  - articles and documents → `.raw/` + ingest;
  - reference links → a `## Links` section on the page for that topic;
  - ideas and decisions → concept pages;
  - facts about people → entity pages;
  - noise → deleted.
- Today's note is skipped by default: you are probably still writing it.
- Processed files are deleted (history stays in git); deferred items stay in the Inbox.

### `.raw/`: immutable sources

`.raw/` is **never cleaned**, because:
- a wiki page is a summary and may be wrong; the original lets you check it;
- contradictions cannot be resolved without the originals;
- `.raw/.manifest.json` stores hashes, so a changed document is re-ingested and an unchanged one is skipped;
- in Obsidian, `.raw/` is hidden (a dot-folder) and does not clutter the explorer or the graph.

Delete only duplicates, superseded versions, and sources whose ingest produced nothing (together with their source page).

**Layout:**
- subfolders such as `.raw/articles/`, `.raw/docs/`, `.raw/meetings/`, `.raw/images/`, `.raw/claude/`;
- names `YYYY-MM-DD-slug.md`, where the date is the document's date;
- PDF and DOCX are converted to markdown;
- heavy binaries stay out of git.

**Living repositories are not copied into `.raw/`.** Documents in git repositories that keep changing (a codebase, a docs repo edited through pull requests) go stale as soon as they are copied. The wiki gets a source page with a summary and a reference like `<prefix>@<branch>:<path>`, and the document itself is read from git before every discussion (see "Living Repository Sources" in `wiki-ingest`).

### Ingest: a source becomes knowledge

One source usually touches 5-15 pages:
- a summary in `wiki/sources/` (or a preset type: a paper, a meeting);
- pages of the people, organizations, concepts and projects involved;
- preset pages it affects: a thesis, a goal, a decision;
- indexes, the log, the hot cache.

Contradictions with older pages are not overwritten. They are flagged with `> [!contradiction]` on both pages, and you decide.

**People.** A person gets a page only with a clear role or repeated appearances. Everyone else is listed in the source summary. Empty stubs are the typical junk of old vaults.

### Review: you confirm, Claude records

Claude writes almost every page, so a page being in the wiki says nothing about whether it is right. When you have checked a page against its sources, say "I checked [[Page]]": Claude sets `reviewed` to today. It never sets it on its own. If the page changes later, `updated` moves past `reviewed` and the page shows up in "what needs review?" and in lint.

You do not need to review everything. Review the pages you act on: the ones decisions, money or other pages depend on. In a conflict Claude prefers a reviewed page; an unreviewed one is still used.

### Freshness: facts that expire

Some knowledge goes out of date without any new source: prices, versions, the current state of a project, plans, someone's role. Claude gives such pages a `stale_after` date. After it, the page is **expired**: queries still use it but say so, and lint lists it with a hint on how to re-check. A definition or a summary of a fixed document gets no date.

### Query and save: knowledge compounds

A good answer is filed back into `wiki/questions/` and becomes part of the wiki. A valuable discussion becomes a page with `/save`. The next question starts from a richer wiki.

## Your vault, your schema

The vault `CLAUDE.md` is the contract between you and Claude. It holds the purpose, presets, content language and your conventions. Edit it whenever something should work differently:

- a new page type ("recipes are concept pages with tag `recipe` and fields `cuisine`, `time_minutes`");
- a naming rule;
- what to ignore;
- how detailed source summaries should be.

Claude follows the vault `CLAUDE.md` over the skills' defaults. See [examples/](examples/) for a full set of custom conventions.

## Moving an existing vault in

Do **not** migrate an old vault wholesale: its old, failed structure would move along with the data. Leave it where it is, read-only, and reference its files as `legacy:<path>`.

1. **Survey.** Claude looks at the old vault: size, note types, where things are, how actively it was kept. The result is a source page about the old vault and a mapping of its folders to topics.
2. **Skeleton from the present.** You say what is alive now and what is not. Claude creates `seed` pages for the living topics: what it is, related people, the best candidate documents for ingest. Dead topics are not moved at all.
3. **Ingest one key document per topic.** The document is copied into `.raw/`, so the source survives even if the old vault is deleted. Topic pages become `developing`, and pages for related concepts and people appear.
4. **Current flow.** Recent daily notes of the old vault are triaged like an Inbox. Open tasks are reviewed as one list; the live ones move to `Tasks/`.
5. **The rest, lazily.** "Find everything about X in the old vault" makes Claude build a summary page on X. Whatever is never asked for stays in the old vault.

## Other tools (Claude web, ChatGPT, notes apps)

**The vault is the single source of truth**; everything else is a workbench.
- Think and discuss wherever it is convenient.
- What is valuable goes into the vault in one action: `/save` in Claude Code, or export the conversation to `.raw/claude/` and ingest it.
- Never copy by hand into two places.

## Rhythm

| When | What | Who |
|---|---|---|
| Any time | Notes in `Inbox/`, documents into `.raw/` | you |
| On demand | ingest, "query:", `/save` | Claude |
| Weekly | "process inbox" (inbox module); a weekly review (personal preset) | Claude drafts, you confirm |
| Every 2-4 weeks | "lint the wiki": orphans, dead links, contradictions, gaps, expired pages | Claude |
| When you act on a page | Check it and say "I checked [[Page]]"; "what needs review?" shows the queue | you |
| Quarterly | Structure review: presets, page types, conventions in `CLAUDE.md` | together |

## Git and sync

- The vault lives in a private git repository. The obsidian-git plugin makes automatic backups.
- Obsidian and Claude Code commit to the same repository, so `git pull --rebase` before every `git push`.
- Context between Claude Code sessions lives in the vault itself: `wiki/hot.md`, `wiki/index.md`, `wiki/log.md`. Claude Code's conversation history is local to the machine and is not needed to continue.
