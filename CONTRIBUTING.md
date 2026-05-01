# Contributing

This guide is for adding new skills to this repo. If you just want to install and use the skills, see [README.md](./README.md).

## Repo structure

```
skills/                       ← all published skills live here
├── clone-ui/
│   ├── SKILL.md
│   ├── evals/
│   │   └── evals.json
│   └── scripts/
└── ...
template/                     ← starter for new skills (not installable)
└── _STARTER.md                  copy this into a new skills/<name>/SKILL.md
assets/                       ← shared images used in README (demo screenshots, etc.)
README.md
CONTRIBUTING.md
.gitignore
```

> The template file is `_STARTER.md` (not `SKILL.md`) so the `npx skills` CLI doesn't list it as an installable skill alongside the real ones.

## Adding a new skill

1. Create the skill folder: `mkdir skills/<your-skill-name>`
2. Copy the starter into it as `SKILL.md`:
   ```bash
   cp template/_STARTER.md skills/<your-skill-name>/SKILL.md
   ```
3. Add the YAML frontmatter at the top of the new `SKILL.md` (see `_STARTER.md` for the template) and write the body.
4. Test locally before publishing:
   ```bash
   npx skills add /absolute/path/to/this/repo --skill <your-skill-name> -g
   ```
5. Iterate the SKILL.md until it triggers reliably and produces good output. The [`skill-creator`](https://github.com/anthropics/skills/tree/main/skills/skill-creator) skill from `anthropics/skills` is a great companion — it walks you through draft + eval + iteration cycles.
6. Commit + push to GitHub. Existing installs pick up the changes via `npx skills update`.

## Skill quality bar

Before merging a new skill into the repo, it should:

- Have a description that triggers reliably without being spammy (use the "pushy but precise" style — list trigger phrases, but don't pretend the skill applies to things it doesn't).
- Include `evals/evals.json` with at least 3 test prompts the skill should handle.
- Pass a manual eval iteration (use `skill-creator`'s flow — draft, run, review, iterate).
- Document any companion MCP servers or setup steps in both the SKILL.md and the README's per-skill section.
- Stay under ~500 lines in SKILL.md (per the Anthropic skill-writing guidance — longer than that and it should be split into reference docs).

## Tooling

For draft + iteration help, install [`skill-creator`](https://github.com/anthropics/skills/tree/main/skills/skill-creator) globally:

```bash
npx skills add anthropics/skills --skill skill-creator -g
```

Then ask your assistant to "create a new skill for X" — it'll walk you through capture intent, drafting, eval setup, and iteration.

## Workspace folders

When you iterate via `skill-creator`, it creates a `<skill-name>-workspace/` folder next to the skill with test outputs, screenshots, and benchmarks. These are ignored via `.gitignore` (`*-workspace/`) — don't commit them. They're per-developer scratch space.
