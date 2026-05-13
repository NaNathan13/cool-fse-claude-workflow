# Upgrading

This kit ships only on the `main` branch — no semver, no releases. The latest commit on `main` is the live version.

## How to upgrade an installed project

From inside `wp-content/themes/`:

```bash
bash .claude/scripts/update.sh
```

That script just re-invokes `setup.sh` with `WORKFLOW.md` already present, which puts the installer in **update mode**.

## What update mode touches

**Overwritten:**
- `WORKFLOW.md`
- `.claude/skills/{ponder,forge,temper,seal,inscribe,scrub,researcher}/SKILL.md`
- `.claude/scripts/update.sh`

**Diff-prompted (asked before overwriting):**
- `.claude/settings.json` — your project may have added local permissions or hooks. Diff is shown and you confirm.

**Never touched:**
- `CLAUDE.md` — your project's. Hand-edit if the template added sections you want.
- `CONTEXT.md` — your project's. Hand-edit if the template added entries you want.
- `.claude/plans/` — both `active/` and `done/`.
- `.claude/screenshots/`.

## Template diff report

After the file copy, update mode compares the shipped templates against your current `CLAUDE.md` and `CONTEXT.md` and prints a list of top-level sections (`## Heading`) present in the template but missing from your file. Use that as a hand-merge worklist.

This is intentionally not automatic. The template is generic; your project file may have intentionally diverged.

## Rolling back

The installer doesn't keep a backup. Before upgrading, commit your current `.claude/` so you can `git checkout` if a skill change breaks something:

```bash
git add CLAUDE.md CONTEXT.md WORKFLOW.md .claude/
git commit -m "chore: snapshot before kit upgrade"
bash .claude/scripts/update.sh
```

If the upgrade introduces a regression, `git diff HEAD~1 -- .claude/skills/` to see what changed and either revert the file or open an issue on the kit repo.

## Adding to the kit (kit author)

This repo is the source of truth.

1. Make changes in `kit/` or `templates/`.
2. Test locally by running `setup.sh` against a throwaway `wp-content/themes/`-shaped directory.
3. Commit + push to `main`.
4. Existing installs pick up changes on their next `update.sh` run.
