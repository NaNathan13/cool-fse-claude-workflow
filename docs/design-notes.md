# Design notes

Why the kit is shaped the way it is.

## What this replaces

A flat `grill-to-imp` / `execute-imp` / `review-imp` chain that worked but wasn't quite
right: tightly coupled to one child theme, no clean split between "plan" and "build"
sessions, no place for visual or accessibility review, no consistent commit step.

## What the kit is

Four named phases — `/ponder` → `/inscribe` → `/forge` → `/temper` → `/seal` — plus a
standalone `/sharpen` helper, `WORKFLOW.md` (methodology), `CONVENTIONS.md` (coding
standards), a `CLAUDE.md` template, and a one-command `setup.sh`. Drops into any
`wp-content/themes/` directory with `cool-fse/` and at least one child theme.

## Locked-in decisions

1. **Plan files, not GitHub issues, are the handoff artifact.** These are often
   static-site installs with no issue tracker. A plan in `.claude/plans/active/` is all a
   phase needs.

2. **Three lanes, picked mid-grill.** Trivial (auto-offered turn 1) / standard / large.

3. **No tests, no TDD, no CI.** WP themes don't ship tests. Verification = your eyes in
   the browser for UI, build success + functional check otherwise.

4. **Files at themes root, not inside the child theme.** Gives Claude native visibility
   of both parent and child, and survives child-theme renames.

5. **One source of truth per concept.** cool-fse coding standards live only in
   `CONVENTIONS.md` (Forge builds to it, Temper audits against it). `CLAUDE.md` is thin —
   project values, build commands, response style, a pointer. `WORKFLOW.md` is the
   methodology. No convention is restated across files, because restated facts drift.

6. **Ponder is self-contained — no external skill dependency.** Earlier versions leaned
   on the upstream `/grill-me` skill as the interview engine; it leaked into onboarding
   and required a separate install. The grilling discipline now lives directly in Ponder.

7. **Ponder and Inscribe are separate skills.** Ponder grills; Inscribe writes the plan
   and hands off to Forge. The split is a clean stopping point between "decide" and
   "build."

8. **Local is optional.** Forge builds with or without a running dev server. The curl
   reachability check only fires for UI work when a URL is configured, and it warns +
   continues rather than stopping. Temper's design pass uses Playwright when a server is
   up, static review otherwise.

9. **Plan format: TL;DR + sections, no PRD bloat.** No user stories, acceptance-criteria
   checklists, or stakeholder sections.

10. **Approval gates: pre-approved in the plan, mid-build re-prompt for new ones.** Gates
    flagged up front become Forge's pre-approved set; a gate discovered mid-build pauses.

11. **Forge does not run the dev server.** Assumes the user runs `pnpm run local` if they
    want browser review.

12. **Temper is three audits, no auto-fix loop.** Code review, accessibility, and
    front-end design (the "looks very good" rubric, dark mode + mobile + matches-the-theme)
    run every time. It reports; the user directs the fix. Accessibility findings stay
    suggestions-only unless the plan required a level.

13. **Seal drafts a short commit and stops.** One `<type>(<scope>): <summary>` line, at
    most one sentence of why — never a multi-paragraph body. It flips the plan to `done`
    and moves it. The user runs `git commit`. Hard rule.

14. **`/sharpen` is a bundled standalone utility.** Call it anytime to turn a rough idea
    into a precise prompt. Not wired into the phase chain.

15. **Bootstrap = git-clone + `setup.sh`.** `curl … | bash` from `wp-content/themes/`.
    Re-running enters update mode and never clobbers project files.

16. **Single session at a time.** One phase, top to bottom. No concurrency.

17. **The Quality Bar — five dimensions, threaded through three places.** Visual quality,
    ADA, cross-browser, mobile, ACF editor UX. Ponder asks them (cross-browser as a
    stated default), Inscribe writes one concrete target per dimension, Temper audits one
    check per line. A shared checklist, not an approval gate.

## What was deliberately rejected

- **Mission control / kanban, PRDs / ADRs, GitHub issues** — too heavy; plan files carry the load.
- **Tests / TDD / CI** — no test framework or pipeline on these themes.
- **Auto-fix loop in Temper** — net negative at this scale.
- **An external interview dependency (`/grill-me`)** — removed; Ponder runs its own.
- **A separate `CONTEXT.md` glossary** — it duplicated `CLAUDE.md`/`WORKFLOW.md`; the few
  useful "use this word, not that one" rules moved into `CLAUDE.md`.
- **`mobile:` utility prefix** — it never existed in cool-fse; responsive is plain
  `@media (max-width: 768px)`. (Caught when conventions were verified against a real checkout.)
- **Model-routing hooks, kit versioning/semver** — `main` is live; users pull via `update.sh`.
