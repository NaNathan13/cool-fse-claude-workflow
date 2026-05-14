---
name: ponder
description: Phase 1 of the cool-fse workflow. Grill the user, decide task lane (trivial/standard/large), and write an implementation plan to .claude/plans/active/. Use at the start of any non-trivial new work. Triggered by /ponder, "let's plan", "grill me on X", "write this up".
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
- Brand tokens (theme.json colors, font presets) — read `{{CHILD_THEME_DIR}}/theme.json`
- Visual reference — ask for a screenshot, a Figma link, or an existing site

**Always-ask questions — the Quality Bar (every non-trivial ponder session):**

These cover the Quality Bar dimensions (see `WORKFLOW.md` → The Quality Bar) plus
dark/light background. Five questions are numbered below; cross-browser is a stated
default. The answers feed the plan's `## Quality Bar` and `## Verification` sections.
Ask one per turn.

1. **Visual quality** — "Is there a comp, Figma link, or existing block to mirror? If not, describe the look you're after." (A block with no visual reference can't be reviewed for design quality — push for one before accepting "waived.")
2. **Mobile** — "How should this behave on mobile? Same layout scaled down, stacked, hidden, or something else?" (Theme breaks at 768px; `mobile:` utility prefix variants exist.)
3. **Dark/light background** — "Does this need to work on both dark backgrounds with light text AND light backgrounds with dark text, or just one?" (Affects color token choices and whether the plan needs a color-scheme gate. Tracked in Design Decisions, not the Quality Bar.)
4. **Accessibility** — "Any specific accessibility requirements? Keyboard nav, screen reader announcements, ARIA roles, reduced-motion support?" (Feeds the plan's Verification section and Temper's a11y audit.)
5. **ACF editor UX** — "Who edits this block, and how configurable should it be? Any fields that must be required, grouped, or need specific instructions?" (Feeds the plan's Quality Bar ACF line and Temper's ACF editor-UX audit.)

**Cross-browser** is the fifth Quality Bar dimension but rarely varies — state the default rather than asking: "I'll target the latest Chrome/Firefox/Safari/Edge, no IE — flag now if the design needs anything unusual." Only escalate to a real question if the design implies risky CSS.

When the codebase can answer a question, **read the code instead of asking.** For multi-file research (utility class surveys, existing block patterns, ACF field conventions), dispatch a research subagent using the `/researcher` brief template rather than reading dozens of files yourself. Dispatch in the background and continue grilling on other branches while it returns.

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

Invoke `/inscribe` — it owns the plan-writing step. Pass all resolved decisions from the grill as context. `/inscribe` will:
- Determine the slug and lane
- Write `.claude/plans/active/<slug>.md` using the standard template
- Hand off to Forge

Do not write the plan yourself. Do not continue into Forge after `/inscribe` completes.

## Conventions

- **Use AskUserQuestion as the default question UI.** Plain text only when truly open-ended.
- **One question per turn.** Two questions at once kills the rhythm.
- **Read the code to answer your own questions.** Cheaper than asking.
- **Recommend, don't ask vaguely.** Every option-set question has your recommended answer.
- **Sub-blocks via `block('...')`** — note these in the plan, don't make Forge guess.
- **Utility-first CSS.** If a question can be answered by reading `cool-fse/blocks/global/css/`, do that first.
- **Don't write code.** This is the planning phase. Save it for Forge.
