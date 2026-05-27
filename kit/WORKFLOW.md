# Workflow

The methodology for any cool-fse child-theme project that ships this kit. Project-agnostic.
Project specifics live in `CLAUDE.md`; coding standards in `CONVENTIONS.md`.

Read this top-to-bottom once, then treat it as reference.

## The big idea

You own the design and the visual review. Claude does the typing and the code review.
Work flows through four named phases plus one human step, each in its own session, with a
single **plan file** carrying state between them.

```
/ponder ─→ /inscribe ─→ /forge ─→ [human review] ─→ /temper ─→ /seal
```

| Phase | What it does | Output |
|---|---|---|
| **Ponder** | Grill out the design, pick a lane | resolved decisions |
| **Inscribe** | Write those decisions into a plan file | `.claude/plans/active/<slug>.md` |
| **Forge** | Read the plan and build it; pause on new gates | code + `Forge complete` line |
| **Human review** | You review the result — read the diff, or open the browser if a server's running | your judgment |
| **Temper** | Three audits: code, accessibility, front-end design | `## Temper Report` in the plan |
| **Seal** | Draft a short commit message, archive the plan | plan moved to `done/`, message in your terminal |

Phases hand off via the plan file, not session memory. Each session reads the plan cold.

Ponder and Inscribe are usually one sitting (`/ponder` ends by invoking `/inscribe`); the
fresh-session boundary that matters is **before Forge** and **before Temper**.

## Who does what

| Phase | Claude | Human |
|---|---|---|
| **Ponder / Inscribe** | Grills, researches the codebase, writes the plan | Answers, decides, approves the plan |
| **Forge** | Builds per the plan | Answers blockers; runs the dev server *if* reviewing in-browser |
| **Human review** | — | Reads the diff and/or reviews in WP Admin + front end |
| **Temper** | Code + ADA + design audits | Reviews findings, decides what to fix |
| **Seal** | Drafts the commit message, archives the plan | Commits, pushes |

**A running dev server is optional.** Forge builds with or without one. The browser review
and Temper's live design pass simply get richer when `pnpm run local` is up.

## The three lanes

Set during Ponder. The lane decides how heavy the process is.

| Lane | Use when | Process |
|---|---|---|
| **Trivial** | Obvious one-liner — typo, copy change, swap an SVG, footer year | Same session, no plan file. Make the change, hand back. |
| **Standard** | A new block, an override, a feature touching a handful of files | One plan. Ponder → Inscribe → Forge → review → Temper → Seal. |
| **Large** | Multi-week feature, full site section, anything with internal slices | One plan with **slices**. Each slice gets its own Forge → review → Temper. One Seal at the end. |

Trivial is offered on Ponder turn 1. Standard-vs-large is decided mid-grill, once scope is
clear. Default standard.

## The Quality Bar

Every non-trivial block is built against five quality dimensions:

| Dimension | What it means |
|---|---|
| **Visual quality** | Looks deliberately designed — spacing rhythm, type hierarchy, polish. Not generic. |
| **ADA / accessibility** | Keyboard-operable, semantic markup, WCAG AA contrast, reduced-motion respected. |
| **Cross-browser** | Latest Chrome, Firefox, Safari, Edge. No IE. |
| **Mobile** | Deliberately composed at 768px and below, via media queries (there is no `mobile:` class prefix). |
| **ACF editor UX** | Pleasant for a content editor — instructions, sensible labels, required flags, grouped fields. |

It threads through three places: **Ponder** asks all five (cross-browser as a stated
default), **Inscribe** writes one concrete target per dimension into the plan's
`## Quality Bar`, and **Temper** audits one check per line. It's a shared checklist, not
an approval gate. Dark/light background support is decided alongside it but tracked in
Design Decisions, not the Bar.

## Plan file format

Inscribe owns the template (see its SKILL.md). Required sections, in order: Status, Lane,
Source, TL;DR, What We're Building, Design Decisions, Quality Bar, Approval Gates
(pre-approved), Files to Create / Modify, Approach, Visual Reference, Out of Scope,
Verification, Slices *(large only)*, Open Questions. No PRD bloat — no user stories,
acceptance-criteria checklists, or stakeholder sections.

The plan grows over time: Forge appends a `Forge complete <date>` line, Temper appends a
`## Temper Report`, Seal appends a `## Seal` section and flips Status to `done`.

## Plan lifecycle

```
.claude/plans/active/<slug>.md   ← Inscribe writes here (Status: in-progress)
                                 ← Forge appends the handoff line
                                 ← Temper appends "## Temper Report"
                                 ← Seal flips Status to "done"
.claude/plans/done/<slug>.md     ← Seal moves it here
```

Cleanup is `rm .claude/plans/done/*` whenever it's cluttered.

## Approval gates

Some actions need explicit approval. They're flagged in the plan up front and then
**pre-approved** for Forge — Forge does NOT re-prompt on them. A NEW gate discovered
mid-build makes Forge pause and ask.

| Gate | Why |
|---|---|
| Touches `cool-fse/` (parent theme) | Shared across every project on the parent. |
| New block-level CSS | Utility-class-first is the rule; new CSS implies a gap. |
| ACF JSON hand-edits | Normally synced from WP Admin; hand-editing risks key collisions. |
| New section in an FSE template | Changes page composition. |
| Editing `functions.php` hooks | Side effects can be invisible. |
| Risky git/shell action | Seal never commits; Forge avoids destructive git. |

## Skill cheat sheet

| Command | Phase | Run when |
|---|---|---|
| `/ponder` | 1 | Starting any non-trivial work |
| `/inscribe` | 1→2 | After grilling, to write the plan (Ponder calls it; also standalone) |
| `/forge [slug]` | 2 | Fresh session, plan exists in `active/` |
| `/temper [slug]` | 3 | Fresh session, after human review |
| `/seal [slug]` | 4 | Fresh session, after Temper (or after you've decided to skip it) |
| `/sharpen` | utility | Anytime you want help writing a sharper prompt — not part of the phase chain |

No external skill dependencies. Ponder runs its own interview.

## Anti-patterns

- **Don't gold-plate.** Forge builds what's in the plan. Spot extra work? Surface it; don't bundle it in.
- **Don't skip the grill on real features.** Cheaper to grill than to rebuild.
- **Don't skip human review.** You're the visual reviewer.
- **Don't write CSS when utility classes exist.** Read `cool-fse/blocks/global/css/` first.
- **Don't edit ACF in WP Admin.** Edit `acf-json/*.json` directly.
- **Don't run `git commit` from a skill.** Seal drafts the message and stops.
- **Don't let Forge improvise.** Wrong plan → fix the plan or surface a blocker.

## Escape hatches

| Situation | Move |
|---|---|
| Plan is wrong mid-build | Stop Forge, edit the plan, restart Forge |
| Forge stuck on ambiguity | It pauses and asks. Answer briefly. |
| Temper finds blockers | Fix manually, then Seal. Or re-run Forge on the specific issues. |
| New gate mid-build | Forge pauses. Approve or reshape the plan. |
| Plan is stale | Forge re-reads every file in "Files to Create / Modify" and catches most drift. |
| Scope changed | Edit the plan in place. The plan is the source of truth. |

## File locations

| Path | What |
|---|---|
| `WORKFLOW.md` | This file — the methodology. |
| `CONVENTIONS.md` | cool-fse coding standards. |
| `CLAUDE.md` | Project-specific entry point — URLs, dirs, build commands. |
| `.claude/skills/` | The six skills. |
| `.claude/settings.json` | Permission allowlist. |
| `.claude/plans/active/` · `done/` | In-flight · archived plans. |
| `.claude/screenshots/<slug>/` | Per-plan visual artifacts. |

## Single session at a time

One phase at a time, top to bottom. No concurrent Forge sessions on the same plan. To
fork, copy the plan to a new slug and treat it as separate work.
