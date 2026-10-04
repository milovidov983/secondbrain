<!-- secondbrain:begin (managed by secondbrain/install.sh; edit the source in global-CLAUDE.md) -->
## Second brain: Obsidian vault (LLM Wiki pattern)

My knowledge lives in an Obsidian vault maintained by Claude (secondbrain pack, Karpathy LLM Wiki pattern).

Vault path: {{VAULT_PATH}}
A workspace `CLAUDE.md` may name a different vault; it takes precedence.

### When to use it

Use the vault when the task needs context that is not in the current project: my notes, decisions, people, sources, earlier research. Do not read it for general programming questions or for things already in the current project or conversation.

### How to read it (cheapest first)

1. `wiki/hot.md`: ~500 words of recent context.
2. `wiki/index.md`: the full catalog. Then `wiki/<folder>/_index.md` for one section.
3. Individual pages (100-300 lines each).
4. Grep over `wiki/` for exact facts.

### Rules

- The vault's own `CLAUDE.md` is its schema: read it before writing anything there.
- Writing to the vault goes through the skills: `wiki` (setup, routing), `wiki-ingest`, `wiki-query`, `save`, `wiki-lint`, and `wiki-inbox` if the inbox module is enabled.
- After any write: update `wiki/index.md`, add an entry at the TOP of `wiki/log.md`, and rewrite `wiki/hot.md`.
- Never modify files in `.raw/`.
- When an answer relies on a vault page, check its frontmatter: if `stale_after` is today or earlier, say the fact may be out of date; if pages disagree, prefer one with `reviewed` on or after `updated` (the owner checked it). Never set `reviewed` yourself.
<!-- secondbrain:end -->
