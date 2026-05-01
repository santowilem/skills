# santowilem/skills

Reusable agent skills for AI coding assistants (Claude Code, Cursor, etc.). Distributed via the [skills.sh](https://skills.sh) CLI.

## Skills

| Skill | Purpose | Recommended companion |
|---|---|---|
| [`sw-clone`](./skills/sw-clone/) | Pixel-faithful clone of any web UI from screenshots, URLs, or raw HTML — into the user's existing stack | [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) for live screenshot capture |

## Install

Global (recommended):

```bash
npx skills add santowilem/skills --skill sw-clone -g
```

Per-project:

```bash
npx skills add santowilem/skills --skill sw-clone
```

Install all skills from this repo:

```bash
npx skills add santowilem/skills -g
```

### Optional: Chrome DevTools MCP (recommended for `sw-clone`)

`sw-clone` works without it but produces **dramatically better** results when [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed — it lets the agent take real screenshots of the target page instead of working from training-data memory.

**One-line install** (after installing the skill):

Windows (PowerShell):
```powershell
~/.claude/skills/sw-clone/scripts/install-chrome-devtools-mcp.ps1
```

Mac/Linux:
```bash
~/.claude/skills/sw-clone/scripts/install-chrome-devtools-mcp.sh
```

Or manually add to `~/.claude/settings.json`:
```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"]
    }
  }
}
```

Restart Claude Code after either method.

## Develop

### Repo structure

```
skills/                       ← all published skills live here
├── sw-clone/
│   └── SKILL.md
└── ...
template/                     ← starter for new skills (not installable)
└── _STARTER.md                  copy this into a new skills/<name>/SKILL.md
README.md
.gitignore
```

> The template file is `_STARTER.md` (not `SKILL.md`) so the `npx skills` CLI doesn't list it as an installable skill.

### Adding a new skill

1. Create the skill folder: `mkdir skills/<your-skill-name>`
2. Copy the starter: `cp template/_STARTER.md skills/<your-skill-name>/SKILL.md`
3. Add the YAML frontmatter at the top (see `_STARTER.md` for the template) and write the body
4. Test locally before publishing:
   ```bash
   npx skills add D:\training\skills --skill <your-skill-name> -g
   ```
5. Iterate the SKILL.md until it triggers reliably and produces good output
6. Commit + push to GitHub — `npx skills update` will pick up changes

### Tooling

For draft + iteration help, use the `skill-creator` skill from `anthropics/skills`:

```bash
npx skills add anthropics/skills --skill skill-creator -g
```

## License

MIT
