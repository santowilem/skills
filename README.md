<div align="center">

# 🎨 SKILL.md Skills for Claude Code, Cursor, Codex CLI & Every AI Coding Assistant

### A curated collection of open-spec [SKILL.md](https://github.com/anthropics/skills) skills — install once, work across every major AI coding tool

[![skills.sh](https://skills.sh/b/santowilem/skills)](https://skills.sh/santowilem/skills) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![SKILL.md Standard](https://img.shields.io/badge/Standard-SKILL.md-blue.svg)](https://github.com/anthropics/skills) [![5+ AI Assistants](https://img.shields.io/badge/AI%20Assistants-5%2B-brightgreen.svg)](#-compatibility) [![Made for Claude Code](https://img.shields.io/badge/Made%20for-Claude%20Code-orange.svg)](https://claude.com/claude-code)

⭐ **[Star this repo](https://github.com/santowilem/skills)** — it helps other developers discover faithful, evidence-driven AI skills instead of fancy autocomplete.

</div>

---

## What's in here

A personal collection of [SKILL.md](https://github.com/anthropics/skills)-standard **agent skills for AI coding assistants** — Claude Code, Cursor, OpenAI Codex CLI, ChatGPT, GitHub Copilot, Aider, and any other tool that supports the open SKILL.md specification.

Each skill lives in its own folder under [`skills/`](./skills/) with two files:

- **`SKILL.md`** — the agent-facing spec (frontmatter + instructions the AI reads)
- **`README.md`** — the human-facing detail page (what it does, how to install, examples)

---

## 📚 Available skills

| Skill | What it does | Detail |
|---|---|---|
| **[`clone-ui`](./skills/clone-ui/)** | **Pixel-faithful website & UI cloning from URL, screenshot, or Figma frame** — anti-hallucination 7-phase flow with adversarial sub-agent verification, computed-style parity checks, and per-target lessons log. Outputs production-ready code in your stack (React, Vue, Next.js, Astro, Svelte, plain HTML). | [README](./skills/clone-ui/README.md) · [SKILL.md](./skills/clone-ui/SKILL.md) |

> More skills are on the way. Each one ships independently — install just the ones you need.

---

## 📦 Install — one command per skill

Skills are installed individually using the [skills.sh CLI](https://skills.sh):

```bash
npx skills add santowilem/skills --skill <skill-name>
```

For example, to install `clone-ui`:

```bash
npx skills add santowilem/skills --skill clone-ui
```

After installation, restart your AI assistant. The skill triggers automatically based on natural-language prompts — no slash commands required. See each skill's README for trigger phrases and examples.

---

## 🔌 Compatibility — works across every major AI coding assistant

All skills in this repo follow the [SKILL.md open specification](https://github.com/anthropics/skills) — released by Anthropic in 2025 and adopted by OpenAI for Codex CLI and ChatGPT. **One skill file works everywhere:**

| Platform | Status | Install path |
|---|---|---|
| **[Claude Code](https://claude.com/claude-code)** | ✅ Native | `~/.claude/skills/` |
| **[Cursor](https://cursor.com)** | ✅ Native | `~/.cursor/skills/` |
| **[OpenAI Codex CLI](https://github.com/openai/codex)** | ✅ Native | `~/.codex/skills/` |
| **[ChatGPT](https://chatgpt.com)** | ✅ via Skills API | Upload SKILL.md as a project skill |
| **[GitHub Copilot Workspace](https://githubnext.com/projects/copilot-workspace)** | ✅ via registry | Reference the repo URL |
| **[Aider](https://aider.chat)**, **[Continue](https://continue.dev)**, others | ⚠️ Manual | Pipe SKILL.md verbatim into context |

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for instructions on adding a new skill to this repo. Pull requests welcome — especially for skills that cover under-served workflows (component extraction, design-system ingestion, accessibility audits, visual regression, etc.).

---

## 🔍 Keywords

For discoverability — these are the terms developers search when looking for skills like these:

`claude-skills` `claude-code-skills` `cursor-skills` `codex-cli-skills` `chatgpt-skills` `copilot-skills` `agent-skills` `ai-agent-skills` `skill-md` `skill-md-spec` `anthropic-skills` `openai-skills` `ai-coding` `ai-coding-assistant` `mcp` `model-context-protocol` `chrome-devtools-mcp` `clone-ui` `screenshot-to-code` `figma-to-code` `design-to-code` `url-to-code` `pixel-perfect-clone` `web-clone` `ai-frontend` `frontend-automation`

---

## 📜 License

[MIT](./LICENSE) — use it, fork it, ship it. If a skill ends up in your product, a star on the repo helps other developers find it.

<div align="center">

⭐ **[Star on GitHub](https://github.com/santowilem/skills)** — free, fast, and genuinely useful for visibility.

Distributed via [skills.sh](https://skills.sh/santowilem/skills)

</div>
