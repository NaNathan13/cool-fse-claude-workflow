# Workflow

The methodology for any cool-fse-based child theme project that ships this kit. Project-agnostic — the project-specific stuff lives in `CLAUDE.md` and `CONTEXT.md`.

If you're new to the kit, read this top-to-bottom once. Afterward, treat it as reference.

## The big idea

You (the human) own the design and the visual review. Claude does the typing and the code review. Work flows through four named phases plus one explicit human step, each in its own session, with a single artifact — a **plan file** — carrying state between them.

```
/ponder ──→ /forge ──→ [human review] ──→ /temper ──→ /seal
```

| Phase | What it does | Output |
|---|---|---|
| **Ponder** | Grill out the design, pick a lane, write a plan | `.claude/plans/active/<slug>.md` |
| **Forge** | Read the plan and build it. Pause on new approval gates. | Code + `Forge complete` line in the plan |
| **Human review** | You review in the browser — WP Admin, front end, interactions | Your judgment on whether it looks and works right |
| **Temper** | Code review + ACF editor-UX review (always); visual + design-review + a11y with `--visual`. Audits the Quality Bar. | `## Temper Report` section in the plan |
| **Seal** | Draft a commit message, archive the plan. | Plan moved to `done/`, message in your terminal |

Phases hand off via the plan file, not session memory. Each new session starts fresh and reads the plan cold.

## Who does what

| Phase | Claude does | Human does |
|---|---|---|
| **Ponder** | Grills, researches codebase, writes the plan | Answers questions, makes design decisions, approves the plan |
| **Forge** | Builds the code per the plan | Keeps dev server running, answers blockers |
| **Human review** | — | Goes into WP Admin, builds/edits the page, adds blocks, customizes, visually and functionally reviews |
| **Temper** | Code review + ACF editor-UX (always); visual + design-review + a11y with `--visual` | Reviews findings, decides what to fix |
| **Seal** | Drafts commit message, archives plan | Commits, pushes |

**The user is the visual reviewer by default, not Playwright.** Human review between Forge and Temper is where you confirm the build looks right in the browser. Temper's `--visual` flag exists for when you want automated Playwright checks on top of your own review — it's opt-in, not the default.

## The three lanes

Set in Ponder, not at the start. The lane decides how heavy the process is.

| Lane | Use when | Process |
|---|---|---|
| **Trivial** | Obvious one-liner — typo fix, copy change, swap an SVG, change the year in the footer | Same session. No plan file. Make the change, hand back to user. |
| **Standard** | A new block, an override, a feature that touches a handful of files | One plan file. Ponder → Forge → human review → Temper → Seal. |
| **Large** | Multi-week feature, full new site section, anything with internal slices | One plan file with **internal slices**. Each slice gets its own Forge → human review → Temper. One Seal at the end. |

Trivial is auto-detected on Ponder turn 1 — if the request reads like a one-liner, Ponder offers to skip the chain. Otherwise Ponder asks "standard or large?" mid-grill (typically 2–4 questions in, once scope is clearer).

**Rule of thumb:** if you're making more than two judgment calls in a row inside the grill without alignment, you skipped too far ahead — back up.

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

## Plan file format

Plans live in `.claude/plans/active/<slug>.md` while in flight, then move to `.claude/plans/done/<slug>.md` after Seal.

Required sections (in order):

```markdown
# <Plan Title>

**Status:** in-progress | done
**Lane:** standard | large
**Source:** Grill session <date>

## TL;DR
One paragraph. What we're building, for whom, why.

## What We're Building
A clear-eyed description from both the editor's POV (what they configure)
and the visitor's POV (what they see).

## Design Decisions
Numbered. Each line: decision + rationale.

## Quality Bar
One concrete, checkable target per dimension (see WORKFLOW.md → The Quality Bar).
Temper audits one check per line. "N/A" only with a reason.

## Approval Gates (pre-approved)
List the gated actions this plan is authorizing up front so Forge doesn't
re-prompt on them. Common ones:
- Touches `cool-fse/` (parent theme)
- New block-level CSS (utilities can't cover X)
- ACF JSON hand-edits

## Files to Create / Modify
Flat checklist with file paths.

## Approach
Per-file or per-step prose. What goes where, which utility classes, which
custom elements, which ACF fields. Concrete, not hand-wavy.

## Visual Reference
Links to screenshots in `.claude/screenshots/<slug>/`, design comps,
or existing blocks to mirror.

## Out of Scope
Things that came up but aren't being built in this pass.

## Verification
How to know it works. For UI: which page, which interactions to check
during human review. For non-UI: which functional behavior to confirm.

## Slices  *(large lane only)*
Numbered sub-tasks, each independently buildable. Each slice gets its own
Forge + Temper. Seal happens once at the end.

## Open Questions  *(only if any remain)*
If this section has unresolved items, Forge will pause on them. Ideally
empty by the time Ponder finishes.
```

The plan grows over time — Forge appends `Forge complete <date>` lines, Temper appends a `## Temper Report` section, Seal appends a `## Seal` section.

## Plan lifecycle

```
.claude/plans/active/<slug>.md   ← Ponder writes here
                                 ← Forge confirms Status is "in-progress"
                                 ← Forge appends handoff line
                                 ← Temper appends "## Temper Report"
                                 ← Seal updates Status to "done"
.claude/plans/done/<slug>.md     ← Seal moves it here
```

Cleanup is `rm .claude/plans/done/*` whenever the directory feels cluttered.

## Approval gates

Some actions need explicit user approval. They are flagged in the plan up front and then **pre-approved** for Forge — Forge does NOT re-prompt on them. If a NEW gate is discovered mid-build (utilities won't cover what was promised, an unexpected `cool-fse/` edit is required), Forge pauses and asks.

Standard gates:

| Gate | Why it matters |
|---|---|
| Touches `cool-fse/` (parent theme) | Parent is shared across every project that builds on it. Changes affect every site. |
| New block-level CSS | Utility-class first is the rule. New CSS implies the utility list is missing something. |
| ACF JSON hand-edits | Normally edited via WP Admin → JSON auto-syncs. Hand-editing risks key collisions. |
| New section in `index.php` (or any FSE template) | Changes the page composition. Confirm placement first. |
| Editing `functions.php` hooks | Side effects can be invisible until much later. |
| Risky git/shell action | `git commit`, `git push`, `git reset --hard`, etc. — Seal never runs these; Forge avoids them. |

Plan-level gate listing is the contract. Mid-build discoveries are the exception.

## Skill cheat sheet

| Command | Phase | Run when |
|---|---|---|
| `/ponder` | 1 | Starting any non-trivial work |
| `/grill-me` | sub-skill of Ponder | Auto-invoked for the interview; you can also use it stand-alone |
| `/inscribe` | sub-skill of Ponder | Auto-invoked after grilling to write the plan file; callable stand-alone when decisions are already resolved |
| `/forge [slug]` | 2 | Fresh session, plan exists in `active/` |
| `/temper [slug] [--visual]` | 3 | Fresh session, after human review. Add `--visual` for visual + design-review + a11y checks |
| `/seal [slug]` | 4 | Fresh session, Temper handed off (or you've decided to skip Temper) |
| `/researcher` | Utility | Research subagent brief template — used inside Ponder and Forge for codebase research |
| `/appraise` | sub-skill of Temper | Design-quality review pass; auto-dispatched by `/temper --visual`, callable stand-alone on a built block |

`/grill-me` is **upstream** — comes from the Pocock skills library (`mattpocock/skills`). Install separately: `~/.claude/skills/grill-me/SKILL.md` or via the plugin. If you don't have it, Ponder falls back to plain-text grilling.

`/inscribe` lives in `.claude/skills/inscribe/SKILL.md` and is part of this kit.

## Sub-skills and subagents per phase

Each top-level phase invokes other skills and/or parallel subagents under the hood. Knowing the breakdown helps when something goes sideways — you can re-run a piece in isolation rather than restarting the whole phase.

| Phase | Calls (skills) | Dispatches (subagents) | Notes |
|---|---|---|---|
| **Ponder** | `/grill-me` (upstream), `/inscribe` (in-kit) | `Explore` via `/researcher` (codebase research) | Grill-me runs the interview; Inscribe writes the plan file. Researcher dispatches read-only research agents for utility-class surveys, existing patterns, etc. All callable stand-alone. |
| **Forge** | — | `Explore` via `/researcher` (pre-build checks) | Researcher dispatches read-only research agents to verify plan assumptions (utility classes exist, no field key conflicts, etc.). The plan is the contract. |
| **Temper** | `/appraise` (in-kit, via the design-review subagent) | `feature-dev:code-reviewer` + ACF editor-UX agent (always); visual + design-review (`appraise`) + a11y agents (only with `--visual`) | Code review and ACF editor-UX run every time. `--visual` adds the three browser-driven passes, dispatched in a single parallel message. |
| **Seal** | — | — | Pure mechanical work: read diff + plan, draft commit message, archive plan. No skills, no subagents. |

**Re-running pieces in isolation:**

- Plan came out wrong but the grill was fine → call `/inscribe` directly and feed it the resolved decisions.
- Want a quick second-pass interview without the planning step → call `/grill-me` directly.
- Temper missed something on one axis (e.g., visual review was off) → re-dispatch just that subagent manually rather than running `/temper` again.
- Seal drafted a commit message you don't like → re-run `/seal` on the same slug; it'll re-read the diff and redraft.

## Worked examples

### Trivial — change the footer copyright year

```
You: change "© 2024" to "© 2026" in the footer
Claude: Trivial — making the change.
       [edits {{CHILD_THEME_DIR}}/blocks/gutenberg/main-footer/main-footer.php]
       Done. Commit when ready.
```

No plan, no fresh session, no temper, no seal. You commit yourself.

### Standard — new testimonial slider block

```
Session 1: /ponder
  → grill: top-level block? repeater vs inner blocks? autoplay? layout?
  → mid-grill: "standard or large?" → standard
  → write plan to .claude/plans/active/testimonial-slider.md
  → hand off: "Run /forge testimonial-slider in a fresh session"

Session 2: /forge testimonial-slider
  → reads plan, reads cool-fse/blocks/gutenberg/media-collage-cta as analogue
  → builds block files, edits acf-json/<group>.json
  → confirms build sanity (page loads, no PHP fatals)
  → appends "Forge complete <date>" to plan
  → hand off: "Review in the browser, then run /temper testimonial-slider"

Human review (you, in the browser):
  → open WP Admin, add the Testimonial Slider block to a test page
  → populate fields, check front-end rendering
  → test interactions: autoplay, hover-pause, swipe, keyboard nav
  → check mobile viewport
  → note anything off — you'll feed it to Temper or fix directly

Session 3: /temper testimonial-slider
  → dispatches code-review + ACF editor-UX subagents (always)
  → (with --visual: also dispatches visual + design-review + a11y subagents)
  → appends "## Temper Report" with findings, including the design verdict
  → "<X> blocking, <Y> suggested, <Z> nits, <N> a11y, <M> ACF UX, design: <verdict>"
  → user fixes blockers (in this session, manually, or whatever)

Session 4: /seal testimonial-slider
  → reads plan + git diff
  → drafts commit message in a fenced code block
  → marks plan done, moves to done/
  → hand off: "Copy the commit message and run git commit yourself"
```

### Large — full new section of the site (multi-slice)

Same as standard, except the plan has a `## Slices` section. After the first Forge → human review → Temper completes, you start a new Forge session for slice 2, then review and Temper, then slice 3, etc. Seal runs once at the end (or per-slice if each slice ships separately — your call).

## Anti-patterns

- **Don't gold-plate.** Forge implements what's in the plan. If you spot extra work mid-build, surface it (Temper will too) — don't quietly bundle it in.
- **Don't skip the grill on real features.** Cheaper to grill than to rebuild.
- **Don't skip human review.** You're the visual reviewer. Check the browser before running Temper — catching layout issues yourself is faster than waiting for a code review to guess at visual intent.
- **Don't write CSS when utility classes exist.** Read `cool-fse/blocks/global/css/` first. Every time.
- **Don't edit ACF in WP Admin.** Edit `acf-json/*.json` directly. WP Admin should be a one-way sync target.
- **Don't run `git commit` from a skill.** Seal drafts the message and stops. You commit.
- **Don't refactor mid-task.** A bug fix doesn't need surrounding cleanup.
- **Don't let Forge improvise.** If the plan is wrong, fix the plan or surface a blocker.

## Escape hatches

| Situation | Move |
|---|---|
| Plan is wrong and Forge is mid-build | Stop Forge, edit the plan, restart Forge |
| Forge is stuck on an ambiguity | It will already pause and ask. Answer briefly, it continues. |
| Temper finds blocking issues | Fix manually, then run Seal. Or run Forge again on the specific issues. |
| Mid-build discovery of a new gate | Forge pauses. Approve or reshape the plan. |
| Plan is stale (codebase moved) | Forge step 2 (re-read every file in "Files to Create / Modify") will catch most drift. Pause, update plan, resume. |
| You changed your mind about scope | Edit the plan in place. Re-run Forge if needed. Plan is the source of truth. |
| Dev server isn't reachable | Forge will tell you and stop. Start `pnpm run local` in the theme dir, retry. |

## File locations

| Path | What it is |
|---|---|
| `WORKFLOW.md` | This file. The methodology. |
| `CLAUDE.md` | Project-specific entry point — fonts, URLs, conventions. |
| `CONTEXT.md` | Domain glossary — universal cool-fse terms + project-specific terms. |
| `.claude/skills/` | Phase skills + utilities. |
| `.claude/settings.json` | Permission allowlist. |
| `.claude/plans/active/` | In-flight plans. |
| `.claude/plans/done/` | Archived plans. Disposable. |
| `.claude/screenshots/<slug>/` | Per-plan visual artifacts. |

## Single-session at a time

The kit assumes you're running one phase at a time, top to bottom. No mid-flight branching, no concurrent Forge sessions on the same plan. If you need to fork, copy the plan to a new slug and treat it as a separate piece of work.
