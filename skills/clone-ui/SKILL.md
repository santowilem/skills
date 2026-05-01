---
name: clone-ui
description: Pixel-faithful clone of any web UI into the user's existing stack, using whatever sources are available — a screenshot alone, a live URL, raw HTML/CSS, or any combination. Use this skill whenever the user wants to recreate, match, replicate, or "clone" a design from a screenshot, image, URL, Figma export, or HTML dump. Trigger on phrases like "clone this", "match this design", "build this from screenshot", "recreate this page", "make it look like this", "rebuild this UI", "copy this layout", or any time the user provides a visual reference and asks for a faithful implementation. Do not undertrigger — even if the user just drops a screenshot without explicit phrasing, this skill applies.
---

# clone-ui

Faithful, multi-source web UI cloning. Optimized for **fidelity over speed**: the goal is "looks identical to the source" first, "fits the project conventions" second.

## Fidelity tiers (read this first)

The output quality of this skill scales with the source material available. Be upfront with the user about what tier you're working in:

| Tier | Inputs available | Achievable result |
|---|---|---|
| **A — Full source** | Live screenshot via browser MCP + rendered DOM + computed styles | "close visual match" → "pixel-perfect" possible |
| **B — Static fetch** | WebFetch HTML works (no JS hydration) + screenshot user provided | "close visual match" likely |
| **C — Provided assets** | User-supplied screenshot/HTML, no live access | "close visual match" if assets are good |
| **D — Memory only** | No fetchable source, no screenshot — only training data | **"rough sketch" max** — say so explicitly |

If you land in Tier D, **stop and tell the user before writing code**. A clone built from training data is almost certainly stale (sites change copy/layout often) and the user is better served by capturing a screenshot first. Offer to walk them through `take_screenshot` MCP setup or ask for a manual capture rather than producing low-fidelity output silently.

## Optional but strongly recommended: Chrome DevTools MCP

When [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) is installed and active, you have access to:

- `take_screenshot` — capture the current viewport (use multiple viewports for responsive)
- `take_snapshot` — DOM + accessibility tree (post-hydration, includes JS-rendered content)
- Network/console inspection for sites that need login flow

These tools elevate every clone from Tier B/C to Tier A. **If the user asks you to clone a live URL and these tools are NOT available, mention it once at the start**: "I'd recommend installing chrome-devtools-mcp for higher-fidelity clones — see the skill's setup section. I'll proceed with what's available."

If unsure whether the MCP is available, just try calling `take_screenshot` once early in Phase 2 — if it fails, you know you're in Tier B or below.

### Concurrency: chrome-devtools is single-browser

`chrome-devtools-mcp` runs **one shared Chrome instance per Claude Code session**. If multiple subagents spawn in parallel and each tries to clone a different URL, they will fight over the same browser tab focus — one agent's `navigate_page` / `resize_page` / `new_page` switches the active tab away from a sibling's work, and the sibling's next `take_screenshot` or `evaluate_script` then runs against the wrong page.

Two mitigations, in order of preference:

1. **Use isolated contexts.** When opening a new page, pass `isolatedContext: true` (or the equivalent flag for whichever `new_page`-style call your MCP version supports). Each agent gets its own browser context with its own page list — no cross-contamination.
2. **Serialize runs.** If isolated contexts aren't available or reliable, run sw-clone tasks one at a time. The skill's per-task duration (~3-5 minutes for a real Tier A clone) makes this acceptable for most workflows.

Symptom that you're hitting the focus drift bug: a `take_screenshot` returns the wrong page, or an `evaluate_script` returns DOM from a URL you didn't navigate to. If you see this, recover by calling `new_page` (which auto-selects) and re-navigating.

### Auth-gated UIs (logged-in views)

`chrome-devtools-mcp` launches Chrome with `--isolated` by default — a fresh user-data-dir with no cookies, no extensions, no logged-in sessions. This is great for repeatability, but it means:

**The MCP can only directly observe what a logged-out visitor sees.** If the user asks you to clone a logged-in view (the GitHub authenticated app header, Gmail inbox, Linear's project view, any SaaS dashboard), `take_screenshot` will return either the marketing/landing version of the page or a sign-in prompt — not the target the user wants.

When this happens, be honest about what tier of source material you actually have:

- **Visual tokens** (color palette, typography, font sizes, button styles) usually still match between logged-out and logged-in surfaces of the same product → **Tier A** for tokens.
- **Layout, components, copy** of the logged-in page itself → unobservable → **Tier D** (memory only) for those parts.

Report this honestly in your output as **"Tier mixed: tokens A, layout D"** rather than claiming a uniform tier. The user gets to decide whether mixed-tier output is good enough or whether they want to take a manual screenshot of the logged-in view and provide it as Tier C input.

If the user explicitly opts into observing the logged-in view, two paths forward:

1. Ask them to drop the `--isolated` flag from their `~/.claude/settings.json` chrome-devtools entry and restart Claude Code so the MCP attaches to a Chrome with their existing session cookies. Trade-off: their personal browsing state becomes visible to the agent.
2. Ask them to take a manual screenshot of the logged-in view and provide its file path. The skill operates on that screenshot as a Tier C input.

Don't silently fall back to memory and pretend you observed a logged-in surface. That produces misleading output and erodes user trust in the skill.

## When to use

Trigger this skill whenever the user gives you:
- A screenshot (single or multi-viewport)
- A live URL to clone
- Raw HTML/CSS
- A Figma frame export
- Any combination of the above

…and asks you to build, recreate, match, or implement that UI in their codebase.

## When **not** to use

- The user asks for an *original design* ("design a hero section for X") — that's a creative task, not a clone task.
- The user asks for *code review* of an existing implementation — different skill.
- The user wants only data extraction (e.g. scraping content from HTML) without rebuilding the UI.

---

## The six-phase flow

Cloning quality collapses when phases are skipped. Resist the urge to jump to "write the code" — every skipped phase shows up as visible drift in the final result.

1. **Inventory inputs** — figure out what sources of truth you have
2. **Gather** — fetch / read every available source
3. **Plan** — break the target into components, identify breakpoints + interactive states
4. **Implement** — translate sources into code in the user's stack
5. **Verify** — compare side-by-side, list every drift
6. **Polish** — fix drifts in priority order until parity

---

## Phase 1 — Inventory inputs

List what you have. Each input type has different fidelity:

| Input | Fidelity | Limitations |
|---|---|---|
| **Screenshot** (PNG/JPG) | Visual truth — what user actually sees | No exact color values, no font names, no exact px |
| **Live URL** | Highest — rendered DOM + computed styles | May be auth-gated, may rate-limit, JS-heavy sites need real browser |
| **Raw HTML** (view-source) | Markup truth, but pre-hydration | Missing JS-rendered content, inlined styles only |
| **Rendered HTML** (post-hydration) | DOM truth | Still no computed styles unless captured |
| **Computed styles dump** (JSON / DevTools export) | Style truth — exact px/colors/fonts | Tied to one viewport + state |
| **Figma export** | Design truth — exact tokens | May not match actual rendered site |

If the user only gave one source, **ask if more are available** before starting:

> "I have the screenshot. Do you also have the live URL or raw HTML? Multi-source clones are dramatically more accurate — even view-source HTML helps."

If only a screenshot is available, that's still workable, but flag the lower fidelity ceiling upfront.

---

## Phase 2 — Gather

For each input the user has, pull it into context:

### Screenshot

`Read` the file path. The image is your visual truth — refer back to it constantly.

If multiple viewport screenshots exist (e.g. `screenshot-w375.png`, `screenshot-w1440.png`), open the **largest** first to understand the desktop layout, then each smaller width to map the responsive transitions.

### Live URL

**Preferred path (Tier A): Chrome DevTools MCP.** If `take_screenshot` and `take_snapshot` are available, use them — `take_snapshot` returns post-hydration DOM (handles SPAs cleanly) and `take_screenshot` gives you visual truth. Capture at minimum 1440px (desktop) and 375px (mobile) viewports; add 768px (tablet) if the layout has 3+ breakpoints.

**Fallback path (Tier B): WebFetch.** Grabs markdown-converted content. **WebFetch does NOT render JavaScript** — it gives you the static HTML response only.

For JS-heavy SPAs (React, Vue, Next.js apps), WebFetch will return a near-empty `<div id="root">`. WebFetch may also be denied by some sites' bot detection (Cloudflare, etc.). In either case, the right move is to either:

1. Ask the user to install Chrome DevTools MCP (see Setup section)
2. Ask the user to capture the rendered DOM (via DevTools "Copy outerHTML" on `<body>`) and provide it as raw HTML
3. Ask the user for a screenshot

Do **not** silently fall back to building from training-data memory — that produces Tier D output even when the user thinks they're getting Tier B. Tell them upfront what tier you're operating in.

### Raw HTML

`Read` the file or paste. Look for:
- Class names → likely Tailwind, BEM, CSS modules, or custom
- Inline styles → exact values to honor
- `<link rel="stylesheet">` → fetch those CSSes too if user has them
- `<style>` blocks → inline CSS rules
- Font imports → Google Fonts links, `@font-face` declarations

### Computed styles / context

If the user provides a context dump (JSON, markdown, CSS variable list), `Read` it. These are **gold** — exact values beat eyeballed values every time. Prioritize them as source of truth.

---

## Phase 3 — Plan

Before writing any code, produce these four artifacts (briefly — bullet lists, not essays):

### 3a. Component breakdown

Break the target into logical components. Match the user's project conventions — if they use functional React with hooks, plan that way; if they use Vue SFCs, plan that way.

```
HomePage
├── HeroSection
│   ├── Logo
│   ├── NavMenu
│   └── HeadlineGroup
├── FeatureGrid (3 cards)
└── Footer
```

### 3b. Breakpoint map

Identify breakpoints from screenshots OR CSS (`@media` queries). Common patterns:

| Width | Behavior |
|---|---|
| ≥ 1280px | Desktop: 3-col grid, full nav |
| 768–1279px | Tablet: 2-col grid, condensed nav |
| < 768px | Mobile: 1-col, hamburger menu |

### 3c. Design tokens

Extract or eyedrop:

- **Colors**: primary, secondary, text, bg, border (hex codes — exact)
- **Typography**: font family, weights used, base size, line-height, scale ratio
- **Spacing**: detect the grid (4px? 8px?), list common gaps
- **Radius**: card radius, button radius
- **Shadows**: subtle? prominent? elevation levels

If you have computed styles → use those values verbatim. If only screenshot → use a color picker mentally and round to the closest sensible value (e.g. `#4F46E5` not `#4F47E4`).

### 3d. Interactive states

Even from a single screenshot, infer states from visible cues:

- Buttons usually have `:hover`, `:active`, `:focus`
- Inputs have `:focus`, `:disabled`, `:invalid`
- Cards may have `:hover` lift
- Nav items may have `aria-current` styling

If the user provides a live URL or context dump with `:hover` rules, capture those exactly.

---

## Phase 4 — Implement

### Stack detection

Auto-detect from `package.json`:

```bash
# Use Read on package.json
```

| Detected dependency | Stack |
|---|---|
| `next` | Next.js (App or Pages router — check `app/` vs `pages/`) |
| `react` (no Next) | React + Vite/CRA |
| `vue` | Vue 3 |
| `svelte` | SvelteKit |
| `astro` | Astro |
| (none) | Plain HTML/CSS — write static files |

### Styling detection

| Found | Use |
|---|---|
| `tailwindcss` | Tailwind classes |
| `styled-components` / `emotion` | CSS-in-JS |
| `*.module.css` | CSS Modules |
| `sass` / `*.scss` | Sass |
| (none) | Plain CSS in a `.css` file next to the component |

**Match the user's existing conventions**, don't introduce new ones. If they use Tailwind, don't write inline styles. If they use CSS Modules, don't suggest Tailwind.

### Fidelity rules (non-negotiable)

These are the rules that separate a real clone from a "looks-roughly-similar" approximation:

1. **Exact colors** — read from CSS or eyedrop precisely. Never approximate.
2. **Exact spacing** — measure pixel gaps in the screenshot or read from computed styles. `mt-3` vs `mt-4` is a visible difference.
3. **Exact font** — if Google Fonts, import the same family + weights. If system font stack, match it.
4. **Exact radius** — `rounded-md` (6px) ≠ `rounded-lg` (8px). Be precise.
5. **Exact icons** — if the source uses Lucide, use Lucide. If Heroicons, use Heroicons. Don't substitute.
6. **No invented content** — keep the source's text verbatim unless the user explicitly says to replace it. Lorem ipsum is a code smell here.
7. **Match the layout primitive** — if the source uses CSS Grid, don't reimplement with flexbox + nth-child hacks.

### Anti-patterns (from prior cloning failures)

- ❌ "Close enough" colors — pick a color picker and copy hex
- ❌ Skipping the responsive viewports — always implement all breakpoints, not just desktop
- ❌ Inferring content from context — copy the actual text, don't summarize
- ❌ Using only the static HTML when JS-rendered DOM is available — the JS version is the truth
- ❌ Refactoring "while you're there" — clone first, refactor in a separate pass

---

## Phase 5 — Verify

After implementing, **don't claim done yet.** Verify in two passes:

### Pass A — Visual diff

**Preferred (Tier A): MCP-driven diff loop.** If Chrome DevTools MCP is available and the user has a working dev server (`npm run dev` / `pnpm dev`), use `take_screenshot` against the local URL at each viewport, then compare visually against the source screenshot you captured earlier. This is the closest thing to an automated regression diff.

**Fallback (Tier B+): manual side-by-side.** Open the cloned page in a browser, place it next to the source screenshot, and look for:

- Color drift (your blue vs their blue)
- Spacing drift (4px difference in padding adds up)
- Font weight mismatch (`font-medium` vs `font-semibold` is visible)
- Layout drift (alignment, gap, wrap)
- Missing states (hover doesn't change, focus ring missing)

For **multi-viewport** clones, resize the browser to each breakpoint and verify all of them — not just the one that's currently open. With MCP, this is `take_screenshot` at each width; without, it's manual resize.

### Pass B — Drift list

Produce a written list:

```
Drift detected:
- Hero headline: source 56px, mine 48px → bump font-size
- CTA button: source has 12px shadow blur, mine has 4px → adjust shadow
- Card grid: source has 24px gap, mine has 32px → reduce gap
- Mobile nav: source slides in from right, mine fades → change transition

No drift detected on:
- Color palette
- Typography family
- Footer layout
```

If the list has > 0 items in "drift detected" → loop back to Phase 4 and fix. **Do not declare done with known drifts.**

---

## Phase 6 — Polish

Last 10% — the bits that distinguish "implemented" from "shipped":

- Hover transitions match the source's easing + duration
- Focus rings are visible and accessible
- Touch targets ≥ 44px on mobile
- `prefers-reduced-motion` respects (if source has motion)
- Dark mode handling (if source supports it and user's stack does)
- Image `alt` attributes (don't leave `alt=""` on meaningful imagery)
- `<title>` and meta tags if cloning a full page

---

## Output expectations

When you finish, hand the user:

1. **List of files created/modified** with paths
2. **Drift list from Phase 5** showing what was checked and what's clean
3. **Known limitations** (e.g. "couldn't match the parallax effect — needs a JS library the project doesn't have")
4. **Suggested next steps** if any (e.g. "you may want to extract the button styles into a reusable component once you have 2-3 instances")

Don't claim "pixel-perfect" unless you've actually verified pixel-level parity. "Close visual match" is honest; "pixel-perfect" requires receipts.

---

## Quick reference: tooling map

| Need | Preferred (Tier A) | Fallback (Tier B+) |
|---|---|---|
| Capture live URL | `take_screenshot` + `take_snapshot` (Chrome DevTools MCP) | `WebFetch` (text only) |
| Read user-provided screenshot | `Read` (image rendering) | — |
| Read raw HTML/CSS | `Read` | — |
| Find files in user's project | `Glob` | — |
| Search for existing components/styles | `Grep` | — |
| Run dev server for visual verification | `Bash` (e.g. `pnpm dev`) | — |
| Diff cloned output vs source | `take_screenshot` of local + visual compare | Manual side-by-side in browser |

The Chrome DevTools MCP path is the difference between "looks roughly like the brand" and "matches the live page". When it's not available and the user asks for a live URL clone, surface that limitation early — don't bury it in NOTES.md after the fact.

## Setup: installing Chrome DevTools MCP

If the user asks how to enable the higher-fidelity path, share these steps:

1. Edit `~/.claude/settings.json` (Mac/Linux) or `C:\Users\<name>\.claude\settings.json` (Windows). Add to the `mcpServers` block:

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

2. Restart Claude Code so the MCP server loads.

3. Verify with a probe: ask the agent to call `take_screenshot` against any URL — if it works, you're set.

Or run the bundled setup script: `~/.claude/skills/sw-clone/scripts/install-chrome-devtools-mcp.ps1` (Windows) / `.sh` (Unix). The script appends the config without overwriting existing `mcpServers` entries.
