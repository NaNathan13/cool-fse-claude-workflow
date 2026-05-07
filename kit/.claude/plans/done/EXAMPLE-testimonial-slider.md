# EXAMPLE — Testimonial Slider Block

> _This is a reference plan shipped with the kit. Skim it once to see what a finished plan looks like — TL;DR, decisions, files, approach, verification, Forge handoff line, Temper Report, Seal section. Delete it whenever (`rm .claude/plans/done/EXAMPLE-*.md`)._

**Status:** done
**Lane:** standard
**Source:** Grill session 2026-04-12

## TL;DR

A new `testimonial-slider` block for the homepage and About page. Editors add quotes via an ACF repeater; visitors see a swipeable slider that auto-rotates every 6s and pauses on hover. Builds on the existing `<ada-slider>` custom element so we don't reinvent slider mechanics.

## What We're Building

**Editor POV:** Adds a "Testimonial Slider" block. Configures a wrapper width (default / small) and an ACF repeater of testimonials — each with quote text, author name, author role, optional headshot.

**Visitor POV:** A horizontally-swipeable slider showing one testimonial at a time. Auto-rotates every 6 seconds; pauses while hovered or focused. Dot pagination underneath. Quote uses the brand accent font; meta uses the body font.

## Design Decisions

1. **`<ada-slider>` over a hand-rolled slider** — it's the established custom element; gives us swipe, keyboard nav, and reduced-motion handling for free.
2. **ACF repeater, not inner blocks** — testimonials are flat data, not composable; repeater is simpler for editors.
3. **One block, two placements** — same block dropped on `/` and `/about/`; no layout variants needed yet.
4. **6s auto-rotate, hover/focus pause** — matches the existing hero slider's cadence so the site feels coherent.
5. **No standalone CSS file** — wrapper, typography, and spacing all covered by existing utility classes (`flex`, `gap-32`, `text-center`, `font-accent`).

## Approval Gates (pre-approved)

- ACF JSON hand-edits — adding a new field group `group_testimonial_slider` to `<child-theme>/acf-json/`.

_(No `cool-fse/` edits, no new block CSS, no FSE template changes.)_

## Files to Create / Modify

**Create:**
- [x] `<child-theme>/blocks/gutenberg/testimonial-slider/testimonial-slider-block.json`
- [x] `<child-theme>/blocks/gutenberg/testimonial-slider/testimonial-slider.php`
- [x] `<child-theme>/blocks/gutenberg/testimonial-slider/testimonial-slider.js`
- [x] `<child-theme>/acf-json/group_testimonial_slider.json`

**Modify:**
- _(none — block is dropped into pages via the editor; no template edits)_

## Approach

**`testimonial-slider-block.json`** — Standard cool-fse block JSON. `"name": "acf/testimonial-slider"`, `"category": "cool-fse"`, `"acf": { "mode": "preview", "renderTemplate": "testimonial-slider.php" }`, `"style": ["cool-fse-css"]`, `"script": "cool-fse-js"`. Icon: `format-quote`.

**`testimonial-slider.php`** — Root element uses `get_block_attributes()` with class `testimonial-slider`. Inside, `<ada-slider autoplay="6000" pause-on-hover>` wrapping a loop of testimonials. Each slide: `<blockquote class="text-center">` with the quote, then `<footer class="flex gap-16 items-center justify-center">` with optional headshot (`esc_url` on `src`, `esc_attr` on `alt`) + author name + role. Use `acf_to_css_var()` on the root for any wrapper-padding overrides. Sub-block calls via `block('...')` — none needed here.

**`testimonial-slider.js`** — Empty file. `<ada-slider>` handles all interactivity. File exists so the auto-bundler picks it up; placeholder comment noting why.

**`group_testimonial_slider.json`** — ACF field group. Repeater field key `field_testimonial_items` with subfields: `field_quote` (wysiwyg), `field_author_name` (text), `field_author_role` (text), `field_author_image` (image, return = array). Wrapper-width field via the standard `wrapper_width` clone field used by every block.

## Visual Reference

- `.claude/screenshots/testimonial-slider/reference-homepage-comp.png` (Figma export)
- Existing analogue: `cool-fse/blocks/gutenberg/media-collage-cta` for the swipeable-row pattern

## Out of Scope

- Per-testimonial background colors (might come in a v2)
- Video testimonials (not in this pass)
- Server-side caching of headshot images

## Verification

- Visit `http://my-site.local/about/` — slider renders with all testimonials, auto-rotates.
- Hover the slider — rotation pauses. Move mouse away — rotation resumes.
- Tab into the slider — focus visible, arrow keys navigate.
- Resize to 375px wide — slider stays single-column, swipe works.
- Playwright screenshots: `desktop-default.png`, `desktop-hover-paused.png`, `mobile-default.png`, `mobile-swipe-mid.png`.

---

**Forge complete 2026-04-13.** Ready for Temper.

## Temper Report — 2026-04-13

**Summary:** Block ships clean. Markup matches the cool-fse PHP pattern; ACF JSON is consistent with neighboring groups; visual matches the comp on both breakpoints. One suggested utility-class swap and two nits.

**Counts:** 0 blocking, 1 suggested, 2 nits, 1 a11y suggestion.

### Blocking
_None._

### Suggested
1. **`testimonial-slider.php:14`** — `style="margin-top: var(--wp--preset--spacing--40);"` should be the utility class `mt-40` on the wrapper. Inline style is redundant when a utility exists.

### Nits
1. **`testimonial-slider.php:22`** — extra blank line inside `<footer>`.
2. **`group_testimonial_slider.json`** — `field_author_role` label is "Author role" (sentence case); the rest of the project uses Title Case ("Author Role") on field labels.

### Accessibility — suggestions only
1. **`testimonial-slider.php:18`** — `<blockquote>` has no associated cite. If author name is the source, wrap the `<footer>` in `<cite>` so screen readers announce attribution.

### Visual review
- Screenshots: `.claude/screenshots/testimonial-slider/temper-*.png`
- All four states render as expected. No regressions on adjacent page sections.

### CSS → Utility Class Replacements
1. `testimonial-slider.php:14` — replace inline `margin-top: var(--wp--preset--spacing--40);` with `mt-40` utility on the root element.

## Seal — 2026-04-13

Commit message drafted (see session output). Plan archived.
