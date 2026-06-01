---
name: ponder
description: Phase 1 of the cool-fse workflow. Grill the user, decide task lane (trivial/standard/large), and write an implementation plan to .claude/plans/active/. Use at the start of any non-trivial new work. Triggered by /ponder, "let's plan", "grill me on X", "write this up".
---

You are Phase 1 of the four-phase cool-fse workflow. Grill the user one question at a
time until the design is solid, then write a single plan file. Do NOT write any code this
session. Do NOT touch theme files except to read them.

Read `WORKFLOW.md` for the contract, `CLAUDE.md` for project specifics, `CONVENTIONS.md`
for coding standards.

## 1. Read context

- `WORKFLOW.md` — methodology, lanes, plan format, Quality Bar
- `CLAUDE.md` — project specifics: local URL, child theme dir, build commands, vocab
- `CONVENTIONS.md` — cool-fse coding standards (so you grill toward buildable decisions)
- `ls .claude/plans/active/` — what's already in flight, so you don't double up

If the user gave a screenshot, comp, or reference link, note it — it anchors the Visual
Reference section of the plan.

## 2. Detect trivial up front

If the first message clearly describes a one-liner (typo, copy change, swap an SVG,
change a single value), offer the trivial lane immediately with AskUserQuestion:

> This looks trivial — make the change in this session, no plan file? **Yes / Treat as standard / Grill more.**

Yes → make the change and end. Otherwise continue.

## 3. Grill, one question at a time

You run the interview yourself — no external skill needed.

**Delivery:**
- Default to **AskUserQuestion** when there's an option set + a recommendation. Always include "Other (describe)".
- Plain text only when genuinely open-ended ("paste the design link", "describe the layout").
- **One question per turn.** Never stack.

**Grill on:**
- Placement and block hierarchy (what goes where)
- New block vs. override of a parent block vs. CSS-only tweak vs. hook extension
- Field shape (ACF repeater vs. inner blocks vs. flat fields)
- Layout — exhaust utility classes in `cool-fse/blocks/global/css/` first; read them so you know what exists
- Wrapper handling — keep the standard wrapper (`get_wrapper_attributes()` + `acf-style-vars`); never override it to fake padding/width. A full-bleed/breakout element is isolated and sized in JS, not served by re-plumbing the wrapper. If the design fights the wrapper width, resolve it now.
- Custom elements (`<ada-slider>`, `<ada-modal>`, `<animate-on-scroll>`, `<g-map>`, …) — check `cool-fse/blocks/global/js/custom-elements/`
- Brand tokens — read `{{CHILD_THEME_DIR}}/theme.json`
- Visual reference — a screenshot, a Figma link, or an existing block to mirror

When the codebase can answer a question, **read the code instead of asking.** For
multi-file surveys (utility-class lists, existing block patterns, ACF field conventions),
dispatch a read-only `Explore` subagent with a tight, scoped brief (one question, a
specific path, "read and report only", a word cap) rather than reading dozens of files
yourself. Dispatch in the background and keep grilling other branches while it returns.

**Always-ask — the Quality Bar** (every non-trivial ponder; see `WORKFLOW.md`). One per turn:

1. **Visual quality** — "Comp, Figma link, or existing block to mirror? If not, describe the look." (No reference = nothing to review design against — push before accepting "waived.")
2. **Mobile** — "How should this behave on mobile? Same layout scaled, stacked, hidden, something else?" (Breakpoint is 768px, written as a media query — there is no `mobile:` class prefix.)
3. **Dark/light background** — "Work on dark backgrounds with light text AND light with dark text, or just one?" (Affects color tokens. Tracked in Design Decisions, not the Bar.)
4. **Accessibility** — "Keyboard nav, screen-reader announcements, ARIA roles, reduced-motion?"
5. **ACF editor UX** — "Who edits this, how configurable? Fields that must be required, grouped, or need instructions?"

**Cross-browser** is the unnumbered Bar dimension — state the default, don't ask:
"latest Chrome/Firefox/Safari/Edge, no IE — flag now if the design needs anything
unusual." Escalate to a real question only if the design implies risky CSS.

## 4. Mid-grill lane decision

Once scope is clearer (≈2–4 questions in), ask:

> **Lane: standard or large?**
> - Standard — single plan, single Forge session.
> - Large — single plan with internal slices; each slice gets its own Forge + Temper.

Recommend by file count and unknowns. Default **standard**.

## 5. Keep grilling

Push down each branch until you could write the steps without further input. Stop when:
- Every approval gate this plan triggers is identified
- Every file to create or modify is named
- Every utility class / custom element / ACF field is decided
- Visual reference is locked in (or explicitly waived)

## 6. Summarize + gate

Output a short bulleted summary of resolved decisions. Ask with AskUserQuestion:

> **Write the plan now, or more to grill?**

More → continue. Write → go to step 7.

## 7. Write the plan

Hand off to `/inscribe` — it owns the plan file. Pass every resolved decision from the
grill as context: placement, new-block-vs-override, field shape, layout/utility classes,
custom elements, the five Quality Bar answers, dark/light, visual reference, lane, and
the approval gates this plan will trigger. Inscribe picks the slug, writes
`.claude/plans/active/<slug>.md`, and hands off to Forge.

Do not write the plan file yourself. Do not continue into Forge after Inscribe runs.

## Conventions

- AskUserQuestion is the default UI; plain text only when truly open-ended.
- One question per turn.
- Read the code to answer your own questions — cheaper than asking.
- Recommend, don't ask vaguely — every option-set question carries your recommended answer.
- Surface every approval gate during the grill so Inscribe can name it in the plan.
- Don't write code, and don't write the plan file. That's Forge and Inscribe.
