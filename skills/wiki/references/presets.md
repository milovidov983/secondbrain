# Presets and Modules

A vault always has the **core**: `.raw/`, `wiki/{index,log,hot,overview}.md`, and the core page types:

| Type | Folder | What |
|---|---|---|
| `source` | `wiki/sources/` | one summary per source document |
| `entity` | `wiki/entities/` | a person, organization, product, place, dataset |
| `concept` | `wiki/concepts/` | an idea, topic, technique, project |
| `synthesis` | `wiki/questions/` | a filed answer or research synthesis |
| `comparison` | `wiki/comparisons/` | a side-by-side analysis |
| `meta` | `wiki/meta/`, `wiki/*.md` | indexes, dashboards, lint reports |

A **preset** adds page types, folders, templates and conventions for one kind of vault. Presets combine: `--preset research,personal`. The definitions live in `assets/presets/<name>/` (`folders`, `conventions.md`, `_templates/`). The vault `CLAUDE.md` holds a copy of the conventions of the presets it uses, and that copy is authoritative.

## Choosing

| The vault is about... | Preset |
|---|---|
| A topic you explore: cooking, history, investing, a hobby | `general` |
| Your life: goals, health, finance, people, books, reflections | `personal` |
| A research question: papers, claims, methods, a thesis | `research` |
| Learning a subject or skill: books, courses, exercises | `learning` |
| Work, a team, a project, a business, clients | `project` |
| A codebase or a technical system | `codebase` |

Examples of combinations:

- "Work as an engineer plus personal life" → `project,personal`
- "PhD on X" → `research,learning`
- "Understanding our product's backend for my job" → `codebase,project`
- "Learning Spanish" → `learning`
- "Everything about my garden" → `general`

When in doubt, start with `general`. A preset can be added later without migration ("add the research preset").

## Presets

### general
No extra folders. Topic areas are described in `wiki/overview.md` and grouped with tags (`#area/<name>`).

### personal
- `wiki/goals/` (`type: goal`): `area`, `target_date`, `progress`, `status: active|paused|done|abandoned`
- `wiki/areas/` (`type: area`): ongoing responsibilities (Health, Finance, Career)
- `wiki/reviews/` (`type: review`): weekly / yearly reviews drafted by Claude from the log, goals and tasks
- Templates: Goal, Area, Review

### research
- `wiki/papers/` (`type: paper`): `authors`, `year`, `venue`, `key_claim`, `methodology`, `supports`, `contradicts`
- `wiki/theses/` (`type: thesis`): living answers to the central research questions
- Templates: Paper, Thesis

### learning
- `wiki/resources/` (`type: resource`): a book or course being worked through, with `progress`
- `wiki/practice/` (`type: practice`): exercises and projects linked to the concepts they train
- Concepts carry `prerequisites`; not-yet-understood concepts are marked `> [!gap]`
- Templates: Resource, Practice

### project
- `wiki/decisions/` (`type: decision`): context, options, decision, consequences; superseded, never rewritten
- `wiki/meetings/` (`type: meeting`): `YYYY-MM-DD <Topic>`, summary, decisions, action items
- Projects are concepts with tag `project`; people and teams are entities with a `role`
- Templates: Decision, Meeting

### codebase
- `wiki/modules/` (`type: module`): `path`, `language`, `depends_on`, `used_by`
- `wiki/flows/` (`type: flow`): request paths and processes, with Mermaid diagrams
- `wiki/decisions/` (`type: decision`): ADRs
- The code is read from the repository, not copied to `.raw/` (see "Living Repository Sources" in `wiki-ingest`)
- Templates: Module, Flow, Decision

## Modules

### inbox
- `Inbox/YYYY-MM-DD.md`: free-form capture, no frontmatter
- `Tasks/` (`type: task`): one file per task
- Skill `wiki-inbox`: weekly triage, plan first, apply after confirmation
- Link direction: materials point to tasks through `activity`; tasks never list materials
- Template: Task

## Your Own Page Types

Presets are just examples. Any vault can define its own types in `## My Conventions` of its `CLAUDE.md`, for example:

```markdown
- Recipes are concept pages with tag `recipe` and fields `cuisine`, `time_minutes`, `servings`.
- Clients are entities with `entity_type: client` and fields `contract_start`, `status`.
```

Claude follows these exactly like preset conventions. If a type needs its own folder, create `wiki/<folder>/` with an `_index.md`, add a section to `wiki/index.md`, and mention it in `## Structure`. See `examples/` in the pack for a full worked example.

## Making a New Preset

Create `assets/presets/<name>/` in the pack with:

- `description`: one line, shown by `scaffold.sh --list`
- `folders`: one line per extra `wiki/` folder, `name<TAB>description`
- `conventions.md`: the rules, copied into the vault `CLAUDE.md`
- `_templates/*.md` (optional): Obsidian templates for the new types

Then re-run `./install.sh`.
