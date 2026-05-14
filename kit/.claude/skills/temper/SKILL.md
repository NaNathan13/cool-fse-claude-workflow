---
name: temper
description: "Phase 3 of the cool-fse workflow. Audit the work done by Forge against project standards. Default: code review + ACF editor-UX. Pass --visual for visual, design, and a11y passes too. Writes a Temper Report into the plan. No auto-fix loop — user directs the next step. Triggered by /temper [slug] [--visual], \"review the implementation\", \"check my code\"."
---

You are starting Phase 3 of the four-phase cool-fse workflow. Audit the work Forge produced. Report what you find — do not fix anything yourself unless the user explicitly tells you to. Audit the work against the plan's `## Quality Bar` — every line there gets one check.

Read `WORKFLOW.md` once. Read `CLAUDE.md` for project specifics. Read `CONTEXT.md` for vocabulary.

## Process

### 1. Load the plan

If a slug was passed, read `.claude/plans/active/<slug>.md`. Otherwise list `active/` and ask which to audit.

Confirm:
- `Status: in-progress`
- A `Forge complete <date>` line is present (after a `---` rule near the bottom)

If either is missing, ask the user — Forge may not have finished, or the slug is wrong.

### 2. Identify diff scope

```bash
git diff --name-only
git status -s
```

Cross-reference with the plan's "Files to Create / Modify". Anything in the diff that's NOT in the plan is **scope drift** — flag it in the report.

Read every file in scope fully. Also read 1–2 existing similar blocks in `{{CHILD_THEME_DIR}}/blocks/gutenberg/` to judge fit, and the relevant utility CSS files in `cool-fse/blocks/global/css/`.

### 3. Parse flags

Check if `--visual` was passed as an argument (e.g., `/temper testimonial-slider --visual`).

**Always dispatched (no flag needed):**
- Code review subagent (includes the cross-browser compat lint)
- ACF editor-UX subagent — read-only JSON analysis, cheap, no browser

**Dispatched only with `--visual`:**
- Visual review subagent
- Design review subagent (the `appraise` skill)
- Accessibility subagent

The user is the visual reviewer by default; `--visual` adds the automated browser passes.

### 4. Dispatch subagents

Send all applicable subagents in a single message (multiple Agent tool calls). Default
run = Subagents 1 + 2. With `--visual` = Subagents 1–5.

#### Subagent 1 — Code Review (always)

Use `feature-dev:code-reviewer` as the subagent type. If the Agent tool returns an error for that type, retry with `general-purpose`. Brief it with:

- The plan's "Files to Create / Modify"
- The actual diff
- These checks (in priority order):

**A. CSS utility-class audit (HIGHEST priority)**
For every CSS rule in any `{{CHILD_THEME_DIR}}/blocks/**/*.css` file in the diff: ask "could this be replaced by a utility class from `cool-fse/blocks/global/css/`?" Common offenders: `display: flex` / `gap` / `align-items` / `text-align` / `font-*` / `color` using `--wp--preset--*` vars / `padding` / `margin`. Read the utility class files first; name the specific class as the replacement.

**B. Naming conventions**
- Block folder + file names: `kebab-case`, all matching
- Block JSON `"name"`: `acf/<block-name>` — matches folder
- PHP root class on block: `<block-name>` — matches folder
- CSS root selector: `<block-name>` (BEM descendants `<block-name>--<element>`, double hyphen not `__`)
- ACF field keys: `snake_case`; labels: Title Case

**C. PHP block pattern**
- `get_block_attributes()` on the root, not hand-rolled `class=`
- `get_wrapper_attributes()` on the wrapper, not hand-rolled
- `acf_to_css_var()` on the block root for ACF style fields
- `maybe_get_block_video_background()` inside the root where relevant
- Sub-blocks via `block('...')`, not `get_template_part()` / `include`
- `esc_html` / `esc_url` / `esc_attr` on output; raw echo only for wysiwyg
- Image fields not using `return_format: id` or not rendered via `img_if()` = **blocking**
- ACF link fields not rendered via `acf_link()` = **blocking**

**D. Block JSON correctness**
- `"style": ["cool-fse-css"]` and `"script": "cool-fse-js"` present
- `"acf": { "mode": "preview", "renderCallback": "acf_display_gutenberg_block_callback" }`
- `"category"` set

**E. ACF JSON correctness**
- Field group edited directly in `acf-json/` (no WP-Admin-export artifacts like unexpected `modified` keys)
- Field key naming consistent with neighboring groups

**F. Hygiene**
- No `var_dump`, `print_r`, `console.log`
- No commented-out code
- No magic numbers or hardcoded hex
- No inline `style=""` outside `acf_to_css_var()` output
- No `!important` without a comment explaining why

**G. Unauthorized `cool-fse/` edits**
Anything modified inside `cool-fse/` that isn't in the plan's pre-approved gate list = **blocking**.

**H. Scope drift**
Files in the diff not in the plan = flag, may be **suggested** or **blocking** depending on what they are.

**I. Cross-browser compat lint**
For every CSS/JS feature in the diff, flag anything outside the support matrix (latest
Chrome/Firefox/Safari/Edge, no IE). Watch for: `:has()`, `backdrop-filter`, subgrid,
`@container` queries, `@property`, top-level `await`. For each flag, name the concern
and a fallback. Categorize as **suggested** — unless the feature has no fallback and
breaks layout in a supported browser, then **blocking**.

**J. Quality Bar coverage**
Cross-reference the plan's `## Quality Bar`. For each line, confirm the diff actually
addresses it (e.g., a "stacks below 768px" line implies `mobile:` utilities in the
markup). A Quality Bar line with no corresponding implementation = **suggested**.

Subagent should categorize each finding as **blocking** (must fix before Seal), **suggested** (worth fixing), or **nit** (cosmetic). Output: a list of findings with `file:line` references and concrete proposed fixes.

#### Subagent 2 — ACF Editor UX (always)

Use the `general-purpose` agent (or `Explore`). Read-only JSON analysis — no browser
needed, so this runs every Temper. Brief it with the diff's
`{{CHILD_THEME_DIR}}/acf-json/*.json` files and the plan's `## Quality Bar` ACF line.
Checks:

- **Instructions** — every field has a non-empty `instructions` string describing what
  it does and any constraint (image dimensions/aspect, character limits).
- **Required** — `required: 1` on every field the block can't render without
  (cross-check the block PHP's early-return conditions).
- **Repeaters** — `collapsed` set to a meaningful sub-field key (rows stay labeled when
  collapsed); `button_label` is specific ("Add Resource", not the default "Add Row");
  `min`/`max` set where the design implies bounds.
- **Grouping & order** — related fields grouped via `tab` / `group` / `accordion`; field
  order matches the block's visual order.
- **Conditional logic** — fields irrelevant to the current selection are hidden.
- **Labels** — Title Case, jargon-free, consistent with `CONTEXT.md` vocabulary.
- **Preview** — block JSON has an `example` so preview mode renders.

Output: findings with `file` references and concrete proposed JSON changes. Categorize
as **suggested** or **nit** — ACF editor-UX findings are never blocking.

#### Subagent 3 — Visual Review (`--visual` only)

Skip this subagent unless `--visual` was passed.

Use Playwright (or the `general-purpose` agent with Playwright access). Brief it with:

- The plan's "Verification" section
- The local URL and any auth (from `CLAUDE.md`)
- Any `before-*.png` screenshots already in `.claude/screenshots/<slug>/`

Have it:
- Drive the same flow Forge ran
- Take fresh `temper-*.png` screenshots
- Compare to `before-*.png` if any exist
- Check adjacent areas of the page for unintended visual regressions
- Note anything that doesn't match the plan's visual reference

Output: list of visual findings with screenshot paths.

#### Subagent 4 — Design Review (`--visual` only)

Skip unless `--visual` was passed. Dispatch a `general-purpose` agent with Playwright
access and have it follow the `appraise` skill. Brief it with:

- The plan's `## Visual Reference` and the `## Quality Bar` visual-quality line
- The local URL and any auth (from `CLAUDE.md`)
- The block's page URL

`appraise` evaluates design quality against a fixed rubric and returns a verdict
(**Approve** / **Recommend changes**) plus actionable findings. Design-review findings
are **suggested** — unless they contradict the plan's `## Visual Reference`, then
**blocking**.

#### Subagent 5 — Accessibility (`--visual` only)

Skip this subagent unless `--visual` was passed.

Use the `general-purpose` agent. Brief it with the same scope. Run these checks:

- Semantic HTML (proper headings, lists, landmarks)
- Heading hierarchy (no skipped levels)
- Alt text on all `<img>` (empty `alt=""` for decorative is OK)
- ARIA attributes on custom elements that need them
- Keyboard navigability — every interactive element reachable + has visible focus state
- Color contrast on text (target WCAG AA)
- Form labels (if any)
- Reduced-motion respect (any animation should honor `prefers-reduced-motion`)

Output: a list of suggestions. **Accessibility findings are never blocking.** They go in their own subsection of the report (`### Accessibility — suggestions only`).

### 5. Merge findings

Combine subagent outputs into a single Temper Report. Categorize:

- **Blocking** — must fix before Seal (unauthorized parent edits, missing required PHP helpers, broken visual states, scope drift that changes intent)
- **Suggested** — worth fixing (CSS that should be utility classes, missing escaping, naming inconsistencies)
- **Nit** — cosmetic (extra blank lines, comment style)
- **Accessibility** — suggestions only
- **ACF Editor UX** — suggestions only, never blocking; its own report subsection
- **Design Review** — the `appraise` verdict pass; its own report subsection; omit if `--visual` was not passed

Within each category, sort by impact.

### 6. Write the report

Append to the plan file, at the bottom:

```markdown

## Temper Report — <today's date>

**Summary:** <one paragraph: overall fit, biggest issue, anything that
needs rework before commit>.

**Counts:** <X> blocking, <Y> suggested, <Z> nits, <N> a11y, <M> ACF UX, design verdict: <Approve | Recommend changes>.

### Blocking
1. **<file>:<line>** — <issue>. <concrete proposed fix>
2. ...

### Suggested
1. **<file>:<line>** — <issue>. <concrete proposed fix>
2. ...

### Nits
1. **<file>:<line>** — <issue>.
2. ...

### ACF Editor UX — suggestions only
1. **<file>** — <issue>. <concrete proposed JSON change>
2. ...

### Accessibility — suggestions only
1. **<file>:<line>** — <issue>. <concrete proposed fix>
2. ...

### Visual Review
*(omit this section if `--visual` was not passed)*
- Screenshots: `.claude/screenshots/<slug>/temper-*.png`
- <findings, if any>

### Design Review
*(omit unless `--visual` was passed)*
- **Verdict:** Approve | Recommend changes
- Rubric + findings from the `appraise` pass; screenshots in `.claude/screenshots/<slug>/`

### CSS → Utility Class Replacements
*(if any — these are the highest-priority "suggested" items)*
1. `<file>:<line>` — replace `display: flex; gap: var(--wp--preset--spacing--40);`
   with utilities `flex gap-40` on the wrapper at `<other-file>:<line>`. Remove the rule.
2. ...
```

If a category has no items, write `_None._` under it. Omit a flag-gated section entirely (Visual Review, Design Review) when its flag wasn't passed.

### 7. Hand off

Tell the user:

> Temper Report appended to `.claude/plans/active/<slug>.md`.
> **<X> blocking, <Y> suggested, <Z> nits, <N> a11y, <M> ACF UX. Design: <verdict>.**
> What do you want to do — fix in this session, fix manually, or proceed to `/seal`?

Wait. **Do NOT auto-fix.** The user decides.

If they ask for fixes, do them in this session and append a `### Temper fixes — <date>` subsection noting what was fixed. Then hand off again.

If they say proceed to seal, do nothing further — they'll start a new session.

## Don't do

- **Don't auto-fix anything without permission.** Report and wait.
- **Don't run the full Forge process again.** Temper is audit-only.
- **Don't run `git commit`.**
- **Don't escalate accessibility findings to blocking** unless the plan explicitly required a level (e.g., "must pass WCAG AA").
- **Don't dispatch subagents serially when they could run in parallel.** Single message, multiple Agent calls.
