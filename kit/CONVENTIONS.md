# Conventions

The cool-fse coding standards. **The single source of truth** — Forge builds to this,
Temper audits against it. Project-agnostic: true for any child theme on the cool-fse
parent.

> **The live codebase wins.** `cool-fse/blocks/global/css/` and
> `cool-fse/blocks/global/js/custom-elements/` are the real source of truth for what
> utility classes and custom elements exist. This file names the high-frequency ones;
> read the directories before assuming something does or doesn't exist.

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
- No type hints on local variables. Match the helper style (`array`/return types only where existing helpers use them).
- Never leave `var_dump`, `print_r`, or `console.log` in.

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

- Always `renderCallback`, never `renderTemplate`. Category is `theme-basics`. 2–5 keywords. Font Awesome SVG for the icon.
- **Structural blocks are the exception.** A header, footer, or other single-use block may set `"inserter": false`, `"multiple": false`, and omit `example` — match how the existing structural blocks are configured rather than forcing the content-block shape.

## CSS

### Utility-class first

Before writing any block CSS, exhaust the utility classes in
`cool-fse/blocks/global/css/`. New block-level CSS is an approval gate. Apply utilities
as classes in the PHP markup. High-frequency files (read the directory for the rest):

`display-helpers.css`, `flex-utilities.css`, `spacing-utilities.css`,
`grid-col-helpers.css`, `show-hide-helpers.css`, `text-helpers.css`,
`sizing-utilities.css`, `positioning-utilities.css`, `hover-focus-animations.css`,
`transition-utilities.css`.

### Naming

`<block-name>` as the root class. Elements: `<block-name>--<element>` (double hyphen).
Modifiers: `<block-name>--<modifier>`. **No double underscores (`__`)** — this is not
standard BEM.

### Responsive

The mobile breakpoint is **768px**, written as a media query in the block CSS:

```css
@media (max-width: 768px) { /* mobile rules */ }
```

There is **no `mobile:` utility prefix.** For show/hide, use `.mobile-only` /
`.desktop-only` from `show-hide-helpers.css`. After building, the layout must hold
together at 375px, not merely "not break."

### Tokens — no hardcoded values

Use the WordPress-generated preset custom properties (auto-created from `theme.json`):
`--wp--preset--color--<slug>`, `--wp--preset--font-family--<slug>`,
`--wp--preset--spacing--<slug>`. Plus the `--font-family-*` vars set in
`{{CHILD_THEME_DIR}}/blocks/global/css/global.css`. No raw hex, no magic spacing numbers.
No `!important` without a comment explaining why.

### Interactive states & motion

Every interactive element gets designed `:hover`, `:focus-visible`, and `:active` states
(`hover-focus-animations.css` and `transition-utilities.css` cover most). Any animation
honors `prefers-reduced-motion: reduce`.

### Cross-browser

Target the latest Chrome, Firefox, Safari, Edge. No IE. Before a recent feature
(`:has()`, `backdrop-filter`, subgrid, `@container`, `@property`, top-level `await`),
confirm baseline support or provide a fallback. When in doubt, prefer the
already-tested utility classes.

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

Web Components in `cool-fse/blocks/global/js/custom-elements/`, available everywhere.
Common ones: `<ada-slider>`, `<ada-modal>`, `<animate-on-scroll>`, `<animated-element>`,
`<g-map>` — plus ~15 more (toggler, read-more, sticky-div, image-compare,
countdown-timer, seamless-marquee, tool-tip, …). **Check the directory before building
anything interactive from scratch.**

`window.coolHelperFunctions` (from `blocks/global/js/_helper-functions.js`) provides
`slideUp`, `slideDown`, `coolAjax`, `debounce`, `generateID`, and cookie / localStorage /
sessionStorage helpers. Vue 3 is bundled globally for complex interactive blocks; hide
Vue-controlled elements during init with `v-cloak`.

## PHP autoloading

`cool-fse/functions.php`:

1. Auto-loads every `.php` under `features/**`.
2. Auto-loads every file matching `blocks/**/*-autoload.php`.
3. Before loading a parent file, checks whether the child theme has the same relative
   path — if so, the child file wins.

Files prefixed with `_` (e.g. `features/_helper-functions/`) load first as core helpers.
The prefix sets load order; it does **not** block overriding — a child theme can still
override a `_`-prefixed file by mirroring its path.

## Override path

To override any parent file, mirror its relative path inside `{{CHILD_THEME_DIR}}/`. No
registration needed — the autoloader handles it.
