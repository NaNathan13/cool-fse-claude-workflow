# cool-fse-claude-workflow

A drop-in AI workflow kit for [cool-fse](https://github.com/) based WordPress child-theme projects.

Installs alongside the parent + child themes inside `wp-content/themes/` and gives any project four phase commands:

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
3. Asks for project name, child theme dir, local URL, local port — and renders `CLAUDE.md` + `CONTEXT.md` from templates
4. Drops `.claude/scripts/update.sh` so you can re-run later in update mode

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

Built to standardize the way I work on the [perry-hotel](https://) child theme and the broader hotel-suite that builds on top of it. Hand-rolled `grill-to-imp` / `execute-imp` / `review-imp` skills got the job done but weren't quite right — too coupled to one project, no clean separation between "plan" and "build" sessions, no place for visual review or a11y.

This kit refines that into four phases modeled after the Pocock-style workflow used in `plant-pal-v4`, but stripped of GitHub issues, mission-control, tests, and CI — none of which fit a static-site WP theme.

## License

Personal use; no license granted yet.
