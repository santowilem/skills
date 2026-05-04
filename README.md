<div align="center">

# 🎨 santowilem/skills

### Pixel-faithful UI cloning for AI coding assistants — without the hallucinations

**One natural-language prompt.** Your AI rebuilds any website, screenshot, or Figma design in your stack — and proves the result is faithful, not invented.

[![skills.sh](https://skills.sh/b/santowilem/skills)](https://skills.sh/santowilem/skills) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![SKILL.md Standard](https://img.shields.io/badge/Standard-SKILL.md-blue.svg)](https://github.com/anthropics/skills) [![5+ AI Assistants](https://img.shields.io/badge/AI%20Assistants-5%2B-brightgreen.svg)](#-compatibility) [![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)

**[Install](#-install)** · **[Quick Start](#-quick-start)** · **[Use Cases](#-use-cases)** · **[How it works](#-how-clone-ui-stays-honest)** · **[Compatibility](#-compatibility)**

⭐ **If this saves you hours of pixel-pushing, [star the repo](https://github.com/santowilem/skills) — it helps other devs find it.**

</div>

---

## ⚡ The 30-second pitch

You give your AI assistant a URL, a screenshot, or a Figma frame. You get back **production-ready code in your stack** — React, Vue, Next.js, Astro, Svelte, plain HTML — that **matches the source visually** AND **proves it via a 5-pass verification flow**, including an adversarial sub-agent that hunts for drift.

```
You: "clone https://stripe.com/pricing into my Next.js project"
AI:  ✓ Acquired source (12 sections, 0 hallucinations)
     ✓ Implemented (446 lines HTML, 920 lines CSS, 85 lines JS)
     ✓ Verified — 5 passes (sanity, computed-style, visual, adversarial, drift report)
     ✓ Done. 9/9 drifts caught and fixed in iter-1b.
```

No "uhh, looks roughly similar?" results. Either the clone is faithful (with receipts), or the skill tells you exactly which sections fell short and why.

---

## 🚀 Skills

### [`clone-ui`](./skills/clone-ui/) — pixel-faithful web UI cloning

The flagship skill. ~1200 lines of carefully-tuned playbook covering every common failure mode in AI-driven UI cloning. Battle-tested across complex SPAs (Resend, mclaws.com.au) with multi-iteration validation.

---

## ✨ What makes `clone-ui` different

Other "clone this UI" workflows fail in 5 predictable ways. We engineered around all of them.

| Common failure mode | Generic AI cloner | `clone-ui` |
|---|---|---|
| Inventing content the source doesn't have | "Looks like there's a hero with 'Welcome to ACME'" — but source actually has "Hi from $Brand" | **Anti-hallucination contract**: every rendered feature traces to file+line in `_source/`. No evidence → no render |
| Self-verification echo chamber | Same agent that built it judges it. Always passes its own review. | **Adversarial Pass D**: spawns fresh sub-agent with no implementation context, tasked with *finding drifts*, not validating |
| Silent regressions on iteration | "Fix X" → rewrite from scratch → drops correctly-built Y, Z | **Iteration-delta mode**: tags features `keep` vs `fix`, regression-diffs before declaring done |
| Style inversions ("section bg is pink → title must be white") | Visual context-inferring | **Computed-style parity (Pass B)**: literal-equality diff `clone.h2.color === source.h2.color` |
| Compounding the same mistakes across runs | Each clone re-learns the same lessons | **Per-target `lessons.md`**: append on drift-found, read on next clone |

---

## 🎯 Use cases

`clone-ui` triggers automatically — just describe what you want. Tested workflows:

| You want to… | Just say… |
|---|---|
| **Clone a competitor's homepage** | `clone https://stripe.com/pricing into my Next.js project` |
| **Turn a screenshot into HTML** | `match this design: [drag screenshot here]` |
| **Recreate one section from a live site** | `recreate the hero from linear.app in plain HTML` |
| **Migrate a Figma frame to React** | `clone this Figma export into our component library` |
| **Rebuild a static site as an SPA** | `clone the site at /old-site into a Next.js app` |
| **Run a pixel-perfect audit** | `audit my clone vs the source` |
| **Re-clone after feedback (iter-N)** | `fix these drifts: ...` (auto-detects iteration-delta mode) |

---

## 🚦 Quick start

```bash
# 1. Install the skill
npx skills add santowilem/skills --skill clone-ui

# 2. Optional but recommended — install Chrome DevTools MCP for live capture
~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.sh   # macOS/Linux
~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.ps1  # Windows

# 3. Restart your AI assistant, then just ask:
"clone https://posthog.com/pricing into my next.js project"
```

That's it. The skill walks the seven-phase flow automatically:

```
Acquire → Inventory → Gather → Plan → Implement → Verify (5 gated passes) → Polish
                                                  └── A. Sanity
                                                  └── B. Computed-style parity
                                                  └── C. Per-section visual diff
                                                  └── D. Adversarial sub-agent ← the secret weapon
                                                  └── E. Drift report + lessons
```

---

## 🔌 Compatibility

`clone-ui` ships as a [SKILL.md](https://github.com/anthropics/skills)-standard skill. **SKILL.md is an open spec released by Anthropic in 2025 and adopted by OpenAI for Codex CLI/ChatGPT** — meaning every skill in this repo works across the entire AI-assistant ecosystem, not just one tool.

| Platform | Status | Notes |
|---|---|---|
| **[Claude Code](https://claude.com/claude-code)** | ✅ Native | Anthropic's official CLI; first-class support |
| **[Cursor](https://cursor.com)** | ✅ Native | SKILL.md import auto-discovers in `~/.cursor/skills/` |
| **[OpenAI Codex CLI](https://github.com/openai/codex)** | ✅ Native | Drop into `~/.codex/skills/` |
| **[ChatGPT](https://chatgpt.com)** | ✅ via Skills API | Upload SKILL.md as a project skill |
| **[GitHub Copilot Workspace](https://githubnext.com/projects/copilot-workspace)** | ✅ via registry | Reference the repo URL |
| **[Aider](https://aider.chat)**, **[Continue](https://continue.dev)**, others | ⚠️ Manual | Pipe SKILL.md verbatim into context |

---

## 🧪 How `clone-ui` stays honest

Most "clone this UI" flows are fancy autocomplete — they generate plausible-looking code that may or may not match the source. `clone-ui` enforces three structural guarantees:

### 1. Tier-based fidelity reporting (no silent fallbacks)

Every clone is classified by what sources were actually available:

- **Tier A** — live URL + screenshots + computed styles → "pixel-perfect" possible
- **Tier B** — static HTML + screenshot → "close visual match" likely
- **Tier C** — user-provided assets only → workable if assets are good
- **Tier D** — memory only → **the skill stops and asks for a screenshot first** rather than producing low-fidelity output silently

Mixed tiers ("tokens A, layout D" for auth-gated views) are reported honestly, not hidden.

### 2. Section-evidence contract

Before any code is written, Phase 3 produces `section-evidence.json`:

```json
{
  "header": [
    { "feature": "transparent gradient bg", "evidence": "_source/nav-states.json: initial.backgroundImage" },
    { "feature": "phone CTA right side",    "evidence": "_source/raw.html: line 1247" }
  ]
}
```

Phase 4 cannot render a feature without an evidence row. Negative evidence (`"feature": "no scroll-triggered solid state"`) protects against features the source explicitly *doesn't* have.

### 3. Adversarial sub-agent (Pass D)

After self-verification passes, a **fresh sub-agent** is spawned with no implementation context. It only sees `_source/` and the final output, and its prompt is: "find at least 5 drifts." This breaks the self-audit echo chamber. Real-world example: in the latest test, Pass D found 6 hallucinations the original implementer was structurally blind to (invented brand wordmarks, fabricated code snippets, wrong column count).

---

## 📦 Install

```bash
npx skills add santowilem/skills --skill clone-ui
```

### Optional but strongly recommended: Chrome DevTools MCP

`clone-ui` works without it but produces **dramatically better** results when [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed — it lets the agent take real screenshots of the target page and read computed styles instead of working from training-data memory. This is what powers the per-section visual diff loop in Phase 0 and the programmatic computed-style parity check in Pass B.

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

---

## 🗺️ What's coming

- [ ] More skills beyond `clone-ui` (component-extract, design-system-builder)
- [ ] Showcase gallery: real before/after diffs from production projects
- [ ] Per-framework presets (Tailwind v4, shadcn/ui, Material-UI, Chakra)
- [ ] Visual regression CI integration

Open to ideas — file an issue or PR.

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for instructions on adding new skills to this repo.

If you've used `clone-ui` and shipped something cool, open an issue with `[showcase]` in the title — happy to feature real-world clones in the README.

---

## 🔍 Keywords

For discoverability — these are the terms developers search when looking for what this skill does:

`claude-skills` `claude-code` `cursor-skills` `codex-cli` `chatgpt-skills` `copilot-skills` `agent-skills` `skill-md` `clone-ui` `clone-website` `web-clone` `screenshot-to-code` `figma-to-code` `design-to-code` `pixel-perfect-clone` `ai-coding` `ai-cloner` `anthropic` `openai` `mcp` `chrome-devtools-mcp`

---

## 📜 License

[MIT](./LICENSE) — use it, fork it, ship it. If it ends up in your product, a star helps other devs find it.

<div align="center">

⭐ **[Star on GitHub](https://github.com/santowilem/skills)** — it's free and it actually matters for visibility.

Built by [@santowilem](https://github.com/santowilem) · Distributed via [skills.sh](https://skills.sh)

</div>
