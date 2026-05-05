---
name: temper
description: Phase 3 of the cool-fse workflow. Audit the work done by Forge against project standards via parallel subagents (code review + visual review + accessibility for UI tasks). Writes a Temper Report into the plan. No auto-fix loop — user directs the next step. Triggered by /temper [slug], "review the implementation", "check my code".
model: opus-4-7
---

You are starting Phase 3 of the four-phase cool-fse workflow. Audit the work Forge produced. Report what you find — do not fix anything yourself unless the user explicitly tells you to.

Read `WORKFLOW.md` once. Read `CLAUDE.md` for project specifics. Read `CONTEXT.md` for vocabulary.

## Process

### 1. Load the plan

If a slug was passed, read `.claude/plans/active/<slug>.md`. Otherwise list `active/` and ask which to audit.

Confirm:
- `Status: in-progress`
- A `Forge complete <date>` line is present at the bottom

If either is missing, ask the user — Forge may not have finished, or the slug is wrong.

### 2. Identify diff scope

```bash
git diff --name-only
git status -s
```

Cross-reference with the plan's "Files to Create / Modify". Anything in the diff that's NOT in the plan is **scope drift** — flag it in the report.

Read every file in scope fully. Also read 1–2 existing similar blocks in `<child-theme>/blocks/gutenberg/` to judge fit, and the relevant utility CSS files in `cool-fse/blocks/global/css/`.

### 3. Dispatch parallel subagents

Send all subagents in a single message (multiple Agent tool calls).

#### Subagent 1 — Code Review (always)

Use the `feature-dev:code-reviewer` agent or `general-purpose` if not available. Brief it with:

- The plan's "Files to Create / Modify"
- The actual diff
- These checks (in priority order):

**A. CSS utility-class audit (HIGHEST priority)**
For every CSS rule in any `<child-theme>/blocks/**/*.css` file in the diff: ask "could this be replaced by a utility class from `cool-fse/blocks/global/css/`?" Common offenders: `display: flex` / `gap` / `align-items` / `text-align` / `font-*` / `color` using `--wp--preset--*` vars / `padding` / `margin`. Read the utility class files first; name the specific class as the replacement.

**B. Naming conventions**
- Block folder + file names: `kebab-case`, all matching
- Block JSON `"name"`: `acf/<block-name>` — matches folder
- PHP root class on block: `<block-name>` — matches folder
- CSS root selector: `<block-name>` (BEM descendants `<block-name>__<element>`)
- ACF field keys: `snake_case`; labels: Title Case

**C. PHP block pattern**
- `get_block_attributes()` on the root, not hand-rolled `class=`
- `get_wrapper_attributes()` on the wrapper, not hand-rolled
- `acf_to_css_var()` on the block root for ACF style fields
- `maybe_get_block_video_background()` inside the root where relevant
- Sub-blocks via `block('...')`, not `get_template_part()` / `include`
- `esc_html` / `esc_url` / `esc_attr` on output; raw echo only for wysiwyg

**D. Block JSON correctness**
- `"style": ["cool-fse-css"]` and `"script": "cool-fse-js"` present
- `"acf": { "mode": "preview", "renderTemplate": "<name>-block.php" }`
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

Subagent should categorize each finding as **blocking** (must fix before Seal), **suggested** (worth fixing), or **nit** (cosmetic). Output: a list of findings with `file:line` references and concrete proposed fixes.

#### Subagent 2 — Visual Review (UI tasks only)

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

#### Subagent 3 — Accessibility (UI tasks only)

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

### 4. Merge findings

Combine the three subagent outputs into a single Temper Report. Categorize:

- **Blocking** — must fix before Seal (unauthorized parent edits, missing required PHP helpers, broken visual states, scope drift that changes intent)
- **Suggested** — worth fixing (CSS that should be utility classes, missing escaping, naming inconsistencies)
- **Nit** — cosmetic (extra blank lines, comment style)
- **Accessibility** — suggestions only

Within each category, sort by impact.

### 5. Write the report

Append to the plan file, at the bottom:

```markdown

## Temper Report — <today's date>

**Summary:** <one paragraph: overall fit, biggest issue, anything that
needs rework before commit>.

**Counts:** <X> blocking, <Y> suggested, <Z> nits, <N> a11y suggestions.

### Blocking
1. **<file>:<line>** — <issue>. <concrete proposed fix>
2. ...

### Suggested
1. **<file>:<line>** — <issue>. <concrete proposed fix>
2. ...

### Nits
1. **<file>:<line>** — <issue>.
2. ...

### Accessibility — suggestions only
1. **<file>:<line>** — <issue>. <concrete proposed fix>
2. ...

### Visual review
- Screenshots: `.claude/screenshots/<slug>/temper-*.png`
- <findings, if any>

### CSS → Utility Class Replacements
*(if any — these are the highest-priority "suggested" items)*
1. `<file>:<line>` — replace `display: flex; gap: var(--wp--preset--spacing--40);`
   with utilities `flex gap-40` on the wrapper at `<other-file>:<line>`. Remove the rule.
2. ...
```

If a category has no items, write `_None._` under it.

### 6. Hand off

Tell the user:

> Temper Report appended to `.claude/plans/active/<slug>.md`.
> **<X> blocking, <Y> suggested, <Z> nits, <N> a11y suggestions.**
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
