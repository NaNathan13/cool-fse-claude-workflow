# Utility Classes — Quick Reference

**Always-available cheat-sheet of every cool-fse CSS utility class.** Read this during
Ponder/Inscribe (to plan the utility-vs-bespoke CSS split) and during Forge (to apply classes
in markup) instead of grepping the CSS. **Utilities-first is a non-negotiable — exhaust this
list before writing any block CSS.**

> **Source & refresh:** generated from `cool-fse/blocks/global/css/*.css`,
> `{{CHILD_THEME_DIR}}/blocks/global/css/*.css`, and the color generator
> `cool-fse/features/_front/create-additional-utility-classes-from-theme-json.php` (palette
> slugs from `{{CHILD_THEME_DIR}}/theme.json`). It is a point-in-time digest — **the live CSS
> wins.** The utility tables below are project-agnostic (identical on every cool-fse site); the
> **"Generated color utilities" + "Semantic tokens" sections are PROJECT-SPECIFIC** and must be
> filled from this project's `theme.json` palette (see the note in that section). When cool-fse
> utilities or this theme's palette change, regenerate (ask Claude to re-read those dirs and
> rebuild this file). **`setup.sh` overwrites this file on install/update**, so re-fill the
> project-specific palette/token sections after an update. Admin source-of-truth dump: the
> `/_dev-tools/utility-classes` route (login required).

## How to use
- **Utilities-first.** Compose layout/spacing/color by applying these classes in PHP markup (`class="..."`); writing new block CSS is an approval gate. Only `@keyframes`, bespoke shapes, and offsets the grid can't express belong in a `.css` file.
- **Breakpoints (col-*, row-grids):** `xs` = all widths · `sm` ≥769px · `md` ≥993px · `lg` ≥1201px (min-width, mobile-first). The generic `@media` mobile cutoff used by `mobile:`/`tablet:`/`desktop-only` is **768px** (tablet prefix = ≤1024px).
- **Prefixes:** `mobile:` (≤768px) on spacing + col-span; `tablet:` (≤1024px) + `mobile:` (≤768px) on `.col-span-*`; `sm:` (≤768px) on `.cols-*`; `hover:`/`focus:` on scale/opacity/outline/underline; show/hide via `.mobile-only`/`.desktop-only`/etc.
- **Color:** prefer semantic vars `--color-primary | --color-secondary | --color-accent`, or palette utilities `.text-<slug>` / `.bg-<slug>` (see Generated section). **Fonts:** `--font-family-main` / `--font-family-accent` (`.font-family-main` / `.font-family-accent`, child aliases `.font-main` / `.font-accent` / `.font-accent-2`).
- Escaped `\:` in source = literal `:` in markup (write `class="hover:opacity-5"`, `class="mobile:mt-0"`).

---

### display-helpers.css
`.block` `.inline` `.inline-block` `.flex` `.inline-flex` `.grid` `.none` → corresponding `display` value.

### flex-utilities.css
| Class | Effect |
|---|---|
| `.flex-1` | `flex:1` |
| `.flex-shrink-0` | `flex-shrink:0` |
| `.flex-row` / `.flex-column` | `flex-direction` |
| `.flex-wrap` / `.flex-nowrap` | `flex-wrap` |
| `.align-start\|center\|end` | `align-items: flex-start\|center\|flex-end` |
| `.justify-start\|center\|end` | `justify-content: flex-start\|center\|flex-end` |
| `.justify-between` / `.space-between` | `space-between` |
| `.justify-around` | `space-around` |
| `.flex-center` | `display:flex; justify+align center` |
| `.gap-0 … .gap-20` | `gap`, step 0.25rem: gap-N = N×0.25rem (gap-4=1rem, gap-8=2rem, gap-20=5rem) |

### row-column-grids.css (Flexbox grid)
- `.row` — flex row, wrap; gutters via `--gap` (default 16px), mobile via `--mobile-gap`; `row-gap:var(--gap)`.
- `.col` — horizontal padding = half gap.
- `.row.reverse` row-reverse · `.col.reverse` column-reverse · `.row--reverse-mobile` (≤768px) row-reverse (column-reverse if it `:has(.col-xs-12)`).
- **`.col-{bp}-{1..12}`** → `flex-basis`/`max-width` = N/12 (1=8.333% … 6=50% … 12=100%). bp = `xs`(all) `sm`(≥769) `md`(≥993) `lg`(≥1201). `.col-{bp}` (no number) = flex-grow:1.
- **`.col-{bp}-offset-{1..11}`** → `margin-left` = N/12.
- **Per-bp align/justify:** `.start-{bp}` `.center-{bp}` `.end-{bp}` (justify + text-align), `.top-{bp}` `.middle-{bp}` `.bottom-{bp}` (align-items), `.around-{bp}` `.between-{bp}` (justify space-around/between), `.first-{bp}` (order:-1) `.last-{bp}` (order:1).
- Specials: `.col-xxs-6` / `.col-xxs-12` (≤500px → 50% / 100%), `.col-xl-4` (≥1600px → 33%), `.col-lg-20-percent` (≥1201px → 20%).

### grid-col-helpers.css (CSS Grid)
- `.twelve-col-grid` → `display:grid; grid-template-columns:repeat(12,1fr)`.
- `.col-span-{1..12}` → `grid-column: span N`. Prefixed: `.tablet:col-span-{1..12}` (≤1024px), `.mobile:col-span-{1..12}` (≤768px).

### spacing-utilities.css
- Scale (rem): `0`=0, `1`=.25, `2`=.5, `3`=.75, `4`=1, `5`=1.25, `6`=1.5, `8`=2, `12`=3, `16`=4, `20`=5, `24`=6, `28`=7, `32`=8, `36`=9, `40`=10, `48`=12, `56`=14, `64`=16. (Only listed steps exist — no `.m-7`, etc.)
- **Margin:** `.m-{n}` `.mt-/.mb-/.ml-/.mr-{n}`. **Padding:** `.p-{n}` `.pt-/.pb-/.pl-/.pr-{n}`.
- Auto: `.m-auto` `.mx-auto` `.my-auto` `.ml-auto` `.mr-auto` `.mt-auto` `.mb-auto`.
- **Mobile prefix (≤768px):** `.mobile:m-{n}` / `.mobile:p-{n}` + all sides + `.mobile:mx-auto` etc.

### sizing-utilities.css
`.w-100` `.h-100` (100%), `.w-auto` `.h-auto`, `.w-100vw` `.h-100vh`, `.max-w-full`/`.max-w-100` `.max-h-full`/`.max-h-100` `.min-w-full`/`.min-w-100` `.min-h-full`/`.min-h-100`. Fixed: `.w-{1,2,3,4,6,8}` / `.h-{1,2,3,4,6,8}` = .25/.5/.75/1/1.5/2 rem.

### positioning-utilities.css
- `.static` `.relative` `.absolute` `.fixed` `.sticky`.
- Offsets: `.t-0 .r-0 .b-0 .l-0` (0); `.t-100 .r-100 .b-100 .l-100` (100%).
- `.z-{0..5}`; `.z-high`(21474836) `.z-very-high`(214748364) `.z-max`(2147483646) `.z-max-1`(2147483647).
- `.absolute-center` (abs + translate -50%), `.absolute-top-right` (top/right 0 + translate 50%,-50%), `.fill-parent` (abs, top/left 0, 100%×100%, z-1).

### text-helpers.css
- `.text-right` `.text-left` `.text-center` (+ `.has-text-align-*` aliases).
- `.text-nowrap`/`.nowrap`/`.no-wrap` (nowrap), `.white-space-pre-line`, `.white-space-pre`.
- `.text-overflow-ellipsis`/`-ellipse` (ellipsis + overflow hidden), `.text-wrap-balance`, `.text-wrap-pretty`.
- `.letter-spacing-{xs|sm|md|lg|xl|2xl}` = -0.05 / -0.01 / 0 / 0.05 / 0.1 / 0.25 em.

### image-text-utilities.css
`img.aligncenter` (auto margins), `.object-fit-contain` `.object-fit-cover`, `.uppercase`, `.text-transform-none`, `.brightness-{1..9}` = `filter:brightness(0.1 … 0.9)`.

### font-families.css
`.font-family-main` (`--font-family-main`), `.font-family-accent` (`--font-family-accent`), `.font-family-mono` (monospace). *(child global.css commonly adds `.font-main`, `.font-accent`, `.font-accent-2`.)*

### border-utilities.css
- `.br-{0,1,2,3,4,5,6,8,10,12}` border-radius = 0/.25/.5/.75/1/1.25/1.5/2/2.5/3 rem; `.br-50` (50%).
- `.border-solid`; `.border-{1..5}` border-width 1–5px; side widths `.border-top-1` `.border-right-1` `.border-bottom-1` `.border-left-1` (+ `-2`).
- Radius-zeroing: `.border-{top|bottom|left|right}-radius-0` (pair), and per-corner `.border-{top|bottom}-{right|left}-radius-0`.

### background-utilities.css
`.bg-cover` `.bg-contain` `.bg-auto`; `.bg-center` `.bg-top` `.bg-bottom` `.bg-left` `.bg-right`; `.bg-no-repeat` `.bg-repeat` `.bg-repeat-x` `.bg-repeat-y` `.bg-repeat-round` `.bg-repeat-space`. *(`.bg-<colorslug>` is generated separately — see Generated section.)*

### blend-mode-background.css
`.is-style-background-blend-{multiply|screen|overlay|darken|lighten|color-dodge|color-burn|hard-light|soft-light}` → `background-blend-mode`.

### cursor-utilities.css
`.cursor-{auto|pointer|grab|wait|move|not-allowed|text|crosshair|help}`.

### overflow-helpers.css
`.overflow-{auto|hidden|visible|scroll}` and `.overflow-x-*` / `.overflow-y-*` (same 4 values).

### show-hide-helpers.css
| Class | Hidden when |
|---|---|
| `.huge-screen-only` | ≤1200px |
| `.large-screen-only` | ≤1024px |
| `.desktop-only` | ≤768px |
| `.mobile-only` | ≥769px |
| `.medium-screen-up-only` | ≤992px |
| `.medium-screen-down-only` | ≥993px |
`.visually-hidden` / `.sr-only` → a11y-hidden (clip, 1px).

### order-utilities.css
`.order-{1..6}` → `order`. `.list-style-none` → `list-style:none`.

### column-count-utilities.css
`.cols-{1..12}` → `columns:N`. Mobile (≤768px): `.sm:cols-{1..12}`.

### aspect-ratio.css
`.aspect-ratio-21-9` `.aspect-ratio-16-9` `.aspect-ratio-4-3` `.aspect-ratio-3-4` `.aspect-ratio-1` (1:1).

### block-gap-helpers.css
`.block-gap--{xs|s|m|l|xl}` → `display:flex; flex-flow:column; gap:` spacing preset 20/30/40/50/60 (`--wp--preset--spacing--NN`).

### transition-utilities.css
Timing: `.ease-in` `.ease-out` `.ease-in-out` `.linear`. Duration: `.duration-{75,100,150,200,250,300,500,700,1000}` ms.

### hover-focus-animations.css
- `.hover:scale-1` / `.focus:scale-1` → `scale(1.1)` on hover/focus. `.hover:scale-child` / `.focus:scale-child` → scales descendant on parent hover.
- `.hover:underline` `.hover:no-underline`, `.hover:fade` (opacity .65), `.hover:animated-underline` (sliding underline; `--animated-underline-color` default black, `--animated-underline-height` 1px), `.hover:outline` (1px solid on hover/focus).

### outline-opacity.css
- `.hover:outline-solid` / `.hover:outline` → 1px solid outline on hover/focus. `.outline-0` / `.outline-none`.
- `.outline-offset-{1..5}` px.
- `.outline-black` `.outline-white` `.outline-transparent` (+ source also defines `.outline-red` `.outline-dark-blue` `.outline-light-blue` — only colors in this theme's palette resolve); `.hover:outline-white`.
- `.opacity-{0..9}` = 0/0.1…0.9 (aliases `.opacity-point-1`…`-9`). `.hover:opacity-{0..9}` on hover/focus.

### shape-and-emphasis.css
`.circle` (border-radius 100%), `.strong` (font-weight 700).

### misc-utilities.css
`.highlight` (yellow rgba bg), `.arrow-link` (`→` after, slides on hover), `.pointer-events-none`, `.two-column-list` (columns:2, gap 2rem → 1 col ≤768px).

### layout.css
`.layout` — flex-wrap row; vars `--gap`, `--alignment`(align-items, def center), `--justification`(def center), `--child-width` (child = `calc(var(--child-width) - var(--gap))`), `--mobile-child-width` & `--mobile-flex-wrap` (≤768px), children → 100% ≤320px.

### wrapper.css (content-width containers)
`.wrapper` — `max-width:var(--max-width, --default-wrapper-width)`; mobile `--mobile-max-width`/`--mobile-margin`. `.wrapper.wrapper--default` / `.wrapper.wrapper--small` (widths set in child `global.css`). **Note:** the wrapper is normally applied by `get_wrapper_attributes()` — don't pass a width class yourself (see CONVENTIONS "Respect the wrapper").

---

### Generated color utilities (from theme.json `color.palette.theme`)
`features/_front/create-additional-utility-classes-from-theme-json.php` injects a `<style>` into `wp_head`/`admin_head`. For **every** palette slug it emits:
- `:root` var → `--color-<slug>: var(--wp--preset--color--<slug>)`
- `.text-<slug>` → `color: var(--color-<slug>)`
- `.bg-<slug>` → `background-color: var(--color-<slug>)`
- `.hover:text-<slug>` / `.hover:bg-<slug>` (on `:hover,:focus`)
- legacy `.hover:has-<slug>-color` / `.hover:has-<slug>-background-color`

> **PROJECT-SPECIFIC — fill this in from `{{CHILD_THEME_DIR}}/theme.json`.** List this site's
> actual palette slugs so the real class names are visible at a glance, e.g.:
>
> | slug | hex |
> |---|---|
> | `black` | #… |
> | `white` | #… |
> | `gold` | #… |
>
> → e.g. `.text-gold`, `.bg-black`, `.hover:text-gold`, var `--color-<slug>`.

### Semantic tokens (child global.css)
> **PROJECT-SPECIFIC — fill from `{{CHILD_THEME_DIR}}/blocks/global/css/global.css`.** Typically
> `--color-primary` / `--color-secondary` / `--color-accent` mapped to palette slugs, and
> `--font-family-main` / `--font-family-accent` / `--font-family-accent-2` (`.font-main` /
> `.font-accent` / `.font-accent-2`).

### Child-added utilities
> **PROJECT-SPECIFIC — fill from `{{CHILD_THEME_DIR}}/blocks/global/css/utilities.css`** if the
> child theme adds any (e.g. extra column-list helpers, text-shadow utilities).

---
**Excluded (not utilities):** base.css, zz_reset.css, slick-slider.css, woocommerce.css, typography.css, button.css, loader.css, pagination.css, wp-fixes.css, wp-wysiwyg-inline.css, rich-text-helpers.css, z_acf-style-vars.css — resets, element/component styles, or ACF-var plumbing.

**Caveats:** spacing/border/sizing scales are sparse — only listed numbers exist. Some `outline-*` color utilities reference slugs that may not be in this theme's palette (dead until added).
