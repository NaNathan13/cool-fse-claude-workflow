---
name: scrub
description: Post-setup cleanup. Replaces generic placeholders (<child-theme>, my-site, <local-url>) with project-specific values, deletes stock files (example plans, update scripts), and tightens WORKFLOW.md. Run once after setup.sh, or on existing installs to clean up. Triggered by /scrub.
---

You are running the post-setup cleanup skill. Your job is to make every kit file project-specific by replacing generic placeholders with real values, then deleting stock files that don't belong in a live project. This is mechanical work — confirm values with the user, then execute.

Read `CLAUDE.md` first to extract the current rendered values (project name, child theme dir, local URL).

## Process

### 1. Read current values from CLAUDE.md

Read `CLAUDE.md` at the themes root. Extract:
- **Project name** — from the `**<name>**` in the first line or `## Project overview`
- **Child theme directory** — from the `<dir>/` child theme reference
- **Local URL** — from the `Local site URL` line

These are the defaults for the confirmation questions below.

### 2. Confirm project name + child theme directory

Use AskUserQuestion. Pre-fill with the values extracted from CLAUDE.md:

> **Project name and child theme directory — look right?**
> - Yes, use `<project name>` / `<child-theme-dir>/` (Recommended)
> - No, let me correct them

If the user corrects, capture the new values.

### 3. Confirm local URL

Use AskUserQuestion. Pre-fill with the value from CLAUDE.md:

> **Local site URL — correct?**
> - Yes, use `<url>` (Recommended)
> - No, let me type the right one

If the user corrects, capture the new value.

### 4. Delete stock files

Execute these deletions. Use `rm -f` / `rm -rf` so missing files don't error (handles both fresh installs and existing projects):

```bash
rm -f .claude/plans/done/EXAMPLE-*.md
rm -rf .claude/scripts/
rm -rf .claude/hooks/
```

### 5. Clean settings.json

Read `.claude/settings.json`. If it contains a `"hooks"` block, remove the entire `"hooks"` key. Write the cleaned JSON back.

If there's no hooks block, skip this step.

### 6. Replace placeholders across project files

Replace these tokens in `WORKFLOW.md`, `CONTEXT.md`, and all `.claude/skills/*/SKILL.md` files:

| Token | Replace with |
|---|---|
| `<child-theme>` | The confirmed child theme directory name |
| `my-site` (when used as a placeholder project name, not as part of a URL like `my-site.local`) | The confirmed project name |
| `<local-url>` | The confirmed local URL |
| `http://my-site.local/` | The confirmed local URL |

Be careful with `my-site` — only replace it when it's clearly a placeholder (e.g., `my-site/blocks/gutenberg/`, `my-site/acf-json/`), not when it's part of generic documentation. Use context to judge.

### 7. Clean WORKFLOW.md sections

Read `WORKFLOW.md`. Remove these sections if still present:

- **"## Model routing"** — the entire section (header through the next `##` header)
- **"## Updating the kit"** — the entire section (header through the next `##` header)

### 8. Update WORKFLOW.md header and worked examples

- Retitle the `# Workflow` header to `# <Project Name> — Workflow`
- In the worked examples section, replace `<child-theme>/` paths with the confirmed child theme dir
- Replace `http://<local-url>/` or `http://my-site.local/` URLs with the confirmed local URL

### 9. Update CONTEXT.md

- Retitle the `# CONTEXT.md` header to `# <Project Name> — Context`
- Update the `## Project-specific terms` section header (keep the section, just confirm the header is present)

### 10. Report

Tell the user:

> Project files are now specific to **<project name>**. You can delete this skill if you won't need it again, or keep it as reference.
>
> Files updated:
> - `WORKFLOW.md` — header, examples, removed stock sections
> - `CONTEXT.md` — header
> - `.claude/skills/*/SKILL.md` — placeholder replacements
> - `.claude/settings.json` — hooks removed (if applicable)
>
> Files deleted:
> - `.claude/plans/done/EXAMPLE-*.md`
> - `.claude/scripts/`
> - `.claude/hooks/`

## Don't do

- **Don't touch CLAUDE.md.** It was already rendered by setup.sh. This skill only reads it for defaults.
- **Don't touch CONTEXT.md vocabulary entries.** Only update the top-level header.
- **Don't write any code.** This is a cleanup skill, not a build skill.
- **Don't commit.** Leave that to the user.
