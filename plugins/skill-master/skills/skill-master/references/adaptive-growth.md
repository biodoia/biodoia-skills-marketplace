# Adaptive Growth System — Deep Dive

## Philosophy

> "Il contesto è importante, i guardrails sono importanti, i tools sono importanti.
> Tutto ciò che serve, nulla di meno e nemmeno nulla di superfluo."

The adaptive growth system continuously analyzes the environment and adjusts:
- **What skills are loaded** (context-aware, not blanket loading)
- **What guardrails are active** (project-specific rules, not universal noise)
- **What tools are available** (relevant MCP servers, not everything at once)
- **What gets recommended** (learned from usage, not static mapping)

## Data Model

### Usage Log (`~/.claude/skill-master-usage.jsonl`)

Every skill interaction is a JSONL record:

```jsonl
{"ts":"2026-03-03T20:15:00+01:00","event":"session_start","project":"memogo","signals":"go framegotui grpc mcp web-ui","recommended":"framegotui-sdk grpc-patterns plugin-dev:mcp-integration"}
{"ts":"2026-03-03T20:15:30+01:00","event":"skill_used","skill":"superpowers:brainstorming","project":"memogo"}
{"ts":"2026-03-03T20:18:00+01:00","event":"skill_used","skill":"superpowers:test-driven-development","project":"memogo"}
{"ts":"2026-03-03T20:45:00+01:00","event":"skill_used","skill":"marketplace-creator","project":"biodoia-skills-marketplace"}
```

### Derived Metrics

From the raw log, the analyzer computes:

| Metric | Formula | Meaning |
|--------|---------|---------|
| **Trigger rate** | used_count / recommended_count | How often a recommended skill gets actually used |
| **Organic rate** | used_without_recommendation / total_used | Skills used without being recommended (signals missed) |
| **Project affinity** | skills_per_project_type | Which skills cluster around which project types |
| **Co-occurrence** | P(B used \| A used) | Skills that are always used together |
| **Staleness** | days_since_last_use | Skills that might be outdated or irrelevant |

## Adaptation Algorithms

### 1. Signal Expansion

**Problem**: A skill is frequently used in a project type but the hook doesn't recommend it.

**Detection**:
```
organic_rate(skill, project_type) > 0.3  # Used organically >30% of the time
AND NOT in signal_map(project_type)      # Not currently recommended
```

**Action**: Add new signal mapping. Example: if `tailscale-expert` is used in 40% of Go projects but not recommended, add `go+networking → tailscale-expert`.

### 2. Signal Contraction

**Problem**: A skill is recommended but never used.

**Detection**:
```
trigger_rate(skill, project_type) < 0.05  # Recommended but used <5%
AND recommendation_count > 10             # Enough data
```

**Action**: Remove from signal mapping for that project type. Reduces noise.

### 3. Description Tuning

**Problem**: A skill should trigger on a user query but doesn't (or vice versa).

**Detection**: Manual flag or pattern analysis showing low semantic match.

**Action**: Generate improved description using the `skill-creator` eval loop:
1. Analyze failed triggers from usage log
2. Generate candidate descriptions
3. Test with eval queries
4. Apply best-scoring description

### 4. Skill Gap Detection

**Problem**: Users repeatedly ask about a topic with no matching skill.

**Detection**:
```
COUNT(sessions WHERE no_skill_triggered AND topic = X) > 5
```

**Action**: Flag topic as candidate for new skill. Generate proposal with:
- Suggested name
- Draft description
- Estimated content areas
- Related existing skills

### 5. Combination Crystallization

**Problem**: Skills A and B are always used together (co-occurrence > 0.8).

**Detection**:
```
P(B | A) > 0.8 AND P(A | B) > 0.8
```

**Action**: Propose a combined workflow skill or a "stack template" in the catalog.

### 6. Content Freshness

**Problem**: A skill's references may be outdated (external APIs, library versions).

**Detection**:
- Skill references mention version numbers or dates
- Last modification date > 90 days
- User reported issues with outdated info

**Action**: Flag for review. If web search available, check for API changes.

## Evolution Workflow

### Automated (hook-driven)
1. SessionStart hook logs signals and recommendations
2. PostToolUse hook logs actual skill usage
3. Weekly: `analyze-usage.py` computes metrics
4. Flags anomalies (high organic rate, zero trigger rate, etc.)
5. Generates evolution proposals in `~/.claude/skill-master-proposals.md`

### Manual (command-driven)
```
/skill-evolve                    # Run full analysis
/skill-evolve --skill tailscale  # Analyze specific skill
/skill-evolve --gaps             # Find skill gaps only
/skill-evolve --combinations     # Find co-occurring skills
```

### MCP-driven (tool-based)
```
skill_master.analyze_usage()           # Full analysis
skill_master.propose_evolution(skill)  # Specific improvement
skill_master.skill_health()            # All skill quality scores
```

## Context-Aware Loading

The system avoids loading unnecessary context:

### Level 0: Always present (~100 words per skill)
- Skill names + descriptions from all installed plugins
- skill-master's hook-injected recommendations

### Level 1: On trigger (~2000 words)
- SKILL.md body loads when description matches
- Only the triggered skill, not all skills

### Level 2: On demand (unlimited)
- References load only when explicitly needed
- Scripts execute without loading into context

### Level 3: Never unless asked
- Usage analytics data
- Evolution proposals
- Historical patterns

This ensures **zero context waste** — every token in context is there because it's relevant to the current task.

## Guardrail Adaptation

The system can recommend project-specific guardrails:

| Project Type | Recommended Guardrails |
|-------------|----------------------|
| Production code | TDD, verification-before-completion, code-review |
| Plugin development | skill testing, progressive disclosure check |
| Infrastructure | plan-before-execute, confirmation prompts |
| Quick scripts | Minimal — just verification |

The SessionStart hook can inject these as context hints, letting the user decide which to follow.

## Metrics Dashboard

The `analyze-usage.py` script outputs:

```
=== SKILL MASTER ANALYTICS ===

Period: 2026-02-01 to 2026-03-03
Sessions analyzed: 47

Top skills by usage:
  1. superpowers:brainstorming         (38 uses, 81% of sessions)
  2. superpowers:tdd                   (29 uses, 62%)
  3. marketplace-creator               (12 uses, 26%)

Recommendation accuracy:
  Trigger rate: 73% (recommended → used)
  Organic rate: 18% (used without recommendation)

Proposed evolutions:
  [!] tailscale-expert: high organic rate in Go projects (42%) — add signal
  [!] plugin-dev:hook-development: low trigger rate (3%) — narrow description
  [+] "systemd-services": gap detected (7 sessions, no matching skill)
  [~] brainstorming + writing-plans: co-occurrence 0.89 — consider stack template
```
