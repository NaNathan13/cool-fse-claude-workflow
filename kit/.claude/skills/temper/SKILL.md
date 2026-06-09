---
name: temper
description: Phase 3 of the cool-fse workflow. Audit Forge's work in three passes — code, accessibility, and front-end design — against the plan and CONVENTIONS. Writes a Temper Report into the plan. No auto-fix loop; the user directs the next step. Triggered by /temper [slug], "review the implementation", "check my code".
---

Phase 3 of the cool-fse workflow. Audit what Forge produced and report it. **Fix nothing
yourself unless the user explicitly says to.** Audit against `CONVENTIONS.md` and the
plan's `## Quality Bar` — every Bar line gets a check.

Read `WORKFLOW.md` (contract), `CLAUDE.md` (project specifics), `CONVENTIONS.md` (the standards).

## 1. Load the plan

Slug passed → read `.claude/plans/active/<slug>.md`. Else list `active/` and ask. Confirm
`Status: in-progress` and a `Forge complete <date>` line (after a `---` near the bottom).
Missing either → ask; Forge may not have finished, or the slug is wrong.

## 2. Identify diff scope

```bash
git diff --name-only
git status -s
```

Cross-reference the plan's "Files to Create / Modify". Diff entries not in the plan =
**scope drift** — flag them. Read every in-scope file fully, plus 1–2 existing similar
blocks in `{{CHILD_THEME_DIR}}/blocks/gutenberg/` and the relevant utility CSS in
`cool-fse/blocks/global/css/`.

## 3. Is a server reachable?

```bash
curl -s -o /dev/null -w "%{http_code}" <LOCAL_URL>
```

`200`/`3xx` → design pass drives the page with Playwright + screenshots. Else → design
pass reviews CSS/markup statically and says so. All three passes run either way. Don't
start the server.

## 4. Dispatch three audits in parallel

One message, multiple Agent calls. All read-only — none edits code.

### Pass 1 — Code audit

`feature-dev:code-reviewer` (retry `general-purpose` if that type errors). Brief it with
the plan's file list, the diff, `CONVENTIONS.md`, and these checks in priority order:

- **A. Wrapper integrity / parent layout (highest — usually blocking).** Block must use standard wrapper handling: `get_block_attributes()` + `acf-style-vars` on the root, `get_wrapper_attributes()` on the inner `<div>`. It must **not** change the parent's default layout — no overriding `acf-style-vars`, no per-block wrapper settings faking padding/width, no CSS fighting the wrapper width. Re-plumbing the wrapper for a block's own layout = **blocking**. Only legitimate breakout: a single element (e.g. a full-bleed image) ignoring the padding while sized in JS, the rest of the block still obeying the wrapper. Treat a claimed exception as a finding to scrutinize.
- **B. Reuse & utility-class audit (high).** First, the cleverness check: did the work reinvent something cool-fse already provides? Flag any bespoke layout, interaction, or helper where an existing utility class, the `.row`/`.col` grid, a custom element, or a `features/_helper-functions/` helper would do — name the existing tool to use instead. Then, for every CSS rule in a `{{CHILD_THEME_DIR}}/blocks/**/*.css` diff file, ask "could a utility class from `cool-fse/blocks/global/css/` replace this?" Offenders: `display:flex` / `grid-template` for a multi-column or aligned **layout** (→ the `.row` / `.col-<bp>-<n>` grid — **hand-rolled layout is a finding**); `gap` / `align-items` / `text-align` / `font-*` / `padding` / `margin` (→ utilities); raw `--wp--preset--color--*` / `--wp--preset--font-family--*` in CSS (→ the `--color-<slug>` / `--font-family-main|accent` aliases). Name the specific replacement class.
- **C. CSS minimalism, smells & splitting (high).** Per block CSS file in the diff:
  - **Smells — flag each:** `container-type: inline-size` with `cqw`/`cqh` as a roundabout `width: 50%`; an inner element reading a parent's `var(--padding-left)` (give it its own); a custom property with no mobile counterpart; CSS re-implementing wrapper width/padding (overlaps A).
  - **Bisect test:** reason rule-by-rule (comment out, re-add only what's needed); report deletable rules — often most of the file.
  - **Budget (suggested):** files over ~30 lines — justify or shrink; typical ~10–15.
  - **Split (suggested):** one file styling multiple sub-blocks → split into parent + per-child CSS (parent CSS in the parent file only).
- **D. Naming.** Block folder + files kebab-case and matching; JSON `"name": "acf/<block>"`; PHP root class `<block>`; CSS root `<block>` with `<block>--<element>` (double hyphen, never `__`); ACF keys snake_case, labels Title Case.
- **E. PHP pattern.** `get_block_attributes(@$_block_data, …)` on root; `get_wrapper_attributes()` on wrapper; `acf_to_css_var()` for ACF style fields; `maybe_get_block_video_background()` where relevant; sub-blocks via `block('…')`; `esc_html`/`esc_url`/`esc_attr` on output. Top-of-file `@param` docblock present and accurate — one line per ACF field the template consumes, types/names matching the `get_field()` calls; missing or stale = **suggested**. Image fields not `return_format: id` or not via `img_if()` = **blocking**. Link fields not via `acf_link()` = **blocking**.
- **F. Block JSON.** `"style": ["cool-fse-css"]`, `"script": "cool-fse-js"`, `"acf": { "mode": "preview", "renderCallback": "acf_display_gutenberg_block_callback" }`, `category` set. (Structural blocks may set `inserter:false`/`multiple:false` and omit `example` — not a finding.)
- **G. ACF JSON + editor UX.** Edited directly in `acf-json/` (no WP-Admin export artifacts); keys consistent with neighbors. Every field has `instructions`; `required:1` where the block can't render without it; repeaters set `collapsed` to a title sub-field + a specific `button_label`; related fields grouped; labels jargon-free. Editor-UX items are **suggested**, never blocking.
- **H. Hygiene.** No `var_dump`/`print_r`/`console.log`; no commented-out code; no hardcoded hex or magic spacing; no inline `style=""` outside `acf_to_css_var()`; no `!important` without a comment.
- **I. Unauthorized `cool-fse/` edits.** Anything in `cool-fse/` not in the plan's pre-approved gates = **blocking**.
- **J. Quality Bar coverage.** Each plan `## Quality Bar` line is addressed by the diff (a "stacks below 768px" line implies a `@media (max-width:768px)` rule). A Bar line with no implementation = **suggested**.

Categorize each finding **blocking** / **suggested** / **nit**, with `file:line` and a concrete fix.

### Pass 2 — Accessibility (ADA) audit

`general-purpose`. Brief it with the diff and the plan's Verification section. Check:
semantic HTML and landmarks; heading hierarchy (no skipped levels); image alt text (empty
`alt=""` for decorative is fine); ARIA on custom elements that need it; every interactive
element keyboard-reachable with a visible focus state; WCAG AA text contrast; form labels;
`prefers-reduced-motion` respected by any animation. **Suggestions-only** unless the plan
explicitly required a level (e.g. "must pass WCAG AA").

### Pass 3 — Front-end design audit

`general-purpose`, with Playwright if the server was reachable in step 3 (drive the
block's page, screenshot desktop + 375px to `.claude/screenshots/<slug>/`), else static
from CSS/markup + any screenshots there. Brief it with the plan's `## Visual Reference` and
`## Quality Bar` visual line. Judge design, not code style. Score each axis Pass / Weak /
Fail with a one-line reason:

1. **Spacing & rhythm** — consistent scale, deliberate breathing room
2. **Typographic hierarchy** — clear levels, sensible line-height/length
3. **Alignment & structure** — aligns to a system; nothing accidentally off-grid
4. **Visual balance** — weight distributed deliberately
5. **Color & emphasis** — theme tokens; emphasis lands where it should; intentional contrast
6. **Interactive states** — hover / focus-visible / active / disabled all designed
7. **Responsive composition** — *composed* at 375px, not just unbroken; tap targets adequate
8. **Dark/light** — works on whichever backgrounds the plan specified
9. **Polish / not-generic** — bespoke, not a default AI card

Return **Verdict: Approve | Recommend changes** (Approve only when no axis is Fail and at
most one Weak), plus findings (axis — what's wrong — concrete change — screenshot ref).
Design findings are **suggested** unless they contradict `## Visual Reference`, then **blocking**.

## 5. Merge findings

One report from the three passes. **Blocking** (must fix before Seal): unauthorized parent
edits, overriding `acf-style-vars` / re-plumbing the wrapper to fake padding/width, missing
required PHP helpers, image/link fields not using `img_if`/`acf_link`, broken visual states,
scope drift that changes intent, design findings contradicting the Visual Reference.
**Suggested**: utility-class replacements, CSS smells, oversized/unsplit CSS, missing
escaping, naming slips, ACF editor-UX. **Nit**: cosmetic. Accessibility: suggestions-only,
own subsection. Sort by impact within each category.

## 6. Write the report

Append to the bottom of the plan:

```markdown

## Temper Report — <today's date>

**Summary:** <one paragraph: overall fit, biggest issue, anything needing rework before commit>.

**Counts:** <X> blocking, <Y> suggested, <Z> nits, <N> a11y. Design verdict: <Approve | Recommend changes>.

### Blocking
1. **<file>:<line>** — <issue>. <concrete fix>

### Suggested
1. **<file>:<line>** — <issue>. <concrete fix>

### Nits
1. **<file>:<line>** — <issue>.

### Accessibility — suggestions only
1. **<file>:<line>** — <issue>. <concrete fix>

### Front-end design
- **Verdict:** Approve | Recommend changes
- 9-axis rubric + findings. Screenshots: `.claude/screenshots/<slug>/` (if a server was reachable).

### CSS → Utility Class Replacements
1. `<file>:<line>` — replace `display:flex; gap:var(--wp--preset--spacing--40);` with utilities `flex gap-40` on the wrapper. Remove the rule.
```

Write `_None._` under any empty category.

## 7. Hand off

> Temper Report appended to `.claude/plans/active/<slug>.md`.
> **<X> blocking, <Y> suggested, <Z> nits, <N> a11y. Design: <verdict>.**
> Fix in this session, fix manually, or proceed to `/seal`?

Then wait. If the user asks for fixes, do them here and append a `### Temper fixes — <date>`
subsection, then hand off again. If they say seal, do nothing further.

## Don't do

- **Don't auto-fix without permission.** Report and wait.
- **Don't re-run the Forge build.** Temper is audit-only.
- **Don't run `git commit`.**
- **Don't escalate accessibility to blocking** unless the plan required a level.
- **Don't dispatch the three passes serially.** Single message, parallel.
