---
name: researcher
description: Reusable brief template for dispatching read-only research subagents with strict scope, token budget, and output format. Not a phase — a pattern used inside Ponder (codebase research) and Forge (checking existing blocks/patterns). Triggered by /researcher or referenced internally.
---

A research subagent brief template. Use this pattern whenever you need to dispatch an agent to investigate the codebase, check existing patterns, or gather information — without letting it edit files or sprawl unbounded.

This is not a phase. It's a tool you reach for inside other phases (Ponder, Forge) when the codebase can answer a question faster than the user can.

## The brief template

Every research dispatch must include all five fields. Copy this structure and fill in the blanks:

```
**What to find:** <specific question — one question per dispatch>
**Where to look:** <file paths, directories, or grep patterns>
**What NOT to do:** Read and report only. Do not edit, create, or delete any files. Do not run build commands. Do not install anything.
**Output format:** <bullet list | table | single paragraph — pick one>
**Word cap:** <150 | 300 | 500 — pick one; default 300>
```

## Rules

1. **One question per dispatch.** "What utility classes exist for flexbox AND what custom elements handle sliders" is two dispatches, not one. Break it up.

2. **Always set a word cap.** Default to 300 words. Use 150 for simple lookups ("does class X exist?"). Use 500 only for surveys ("list all blocks that use ada-slider and describe how each uses it").

3. **No implementation.** Research agents read and report. They never edit files. Include the "What NOT to do" line in every brief — even when it feels obvious.

4. **Scope the search path.** "Look in the codebase" is too vague. "Look in `cool-fse/blocks/global/css/`" is scoped. "Grep for `ada-slider` in `cool-fse/blocks/`" is better.

5. **Prefer multiple focused agents over one sprawling one.** If you need three answers from three different parts of the codebase, dispatch three agents in a single message (parallel). Each gets its own brief from this template.

6. **Use the right agent type.** For codebase searches, use the `Explore` subagent type — it's optimized for read-only search. For web research or broader investigation, use `general-purpose`.

## When to use

### Inside Ponder

During the grill, when the codebase can answer a question faster than asking the user:

- "What utility classes cover flexbox layouts?" → dispatch researcher to `cool-fse/blocks/global/css/`
- "Do any existing blocks use `<ada-slider>`?" → dispatch researcher to grep across `blocks/`
- "What ACF field patterns does the child theme already use?" → dispatch researcher to `<child-theme>/acf-json/`

Dispatch the research, continue grilling on other branches while it returns.

### Inside Forge

Before building, to verify the plan's assumptions still hold:

- "Does the utility class `flex-col` actually exist?" → quick researcher before writing markup that depends on it
- "What does the parent block's PHP look like for this override?" → researcher to read and summarize the parent file
- "Are there any other blocks using this ACF field key pattern?" → researcher to check for conflicts

## Example dispatch

Three parallel research agents dispatched in a single message during Ponder:

```
Agent 1 (Explore):
  What to find: All utility classes related to flexbox (display, direction, wrap, gap, align, justify)
  Where to look: cool-fse/blocks/global/css/
  What NOT to do: Read and report only. Do not edit, create, or delete any files.
  Output format: table with columns: class name, CSS property, value
  Word cap: 300

Agent 2 (Explore):
  What to find: Which existing blocks use <ada-slider> and how they configure it (attributes used)
  Where to look: grep for "ada-slider" in cool-fse/blocks/ and <child-theme>/blocks/
  What NOT to do: Read and report only. Do not edit, create, or delete any files.
  Output format: bullet list — one entry per block, with the relevant PHP snippet
  Word cap: 300

Agent 3 (Explore):
  What to find: What ACF field key prefix pattern the child theme uses (e.g., field_<block>_<name>)
  Where to look: <child-theme>/acf-json/
  What NOT to do: Read and report only. Do not edit, create, or delete any files.
  Output format: single paragraph summarizing the convention, with 2-3 examples
  Word cap: 150
```

## Don't do

- **Don't dispatch research for things you can check in one `grep`.** If it's a single file lookup, just read the file yourself.
- **Don't let research block the conversation.** Dispatch in the background or in parallel with other work when possible.
- **Don't skip the brief template.** Unbriefed agents wander, burn tokens, and return essays instead of answers.
