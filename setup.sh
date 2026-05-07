#!/usr/bin/env bash
# cool-fse-claude-workflow — installer / updater
# Run from inside `wp-content/themes/`:
#   curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
#
# First run: copies kit + renders CLAUDE.md / CONTEXT.md from templates.
# Re-run:    overwrites project-agnostic files only; never touches CLAUDE.md / CONTEXT.md.

set -o pipefail

# Read from /dev/tty if available, else fall back to env var or default.
# Usage: prompt VAR_NAME "Prompt text" "default" "ENV_VAR_NAME"
prompt() {
  local var="$1" msg="$2" default="$3" envvar="$4"
  local envval="${!envvar:-}"
  if [[ -n "$envval" ]]; then
    printf -v "$var" '%s' "$envval"
    echo "  $msg [$envval] (from \$$envvar)"
    return
  fi
  if [[ -r /dev/tty ]]; then
    if [[ -n "$default" ]]; then
      printf "  %s [%s]: " "$msg" "$default"
    else
      printf "  %s: " "$msg"
    fi
    local ans=""
    read -r ans </dev/tty || ans=""
    [[ -z "$ans" ]] && ans="$default"
    printf -v "$var" '%s' "$ans"
  else
    printf -v "$var" '%s' "$default"
    echo "  $msg → $default (no tty; using default)"
  fi
}

REPO_URL="https://github.com/NaNathan13/cool-fse-claude-workflow.git"
TARGET="$(pwd)"

echo ""
echo "→ cool-fse-claude-workflow installer"
echo "  target: $TARGET"
echo ""

# --- 1. Verify we're in a wp-content/themes/ dir --------------------------------------
if [[ ! -d "$TARGET/cool-fse" ]]; then
  echo "✗ This doesn't look like a wp-content/themes/ directory (no cool-fse/ sibling)."
  echo "  cd into your themes dir and run again."
  exit 1
fi

# Find non-cool-fse theme dirs to suggest as the child theme
child_candidates=()
for d in "$TARGET"/*/; do
  name="$(basename "$d")"
  [[ "$name" == "cool-fse" ]] && continue
  [[ -f "$d/style.css" || -f "$d/functions.php" ]] && child_candidates+=("$name")
done

if [[ ${#child_candidates[@]} -eq 0 ]]; then
  echo "✗ No child theme detected (need at least one non-cool-fse theme dir with style.css or functions.php)."
  exit 1
fi

# --- 2. Detect first-run vs update ----------------------------------------------------
MODE="install"
if [[ -f "$TARGET/WORKFLOW.md" ]]; then
  MODE="update"
fi
echo "→ mode: $MODE"

# --- 3. Clone repo to a temp dir ------------------------------------------------------
TMPDIR="$(mktemp -d -t cool-fse-claude-workflow.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "→ fetching repo..."
if ! git clone --depth 1 "$REPO_URL" "$TMPDIR/repo" >/dev/null 2>&1; then
  echo "✗ Failed to clone $REPO_URL"
  echo "  Check connectivity, gh auth, and that the repo exists."
  exit 1
fi
SRC="$TMPDIR/repo"

# --- 4. Copy project-agnostic files (both modes) --------------------------------------
echo "→ copying WORKFLOW.md"
cp "$SRC/kit/WORKFLOW.md" "$TARGET/WORKFLOW.md"

echo "→ copying .claude/skills"
mkdir -p "$TARGET/.claude/skills"
rm -rf "$TARGET/.claude/skills/ponder" "$TARGET/.claude/skills/forge" "$TARGET/.claude/skills/temper" "$TARGET/.claude/skills/seal" "$TARGET/.claude/skills/inscribe"
cp -R "$SRC/kit/.claude/skills/." "$TARGET/.claude/skills/"

echo "→ copying .claude/hooks"
mkdir -p "$TARGET/.claude/hooks"
cp "$SRC/kit/.claude/hooks/model-router.sh" "$TARGET/.claude/hooks/model-router.sh"
chmod +x "$TARGET/.claude/hooks/model-router.sh"

# settings.json — copy on install, diff-prompt on update
if [[ "$MODE" == "install" ]]; then
  echo "→ copying .claude/settings.json"
  cp "$SRC/kit/.claude/settings.json" "$TARGET/.claude/settings.json"
else
  if ! diff -q "$SRC/kit/.claude/settings.json" "$TARGET/.claude/settings.json" >/dev/null 2>&1; then
    echo ""
    echo "  .claude/settings.json differs from shipped version."
    echo "  Diff (shipped → yours):"
    diff "$SRC/kit/.claude/settings.json" "$TARGET/.claude/settings.json" | sed 's/^/    /'
    echo ""
    ans="n"
    if [[ "${OVERWRITE_SETTINGS:-}" == "y" ]]; then
      ans="y"
    elif [[ -r /dev/tty ]]; then
      printf "  Overwrite settings.json? [y/N] "
      read -r ans </dev/tty || ans="n"
    fi
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      cp "$SRC/kit/.claude/settings.json" "$TARGET/.claude/settings.json"
      echo "  → overwritten"
    else
      echo "  → kept yours"
    fi
  fi
fi

# Plans + screenshots dirs
mkdir -p "$TARGET/.claude/plans/active" "$TARGET/.claude/plans/done" "$TARGET/.claude/screenshots"
[[ -f "$TARGET/.claude/plans/active/.gitkeep" ]] || touch "$TARGET/.claude/plans/active/.gitkeep"
[[ -f "$TARGET/.claude/plans/done/.gitkeep" ]] || touch "$TARGET/.claude/plans/done/.gitkeep"
[[ -f "$TARGET/.claude/screenshots/.gitkeep" ]] || touch "$TARGET/.claude/screenshots/.gitkeep"

# Drop the shipped example plan into done/ on first install only
if [[ "$MODE" == "install" && -f "$SRC/kit/.claude/plans/done/EXAMPLE-testimonial-slider.md" ]]; then
  cp "$SRC/kit/.claude/plans/done/EXAMPLE-testimonial-slider.md" "$TARGET/.claude/plans/done/"
fi

# update.sh helper
mkdir -p "$TARGET/.claude/scripts"
cat > "$TARGET/.claude/scripts/update.sh" <<'EOF'
#!/usr/bin/env bash
# Re-run the installer in update mode.
cd "$(dirname "$0")/../.." && curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
EOF
chmod +x "$TARGET/.claude/scripts/update.sh"

# --- 5. Install mode: render templates ------------------------------------------------
if [[ "$MODE" == "install" ]]; then
  echo ""
  echo "→ rendering templates"

  # Suggest first child theme as default
  default_child="${child_candidates[0]}"

  prompt project_name "Project name (e.g. \"Acme Site\")" "My Project" "PROJECT_NAME"
  prompt child_dir    "Child theme directory" "$default_child" "CHILD_THEME_DIR"
  default_url="http://${child_dir}.local/"
  prompt local_url    "Local URL" "$default_url" "LOCAL_URL"
  # Local proxy port is hardcoded to 10000 (BrowserSync default for cool-fse).
  # Edit CLAUDE.md after install if your stack uses something else.
  local_port="${LOCAL_PORT:-10000}"

  # Render CLAUDE.md — skip if it already exists (don't clobber hand-edited content)
  if [[ -f "$TARGET/CLAUDE.md" ]]; then
    echo "  → CLAUDE.md exists, skipping (rendered template at $TARGET/CLAUDE.md.template-rendered for reference)"
    sed \
      -e "s|{{PROJECT_NAME}}|${project_name}|g" \
      -e "s|{{CHILD_THEME_DIR}}|${child_dir}|g" \
      -e "s|{{LOCAL_URL}}|${local_url}|g" \
      -e "s|{{LOCAL_PORT}}|${local_port}|g" \
      "$SRC/templates/CLAUDE.md.template" > "$TARGET/CLAUDE.md.template-rendered"
  else
    sed \
      -e "s|{{PROJECT_NAME}}|${project_name}|g" \
      -e "s|{{CHILD_THEME_DIR}}|${child_dir}|g" \
      -e "s|{{LOCAL_URL}}|${local_url}|g" \
      -e "s|{{LOCAL_PORT}}|${local_port}|g" \
      "$SRC/templates/CLAUDE.md.template" > "$TARGET/CLAUDE.md"
    echo "  → wrote CLAUDE.md"
  fi

  if [[ -f "$TARGET/CONTEXT.md" ]]; then
    echo "  → CONTEXT.md exists, skipping (template at $TARGET/CONTEXT.md.template-shipped for reference)"
    cp "$SRC/templates/CONTEXT.md.template" "$TARGET/CONTEXT.md.template-shipped"
  else
    cp "$SRC/templates/CONTEXT.md.template" "$TARGET/CONTEXT.md"
    echo "  → wrote CONTEXT.md"
  fi

  echo ""
  echo "✓ Installed."
  echo ""
  echo "  Next steps:"
  echo "  1. Open WORKFLOW.md and skim it once."
  echo "  2. Make sure the upstream /grill-me skill is installed (Pocock skills library)."
  echo "  3. Start a new Claude Code session here: cd $TARGET && claude"
  echo "  4. Try /ponder on your first task."
  echo ""
  exit 0
fi

# --- 6. Update mode: diff templates and report ----------------------------------------
echo ""
echo "→ checking templates against your current files"

template_diff_report() {
  local template="$1"
  local actual="$2"
  local label="$3"

  [[ -f "$actual" ]] || return 0
  [[ -f "$template" ]] || return 0

  # Strip placeholders from template before diffing — actual file has them filled in
  local stripped="$TMPDIR/stripped.${label}"
  sed -E 's/\{\{[A-Z_]+\}\}/<value>/g' "$template" > "$stripped"

  # Compute new top-level sections in template missing from actual
  local new_sections
  new_sections=$(comm -23 \
    <(grep -E '^## ' "$stripped" | sort -u) \
    <(grep -E '^## ' "$actual" | sort -u))

  if [[ -n "$new_sections" ]]; then
    echo ""
    echo "  $label — new template sections you may want to merge in by hand:"
    echo "$new_sections" | sed 's/^/    /'
  fi
}

template_diff_report "$SRC/templates/CLAUDE.md.template" "$TARGET/CLAUDE.md" "CLAUDE.md"
template_diff_report "$SRC/templates/CONTEXT.md.template" "$TARGET/CONTEXT.md" "CONTEXT.md"

echo ""
echo "✓ Updated."
echo "  WORKFLOW.md, .claude/skills/, .claude/hooks/ overwritten."
echo "  CLAUDE.md, CONTEXT.md, .claude/plans/, .claude/screenshots/ untouched."
echo ""
