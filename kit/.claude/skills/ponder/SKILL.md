---
name: ponder
description: Phase 1 of the cool-fse workflow. Grill the user, decide task lane (trivial/standard/large), and write an implementation plan to .claude/plans/active/. Use at the start of any non-trivial new work. Triggered by /ponder, "let's plan", "grill me on X", "write this up".
---

Phase 1 of the cool-fse workflow. Grill the user one question at a time until the design is
solid, then hand off to Inscribe. Write no code this session. Touch theme files only to read them.

## 1. Read context

- `WORKFLOW.md` — methodology, lanes, plan format, Quality Bar
- `CLAUDE.md` — project specifics: local URL, child theme dir, build commands, vocab
- `CONVENTIONS.md` — cool-fse standards (so you grill toward buildable decisions)
- `ls .claude/plans/active/` — what's in flight, so you don't double up

A screenshot, comp, or reference link → note it; it anchors the plan's Visual Reference.

## 2. Detect trivial up front

First message clearly a one-liner (typo, copy change, swap an SVG, change a single value)
→ offer the trivial lane immediately (AskUserQuestion):

> This looks trivial — make the change in this session, no plan file? **Yes / Treat as standard / Grill more.**

Yes → make the change and end. Else continue.

## 3. Grill, one question at a time

**Delivery:**
- Default **AskUserQuestion** when there's an option set + a recommendation. Always include "Other (describe)".
- Plain text only when genuinely open-ended ("paste the design link", "describe the layout").
- **One question per turn.** Never stack.

**Grill on:**
- Placement and block hierarchy (what goes where)
- New block vs. override of a parent block vs. CSS-only tweak vs. hook extension
- Field shape (ACF repeater vs. inner blocks vs. flat fields)
- Layout — compose from utility classes, not hand CSS; multi-column/aligned layouts use the `.row` / `.col-<bp>-<n>` grid. Read `cool-fse/blocks/global/css/` first
- Wrapper handling — keep the standard wrapper (`get_wrapper_attributes()` + `acf-style-vars`); never override it to fake padding/width. A breakout element is isolated and sized in JS, not served by re-plumbing the wrapper. If the design fights the wrapper width, resolve it now.
- Custom elements (`<ada-slider>`, `<ada-modal>`, `<animate-on-scroll>`, `<g-map>`, …) — check `cool-fse/blocks/global/js/custom-elements/`
- Brand tokens — read `{{CHILD_THEME_DIR}}/theme.json`
- Visual reference — a screenshot, a Figma link, or an existing block to mirror

Read the code to answer your own questions instead of asking. For multi-file surveys
(utility-class lists, block patterns, ACF field conventions), dispatch a read-only `Explore`
subagent with a tight scoped brief in the background, and keep grilling other branches while
it returns.

**Always-ask — the Quality Bar** (every non-trivial ponder). One per turn:

1. **Visual quality** — "Comp, Figma link, or existing block to mirror? If not, describe the look." (No reference = nothing to review design against — push before accepting "waived.")
2. **Mobile** — "Behavior on mobile? Same layout scaled, stacked, hidden, other?" (768px, usually a `@media` query; the limited `mobile:`/`tablet:` prefix is spacing + col-span only.)
3. **Dark/light background** — "Dark bg with light text AND light with dark text, or just one?" (Affects color tokens. Tracked in Design Decisions, not the Bar.)
4. **Accessibility** — "Keyboard nav, screen-reader announcements, ARIA roles, reduced-motion?"
5. **ACF editor UX** — "Who edits this, how configurable? Fields that must be required, grouped, or need instructions?"

## 4. Mid-grill lane decision

Once scope is clearer (≈2–4 questions in):

> **Lane: standard or large?**
> - Standard — single plan, single Forge session.
> - Large — single plan with internal slices; each slice gets its own Forge + Temper.

Recommend by file count and unknowns. Default **standard**.

## 5. Keep grilling

Push down each branch until you could write the steps without further input. Stop when:
- Every approval gate this plan triggers is identified
- Every file to create or modify is named
- Every utility class / custom element / ACF field is decided — each field's name, type, and purpose (these become the block's `@param` docblock)
- Visual reference is locked in (or explicitly waived)

## 6. Summarize + gate

Output a short bulleted summary of resolved decisions. Then (AskUserQuestion):

> **Write the plan now, or more to grill?**

## 7. Hand off to Inscribe

Hand off to `/inscribe` — it owns the plan file. Pass every resolved decision: placement,
new-block-vs-override, field shape, layout/utility classes, custom elements, the four
Quality Bar answers, dark/light, visual reference, lane, and the approval gates this plan
triggers. Don't write the plan file yourself; don't continue into Forge.

## Rules

- AskUserQuestion is the default UI; plain text only when truly open-ended. One question per turn.
- Read the code to answer your own questions — cheaper than asking.
- Every option-set question carries your recommended answer.
- Surface every approval gate during the grill so Inscribe can name it.
- Don't write code, and don't write the plan file. That's Forge and Inscribe.
