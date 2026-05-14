# Kit Recommendations — Block Quality Coverage — 2026-05-14

> Scope: improvements aimed at the five quality dimensions you build every block against —
> **visual quality, ADA compliance, cross-browser, mobile, ACF editor UX**. Separate from
> `AUDIT.md`, which covered convention-enforcement and stale references (mostly resolved).
>
> **Status:** implemented 2026-05-14 — see `.claude/PLAN-OF-ACTION.md`.

## TL;DR

The kit's *process spine* (Ponder → Forge → Temper → Seal, plan-as-handoff, gates) is solid.
The gap is that your five quality dimensions aren't threaded through it consistently:

- **3 of 5 are partially covered** — mobile, a11y (and dark/light) are "always-ask" in Ponder,
  but the thread frays before Temper: Forge has no build guidance for them, and Temper only
  checks them with `--visual`.
- **2 of 5 have zero coverage anywhere** — **cross-browser** and **ACF editor UX** are absent
  from every phase.

The single highest-leverage change is to make these five a **named, plan-level Quality Bar**
that Ponder asks about, Inscribe writes into the plan, Forge builds to, and Temper audits line
by line — which is the "a check for each in Temper" idea, anchored so the checks have written
criteria to test against.

## Coverage matrix — where each dimension lives today

| Dimension | Ponder | Plan (Inscribe) | Forge | Temper |
|---|---|---|---|---|
| **Visual quality** | Asks for a visual reference — but it can be "waived" (`ponder` L71) | `## Visual Reference` section, may say "waived" | No polish/interactive-state conventions | Visual subagent — `--visual` only; checks "matches the plan," not "is it actually good" |
| **ADA / a11y** | ✅ Always-asks (`ponder` L51) | Feeds `## Verification` | No semantic-HTML / reduced-motion conventions | A11y subagent — `--visual` only, **never blocking** (`temper` L130) |
| **Cross-browser** | ❌ nothing | ❌ nothing | ❌ nothing | ❌ nothing |
| **Mobile** | ✅ Always-asks (`ponder` L49) | `## Verification` has a 375px line | `mobile:` prefix mentioned once (`forge` L155); no build guidance | Incidental — only if visual subagent happens to resize |
| **ACF editor UX** | Grills field *shape* (repeater vs. inner blocks), not field *ergonomics* | "concrete field keys" — nothing on usability | JSON *correctness* rules; nothing on editor experience | Code review checks JSON *correctness*, not whether an editor can use it |

**Grounding the ACF gap:** the live `pontiac-edc` field groups show the problem concretely —
`"instructions": ""` on every field, `"required": 0` everywhere (even on fields the block
early-returns without), and repeaters with `"collapsed": ""` so rows are unlabeled when
collapsed. Nothing in the kit asks anyone to fix that.

## Recommendations (priority order)

### R1 — Make the five dimensions a named "Quality Bar" threaded through every phase

The unifying move. Everything below hangs off this.

- **Ponder** — promote the "always-ask" block (currently mobile / dark-light / a11y) to the
  full five. Add cross-browser and ACF editor UX as always-asks. Give the set a name.
- **Inscribe** — add a `## Quality Bar` section to the plan template: one line per dimension
  stating the *specific* target for this block (e.g. "Mobile: stacks single-column below 768px";
  "ADA: keyboard-operable, WCAG AA contrast"; "Browsers: latest Chrome/FF/Safari/Edge").
  This is what gives Temper something concrete to check.
- **Forge** — short conventions per dimension (see R2–R5).
- **Temper** — one check per Quality Bar line. This is the "a check for each" idea, now with
  written acceptance criteria instead of Temper guessing intent.

### R2 — Close the cross-browser gap — static compat lint *(decided: lint only)*

A "compat lint" added to the **code-review subagent's checklist** — no new subagent, no browser
infra, runs every Temper:

- Flag CSS/JS features outside the support matrix. Candidates given what `cool-fse` already
  leans on: `:has()`, `backdrop-filter`, subgrid, container queries, `@property`,
  top-level `await`. Each flag names a fallback.
- **Forge** gets one convention bullet: "Target latest Chrome/Firefox/Safari/Edge. No IE.
  Before using a bleeding-edge CSS feature, confirm baseline support or provide a fallback."

Live multi-engine Playwright testing was considered and **declined** — the static lint carries
the value without the Playwright-per-engine infra.

### R3 — Add an ACF editor-UX review — dedicated Temper subagent *(decided)*

Its own Temper subagent with its own report section. Pure read-only JSON analysis
(`acf-json/*.json`), so it's cheap — it runs **by default**, not gated on `--visual`, which
keeps the Quality Bar's ACF line always-checked.

What it checks:
- Every field has an `instructions` string (what it does + constraints: image dimensions,
  char limits, aspect ratios)
- `required` set on fields the block can't render without
- Repeaters: `collapsed` points at a meaningful sub-field, `button_label` is specific
  ("Add Resource" not "Add Row"), `min`/`max` set where it matters
- Conditional logic hides irrelevant fields; sensible field order; related fields grouped
  (`tab` / `group` / `accordion`)
- Labels are Title Case, jargon-free, and match `CONTEXT.md` vocabulary
- `example` / preview mode actually renders

Findings categorize as suggested / nit like the code-review subagent. A future `/acf-design`
Ponder sub-skill (design field groups up front) was considered but is **out of scope for now**.

### R4 — a11y blocking — no change *(decided: keep suggestions-only)*

R4 originally proposed making declared-ADA violations blocking. **Declined** — design-note #12
("a11y is suggestions-only") stands. The a11y subagent keeps its current behavior: runs with
`--visual`, findings are always suggestions-only, the human directs the fix.

The Quality Bar's ADA line is still valuable as written intent — it's what the `--visual` a11y
pass and the human reviewer check against. It just doesn't become an automated gate.

### R5 — Make "looks very good" measurable — new design-review skill *(decided)*

A **new design-review skill** purpose-built to *evaluate* a block (not build one). It carries
`frontend-design`'s aesthetic standards — spacing rhythm, type hierarchy, visual balance,
interactive states, avoiding generic AI aesthetics — but is framed as an audit that returns a
clear **recommend / approve** verdict plus specific findings. Temper dispatches it as a
`--visual` subagent pass.

(`frontend-design` itself is built to *create* interfaces; using it as-is to review would be
off-label. The new skill borrows its standards, owns its own review framing. Working name TBD —
something in the kit's metalworking vocabulary, e.g. `burnish`.)

Supporting changes:
- **Ponder** — for blocks where visual quality matters, push hard for a real visual reference
  (comp, Figma link, or an existing block to mirror). The design-review skill judges intrinsic
  polish, but a reference sharpens "does it match intent."
- **Forge** — one convention bullet: every interactive element gets designed hover/focus/active
  states and honors `prefers-reduced-motion`. (`cool-fse` already ships
  `hover-focus-animations.css` and `transition-utilities.css` — point Forge at them.)

## Resulting Temper structure

| Subagent | Runs | Status |
|---|---|---|
| Code review | always | existing — **+ cross-browser compat lint section** (R2) |
| ACF editor-UX | always | **new** (R3) |
| Visual review | `--visual` | existing — brief unchanged |
| Design review | `--visual` | **new skill** (R5) |
| Accessibility | `--visual` | existing — unchanged, suggestions-only (R4) |

No new top-level phase. Everything fits as Temper subagents plus conventions in
Ponder / Inscribe / Forge. A fifth phase would break the clean four-phase model for no gain.

## Decisions (locked 2026-05-14)

1. **Visual review** → new dedicated design-review skill carrying `frontend-design`'s standards;
   Temper `--visual` subagent; returns recommend/approve.
2. **a11y blocking** → no change. Stays suggestions-only per design-note #12.
3. **ACF editor-UX review** → dedicated Temper subagent, runs by default (read-only JSON).
4. **Cross-browser** → static compat lint in the code-review subagent only. No live
   multi-engine testing.

## Next step

Write a dedicated plan of action covering: R1 (Quality Bar across Ponder/Inscribe/Forge/Temper),
R2 (compat lint + Forge bullet), R3 (ACF-UX subagent), R5 (new design-review skill + Ponder/Forge
bullets). R4 requires no work.
