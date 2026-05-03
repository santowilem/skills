# santowilem/skills

Reusable agent skills for Claude Code, Cursor, and other AI coding assistants. Distributed via the [skills.sh](https://skills.sh) CLI.

## Skills

### [`clone-ui`](./skills/clone-ui/) — pixel-faithful web UI cloning

Clone any web UI into your existing stack (React, Vue, plain HTML/CSS, Astro, Svelte, etc.) using whatever sources are available — a screenshot, a live URL, raw HTML, a Figma export, or any combination.

#### Why use `clone-ui` instead of a generic cloner

- **Tier-based fidelity reporting.** The skill is explicit about what it can and can't do — Tier A (live screenshot + DOM tokens), B (static fetch + screenshot), C (user-provided assets), D (memory only). It refuses to fall back to memory silently and pretend the result is faithful.
- **Multi-source support.** Drop a screenshot, paste a URL, give it raw HTML, or any mix. The skill picks the highest-fidelity input you have.
- **Anti-hallucination contract.** Every rendered feature must trace to a file+line in `_source/` via a `section-evidence.json` artifact. If the agent can't cite "where in source is this?", the feature does not get rendered. Negative-evidence entries protect against features the source explicitly *doesn't* have (e.g. "no scroll-triggered solid header state").
- **Adversarial verification.** Phase 5 includes a Pass D where a fresh sub-agent — with no implementation context — is tasked with *finding drifts*, not validating. This breaks the implementer-as-own-auditor echo chamber that lets hallucinations slip past self-review.
- **Iteration-delta mode.** When a `outputs-iterN-1-archive/` exists, the skill enters fix-up mode: tag every prior feature `keep` or `fix`, touch only `fix` items, regression-diff before declaring done. Catches the silent-regression class ("user said remove X, but X is still wired in JS").
- **Compounding lessons per target.** The skill writes a `{workspace}/lessons.md` after every iteration. Phase 0 reads it before the next clone of the same target. Each iteration makes the next iteration sharper without an SKILL.md edit.
- **Auth-gated UI handling.** Logged-in views (GitHub authenticated chrome, Gmail, dashboards) are flagged honestly as "Tier mixed: tokens A, layout D" instead of being faked from training data.
- **Stack-agnostic.** Auto-detects your project's framework + styling system from `package.json` and matches your conventions. No "now I want this in your stack" rewrites.
- **Companion MCP wired in.** When [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed, the skill captures live screenshots + DOM at multiple viewports automatically and runs Pass B (programmatic computed-style parity diff) against your clone.

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

The skill triggers automatically and walks through a **seven-phase flow**: acquire sources → inventory inputs → gather → plan (tokens, assets, embeds, section-map, **section-evidence**) → implement → **verify (five gated passes: sanity → computed-style parity → per-section visual diff → adversarial sub-agent → drift report + lessons append)** → polish.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for instructions on adding new skills to this repo.

## License

MIT
