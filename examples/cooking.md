# Example: home cooking vault

Setup:

```bash
./install.sh --vault ~/cooking --preset general --modules none \
  --purpose "Home cooking: recipes I make, techniques, ingredients, what worked" --yes
```

Paste into `## My Conventions` of the vault `CLAUDE.md`:

```markdown
- **Recipes** live in `wiki/recipes/` (`type: recipe`) with fields `cuisine`, `time_minutes`, `servings`,
  `difficulty: easy|medium|hard`, `tried: true|false`, `rating` (1-5), `ingredients` (wikilinks).
  Body: ingredients, steps, and a `## My notes` section with dated attempts.
- **Ingredients** are entities with `entity_type: ingredient`: season, substitutes, where I buy it.
- **Techniques** (braising, emulsions, fermentation) are concept pages with tag `technique`;
  recipes link the techniques they use in `related`.
- Recipe sources (videos, blogs, books) are ingested as sources; the recipe page cites them in `sources`.
- When I say "I made X", append a dated entry to `## My notes` of the recipe and update `tried` and `rating`.
```

Since recipes get their own folder, also create `wiki/recipes/_index.md` and a `## Recipes` section in `wiki/index.md` (or ask Claude to do it).
