# Workflow

The methodology for any cool-fse-based child theme project that ships this kit. Project-agnostic — the project-specific stuff lives in `CLAUDE.md` and `CONTEXT.md`.

If you're new to the kit, read this top-to-bottom once. Afterward, treat it as reference.

## The big idea

You (the human) own the design. Claude does the typing. Work flows through four named phases, each in its own session, with a single artifact — a **plan file** — carrying state between them.

```
/ponder ──→ /forge ──→ /temper ──→ /seal
```

| Phase | What it does | Output |
|---|---|---|
| **Ponder** | Grill out the design, pick a lane, write a plan | `.claude/plans/active/<slug>.md` |
| **Forge** | Read the plan and build it. Pause on new approval gates. | Code + `Forge complete` line in the plan |
| **Temper** | Parallel review (code + visual + a11y for UI). | `## Temper Report` section in the plan |
| **Seal** | Draft a commit message, archive the plan. | Plan moved to `done/`, message in your terminal |

Phases hand off via the plan file, not session memory. Each new session starts fresh and reads the plan cold.

## The three lanes

Set in Ponder, not at the start. The lane decides how heavy the process is.

| Lane | Use when | Process |
|---|---|---|
| **Trivial** | Obvious one-liner — typo fix, copy change, swap an SVG, change the year in the footer | Same session. No plan file. Make the change, hand back to user. |
| **Standard** | A new block, an override, a feature that touches a handful of files | One plan file. Four sessions: Ponder → Forge → Temper → Seal. |
| **Large** | Multi-week feature, full new site section, anything with internal slices | One plan file with **internal slices**. Each slice gets its own Forge + Temper. One Seal at the end. |

Trivial is auto-detected on Ponder turn 1 — if the request reads like a one-liner, Ponder offers to skip the chain. Otherwise Ponder asks "standard or large?" mid-grill (typically 2–4 questions in, once scope is clearer).

**Rule of thumb:** if you're making more than two judgment calls in a row inside the grill without alignment, you skipped too far ahead — back up.

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
How to know it works. For UI: which page, which interactions, which
screenshots Forge should take. For non-UI: which functional behavior to confirm.

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
                                 ← Forge updates Status to "in-progress"
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
| Touches `cool-fse/` (parent theme) | Parent is shared across the hotel suite. Changes affect every site. |
| New block-level CSS | Utility-class first is the rule. New CSS implies the utility list is missing something. |
| ACF JSON hand-edits | Normally edited via WP Admin → JSON auto-syncs. Hand-editing risks key collisions. |
| New section in `index.php` (or any FSE template) | Changes the page composition. Confirm placement first. |
| Editing `functions.php` hooks | Side effects can be invisible until much later. |
| Risky git/shell action | `git commit`, `git push`, `git reset --hard`, etc. — Seal never runs these; Forge avoids them. |

Plan-level gate listing is the contract. Mid-build discoveries are the exception.

## Model routing

Each skill declares a preferred model in its frontmatter. A `PreToolUse` hook on the `Skill` tool prints a non-blocking reminder if the current session is on a different tier.

| Skill | Preferred | Why |
|---|---|---|
| `/ponder` | `opus-4-7` | Open-ended design judgment + grill steering |
| `/forge` | `opus-4-7` | Implementation requires reasoning across files |
| `/temper` | `opus-4-7` | Multi-subagent review with judgment |
| `/seal` | `sonnet` | Mechanical text/git work — sonnet is plenty |

The hook is advisory. Override with `/model <tier>` if you want.

## Skill cheat sheet

| Command | Phase | Run when |
|---|---|---|
| `/ponder` | 1 | Starting any non-trivial work |
| `/grill-me` | sub-skill of Ponder | Auto-invoked; you can also use it stand-alone |
| `/forge [slug]` | 2 | Fresh session, plan exists in `active/` |
| `/temper [slug]` | 3 | Fresh session, Forge handed off |
| `/seal [slug]` | 4 | Fresh session, Temper handed off (or you've decided to skip Temper) |

`/grill-me` is **upstream** — comes from the Pocock skills library (`mattpocock/skills`). Install separately: `~/.claude/skills/grill-me/SKILL.md` or via the plugin. If you don't have it, Ponder falls back to plain-text grilling.

## Worked examples

### Trivial — change the footer copyright year

```
You: change "© 2024" to "© 2026" in the footer
Claude: Trivial — making the change.
       [edits perry-hotel/blocks/gutenberg/main-footer/main-footer.php]
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
  → runs Playwright on http://<local-url>/test-page/
  → screenshots into .claude/screenshots/testimonial-slider/
  → appends "Forge complete <date>" to plan
  → hand off: "Run /temper testimonial-slider"

Session 3: /temper testimonial-slider
  → dispatches code-review + visual-review + a11y subagents
  → appends "## Temper Report" with findings
  → "<X> blocking, <Y> suggested, <Z> nits, <N> a11y suggestions"
  → user fixes blockers (in this session, manually, or whatever)

Session 4: /seal testimonial-slider
  → reads plan + git diff
  → drafts commit message in a fenced code block
  → marks plan done, moves to done/
  → hand off: "Copy the commit message and run git commit yourself"
```

### Large — full new section of the site (multi-slice)

Same as standard, except the plan has a `## Slices` section. After the first Forge+Temper completes, you start a new Forge session for slice 2, then Temper, then slice 3, etc. Seal runs once at the end (or per-slice if each slice ships separately — your call).

## Anti-patterns

- **Don't gold-plate.** Forge implements what's in the plan. If you spot extra work mid-build, surface it (Temper will too) — don't quietly bundle it in.
- **Don't skip the grill on real features.** Cheaper to grill than to rebuild.
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
| `.claude/skills/` | The four phase skills. |
| `.claude/hooks/model-router.sh` | Advises on model tier when invoking skills. |
| `.claude/settings.json` | Hook registration + permission allowlist. |
| `.claude/plans/active/` | In-flight plans. |
| `.claude/plans/done/` | Archived plans. Disposable. |
| `.claude/screenshots/<slug>/` | Per-plan visual artifacts. |
| `.claude/scripts/update.sh` | Re-runs `setup.sh` in update mode. |

## Updating the kit

```bash
bash .claude/scripts/update.sh
```

Overwrites: `WORKFLOW.md`, `.claude/skills/*`, `.claude/hooks/*`.
Diff-only: `.claude/settings.json`, `templates/CLAUDE.md.template` vs your `CLAUDE.md`, `templates/CONTEXT.md.template` vs your `CONTEXT.md`.
Never touched: `CLAUDE.md`, `CONTEXT.md`, `.claude/plans/`, `.claude/screenshots/`.

If the update prints "new template sections you may want to merge", that's a signal the kit added something to the template that your project file doesn't have yet — open the template and merge by hand.

## Single-session at a time

The kit assumes you're running one phase at a time, top to bottom. No mid-flight branching, no concurrent Forge sessions on the same plan. If you need to fork, copy the plan to a new slug and treat it as a separate piece of work.
