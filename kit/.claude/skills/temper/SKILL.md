---
name: temper
description: Phase 3 of the cool-fse workflow. Audit Forge's work in three passes — code, accessibility, and front-end design — against the plan and CONVENTIONS. Writes a Temper Report into the plan. No auto-fix loop; the user directs the next step. Triggered by /temper [slug], "review the implementation", "check my code".
---

You are Phase 3 of the four-phase cool-fse workflow. Audit what Forge produced and report
what you find. **Do not fix anything yourself unless the user explicitly tells you to.**
Audit against `CONVENTIONS.md` and the plan's `## Quality Bar` — every Bar line gets a
check.

Read `WORKFLOW.md` for the contract, `CLAUDE.md` for project specifics, `CONVENTIONS.md`
for the standards you're auditing against.

## 1. Load the plan

If a slug was passed, read `.claude/plans/active/<slug>.md`. Otherwise list `active/` and
ask which to audit. Confirm `Status: in-progress` and a `Forge complete <date>` line
(after a `---` near the bottom). If either is missing, ask — Forge may not have finished,
or the slug is wrong.

## 2. Identify diff scope

```bash
git diff --name-only
git status -s
```

Cross-reference with the plan's "Files to Create / Modify". Anything in the diff that's
NOT in the plan is **scope drift** — flag it. Read every in-scope file fully, plus 1–2
existing similar blocks in `{{CHILD_THEME_DIR}}/blocks/gutenberg/` and the relevant
utility CSS in `cool-fse/blocks/global/css/`.

## 3. Is a server reachable?

The design pass is richer with a live page. Check once:

```bash
curl -s -o /dev/null -w "%{http_code}" <LOCAL_URL>
```

`200`/`3xx` → the design subagent drives the page with Playwright and screenshots it.
Otherwise → the design subagent reviews CSS/markup **statically** and says so. Either
way, all three passes run. Don't start the server yourself.

## 4. Dispatch three audits in parallel

Send all three in a single message (multiple Agent calls). Each is read-only and
reports — none of them edits code.

### Pass 1 — Code audit

`feature-dev:code-reviewer` (retry with `general-purpose` if that type errors). Brief it
with the plan's file list, the diff, `CONVENTIONS.md`, and these checks in priority order:

- **A. Wrapper integrity / parent layout (highest — usually blocking).** The block must use standard wrapper handling: `get_block_attributes()` + `acf-style-vars` on the root, `get_wrapper_attributes()` on the inner `<div>`. It must **not** change the parent's default layout — no overriding `acf-style-vars`, no per-block wrapper settings faking padding/width, no CSS fighting the wrapper width. This keeps admin settings (padding/width/alignment) consistent across blocks, so re-plumbing the wrapper to control a block's own layout = **blocking**. Only legitimate breakout: a single element (e.g. a full-bleed image) ignoring the padding while sized in JS, the rest of the block still obeying the wrapper. 99.99% of blocks fit with no workaround; treat a claimed exception as a finding to scrutinize, not accept.
- **B. Utility-class audit (high).** For every CSS rule in a `{{CHILD_THEME_DIR}}/blocks/**/*.css` diff file, ask "could a utility class from `cool-fse/blocks/global/css/` replace this?" Common offenders: `display:flex` / `gap` / `align-items` / `text-align` / `font-*` / `color` via `--wp--preset--*` / `padding` / `margin`. Name the specific replacement class.
- **C. CSS minimalism, smells & splitting (high).** Scrutinize every block CSS file in the diff:
  - **Smell-list — flag each occurrence:** `container-type: inline-size` with `cqw`/`cqh` units used as a roundabout `width: 50%`; an inner element referencing a parent's `var(--padding-left)` (give it its own `padding-left` instead); any custom property used with no mobile counterpart; CSS re-implementing wrapper width/padding (overlaps check A).
  - **Bisect test:** for any heavy CSS file, reason rule-by-rule (mentally comment out, then re-add only what's needed) and report which rules appear deletable — often most of the file.
  - **Budget (suggested):** files over ~30 lines — justify or shrink; typical is ~10–15.
  - **Split (suggested):** one file styling multiple sub-blocks should split into parent + per-child-block CSS files (parent CSS in the parent file only).
- **D. Naming.** Block folder + files kebab-case and matching; JSON `"name": "acf/<block>"`; PHP root class = `<block>`; CSS root `<block>` with `<block>--<element>` descendants (double hyphen, never `__`); ACF keys snake_case, labels Title Case.
- **E. PHP pattern (per CONVENTIONS).** `get_block_attributes(@$_block_data, …)` on root; `get_wrapper_attributes()` on wrapper; `acf_to_css_var()` for ACF style fields; `maybe_get_block_video_background()` where relevant; sub-blocks via `block('…')`; `esc_html`/`esc_url`/`esc_attr` on output. Image fields not `return_format: id` or not via `img_if()` = **blocking**. Link fields not via `acf_link()` = **blocking**.
- **F. Block JSON.** `"style": ["cool-fse-css"]`, `"script": "cool-fse-js"`, `"acf": { "mode": "preview", "renderCallback": "acf_display_gutenberg_block_callback" }`, `category` set. (Structural blocks may set `inserter:false`/`multiple:false` and omit `example` — not a finding.)
- **G. ACF JSON + editor UX.** Edited directly in `acf-json/` (no WP-Admin export artifacts); keys consistent with neighbors. Editor UX: every field has `instructions`; `required:1` on fields the block can't render without; repeaters set `collapsed` to a title sub-field + a specific `button_label`; related fields grouped; labels jargon-free. Editor-UX items are **suggested**, never blocking.
- **H. Hygiene.** No `var_dump`/`print_r`/`console.log`; no commented-out code; no hardcoded hex or magic spacing; no inline `style=""` outside `acf_to_css_var()`; no `!important` without a comment.
- **I. Unauthorized `cool-fse/` edits.** Anything in `cool-fse/` not in the plan's pre-approved gates = **blocking**.
- **J. Cross-browser lint.** Flag features outside the matrix (latest Chrome/Firefox/Safari/Edge, no IE): `:has()`, `backdrop-filter`, subgrid, `@container`, `@property`, top-level `await`. Name the concern + a fallback. **Suggested** unless it has no fallback and breaks a supported browser, then **blocking**.
- **K. Quality Bar coverage.** For each plan `## Quality Bar` line, confirm the diff addresses it (e.g. a "stacks below 768px" line implies a `@media (max-width:768px)` rule). A Bar line with no implementation = **suggested**.

Categorize each finding **blocking** / **suggested** / **nit**, with `file:line` and a concrete fix.

### Pass 2 — Accessibility (ADA) audit

`general-purpose`. Brief it with the diff and the plan's Verification section. Check:
semantic HTML and landmarks; heading hierarchy (no skipped levels); alt text on images
(empty `alt=""` for decorative is fine); ARIA on custom elements that need it; every
interactive element keyboard-reachable with a visible focus state; WCAG AA text contrast;
form labels; `prefers-reduced-motion` respected by any animation. **Accessibility findings
are suggestions-only** unless the plan explicitly required a level (e.g. "must pass WCAG
AA").

### Pass 3 — Front-end design audit

`general-purpose`, with Playwright if the server was reachable in step 3 (drive the
block's page, screenshot desktop + 375px to `.claude/screenshots/<slug>/`), else static
from CSS/markup + any screenshots in that folder. Brief it with the plan's
`## Visual Reference` and the `## Quality Bar` visual line. This is the "looks very good"
check — judge design, not code style. Score each axis Pass / Weak / Fail with a one-line
reason:

1. **Spacing & rhythm** — consistent scale, deliberate breathing room
2. **Typographic hierarchy** — clear levels, sensible line-height/length
3. **Alignment & structure** — aligns to a system; nothing accidentally off-grid
4. **Visual balance** — weight distributed deliberately
5. **Color & emphasis** — theme tokens; emphasis lands where it should; intentional contrast
6. **Interactive states** — hover / focus-visible / active / disabled all designed
7. **Responsive composition** — *composed* at 375px, not just unbroken; tap targets adequate
8. **Dark/light** — works on whichever backgrounds the plan specified
9. **Polish / not-generic** — bespoke, not a default AI card

Return a **Verdict: Approve | Recommend changes** (Approve only when no axis is Fail and
at most one Weak), plus findings (axis — what's wrong — concrete change — screenshot ref).
Design findings are **suggested** unless they contradict the plan's `## Visual Reference`,
then **blocking**.

## 5. Merge findings

Combine the three passes into one report. **Blocking** (must fix before Seal): unauthorized
parent edits, overriding `acf-style-vars` / re-plumbing the wrapper to fake padding/width,
missing required PHP helpers, image/link fields not using `img_if`/`acf_link`, broken visual
states, scope drift that changes intent, design findings that contradict the Visual
Reference. **Suggested**: utility-class replacements, CSS smells, oversized/unsplit CSS
files, missing escaping, naming slips, cross-browser, ACF editor-UX. **Nit**: cosmetic.
Accessibility: suggestions-only, own subsection. Within
each category, sort by impact.

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

Wait. **Do NOT auto-fix.** If the user asks for fixes, do them here and append a
`### Temper fixes — <date>` subsection, then hand off again. If they say seal, do nothing
further.

## Don't do

- **Don't auto-fix without permission.** Report and wait.
- **Don't re-run the whole Forge build.** Temper is audit-only.
- **Don't run `git commit`.**
- **Don't escalate accessibility to blocking** unless the plan required a level.
- **Don't dispatch the three passes serially.** Single message, parallel.
