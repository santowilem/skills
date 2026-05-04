<div align="center">

# clone-ui — Pixel-Perfect Website & UI Cloner for AI Coding Assistants

### Clone any website, screenshot, or Figma design into your stack — without the hallucinations

**One natural-language prompt.** Your AI assistant rebuilds any URL, screenshot, or Figma frame as production-ready code in **React, Vue, Next.js, Astro, Svelte, or plain HTML** — and proves the result is faithful, not invented, through a 5-pass verification flow with an adversarial sub-agent that hunts for visual drift.

[![skills.sh](https://skills.sh/b/santowilem/skills)](https://skills.sh/santowilem/skills/clone-ui) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![SKILL.md Standard](https://img.shields.io/badge/Standard-SKILL.md-blue.svg)](https://github.com/anthropics/skills) [![5+ AI Assistants](https://img.shields.io/badge/AI%20Assistants-5%2B-brightgreen.svg)](#-compatibility) [![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)

**[Install](#-install)** · **[Quick Start](#-quick-start)** · **[Use Cases](#-use-cases)** · **[How it works](#-how-clone-ui-stays-honest)** · **[Compatibility](#-compatibility)**

⭐ **If `clone-ui` saves you hours of pixel-pushing, [star the repo](https://github.com/santowilem/skills)** — it helps other developers discover faithful AI UI cloning instead of fancy autocomplete.

</div>

---

## ⚡ The 30-second pitch — AI website cloning that actually works

You give your AI coding assistant a URL, a screenshot, or a Figma frame. You get back **production-ready code in your existing stack** — React, Vue, Next.js, Astro, Svelte, or plain HTML/CSS/JS — that **matches the source visually** AND **proves it via a five-pass verification flow**, including an adversarial sub-agent that hunts for drift before you ever see the output.

```
You: "clone https://stripe.com/pricing into my Next.js project"
AI:  ✓ Acquired source (12 sections, 0 hallucinations)
     ✓ Implemented (446 lines HTML, 920 lines CSS, 85 lines JS)
     ✓ Verified — 5 passes (sanity, computed-style, visual, adversarial, drift report)
     ✓ Done. 9/9 drifts caught and fixed in iter-1b.
```

No "uhh, looks roughly similar?" results. Either the clone is faithful (with receipts), or `clone-ui` tells you exactly which sections fell short and why. **This is screenshot-to-code, URL-to-code, and Figma-to-code — done honestly.**

---

## ✨ What makes `clone-ui` different from generic AI website cloners

Other "clone this UI with AI" workflows fail in 5 predictable ways. We engineered around all of them.

| Common failure mode | Generic AI cloner | `clone-ui` |
|---|---|---|
| **Inventing content the source doesn't have** | "Looks like there's a hero with 'Welcome to ACME'" — but the source actually says "Hi from $Brand" | **Anti-hallucination contract**: every rendered feature traces to file+line in `_source/`. No evidence → no render. |
| **Self-verification echo chamber** | The same agent that built the clone judges it. Always passes its own review. | **Adversarial Pass D**: spawns a fresh sub-agent with no implementation context, tasked with *finding drifts*, not validating. |
| **Silent regressions on iteration** | "Fix X" → rewrite from scratch → drops correctly-built Y, Z | **Iteration-delta mode**: tags features `keep` vs `fix`, regression-diffs before declaring done. |
| **Style inversions** ("section background is pink → title must be white") | Visual context-inferring | **Computed-style parity (Pass B)**: literal-equality diff `clone.h2.color === source.h2.color`. |
| **Compounding the same mistakes across runs** | Each clone re-learns the same lessons | **Per-target `lessons.md`**: append on drift-found, read on next clone. |

---

## 🎯 Use cases — what you can clone with this skill

`clone-ui` triggers automatically when you describe what you want — no slash-commands, no special syntax. Tested workflows include:

| You want to… | Just say… |
|---|---|
| **Clone a competitor's homepage into Next.js** | `clone https://stripe.com/pricing into my Next.js project` |
| **Convert a screenshot to HTML/CSS** | `match this design: [drag screenshot here]` |
| **Recreate one section from a live website** | `recreate the hero from linear.app in plain HTML` |
| **Migrate a Figma frame to React** | `clone this Figma export into our component library` |
| **Rebuild a static site as an SPA** | `clone the site at /old-site into a Next.js app` |
| **Run a pixel-perfect audit of an existing build** | `audit my clone vs the source` |
| **Re-clone after feedback (iter-N)** | `fix these drifts: ...` (auto-detects iteration-delta mode) |

Whether you're doing **website cloning**, **screenshot-to-code conversion**, **design-to-code translation**, or **pixel-perfect UI replication**, the same skill handles all of them through the same evidence-driven pipeline.

---

## 🚦 Quick start

```bash
# 1. Install the skill (one command)
npx skills add santowilem/skills --skill clone-ui

# 2. Optional but recommended — enable Chrome DevTools MCP for live capture
#    See "Chrome DevTools MCP" section below for the JSON snippet to add to ~/.claude.json

# 3. Restart your AI assistant, then just ask:
"clone https://posthog.com/pricing into my next.js project"
```

That's it. The skill walks the seven-phase clone flow automatically:

```
Acquire → Inventory → Gather → Plan → Implement → Verify (5 gated passes) → Polish
                                                  └── A. Sanity
                                                  └── B. Computed-style parity
                                                  └── C. Per-section visual diff
                                                  └── D. Adversarial sub-agent ← the secret weapon
                                                  └── E. Drift report + lessons
```

---

## 🔌 Compatibility — works across every major AI coding assistant

`clone-ui` ships as a [SKILL.md](https://github.com/anthropics/skills)-standard skill. **SKILL.md is an open specification released by Anthropic in 2025 and adopted by OpenAI for Codex CLI and ChatGPT** — meaning every skill in this repo works across the entire AI coding assistant ecosystem, not locked to a single tool.

| Platform | Status | Notes |
|---|---|---|
| **[Claude Code](https://claude.com/claude-code)** | ✅ Native | Anthropic's official CLI for AI coding; first-class support |
| **[Cursor](https://cursor.com)** | ✅ Native | SKILL.md import auto-discovers in `~/.cursor/skills/` |
| **[OpenAI Codex CLI](https://github.com/openai/codex)** | ✅ Native | Drop into `~/.codex/skills/` |
| **[ChatGPT](https://chatgpt.com)** | ✅ via Skills API | Upload SKILL.md as a project skill |
| **[GitHub Copilot Workspace](https://githubnext.com/projects/copilot-workspace)** | ✅ via registry | Reference the repo URL |
| **[Aider](https://aider.chat)**, **[Continue](https://continue.dev)**, others | ⚠️ Manual | Pipe SKILL.md verbatim into context |

---

## 🧪 How `clone-ui` stays honest — three structural guarantees against AI hallucinations

Most "clone this UI with AI" flows are fancy autocomplete — they generate plausible-looking code that may or may not match the source. `clone-ui` enforces three structural guarantees that block hallucinations at the architecture level, not the prompt level:

### 1. Tier-based fidelity reporting (no silent fallbacks)

Every clone is classified by what sources were actually available, and the tier is reported back to you upfront:

- **Tier A** — live URL + Chrome DevTools MCP screenshots + computed styles → "pixel-perfect" possible
- **Tier B** — static HTML + screenshot → "close visual match" likely
- **Tier C** — user-provided assets only → workable if the assets are good
- **Tier D** — memory only → **the skill stops and asks for a screenshot first** rather than producing low-fidelity output silently

Mixed tiers — e.g. "tokens A, layout D" for auth-gated dashboards — are reported honestly, never hidden.

### 2. Section-evidence contract — every rendered feature must trace to source

Before any code is written, Phase 3 produces `section-evidence.json`:

```json
{
  "header": [
    { "feature": "transparent gradient bg", "evidence": "_source/nav-states.json: initial.backgroundImage" },
    { "feature": "phone CTA right side",    "evidence": "_source/raw.html: line 1247" }
  ]
}
```

Phase 4 implementation cannot render a feature without an evidence row. Negative evidence (`"feature": "no scroll-triggered solid state"`) protects against features the source explicitly *does not* have — preventing the agent from inventing modern-looking interactions that aren't in the original design.

### 3. Adversarial sub-agent (Pass D) — fresh eyes, no echo chamber

After self-verification passes, a **fresh sub-agent** is spawned with zero implementation context. It only sees `_source/` and the final output, and its prompt is: "find at least 5 drifts." This breaks the self-audit echo chamber that makes most AI cloners pass their own reviews trivially. In real-world testing, Pass D routinely finds 5–8 hallucinations the original implementer was structurally blind to: invented brand wordmarks, fabricated copy, wrong column counts, missing pseudo-elements, fake link destinations.

---

## 📦 Install

```bash
npx skills add santowilem/skills --skill clone-ui
```

### Optional but strongly recommended: Chrome DevTools MCP

`clone-ui` works without it but produces **dramatically better** results when [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed — it gives the agent real screenshots of the target page and lets it read computed styles directly, instead of working from training-data memory. This is what powers the per-section visual diff loop in Phase 0 and the programmatic computed-style parity check in Pass B.

**Install manually** by adding the entry below to your Claude Code config at `~/.claude.json` (under `mcpServers`):

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

> **Why no install script?** This skill never writes to your MCP/settings files. Configuration changes are explicit — copy the snippet, paste it, save. See the [Security & threat model](./SKILL.md#security--threat-model-read-this-before-phase-1) section in `SKILL.md` for the full rationale.

Restart Claude Code (or your AI assistant) after editing the file.

**Security tip:** chrome-devtools-mcp launches Chrome with `--isolated` by default — a fresh user-data-dir with no cookies, no extensions, no logged-in sessions. **Keep that flag.** Do not drop it to clone authenticated views — that would expose your real browser state (cookies, sessions, autofill, internal URLs) to the agent and to any cloned output that ends up on disk in `_source/` or `_mirror/`. For logged-in surfaces, take a manual screenshot and provide the file path instead.

### Recommended permission rules — kill the prompt fatigue

Phase 2 of `clone-ui` saves 10–15 JSON capture artifacts to disk per clone (`section-styles.json`, `nav-states.json`, `pseudo-elements.json`, etc). Each save runs a small command, and Claude Code's default permission model prompts you for every one of them. To approve the helper-script pattern **once** instead of per-save, add this to your `~/.claude/settings.json` under `permissions.allow`:

```json
{
  "permissions": {
    "allow": [
      "PowerShell(pwsh*save-tool-result.ps1*)",
      "Bash(python*save-tool-result.py*)"
    ]
  }
}
```

Why this is safe to allow:

- The helper script (`save-tool-result.ps1` / `save-tool-result.py`) only reads the path passed via `-src` / `--src` and only writes the path passed via `-out` / `--out`. It does **not** mutate any user, agent, or IDE configuration, and makes no network calls.
- The pattern matches only the bundled helper — arbitrary PowerShell/Python invocations still prompt for review.

Source: [`scripts/save-tool-result.ps1`](./scripts/save-tool-result.ps1) · [`scripts/save-tool-result.py`](./scripts/save-tool-result.py)

---

## 🤝 Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) at the repo root for instructions on adding new skills.

If you've used `clone-ui` and shipped something cool, open an issue with `[showcase]` in the title — happy to feature real-world clones.

---

## 🔍 Keywords

For discoverability — these are the terms developers search when looking for what `clone-ui` does:

`claude-skills` `claude-code` `cursor-skills` `codex-cli` `chatgpt-skills` `copilot-skills` `agent-skills` `skill-md` `clone-ui` `clone-website` `web-clone` `ai-website-cloner` `screenshot-to-code` `figma-to-code` `design-to-code` `url-to-code` `pixel-perfect-clone` `pixel-perfect-ui` `ai-coding` `ai-cloner` `ai-frontend` `frontend-automation` `anthropic` `openai` `mcp` `chrome-devtools-mcp` `model-context-protocol`

---

## 📜 License

[MIT](../../LICENSE) — use it, fork it, ship it. If `clone-ui` ends up in your product, a star on the repo helps other developers find it.

<div align="center">

⭐ **[Star on GitHub](https://github.com/santowilem/skills)** — it's free and it actually matters for visibility.

Distributed via [skills.sh](https://skills.sh/santowilem/skills/clone-ui)

</div>
