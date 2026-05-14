# Design notes

Why the kit is shaped the way it is. Condensed from the grill session that produced the original implementation plan.

## What this replaces

A flat `grill-to-imp` / `execute-imp` / `review-imp` chain that worked but wasn't quite right:

- The old skills were tightly coupled to one specific child theme — terms, file paths, conventions hard-coded into prose
- "Plan written" and "plan executed" lived in the same session, blurring the handoff
- No place for visual review, no place for accessibility audit
- No place for a "draft commit + archive plan" step, so commits had no consistent shape

## What the kit is

Four phase skills (`/ponder`, `/forge`, `/temper`, `/seal`) plus `WORKFLOW.md`, `CLAUDE.md`, `CONTEXT.md` templates and a one-command `setup.sh`. Drops into any `wp-content/themes/` directory that has `cool-fse/` and at least one child theme.

## Locked-in decisions

### 1. Plan files, not GitHub issues, are the handoff artifact

No GitHub integration. Many of these projects are static-site WordPress installs with no issue tracker. A plan file in `.claude/plans/active/` is the only handoff a phase needs.

### 2. Three lanes, picked mid-grill

Trivial / standard / large. Trivial is auto-detected on turn 1 (one-liner detected → offer to skip the chain). Lane decision for non-trivial work happens 2–4 questions into the grill, once scope is clearer.

### 3. No tests, no TDD, no CI

WP themes don't ship tests. Verification = Playwright + manual eyes for UI tasks; build success + functional check for non-UI.

### 4. Files at themes root, not inside the child theme

Kit installs to `wp-content/themes/`, not `wp-content/themes/<child-theme>/`. This gives Claude visibility of both the parent and the child natively, and survives child-theme renames.

### 5. Three doc files with sharp roles

- **`CLAUDE.md`** — project-specific: URLs, fonts, child theme dir, build commands. Hand-edited.
- **`WORKFLOW.md`** — methodology. Project-agnostic. Dropped in unchanged. Updated by the kit.
- **`CONTEXT.md`** — domain glossary. Universal cool-fse vocabulary pre-filled; project-specific entries lazy-added.

### 6. Plan organization: active / done split, no feature-area buckets

`.claude/plans/active/` for in-flight, `.claude/plans/done/` for archived. Cleanup is `rm done/*`. No `done/2026-Q2/` or `done/header/` bucketing — flat is enough.

### 7. Plan format: TLDR + sections, no PRD bloat

Required sections: TL;DR, Status, Lane, Approval gates, Files, Approach, Visual reference, Out of scope, Verification, Slices (large only). Optional: Open questions. Skips PRD-style "user stories", "acceptance criteria checkboxes", "stakeholders".

### ~~8. Model routing per skill via PreToolUse hook~~ *(removed)*

Model routing was removed from the kit. All phases run on whatever model the user has active. The hook and `preferred-model` frontmatter no longer ship.

### 9. AskUserQuestion is the default UI for grill questions

Plain text only when the question is genuinely open-ended (paste a link, describe a layout). Single-question turns. Always include "Other (describe)" as a fallback option.

### 10. Approval gates: pre-approved in plan, mid-build re-prompt for new

Gates flagged in the plan up front (touches `cool-fse/`, new block CSS, ACF JSON edits) become Forge's pre-approved set. Forge does not re-prompt on those. **New** gates discovered mid-build (utilities won't cover what was promised, unexpected parent edit needed) DO trigger a pause.

### 11. Forge does not run the dev server

Assumes `pnpm run local` is already running. If not reachable, Forge says so and stops. Reduces blast radius.

### 12. Temper has no auto-fix loop

Reports findings; user directs the fix. Auto-fix loops at this scale create more
confusion than they save. Two subagents always run (code review, ACF editor-UX);
`--visual` adds three more in parallel (visual review, design review via `appraise`,
accessibility). Accessibility findings stay suggestions-only — see decision #17.

### 13. Seal does not run `git commit`

Drafts a conventional-commit message in a fenced code block, flips the plan to `done`, moves it to `done/`. User runs the commit themselves. Hard rule.

### 14. Replace, don't alias

Old skills (`grill-to-imp`, `execute-imp`, `review-imp`) are deleted from projects on adoption. `/ponder`, `/forge`, `/temper`, `/seal` are the four entry points. `/grill-me` (upstream Pocock) stays as Ponder's interview engine.

### 15. Bootstrap = git-clone + `setup.sh`

One-liner install: `curl … | bash` from inside `wp-content/themes/`. Re-running enters update mode and never clobbers project files.

### 16. Single session at a time

No concurrency spec. One phase at a time, top to bottom.

### 17. The Quality Bar — five named dimensions, threaded through every phase

Visual quality, ADA / accessibility, cross-browser, mobile, ACF editor UX. Ponder asks all five,
Inscribe writes a `## Quality Bar` plan section with one concrete target per dimension,
Forge builds to it, Temper audits one check per line. It is a shared checklist, not an
approval gate. Accessibility stays suggestions-only even though it's on the Bar — the
written target is intent for the human reviewer and the `--visual` a11y pass, not an
automated blocker. Cross-browser is enforced by a static compat lint inside the
code-review subagent, not by live multi-engine testing.

## What was deliberately rejected

- **Mission control / kanban** — too heavy for a static WP project; plan files alone carry the load.
- **PRDs / ADRs** — same reason.
- **GitHub issues / triage** — many client projects don't have repos with issues enabled.
- **Tests / TDD** — no test framework on these themes.
- **CI** — no pipeline target.
- **Auto-fix loop in Temper** — net negative at this scale.
- **`/diagnose` skill** — debugging fits inside `/ponder` for now.
- **`/zoom-out` skill** — Read + grep cover it.
- **Versioning / semver of the kit** — `main` is live; users pull via `update.sh`.
