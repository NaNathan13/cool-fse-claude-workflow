# Quality Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thread the five block-quality dimensions — visual quality, ADA, cross-browser, mobile, ACF editor UX — through every phase of the cool-fse kit as a named "Quality Bar," and add the Temper passes that audit it.

**Architecture:** Edit the kit *source* in `kit/` and `templates/` (installed instances pull from `main` via `update.sh` — not in scope here). Add one new skill (`appraise`, a design-review pass). Wire two new Temper subagents (ACF editor-UX, design review) plus a cross-browser compat-lint section into the existing code-review subagent. The four-phase model is unchanged — no new top-level phase.

**Tech Stack:** Markdown skill files, `WORKFLOW.md`, Bash installer (`setup.sh`, not modified — it auto-discovers skill dirs). No unit-test framework exists for this kit (design-note #3); "verification" here means cross-file consistency greps + a token sweep.

**Decisions driving this plan** (from `.claude/RECOMMENDATIONS.md`, locked 2026-05-14):
1. Visual review → new dedicated `appraise` design-review skill, Temper `--visual` subagent.
2. a11y blocking → no change; stays suggestions-only. **No work required.**
3. ACF editor-UX → dedicated Temper subagent, runs by default.
4. Cross-browser → static compat lint inside the code-review subagent only.

---

## File Structure

| File | Responsibility | Change |
|---|---|---|
| `kit/WORKFLOW.md` | Methodology | Add `## The Quality Bar`; add `## Quality Bar` to plan-format; update sub-skills table, cheat sheet, worked example |
| `kit/.claude/skills/ponder/SKILL.md` | Phase 1 | Rename always-ask block to "the Quality Bar," expand to 5 dimensions |
| `kit/.claude/skills/inscribe/SKILL.md` | Plan writer | Add `## Quality Bar` to the plan template |
| `kit/.claude/skills/forge/SKILL.md` | Phase 2 | Add cross-browser, interactive-states, mobile conventions; reference the plan's Quality Bar |
| `kit/.claude/skills/temper/SKILL.md` | Phase 3 | Add compat-lint to code review; add ACF editor-UX subagent; wire in `appraise`; update dispatch logic + report template |
| `kit/.claude/skills/appraise/SKILL.md` | **New** — design-review pass | Create the skill |
| `templates/CLAUDE.md.template` | Project entry point | One-line pointer to the Quality Bar |
| `docs/design-notes.md` | Rationale record | Update decision #12; add decision #17 |

`setup.sh` is **not** modified: it derives the skill list from `kit/.claude/skills/*/` at install time (lines 162-165), so the new `appraise/` dir is picked up automatically.

---

## Task 0: Branch

- [ ] **Step 1: Create a working branch**

Current branch is `main`. Branch before editing.

Run:
```bash
cd /Users/nathanwilson/Documents/Nathan/Projects/cool-fse-claude-workflow
git checkout -b feat/quality-bar
```
Expected: `Switched to a new branch 'feat/quality-bar'`

---

## Task 1: Quality Bar foundation in WORKFLOW.md

Everything downstream references this. Do it first.

**Files:**
- Modify: `kit/WORKFLOW.md` — add a section after `## The three lanes` (ends ~line 49); add `## Quality Bar` to the plan-format block (~lines 55-106)

- [ ] **Step 1: Add the `## The Quality Bar` section**

Insert this new section in `kit/WORKFLOW.md` immediately after the `## The three lanes` section (after the "Rule of thumb" line, before `## Plan file format`):

```markdown
## The Quality Bar

Every non-trivial block is built against five quality dimensions, named collectively
the **Quality Bar**. They thread through every phase.

| Dimension | What it means |
|---|---|
| **Visual quality** | The block looks deliberately designed — spacing rhythm, type hierarchy, polish. Not generic. |
| **ADA / accessibility** | Keyboard-operable, semantic markup, WCAG AA contrast, reduced-motion respected. |
| **Cross-browser** | Works on the latest Chrome, Firefox, Safari, and Edge. No IE. |
| **Mobile** | Deliberately designed at the 768px breakpoint and below — not just "doesn't break." |
| **ACF editor UX** | The field group is pleasant for a content editor — instructions, sensible labels, required flags, grouped fields. |

- **Ponder** asks about all five (the always-ask block).
- **Inscribe** writes a `## Quality Bar` section into the plan — one concrete, checkable target per dimension.
- **Forge** builds to those targets.
- **Temper** audits each Quality Bar line: one check per dimension.

The Quality Bar is not an approval gate — it's a shared checklist so "looks good" and
"accessible" have written criteria instead of being left to judgment. Dark/light
background support is asked alongside it but is tracked in Design Decisions, not the Bar.
```

- [ ] **Step 2: Add `## Quality Bar` to the plan file format**

In the `## Plan file format` fenced template (`kit/WORKFLOW.md` ~lines 57-106), insert this block immediately after the `## Design Decisions` entry and before `## Approval Gates (pre-approved)`:

```markdown
## Quality Bar
One concrete, checkable target per dimension (see WORKFLOW.md → The Quality Bar).
Temper audits one check per line. "N/A" only with a reason.
```

- [ ] **Step 3: Verify the section landed and is referenced consistently**

Run:
```bash
grep -n "Quality Bar" kit/WORKFLOW.md
```
Expected: matches for the new `## The Quality Bar` heading, the table intro, the four phase bullets, and the new `## Quality Bar` plan-format entry (6+ lines).

- [ ] **Step 4: Commit**

```bash
git add kit/WORKFLOW.md
git commit -m "feat(workflow): define the five-dimension Quality Bar"
```

---

## Task 2: Ponder — expand always-asks to the Quality Bar

**Files:**
- Modify: `kit/.claude/skills/ponder/SKILL.md:45-53` — the "Always-ask questions" block

- [ ] **Step 1: Replace the always-ask block**

In `kit/.claude/skills/ponder/SKILL.md`, replace the existing block that starts with `**Always-ask questions (every non-trivial ponder session):**` and ends at the line before `### 4. Mid-grill lane decision` with:

```markdown
**Always-ask questions — the Quality Bar (every non-trivial ponder session):**

These surface the five Quality Bar dimensions (see `WORKFLOW.md` → The Quality Bar).
The answers feed the plan's `## Quality Bar` and `## Verification` sections. One per turn.

1. **Visual quality** — "Is there a comp, Figma link, or existing block to mirror? If not, describe the look you're after." A block with no visual reference can't be reviewed for design quality — push for one before accepting "waived."
2. **Mobile** — "How should this behave on mobile? Same layout scaled down, stacked, hidden, or something else?" (Theme breaks at 768px; `mobile:` utility prefix variants exist.)
3. **Dark/light background** — "Does this need to work on both dark backgrounds with light text AND light backgrounds with dark text, or just one?" (Affects color token choices and whether the plan needs a color-scheme gate. Tracked in Design Decisions, not the Quality Bar.)
4. **Accessibility** — "Any specific accessibility requirements? Keyboard nav, screen reader announcements, ARIA roles, reduced-motion support?" (Feeds the plan's Verification section and Temper's a11y audit.)
5. **ACF editor UX** — "Who edits this block, and how configurable should it be? Any fields that must be required, grouped, or need specific instructions?" (Feeds the plan's Quality Bar ACF line and Temper's ACF editor-UX audit.)

**Cross-browser** is the fifth Quality Bar dimension but rarely varies — state the default rather than asking: "I'll target the latest Chrome/Firefox/Safari/Edge, no IE — flag now if the design needs anything unusual." Only escalate to a real question if the design implies risky CSS.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "Quality Bar\|ACF editor UX\|Cross-browser" kit/.claude/skills/ponder/SKILL.md
```
Expected: the renamed always-ask heading, the ACF editor UX item, and the cross-browser default paragraph.

- [ ] **Step 3: Commit**

```bash
git add kit/.claude/skills/ponder/SKILL.md
git commit -m "feat(ponder): ask the full Quality Bar in every grill"
```

---

## Task 3: Inscribe — add the `## Quality Bar` plan section

**Files:**
- Modify: `kit/.claude/skills/inscribe/SKILL.md:33-92` — the plan template; `:114-123` — Conventions

- [ ] **Step 1: Add `## Quality Bar` to the template**

In `kit/.claude/skills/inscribe/SKILL.md`, in the `## Step 3 — Write the plan` fenced template, insert this block immediately after the `## Design Decisions` entry and before `## Approval Gates (pre-approved)`:

```markdown
## Quality Bar
One concrete, checkable target per dimension. Pull these from the grill's
always-ask answers. Be specific — Temper audits one check per line.
- **Visual quality:** <reference to mirror + the specific look — e.g. "matches Figma in Visual Reference; cards lift 4px on hover">
- **ADA:** <e.g. "keyboard-operable slider, WCAG AA contrast, prefers-reduced-motion disables autoplay">
- **Cross-browser:** <usually "latest Chrome/Firefox/Safari/Edge, no IE"; name any risky CSS feature + its fallback>
- **Mobile:** <e.g. "stacks single-column below 768px; controls stay tap-sized">
- **ACF editor UX:** <e.g. "every field has instructions; repeater rows collapse to the title sub-field; image fields note the 16:9 crop">
```

- [ ] **Step 2: Add a Conventions bullet**

In `kit/.claude/skills/inscribe/SKILL.md`, in the `## Conventions` list, add this bullet after the "Every approval gate named" bullet:

```markdown
- **Every Quality Bar line is concrete.** "Mobile: responsive" is not a target. "Mobile: stacks single-column below 768px" is. Vague lines give Temper nothing to check.
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "Quality Bar" kit/.claude/skills/inscribe/SKILL.md
```
Expected: the `## Quality Bar` template entry plus the new Conventions bullet.

- [ ] **Step 4: Commit**

```bash
git add kit/.claude/skills/inscribe/SKILL.md
git commit -m "feat(inscribe): write a Quality Bar section into every plan"
```

---

## Task 4: Forge — per-dimension build conventions

**Files:**
- Modify: `kit/.claude/skills/forge/SKILL.md:6-9` — intro; `:86-180` — section 9 conventions

- [ ] **Step 1: Reference the Quality Bar in the intro**

In `kit/.claude/skills/forge/SKILL.md`, in the opening paragraph block (after "Read `WORKFLOW.md` once for the contract..."), add this sentence to the end of that paragraph:

```markdown
Build to the plan's `## Quality Bar` — every line there is a target Temper will audit.
```

- [ ] **Step 2: Add three convention subsections to section 9**

In `kit/.claude/skills/forge/SKILL.md`, in `### 9. Follow cool-fse conventions`, add these three subsections immediately before `#### Other rules`:

```markdown
#### Cross-browser

Target the latest Chrome, Firefox, Safari, and Edge. No IE. Before using a recent
CSS feature (`:has()`, `backdrop-filter`, subgrid, `@container` queries, `@property`)
or `top-level await`, confirm baseline support or provide a fallback. When in doubt,
prefer the utility classes — they're already cross-browser-tested.

#### Interactive states

Every interactive element (links, buttons, controls, cards-as-links) gets designed
`:hover`, `:focus-visible`, and `:active` states — never rely on default browser
styling. `cool-fse/blocks/global/css/hover-focus-animations.css` and
`transition-utilities.css` cover most cases. Any animation or transition must honor
`prefers-reduced-motion: reduce`.

#### Mobile

Build the mobile layout the plan's Quality Bar describes — don't leave it to chance.
Apply `mobile:` utility prefixes (breakpoint 768px) on the markup. After building,
the block must hold together at 375px, not merely "not break."
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "Cross-browser\|Interactive states\|prefers-reduced-motion\|Quality Bar" kit/.claude/skills/forge/SKILL.md
```
Expected: the three new subsection headings, the reduced-motion line, and the intro Quality Bar reference.

- [ ] **Step 4: Commit**

```bash
git add kit/.claude/skills/forge/SKILL.md
git commit -m "feat(forge): cross-browser, interactive-state, and mobile conventions"
```

---

## Task 5: Create the `appraise` design-review skill

`appraise` evaluates whether a built block "looks very good." It carries `frontend-design`'s
aesthetic standards but is framed as an *audit* that returns a verdict — it never edits code.
Temper dispatches it as a `--visual` subagent.

**Files:**
- Create: `kit/.claude/skills/appraise/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `kit/.claude/skills/appraise/SKILL.md` with exactly this content:

```markdown
---
name: appraise
description: Design-quality review pass. Sub-skill of Temper — evaluates whether a built block "looks very good" against a fixed aesthetic rubric and returns an Approve / Recommend-changes verdict. Read-and-report only; never edits code. Triggered by /appraise or dispatched by Temper with --visual.
---

You are auditing the **visual design quality** of a block Forge already built. You do
NOT fix anything, rewrite CSS, or run the rest of Temper. You evaluate against a fixed
rubric and return a verdict plus specific, actionable findings.

This is the "looks very good" check. Convention compliance is the code-review subagent's
job, not yours — judge design, not code style.

## Inputs

- The block's rendered page URL (and any auth) — from `CLAUDE.md`
- The plan's `## Visual Reference` and the `## Quality Bar` visual-quality line
- Any `before-*.png` / `temper-*.png` screenshots in `.claude/screenshots/<slug>/`

If you have Playwright access, drive the page yourself and screenshot at desktop and
375px. If not, work from the screenshots provided.

## The rubric

Score each axis Pass / Weak / Fail with a one-line reason:

1. **Spacing & rhythm** — consistent spacing scale; related elements grouped; deliberate breathing room, not arbitrary gaps.
2. **Typographic hierarchy** — clear, distinct levels; sensible line-height and line length; no awkward orphans/widows.
3. **Alignment & structure** — elements align to a visible system; nothing accidentally off-grid.
4. **Visual balance** — weight is distributed deliberately; asymmetry (if any) reads as intentional.
5. **Color & emphasis** — uses theme tokens; emphasis goes where the eye should land; contrast is intentional.
6. **Interactive states** — hover / focus-visible / active / disabled are all designed; transitions feel intentional, not default.
7. **Responsive composition** — the layout is *composed* at 375px, not just unbroken; tap targets are adequate.
8. **Polish / not-generic** — reads as bespoke, not a default AI-generated card. Call out anything that looks templated.

## Output

Return, in this shape:

```
**Verdict:** Approve | Recommend changes

**Rubric:** <8 axes, each Pass/Weak/Fail + one-line reason>

**Findings:**
1. <axis> — <what's wrong> — <concrete change> — <screenshot ref if any>
2. ...
```

Verdict is **Approve** only when no axis is Fail and at most one is Weak. Otherwise
**Recommend changes**.

## Don't do

- **Don't edit, rewrite, or restyle anything.** Report only.
- **Don't audit code conventions, naming, or PHP/JSON correctness.** Not your axis.
- **Don't escalate to blocking.** Temper decides severity; you supply the verdict and findings.
- **Don't run the rest of Temper.** Single pass, single output.
```

- [ ] **Step 2: Verify the skill is well-formed**

Run:
```bash
head -4 kit/.claude/skills/appraise/SKILL.md && echo "---" && grep -n "^## \|^name:\|^description:" kit/.claude/skills/appraise/SKILL.md
```
Expected: valid frontmatter (`name: appraise`, a `description:` line) and the section headings (`## Inputs`, `## The rubric`, `## Output`, `## Don't do`).

- [ ] **Step 3: Commit**

```bash
git add kit/.claude/skills/appraise/SKILL.md
git commit -m "feat(appraise): add the design-quality review skill"
```

---

## Task 6: Temper — wire in the new passes

The biggest task. Temper gains a cross-browser compat-lint check, a new always-on ACF
editor-UX subagent, and a new `--visual` design-review subagent, plus an updated dispatch
table and report template.

**Files:**
- Modify: `kit/.claude/skills/temper/SKILL.md` — intro (~L6-9), section 3 (~L33-39), section 4 (~L40-131), section 6 (~L144-182)

- [ ] **Step 1: Reference the Quality Bar in the intro**

In `kit/.claude/skills/temper/SKILL.md`, add to the end of the opening paragraph (after "Report what you find — do not fix anything yourself unless the user explicitly tells you to."):

```markdown
Audit the work against the plan's `## Quality Bar` — every line there gets one check.
```

- [ ] **Step 2: Rewrite section 3 (Parse flags) for the new subagent set**

Replace the body of `### 3. Parse flags` with:

```markdown
Check if `--visual` was passed as an argument (e.g., `/temper testimonial-slider --visual`).

**Always dispatched (no flag needed):**
- Code review subagent (includes the cross-browser compat lint)
- ACF editor-UX subagent — read-only JSON analysis, cheap, no browser

**Dispatched only with `--visual`:**
- Visual review subagent
- Design review subagent (the `appraise` skill)
- Accessibility subagent

The user is the visual reviewer by default; `--visual` adds the automated browser passes.
```

- [ ] **Step 3: Add the cross-browser compat lint to the code-review subagent**

In `### 4. Dispatch subagents` → `#### Subagent 1 — Code Review (always)`, add this check after check **H. Scope drift** and before the "Subagent should categorize..." line:

```markdown
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
```

- [ ] **Step 4: Add the ACF editor-UX subagent**

In `### 4. Dispatch subagents`, insert this new subagent immediately after `#### Subagent 1 — Code Review (always)` and before the current `#### Subagent 2 — Visual Review`:

```markdown
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
```

- [ ] **Step 5: Renumber the remaining subagents and add Design Review**

The existing `#### Subagent 2 — Visual Review (--visual only)` becomes **Subagent 3**;
`#### Subagent 3 — Accessibility (--visual only)` becomes **Subagent 5**. Insert a new
**Subagent 4 — Design Review** between them. Rename the two existing headings and add:

```markdown
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
```

- [ ] **Step 6: Update the dispatch instruction**

The line under `### 4. Dispatch subagents` currently reads "Send all applicable subagents
in a single message (multiple Agent tool calls)." Replace with:

```markdown
Send all applicable subagents in a single message (multiple Agent tool calls). Default
run = Subagents 1 + 2. With `--visual` = Subagents 1–5.
```

- [ ] **Step 7: Update the report template (section 6)**

In `### 6. Write the report`, in the fenced report template, add an `### ACF Editor UX`
subsection after `### Nits` and before `### Accessibility — suggestions only`, and a
`### Design Review` subsection after `### Visual review`:

```markdown
### ACF Editor UX — suggestions only
1. **<file>** — <issue>. <concrete proposed JSON change>
2. ...
```

```markdown
### Design Review
*(omit unless `--visual` was passed)*
- **Verdict:** Approve | Recommend changes
- Rubric + findings from the `appraise` pass; screenshots in `.claude/screenshots/<slug>/`
```

Also update the `**Counts:**` line in the template to:

```markdown
**Counts:** <X> blocking, <Y> suggested, <Z> nits, <N> a11y suggestions, <M> ACF UX, design verdict: <Approve | Recommend changes>.
```

- [ ] **Step 8: Update the section 7 hand-off**

In `### 7. Hand off`, update the quoted hand-off message's counts line to match:

```markdown
> **<X> blocking, <Y> suggested, <Z> nits, <N> a11y, <M> ACF UX. Design: <verdict>.**
```

- [ ] **Step 9: Verify**

Run:
```bash
grep -n "Subagent [1-5]\|compat lint\|ACF Editor UX\|Design Review\|appraise\|Quality Bar" kit/.claude/skills/temper/SKILL.md
```
Expected: Subagents 1–5 numbered, the compat-lint check (I), Quality Bar coverage check (J), the ACF Editor UX subagent + report subsection, the Design Review subagent + report subsection, and `appraise` referenced.

- [ ] **Step 10: Commit**

```bash
git add kit/.claude/skills/temper/SKILL.md
git commit -m "feat(temper): add compat-lint, ACF editor-UX, and design-review passes"
```

---

## Task 7: WORKFLOW.md cross-references

Now that the skills are updated, fix the WORKFLOW.md references that describe them.

**Files:**
- Modify: `kit/WORKFLOW.md` — phase table (~L15-23), skill cheat sheet (~L142-151), sub-skills table (~L156-165), worked example (~L210-216)

- [ ] **Step 1: Update the Temper row in the phase table**

In the `## The big idea` phase table, change the **Temper** row's "What it does" cell to:

```markdown
| **Temper** | Code review + ACF editor-UX review (always); visual + design + a11y with `--visual`. Audits the Quality Bar. | `## Temper Report` section in the plan |
```

- [ ] **Step 2: Add `/appraise` to the skill cheat sheet**

In `## Skill cheat sheet`, add this row after the `/researcher` row:

```markdown
| `/appraise` | sub-skill of Temper | Design-quality review pass; auto-dispatched by `/temper --visual`, callable stand-alone on a built block |
```

- [ ] **Step 3: Update the sub-skills/subagents table**

In `## Sub-skills and subagents per phase`, replace the **Temper** row with:

```markdown
| **Temper** | `/appraise` (in-kit, via the design-review subagent) | `feature-dev:code-reviewer` + ACF editor-UX agent (always); visual + design-review (`appraise`) + a11y agents (only with `--visual`) | Code review and ACF editor-UX run every time. `--visual` adds the three browser-driven passes, dispatched in a single parallel message. |
```

- [ ] **Step 4: Update the worked example**

In `### Standard — new testimonial slider block`, replace the `Session 3: /temper testimonial-slider` block with:

```markdown
Session 3: /temper testimonial-slider
  → dispatches code-review + ACF editor-UX subagents (always)
  → (with --visual: also dispatches visual + design-review + a11y subagents)
  → appends "## Temper Report" with findings, including the design verdict
  → "<X> blocking, <Y> suggested, <Z> nits, ..."
  → user fixes blockers (in this session, manually, or whatever)
```

- [ ] **Step 5: Verify**

Run:
```bash
grep -n "appraise\|ACF editor-UX\|design-review\|Quality Bar" kit/WORKFLOW.md
```
Expected: the cheat-sheet row, the sub-skills table row, the phase-table cell, and the worked-example lines.

- [ ] **Step 6: Commit**

```bash
git add kit/WORKFLOW.md
git commit -m "docs(workflow): document the new Temper passes and appraise skill"
```

---

## Task 8: design-notes.md and CLAUDE.md.template

**Files:**
- Modify: `docs/design-notes.md` — decision #12 (~L66-68); add decision #17
- Modify: `templates/CLAUDE.md.template` — `## Workflow` section (~L143-147)

- [ ] **Step 1: Update design-note #12**

In `docs/design-notes.md`, replace the body of `### 12. Temper has no auto-fix loop` with:

```markdown
Reports findings; user directs the fix. Auto-fix loops at this scale create more
confusion than they save. Two subagents always run (code review, ACF editor-UX);
`--visual` adds three more in parallel (visual review, design review via `appraise`,
accessibility). Accessibility findings stay suggestions-only — see decision #17.
```

- [ ] **Step 2: Add design-note #17**

In `docs/design-notes.md`, add at the end of the `## Locked-in decisions` section (after decision #16):

```markdown
### 17. The Quality Bar — five named dimensions, threaded through every phase

Visual quality, ADA, cross-browser, mobile, ACF editor UX. Ponder asks all five,
Inscribe writes a `## Quality Bar` plan section with one concrete target per dimension,
Forge builds to it, Temper audits one check per line. It is a shared checklist, not an
approval gate. Accessibility stays suggestions-only even though it's on the Bar — the
written target is intent for the human reviewer and the `--visual` a11y pass, not an
automated blocker. Cross-browser is enforced by a static compat lint inside the
code-review subagent, not by live multi-engine testing.
```

- [ ] **Step 3: Add a Quality Bar pointer to CLAUDE.md.template**

In `templates/CLAUDE.md.template`, in the `## Workflow` section, add after the first paragraph (the one ending "...Read `CONTEXT.md` for canonical names and synonyms-to-avoid."):

```markdown
Every non-trivial block is built against the five-dimension **Quality Bar** (visual
quality, ADA, cross-browser, mobile, ACF editor UX) — see `WORKFLOW.md`.
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -n "Quality Bar\|appraise\|design review" docs/design-notes.md templates/CLAUDE.md.template
```
Expected: decision #17, the updated #12, and the CLAUDE.md.template pointer.

- [ ] **Step 5: Commit**

```bash
git add docs/design-notes.md templates/CLAUDE.md.template
git commit -m "docs: record the Quality Bar decision and update Temper rationale"
```

---

## Task 9: Final consistency sweep

No code to run — this kit has no test suite. Verify cross-file consistency and that no
broken template tokens were introduced.

**Files:** none modified unless the sweep finds an issue.

- [ ] **Step 1: Token sweep — confirm only the four valid tokens appear**

Run:
```bash
grep -rhoE '\{\{[A-Z_]+\}\}' kit/ templates/ | sort -u
```
Expected: exactly `{{CHILD_THEME_DIR}}`, `{{LOCAL_PORT}}`, `{{LOCAL_URL}}`, `{{PROJECT_NAME}}` — nothing else. Any other token is a typo introduced by this plan; fix it.

- [ ] **Step 2: Confirm the new skill is discoverable by the installer**

Run:
```bash
for d in kit/.claude/skills/*/; do basename "$d"; done
```
Expected: `appraise forge inscribe ponder researcher seal temper` — `appraise` present. (`setup.sh` lines 162-165 glob this same path, so presence here = auto-installed.)

- [ ] **Step 3: Confirm "Quality Bar" is threaded through all four phase skills + WORKFLOW**

Run:
```bash
grep -rl "Quality Bar" kit/WORKFLOW.md kit/.claude/skills/ponder/SKILL.md kit/.claude/skills/inscribe/SKILL.md kit/.claude/skills/forge/SKILL.md kit/.claude/skills/temper/SKILL.md
```
Expected: all five files listed.

- [ ] **Step 4: Confirm subagent numbering in Temper is sequential with no gaps or dupes**

Run:
```bash
grep -nE '^#### Subagent [0-9]' kit/.claude/skills/temper/SKILL.md
```
Expected: Subagent 1 through 5, in order, each once.

- [ ] **Step 5: Confirm `setup.sh` was not modified**

Run:
```bash
git diff --name-only main -- setup.sh
```
Expected: no output (setup.sh unchanged — it auto-discovers the new skill).

- [ ] **Step 6: Update RECOMMENDATIONS.md status line and commit the sweep**

In `.claude/RECOMMENDATIONS.md`, change the status line under the title from
`**Status:** decisions locked 2026-05-14 (see end of doc). Next: dedicated plan of action.`
to:
`**Status:** implemented 2026-05-14 — see \`.claude/PLAN-OF-ACTION.md\`.`

Then:
```bash
git add .claude/RECOMMENDATIONS.md
git commit -m "docs: mark Quality Bar recommendations as implemented"
```

---

## Self-Review

**Spec coverage** (against `.claude/RECOMMENDATIONS.md`):
- R1 Quality Bar → Tasks 1 (WORKFLOW), 2 (Ponder), 3 (Inscribe), 4 (Forge), 6 (Temper audit). ✓
- R2 cross-browser compat lint → Task 6 Step 3 (code-review check I) + Task 4 Step 2 (Forge convention). ✓
- R3 ACF editor-UX subagent → Task 6 Step 4 + report subsection Step 7. ✓
- R4 a11y blocking → no change required; recorded in design-note #17 (Task 8). ✓
- R5 appraise design-review skill → Task 5 (skill) + Task 6 Step 5 (Temper wiring) + Task 4 (Forge interactive states) + Task 2 (Ponder visual-reference push). ✓

**Placeholder scan:** every step shows the exact prose to insert and an exact verify command. No TBDs.

**Type/name consistency:** skill named `appraise` in Tasks 5, 6, 7, 8. Subagents numbered 1 (Code Review) → 2 (ACF Editor UX) → 3 (Visual Review) → 4 (Design Review) → 5 (Accessibility) consistently across Task 6 and the WORKFLOW/design-notes references. Report subsections `### ACF Editor UX` and `### Design Review` match between Task 6 Step 7 and the WORKFLOW worked example.

---

## Execution Handoff

Plan complete and saved to `.claude/PLAN-OF-ACTION.md`. Two execution options:

1. **Subagent-Driven (recommended)** — a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session with checkpoints for review.

Which approach?
