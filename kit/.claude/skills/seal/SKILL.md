---
name: seal
description: Phase 4 of the cool-fse workflow. Drafts a short commit message from the plan + diff, marks the plan done, and moves it to .claude/plans/done/. Never runs git commit — the user owns commits. Triggered by /seal [slug], "wrap it up", "seal it".
---

You are Phase 4 of the four-phase cool-fse workflow. Mechanical work: draft a **short**
commit message and archive the plan. **You never run `git commit`** — that's the user's.

Read `WORKFLOW.md` for the contract; `CLAUDE.md` only if you need project specifics.

## 1. Load the plan

If a slug was passed, read `.claude/plans/active/<slug>.md`. Otherwise list `active/` and
ask which to seal.

## 2. Read the diff

```bash
git diff
git status -s
```

Read everything — staged, unstaged, untracked.

## 3. Sanity check

Use AskUserQuestion (**Yes / No, stop here**) for each that fails:

- Plan has a `Forge complete <date>` line? If not: "Forge handoff line is missing — proceed anyway?"
- Plan has a `## Temper Report`? If not: "Temper wasn't run — proceed anyway?"
- Temper Report has zero unresolved blockers? If not: list them, "Temper has <N> unresolved blocking items — proceed anyway?"

## 4. Match the commit style

```bash
git log --oneline -20
```

Conventional commits (`feat(scope): …`, `fix(scope): …`, `style: …`, `chore: …`) are the
default unless the project clearly uses something else.

## 5. Draft a short commit message

**One line. Optionally one short sentence of context — never more.**

```
<type>(<scope>): <imperative summary, ~70 chars>
```

or, when one line genuinely needs context:

```
<type>(<scope>): <imperative summary>

<one short sentence — the WHY, not the what>
```

- **Type:** `feat` (new block/feature), `fix`, `style` (CSS-only), `chore` (acf-json regen, deps), `refactor`, `docs`.
- **Scope:** the block name, the feature area, or `theme`. Lowercase, kebab.
- No multi-paragraph body. No "Refs:" line. No restating the diff — the diff shows WHAT.

Output it in a ```text fenced block so the user can copy it.

Example:
```text
feat(testimonial-slider): add autoplay testimonial slider block
```

## 6. Mark the plan done

Edit the plan: flip `Status:` to `done`, append:

```markdown

## Seal — <today's date>

Commit message drafted. Plan archived.
```

## 7. Move to done/

```bash
mv .claude/plans/active/<slug>.md .claude/plans/done/<slug>.md
```

## 8. Hand off

> Plan archived to `.claude/plans/done/<slug>.md`. Commit message is above — copy it, run
> `git commit` yourself, then push when ready.

End the session.

## Don't do

- **Don't run `git commit` or `git push`.** Hard rule — the user owns commits.
- **Don't `git add`** unless asked.
- **Don't draft multiple variants.** One message, committed to.
- **Don't write a long body.** One line; at most one sentence of why.
