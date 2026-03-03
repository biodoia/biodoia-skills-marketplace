---
name: skill-evolve
description: Analyze skill usage patterns, detect gaps, and propose adaptive improvements to the skill ecosystem
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
---

# /skill-evolve

Run the adaptive growth analysis on the skill ecosystem.

## Process

1. **Load usage data** — Read `~/.claude/skill-master-usage.jsonl`. If no data exists, explain that usage tracking happens automatically via the SessionStart and PostToolUse hooks, and the user should run some sessions first.

2. **Run analysis** — Execute `python3 <plugin_root>/skills/skill-master/scripts/analyze-usage.py --json --period 90` to get metrics.

3. **Interpret results** — For each proposed evolution:

   ### Signal Expansion (high organic rate)
   - A skill is being used frequently without being recommended
   - **Action**: Update the SessionStart hook's signal detection to include new triggers
   - Show the specific signal → skill mapping to add

   ### Signal Contraction (low trigger rate)
   - A skill is recommended but rarely used
   - **Action**: Narrow or remove the signal mapping
   - Show which signal → skill mapping to remove or restrict

   ### Combination Discovery (high co-occurrence)
   - Two skills are always used together
   - **Action**: Propose a stack template or combined workflow
   - Show the co-occurrence rate and suggested template

   ### Skill Gap Detection
   - Users repeatedly work on topics with no matching skill
   - **Action**: Propose a new skill with draft name, description, and content areas
   - Use the skill-creator workflow to build it

   ### Description Tuning
   - A skill should trigger but doesn't match user queries
   - **Action**: Propose improved description text

4. **Present report** with the formatted analytics dashboard.

5. **Offer to apply** — For each proposal, ask if the user wants to:
   - Apply automatically (edit hooks, update descriptions)
   - Create a new skill (launch skill-creator)
   - Dismiss (mark as reviewed)

## Flags

- No arguments: full analysis (90 days)
- `--period N`: analyze last N days
- `--skill NAME`: focus on a specific skill
- `--gaps`: show only skill gap proposals
- `--combinations`: show only co-occurrence patterns
- `--apply`: auto-apply safe proposals (signal expansion/contraction)
