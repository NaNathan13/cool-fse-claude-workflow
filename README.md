# cool-fse-claude-workflow

A drop-in AI workflow kit for [cool-fse](https://github.com/) based WordPress child-theme projects.

Installs alongside the `cool-fse` parent theme and your child theme inside `wp-content/themes/` and gives any project four phase commands:

- `/ponder` — grill out the design, pick a lane, write a plan
- `/forge` — execute the plan, run Playwright on UI tasks, pause on new approval gates
- `/temper` — parallel review (code + visual + a11y) and write a report into the plan
- `/seal` — draft a commit message, archive the plan (you run the commit yourself)

Everything else — methodology, lane definitions, plan format, model routing — lives in [`kit/WORKFLOW.md`](kit/WORKFLOW.md).

## Install

From inside `wp-content/themes/` (the directory that contains `cool-fse/` and your child theme):

```bash
curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
```

The installer:

1. Verifies you're in a `wp-content/themes/` dir (must contain `cool-fse/` and at least one other theme dir)
2. Copies `WORKFLOW.md`, `.claude/skills/*`, `.claude/hooks/*`, `.claude/settings.json`, and the empty `.claude/plans/{active,done}/` + `.claude/screenshots/` directories
3. Asks for project name, child theme dir, and local URL — and renders `CLAUDE.md` + `CONTEXT.md` from templates (local proxy port defaults to `10000`; edit `CLAUDE.md` later if your stack differs)
4. Drops `.claude/scripts/update.sh` so you can re-run later in update mode

## First-run AI setup prompt

After installing, paste this into a fresh Claude Code session at the themes root. It confirms the values the installer rendered into CLAUDE.md (project name, child theme dir, local URL) so you can catch any typos before starting work:

```
You're being run inside a freshly-installed cool-fse-claude-workflow kit. Read
WORKFLOW.md and CLAUDE.md so the methodology and project context are loaded,
then use AskUserQuestion to confirm: "Does CLAUDE.md look correct?" — show
the rendered project name, child theme dir, and local URL. Patch CLAUDE.md
only if I say something is wrong.

Then stop. Don't infer anything else, don't seed the glossary, don't start
/ponder.
```

## Update

From the same `wp-content/themes/` dir:

```bash
bash .claude/scripts/update.sh
```

Update mode overwrites project-agnostic files (`WORKFLOW.md`, skills, hooks) and **does not** touch `CLAUDE.md` or `CONTEXT.md`. It diffs the templates against your current files and prints a list of new sections you might want to merge in by hand.

## Requirements

- A `wp-content/themes/` directory with `cool-fse/` (parent) and at least one child theme
- Claude Code CLI
- The upstream `/grill-me` skill ([Pocock skills](https://github.com/mattpocock/skills)) — Ponder uses it as its interview engine. Install via the `mattpocock/skills` plugin or copy the SKILL.md into `~/.claude/skills/grill-me/`
- `gh` CLI (optional — only used by `/seal` when reading recent commits)

## Why this exists

Working on cool-fse child themes with hand-rolled `grill-to-imp` / `execute-imp` / `review-imp` skills got the job done but wasn't quite right — too coupled to whichever project they were originally written for, no clean separation between "plan" and "build" sessions, no place for visual review or a11y.

This kit refines that into four phases modeled after the Pocock-style workflow, but stripped of GitHub issues, mission-control, tests, and CI — none of which fit a static-site WP theme.

## License

Personal use; no license granted yet.
