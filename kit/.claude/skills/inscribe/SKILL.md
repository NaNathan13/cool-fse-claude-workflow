---
name: inscribe
description: Write an implementation plan to .claude/plans/active/ from a resolved set of design decisions. The handoff between Ponder and Forge — callable standalone when the grill is already done. Triggered by /inscribe, "write the plan", "write it up".
---

You write a cool-fse implementation plan. The design decisions are already resolved —
your only job is a precise, Forge-ready plan file. Do NOT grill, do NOT ask open-ended
questions, do NOT write code.

## Inputs

Resolved decisions come from one of:
- A `/ponder` session that finished grilling and handed off to you.
- A direct `/inscribe` invocation where the user pastes or describes the decisions.

If critical information is missing (files to touch, lane, slug), ask once with
AskUserQuestion before writing. Don't guess.

## Step 1 — Orient

Read if not already in context:
- `WORKFLOW.md` — plan-format contract
- `CLAUDE.md` — project specifics (child theme dir, local URL)
- `CONVENTIONS.md` — coding standards (so the Approach is concrete and buildable)
- `ls .claude/plans/active/` — avoid duplicating a slug

## Step 2 — Slug and lane

- **Slug:** kebab-case from the task name ("accent background image" → `accent-background-image`). If a plan for the same block exists, suffix to disambiguate.
- **Lane:** from the grill. If unstated, default `standard` for ≤5 files, `large` for bigger / sliced.

## Step 3 — Write the plan

Save `.claude/plans/active/<slug>.md` with the Write tool. Exactly this structure:

```markdown
# <Plan Title>

**Status:** in-progress
**Lane:** standard | large
**Source:** Ponder session <today's date YYYY-MM-DD>

## TL;DR
One paragraph. What we're building, for whom, why.

## What We're Building
Editor POV: what they configure. Visitor POV: what they see.

## Design Decisions
Numbered. Each line: decision — rationale. Specific enough that Forge never guesses.

## Quality Bar
One concrete, checkable target per dimension (Temper audits one check per line):
- **Visual quality:** <reference to mirror + the specific look>
- **ADA:** <e.g. keyboard-operable, WCAG AA contrast, prefers-reduced-motion handling>
- **Cross-browser:** <usually "latest Chrome/Firefox/Safari/Edge, no IE"; name risky features + fallback>
- **Mobile:** <e.g. "stacks single-column below 768px; tap targets stay sized">
- **ACF editor UX:** <e.g. "every field has instructions; repeater rows collapse to a title field">

## Approval Gates (pre-approved)
Every gated action this plan authorizes, so Forge does NOT re-prompt. Common: touching
cool-fse/, new block-level CSS, ACF JSON hand-edits, new FSE template sections,
functions.php hook changes. Write "None" if it triggers no gates.

## Files to Create / Modify
**Create:**
- [ ] `<path>`
**Modify:**
- [ ] `<path>`

## Approach
Per-file/step prose. Real file names, real utility classes, real ACF field keys, real
custom element tags. Specific enough that Forge executes without judgment calls. For each
file: what changes, where, why.

## Visual Reference
Paths to `.claude/screenshots/<slug>/`, Figma links, or "waived".

## Out of Scope
Things that came up but aren't being built this pass.

## Verification
Page URL: <local URL, or "n/a — no live server this pass">
- [ ] Renders in the editor (preview mode)
- [ ] Renders on the front end (matches editor)
- [ ] Empty/partial field data — no PHP errors, graceful fallback
- [ ] Light background and dark background
- [ ] Mobile viewport (375px)
- [ ] <block-specific interactions>

## Slices  *(large lane only — omit for standard)*
1. <slice 1 — independently buildable>

## Open Questions
Empty unless genuinely unresolved. Forge pauses on anything listed here.
```

## Step 4 — Hand off

Output this verbatim, with `<slug>` filled in:

> Plan saved to `.claude/plans/active/<slug>.md`.
>
> Open a **fresh Claude Code session** at the themes root and paste:
>
> ````
> /forge <slug>
> ````

Then stop. Do not continue into Forge. Do not write code.

## Conventions

- **ACF field keys follow the naming guidance in `CONVENTIONS.md`.**
- **Concrete, not hand-wavy.** Undecided ACF key? Decide it now and write it down.
- **Every approval gate named** — Forge should discover none mid-build.
- **Every Quality Bar line is concrete.** "Mobile: responsive" is not a target; "stacks single-column below 768px" is.
- **Image fields: specify `return_format: id`** and the `img_if()` size for each. Flag the rare URL exception with rationale.
- **New blocks: note `category`, `keywords`, and `icon` concept** (Forge picks the SVG).
- **No code in this file.** The plan describes intent; Forge writes code.
- **Do not commit.** Plan files are never committed from this skill.
