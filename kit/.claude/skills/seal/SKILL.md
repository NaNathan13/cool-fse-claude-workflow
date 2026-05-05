---
name: seal
description: Phase 4 of the cool-fse workflow. Drafts a commit message based on the plan + diff, marks the plan done, and moves it to .claude/plans/done/. Never runs git commit — user owns commits. Triggered by /seal [slug], "wrap it up", "seal it".
preferred-model: sonnet
---

You are starting Phase 4 of the four-phase cool-fse workflow. Mechanical work: draft a commit message, archive the plan. **You never run `git commit`.** That's the user's job.

Read `WORKFLOW.md` once for the contract. Read `CLAUDE.md` if you need project specifics.

## Process

### 1. Load the plan

If a slug was passed, read `.claude/plans/active/<slug>.md`. Otherwise list `active/` and ask which to seal.

### 2. Read the diff

```bash
git diff
git status -s
```

Read everything — staged, unstaged, untracked.

### 3. Quick sanity check

- Plan has `Forge complete <date>` line — yes? If no, ask the user "Forge handoff line is missing — proceed anyway?"
- Plan has `## Temper Report` — yes? If no, ask "Temper wasn't run — proceed anyway?"
- Temper Report has zero unresolved blockers — yes? If there are unresolved blockers, ask "Temper has <N> unresolved blocking items — proceed anyway? (list them so the user can confirm)"

For each "proceed anyway?" question, use AskUserQuestion with **Yes / No, stop here** as the options.

### 4. Read recent commits

```bash
git log --oneline -20
```

Match the project's commit-message style. Conventional commits (`feat(scope): ...`, `fix(scope): ...`, `style: ...`, `chore: ...`) are the default unless the project clearly uses something else.

### 5. Draft the commit message

Format:

```
<type>(<scope>): <short summary, imperative, ~70 chars max>

<body — explains WHY, pulled from the plan's TL;DR + Approach. Two or three
short paragraphs at most. Don't restate the diff — the diff already shows
WHAT changed.>

Refs: .claude/plans/done/<slug>.md
```

**Type guidance:**
- `feat` — new block, new functionality
- `fix` — bug fix
- `style` — CSS-only changes that don't touch behavior
- `chore` — non-code (acf-json regen, dependency bumps)
- `refactor` — restructure without behavior change
- `docs` — README, comments, plan-only updates

**Scope:** the block name, the feature area, or `theme` for project-wide. Lowercase, kebab.

Output the full message in a fenced ```` ```text ```` code block so the user can copy it cleanly.

### 6. Mark the plan done

Edit the plan:
- Flip `Status:` to `done`
- Append a `## Seal — <date>` section:

```markdown

## Seal — <today's date>

Commit message drafted (see session output). Plan archived.
```

### 7. Move the plan to done/

```bash
mv .claude/plans/active/<slug>.md .claude/plans/done/<slug>.md
```

### 8. Hand off

Tell the user:

> Plan archived to `.claude/plans/done/<slug>.md`. Commit message is above — copy it, run `git commit` yourself, then `git push` when ready.

End the session.

## Don't do

- **Don't run `git commit`.** Hard rule. The user owns commits.
- **Don't run `git push`.** Same reason.
- **Don't `git add`** unless the user explicitly asks. Leave staging to them.
- **Don't draft multiple message variants.** Pick one, commit to it, output it.
- **Don't pad the body.** Two paragraphs max. Diff shows WHAT — body explains WHY.
