# cool-fse-claude-workflow

A drop-in AI workflow kit for `cool-fse`-based WordPress child themes. It gives any
project a named flow — one phase per stage of the work:

```
/ponder → /inscribe → /forge → [you review] → /temper → /seal
```

- `/ponder` — grill out the design, pick a lane
- `/inscribe` — write the agreed design into a plan file
- `/forge` — execute the plan, verify the build, pause on approval gates
- `/temper` — three audits in one pass: code, accessibility, front-end design
- `/seal` — draft a commit message, archive the plan (you run the commit)

Plus two standalone helpers, usable anytime (not part of the phase chain):
- `/sharpen` — turn a rough idea into a sharper prompt
- `/showcase` — build an example-block post demonstrating a Gutenberg block's core variations (a QA/demo page)

Each phase runs in its own session and hands off through a single plan file. A running
dev server is optional — the flow builds with or without Local; a live server only adds
browser review and Temper's design pass. Method lives in
[`kit/WORKFLOW.md`](kit/WORKFLOW.md); cool-fse standards in
[`kit/CONVENTIONS.md`](kit/CONVENTIONS.md).

## Install

From inside `wp-content/themes/` (the dir containing `cool-fse/` and your child theme):

```bash
curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
```

The installer:

1. Verifies you're in a `wp-content/themes/` dir (contains `cool-fse/` + another theme)
2. Asks for project name, child theme dir, and local URL (proxy port defaults to `10000`)
3. Copies the kit — `WORKFLOW.md`, `CONVENTIONS.md`, skills, settings, and the plan/screenshot dirs
4. Renders every file from your answers (saved to `.claude/.kit-config`)
5. Drops `.claude/scripts/update.sh` so you can re-run later in update mode

## Update

From the same dir:

```bash
bash .claude/scripts/update.sh
```

Refreshes the kit files (`WORKFLOW.md`, `CONVENTIONS.md`, skills) from your saved
answers, so your project values and `CLAUDE.md` survive. See
[`docs/upgrading.md`](docs/upgrading.md) for the full breakdown.

## Requirements

- A `wp-content/themes/` dir with `cool-fse/` (parent) and at least one child theme
- Claude Code CLI
- `gh` CLI (optional — only `/seal` uses it, to read recent commits)
