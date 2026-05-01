# Skill Starter Template

> **Not installable.** This file is a starter template for adding new skills to this repo, not a real skill. To use it, copy this folder to `skills/<your-skill-name>/SKILL.md`, then edit the frontmatter and body.

When you copy this to a new skill folder, restore the YAML frontmatter:

```
---
name: your-skill-name
description: When the skill should trigger and what it does. Be "pushy" — list user phrases and contexts that should activate the skill, even ambiguous ones. Skills tend to undertrigger; counter that with explicit trigger language.
---
```

Then build out these sections:

## When to use

Describe the user contexts where this skill applies.

## When **not** to use

Disambiguate from neighboring skills.

## Workflow

Phase-by-phase steps. Resist the urge to compress — explicit phases prevent skipping.

## Anti-patterns

Common failure modes from prior runs of this workflow.

## Output expectations

What the user should receive when the skill finishes successfully.

---

To use this template:

1. Copy this folder: `cp -r template skills/<your-skill-name>`
2. Edit the frontmatter `name` and `description`
3. Replace the body with real content
4. Test locally: `npx skills add D:\training\skills --skill <your-skill-name> -g`
5. Commit and push when ready
