---
name: inscribe
description: Write an implementation plan to .claude/plans/active/ from a resolved set of design decisions. Sub-skill of Ponder, but callable standalone when the grill is already done. Triggered by /inscribe, "write the plan", "write it up".
---

You are writing a cool-fse implementation plan. The design decisions are already resolved — your only job is to produce a precise, Forge-ready plan file. Do NOT grill, do NOT ask open-ended questions, do NOT write code.

## Inputs

You receive resolved design decisions from one of:
- A completed `/grill-me` session in this conversation.
- A `/ponder` session that has finished grilling and asked you to write.
- A direct `/inscribe` invocation where the user pastes or describes the decisions inline.

If critical information is missing (files to touch, lane, slug), ask for it once with AskUserQuestion before writing. Do not guess.

## Step 1 — Orient

Read these if not already in context:
- `WORKFLOW.md` (at themes root) — plan format contract
- `CLAUDE.md` (at themes root) — project specifics (child theme dir name, local URL, conventions)
- `ls .claude/plans/active/` — avoid duplicating a slug that already exists

## Step 2 — Determine slug and lane

- **Slug:** auto-generate kebab-case from the task name ("accent background image" → `accent-background-image`). If a plan for the same block/feature already exists, suffix with the feature name (e.g. `overlapping-content-cta-accent-bg`).
- **Lane:** use the lane from the grill session. If not stated, default to `standard` for anything touching ≤5 files; `large` for anything bigger or with internal slices.

## Step 3 — Write the plan

Save to `.claude/plans/active/<slug>.md` using the Write tool. Use exactly this structure:

```markdown
# <Plan Title>

**Status:** in-progress
**Lane:** standard | large
**Source:** Grill session <today's date YYYY-MM-DD>

## TL;DR
One paragraph. What we're building, for whom, why it matters.

## What We're Building
Editor POV: what they configure.
Visitor POV: what they see.

## Design Decisions
Numbered. Each line: decision — rationale. Be specific enough that Forge
never has to guess what was agreed on.

## Approval Gates (pre-approved)
List every gated action this plan authorizes so Forge does NOT re-prompt.
Common gates: touching cool-fse/, new block-level CSS, ACF JSON hand-edits,
new FSE template sections, functions.php hook changes, risky shell actions.
Write "None" if this plan triggers no gates.

## Files to Create / Modify
**Create:**
- [ ] `<path>`

**Modify:**
- [ ] `<path>`

## Approach
Per-file or per-step prose. Use concrete file names, real utility classes,
real ACF field keys, real custom element tags. Specific enough that Forge can
execute without judgment calls. For each file: what changes, where, and why.

## Visual Reference
Paths to .claude/screenshots/<slug>/ screenshots, Figma links, or "waived".

## Out of Scope
Things that came up but are not being built in this pass.

## Verification
Page URL: <local URL for this block>

- [ ] Block renders correctly in the editor (preview mode)
- [ ] Block renders on the front end (matches editor)
- [ ] Block with empty/partial field data (no PHP errors, graceful fallback)
- [ ] Block on a light background and a dark background
- [ ] Mobile viewport (375px)
- [ ] <block-specific interactions — Inscribe fills these in per-plan>

## Slices  *(large lane only — omit for standard)*
1. <slice 1 — independently buildable>
2. ...

## Open Questions
Empty unless something is genuinely unresolved. Forge will pause on any item
listed here. Ideally empty.
```

## Step 4 — Hand off

Output the hand-off block below verbatim, with `<slug>` filled in. The fenced prompt is meant to be copy-pasted into a fresh Claude Code session to start Forge cleanly.

> Plan saved to `.claude/plans/active/<slug>.md`.
>
> Open a **fresh Claude Code session** at the themes root and paste this prompt to begin Forge:
>
> ````
> /forge <slug>
>
> Read .claude/plans/active/<slug>.md, WORKFLOW.md, and CLAUDE.md before touching
> any code. Trust the plan's pre-approved Approval Gates — do not re-prompt on
> them. Pause if you discover a gate the plan didn't authorize, or if the dev
> server isn't reachable. Verify per the plan's Verification section when done,
> then append the "Forge complete <date>" handoff line.
> ````

Then stop. Do not continue into Forge. Do not make any code changes.

## Conventions

- **ACF field keys must follow the naming convention defined in CONTEXT.md.**
- **Concrete, not hand-wavy.** If an ACF field key isn't decided, decide it now and write it down.
- **Every approval gate named.** Forge should never discover a gate mid-build that the plan didn't pre-authorize.
- **ACF image fields: specify `return_format: id`** for each image field and note the `img_if()` size parameter. Flag the rare URL exception with rationale.
- **New blocks: note the intended `category`, `keywords`, and `icon` concept** (Forge picks the actual SVG).
- **Utility-class first.** If the approach section mentions CSS, confirm utilities can't cover it first.
- **No code in this file.** The plan describes intent; Forge writes code.
- **Do not commit.** Plan files are never committed from this skill.
