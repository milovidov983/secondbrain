---
name: wiki-query
description: "Answer questions using the Obsidian wiki vault. Reads hot cache first, then index, then relevant pages. Synthesizes answers with citations. Files good answers back as wiki pages. Supports quick, standard, and deep modes. Triggers on: what do you know about, query:, what is, explain, summarize, find in wiki, search the wiki, based on the wiki, wiki query quick, wiki query deep."
allowed-tools: Read Glob Grep Write Edit
---

# wiki-query: Query the Wiki

The wiki has already done the synthesis work. Read strategically, answer precisely, and file good answers back so the knowledge compounds.

---

## Query Modes

Three depths. Choose based on the question complexity.

| Mode | Trigger | Reads | Token cost | Best for |
|------|---------|-------|------------|---------|
| **Quick** | `query quick: ...` or simple factual Q | hot.md + index.md only | ~1,500 | "What is X?", date lookups, quick facts |
| **Standard** | default (no flag) | hot.md + index + 3-5 pages | ~3,000 | Most questions |
| **Deep** | `query deep: ...` or "thorough", "comprehensive" | Full wiki + optional web | ~8,000+ | "Compare A vs B across everything", synthesis, gap analysis |

---

## Quick Mode

Use when the answer is likely in the hot cache or index summary.

1. Read `wiki/hot.md`. If it answers the question, respond immediately.
2. If not, read `wiki/index.md`. Scan descriptions for the answer.
3. If found in index summary, respond and do not open any pages.
4. If not found, say "Not in quick cache. Run as standard query?"

Do not open individual wiki pages in quick mode.

---

## Standard Query Workflow

1. **Read** `wiki/hot.md` first. It may already have the answer or directly relevant context.
2. **Read** `wiki/index.md` to find the most relevant pages. Answer in the vault's content language unless the user writes in another one (scan for titles and descriptions).
3. **Read** those pages. Follow wikilinks to depth-2 for key entities. No deeper.
4. **Synthesize** the answer in chat. Cite sources with wikilinks: `(Source: [[Page Name]])`. Weigh what you read by trust and freshness (see below).
5. **Offer to file** the answer: "This analysis seems worth keeping. Should I save it as `wiki/questions/answer-name.md`?"
6. If the question reveals a **gap**: say "I don't have enough on X. Want to find a source?"

---

## Deep Mode

Use for synthesis questions, comparisons, or "tell me everything about X."

1. Read `wiki/hot.md` and `wiki/index.md`.
2. Identify all relevant sections (concepts, entities, sources, comparisons).
3. Read every relevant page. No skipping.
4. If wiki coverage is thin, offer to supplement with web search.
5. Synthesize a comprehensive answer with full citations, weighing pages by trust and freshness (see below).
6. Always file the result back as a wiki page. Deep answers are too valuable to lose.

---

## Trust and Freshness

Every page records who confirmed it and how long it stays true (`reviewed`, `stale_after`; rules in `~/.claude/skills/wiki/references/frontmatter.md`). Read those fields on every page you open and use them like this:

- **Expired** (`stale_after` <= today): use it, but say so next to the claim: "(as of [[Page]], may be out of date since YYYY-MM-DD)". If the answer hinges on it, offer to re-check the source or search the web.
- **Pages disagree:** prefer a reviewed page (`reviewed` >= `updated`) over an unreviewed one, unless the unreviewed one rests on a clearly newer source. Name the conflict either way; never silently pick a side.
- **Review outdated** (`updated` > `reviewed`): treat it as unreviewed.
- Do not label every claim with its trust level. Mention it only when it changes the answer: a conflict, an expired fact, or a decision the user is about to make on an unreviewed page.

Quick mode reads only the index, which carries no dates. If a quick answer is about something time-sensitive (prices, versions, current state), say it comes from the index and offer a standard query.

---

## Token Discipline

Read the minimum needed:

| Start with | Cost (approx) | When to stop |
|------------|---------------|--------------|
| hot.md | ~500 tokens | If it has the answer |
| index.md | ~1000 tokens | If you can identify 3-5 relevant pages |
| 3-5 wiki pages | ~300 tokens each | Usually sufficient |
| 10+ wiki pages | expensive | Only for synthesis across the entire wiki |

If hot.md has the answer, respond without reading further.

---

## Index Format Reference

The master index (`wiki/index.md`) looks like:

```markdown
## Navigation
- [[overview]], [[hot]], [[log]]

## Entities
- [[Entity Name]] — <description>

## Concepts
- [[Concept Name]] — <description>

## Sources
- [[Source Title]] — <description>

## Questions
- [[Question Title]] — <description>

## Comparisons
- [[Comparison Title]] — <description>

## <Preset sections: Papers, Goals, Decisions, ...>
- [[Page]] — <description>
```

Every entry is the page's `description` frontmatter field, copied verbatim. Scan the section headers first to determine which sections to read.

---

## Sub-Index Format

`wiki/entities/`, `wiki/concepts/` and `wiki/sources/` each have an `_index.md` for focused lookups:

```markdown
---
type: meta
title: "Entities Index"
updated: YYYY-MM-DD
---
# Entities

## People
- [[Person Name]] — <description>

## Organizations
- [[Org Name]] — <description>

## Products
- [[Product Name]] — <description>
```

Use sub-indexes when the question is scoped to one type of page. Avoid reading the full master index for narrow queries.

---

## Filing Answers Back

Good answers compound into the wiki. Don't let insights disappear into chat history.

When filing an answer:

```yaml
---
type: synthesis
title: "Short descriptive title"
description: "One sentence: the answer in short."
question: "The exact query as asked."
answer_quality: solid
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - question
  - <topic>
status: developing
related:
  - "[[Page referenced in answer]]"
sources:
  - "[[Relevant Source]]"
---
```

Save it to `wiki/questions/<Short descriptive title>.md` (template: `_templates/Synthesis.md`). Write the answer as the page body. Include citations. Link every mentioned concept or entity. If the answer rests on facts that expire, set `stale_after` to the earliest `stale_after` among the pages it relies on (or your own estimate). Never set `reviewed`.

After filing, add `- [[Title]] — <description>` to `wiki/index.md` under Questions, add a new entry at the TOP of `wiki/log.md`, and rewrite `wiki/hot.md`.

---

## Gap Handling

If the question cannot be answered from the wiki:

1. Say clearly: "I don't have enough in the wiki to answer this well."
2. Identify the specific gap: "I have nothing on [subtopic]."
3. Suggest: "Want to find a source on this? I can help you search or process one."
4. Do not fabricate. Do not answer from training data if the question is about the specific domain in this wiki.
