#!/usr/bin/env bash
# PreToolUse hook on the Skill tool.
# If the invoked skill declares `model: <tier>` in its frontmatter and the
# current session is on a different tier, prints a non-blocking
# <system-reminder> recommending /model <tier>. Always exits 0.
#
# Hook input (JSON on stdin) — relevant fields:
#   tool_name:        "Skill"
#   tool_input.skill: the skill name (e.g., "ponder")
#
# Current model is read from $CLAUDE_MODEL or falls back to $ANTHROPIC_MODEL.

set -uo pipefail

input="$(cat)"

# Bail if not a Skill invocation
tool_name=$(printf '%s' "$input" | sed -nE 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -1)
[[ "$tool_name" == "Skill" ]] || exit 0

# Extract skill name
skill=$(printf '%s' "$input" | sed -nE 's/.*"skill"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -1)
[[ -n "$skill" ]] || exit 0

# Find the SKILL.md file. Search the project's .claude/skills/ first, then user-global.
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
skill_file=""
for candidate in \
  "$project_dir/.claude/skills/$skill/SKILL.md" \
  "$HOME/.claude/skills/$skill/SKILL.md"; do
  [[ -f "$candidate" ]] && { skill_file="$candidate"; break; }
done
[[ -n "$skill_file" ]] || exit 0

# Read preferred model from frontmatter (line `preferred-model: <tier>` between two `---` lines)
# NB: we deliberately avoid the `model:` key — Claude Code itself consumes that
# field and will hard-switch the session to it, which fails for IDs like
# `opus-4-7` (the canonical ID is `claude-opus-4-7`). Using a distinct key
# means only this hook reads it, and we surface a soft suggestion instead.
preferred=$(awk '
  /^---/ { if (++fence == 2) exit; next }
  fence == 1 && /^preferred-model:/ { sub(/^preferred-model:[[:space:]]*/, ""); gsub(/[[:space:]]*$/, ""); print; exit }
' "$skill_file")
[[ -n "$preferred" ]] || exit 0

# Current model
current="${CLAUDE_MODEL:-${ANTHROPIC_MODEL:-unknown}}"

# Normalize: strip "claude-" prefix and any "-YYYYMMDD" suffix and "[1m]" tags
norm() {
  printf '%s' "$1" \
    | sed -E 's/^claude-//; s/\[[^]]*\]//g; s/-[0-9]{8}$//; s/[[:space:]]+//g' \
    | tr 'A-Z' 'a-z'
}

p_norm=$(norm "$preferred")
c_norm=$(norm "$current")

# Match if normalized current contains preferred (e.g. opus-4-7 ⊂ opus-4-7-1m)
case "$c_norm" in
  *"$p_norm"*) exit 0 ;;
esac

cat <<EOF
<system-reminder>
This skill prefers ${preferred}. Current session is on ${current}.
Run /model ${preferred} to switch, or proceed if quick.
</system-reminder>
EOF

exit 0
