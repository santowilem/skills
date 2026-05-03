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
2. **Serialize runs.** If isolated contexts aren't available or reliable, run clone-ui tasks one at a time. The skill's per-task duration (~3-5 minutes for a real Tier A clone) makes this acceptable for most workflows.

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

## Lessons log (read first, append last)

This skill keeps a per-workspace `lessons.md` next to the clone outputs (sibling of `outputs/`, `_source/`, `_assets/`). It accumulates concrete failure patterns the skill previously got wrong **for this specific clone target**.

Why per-workspace and not global: different sites have different gotchas. Mclaws's "section-pink-bg-but-black-heading" lesson doesn't generalize; Linear's "gradient-blob-positions" lesson doesn't either. Lessons compound *within* a clone target across iterations.

**Phase 0 starts by reading `{workspace}/lessons.md`** if it exists. For each lesson, pattern-match the smell against the current source — if it applies, apply the named mitigation explicitly during planning/implementation.

**Phase 5 ends by appending lessons.** Whenever the verification loop surfaces a drift, write a paragraph entry in this format:

```markdown
## YYYY-MM-DD — short title

**Smell**: pattern that triggers this drift (what to look for in source)
**Failure**: what the agent typically renders
**Truth**: what source actually has
**Mitigation**: concrete check to apply next iteration
```

Don't duplicate existing entries — refine or extend if similar. The file is plain markdown, append-only, kept under ~300 lines (consolidate older lessons if it grows).

This is how the skill compounds for a given clone target: each iteration makes the next iteration more accurate without an SKILL.md edit.

---

## The seven-phase flow

Cloning quality collapses when phases are skipped. Resist the urge to jump to "write the code" — every skipped phase shows up as visible drift in the final result.

0. **Acquire sources** — pull raw HTML, rendered DOM, screenshots, CSS overview into a `_source/` folder before anything else
1. **Inventory inputs** — figure out what sources of truth you have, including embeds and interaction patterns
2. **Gather** — fetch / read every available source, download assets locally, capture pseudo-element styles
3. **Plan** — produce `tokens.json`, `assets.json`, `embeds.json`, `section-map.json`
4. **Implement** — translate artifacts into code in the user's stack, using local assets and verbatim embed scripts
5. **Verify (five gated passes)** — sanity → computed-style parity → per-section visual diff → adversarial sub-agent review → drift report + lessons append
6. **Polish** — final touches across the page

---

## Phase 0 — Acquire sources

Before any analysis, dump everything you'll need into a `_source/` folder next to your output. This separates "raw evidence from the source page" from "your derived artifacts and code." If something later goes wrong, you can re-read the raw evidence without re-fetching.

### What to capture

For a live URL via Chrome DevTools MCP:

```
_source/
├── raw.html              # WebFetch response — the server's HTML, pre-JavaScript
├── rendered.html         # evaluate_script: document.documentElement.outerHTML — post-hydration DOM
├── css-overview.json     # palette + fonts + breakpoints + selectors used (Show CSS Overview equivalent)
├── section-map.json      # [{ name, selector, type }, ...]  — your section breakdown
├── section-styles.json   # computed styles dumped PER SECTION (heading color, button bg, container width, etc.)
├── nav-states.json       # nav at scroll=0 vs scrolled — captures transparent→solid transitions
├── hover-states.json     # screenshots/computed-style of nav items + submenus on hover
└── .captures/
    ├── source-1440-fullpage.png       # whole page at desktop
    ├── source-1440-viewport.png       # initial viewport at desktop
    ├── source-768.png                 # tablet viewport
    ├── source-375.png                 # mobile viewport
    └── sections/
        ├── source-hero.png            # per-section viewport screenshots (the secret weapon)
        ├── source-features.png
        ├── source-testimonials.png
        └── source-footer.png
```

### Per-section screenshot loop (don't skip)

Whole-page screenshots are great for "does the section order match" but useless for "does this card's badge sit in the right place." For every section in `section-map.json`, scroll to it and take a viewport-cropped screenshot. This pays off at Pass C (visual diff) when you compare clone-section vs source-section instead of squinting at 12000px-tall full-page strips.

```js
// In chrome-devtools MCP — per section in section-map.json
for (const section of SECTION_MAP) {
  const el = document.querySelector(section.sourceSelector);
  if (!el) continue;
  const top = el.getBoundingClientRect().top + window.scrollY - 60; // -60 to clear sticky header
  window.scrollTo({ top, behavior: 'instant' });
  // wait 200-400ms for any scroll-triggered animation/lazy-load to settle
  // then chrome-devtools-mcp: take_screenshot, save as source-{section.name}.png
}
```

Run this once for desktop (1440), once for mobile (375). The output is `_source/.captures/sections/source-{name}-{width}.png` for every section × every viewport.

**Why this matters**: at Phase 5 Pass C, you're already crop-comparing per section. Without these source crops you have to rerun chrome-devtools-mcp during verification to capture them. Doing it once in Phase 0 means Pass C reads from disk → 60+ screenshot round-trips avoided.

This is the same workflow Google's Antigravity browser-agent does automatically ("scroll 800px, screenshot, scroll 800px, screenshot, …") — chrome-devtools-mcp gives you the same primitive, just be explicit about using it.

### Why both `raw.html` and `rendered.html`

These are not the same page — they tell you different things:

| Source | Captures | Use it to detect |
|---|---|---|
| `raw.html` (WebFetch) | What the server sent before any JavaScript ran | **Embed scripts** (`<script src="...senja...">`, `<script src="...elfsight...">`), original `<iframe>` declarations, `<noscript>` content, structured data, real source `<link>` tags for fonts/CSS |
| `rendered.html` (evaluate_script outerHTML) | What the user actually sees after hydration | Final layout, JS-injected content, expanded widget contents, computed class lists |

A clone that only reads `rendered.html` will see the **expanded** Senja review widget (8 review cards in DOM) and try to rebuild it as 8 custom-styled cards — when in reality `raw.html` shows the widget is two lines of script. Always check both.

### Capturing them

```js
// In chrome-devtools MCP via evaluate_script
({
  rendered: document.documentElement.outerHTML,
})
```

Then via WebFetch (or Bash + curl as fallback):

```
WebFetch(url, "Return the raw HTML response, do not summarize")
```

Save both to `_source/raw.html` and `_source/rendered.html`.

### CSS overview

Run an `evaluate_script` payload that approximates Chrome DevTools' "Show CSS Overview" panel — gather every distinct color, font, and media query the page uses. This becomes the upstream input for Phase 3's `tokens.json`.

```js
({
  colors: [...new Set(
    [...document.querySelectorAll('*')].flatMap(el => {
      const s = getComputedStyle(el);
      return [s.color, s.backgroundColor, s.borderColor].filter(c => c && c !== 'rgba(0, 0, 0, 0)');
    })
  )].slice(0, 200),
  fonts: [...new Set(
    [...document.querySelectorAll('*')].map(el => getComputedStyle(el).fontFamily)
  )],
  mediaQueries: [...document.styleSheets].flatMap(s => {
    try { return [...s.cssRules].filter(r => r.type === CSSRule.MEDIA_RULE).map(r => r.conditionText); }
    catch { return []; }  // cross-origin sheets throw
  }),
})
```

### Section map

Walk the page top-to-bottom and produce a list of major sections with their CSS selectors:

```json
[
  { "name": "header",          "selector": "header.site-header",      "type": "navigation" },
  { "name": "hero",             "selector": "section.hero",            "type": "hero" },
  { "name": "find-property",    "selector": "section.find-property",   "type": "search-and-grid" },
  { "name": "living-partner",   "selector": "section.living-partner",  "type": "cta-band" },
  { "name": "why-us",           "selector": "section.why-us",          "type": "feature-grid" },
  { "name": "testimonials",     "selector": "section.testimonials",    "type": "embed-widget" },
  { "name": "achievements",     "selector": "section.achievements",    "type": "stat-counter" },
  { "name": "recent-news",      "selector": "section.recent-news",     "type": "news-grid" },
  { "name": "free-appraisal",   "selector": "section.free-appraisal",  "type": "form" },
  { "name": "footer",           "selector": "footer.site-footer",      "type": "footer" }
]
```

This is your contract for Phase 5 — every section here gets independently verified.

### Computed style dump per section (the anti-guesswork file)

The single biggest source of "looks similar but colors/sizes are off" drift is the agent **inferring** colors and sizes from visual context ("the section has a pink bg, so the title must be white"). The fix is to dump computed styles for every meaningful element in every section, then read from the file in Phase 4 — never guess.

For each section in `section-map.json`, run an `evaluate_script` like this and save the merged result to `_source/section-styles.json`:

```js
// Run for each section; keys = section.name
const result = {};
for (const section of SECTION_MAP) {
  const root = document.querySelector(section.selector);
  if (!root) continue;
  const pick = (el) => {
    if (!el) return null;
    const cs = getComputedStyle(el);
    return {
      color: cs.color,
      backgroundColor: cs.backgroundColor,
      backgroundImage: cs.backgroundImage,
      backgroundPosition: cs.backgroundPosition,
      fontSize: cs.fontSize,
      fontWeight: cs.fontWeight,
      fontFamily: cs.fontFamily,
      lineHeight: cs.lineHeight,
      padding: cs.padding,
      borderRadius: cs.borderRadius,
      border: cs.border,
      width: el.getBoundingClientRect().width,
    };
  };
  result[section.name] = {
    container: pick(root),
    contentWidth: root.querySelector('.container, .e-con-inner, .elementor-container, [class*="container"]')?.getBoundingClientRect().width,
    headings: [...root.querySelectorAll('h1,h2,h3,h4')].map(h => ({ text: h.innerText.trim().slice(0, 80), ...pick(h) })),
    buttons: [...root.querySelectorAll('a.btn, button, .elementor-button, [class*="cta"]')].map(b => ({ text: b.innerText.trim(), ...pick(b) })),
    images: [...root.querySelectorAll('img')].map(img => ({ src: img.src, alt: img.alt, width: img.naturalWidth, height: img.naturalHeight })),
  };
}
result;
```

In Phase 4, when implementing each section, **open `section-styles.json` and copy values verbatim**. Title color of "Mclaws Property" is whatever `section-styles.json["living-partner"].headings[0].color` says — not what looks right against the pink background.

### Scroll-state and hover-state captures

A static screenshot only shows initial state. Real pages morph — nav goes from transparent to solid on scroll, submenus reveal carets on hover, sticky headers gain shadow. Capture these explicitly:

```js
// nav-states.json — initial vs scrolled
const nav = document.querySelector('header, .site-header, nav');
const initial = getComputedStyle(nav);
const initialState = { backgroundColor: initial.backgroundColor, backgroundImage: initial.backgroundImage, boxShadow: initial.boxShadow, color: initial.color };
window.scrollTo(0, 400);
await new Promise(r => setTimeout(r, 300));
const scrolled = getComputedStyle(nav);
({ initial: initialState, scrolled: { backgroundColor: scrolled.backgroundColor, backgroundImage: scrolled.backgroundImage, boxShadow: scrolled.boxShadow, color: scrolled.color } })
```

Pair with `take_screenshot` before and after scroll. Save both PNGs in `_source/.captures/nav-initial.png` and `_source/.captures/nav-scrolled.png`.

For hover states on nav items with dropdowns, dispatch a `mouseenter` event and re-capture:

```js
const item = document.querySelector('header nav li:has(.sub-menu), header nav .menu-item-has-children');
item.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
await new Promise(r => setTimeout(r, 200));
// then take_screenshot to see the open dropdown
```

If these states aren't captured, the clone will ship a permanently-solid nav with no dropdown carets.

### Don't skip Phase 0

When the agent jumps to "implement" without producing these files, missing details cascade through every later phase. The 5 minutes spent on Phase 0 saves multiple iterations later.

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

### Embed detection — read `_source/raw.html` first

Many sites use third-party widgets (review platforms, calendar pickers, social feeds, video players) that show up in `rendered.html` as fully-expanded DOM but in `raw.html` as a tiny embed script. **A clone that re-implements them from the rendered DOM is wrong twice over** — wrong content (placeholders or hallucinated reviews), and wrong update mechanism (won't reflect new content from the platform).

Read `_source/raw.html` and grep for these patterns. If found, **inject them verbatim** in Phase 4 instead of rebuilding:

| Pattern in raw.html | Vendor / type | What to do |
|---|---|---|
| `widget.senja.io` / `<div class="senja-embed">` | Senja reviews | Inject the `<script>` + the `<div data-id>` verbatim |
| `static.elfsight.com` / `<div class="elfsight-app">` | Elfsight (reviews, social, etc.) | Inject the `<script>` + the `<div class>` verbatim |
| `youtube.com/embed/` / `<iframe>` from youtube | YouTube video | Use the original `<iframe>` markup, including allow attrs |
| `player.vimeo.com` | Vimeo video | Same — verbatim iframe |
| `calendly.com/...` | Calendly booking | Inject calendly script + container div |
| `typeform.com/...` | Typeform | Verbatim iframe or embed div |
| `googlemaps` / `google.com/maps/embed` | Google Maps | Verbatim iframe |
| `instagram.com/embed.js` / Smash Balloon | Instagram feed | Verbatim script + container |
| `<iframe>` from any third-party domain | Generic embed | Default to verbatim — don't try to reproduce the iframe content |

Save findings to `embeds.json` in Phase 3:

```json
[
  {
    "section": "testimonials",
    "vendor": "senja",
    "html": "<div class=\"elementor-widget-container\"><script src=\"https://widget.senja.io/widget/1f486e44-2ddf-403b-9fc6-ea1b96f124bf/platform.js\" async></script><div class=\"senja-embed\" data-id=\"1f486e44-2ddf-403b-9fc6-ea1b96f124bf\" data-mode=\"shadow\" data-lazyload=\"false\"></div></div>"
  }
]
```

In Phase 4, **drop the html field straight into your output** at the corresponding section. Do not try to style the rendered widget — Senja/Elfsight/etc. ship their own styling and ignore yours.

### Interaction patterns inventory

A static screenshot lies about anything that moves. Before fetching, scan the source for non-static elements you'll need to handle in Phase 4 — *don't flatten them into the first state you see*. Look for:

| Pattern | How to detect | Cloning implication |
|---|---|---|
| **Carousel / slider** | Arrow buttons (`‹ ›`), pagination dots, repeated card row that overflows the visible viewport, classes like `.swiper`, `.slick`, `.glide` | Must be implemented as carousel, not a static grid. List all slides, not just the visible ones. |
| **Video background** | `<video>` tag, `<iframe>` from youtube/vimeo, `playsinline` attribute, autoplay style | Capture the video URL or poster frame. Don't substitute with a still image without flagging it. |
| **Embedded third-party widget** | `<iframe>` from google reviews, instagram, calendly, typeform, etc. | Often renders empty in static fetch / new-tab capture. Note in `assets.json`, may need to ask user for content. |
| **Lazy-loaded content** | `loading="lazy"`, sections that pop in on scroll, `IntersectionObserver` patterns, classes like `.aos-init`, `.fade-in-on-scroll` | First screenshot may show empty placeholders. Scroll the page (`evaluate_script`: `window.scrollTo(0, document.body.scrollHeight)`) before final capture. |
| **Modal / lightbox** | `[data-modal]`, click-triggered overlays, focus traps | Inventory the trigger + the modal contents separately. |
| **Tabs / accordions** | `[role="tab"]`, `aria-expanded`, click handlers that swap content | All tab panels' content must be captured, not just the visible one. |
| **Dynamic counters / animated numbers** | `data-count`, `CountUp.js` patterns, numbers that increment on scroll | Source-of-truth is the **final value**, not the in-flight `0` you might catch mid-animation. Read the `data-*` attribute or wait for animation to settle before capturing. |

This list is not exhaustive — be alert to anything that suggests "this changes after page load." If you see something like that and don't have a clear plan to capture it, **flag it in Phase 1 output** rather than discover the gap mid-implementation.

### Decorative + structural inventory (easy-to-miss categories)

Beyond interactive patterns, there are five categories of detail that consistently get dropped on first-pass clones because they're "subtle" — but their absence is the tell that betrays a clone as a clone. Walk every section and explicitly inventory:

| Category | What to look for | Where it hides | Why agents miss it |
|---|---|---|---|
| **Section dividers** | SVG / image breaks between sections (chevron-down arrows, angled cuts, wave separators), often near section bottom edge | `<svg>` at `position: absolute; bottom: 0`, or `::after` background-image, or sibling `<div class="separator">` | Agents see them as "decorative noise" and skip; they're actually part of brand identity |
| **Pseudo-element backgrounds** | Watermark patterns, gradient overlays, oversized brand glyphs sitting behind content | `::before` / `::after` with `background-image` and `position: absolute` | The DOM walk doesn't surface them — must query computed styles for pseudo-elements explicitly |
| **Form field decorations** | Background-image PNG/SVG icons inside `<input>` (mail icon, phone icon, location pin, dropdown caret) | `input { background-image: url(...) }` in CSS, no `<img>` in DOM | Agents render plain inputs because no `<img>` exists to copy |
| **Dropdown indicators** | Caret/chevron next to nav items with submenus, "tab open" indicator on submenu wrapper | `::after { content: ""; }` with arrow geometry, or inline `<svg>` after the link text | Agents only inventory the link text, not its trailing pseudo-element |
| **Header utility items** | Phone numbers, search icons, language switcher, "Call us" CTAs sitting outside `<nav>` but inside `<header>` | Direct children of `<header>`, often before/after `<nav>` | Agents grep `<nav>` only and miss everything in `<header>` siblings |

For each section, write a one-line check in your Phase 1 output:

```
hero: divider=chevron-svg-bottom, pseudo=none, formIcons=none, dropdowns=n/a, headerUtility=phone "02 8880 8889"
find-property: divider=chevron-svg-bottom, pseudo=::after pattern-angled-3.png, formIcons=none, ...
free-appraisal: divider=none, pseudo=none, formIcons=YES (Full Name → name.png, Email → mail.png, ...), ...
```

If any cell says "?" you have to go back to Phase 0 and capture more. Don't proceed to implementation with unknowns.

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

### Pseudo-element backgrounds — walk ALL elements, not a sample

A common source of "the section background just looks different" drift: pseudo-elements (`::before`, `::after`) carrying decorative backgrounds, watermarks, or gradients. The DOM walk doesn't naturally include them — you have to query for them explicitly. **And you must walk every element, not just sections** — pseudo backgrounds often live on inner containers, not the section wrapper itself.

```js
// Walk EVERY element (cap at ~5000 to avoid huge payloads on giant pages)
const found = [];
const all = [...document.querySelectorAll('*')].slice(0, 5000);
for (const el of all) {
  for (const pseudo of ['::before', '::after']) {
    const cs = getComputedStyle(el, pseudo);
    const bgImage = cs.backgroundImage;
    const content = cs.content;
    const maskImage = cs.maskImage || cs.webkitMaskImage;
    if (bgImage !== 'none' || maskImage && maskImage !== 'none' || (content !== 'none' && content !== '""' && content !== "''")) {
      // Build a stable selector for the host element
      const id = el.id ? `#${el.id}` : '';
      const cls = [...el.classList].slice(0, 3).map(c => `.${c}`).join('');
      found.push({
        selector: `${el.tagName.toLowerCase()}${id}${cls}`,
        pseudo,
        backgroundImage: bgImage,
        backgroundPosition: cs.backgroundPosition,
        backgroundSize: cs.backgroundSize,
        backgroundRepeat: cs.backgroundRepeat,
        maskImage,
        content: content === 'none' ? null : content,
        position: cs.position,
        inset: `${cs.top} ${cs.right} ${cs.bottom} ${cs.left}`,
        width: cs.width, height: cs.height,
        opacity: cs.opacity, transform: cs.transform,
        zIndex: cs.zIndex,
      });
    }
  }
}
found;
```

Save the result to `_source/pseudo-elements.json`. In Phase 4, **every entry with a `backgroundImage` URL must be replicated** — download the asset, attach it to the matching selector with the same `position` / `inset` / `size` / `opacity`. Do not skip "minor-looking" decorative pseudo-elements; they're often the element that makes the section feel branded.

This is where the "Find Your Property has a watermark pattern, my clone has a flat color" and "the section divider chevron is gone" failures happen. Catch them here.

### Form input decorations (background-image icons)

Many form designs put icons inside inputs via `background-image`, not `<img>`. The agent's DOM walk sees a bare `<input>` and renders a bare `<input>`, losing the icon. Run an explicit scan:

```js
[...document.querySelectorAll('input, select, textarea')].map(el => {
  const cs = getComputedStyle(el);
  return {
    name: el.name || el.id,
    type: el.type || el.tagName.toLowerCase(),
    placeholder: el.placeholder,
    backgroundImage: cs.backgroundImage,
    backgroundPosition: cs.backgroundPosition,
    backgroundSize: cs.backgroundSize,
    paddingLeft: cs.paddingLeft, paddingRight: cs.paddingRight,
  };
}).filter(f => f.backgroundImage && f.backgroundImage !== 'none');
```

Save URLs to `assets.json` under a `formIcons` key, download them, and reproduce the CSS rules verbatim in Phase 4.

### Container width — measure, don't default

The single most visible global drift is "clone feels narrower than source" because the agent defaulted to a generic 1200px max-width container. Don't default. **Measure** the actual content width in the source at multiple viewports and record it in `tokens.json`:

```js
// At each viewport size you care about (run after resize_page)
const probes = ['.container', '.elementor-container', '.e-con-inner', 'main > section > div:first-child', '[class*="container"]'];
const widths = {};
for (const sel of probes) {
  const el = document.querySelector(sel);
  if (!el) continue;
  const rect = el.getBoundingClientRect();
  const cs = getComputedStyle(el);
  widths[sel] = {
    width: rect.width,
    maxWidth: cs.maxWidth,
    paddingLeft: cs.paddingLeft, paddingRight: cs.paddingRight,
    viewportWidth: window.innerWidth,
  };
}
widths;
```

If the source uses near-full-width with horizontal padding (common: Elementor "boxed" containers, Tailwind `container` with custom padding), reproduce that — don't impose a `max-width: 1200px` of your own.

This is where the "Find Your Property has a watermark pattern in its background, and my clone has a flat color" failure happens. Catch it here.

### Download assets locally

For long-lived clones, prefer **local assets over CDN-linked ones** — broken links from the source CDN, third-party hotlink protection, and offline reliability all become problems otherwise. The exception is when the user explicitly says "just link to the live URLs."

For each entry in `assets.json` that has a remote URL, download it to a sibling `_assets/` folder:

```
_assets/
├── images/
│   ├── logo.svg
│   ├── hero-poster.jpg
│   └── team.jpg
├── icons/
│   ├── professional.svg
│   ├── efficient.svg
│   └── stability.svg
└── fonts/
    └── (Google Fonts handled via @import, not local copies, unless user requests)
```

Tools available:

- `Bash`: `curl -L -o "_assets/images/logo.svg" "https://source.com/logo.svg"` — most reliable for arbitrary URLs.
- `WebFetch`: text-only, won't work for binary assets like images.

In your output (`index.html`, `styles.css`), reference the **local path** (`_assets/icons/professional.svg`) not the source URL. Update `assets.json` to record both `sourceUrl` and `localPath`.

When an asset can't be downloaded (CORS, 403, requires auth), keep the source URL but flag it explicitly in `assets.json.localPath: null` and note it in the drift list.

### Icon uniqueness check

Source pages sometimes serve the same SVG for what looks like three distinct icons (Elementor sprite reuse — a real-world bug). When you scrape icons from the DOM, **verify the URLs are distinct before assuming they are different files**. If three icons all point to the same source SVG, that's a source-side bug — flag it in `NOTES.md` and use the closest fitting Lucide/Heroicons fallback for the duplicates, with a clear drift note.

### Content fidelity — capture verbatim, don't summarise

Visual style is half the clone; the other half is **the actual words and numbers on the page**. Approximating content is a common, easy-to-miss failure mode — you build a beautiful section that says "200+ Properties Sold" while the source says "1,200 Sales in 2024" and never notice.

When you have a live URL via Chrome DevTools MCP, run a single `evaluate_script` early in Phase 2 that captures **all visible text plus the values of important non-text attributes**:

```js
// Example payload — adapt the selectors to the section structure you've inventoried
({
  headings: [...document.querySelectorAll('h1,h2,h3,h4')].map(h => ({
    level: h.tagName, text: h.innerText.trim(),
  })),
  stats: [...document.querySelectorAll('[data-count], .counter, .stat-number')].map(n => ({
    visibleText: n.innerText.trim(),         // e.g. "200+"
    dataCount: n.getAttribute('data-count'), // e.g. "200" — final value if animated
  })),
  buttons: [...document.querySelectorAll('button, a.btn, [class*="cta"]')].map(b => b.innerText.trim()),
  formFields: [...document.querySelectorAll('form input, form select, form textarea')].map(f => ({
    label: f.labels?.[0]?.innerText?.trim() ?? f.placeholder ?? f.name,
    type: f.type, required: f.required,
  })),
  testimonials: [...document.querySelectorAll('[class*="testimonial"], [class*="review"]')]
    .map(t => t.innerText.trim().slice(0, 500)),
  navItems: [...document.querySelectorAll('header nav a, [role="navigation"] a')].map(a => a.innerText.trim()),
})
```

Save the result. In Phase 4, **use it as the literal source of truth for copy** — `200+` not `0+`, the actual button labels, the actual nav items. Never paraphrase.

If you can't capture programmatically (no MCP, only screenshot), transcribe the visible text into a short content inventory and refer back to it during implementation:

```
Hero headline: "Sell, Buy, Rent"
Hero sub: "Results is what our clients expect. Excellence is what we deliver."
Stats: "200+ Sold | 300+ Leased | 30 Average days on Market"
Form fields: Full Name (required), Email (required), Phone, Address, Property Type, Purpose of Valuation, Additional Information
```

When something on the source is illegible, dynamically loaded, or rendered empty in your capture, **flag it explicitly** in your Phase 1 output rather than inventing plausible-looking placeholders. It's better to ship `[testimonials section: 8 reviews — content not capturable, see source]` than to ship 3 fake testimonials.

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

### 3c. Design tokens — produce `tokens.json`

Don't keep tokens in your head — write them to disk as `tokens.json` next to your output. Phase 4 implementation reads from this file as the **single source of truth**, so colors / fonts / spacing don't drift mid-build.

```json
{
  "colors": {
    "primary": "#e90a8c",
    "ink": "#101010",
    "soft-pink": "#ffe8f6",
    "muted": "#666666",
    "border": "#e6e6e6"
  },
  "typography": {
    "fontFamilies": {
      "heading": "Poppins, sans-serif",
      "body": "DM Sans, sans-serif"
    },
    "scale": {
      "h1": { "size": "80px", "lineHeight": "100px", "weight": 700 },
      "h2": { "size": "54px", "lineHeight": "65px", "weight": 700 },
      "h3": { "size": "20px", "lineHeight": "1.4", "weight": 700 },
      "body": { "size": "16px", "lineHeight": "1.6", "weight": 400 }
    }
  },
  "spacing": { "base": 4, "sectionPadding": "80px", "containerMax": "1280px" },
  "radius": { "card": "12px", "button": "999px" },
  "shadow": { "card": "0 1px 3px rgba(0,0,0,0.08)" },
  "gradients": {},
  "motion": { "ease": "cubic-bezier(0.4, 0, 0.2, 1)", "duration": "200ms" }
}
```

If you have computed styles via `evaluate_script` → use those values verbatim. If only screenshot → use a mental color picker and round to the closest sensible value (e.g. `#4F46E5` not `#4F47E4`). Either way, write the file before Phase 4 starts.

### 3d. Assets — produce `assets.json`

Tokens cover style; **assets** cover the actual files referenced by the page. Capturing this list is what catches the "hero is supposed to be a video, not a still image" failure mode.

```json
{
  "fonts": [
    { "family": "Poppins", "source": "https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700" }
  ],
  "logo": { "type": "image", "src": "https://source.com/logo.svg" },
  "hero": {
    "type": "video",
    "src": "https://source.com/hero.mp4",
    "poster": "https://source.com/hero-poster.jpg",
    "fallback": "If video can't be downloaded, use poster as background-image and document in drift list."
  },
  "sectionImages": [
    { "section": "team", "src": "https://source.com/team.jpg", "alt": "Mclaws team" }
  ],
  "icons": {
    "system": "Lucide | Heroicons | custom SVG",
    "items": [
      { "name": "professional", "src": "https://source.com/icons/professional.svg" },
      { "name": "efficient", "src": "https://source.com/icons/efficient.svg" }
    ]
  },
  "embeddedWidgets": [
    {
      "name": "google-reviews",
      "type": "iframe",
      "src": "https://elfsight.com/...",
      "renderState": "empty in static capture — content not capturable, flag as Tier mixed"
    }
  ],
  "videos": [],
  "thirdParty": []
}
```

For each non-trivial asset, capture either the live URL (preferred — references the source's CDN) or note "asset unavailable, using placeholder + drift note." **Never silently substitute a video with a still image, or a custom icon with a generic Lucide icon, without flagging it.**

### 3e. Embeds — produce `embeds.json`

For every embed pattern detected in Phase 1 from `_source/raw.html`, save it to `embeds.json` with the **verbatim original markup** + the `section-map` name where it should land.

```json
[
  {
    "section": "testimonials",
    "vendor": "senja",
    "html": "<script src=\"https://widget.senja.io/widget/.../platform.js\" async></script><div class=\"senja-embed\" data-id=\"...\" data-mode=\"shadow\" data-lazyload=\"false\" style=\"display: block; width: 100%;\"></div>"
  },
  {
    "section": "hero",
    "vendor": "youtube",
    "html": "<iframe src=\"https://www.youtube.com/embed/...?autoplay=1&mute=1&loop=1\" frameborder=\"0\" allow=\"autoplay; encrypted-media\" allowfullscreen></iframe>"
  }
]
```

This file is what Phase 4 reads to inject embeds verbatim. Don't try to recreate the widget — drop the html string straight into the section.

### 3f. Section map (carried over from Phase 0)

Phase 0 already produced `_source/section-map.json`. In Phase 3, copy or link it to your output root as `section-map.json` so Phase 5's per-section verifier has a stable reference. Add `cloneSelector` for each section to point at the equivalent element in your own output:

```json
[
  {
    "name": "hero",
    "sourceSelector": "section.hero",
    "cloneSelector": "section.hero",
    "type": "hero",
    "embed": "hero"
  }
]
```

### 3g. Interactive states

Even from a single screenshot, infer states from visible cues:

- Buttons usually have `:hover`, `:active`, `:focus`
- Inputs have `:focus`, `:disabled`, `:invalid`
- Cards may have `:hover` lift
- Nav items may have `aria-current` styling

If the user provides a live URL or context dump with `:hover` rules, capture those exactly.

### 3h. Evidence contract — produce `section-evidence.json`

The single biggest failure mode across clones is the agent rendering features the source doesn't have. Real examples from prior runs:

- "header transitions to solid white on scroll" — source actually stays transparent at all scroll positions
- "footer has a large 'brand-name' word watermark" — source has no such watermark
- "card has a CTA button overlay" — source has only a price badge, no CTA

These are honest mistakes — the agent saw a similar pattern on a similar site and inferred. The fix is structural: **every rendered feature must trace to a file + line in `_source/`**. If you can't cite the evidence, the feature does not exist.

For each section in `section-map.json`, list the rendered features with citations:

```json
{
  "header": [
    { "feature": "transparent gradient background",  "evidence": "_source/nav-states.json: initial.backgroundImage" },
    { "feature": "phone CTA on right side",          "evidence": "_source/raw.html: line 1247 <a class='phone-cta'>" },
    { "feature": "submenu carets next to nav items", "evidence": "_source/pseudo-elements.json: .menu-item-has-children::after" },
    { "feature": "no scroll-triggered solid state",  "evidence": "_source/nav-states.json: scrolled.backgroundColor === initial.backgroundColor" }
  ],
  "find-property": [
    { "feature": "chevron divider at section top",   "evidence": "_source/raw.html: <svg class='elementor-shape-top'>" },
    { "feature": "watermark bg pattern via ::before","evidence": "_source/pseudo-elements.json: .find-property::before backgroundImage" },
    { "feature": "tabs with full border (not bottom-only)", "evidence": "_source/section-styles.json: find-property.tabGroup.border" }
  ],
  "footer": [
    { "feature": "social icons in dark square containers", "evidence": "_source/section-styles.json: footer.socialIcon.backgroundColor + borderRadius" },
    { "feature": "bare menu links (no chevron prefix)",    "evidence": "_source/raw.html: footer <a> elements have only text content" },
    { "feature": "angled-pattern PNG at bottom-left",      "evidence": "_source/pseudo-elements.json: footer::after backgroundImage" }
  ]
}
```

Note the **negative evidence** entries ("no scroll-triggered solid state", "bare menu links no chevron prefix") — these are explicit non-features that protect against hallucinations. When prior iteration feedback or instinct suggests "the nav probably goes solid on scroll," the negative evidence line is what stops the agent from rendering it.

**Hard rule for Phase 4**: before rendering any feature, the agent must be able to cite its evidence row. If the answer is "I just thought it would look right," the feature does not get rendered. If the source is genuinely missing data (e.g., no Phase 0 capture of the relevant pseudo-element), go back to Phase 0 — don't proceed by guessing.

---

## Phase 4 — Implement

### Iteration-delta mode (when re-cloning)

**Check for sibling archives first**: if `outputs-iterN-1-archive/` (or any prior-iteration archive) exists next to your output target, you are in **fix-up mode, not fresh-clone mode**. Misreading this is the #1 source of cross-iteration regressions.

The contract differs from a fresh clone:

| Mode | Starting point | Bar |
|---|---|---|
| Fresh clone | empty output dir | "match the source" |
| Iteration-delta | iter-N-1's output | "minimum diff that resolves the listed drifts, without regressing what was correct" |

Required steps before writing any code:

1. **Read iter-N-1's `NOTES.md`** to inventory what worked and what didn't. The user's drift list for iter-N tells you what's broken; iter-N-1's "no drift detected on" section tells you what must stay correct.
2. **Tag every feature** in iter-N-1 as either `keep` (correct, don't touch) or `fix` (drift, rewrite). Save as `iteration-delta.json`:

   ```json
   {
     "keep": [
       "header phone CTA right side",
       "Senja embed verbatim",
       "form 7 fields with PNG icons",
       "footer angled-pattern bg"
     ],
     "fix": [
       "header was solid white at scroll=0 → must be transparent (per nav-states.json initial)",
       "card badge was inline → must be position:absolute bottom-left",
       "Living Partner title was white → must be black (per section-styles.json living-partner.h2.color)"
     ]
   }
   ```

3. **Touch only `fix` items.** Do not refactor, restyle, or re-architect `keep` items even if you'd structure them differently. The bar is "minimum diff that resolves the listed drifts" — every line you change in a `keep` block is a regression risk.

4. **Before declaring Phase 4 done**, run a regression diff: for each `keep` feature, confirm iter-N renders it the same way iter-N-1 did. Any divergence is a regression — revert it.

### Common silent regressions in iteration-delta mode

These have happened in real prior runs — watch for them explicitly:

- Verbatim YouTube/Vimeo iframe replaced with a static fallback image because "slideshow not implemented" (iframe was already correct, don't downgrade)
- `position: fixed` / `position: sticky` on nav dropped while fixing transparency (these are independent properties; you need both)
- Scroll-state JS bindings (`IntersectionObserver` for nav, lazy-load triggers, count-up animations) lost in the rewrite
- Verbatim Senja/Calendly/Elfsight embed replaced with a fake reproduction
- Container widths reset to a default `max-width: 1200px` while fixing inner spacing

User feedback like "X drift in iter-4" means **fix X**, not "rebuild iter-5 from scratch." The honest path: keep what was correct, fix what was wrong, document any deliberate downgrade with a "why" in NOTES.md.

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
| (none, or no `package.json` at all) | **Plain HTML + CSS + JS** — write `index.html`, `styles.css`, and `app.js` as siblings the user can open directly in a browser. See "Default plain output" below. |

#### Default plain output

When there's no project context to match (the user is in an empty folder, in their home directory, or just dropped a prompt without pointing you at a codebase), default to a **three-file plain web** structure:

```
index.html
styles.css
app.js
```

Rationale: most real-world web pages need *some* interactivity even if it looks minimal — hamburger menu toggle, smooth-scroll behavior, an intersection observer for nav-on-scroll, a dropdown. Always scaffolding all three files (even if `app.js` starts as a couple lines) avoids the awkward "I built it pure CSS but now you want a menu toggle, here's a fourth file" moment.

If the source page is genuinely zero-JS (a static brochure with no interactivity at all), you can omit `app.js` — but call it out in your output: "no JS file created since the source has no interactive behavior." Otherwise default to all three.

Do not introduce a build step (no Vite, no Tailwind CDN unless you explicitly verify the user wants that, no `npm install`). The whole point of the plain default is the user can double-click `index.html` and see the result.

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

1. **Exact colors** — read from `_source/section-styles.json` per element. **Never infer from context** ("section bg is pink so title must be white" is wrong — read the computed `color` and use that). Eyedrop only when no computed-style file exists.
2. **Exact spacing** — measure pixel gaps in the screenshot or read from computed styles. `mt-3` vs `mt-4` is a visible difference.
3. **Exact font** — if Google Fonts, import the same family + weights. If system font stack, match it.
4. **Exact radius** — `rounded-md` (6px) ≠ `rounded-lg` (8px). Be precise.
5. **Exact icons** — if the source uses Lucide, use Lucide. If Heroicons, use Heroicons. Don't substitute.
6. **No invented content (HARD RULE)** — keep the source's text verbatim. **If a section's content cannot be extracted** (gated, dynamic, embedded widget that didn't render in your capture, third-party feed without API access), the section's markup **must still be rendered** but with **empty body** and an HTML comment: `<!-- TIER C: content not extractable, see NOTES.md -->`. Forbidden, even when "well-intentioned":
   - Re-using content from a sibling section ("Blog" tab content copied into "Videos" tab because Videos didn't load)
   - Free-text disclaimers in the rendered output ("Instagram feed requires API token", "feed not loaded — placeholders shown") — these are still invented content; document them in `NOTES.md` instead
   - Lorem ipsum, fake testimonials, fake counters, generic stock copy
   - "Plausible-looking" text inferred from section heading (a "Why Us" section with three made-up benefit blurbs)
   If you find yourself typing words that aren't in `_source/raw.html` or the verbatim content capture, stop. Either find them in the source or leave the slot empty.
7. **Match the layout primitive** — if the source uses CSS Grid, don't reimplement with flexbox + nth-child hacks.
8. **Preserve DOM structure for complex components** — for cards, forms, nav, footer, and any component with absolute-positioned children, **copy the structure from `_source/raw.html` (or `rendered.html` if raw is incomplete) verbatim**, then re-style. Don't rebuild from "what the screenshot looks like." Specifically:
   - **Cards**: preserve sibling order of image / badge / stats / title / cta. If the source has `<img><span class="badge sale">SALE BY NEGOTIATION</span><h3>...` with the badge `position: absolute; bottom: 16px; left: 16px`, reproduce that — don't move the badge below the stats just because that's where it "looks like it lives" in the rendered screenshot.
   - **Forms**: preserve label/input/helper-text relationships, field group order, full select-option lists (15 Property Type options means 15, not 5).
   - **Nav**: preserve header utility area (phone, search, language switch) as a peer of `<nav>`, not inside it. Preserve dropdown indicator pseudo-elements.
   - **Icon containers**: if the source has bare `<a><svg>...</svg></a>` with no wrapper styling, **do not add circular pill wrappers** around the icon. Same for contact-info icons (pin/phone/envelope) — if source uses small inline glyphs without backgrounds, don't render them inside filled circles. The container around an icon is part of its identity; copying the icon SVG but adding your own pink circle around it is a fidelity miss.
   - **Menu link decorations**: if the source's footer/nav links are bare `<a>Buy</a>`, do **not** add `›` / `>` / chevron prefix glyphs (whether via `::before content` or inline span). That's both invented content (Rule 6) AND structure drift.
   - **Footer**: footers are dense decoration zones (logo, contact rows, link columns, social icons, newsletter form, watermark bg). Apply the same per-section discipline — section-styles.json read, pseudo-elements.json check, raw.html structure copy — that you'd apply to the hero. Don't treat footer as "and finally a footer".
9. **No imposed max-width** — read container width from `_source/section-styles.json` per section. If the source uses near-full-edge layout with horizontal padding, do the same. Don't drop a 1200px container around everything by default.

10. **No silent regressions across iterations** — if you are running iter-N as a re-clone (not a fresh clone), the previous iteration's output is in `outputs-iterN-1-archive/`. Before declaring iter-N done, **diff iter-N against the archive for features the user explicitly liked or that were already correct**. Common silent regressions:
    - Replacing a correct YouTube/video iframe with a static fallback image because "slideshow not implemented" — if the previous iteration had the iframe rendering, that's not a slideshow, it's already correct; don't downgrade.
    - Dropping `position: fixed` / `position: sticky` on nav and replacing with `position: absolute` because user said "transparent on top" — fixed/sticky and transparent are independent properties; you need both.
    - Removing interactive JS bindings (carousel autoplay, scroll-triggered nav state, lazy-load) because the rewrite forgot to port them.
    - Substituting a correctly-injected verbatim embed (Senja, Calendly, etc.) with a fake reproduction.
    User feedback like "X drift in iter-4" means **fix X**, not "rebuild iter-5 from scratch and reintroduce features iter-4 had correctly." The honest path is: keep what was correct, fix what was wrong, document any deliberate downgrade with a "why" in NOTES.md.

11. **Honor guesswork markers in `section-evidence.json`** — before rendering ANY feature, scan its evidence row for markers like `(implied)`, `(inferred)`, `(guessed)`, `(speculation)`, `(palette has Nth)`. Phase 1's own honesty about what it captured is the strongest signal you have about Phase 4 hallucination risk. **Do not render features whose only evidence row contains these markers.** Either:
    - Go back to Phase 0 and capture more (e.g., the actual title text via re-screenshot or DOM walk), then update the evidence row, OR
    - Omit the feature and document under "Known limitations" in NOTES.md.

    Real-world example: in the resend.com clone, `section-evidence.json: reach.h4Features[7]` was literally labeled `"title": "(implied — palette has 8th)"`. Phase 4 rendered an 8th feature card titled "Trusted IP pools" anyway. Pass D adversarial caught it. The fix is enforcement at Phase 4, not catching at Phase 5: **grep the evidence file for `\((implied|inferred|guessed|speculation)`** before each section's implementation, and STOP if any match falls into the section you're about to render.

### Anti-patterns (from prior cloning failures)

- ❌ "Close enough" colors — pick a color picker and copy hex
- ❌ Skipping the responsive viewports — always implement all breakpoints, not just desktop
- ❌ Inferring content from context — copy the actual text, don't summarize
- ❌ Using only the static HTML when JS-rendered DOM is available — the JS version is the truth
- ❌ Refactoring "while you're there" — clone first, refactor in a separate pass

---

## Phase 5 — Verify (five gated passes)

After implementing, **don't claim done yet.** Phase 5 is five gated passes that run in order — each is cheap-to-expensive, and earlier passes catch issues before later passes start spending screenshots and sub-agent calls. Cap the per-section visual loop at 3 iterations so it doesn't run forever.

The five passes:

| Pass | What it does | Cost | Catches |
|---|---|---|---|
| **A** — Tokens-and-content sanity | Text-level grep of output against `tokens.json` + content inventory | Cheapest (no screenshots) | Stray hex colors, missing headings, missing stat numbers, wrong asset types |
| **B** — Computed-style parity | Programmatic `evaluate_script` diff: source vs clone, same payload | Cheap (one MCP round-trip per page) | Color/spacing/typography mismatches the eye smooths over |
| **C** — Per-section visual diff | Screenshot loop, section by section | Medium (sections × viewports × iterations) | Layout, structure, decorative pseudo-elements, interactive states |
| **D** — Adversarial review | Spawn fresh sub-agent to find drifts independently | Medium (one Agent call) | Hallucinations, regressions, blind-spot errors the implementer missed |
| **E** — Drift report + lessons append | Write the report and update `{workspace}/lessons.md` | Cheap | Compounding learnings for next iteration |

**You don't get to skip passes.** The passes complement each other — A finds different drifts than B, B finds different drifts than D. Skipping any pass means a class of drifts goes uncaught.

### How to open the clone for screenshotting (per stack)

You need to render your clone in a browser before you can compare it to the source. The path differs by stack:

| Stack | How to open |
|---|---|
| **Plain HTML/CSS/JS** | `new_page` with `url: "file:///D:/path/to/index.html"`. No server needed. **Use forward slashes and a fully-qualified `file://` URL.** On Windows that means `file:///D:/path/...`. |
| **Next.js / Vite / SvelteKit / Astro dev** | Ask the user to start the dev server (`pnpm dev`, `npm run dev`) on a known port before Phase 5. Then `new_page` against `http://localhost:<port>`. If they can't or don't, skip the visual loop and document it in Pass C. |
| **Astro / static export** | Build (`npm run build`) and serve (`npx serve dist/`) on a known port, then visit. |
| **No way to render** | Skip the visual loop and explicitly note this is a "verification deferred" output. Don't pretend it's done. |

For testing scenarios that you (the agent) initiated yourself — empty folder, default plain output — the file:// URL path is always available since you just wrote the files. There is no excuse to skip the visual loop in that case.

### Pass A — Tokens-and-content sanity check (cheap, run first)

Before any visual screenshot, do a quick text-level sanity pass against the artifacts you produced in Phase 3:

- Open `tokens.json` and search your output for any **literal hex color** that isn't in the tokens file — drift.
- Open the content inventory (Phase 2 verbatim capture) and grep your output for the visible text from each section. Any heading or stat number that's missing or different is drift.
- Open `assets.json` and confirm every listed asset is referenced in the output. If `hero.type === "video"` but your output has `<img>` for the hero, that's drift — flag it.

Catch what you can here before paying for a screenshot round-trip.

### Pass B — Computed-style parity (programmatic)

Visual diffs from screenshots miss small style mismatches that the eye smooths over (a heading that's `#0d0d0d` vs `#101010`, padding that's `78px` vs `80px`, a border-radius that's `4px` vs source's `10%` on a 22×44 element). The fix is to run the **same `evaluate_script` payload against both the source and the clone**, then literal-equality-diff the JSON outputs.

Required steps:

1. With chrome-devtools MCP, open the clone (file:// URL or `localhost:<port>`) in a tab and the source URL in another tab — or run them sequentially in the same tab (capture clone result → save → navigate to source → re-capture).
2. Run the **same payload** that produced `_source/section-styles.json` against the clone, producing `clone-styles.json`. Use the clone's selectors (mapped via `section-map.json[i].cloneSelector`).
3. Diff the two files. Build `_source/style-diff.json`:

   ```json
   {
     "header": {
       "container.backgroundColor": { "source": "rgba(0, 0, 0, 0)", "clone": "rgb(255, 255, 255)" },
       "headings[0].color":          { "source": "rgb(255, 255, 255)", "clone": "rgb(255, 255, 255)" }
     },
     "living-partner": {
       "headings[0].color":          { "source": "rgb(16, 16, 16)",   "clone": "rgb(255, 255, 255)" }
     }
   }
   ```

4. Every entry in `style-diff.json` is a drift. Fix them all before moving to Pass C — these are objective mismatches, not judgment calls.

This pass replaces a category of "did I get the colors right?" eyeball checks. If `style-diff.json` is empty, your tokens/colors/spacing are provably correct at the captured selectors and you can spend Pass C's iterations on layout and structure instead.

**Common gotchas**:
- Color values returned by `getComputedStyle` are normalized — `#101010` becomes `rgb(16, 16, 16)`. Compare normalized strings, not source markup.
- `border-radius: 10%` resolves to a different `px` per element size — the diff is meaningful, not noise.
- Pseudo-elements need a separate query (`getComputedStyle(el, '::before')`); don't expect them in the main payload.

### Pass C — Per-section visual diff loop (iterate)

Whole-page diffs miss subtleties: a button that's slightly off-center inside a section, or a watermark hiding behind a hero. **Diff section-by-section using `section-map.json`**, with the loop scoped to the current section:

```
For each section S in section-map.json:
    For each viewport in [1440, 768, 375]:
        1. Crop or re-capture source screenshot to S's bounding box
           (in chrome-devtools MCP: take_screenshot then crop, or use evaluate_script
            to get S.getBoundingClientRect() and capture only that element)
        2. Take same-viewport screenshot of your clone, scoped to S.cloneSelector
        3. Walk the diff checklist for S
        4. List drifts
        5. If drift count > 0 AND iteration < 2 (per-section cap):
            a. Fix the drift list in your code (only edits inside S's scope)
            b. Re-screenshot S
            c. Re-diff
            Loop back to step 4
        6. If iteration >= 2, document remaining S drifts as known limitations and move on
After all sections converge or hit cap:
    7. Take a single full-page screenshot at 1440 of source vs clone as a final sanity pass.
       Catches inter-section issues like inconsistent vertical rhythm.
```

This is bounded: at most `sections × viewports × iterations = 10 × 3 × 2 = 60` screenshots. Per-section cap is tighter (2) than the old flat cap (3) because section-scoped fixes are smaller and converge faster.

#### The diff checklist (run for each viewport)

Run through every item — surface-level drifts hide real ones. Items prefixed **[CSS]** read from `_source/section-styles.json` / `_source/pseudo-elements.json` and compare against your output's computed styles, not just the visual screenshot.

**Content + structure**
- **Hero**: Same media type? (video vs static image vs gradient) Same headline copy verbatim? Same CTA buttons present?
- **Section order**: Does the clone have all the sections the source has, in the same order? (Easy to drop a whole section silently.)
- **Section-level layout**: Carousel vs grid, 1-featured-plus-3-sides vs 4-equal-cards, etc.
- **Stat numbers**: Are the visible counter values from your verbatim capture present? `200+` not `0+`.
- **Form fields**: Field count, labels, AND full select-option lists match the captured form-fields list? (15 Property Types means 15.)
- **Headings**: Same text, similar size hierarchy?
- **DOM structure for cards**: Badge position (absolute? inside image? overlay?), stat row order, title-vs-stats-vs-cta vertical order — all match `_source/raw.html`?
- **No invented content**: Search clone output for any string not in `_source/raw.html` or content inventory. Disclaimers like "feed not loaded" / "requires API token" rendered into HTML are forbidden — flag and remove.

**Style — read from computed-style files, don't eyeball**
- **[CSS] Title color per section**: clone's heading `color` matches `section-styles.json[section].headings[0].color`? (Catches the "section bg is pink, so I made the title white" inversion.)
- **[CSS] Button color contract**: bg + text color + hover state match per section? (Catches the inverted-button drift.)
- **[CSS] Container width**: clone's content-area `width` within ±5% of `section-styles.json[section].contentWidth` at 1440px? (Catches the imposed-max-width drift.)
- **[CSS] Tab/pill styling**: full border vs border-bottom only — match exactly?
- **[CSS] Color palette**: Pulling from `tokens.json` only, no stray hexes?
- **[CSS] Typography**: Same font family, same weight per role, exact `fontSize` per heading from `section-styles.json`?
- **[CSS] Spacing**: Section padding within ~20%? Card gaps within ~4px?

**Decorative + structural details (the "easy to miss" tier)**
- **Pseudo-element backgrounds rendered**: every entry in `_source/pseudo-elements.json` with a `backgroundImage` is **visually present** in the clone (not just "the CSS rule exists"). Open the clone in a browser, screenshot the section, confirm the watermark/pattern is visible.
- **Section dividers**: every chevron/wave/cut SVG between sections in the source is present in the clone — count them and match.
- **Form input icons**: every entry in `assets.json.formIcons` renders inside its input field — visible, not just declared in CSS.
- **Background-image position**: news/feature sections with bg images at specific positions (e.g. "left-bottom") match — not defaulted to top-left.

**Interactive behavior**
- **Nav scroll states**: scroll the clone 400px and confirm the nav transitions match `nav-states.json` (e.g. transparent → solid, no shadow → shadow).
- **Dropdown indicators**: nav items with submenus show carets next to text + open-state indicator on the dropdown wrapper.
- **Hover states**: buttons + cards have hover transitions; nav items reveal dropdown on hover.

**Assets + fallbacks**
- **Icons**: From the source's icon system, or substituted? If substituted, flagged?
- **Images**: From local `_assets/` folder (downloaded from source), or replaced with placeholders? If placeholders, flagged?
- **Header utility area**: phone numbers / search / CTAs that live in `<header>` outside `<nav>` are present.

**Responsive**
- **Mobile breakpoint**: Hamburger present, content stacks correctly, no horizontal overflow?

**Footer-specific (commonly skipped)**
Run the entire checklist above on `footer` with the same rigor as `hero`. Footer drifts that recurringly slip through:
- **Social icon wrappers**: source flat glyph vs clone circular-pill — read computed `borderRadius` + `backgroundColor` of the icon's parent `<a>`/`<span>`, not just the icon itself.
- **Contact info icon style**: small outlined glyph vs filled circle container — same check.
- **Footer menu links**: bare `<a>` vs links with `›` prefix glyphs — search clone output for any chevron/arrow character that isn't in `_source/raw.html`.
- **Newsletter input**: bare borderless input vs filled-bg input + submit-button — match source's exact decoration (often there's no visible submit button at all).
- **Footer watermark**: oversized brand-text or pattern as bg — must be in `pseudo-elements.json` extraction, must render visibly in the clone.
- **Logo treatment**: footer logo size/color often differs from header logo — read from section-styles.json["footer"], don't reuse header logo styling.

### Pass D — Adversarial review (fresh sub-agent)

The agent that implemented the clone is the worst auditor of its own work — same biases, same blind spots, same "it looks fine" reflex. Pass D breaks that loop by spawning a **fresh sub-agent** with no implementation context, only the source artifacts and the final output, tasked with **finding drifts**, not confirming success.

How to run it:

```
Agent({
  description: "Adversarial clone-ui review",
  subagent_type: "general-purpose",
  prompt: `
You are an adversarial reviewer. Another agent built a clone of {SOURCE_URL}; the output is at {CLONE_PATH}. You did NOT implement it — your job is to find what's wrong, not to validate.

Inputs available to you:
- Source artifacts in {CLONE_PATH}/_source/  (raw.html, rendered.html, section-styles.json, pseudo-elements.json, nav-states.json, section-evidence.json, .captures/)
- Final output: {CLONE_PATH}/index.html (or framework equivalent), styles, JS
- The skill's contract: clone-ui/SKILL.md fidelity rules 1-10

Find at least 5 drifts. For each, cite:
- The rendered feature in the clone (file + line)
- The source evidence that contradicts it (file + line in _source/)
- The category: hallucination / inversion / structure-drift / asset-substitution / iteration-regression

Specifically attack:
1. Features the clone renders that have NO entry in section-evidence.json (hallucination)
2. Computed styles in clone that diverge from section-styles.json (inversion)
3. DOM structure of cards/forms/nav/footer that differs from raw.html (structure drift)
4. Assets in clone not present in assets.json, or assets.json entries not referenced (asset drift)
5. If outputs-iterN-1-archive/ exists: features that were correct there but are wrong now (regression)

Be specific. "The header looks off" is not a drift; "The .site-header backgroundColor in clone is rgb(255,255,255) but section-styles.json says rgba(0,0,0,0)" is a drift. Report under 400 words.
  `
})
```

The sub-agent's output is the source of truth for "what's actually broken." If it returns ≥5 drifts, **iter the implementation against those** (back to Pass C with the new drift list). If it returns 0–2 drifts after exhausting effort, you are converged — proceed to Pass E.

**Why this works**: the sub-agent has no investment in the implementation being correct, no memory of "I struggled with this for 2 hours, let me declare it done." It will read `section-evidence.json` and notice features in the output that aren't in it. That asymmetry is the leverage.

**Calibration: tell the sub-agent to use `Grep` (the tool), not `Bash` grep.** When the sub-agent claims "string X is NOT in `rendered.html`", that's a critical negative finding — it directly drives "this content was hallucinated" drifts. Bash `grep` and `grep -P` can fail silently on non-UTF8 Windows locales (`grep: -P supports only unibyte and UTF-8 locales`) and produce false-negative drift claims. Add this verbatim to your Pass D prompt:

> "When you need to verify that a string is *not present* in a captured file (e.g., 'this text was invented because it's not in rendered.html'), use the **Grep tool** (which uses ripgrep, locale-agnostic). Do NOT use Bash `grep` for negative findings — it can fail silently and report 0 hits when the string actually exists. Bash `grep` is fine for positive enumeration; for the existence-check that drives a hallucination drift, the tool is required."

This was a real source of false positives in prior runs: 3 of 11 Pass D drifts in the resend.com clone were false-negatives caused by `grep -P` locale errors that the sub-agent didn't notice.

**When to skip Pass D**: never. Even if Pass A/B/C are clean, run Pass D once — the cost is one sub-agent call, the upside is catching the class of drifts that the implementer is structurally blind to (hallucinations, regressions). The only legitimate skip is when you genuinely can't spawn an Agent (rare).

### Pass E — Drift report + lessons append (only after all passes)

After Passes A-D all converge or hit cap, produce a written report:

```
Iteration 1 → 2 progression:
  Fixed: stat counters now read 200+/300+/30 instead of 0+/0+/0
  Fixed: hero is now <video> with poster fallback
  Fixed (from Pass D): footer social icon container shape (square not circle)
  Still drifting: testimonial widget content (not capturable from source)

Pass results:
  A (sanity):   clean
  B (computed): 0 entries in style-diff.json
  C (visual):   converged at iter 2
  D (adversarial): 1 drift found and fixed; second pass clean

Final drift list (known limitations):
  - Why Us icons substituted with generic Lucide — source uses Elementor brand icons, asset URLs not resolvable
  - Testimonials section: 8 reviews in source, mine shows 3 placeholders — Google review widget renders empty in static capture

No drift detected on:
  - Color palette, typography, section order, form fields, footer layout
```

**Then append to lessons.md.** For each drift surfaced and fixed during this iteration (especially the ones found by Pass D), append an entry to `{workspace}/lessons.md` using the format from the top-of-file lessons section. Lessons that recur across iterations indicate a structural skill gap — flag them in the report and consider whether SKILL.md itself needs updating.

The contract: **if you finish Phase 5 without running all five passes (A–E), you are not done.** A clone that has only been self-verified is still a guess — Pass D is what makes it a verified clone.

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

1. **List of files created/modified** with paths (including `_source/`, `_assets/`, `tokens.json`, `assets.json`, `embeds.json`, `section-map.json`, `section-evidence.json`)
2. **Phase 5 pass results** — one line per pass (A: clean / B: 0 entries in style-diff / C: converged at iter 2 / D: 1 drift found and fixed / E: lessons appended)
3. **Known limitations** (e.g. "couldn't match the parallax effect — needs a JS library the project doesn't have")
4. **Lessons appended to `{workspace}/lessons.md`** — one-line summary of each new lesson; this is what makes future iterations of this clone target sharper
5. **Suggested next steps** if any (e.g. "you may want to extract the button styles into a reusable component once you have 2-3 instances")

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

Or run the bundled setup script: `~/.claude/skills/clone-ui/scripts/install-chrome-devtools-mcp.ps1` (Windows) / `.sh` (Unix). The script appends the config without overwriting existing `mcpServers` entries.
