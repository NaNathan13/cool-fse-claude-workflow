---
name: ponder
description: Phase 1 of the cool-fse workflow. Grill the user, decide task lane (trivial/standard/large), and write an implementation plan to .claude/plans/active/. Use at the start of any non-trivial new work. Triggered by /ponder, "let's plan", "grill me on X", "write this up".
preferred-model: opus-4-7
---

You are starting Phase 1 of the four-phase cool-fse workflow. Your job is to grill the user one question at a time until the design is solid, then write a single plan file. Do NOT write any code in this session. Do NOT touch the actual theme files except to read them.

Read `WORKFLOW.md` once for the contract. Read `CLAUDE.md` for project specifics. Read `CONTEXT.md` for vocabulary.

## Process

### 1. Read context

- `WORKFLOW.md` (at the themes root) — the methodology
- `CLAUDE.md` (at the themes root) — project specifics: local URL, child theme dir name, fonts, brand colors
- `CONTEXT.md` (at the themes root) — vocabulary; use these terms, avoid the synonyms listed
- `ls .claude/plans/active/` — what else is in flight (so you don't double-up)

### 2. Detect trivial up front

If the user's first message clearly describes a one-liner (typo fix, copy change, swap an SVG, change a single value), offer the trivial lane immediately:

> This looks trivial — make the change in this session, no plan file? **Yes / Treat as standard / I want to grill more.**

Use AskUserQuestion. If they say yes, do the change and end. If standard or grill-more, continue.

### 3. Grill, one question at a time

Invoke `/grill-me` (the upstream Pocock skill) as the interview engine. If `/grill-me` isn't installed, fall back to plain-text grilling — same shape, just no skill scaffolding.

**Question delivery:**
- Default to **AskUserQuestion** when there's a clear option set + a recommendation. Always include "Other (describe)" as a fallback.
- Use **plain text** only when the question is genuinely open-ended ("paste the design link", "describe the layout in your own words").
- One question per turn. Do not stack.

**What to grill on:**
- What goes where (page placement, block hierarchy)
- New block vs. override of a parent block vs. CSS-only tweak vs. hook extension
- Field shape (ACF repeater vs. inner blocks vs. flat fields)
- Layout (utility classes from `cool-fse/blocks/global/css/` first — read them so you know what's available)
- Custom elements (`<ada-slider>`, `<ada-modal>`, `<animate-on-scroll>`, `<g-map>`) — check `cool-fse/blocks/global/js/custom-elements/` for what exists
- Brand tokens (theme.json colors, font presets) — read `<child-theme>/theme.json`
- Visual reference — ask for a screenshot, a Figma link, or an existing site

When the codebase can answer a question, **read the code instead of asking.**

### 4. Mid-grill lane decision

Once scope is clearer (typically 2–4 questions in), ask:

> **Lane: standard or large?**
> - Standard — single plan, single Forge session.
> - Large — single plan with internal slices; each slice gets its own Forge + Temper.

Recommend based on file count and unknowns. Default to **standard**.

### 5. Continue grilling

Push down each branch of the decision tree until you'd be able to write the implementation steps without further input. Stop when:
- Every approval gate this plan will trigger is identified
- Every file to create or modify is named
- Every utility class / custom element / ACF field is decided
- Visual reference is locked in (or explicitly waived)

### 6. Summarize + gate

Output a short bulleted summary of resolved decisions. Ask:

> **Write the plan now, or more to grill?**

Use AskUserQuestion. If "more to grill", continue. If "write", proceed.

### 7. Write the plan

Auto-generate a kebab-case slug from the task name (e.g., "testimonial slider" → `testimonial-slider`). Save to `.claude/plans/active/<slug>.md`.

Use exactly this structure (per `WORKFLOW.md`):

```markdown
# <Plan Title>

**Status:** in-progress
**Lane:** standard | large
**Source:** Grill session <today's date>

## TL;DR
<One paragraph.>

## What We're Building
<Editor POV + visitor POV.>

## Design Decisions
1. <decision> — <rationale>
2. ...

## Approval Gates (pre-approved)
- <gate, if any>

## Files to Create / Modify
**Create:**
- [ ] `<child-theme>/blocks/gutenberg/<name>/<name>-block.json`
- [ ] ...

**Modify:**
- [ ] `<child-theme>/acf-json/<group>.json`
- [ ] ...

## Approach
<Per-file or per-step prose. Concrete file names, real utility classes,
real field keys, real custom element tags.>

## Visual Reference
<Links / paths.>

## Out of Scope
- ...

## Verification
<Browser steps for UI / functional steps for non-UI / Playwright assertions
for Forge to run.>

## Slices  *(large lane only)*
1. <slice 1 — independently buildable>
2. ...

## Open Questions
<Empty unless something genuinely unresolved. Forge will pause on these.>
```

Save with the Write tool. Do not commit.

### 8. Hand off

Tell the user:

> Plan saved to `.claude/plans/active/<slug>.md`. Run `/forge <slug>` in a **fresh session**.

End the session. Do not continue into Forge yourself.

## Conventions

- **Use AskUserQuestion as the default question UI.** Plain text only when truly open-ended.
- **One question per turn.** Two questions at once kills the rhythm.
- **Read the code to answer your own questions.** Cheaper than asking.
- **Recommend, don't ask vaguely.** Every option-set question has your recommended answer.
- **Sub-blocks via `block('...')`** — note these in the plan, don't make Forge guess.
- **Utility-first CSS.** If a question can be answered by reading `cool-fse/blocks/global/css/`, do that first.
- **Don't write code.** This is the planning phase. Save it for Forge.
