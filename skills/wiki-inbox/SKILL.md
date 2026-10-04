---
name: wiki-inbox
description: >
  Triage the Obsidian vault Inbox: read free-form daily capture notes in Inbox/, split them into
  items, and route each one to Tasks/, .raw/ + ingest, wiki concept/entity pages, or deletion,
  after the user confirms a triage plan. Updates index, log, and hot cache.
  Triggers on: "разбери inbox", "разбор inbox", "разбери инбокс", "process inbox",
  "triage inbox", "inbox triage", "clean up inbox", "/inbox".
allowed-tools: Read Write Edit Glob Grep Bash WebFetch
---

# wiki-inbox: Inbox Triage

Part of the optional **inbox module**. If the vault has no `Inbox/` folder, say so and offer to enable the module (`wiki` skill, ADD PRESET / MODULE).

Write the plan, task pages and log entries in the vault's content language (see the vault `CLAUDE.md`). The examples below are in English.

`Inbox/` is the capture layer: the owner writes whatever comes up (links, todos, thoughts, meeting scraps) in free form, usually one file per day (`Inbox/YYYY-MM-DD.md`), without frontmatter. Triage turns that into structured knowledge and leaves the Inbox empty.

Junk is filtered here, at the entrance. Whatever passes triage into `.raw/` stays there permanently: `.raw/` is never cleaned up afterwards (see `METHODOLOGY.md` of the secondbrain pack).

Run weekly, or whenever the user asks.

---

## Scope

- Default: every file in `Inbox/` except `.gitkeep`.
- Skip today's note (`Inbox/<today>.md`) unless the user asks for it: it is probably still being written.
- If the user names files or a date range ("process last week's inbox"), process only those.
- Non-markdown files in `Inbox/` (PDF, DOCX, images) are documents: route them to `.raw/`.

---

## Item Types and Routes

Split each note into items: a bullet, a checkbox, a link, or a paragraph on one topic. Classify every item:

| Item | Route | Result |
|------|-------|--------|
| Open todo (`- [ ]`, "todo", "don't forget", or the same in the vault language) | `Tasks/` | New task page from `_templates/Task.md` |
| Done todo (`- [x]`) | delete | Mention in the log only if it closed an existing task (then set that task's `status: done`) |
| Link worth reading in depth (article, doc, spec) | `.raw/articles/` + ingest | Source page via `wiki-ingest` |
| Reference link (tool, dashboard, repo, wiki page to keep handy) | existing concept/entity page | Add to its `## Links` section (heading in the vault language), no ingest |
| Document file in Inbox | `.raw/docs/YYYY-MM-DD-slug.ext` + ingest | Source page via `wiki-ingest` |
| Meeting scrap / notes | `.raw/meetings/YYYY-MM-DD-slug.md` + ingest | Source page via `wiki-ingest` |
| Idea, insight, decision | `wiki/concepts/` | New concept page, or a section appended to an existing one |
| Fact about a person/team/org | `wiki/entities/` | Update the entity page (create a `seed` page if missing) |
| Noise (obsolete, duplicate, already in the wiki) | delete | Counted in the log |
| Unclear | ask | Keep in Inbox if the user says "later" |

Before creating any page, check `wiki/index.md` and Grep `wiki/` and `Tasks/` for an existing one. Prefer updating over creating.

---

## Workflow

1. **Load context.** Read `wiki/hot.md` and `wiki/index.md`. These are needed to match items to existing pages.
2. **Collect.** List files in scope. Read each one completely.
3. **Classify.** Split into items and assign a route using the table above. Pick target pages (existing or new, with proposed titles).
4. **Present the triage plan** and wait for confirmation. Group by route, one line per item:
   ```markdown
   ## Inbox triage: 3 files, 17 items

   ### → Tasks (4)
   - "call the plumber about the leak" → [[Call the plumber about the leak]] (priority: high)

   ### → .raw + ingest (2)
   - https://example.com/article → .raw/articles/article-2026-09-26.md

   ### → Links on pages (3)
   - https://some-tool.example → [[Home Budget]] § Links

   ### → Concepts / Entities (3)
   - idea about batch cooking on Sundays → new [[Batch Cooking]]

   ### ✗ Delete (4)
   - "buy milk" (done)

   ### ? Unclear (1)
   - "check what Alex said" — what does this refer to?

   Files Inbox/2026-09-20.md, Inbox/2026-09-21.md will be deleted after triage.
   ```
   Ask: "Apply? You can edit any line." Apply the user's edits to the plan before proceeding.
5. **Apply.**
   - **Tasks:** one file per task in `Tasks/`, named after the task title (unique, human-readable). Use `_templates/Task.md` fields (`type: task`, `title`, `created`, `status: todo`, `priority`, `due`, `waiting_for`, `tags`). Body: the original wording plus context, and `From Inbox: YYYY-MM-DD`. Do not put links to materials inside a task.
   - **Links to materials:** if a material relates to a task or activity, set the `activity` field in the material's frontmatter (source/concept), never the other way round.
   - **Ingest:** save URLs to `.raw/articles/`, move document files to `.raw/docs/` or `.raw/meetings/`, then load the `wiki-ingest` skill and run it as a batch ingest. Skip its per-source discussion step unless the user wants it.
   - **Concepts / entities:** create from `_templates/Concept.md` / `_templates/Entity.md`, or append a dated section to an existing page and bump its `updated`.
   - **Deletions:** remove the items; they stay recoverable from git history.
6. **Clean up Inbox.** Delete every fully processed file. For a partially processed file, rewrite it to contain only the items the user deferred. Never delete `Inbox/.gitkeep`.
7. **Update bookkeeping** (once, at the end):
   - `wiki/index.md` and the relevant `wiki/*/_index.md`: add new pages.
   - `wiki/log.md`: new entry at the TOP:
     ```markdown
     ## [YYYY-MM-DD] inbox | Inbox triage (N files, M items)
     - Processed: `Inbox/2026-09-20.md`, `Inbox/2026-09-21.md`
     - Tasks created: [[Task 1]], [[Task 2]]
     - Ingested: [[Source 1]]
     - Pages created: [[Page 1]]
     - Pages updated: [[Page 2]]
     - Deleted: K items
     - Left in Inbox: L items (deferred)
     ```
   - `wiki/hot.md`: rewrite, including new tasks and open threads.
8. **Report** in one short summary: what went where, what is left in the Inbox, and any questions still open.

---

## What Not to Do

- Do not apply anything before the user confirms the plan.
- Do not delete an Inbox file while any of its items is unresolved.
- Do not modify existing files in `.raw/`. Only add new ones.
- Do not create duplicate tasks or pages: search first.
- Do not add frontmatter to Inbox files: the Inbox stays free-form.
