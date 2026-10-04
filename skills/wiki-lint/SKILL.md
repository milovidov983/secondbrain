---
name: wiki-lint
description: >
  Health check the Obsidian wiki vault. Finds orphan pages, dead wikilinks, stale claims,
  expired pages, pages that need the owner's review, missing cross-references, frontmatter
  gaps, and empty sections. Creates or updates
  Dataview dashboards. Generates canvas maps. Triggers on: "lint", "health check",
  "clean up wiki", "check the wiki", "wiki maintenance", "find orphans", "wiki audit".
allowed-tools: Read Write Edit Glob Grep
---

# wiki-lint: Wiki Health Check

Run lint after every 10-15 ingests, or weekly. Ask before auto-fixing anything. Output a lint report to `wiki/meta/lint-report-YYYY-MM-DD.md`.

---

## Lint Checks

Work through these in order:

1. **Orphan pages**. Wiki pages with no inbound wikilinks. They exist but nothing points to them.
2. **Dead links**. Wikilinks that reference a page that does not exist. This includes any `[[.raw/...]]` link: Obsidian does not index dot-folders, so these links never resolve. Fix by removing the link and keeping the path as a plain string in the source page's `url` field.
3. **Stale claims**. Assertions on older pages that newer sources have contradicted or updated.
4. **Missing pages**. Concepts or entities mentioned in multiple pages but lacking their own page.
5. **Missing cross-references**. Entities mentioned in a page but not linked.
6. **Frontmatter gaps**. Pages missing required fields (type, title, description, status, created, updated, tags; `meta` pages need no description), plus the type-specific fields defined in `~/.claude/skills/wiki/references/frontmatter.md` and in the preset conventions of the vault `CLAUDE.md`.
7. **Empty sections**. Headings with no content underneath.
8. **Stale index entries**. Items in `wiki/index.md` or the sub-indexes (`wiki/*/_index.md`, including preset folders) pointing to renamed or deleted pages, pages missing from them, and entries whose text differs from the page's `description`.
9. **Misplaced pages**. A page whose `type` belongs to another folder according to the vault `CLAUDE.md` (a `paper` in `wiki/sources/`, a `decision` in `wiki/concepts/`).
10. **Expired pages**. `stale_after` <= today. For each, say what is likely out of date and how to re-check it (re-read the source, a web search, ask the owner). Also flag pages that clearly hold expiring facts (prices, versions, current state, plans) but have no `stale_after`, and `evergreen` pages that have one.
11. **Review queue**. Report only; never set `reviewed` yourself (rules: `~/.claude/skills/wiki/references/frontmatter.md`):
    - review outdated: `updated` > `reviewed`;
    - unreviewed pages that others lean on: `mature` / `evergreen` pages, and pages with many inbound links;
    - pages where a `[!contradiction]` involves a reviewed page.

Checks 6, 8, 10 and 11 read only frontmatter: do them with Grep over `wiki/`, not by opening pages one by one.

---

## Lint Report Format

Create at `wiki/meta/lint-report-YYYY-MM-DD.md`:

```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [meta, lint]
status: developing
---

# Lint Report: YYYY-MM-DD

## Summary
- Pages scanned: N
- Issues found: N
- Auto-fixed: N
- Needs review: N

## Orphan Pages
- [[Page Name]]: no inbound links. Suggest: link from [[Related Page]] or delete.

## Dead Links
- [[Missing Page]]: referenced in [[Source Page]] but does not exist. Suggest: create stub or remove link.

## Missing Pages
- "concept name": mentioned in [[Page A]], [[Page B]], [[Page C]]. Suggest: create a concept page.

## Frontmatter Gaps
- [[Page Name]]: missing fields: status, tags

## Stale Claims
- [[Page Name]]: claim "X" may conflict with newer source [[Newer Source]].

## Expired Pages
- [[Page Name]]: expired YYYY-MM-DD. Likely out of date: the version number. Re-check: the release notes.
- [[Page Name]]: holds current prices but has no `stale_after`. Suggest: stale_after YYYY-MM-DD.

## Review Queue
- [[Page Name]]: reviewed YYYY-MM-DD, changed YYYY-MM-DD (new section on X). Check the new section.
- [[Page Name]]: mature, 12 inbound links, never reviewed.

## Cross-Reference Gaps
- [[Entity Name]] mentioned in [[Page A]] without a wikilink.
```

---

## Naming Conventions

Enforce these during lint:

| Element | Convention | Example |
|---------|-----------|---------|
| Filenames | Title Case with spaces | `Machine Learning.md` |
| Folders | lowercase with dashes | `wiki/data-models/` |
| Tags | lowercase, hierarchical | `#area/health` |
| Wikilinks | match filename exactly | `[[Machine Learning]]` |

Filenames must be unique across the vault. Wikilinks work without paths only if filenames are unique.

---

## Writing Style Check

During lint, flag pages that violate the style guide:

- Not declarative present tense ("X basically does Y" instead of "X does Y")
- Missing source citations where claims are made
- Uncertainty not flagged with `> [!gap]`
- Contradictions not flagged with `> [!contradiction]`

---

## Dataview Dashboard

Create or update `wiki/meta/dashboard.md` with these queries:

````markdown
---
type: meta
title: "Dashboard"
updated: YYYY-MM-DD
---
# Wiki Dashboard

## Recent Activity
```dataview
TABLE type, status, updated FROM "wiki" SORT updated DESC LIMIT 15
```

## Expired
```dataview
TABLE stale_after, updated FROM "wiki" WHERE stale_after AND stale_after <= date(today) SORT stale_after ASC
```

## Review Outdated
```dataview
TABLE reviewed, updated FROM "wiki" WHERE reviewed AND updated > reviewed SORT updated DESC
```

## Mature but Never Reviewed
```dataview
LIST FROM "wiki" WHERE !reviewed AND (status = "mature" OR status = "evergreen") SORT updated DESC
```

## Seed Pages (Need Development)
```dataview
LIST FROM "wiki" WHERE status = "seed" SORT updated ASC
```

## Entities Missing Sources
```dataview
LIST FROM "wiki/entities" WHERE !sources OR length(sources) = 0
```

## Open Questions
```dataview
LIST FROM "wiki/questions" WHERE answer_quality = "draft" SORT created DESC
```
````

---

## Canvas Map

Create or update `wiki/meta/overview.canvas` for a visual domain map:

```json
{
  "nodes": [
    {
      "id": "1",
      "type": "file",
      "file": "wiki/overview.md",
      "x": 0, "y": 0,
      "width": 300, "height": 140,
      "color": "1"
    }
  ],
  "edges": []
}
```

Add one node per sub-index (`wiki/*/_index.md`) and per key concept page. Connect nodes that have significant cross-references. Colors map to the CSS scheme: 1=blue, 2=purple, 3=yellow, 4=orange, 5=green, 6=red.

---

## Before Auto-Fixing

Always show the lint report first. Ask: "Should I fix these automatically, or do you want to review each one?"

Safe to auto-fix:
- Adding missing required frontmatter fields with placeholder values (never `reviewed` or `stale_after`: they are left out until there is a real date)
- Writing a missing `description` from the page body, and syncing index entries to descriptions
- Adding `stale_after` to pages with expiring facts
- Creating stub pages for missing entities
- Adding wikilinks for unlinked mentions

Needs review before fixing:
- Refreshing the content of expired pages (show what would change first)
- Deleting orphan pages (they might be intentionally isolated)
- Resolving contradictions (requires human judgment)
- Merging duplicate pages

Never auto-fix:
- `reviewed`: only the owner sets it
