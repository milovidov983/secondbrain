# Frontmatter Schema

Every wiki page starts with flat YAML frontmatter. No nested objects. Obsidian's Properties UI requires flat structure.

---

## Universal Fields

Every page, no exceptions:

```yaml
---
type: <source|entity|concept|synthesis|comparison|meta|...preset types>
title: "Human-Readable Title"
description: "One sentence: what this page says."
created: 2026-04-07
updated: 2026-04-07
tags:
  - <domain-tag>
  - <type-tag>
status: <seed|developing|mature|evergreen>
related:
  - "[[Other Page]]"
sources:
  - "[[Source Page Title]]"
---
```

`sources` links to wiki pages in `wiki/sources/`, never to files in `.raw/`. Obsidian does not index dot-folders, so a `[[.raw/...]]` link is always unresolved. The path to the original file goes in the `url` field of the source page.

**status values:**
- `seed`: exists, barely populated
- `developing`: has real content, not yet complete
- `mature`: comprehensive, well-linked
- `evergreen`: unlikely to need updates

`status` is how complete a page is, not how much to trust it. Trust and freshness have their own fields, below.

**description:** one sentence that summarizes the page, written so it makes sense in a list without opening the page. It is the text of the page's entry in `wiki/index.md` and the sub-indexes, copied verbatim. When the description changes, update those entries. Required on every page except `type: meta`.

---

## Trust and Freshness Fields

Optional, flat, on any page. Their absence carries meaning, so never fill them with placeholders.

```yaml
reviewed: 2026-04-07     # the owner confirmed the page against its sources on this date
stale_after: 2026-10-01  # the content may be out of date from this date on
```

### reviewed

Who wrote a page (almost always Claude) and who confirmed it are different things. `reviewed` records the second.

- Set it only when the owner says they checked the page ("I checked [[X]]", "mark reviewed", "проверил"). Claude never sets or moves it on its own initiative, including after its own edits.
- Never remove it. A later edit bumps `updated`, and that alone shows the review is out of date.

Trust levels are derived, not stored:

| Level | Condition |
|---|---|
| unreviewed | no `reviewed` |
| reviewed | `reviewed` >= `updated` |
| review outdated | `updated` > `reviewed`: the page changed after the owner checked it |

Use them when pages disagree (a reviewed page outweighs an unreviewed one, though a newer source can still override it) and to tell the owner what deserves a look. They do not block anything: an unreviewed page is still used.

### stale_after

The date from which the content may no longer be true. A page is **expired** when `stale_after` <= today.

- Set it when a page holds facts that expire on their own, without a new source: prices, versions, current state of a system or a project, plans, rankings, someone's current role. Pick the date from how fast the facts change (a release version: 3-6 months; a person's role: a year).
- Leave it out for content that does not expire: definitions, history, a summary of a fixed document. Never set it on `evergreen` pages.
- When the page is re-checked and still true, move `stale_after` forward and leave `updated` alone: the content did not change. When it is no longer true, update the content (and `updated`), then set a new `stale_after`.

---

## Type-Specific Additions

### source

Add these fields after the universal fields:

```yaml
source_type: article    # article | video | podcast | paper | book | transcript | data
author: ""
date_published: YYYY-MM-DD
url: ""                 # web URL, or path to the original file in .raw/ as a plain string
confidence: high        # high | medium | low
key_claims:
  - "First key claim from this source"
  - "Second key claim"
```

### entity

```yaml
entity_type: person     # person | organization | product | place | ... (vault conventions may add more)
role: ""
first_mentioned: "[[Source Title]]"
```

### concept

```yaml
complexity: intermediate  # basic | intermediate | advanced
domain: ""              # topic area this concept belongs to
aliases:
  - "alternative name"
  - "abbreviation"
```

### comparison

```yaml
subjects:
  - "[[Thing A]]"
  - "[[Thing B]]"
dimensions:
  - "performance"
  - "cost"
  - "ease of use"
verdict: "One-line conclusion."
```

### question

```yaml
question: "The original query as asked."
answer_quality: solid   # draft | solid | definitive
```

### preset types

Presets add types such as `goal`, `area`, `review`, `paper`, `thesis`, `resource`, `practice`, `decision`, `meeting`, `module`, `flow`, `task`. Their fields are defined in the preset conventions copied into the vault `CLAUDE.md` and in the templates in `_templates/`. Those definitions win over this file.

---

## Rules

1. Use flat YAML only. Never nest objects.
2. Dates as `YYYY-MM-DD` strings, not ISO datetime.
3. Lists always use the `- item` format, not inline `[a, b, c]`.
4. Wikilinks in YAML fields must be quoted: `"[[Page Name]]"`.
5. Keep `related` and `sources` as wikilinks, not plain URLs.
6. Update `updated` every time you change what the page says. Pure upkeep (adding a link to `related`, fixing a tag, filling a missing field) does not count, so that it does not make a review look outdated.
7. Never write empty `reviewed` or `stale_after` fields: leave them out until there is a date.
