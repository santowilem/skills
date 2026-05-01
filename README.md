# santowilem/skills

Reusable agent skills for Claude Code, Cursor, and other AI coding assistants. Distributed via the [skills.sh](https://skills.sh) CLI.

## Skills

### [`clone-ui`](./skills/clone-ui/) — pixel-faithful web UI cloning

Clone any web UI into your existing stack (React, Vue, plain HTML/CSS, Astro, Svelte, etc.) using whatever sources are available — a screenshot, a live URL, raw HTML, a Figma export, or any combination.

#### Why use `clone-ui` instead of a generic cloner

- **Tier-based fidelity reporting.** The skill is explicit about what it can and can't do — Tier A (live screenshot + DOM tokens), B (static fetch + screenshot), C (user-provided assets), D (memory only). It refuses to fall back to memory silently and pretend the result is faithful.
- **Multi-source support.** Drop a screenshot, paste a URL, give it raw HTML, or any mix. The skill picks the highest-fidelity input you have.
- **Auth-gated UI handling.** Logged-in views (GitHub authenticated chrome, Gmail, dashboards) are flagged honestly as "Tier mixed: tokens A, layout D" instead of being faked from training data.
- **Stack-agnostic.** Auto-detects your project's framework + styling system from `package.json` and matches your conventions. No "now I want this in your stack" rewrites.
- **Companion MCP wired in.** When [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed, the skill captures live screenshots + DOM at multiple viewports automatically.

## Install

Global (recommended — available across all projects):

```bash
npx skills add santowilem/skills --skill clone-ui -g
```

Per-project:

```bash
npx skills add santowilem/skills --skill clone-ui
```

### Optional but strongly recommended: Chrome DevTools MCP

`clone-ui` works without it but produces **dramatically better** results when [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed — it lets the agent take real screenshots of the target page and read computed styles instead of working from training-data memory.

**One-line install** (after installing the skill):

Windows (PowerShell):
```powershell
~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.ps1
```

Mac/Linux:
```bash
~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.sh
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

Restart Claude Code (or your AI assistant) after either method.

## Quick start

After installing, just ask your assistant:

```
clone https://posthog.com/pricing into my next.js project
```

or paste a screenshot:

```
match this design: [screenshot.png]
```

The skill triggers automatically and walks through inventory → gather → plan → implement → verify → polish.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for instructions on adding new skills to this repo.

## License

MIT
