---
name: skill-recommend
description: Get intelligent skill recommendations for the current project based on detected signals, usage patterns, and adaptive learning
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# /skill-recommend

Analyze the current project and recommend the optimal skill stack.

## Process

1. **Detect project signals** — Scan for go.mod, package.json, Dockerfile, .claude-plugin, proto/, .mcp.json, tailscale configs, xen orchestra configs, CLAUDE.md, and other markers.

2. **Check usage history** — Read `~/.claude/skill-master-usage.jsonl` for this project's past skill usage patterns. Identify which skills were previously effective here.

3. **Cross-reference catalog** — Match detected signals against the skill catalog (read `references/skill-catalog.md` from the skill-master skill). Map signals to recommended skills with confidence levels.

4. **Apply adaptive learning** — If usage data exists:
   - Boost skills with high trigger rates for this project type
   - Demote skills with low trigger rates (noisy recommendations)
   - Include organically-used skills that aren't in the default signal map
   - Suggest co-occurring skill pairs that work well together

5. **Present recommendations** — Output a prioritized skill stack:

```
Recommended skills for [project]:

  Critical (always use):
    1. skill-name — reason

  Recommended (likely useful):
    2. skill-name — reason

  Optional (if needed):
    3. skill-name — reason

  Stack template match: [template name]
    → skill-a → skill-b → skill-c (workflow order)
```

6. **Offer installation** — For any recommended skill not yet installed, offer to install it from the marketplace.

## Flags

- No arguments: analyze current directory
- `--all`: show all available skills with relevance scores
- `--install`: auto-install missing recommended skills
- `--json`: output as JSON for programmatic use
