---
name: forge
description: Phase 2 of the cool-fse workflow. Load a plan from .claude/plans/active/ and execute it. Trusts the plan's pre-approved gates; pauses on newly discovered gates. Triggered by /forge [slug], "execute the plan", "build it", "run the plan".
---

You are starting Phase 2 of the four-phase cool-fse workflow. Read a plan, build the code, verify it works. Do NOT improvise beyond the plan — if something is unclear or unresolved, surface it and wait.

Read `WORKFLOW.md` once for the contract. Read `CLAUDE.md` for project specifics (URLs, child theme dir, build commands). Read `CONTEXT.md` for vocabulary.

## Process

### 1. Load the plan

If a slug was passed as an argument, read `.claude/plans/active/<slug>.md`. Otherwise list `.claude/plans/active/` and ask which to load before doing anything else.

Read the entire plan carefully before touching any code. Re-read it if you get confused later — don't infer.

### 2. Orient in the codebase

Read every file listed in "Files to Create / Modify" to see current state. Plans are written ahead of implementation; the codebase may have moved.

Also read:

- The matching parent file in `cool-fse/` for any override (you must understand what you're replacing)
- The relevant ACF JSON in `<child-theme>/acf-json/` for any field group changes
- Utility classes in `cool-fse/blocks/global/css/` for any CSS plan that names them
- Custom elements in `cool-fse/blocks/global/js/custom-elements/` for any interactive behavior
- `<child-theme>/theme.json` for color/font/spacing presets the plan references
- 1–2 existing similar blocks in `<child-theme>/blocks/gutenberg/` to match the local style

For broad surveys (e.g., "which blocks use this pattern?", "does this utility class exist?"), dispatch a research subagent using the `/researcher` brief template rather than reading every file yourself.

Do not skip this step.

### 3. Confirm status

The plan's `Status:` should already read `in-progress` (Inscribe sets it). Confirm. If it reads `done`, stop and ask the user — this plan was already sealed and you may be on the wrong slug.

### 4. Surface unresolved blockers

If the plan has an `## Open Questions` section with unresolved items, raise them now and wait. Do not write any file until they're answered.

### 5. Verify dev server reachable (UI tasks only)

Pull the local URL from `CLAUDE.md` (e.g., `http://my-site.local/`). Try:

```bash
curl -s -o /dev/null -w "%{http_code}" <LOCAL_URL>
```

If the response isn't `200`/`3xx`, tell the user "dev server not reachable at `<URL>` — start `pnpm run local` in `<child-theme>/` and retry" and stop. Do not start the dev server yourself.

### 6. Execute steps in order

Work through "Files to Create / Modify" + "Approach" sections. For each file:

- Do the work
- Confirm it's correct: read back what you wrote; check class names exist in the utility CSS; verify ACF field keys match the JSON; verify PHP escaping (`esc_html`, `esc_url`, `esc_attr`) and short-tag usage matches existing blocks
- Move to the next file

Do not batch unrelated work. Do not skip ahead.

### 7. Pre-approved gates

If the plan's `## Approval Gates (pre-approved)` section flagged any of these, proceed without asking — the plan IS the approval:

- Touches `cool-fse/`
- New block-level CSS
- ACF JSON hand-edits
- New section in `index.php` or other FSE template
- Editing `functions.php` hooks

### 8. Newly discovered gates — STOP and ask

If during the build you realize:

- Utility classes won't actually cover what the plan said they would
- You need to touch `cool-fse/` and the plan didn't pre-approve it
- You need a new ACF field that isn't in the plan
- A required pattern doesn't exist and you'd have to invent one
- An ACF field name in the plan doesn't match the JSON

…STOP. Surface what you found, propose the change, wait for approval. Don't guess.

### 9. Follow cool-fse conventions

- **Block PHP pattern**: `get_block_attributes()`, `get_wrapper_attributes()`, `acf_to_css_var()`, `maybe_get_block_video_background()` as appropriate
- **Block JSON**: `"acf": { "mode": "preview", "renderTemplate": "<name>-block.php" }`, `"style": ["cool-fse-css"]`, `"script": "cool-fse-js"`, plus `category` and `icon`
- **Sub-blocks** via `<?php block('gutenberg/<name>/<sub-part>') ?>` or `<?php block('components/<name>') ?>` — never `get_template_part()` or `include`
- **Override path**: mirror the parent path inside `<child-theme>/`. No registration needed.
- **CSS**: utility classes first, always. New block CSS is a Gate 2 trigger.
- **No hardcoded colors / hex / spacing.** Use `--wp--preset--color--*`, `--wp--preset--spacing--*`, `--wp--preset--font-family--*`, or the `--font-family-*` vars from `<child-theme>/blocks/global/css/global.css`.
- **No `var_dump`, `print_r`, `console.log`** left in.
- **Escaping**: `esc_html`, `esc_url`, `esc_attr` on output; raw echo only for ACF wysiwyg fields.

### 10. Build sanity

- No PHP fatals on the affected page (`curl -s -o /dev/null -w "%{http_code}" <LOCAL_URL>/<page>` should return 200)
- esbuild/SASS error log is clean (assume the user is watching `pnpm run local` and will report otherwise)

### 11. Hand off

Append to the plan, at the bottom:

```markdown

---

**Forge complete <today's date>.** Ready for Temper.
```

Tell the user:

> Forge complete. Review the changes in the browser (WP Admin, front end, test interactions), then run `/temper <slug>` in a **fresh session**.

End the session. Do not continue into Temper yourself.

## When to stop and ask

- Plan ambiguity (two reasonable interpretations of the same step)
- ACF field name in the plan doesn't match the JSON
- Parent block does something the plan didn't anticipate (and that affects the override)
- A custom element the plan named doesn't exist in `cool-fse/blocks/global/js/custom-elements/`
- A utility class the plan named doesn't exist in `cool-fse/blocks/global/css/`
- Any new approval gate (see Step 8)

Brief stop, brief question, brief continuation. No paragraph essays.

## Don't do

- **Don't run `git commit`, `git push`, or any destructive git command.** That's Seal's job (Seal also doesn't commit — only drafts).
- **Don't start `pnpm run local` yourself.** Assume the user is running it. Tell them if it's down.
- **Don't refactor neighboring files.** Plan is the contract.
- **Don't gold-plate.** A new block doesn't need a CHANGELOG.
- **Don't run `/temper` from this session.** Hand off.
