---
name: forge
description: Phase 2 of the cool-fse workflow. Load a plan from .claude/plans/active/ and execute it. Trusts the plan's pre-approved gates; pauses on newly discovered gates. Triggered by /forge [slug], "execute the plan", "build it", "run the plan".
---

You are Phase 2 of the four-phase cool-fse workflow. Read a plan, build the code, verify
it. Do NOT improvise beyond the plan — if something is unclear or unresolved, surface it
and wait.

Read `WORKFLOW.md` for the contract, `CLAUDE.md` for project specifics (URL, child theme
dir, build commands), and **`CONVENTIONS.md` for the coding standards — build to it.**
Build to the plan's `## Quality Bar`; every line there is a target Temper will audit.

## 1. Load the plan

If a slug was passed, read `.claude/plans/active/<slug>.md`. Otherwise list
`.claude/plans/active/` and ask which to load. Read the whole plan before touching code.
Re-read it if you get confused later — don't infer.

## 2. Orient in the codebase

Read every file in "Files to Create / Modify" to see current state — plans are written
ahead of implementation; the codebase may have moved. Also read:

- The matching parent file in `cool-fse/` for any override (understand what you're replacing)
- The relevant ACF JSON in `{{CHILD_THEME_DIR}}/acf-json/` for field-group changes
- `cool-fse/blocks/global/css/` — the utility classes, before writing any CSS (see `CONVENTIONS.md`)
- `cool-fse/blocks/global/js/custom-elements/` — for any interactive behavior
- `{{CHILD_THEME_DIR}}/theme.json` for color/font/spacing presets the plan references
- 1–2 existing similar blocks in `{{CHILD_THEME_DIR}}/blocks/gutenberg/` to match local style

For broad surveys ("which blocks use this pattern?", "does this utility class exist?"),
dispatch a read-only `Explore` subagent with a tight, scoped brief (one question, a
specific path, "read and report only", a word cap) rather than reading every file
yourself. Don't skip this step.

## 3. Confirm status

The plan's `Status:` should read `in-progress` (Inscribe sets it). If it reads `done`,
stop and ask — it may have been sealed and you're on the wrong slug.

## 4. Surface unresolved blockers

If `## Open Questions` has unresolved items, raise them now and wait. Write nothing until
they're answered.

## 5. Dev server — optional

Building does not require a running server. Only check when the task is UI work **and** a
local URL is configured in `CLAUDE.md`:

```bash
curl -s -o /dev/null -w "%{http_code}" <LOCAL_URL>
```

If it doesn't return `200`/`3xx`, print one line — "dev server not reachable at `<URL>`;
building anyway — start `pnpm run local` in `{{CHILD_THEME_DIR}}/` if you want to review
in the browser" — and continue. Do not start the server yourself. Do not stop.

## 6. Execute steps in order

Work through "Files to Create / Modify" + "Approach". For each file:

- Do the work, following `CONVENTIONS.md` exactly (block boilerplate, JSON shape, naming, ACF helpers, utility-first CSS).
- Confirm it: read back what you wrote; check class names exist in the utility CSS; verify ACF field keys match the JSON; verify escaping (`esc_html`/`esc_url`/`esc_attr`) and `<?=` short tags.
- Move to the next file.

Don't batch unrelated work. Don't skip ahead. Don't gold-plate.

## 7. Pre-approved gates

If `## Approval Gates (pre-approved)` flagged any of these, proceed without asking — the
plan IS the approval:

- Touches `cool-fse/`
- New block-level CSS
- ACF JSON hand-edits
- New section in an FSE template
- Editing `functions.php` hooks

## 8. Newly discovered gates — STOP and ask

If mid-build you realize: utility classes won't actually cover what the plan said; you
need to touch `cool-fse/` and the plan didn't pre-approve it; you need an ACF field not in
the plan; a required pattern doesn't exist; or an ACF field name doesn't match the JSON —
**STOP.** Surface what you found, propose the change, wait for approval. Don't guess.

## 9. Build sanity

- No PHP fatals on the affected page. If the server was reachable in step 5: `curl -s -o /dev/null -w "%{http_code}" <LOCAL_URL>/<page>` returns 200. If there's no server, reason about fatals from the code (ABSPATH guard, field existence, helper signatures per `CONVENTIONS.md`).
- esbuild/SASS log is clean (assume the user is watching `pnpm run local` and will report otherwise).

## 10. Hand off

Append to the bottom of the plan:

```markdown

---

**Forge complete <today's date>.** Ready for Temper.
```

Then tell the user:

> Forge complete. Review the changes (in the browser if a server's running, or read the diff), then run `/temper <slug>` in a **fresh session**.

End the session. Don't continue into Temper.

## When to stop and ask

- Plan ambiguity (two reasonable readings of a step)
- ACF field name in the plan doesn't match the JSON
- Parent block does something the plan didn't anticipate (and it affects the override)
- A custom element or utility class the plan named doesn't exist in `cool-fse/`
- Any new approval gate (step 8)

Brief stop, brief question, brief continuation.

## Don't do

- **Don't run `git commit`, `git push`, or any destructive git command.** That's never Forge's job.
- **Don't start `pnpm run local` yourself.** Assume the user runs it; tell them if it's down.
- **Don't refactor neighboring files.** The plan is the contract.
- **Don't run `/temper` from this session.** Hand off.
