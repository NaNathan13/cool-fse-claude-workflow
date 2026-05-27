# cool-fse-claude-workflow

A drop-in AI workflow kit for cool-fse-based WordPress child-theme projects.

Installs alongside the `cool-fse` parent theme and your child theme inside
`wp-content/themes/` and gives any project a simple, named flow — one phase per stage of
the work:

```
/ponder ─→ /inscribe ─→ /forge ─→ [you review] ─→ /temper ─→ /seal
```

- 💭 `/ponder` — grill out the design, pick a lane
- ✍️ `/inscribe` — write the agreed design into a plan file, hand off to Forge
- 🔥 `/forge` — execute the plan, verify the build, pause on new approval gates
- 🧊 `/temper` — three audits in one pass: code, accessibility, front-end design
- 🗡️ `/seal` — draft a short commit message, archive the plan (you run the commit yourself)

Plus `/sharpen` — a standalone helper for writing a sharper prompt, anytime.

Each phase runs in its own session and hands off through a single plan file. The
methodology lives in [`kit/WORKFLOW.md`](kit/WORKFLOW.md); the cool-fse coding standards
live in [`kit/CONVENTIONS.md`](kit/CONVENTIONS.md).

**A running dev server is optional** — the flow builds code with or without Local. A live
server only adds browser review and Temper's live design pass.

## Install

From inside `wp-content/themes/` (the directory that contains `cool-fse/` and your child theme):

```bash
curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
```

The installer:

1. Verifies you're in a `wp-content/themes/` dir (must contain `cool-fse/` and at least one other theme dir)
2. Asks for project name, child theme dir, and local URL (proxy port defaults to `10000`)
3. Copies `WORKFLOW.md`, `CONVENTIONS.md`, `.claude/skills/*`, `.claude/settings.json`, and the empty `.claude/plans/{active,done}/` + `.claude/screenshots/` dirs
4. Renders every kit file from your answers and saves them to `.claude/.kit-config`
5. Drops `.claude/scripts/update.sh` so you can re-run later in update mode

## Update

From the same `wp-content/themes/` dir:

```bash
bash .claude/scripts/update.sh
```

Update mode refreshes the project-agnostic files (`WORKFLOW.md`, `CONVENTIONS.md`, skills)
and re-renders them from `.claude/.kit-config`, so your project values survive. It never
touches `CLAUDE.md`, and it diffs the CLAUDE.md template against yours to print any new
sections you might want to merge in by hand.

See [`docs/upgrading.md`](docs/upgrading.md) for the full breakdown.

## Requirements

- A `wp-content/themes/` directory with `cool-fse/` (parent) and at least one child theme
- Claude Code CLI
- `gh` CLI (optional — only used by `/seal` when reading recent commits)

No external skill dependencies — Ponder runs its own interview.

## Why this exists

Working on cool-fse child themes with hand-rolled `grill-to-imp` / `execute-imp` /
`review-imp` skills got the job done but was too coupled to one project and blurred the
"plan" and "build" sessions.

This kit refines that into a small set of named phases, then strips out everything a
static-site WP theme doesn't need — GitHub issues, mission-control, tests, CI, and any
external skill dependency. Every cool-fse convention lives in exactly one place
([`CONVENTIONS.md`](kit/CONVENTIONS.md)), verified against a real cool-fse codebase.

The full rationale lives in [`docs/design-notes.md`](docs/design-notes.md).

## License

Personal use; no license granted yet.
