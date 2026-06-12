# docs/DESIGN.md · commons design system contributor guide

All HTML pages deployed to the Common Information System must adhere to this
specification. The canonical reference is `design-system.html` at the repo root.
The shared stylesheet is `commons.css`. This document is the protocol for both
human contributors and agents.

---

## Quick start

Every new page begins with:

```html
<!DOCTYPE html>
<html lang="en" data-mode="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Page title · commons</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="commons.css">
<style>
/* page-specific styles only */
</style>
</head>
```

The `commons.css` link provides: all design tokens, base reset, shared components
(`.rule`, `.prov`, `.chip-*` flat variants, `.mode-btn`, `.site-nav`, `footer`),
and the Google Fonts import.

---

## Design tokens

All values live in `commons.css` as CSS custom properties. Never hard-code colors,
spacing, or font stacks in page styles — always reference the token.

### Ground palette (dark ground state)

```
--bg             #0f0f0f    page background
--surface        #1a1a1a    cards, panels, inset surfaces
--surface-raised #232220    elevated elements (tooltips, modals)
--border         #333333    standard dividers
--border-strong  #4a4a4a    prominent dividers, table headers
```

### Accent

```
--terra          #c4956a    fill, borders — decorative only
--terra-text     #c4956a    text on dark / #96704a on light
--terra-dim      rgba(196,149,106,0.12)   tinted backgrounds
--terra-glow     rgba(196,149,106,0.06)   subtle washes
```

Terracotta is the only decorative hue. It marks active state, accent borders, and
brand elements. It is not a semantic color — do not use it to mean "warning."

### Text ramp

```
--heading        #e8e0d8    titles and labels
--text           #d4d4d4    body copy
--muted          #999999    secondary, captions
--faint          #666666    tertiary, placeholders
```

### State (instrument surfaces only)

```
--ok             #94ae84    verified, done, healthy
--ok-dim         rgba(148,174,132,0.14)
--info           #8da3b5    in-progress, informational
--info-dim       rgba(141,163,181,0.14)
--warn           #c0705c    blocked, needs attention, critical
--warn-dim       rgba(192,112,92,0.14)
```

State colors appear only on instrument surfaces (HUD, Loop, dashboards). They do
not appear in document grammar pages (PRDs, decision briefs, specifications).

**No alarm red.** There is no `--crit` in this system. The `--crit` token is a
backward-compat alias that resolves to `--warn` (clay). If a surface needs to
signal danger, use `--warn` with a clear label.

### Spacing scale

```
--s1: 4px   --s2: 8px   --s3: 12px  --s4: 16px
--s5: 24px  --s6: 32px  --s7: 48px  --s8: 64px
```

Use the scale tokens. Do not use arbitrary pixel values for spacing.

### Motion

```
--dur-mode:  400ms   color-mode transitions
--dur-micro: 160ms   hover/interactive transitions
--ease:      cubic-bezier(0.4, 0, 0.2, 1)
```

### Light mode

The `:root` defines dark as the ground state. Light mode is applied by either:
- `[data-mode="light"]` (explicit toggle)
- `@media (prefers-color-scheme: light)` (system preference, only when
  `data-mode` is not set to `dark`)

All token overrides for light mode are in `commons.css`. Pages do not need to
define their own light-mode values.

---

## Typography

Two typefaces only. No third face.

```
--font-serif: 'Libre Baskerville', Georgia, serif
--font-mono:  'IBM Plex Mono', ui-monospace, monospace
--font-sans:  'IBM Plex Mono', ui-monospace, monospace  (no sans — resolves to mono)
```

**Libre Baskerville** (serif) is for reading: body copy, headings, document
grammar pages. Its slight warmth and editorial weight carry authority without
formality.

**IBM Plex Mono** (mono) is for everything technical: IDs, tokens, labels,
figures, metadata, instrument surfaces. When something needs to be precise,
scannable, or tabular, use mono.

`--font-sans` is defined as an alias for mono. There is no third typeface. If a
page inherits `font-family: var(--font-sans)` from an older codebase, it resolves
correctly.

---

## Layout grammars

Two distinct surface types, each with its own grammar. Never mix them on a single
page.

### Document grammar

Reading surfaces: PRDs, decision briefs, the index page, specifications.

- `body` defaults to serif, 16px, line-height 1.85
- `.page` provides the reading measure: `max-width: 720px; margin: 0 auto`
- `.site-nav` at the top; `.rule` dividers between sections
- Headings: Libre Baskerville, weight 700, warm `--heading` color
- Labels and captions: IBM Plex Mono, uppercase, `--terra-text` or `--faint`
- No state chips in document grammar — status is conveyed through text

### Instrument grammar

Watching surfaces: HUD, Loop, dashboards, live data panels.

- `body` overrides to mono, 14px base, line-height 1.6
- Compact topbar (`.topbar`) with status chips rather than the document nav
- Dense information layout: tiles, tables, status panels, progress bars
- State chips (`--ok`, `--info`, `--warn`) are appropriate here
- Figure values in `font-variant-numeric: tabular-nums`

---

## Shared components

### `.rule`

A terracotta fading divider. Add `margin` in the page's own styles.

```html
<div class="rule"></div>
```

### `.chip-*` flat variants

For instrument surfaces. No base `.chip` class is defined in `commons.css` — pages
define their own base chip shape.

```html
<span class="chip chip-ok">verified</span>
<span class="chip chip-warn">blocked</span>
<span class="chip chip-info">in progress</span>
<span class="chip chip-muted">pending</span>
<span class="chip chip-terra">in progress</span>
```

### `.prov` (provenance chip)

Shows the authority for a figure or rule. Required for any data claim on an
instrument surface.

```html
<span class="prov">
  <span class="cite">grant:§4</span>
  <span class="sep">·</span>
  KPI threshold
</span>
```

### `.mode-btn`

Base styles for the dark/light toggle. Add `position: fixed` and coordinates in
the page's own styles.

```html
<button class="mode-btn" id="modeBtn">light</button>
```

### `.site-nav` (document grammar)

Sticky navigation bar. Use `.nav-brand` for the wordmark, `.nav-links` for the
link list.

```html
<nav class="site-nav">
  <div class="site-nav-inner">
    <a class="nav-brand" href="index.html">CIS · Commons</a>
    <ul class="nav-links">
      <li><a href="#section">Section</a></li>
      <li><a href="hud.html">HUD</a></li>
      <li><a href="design-system.html">Design</a></li>
    </ul>
  </div>
</nav>
```

---

## Voice

The voice is part of the design. An artifact with the right colors and the wrong
voice is off-brand.

**Tone:** Quiet, precise, grounded. Unhurried. Editorial. Slightly etymological.
Lead with the word. Never shout and never sell.

**Do:**
- Use the etymology move where it adds meaning
- Name authority explicitly ("per AGENTS.md §7," "per draft-bylaws:§2.4")
- Be honest about what is not yet known
- Write for members who are doing real work, not for users consuming a product

**Do not:**
- Use urgency language or alarm framing ("critical error," "danger zone")
- Use marketing superlatives ("powerful," "seamless," "best-in-class")
- Address the reader as "you" in governance documents (use "the member," "the organizer")
- Use red — it communicates panic, which this system does not produce

---

## Checklist for new pages

Before merging a new page:

- [ ] `<link rel="stylesheet" href="commons.css">` in `<head>`
- [ ] `<html lang="en" data-mode="dark">` on the root element
- [ ] No inline `:root { }` token block (tokens come from commons.css)
- [ ] No hard-coded color values — all values reference `--` custom properties
- [ ] No third typeface
- [ ] No `--crit` in new code (use `--warn`)
- [ ] Light mode toggled via `data-mode` attribute only (no separate dark class)
- [ ] State colors (`--ok`, `--info`, `--warn`) absent from document grammar pages
- [ ] Page follows one layout grammar (document or instrument), not both
- [ ] Voice consistent with tone guidelines above

---

## Backward-compat aliases

Older pages used `--surface-2` or `--surface2` (resolves to `--surface-raised`)
and `--crit` / `--crit-dim` (resolves to `--warn` / `--warn-dim`). These aliases
are defined in `commons.css` and will continue to work. New code should use the
canonical names.

---

*Maintained by agents under human review. Changes to this document require the same
review as changes to `commons.css`. The canonical design specification is
`design-system.html` — if this document and the reference disagree, the reference
wins.*
