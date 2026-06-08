# Conventions

cool-fse coding standards. Single source of truth — Forge builds to this, Temper audits
against it. Project-agnostic: true for any child theme on the cool-fse parent.

> **The live codebase wins.** `cool-fse/blocks/global/css/` and
> `cool-fse/blocks/global/js/custom-elements/` are the real source of truth for what
> exists. Read the directories before assuming a class or element does or doesn't exist.

## Non-negotiables

The rules broken most often. Each is detailed in its section below.

1. **Reuse before building.** Search cool-fse first; mirror the existing pattern. Don't reinvent, don't be clever.
2. **Never touch the wrapper.** Standard handling only; never override `acf-style-vars` or fake padding/width.
3. **Utility-class first.** Exhaust `blocks/global/css/` before writing block CSS — new block CSS is an approval gate.
4. **Layout = `.row` / `.col`.** Never hand-roll `display:flex` / `grid-template` for a layout.
5. **Semantic tokens only.** `var(--color-<slug>)`, `--font-family-main|accent` — never raw hex or `--wp--preset--*` in block CSS.
6. **ACF through helpers.** `img_if()`, `acf_link()`, `block()`, … — never hand-rolled markup. Edit ACF in `acf-json/`, never WP Admin.
7. **Custom element before custom JS.** Check the custom-elements dir before building anything interactive.

## Reuse before you build

The pattern almost always already exists. Find it before writing anything new.

- **Don't reinvent the wheel.** Before any layout, interaction, or helper, search the
  parent: utility classes in `blocks/global/css/`, custom elements in
  `blocks/global/js/custom-elements/`, helpers in `features/_helper-functions/`, and how
  existing `blocks/gutenberg/` blocks solved it. Mirror what's there.
- **Don't be clever.** Simplest approach on the established pattern wins. A bespoke
  flex/grid layout instead of `.row`/`.col`, custom-property gymnastics, a hand-rolled
  slider instead of a custom element — each means the existing tool was skipped.
- **A new abstraction is a smell.** New block CSS, a new helper, or a clever one-liner only
  after confirming nothing in the theme does it — then keep it minimal and match the
  surrounding style.
- **Can't find the pattern? Ask — don't invent your own framework.**

## Themes

- **`cool-fse/`** — parent theme. Framework, global utilities, custom elements, base
  blocks. Modifying it is an approval gate (see `WORKFLOW.md`).
- **`{{CHILD_THEME_DIR}}/`** — child theme. All project work goes here. Mirror a parent
  file's relative path to override it; the autoloader picks it up, no registration.

## Block anatomy

Each Gutenberg block lives in `blocks/gutenberg/<block-name>/`:

| File | Purpose |
|---|---|
| `<name>-block.json` | Registers the block; sets ACF render callback, icon, category |
| `<name>.php` | Render template (HTML output) |
| `<name>.css` | Block-scoped styles (auto-bundled into `public/style.css`) |
| `<name>.js` | Block-scoped JS (auto-bundled into `public/app.js`) |

Block JSON is auto-registered via glob — no manual `register_block_type()`.

## Block PHP boilerplate

Every block follows this exact pattern:

```php
<?php
if (!defined('ABSPATH')) exit;

$field = get_field('field_name');
if (empty($field)) return;

$block_attributes = [
  'class' => 'block-name acf-style-vars',
  'style' => acf_to_css_var()
];
?>
<div <?= get_block_attributes(@$_block_data, $block_attributes) ?>>
  <?= maybe_get_block_video_background() ?>
  <animate-on-scroll <?= get_block_animation_attributes() ?>>
    <div <?= get_wrapper_attributes() ?>>
      <!-- content -->
    </div>
  </animate-on-scroll>
</div>
```

Non-negotiable details:
- `@$_block_data` (with the `@`) is always the first argument to `get_block_attributes()`.
- The root class always includes `acf-style-vars`.
- Short echo tags `<?=` exclusively — never `<?php echo`.
- Escape on output: `esc_html`, `esc_url`, `esc_attr`. Raw echo only for ACF wysiwyg fields.
- No type hints on local variables. Match helper style (`array`/return types only where existing helpers use them).
- Never leave `var_dump`, `print_r`, or `console.log` in.

## Respect the wrapper

Standard wrapper handling, every block: `get_block_attributes()` + `acf-style-vars` on the
root, `get_wrapper_attributes()` on the inner `<div>`. The helpers own padding and width —
keep it that way.

**Never change the parent's default CSS/HTML layout.** Admin settings (padding/width/
alignment) stay consistent only when each block works within the framework. Treat an
apparent exception as a finding to scrutinize, not accept.

- **Never override `acf-style-vars`** to set your own padding/width, and never invent
  per-block wrapper settings to fake `get_wrapper_attributes()`. Overriding the style vars
  breaks parent block settings — red flag.
- One element breaking out (e.g. a full-bleed image): **only that element** ignores the
  padding — size it in JS; the rest of the block keeps obeying the wrapper. Don't re-plumb
  the wrapper for the whole block to serve one element.
- CSS fighting the wrapper width or re-implementing its padding = reinventing standard
  handling. Stop, use the standard pattern.

## Block JSON shape

Content blocks use the full shape:

```json
{
  "name": "acf/block-name",
  "title": "Block Title",
  "description": "What this block does",
  "category": "theme-basics",
  "keywords": ["keyword1", "keyword2"],
  "icon": "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 512 512\">...</svg>",
  "script": "cool-fse-js",
  "style": ["cool-fse-css"],
  "acf": {
    "mode": "preview",
    "renderCallback": "acf_display_gutenberg_block_callback"
  },
  "example": {
    "attributes": { "mode": "preview", "data": { "is_preview": true } }
  },
  "supports": { "inserter": true, "multiple": true, "anchor": true }
}
```

- Always `renderCallback`, never `renderTemplate`. Category `theme-basics`. 2–5 keywords. Font Awesome SVG icon.
- **Structural blocks are the exception.** A header, footer, or other single-use block may set `"inserter": false`, `"multiple": false`, and omit `example` — match the existing structural blocks rather than forcing the content-block shape.

## CSS

### Utility-class first

Exhaust the utility classes in `cool-fse/blocks/global/css/` before writing any block CSS.
New block-level CSS is an approval gate. Apply utilities as classes in the PHP markup.
High-frequency files (read the directory for the rest):

`display-helpers.css`, `flex-utilities.css`, `row-column-grids.css`,
`spacing-utilities.css`, `grid-col-helpers.css`, `show-hide-helpers.css`,
`text-helpers.css`, `sizing-utilities.css`, `positioning-utilities.css`,
`hover-focus-animations.css`, `transition-utilities.css`.

### Layout — compose with `.row` / `.col`

**Never hand-write layout CSS.** cool-fse ships a 12-column responsive flexbox grid
(`row-column-grids.css`) — use it instead of `display:flex` / `grid-template` in a block
CSS file.

- `.row` wraps `.col-<bp>-<n>` children (`<n>` = 1–12), e.g. `col-xs-12 col-md-6` → full
  width on mobile, half from 993px up.
- Breakpoints: **xs** (all) · **sm** ≥769 · **md** ≥993 · **lg** ≥1201px. Mobile is
  unprefixed `col-xs-*`; widen at larger breakpoints.
- On `.row`: align `start|center|end-<bp>`, `top|middle|bottom-<bp>`; distribute
  `around|between-<bp>`; order `first|last-<bp>`, `.reverse`, `.row--reverse-mobile`;
  offset `.col-<bp>-offset-<n>`. Gutter `--gap` (default `1rem`) / `--mobile-gap`.
- CSS-grid alternative: `grid-col-helpers.css` → `.twelve-col-grid` + `.col-span-<n>`
  (with `tablet:` / `mobile:` prefixes).

Hand-rolled `display:flex` / `grid-template` for a layout = skipped grid utility = Temper finding.

### Keep it minimal

Block CSS stays small — ~10–15 lines, not 100+. Every rule justified; if a utility covers
it, delete it. Ballooning = utilities skipped or the block overcomplicated.

- **Split by block.** Each CSS file styles only its own direct elements. Parent block CSS
  in the parent file only; each sub-block/component gets its own CSS file in its own folder.
  Don't pile descendants' styles into one cross-reaching file.
- **Delete-this smells:** `container-type: inline-size` with `cqw`/`cqh` as a roundabout
  `width: 50%`; an inner element reading a parent's `var(--padding-left)` (give it its own);
  a custom property with no mobile counterpart; any CSS re-implementing wrapper width/padding.
- **Bisect test:** comment a heavy file out, re-add only what the live page needs — most
  shed the majority of their rules.

### Naming

`<block-name>` as the root class. Elements: `<block-name>--<element>` (double hyphen).
Modifiers: `<block-name>--<modifier>`. **No double underscores (`__`)** — not standard BEM.

### Responsive

Mobile breakpoint is **768px**, as a media query:

```css
@media (max-width: 768px) { /* mobile rules */ }
```

A `@media` query is the default — there is no general `mobile:` prefix. A limited
`mobile:` / `tablet:` prefix exists only for spacing (`mobile:mt-0`, `spacing-utilities.css`)
and grid col-span (`mobile:col-span-6`, `grid-col-helpers.css`). Show/hide: `.mobile-only` /
`.desktop-only`. Layout must hold at 375px, not merely "not break."

### Tokens — no hardcoded values

Semantic CSS vars only — never raw literals or `--wp--preset--*` in block CSS.

- **Color** → `var(--color-<slug>)`, or the `.text-<slug>` / `.bg-<slug>` /
  `.hover:text-<slug>` / `.hover:bg-<slug>` classes. The parent auto-generates all of these
  from the `theme.json` palette every load
  (`features/_front/create-additional-utility-classes-from-theme-json.php`) — add a palette
  color and they exist. Prefer the class in markup, the var in CSS. Never `--wp--preset--color--*`.
- **Font family** → `var(--font-family-main)` / `var(--font-family-accent)` (parent
  `base.css` `:root`). Never `--wp--preset--font-family--<slug>`.
- **Spacing** → `p-*` / `m-*` / `gap-*` utilities first; `var(--wp--preset--spacing--<slug>)`
  only when a raw value is unavoidable. Block padding/margin come from the wrapper +
  `acf-style-vars`, not hand CSS.

No raw hex, no magic numbers. No `!important` without a comment.

> `--color-text`, `--color-background`, `--color-links`, `--color-overlay` are ACF-driven
> (set per block instance, consumed by `.acf-style-vars`). Reference as fallbacks; never
> hand-author their values.

### Interactive states & motion

Every interactive element gets designed `:hover`, `:focus-visible`, `:active` states
(`hover-focus-animations.css`, `transition-utilities.css` cover most). Any animation honors
`prefers-reduced-motion: reduce`.

## ACF helpers

Render through these — never hand-roll the equivalent markup. Confirm signatures against
`cool-fse/features/_helper-functions/` if anything looks off.

| Helper | Signature / use |
|---|---|
| `img_if()` | `img_if($id, $size, string $classes = '', bool $allow_placeholder = false, $additional_attr = []): ?string`. Image fields use `return_format: "id"`; render with this, never raw `<img src>` or `wp_get_attachment_image()`. URL format is for CSS `background-image` only, and must be justified. |
| `acf_link()` | `acf_link($link, $classes = '', $aria = '', $additional_attr = [])`. Render ACF link fields with this — never build `<a>` tags from the link array by hand. |
| `acf_to_css_var()` | Converts ACF style fields (padding, color, etc.) to inline CSS custom properties on the block root. |
| `get_block_attributes()` | Block root attributes. First arg is always `@$_block_data`. |
| `get_wrapper_attributes()` | Applies ACF wrapper width/padding. Pass `['class' => '…']` to add classes (e.g. `rich-text`). |
| `maybe_get_block_video_background()` | Outputs the background-video element when the ACF video-bg field is set. |
| `get_block_animation_attributes()` | Attributes for the `<animate-on-scroll>` wrapper. |
| `block()` | `block($_name, $_args = [], $_echo = true)`. Include a sub-block/component — e.g. `block('gutenberg/main-header/logo')` or `block('components/accordion', ['slides' => $slides])` (each `$_args` key becomes a local variable). Replaces `get_template_part()` / `include`. |

### ACF field definitions

Field groups are JSON in `{{CHILD_THEME_DIR}}/acf-json/`, edited **directly** — WordPress
syncs them on next admin load. **Never create or edit ACF fields in WP Admin.** Hand-editing
the JSON is an approval gate (key-collision risk). ACF-generated keys are hex; when
hand-authoring, namespace by group to avoid collisions.

## Custom elements

Web Components in `cool-fse/blocks/global/js/custom-elements/`, available everywhere:
`<ada-slider>`, `<ada-modal>`, `<animate-on-scroll>`, `<animated-element>`, `<g-map>`, plus
~15 more (toggler, read-more, sticky-div, image-compare, countdown-timer, seamless-marquee,
tool-tip, …). **Check the directory before building anything interactive.**

`window.coolHelperFunctions` (`blocks/global/js/_helper-functions.js`): `slideUp`,
`slideDown`, `coolAjax`, `debounce`, `generateID`, and cookie / localStorage /
sessionStorage helpers. Vue 3 is bundled globally for complex interactive blocks; hide
Vue-controlled elements during init with `v-cloak`.

## PHP autoloading

`cool-fse/functions.php`:

1. Auto-loads every `.php` under `features/**`.
2. Auto-loads every file matching `blocks/**/*-autoload.php`.
3. Before loading a parent file, checks whether the child theme has the same relative path —
   if so, the child file wins.

Files prefixed with `_` (e.g. `features/_helper-functions/`) load first as core helpers.
The prefix sets load order; it does **not** block overriding — a child can still override a
`_`-prefixed file by mirroring its path.

## Override path

To override any parent file, mirror its relative path inside `{{CHILD_THEME_DIR}}/`. No
registration needed — the autoloader handles it.
