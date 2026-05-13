# Kit Audit — 2026-05-13

## Action / Skip Summary

### Do now (worth your time before sharing)

**Convention enforcement gaps in skills (biggest impact — these cause bad code from Forge):**

1. **forge/SKILL.md — no ACF image field rules.** The theme uses `return_format: "id"` on every image field and renders with `img_if($id, $size, $classes)`. Forge has zero mention of `img_if()` or image return format. It will generate `<img src="<?= get_field('image') ?>">` or URL-based rendering instead of `<?= img_if(get_field('image'), 'large', 'block-name--image') ?>`. This is the single highest-frequency convention miss.
2. **forge/SKILL.md — wrong BEM convention.** Line 91 says "CSS classes: `<block-name>` as root, BEM-style descendants" but doesn't specify the actual pattern. The theme uses **double-hyphen** for element separation (`block-name--element`), not the standard BEM double-underscore (`block-name__element`). Without this, Forge produces `__` underscores that don't match any existing block in the codebase.
3. **forge/SKILL.md — no block JSON completeness rules.** Forge has no instruction to set `icon`, `keywords`, `description`, `example`, or `supports` in block JSON. The theme's blocks consistently include all of these — SVG icons from Font Awesome, keyword arrays, description strings, `example` with `is_preview: true`, and `supports` with `inserter/multiple/anchor`. Forge should set all of these during build, not leave them for Temper to catch.
4. **forge/SKILL.md — no block JSON `renderCallback` convention.** The theme uses `"renderCallback": "acf_display_gutenberg_block_callback"` — not `"renderTemplate"`. Forge line 88 explicitly says `"renderTemplate": "<name>-block.php"` which is wrong for this theme. Every block in the codebase uses the callback pattern.
5. **forge/SKILL.md — utility-class-first is stated but not enforced.** Line 91 says "CSS: utility classes first, always" but doesn't name any classes or tell Forge where to look. The theme has extensive utility CSS: `display-helpers.css` (`.flex`, `.inline`, `.block`, `.grid`), `flex-utilities.css` (`.justify-*`, `.align-*`, `.flex-column`), `spacing-utilities.css` (`.m-*`, `.p-*` with scale 1-64), `grid-col-helpers.css` (`.col-*`, `.row`), `show-hide-helpers.css` (`.desktop-only`, `.mobile-only`), `text-helpers.css`, `sizing-utilities.css`, `positioning-utilities.css`, plus mobile prefix `mobile:` variants. Forge should be told to read `cool-fse/blocks/global/css/` before writing any CSS, and to apply classes on the PHP markup rather than writing CSS rules.
6. **forge/SKILL.md — no PHP typing rule.** The theme does not type-hint local variables and uses minimal parameter typing (mostly `array` and return types on helpers). Forge has no instruction about this, so it may produce `string $var = get_field(...)` or typed closures. Add: "No type hints on local variables. Match the existing helper function typing style."
7. **forge/SKILL.md — missing standard block boilerplate.** The theme's blocks follow a strict boilerplate: ABSPATH guard, get fields, early return on empty, `$block_attributes` array with `'class' => 'blockname acf-style-vars'` + `'style' => acf_to_css_var()`, then `get_block_attributes(@$_block_data, $block_attributes)` on the root div. Forge mentions some helpers (line 87-89) but doesn't show the actual boilerplate pattern. An inline example would prevent Forge from inventing its own structure.
8. **inscribe/SKILL.md — plan template doesn't enforce ACF field details.** The Approach section says "use concrete ACF field keys" but doesn't require specifying `return_format` for each field. Plans should explicitly state `return_format: id` for images (and flag the rare URL exception with rationale), so Forge doesn't guess.
9. **temper/SKILL.md — BEM check uses wrong convention.** Line 59 says `CSS root selector: <block-name> (BEM descendants <block-name>__<element>)` — double underscore. Should be `<block-name>--<element>` (double hyphen) to match the actual theme.

**Structural / reference issues:**

10. **README.md:12** — remove "model routing" from the feature list. It was removed from the kit but this mention survived.
11. **README.md:25** — says setup copies `.claude/hooks/*` but setup.sh doesn't copy any hooks directory. Delete the hooks reference.
12. **setup.sh:144-145** — references `EXAMPLE-testimonial-slider.md` in `kit/.claude/plans/done/` but that file doesn't exist. Either create it or remove the copy logic.
13. **inscribe/SKILL.md:70** — says `.claude/design-references/` but every other file uses `.claude/screenshots/<slug>/`. Fix to match.
14. **inscribe/SKILL.md:75** — heading `## Verification — Human Review Checklist` doesn't match WORKFLOW.md:95 `## Verification`. Forge searches for "Verification section" — align the name.
15. **WORKFLOW.md:114** — lifecycle diagram says `Forge updates Status to "in-progress"` but Inscribe already sets this. Reword or remove.
16. **docs/upgrading.md:20** — lists `.claude/hooks/model-router.sh` as overwritten. Stale. Also missing inscribe/scrub/researcher from skill list.
17. **docs/design-notes.md:53** — Decision #8 describes model routing as "locked-in" but it was removed. Contradicts the same doc's line 12.

### Skip (not worth your time)

1. **`<child-theme>` placeholders in skills** — intentional generic prose. Scrub handles replacement post-install.
2. **scrub/SKILL.md steps 5 + 8** reference removing model-router hooks and preferred-model frontmatter. Both are conditional no-ops on fresh installs. Harmless dead code.
3. **`my-site.local` in forge/SKILL.md:45** — illustrative example in a parenthetical. Scrub replaces it.
4. **WORKFLOW.md worked examples use `<child-theme>/`** — same as #1.
5. **No hooks directory ships** — Scrub's `rm -rf .claude/hooks/` is a no-op. Fine.
6. **ACF field keys use hex format** — CONTEXT.md describes a `field_<group_slug>_<field_name>` convention, but the actual theme uses ACF-generated hex keys (`field_66f6df4e22b30`). This mismatch doesn't matter in practice because Forge should be copying/extending existing ACF JSON files, not inventing keys from scratch. The hex keys are generated by ACF; the naming convention in CONTEXT.md is aspirational for hand-created fields.
7. **`get_block_animation_attributes()`** — used in the theme boilerplate (`<animate-on-scroll>` wrapper) but not mentioned in any skill. Low priority — it's optional per block and Forge will see it when reading existing blocks for reference.

---

## Detailed Findings

### Part 1 — Convention Enforcement in Skills

These findings come from comparing the actual cool-fse/pontiac-edc codebase conventions against what the skills tell Claude to do. Sorted by frequency of impact.

#### C1. ACF Image Fields — `img_if()` not mentioned anywhere

**Affected skills:** forge/SKILL.md, inscribe/SKILL.md, temper/SKILL.md

**The convention:** Every ACF image field in the theme uses `return_format: "id"`. Images are rendered with the `img_if()` helper:

```php
<?= img_if(get_field('image'), 'large', 'block-name--image') ?>
```

Signature: `img_if($id, $size, string $classes = '', bool $allow_placeholder = false, $additional_attr = [])`

The function handles responsive srcset, placeholder fallback, and proper `<img>` markup. URL return format is only used for CSS `background-image` inline styles — and that's rare.

**What the skills say:** Nothing. `img_if()` appears zero times across all skills. CLAUDE.md.template doesn't mention it either. Forge will generate raw `<img src="<?= get_field('image') ?>">` or `wp_get_attachment_image()` patterns instead.

**Fix — forge/SKILL.md:** Add to section 9 ("Follow cool-fse conventions"):
```
- **Images**: ACF image fields MUST use `return_format: "id"`. Render with `img_if($id, $size, $classes)` — never raw `<img src>` or `wp_get_attachment_image()`. URL format is only for CSS `background-image` and must be explicitly justified.
```

**Fix — inscribe/SKILL.md:** In the Approach section guidance, add: "For any image field, specify return_format: id and note the img_if() size parameter."

**Fix — temper/SKILL.md:** Add to code review checks: "Image fields not using `return_format: id` or not rendered via `img_if()` = **blocking**."

**Fix — CLAUDE.md.template:** Add `img_if()` to the "Theme architecture" helpers list alongside `acf_to_css_var()`.

#### C2. BEM Naming — Double Hyphen, Not Double Underscore

**Affected skills:** forge/SKILL.md:91, temper/SKILL.md:59, CLAUDE.md.template:118

**The convention:** The theme uses double-hyphen for element separation:

```css
.content-slider { }              /* block */
.content-slider--slide { }       /* element */
.content-slider--cap-images { }  /* modifier */
.global-popup--close { }         /* element */
.global-popup--has-image { }     /* modifier */
.accordion-component--toggle-all { }
```

No double underscores anywhere in the codebase.

**What the skills say:**
- CLAUDE.md.template:118: "CSS classes: `<block-name>` as root, BEM-style descendants" (vague, no example)
- temper/SKILL.md:59: "BEM descendants `<block-name>__<element>`" (explicitly wrong — uses `__`)
- forge/SKILL.md doesn't specify the pattern at all

**Fix — forge/SKILL.md section 9:** Replace the CSS bullet with:
```
- **CSS naming**: `<block-name>` as root class. Elements: `<block-name>--<element>` (double hyphen). Modifiers: `<block-name>--<modifier-name>`. No double underscores (`__`) — this is not standard BEM.
```

**Fix — temper/SKILL.md:59:** Change `<block-name>__<element>` to `<block-name>--<element>`.

**Fix — CLAUDE.md.template:118:** Change to: "CSS classes: `<block-name>` as root, `<block-name>--<element>` for descendants (double-hyphen, not `__`)"

#### C3. Block JSON Completeness — icon, keywords, description, example, supports

**Affected skills:** forge/SKILL.md, inscribe/SKILL.md

**The convention:** Every block JSON in the theme includes all of these:

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
    "attributes": {
      "mode": "preview",
      "data": { "is_preview": true }
    }
  },
  "supports": {
    "inserter": true,
    "multiple": true,
    "anchor": true
  }
}
```

**What the skills say:**
- forge/SKILL.md:88 mentions `"style"`, `"script"`, and `"acf"` but omits `icon`, `keywords`, `description`, `example`, `supports`
- forge/SKILL.md:88 says `"renderTemplate"` — the theme uses `"renderCallback": "acf_display_gutenberg_block_callback"` instead
- inscribe doesn't tell the planner to decide on icon/keywords/category during planning

**Fix — forge/SKILL.md section 9, Block JSON bullet:** Replace with the full template above and add: "Every field is required. Pick an appropriate Font Awesome SVG for the icon. Set 2-5 keywords. Always use `renderCallback`, not `renderTemplate`. Category is always `theme-basics`."

**Fix — inscribe/SKILL.md:** Add a note in the Approach section: "For new blocks, note the intended `category`, `keywords`, and `icon` concept (Forge picks the actual SVG)."

#### C4. Utility-Class-First Enforcement

**Affected skills:** forge/SKILL.md

**The convention:** The theme has extensive utility CSS covering: display (`.flex`, `.grid`, `.block`, `.inline`, `.none`), flex (`.justify-center`, `.align-center`, `.flex-column`, `.flex-wrap`), spacing (`.m-*`, `.p-*`, `.mt-*`, `.mb-*`, `.pt-*`, `.pb-*` from 1-64), grid (`.col-*`, `.row`), visibility (`.desktop-only`, `.mobile-only`, `.sr-only`), text, sizing, positioning, overflow. Plus `mobile:` responsive prefix variants.

Typical blocks are 70-80% utility classes applied in PHP, 20-30% custom CSS (mostly for block-specific layout or animation).

**What the skills say:** forge/SKILL.md:91 says "utility classes first, always" and "New block CSS is a Gate 2 trigger" — but doesn't name any classes or file locations. A model following this instruction has no idea what utilities are available.

**Fix — forge/SKILL.md section 2 (Orient):** Add: "Read `cool-fse/blocks/global/css/` to know what utility classes exist before writing any CSS. Key files: `display-helpers.css`, `flex-utilities.css`, `spacing-utilities.css`, `grid-col-helpers.css`, `show-hide-helpers.css`, `text-helpers.css`. Apply these as classes in the PHP markup. Custom CSS is a last resort."

**Fix — forge/SKILL.md section 9:** Add: "Mobile-responsive utility prefix: `mobile:` (e.g., `mobile:m-0`, `mobile:flex-column`). Breakpoint: 768px."

#### C5. Standard Block PHP Boilerplate

**Affected skills:** forge/SKILL.md

**The convention:** Every block follows this exact pattern:

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

Key details: `@$_block_data` (with `@` suppression), `acf-style-vars` class always present, short tags `<?=` exclusively (never `<?php echo`).

**What the skills say:** forge/SKILL.md:87-89 lists the helpers by name but doesn't show the actual boilerplate or the `@$_block_data` parameter pattern. CLAUDE.md.template:62-74 has an older version that omits `@$_block_data`, the ABSPATH guard, and `animate-on-scroll`.

**Fix — forge/SKILL.md section 9:** Add the full boilerplate as an inline code example. Emphasize `@$_block_data` as the first argument to `get_block_attributes()`.

**Fix — CLAUDE.md.template:62-74:** Update the "Standard block PHP pattern" to match the actual convention (add `@$_block_data`, ABSPATH guard, early return pattern).

#### C6. No PHP Type Hints on Variables

**Affected skills:** forge/SKILL.md

**The convention:** The codebase does not type-hint local variables. Helper functions use light typing (`array $attr = []`, return types like `: string`, `: ?string`) but block PHP files have none. No typed properties, no typed closures, no `string $var = ...`.

**What the skills say:** Nothing. Forge may produce typed PHP since modern PHP and Claude's training data lean that direction.

**Fix — forge/SKILL.md section 9:** Add: "No type hints on local variables or block-level code. Match the helper function style: `array` and return types only where existing functions use them."

#### C7. `block()` Component Pattern

**Affected skills:** forge/SKILL.md

**The convention:** Components live in `blocks/components/` and are called via:
```php
<?php block('components/accordion', ['slides' => $slides, 'include_toggle_all' => true]) ?>
```

Sub-blocks of gutenberg blocks:
```php
<?php block('gutenberg/logos/logo', $logo) ?>
```

The `block()` function (in `features/_helper-functions/block.php`) extracts array keys as local variables in the included file's scope.

**What the skills say:** forge/SKILL.md:89 mentions `block('...')` but doesn't explain the argument-passing convention (associative array → extracted variables). Forge may pass arguments wrong or use `include` instead.

**Fix — forge/SKILL.md section 9:** Expand the sub-blocks bullet: "Arguments are an associative array — each key becomes a local variable in the component's scope. E.g., `block('components/accordion', ['slides' => $slides])` makes `$slides` available inside `accordion.php`."

#### C8. `acf_link()` Helper

**Affected skills:** None mention it.

**The convention:** ACF link fields are rendered with `acf_link()`:
```php
<?= acf_link($link, 'button w-100', 'aria-label') ?>
```

Signature: `acf_link($link, $classes = '', $aria = '', $additional_attr = [])`

**Fix — forge/SKILL.md section 9:** Add: "ACF link fields: render with `acf_link($link, $classes, $aria)` — never build `<a>` tags manually from ACF link arrays."

**Fix — CLAUDE.md.template:** Add `acf_link()` to the helpers list.

#### C9. Short Tags Exclusively

**Affected skills:** forge/SKILL.md

**The convention:** Every block in the codebase uses `<?=` for echo. Zero instances of `<?php echo`.

**What the skills say:** CLAUDE.md.template mentions "short-tag usage matches existing blocks" but forge/SKILL.md doesn't specify.

**Fix — forge/SKILL.md section 9:** Add: "Always use short echo tags (`<?=`), never `<?php echo`."

---

### Part 2 — Structural / Reference Issues

#### Blocking

1. **Stale "model routing" in README.md:12**
   - Line: `Everything else — methodology, lane definitions, plan format, model routing — lives in kit/WORKFLOW.md.`
   - Model routing was intentionally removed. WORKFLOW.md has no model routing section.
   - **Fix:** Delete `, model routing` from the sentence.

2. **README.md:25 references `.claude/hooks/*` — doesn't exist**
   - Line: `Copies WORKFLOW.md, .claude/skills/*, .claude/hooks/*, .claude/settings.json...`
   - setup.sh never copies a hooks directory.
   - **Fix:** Remove `.claude/hooks/*,` from the sentence.

3. **setup.sh:144-145 tries to copy a missing example plan**
   - `kit/.claude/plans/done/EXAMPLE-testimonial-slider.md` does not exist. Silent no-op.
   - **Fix:** Either create the example plan file or remove lines 144-145 from setup.sh.

4. **inscribe/SKILL.md:70 — wrong screenshot path**
   - Says `.claude/design-references/` — should be `.claude/screenshots/<slug>/`.
   - **Fix:** Change to match every other file in the kit.

5. **inscribe/SKILL.md:75 vs WORKFLOW.md:95 — mismatched Verification heading**
   - inscribe: `## Verification — Human Review Checklist`
   - WORKFLOW.md: `## Verification`
   - **Fix:** Use `## Verification` everywhere.

6. **WORKFLOW.md:114 — lifecycle diagram says Forge updates Status**
   - Inscribe already sets `Status: in-progress`. Forge only confirms it.
   - **Fix:** Change to `← Forge confirms Status is "in-progress"` or remove.

#### Suggested

7. **docs/upgrading.md:20** — lists `.claude/hooks/model-router.sh` as overwritten. Missing inscribe/scrub/researcher from skill list. Stale.

8. **docs/design-notes.md:53** — Decision #8 (model routing) contradicts the kit's actual state and line 12 of the same doc.

9. **scrub/SKILL.md steps 5 + 8** — reference removed features (model-router hook, preferred-model frontmatter). Harmless no-ops but confusing to read.

10. **temper/SKILL.md:19** — checks for Forge handoff line "at the bottom" but Forge writes it after a `---` rule. Low risk, worth aligning language.

11. **settings.json — no `rm` permission for scrub.** Scrub's deletions will trigger permission prompts. Add to allowlist or accept the prompts (runs once).

12. **README first-run prompt (lines 34-41)** — double-confirms values setup.sh already prompted for. Belt-and-suspenders; decide if the friction is worth it.

#### Nits

13. **WORKFLOW.md:152** — `/scrub` description says "or on existing installs" but it deletes `update.sh`.

14. **CLAUDE.md.template:119 + 126-127** — ACF JSON edit rule stated twice (Naming conventions and ACF+Gutenberg sections).

15. **temper/SKILL.md:98** — visual subagent type is ambiguous ("Playwright or general-purpose agent with Playwright access").

---

## Summary

- **9 convention enforcement gaps** — these are why Forge produces code that doesn't match theme conventions. Highest-impact fixes. Focus on forge/SKILL.md section 9 and the block JSON template.
- **6 structural blocking issues** — stale references, missing files, mismatched headings
- **6 suggested improvements** — stale docs, permission gaps, minor mismatches
- **3 nits** — wording, redundancy

The core workflow logic (handoff protocol, plan lifecycle, gate system) is solid. The skills correctly describe *what* to do at each phase. The gap is that they don't describe *how* to write cool-fse code — the theme's specific helpers, naming patterns, and boilerplate aren't encoded in the skills, so Forge falls back to generic WordPress patterns that don't match the codebase.
