#!/usr/bin/env bash
# cool-fse-claude-workflow — installer / updater
# Run from inside `wp-content/themes/`:
#   curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
#
# First run: copies the kit, prompts for project values, renders every kit file
#            from them, and writes .claude/.kit-config.
# Re-run:    refreshes project-agnostic files and re-renders them from
#            .claude/.kit-config; never touches CLAUDE.md.

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

# Escape a value for the replacement side of a sed s|...|...| command.
sed_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//&/\\&}"
  s="${s//|/\\|}"
  printf '%s' "$s"
}

# Escape a value for embedding inside a JSON string literal.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# Read one string key out of a flat JSON file written by this script.
# Usage: kit_config_get KEY FILE
kit_config_get() {
  sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\"[[:space:]]*,\{0,1\}[[:space:]]*\$/\1/p" "$2" \
    | sed 's/\\"/"/g; s/\\\\/\\/g'
}

# render SRC DEST — substitute the four kit tokens (uses project_name/child_dir/
# local_url/local_port from the enclosing scope).
render() {
  local e_pn e_cd e_lu e_lp
  e_pn="$(sed_escape "$project_name")"
  e_cd="$(sed_escape "$child_dir")"
  e_lu="$(sed_escape "$local_url")"
  e_lp="$(sed_escape "$local_port")"
  sed \
    -e "s|{{PROJECT_NAME}}|${e_pn}|g" \
    -e "s|{{CHILD_THEME_DIR}}|${e_cd}|g" \
    -e "s|{{LOCAL_URL}}|${e_lu}|g" \
    -e "s|{{LOCAL_PORT}}|${e_lp}|g" \
    "$1" > "$2"
}

# render_inplace FILE — render a file over itself (no-op if it doesn't exist).
render_inplace() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if render "$f" "$f.kit-tmp"; then
    mv "$f.kit-tmp" "$f"
  else
    rm -f "$f.kit-tmp"
    return 1
  fi
}

REPO_URL="https://github.com/NaNathan13/cool-fse-claude-workflow.git"
TARGET="$(pwd)"
KIT_CONFIG="$TARGET/.claude/.kit-config"

# Skills retired from the kit — purged from existing installs on update.
# The current skill list (KIT_SKILLS) is derived from the cloned repo below.
LEGACY_SKILLS=(scrub burnish appraise researcher)

# Banner (colors only when stdout is a terminal)
if [[ -t 1 ]]; then
  C=$'\033[38;5;111m' B=$'\033[38;5;75m' G=$'\033[38;5;78m'
  Y=$'\033[38;5;178m' R=$'\033[38;5;203m' D=$'\033[38;5;240m' N=$'\033[0m'
else
  C='' B='' G='' Y='' R='' D='' N=''
fi

printf '%s\n' "" \
  "${C}                    __       ____${N}" \
  "${C}   _________  ____ ${B}/ /${C}     ${B}/ __/${C}_______${N}" \
  "${C}  / ___/ __ \\/ __ \\${B}/ /${D}_____${B}/ /${C}_/ ___/ _ \\${N}" \
  "${C} / /__/ /_/ / /_/ ${B}/ /${D}_____${B}/ __/${C}__  )  __/${N}" \
  "${C} \\___/\\____/\\____/${B}_/${C}     ${B}/_/${C} /____/\\___/${N}" \
  "" \
  "  ${D}──────────────────────────────────────────────${N}" \
  "  💭 ${G}ponder${N}  →  🔥 ${Y}forge${N}  →  🧊 ${B}temper${N}  →  🗡️  ${R}seal${N}" \
  "  ${D}──────────────────────────────────────────────${N}" \
  ""
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

# Derive the kit's skill list from what the repo actually ships, so the copy
# and render passes can't drift when skills are added to or removed from the kit.
KIT_SKILLS=()
for d in "$SRC"/kit/.claude/skills/*/; do
  [[ -d "$d" ]] && KIT_SKILLS+=("$(basename "$d")")
done

# --- 4. Gather project values ---------------------------------------------------------
# Install always prompts. Update reads .claude/.kit-config; if it's missing
# (a pre-templating install), it prompts the same way and the file is written below.
need_config_write="no"

# Update mode reads the persisted values; install mode — or an update with a
# missing/incomplete .kit-config — prompts for them and (re)writes the file.
if [[ "$MODE" == "update" && -f "$KIT_CONFIG" ]]; then
  project_name="$(kit_config_get project_name "$KIT_CONFIG")"
  child_dir="$(kit_config_get child_theme_dir "$KIT_CONFIG")"
  local_url="$(kit_config_get local_url "$KIT_CONFIG")"
  local_port="$(kit_config_get local_port "$KIT_CONFIG")"
  [[ -z "$local_port" ]] && local_port="10000"
fi

if [[ -n "${project_name:-}" && -n "${child_dir:-}" && -n "${local_url:-}" ]]; then
  echo "→ project config: loaded from .claude/.kit-config"
  echo "  project: $project_name · child theme: $child_dir/ · url: $local_url"
else
  echo ""
  if [[ "$MODE" == "update" ]]; then
    echo "→ .claude/.kit-config is missing or incomplete — enter your project values"
    echo "  so the kit files can be re-rendered:"
  else
    echo "→ project setup"
  fi
  default_child="${child_candidates[0]}"
  prompt project_name "Project name (e.g. \"Acme Site\")" "My Project" "PROJECT_NAME"
  prompt child_dir    "Child theme directory" "$default_child" "CHILD_THEME_DIR"
  default_url="http://${child_dir}.local/"
  prompt local_url    "Local URL" "$default_url" "LOCAL_URL"
  # Local proxy port defaults to 10000 (BrowserSync default for cool-fse).
  # Edit CLAUDE.md after install if your stack uses something else.
  local_port="${LOCAL_PORT:-10000}"
  need_config_write="yes"
fi

# --- 5. Copy project-agnostic files (both modes) --------------------------------------
echo ""
echo "→ copying WORKFLOW.md + CONVENTIONS.md + UTILITY-CLASSES.md"
cp "$SRC/kit/WORKFLOW.md" "$TARGET/WORKFLOW.md"
cp "$SRC/kit/CONVENTIONS.md" "$TARGET/CONVENTIONS.md"
cp "$SRC/kit/UTILITY-CLASSES.md" "$TARGET/UTILITY-CLASSES.md"

echo "→ copying .claude/skills"
mkdir -p "$TARGET/.claude/skills"
for s in "${KIT_SKILLS[@]}" "${LEGACY_SKILLS[@]}"; do
  rm -rf "$TARGET/.claude/skills/$s"
done
cp -R "$SRC/kit/.claude/skills/." "$TARGET/.claude/skills/"

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

# update.sh helper
mkdir -p "$TARGET/.claude/scripts"
cat > "$TARGET/.claude/scripts/update.sh" <<'EOF'
#!/usr/bin/env bash
# Re-run the installer in update mode.
cd "$(dirname "$0")/../.." && curl -fsSL https://raw.githubusercontent.com/NaNathan13/cool-fse-claude-workflow/main/setup.sh | bash
EOF
chmod +x "$TARGET/.claude/scripts/update.sh"

# --- 6. Write .claude/.kit-config -----------------------------------------------------
if [[ "$need_config_write" == "yes" ]]; then
  cat > "$KIT_CONFIG" <<EOF
{
  "project_name": "$(json_escape "$project_name")",
  "child_theme_dir": "$(json_escape "$child_dir")",
  "local_url": "$(json_escape "$local_url")",
  "local_port": "$(json_escape "$local_port")"
}
EOF
  echo "→ wrote .claude/.kit-config"
fi

# --- 7. Render kit files from project values ------------------------------------------
echo "→ rendering WORKFLOW.md + CONVENTIONS.md + UTILITY-CLASSES.md + skills"
render_inplace "$TARGET/WORKFLOW.md"
render_inplace "$TARGET/CONVENTIONS.md"
render_inplace "$TARGET/UTILITY-CLASSES.md"
for s in "${KIT_SKILLS[@]}"; do
  render_inplace "$TARGET/.claude/skills/$s/SKILL.md"
done

# --- 8. Install mode: render CLAUDE.md ------------------------------------------------
if [[ "$MODE" == "install" ]]; then
  echo "→ rendering CLAUDE.md"

  # Render CLAUDE.md — skip if it already exists (don't clobber hand-edited content)
  if [[ -f "$TARGET/CLAUDE.md" ]]; then
    echo "  → CLAUDE.md exists, skipping (rendered template at CLAUDE.md.template-rendered for reference)"
    render "$SRC/templates/CLAUDE.md.template" "$TARGET/CLAUDE.md.template-rendered"
  else
    render "$SRC/templates/CLAUDE.md.template" "$TARGET/CLAUDE.md"
    echo "  → wrote CLAUDE.md"
  fi

  echo ""
  echo "✓ Installed."
  echo ""
  echo "  Next steps:"
  echo "  1. Start a new Claude Code session here: cd $TARGET && claude"
  echo "  2. Skim WORKFLOW.md + CONVENTIONS.md once, then try /ponder on your first task."
  echo ""
  exit 0
fi

# --- 9. Update mode: diff templates and report ----------------------------------------
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

# CONTEXT.md was retired — its content folded into CLAUDE.md + CONVENTIONS.md.
if [[ -f "$TARGET/CONTEXT.md" ]]; then
  echo ""
  echo "  note: CONTEXT.md is no longer used by the kit (folded into CLAUDE.md + CONVENTIONS.md)."
  echo "        Nothing references it now — safe to delete once you've moved any custom terms."
fi

echo ""
echo "✓ Updated."
echo "  WORKFLOW.md, CONVENTIONS.md, + .claude/skills/ refreshed and re-rendered from .claude/.kit-config."
echo "  CLAUDE.md, .claude/plans/, .claude/screenshots/ untouched."
echo ""
