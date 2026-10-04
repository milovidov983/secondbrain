# Examples

Presets cover common kinds of vaults. Everything specific to *you* goes into the `## My Conventions` section of your vault `CLAUDE.md`. Claude treats those lines as rules, exactly like preset conventions.

Each example below is a block you can paste into `## My Conventions` and adapt. Claude can also write it for you during onboarding ("/wiki") from a description like "I'm a software architect, I support several product domains".

| Example | Presets it builds on |
|---|---|
| [engineering-work.md](engineering-work.md): an engineer or architect supporting several domains and systems at work | `project` (+ `codebase`, `personal`) |
| [cooking.md](cooking.md): a home cooking vault with recipes and ingredients | `general` |

## Writing your own

A good convention says:

1. **What the thing is** and where it lives: a folder (`wiki/recipes/`) or, more simply, a concept page with a tag (`tag recipe`).
2. **Its `type`** and **fields**, with allowed values.
3. **Naming**, if it matters (`Domain <Name>`, `YYYY-MM-DD <Topic>`).
4. **Links**: which field points where (`domain: "[[Domain X]]"`).

Prefer tags on concept pages over new folders: fewer folders, fewer indexes. Create a folder only for a type with many pages that you browse as a group.
