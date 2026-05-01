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
skills/                  ← all published skills live here
├── sw-clone/
│   └── SKILL.md
└── ...
template/                ← starter SKILL.md for new skills
└── SKILL.md
README.md
.gitignore
```

### Adding a new skill

1. Copy the template: `cp -r template skills/<your-skill-name>`
2. Edit `skills/<your-skill-name>/SKILL.md` — fill in `name`, `description`, body
3. Test locally before publishing:
   ```bash
   npx skills add D:\training\skills --skill <your-skill-name> -g
   ```
4. Iterate the SKILL.md until it triggers reliably and produces good output
5. Commit + push to GitHub — `npx skills update` will pick up changes

### Tooling

For draft + iteration help, use the `skill-creator` skill from `anthropics/skills`:

```bash
npx skills add anthropics/skills --skill skill-creator -g
```

## License

MIT
