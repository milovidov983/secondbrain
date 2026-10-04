# Example: engineering work vault

For an engineer or architect who supports several product domains at a company and wants one vault for work (and optionally personal life).

Setup:

```bash
./install.sh --vault ~/vault --preset project,personal --modules inbox \
  --purpose "Work as a system architect at <Company>, plus personal life" --yes
```

Paste into `## My Conventions` of the vault `CLAUDE.md`:

```markdown
- **Domains** (the product areas I support) are concept pages named `Domain <Name>`
  with tag `domain` and field `support: active|former|adjacent`.
- **Systems** (services, legacy servers, shared platforms, key databases) are concept pages with tag `system`
  and fields `owner` (team entity), `domain: "[[Domain <Name>]]"`.
- **Projects** are concept pages with tag `project` and field `domain: "[[Domain <Name>]]"`.
- **Technologies** are concept pages with tag `technology`.
- Teams are entities with `entity_type: team`; people get `role` and `team`.
- The architecture repository (living source, read from git, never copied to .raw/):
  - Clone: `~/src/architecture`, prefix `arch`. Reference documents as `arch:<path>` or `arch@<branch>:<path>`.
- Old vault (read-only, not migrated wholesale): `~/old-vault`, referenced as `legacy:<path>`.
```

What this gives you:

- `query: what do we know about Domain Payments` pulls the domain page, its systems, projects, people and decisions.
- Ingesting a meeting updates the meeting page, the decisions, the systems and the people involved.
- `wiki-lint` flags systems without a domain and projects without an owner.
