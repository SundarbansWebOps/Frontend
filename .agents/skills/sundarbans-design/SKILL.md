---
name: sundarbans-design
description: The Sundarbans House design system and how to change the site's look without breaking it. Use before any change to how the site looks — a .vue template or style, CSS, layout, colour, motion, or a new page or component.
---

# Sundarbans design

The site is warm paper, ink and marigold, set in Anek Latin, with hand-painted _pat_ (patachitra)
art and bespoke motion. Every new piece is built from what already exists: **reuse** first, and take
every value from the **tokens**. A change that looks like a generic template or a different website
is a design break, even if it works.

**Hard limits.** Keep these as they are: `src/assets/tokens.css`, the font link in `index.html`,
`scripts/design-baseline.json` and `package.json` dependencies. If the change needs a new colour,
token, typeface, breakpoint or library, stop and ask Raja.

## 1. Find the nearest existing piece

Before writing anything, find the page or component in `src/pages/` or `src/components/site/` that is
closest to what you are building, and read it fully. Copy its structure, class names and CSS, then
change the content. Done when you can name the file you are copying from.

Page skeleton (from `src/pages/TeamsPage.vue`): `<main class="wrap">` → `<header class="head rise">`
with the `<h1>` → `<section class="sec">` blocks, each with `<h2 class="sec-h"><span
class="mono">01</span> Title</h2>` and a `<p class="sec-sub">`.

## 2. Build it with the system

Use only the values in the reference below. Components are `<script setup>` with `<style scoped>`.

## 3. Check

```bash
npm run check:design
npm run format
npm run lint
npm run build
npm run shots
```

The first time, run `npx playwright install chromium` so `shots` has a browser.

Done when all five pass. `check:design` and `shots` print what is wrong and where; fix it and rerun.
`npm run shots` saves every page in light and dark, desktop and phone, to `test-results/shots/`.
Open the shots of the pages you changed and compare them with the live site. Done when the new part
looks like it was always there, in both themes and at both widths. In full-page shots the phone tab
bar appears mid-page; that is expected.

## 4. Show the person

Give the person the paths of the changed pages' screenshots, or run `npm run dev` for them. Attach
those screenshots to the pull request.

---

## Reference

### Colour: tokens only

Write colours as `var(--token)`. `npm run check:design` rejects hex, `rgb()`, `hsl()` and named
colours. Each token has a light and a dark value, so a component built from tokens works in both
themes.

| Token                                   | Use                                                          |
| --------------------------------------- | ------------------------------------------------------------ |
| `--paper`, `--sunk`, `--card`           | page background, recessed areas, raised cards                |
| `--ink`, `--ink-2`, `--ink-3`           | main text, secondary text, quiet labels                      |
| `--line`, `--line-strong`               | borders and dividers (decorative, never text)                |
| `--mari`, `--mari-soft`, `--mari-ink`   | marigold accent fill, soft wash, marigold as text or outline |
| `--on-mari`                             | text on a `--mari` fill, in both themes                      |
| `--verm`, `--verm-soft`                 | vermilion: urgent, countdowns, errors                        |
| `--w-cultural`, `--w-games`, `--w-tech` | event wings; set with the class `.w-cultural` etc. and use   |
| `--w-talks`, `--w-meetups`              | `var(--w)` inside the component                              |
| `--shadow`                              | the one card shadow                                          |

The palette has no green. Text on marigold is always `--on-mari`. The Home page (Pat scroll) keeps
its painted colours in both themes; leave them as they are.

### Type

- One typeface: `var(--font)` (Anek Latin). `var(--mono)`, or the global `.mono` class, for codes,
  numbers, dates and section numbers.
- Page title `h1`: `clamp(34px, 4.4vw, 48px)`, weight 750, `letter-spacing: -0.04em`,
  `line-height: 0.95`.
- Section title `.sec-h`: `clamp(24px, 2.6vw, 30px)`, weight 750, `letter-spacing: -0.035em`.
- Body 14–15px (`--ink-2` for supporting text, `max-width: 62ch`); labels 12–13px; tiny caps labels
  10.5–11px, uppercase, `letter-spacing: 0.08em`–`0.14em`.
- Weights 500–750. Numbers that change use `font-variant-numeric: tabular-nums`.

### Shape and layout

- Page container: `max-width: 1240px; margin: 0 auto; padding: 18px 24px 80px;` and on phones
  (`max-width: 560px`) `padding: 14px 16px 90px`.
- Grids use `minmax(0, 1fr)`, never a bare `1fr`: long content inside a bare `1fr` pushes the layout
  off-screen on phones.
- Pills and chips `border-radius: 99px`; dots and avatars `50%`; cards `var(--r)` (14px) or 12px.
- Breakpoints: `560`, `640`, `760`, `860`, `900`, `1020` px (max-width). Pick the nearest.
- Section spacing: `.sec { padding-top: 34px }`, `.sec + .sec { margin-top: 26px; border-top: 1px
solid var(--line) }`.

### Motion

- Entrance: add `class="rise"` with `style="--i: 0"`, `1`, `2`… for a stagger. No loaders or
  spinners.
- Easing: `var(--ease-out)` for movement, `var(--ease-spring)` for playful pops. Durations
  0.2–0.5s for hover and state changes.
- CSS motion is switched off for reduced motion by `tokens.css`. JavaScript animation checks
  `matchMedia('(prefers-reduced-motion: reduce)')` and jumps to the end state (see `TeamsPage.vue`).

### Imagery

- Art is hand-painted pat plates from `src/assets/pat/`, reused as they are. People's photos are real
  portraits. No stock photos, emoji or icon packs; small icons come from
  `src/components/site/LineIcon.vue`.
- Display images are hosted on Cloudinary (see `CONTRIBUTING.md`), not committed.

### Accessibility

- Every `<section>` has `aria-labelledby` pointing at its heading.
- Icon-only buttons carry a `<span class="visually-hidden">` label.
- Focus rings come from the global `:focus-visible` rule; keep it visible.

### Vue gotchas

- Dark-mode overrides are written `:root[data-theme='dark'] .thing { … }`. `:global(.a) .b` compiles
  to `.a` alone.
- A class a parent puts on a child component's root also receives the parent's scoped styles.
