---
name: skill-master
description: This skill should be used when the user asks "which skill should I use", "skill recommendations", "onboard me", "what skills do I have", "improve skills", "skill analytics", "adaptive skills", or "skill ecosystem". Make sure to use this skill whenever the user needs to find the right skill for a task, wants onboarding into a new project, needs skill combination recommendations, wants to analyze skill usage patterns, evolve or improve existing skills based on usage data, or manage the skill ecosystem, even if they just ask what tools or capabilities are available.
---

# Skill Master

Intelligent orchestrator for the entire Claude Code skill ecosystem. Provides proactive onboarding, skill recommendation, usage analytics, and adaptive growth -- skills that learn and improve from how they are used.

## Architecture

Three integrated layers work together:

1. **SessionStart Hook** (proactive) -- Fires on every conversation. Scans the project for signals (go.mod, Dockerfile, .claude-plugin, etc.) and injects recommended skills into context.

2. **This Skill** (knowledge) -- The meta-knowledge base. Contains information about what every skill does, when to combine them, and how to evolve them.

3. **MCP Server** (tools) -- Persistent tools for searching, recommending, installing, and evolving skills programmatically.

## Onboarding Flow

The onboarding process follows this sequence:

1. **Session starts** -- A new Claude Code conversation begins
2. **Hook scans project** -- The SessionStart hook examines the working directory
3. **Detect signals** -- File patterns and configurations are matched against known indicators
4. **Map to skills** -- Detected signals are mapped to relevant skills from the catalog
5. **Inject recommendations** -- Matched skills are surfaced in the conversation context
6. **User asks question** -- When the user queries about skills or capabilities...
7. **Skill-master triggers** -- This skill activates for deep analysis
8. **Recommend stack** -- A tailored combination of skills is proposed based on project context

## Signal Detection

The hook detects these project signals:

| Signal | Detection | Recommended Skills |
|--------|-----------|-------------------|
| Go project | go.mod, go.sum | go-development, framegotui-sdk |
| framegotui | pkg/core/app.go, import | framegotui-sdk (critical) |
| Node.js | package.json | frontend-design |
| Docker | Dockerfile, compose | docker-deployment |
| Claude plugin | .claude-plugin/ | marketplace-creator, plugin-dev:* |
| Tailscale | tailscale.json, /var/lib/tailscale | tailscale-expert |
| Xen Orchestra | xo-cli.conf | xen-orchestra-expert |
| gRPC | proto/, buf.yaml | grpc-patterns |
| MCP | .mcp.json, pkg/mcp | plugin-dev:mcp-integration |
| Web UI | pkg/web, web/ | frontend-design |
| CLAUDE.md | CLAUDE.md exists | claude-md-management |

### Configuring New Signals

To add a new signal detection pattern:

1. **Edit the hook script** at `hooks/session-start.sh` (or the equivalent hook configuration)
2. **Define the detection pattern** -- Specify file paths, directory names, or configuration keys that indicate the technology
3. **Map to skills** -- Associate the signal with one or more skill names from the catalog
4. **Set priority** -- Mark skills as "critical" (always inject), "recommended" (inject if relevant), or "optional" (mention only on request)
5. **Test detection** -- Run the hook manually against a sample project directory to verify correct matching

Example signal entry structure:
```
Signal name:     "terraform"
Detection:       main.tf, *.tf, .terraform/
Skills:          infrastructure-as-code (critical)
Compound:        terraform + tailscale -> network-infra-combo
```

## Skill Combination Patterns

Some tasks need multiple skills working together:

**New biodoia project** (Go + framegotui):
1. `framegotui-sdk` -- architecture patterns
2. `superpowers:test-driven-development` -- TDD discipline
3. `superpowers:brainstorming` -- design first
4. `marketplace-creator` -- if building a plugin

**Infrastructure task** (Tailscale + XO):
1. `tailscale-expert` -- VPN mesh
2. `xen-orchestra-expert` -- VM management
3. `superpowers:writing-plans` -- plan before executing

**Skill development** (meta):
1. `skill-creator:skill-creator` -- create and test skills
2. `plugin-dev:skill-development` -- plugin skill patterns
3. `superpowers:writing-skills` -- TDD for skills
4. `marketplace-creator` -- register in marketplace

## Adaptive Growth System

Skills evolve based on usage data. The system tracks patterns and proposes improvements automatically.

### What Gets Tracked

- Which skills are invoked per project type (via PostToolUse hook)
- Which signals map to which recommendations (via SessionStart hook)
- Session logs stored in `~/.claude/skill-master-usage.jsonl`

### Growth Cycle

The adaptive growth workflow operates as a continuous loop:

1. **Track usage** -- Record which skills are invoked, in what project context, and how often
2. **Analyze patterns** -- Aggregate usage data to find trends, correlations, and anomalies
3. **Identify gaps** -- Compare actual usage against expected mappings; if gaps exist, continue to step 4; otherwise, loop back to step 1
4. **Propose improvement** -- Generate a concrete change proposal (description tweak, new signal, content update)
5. **Test with evals** -- Validate the proposal does not break existing triggers or cause false positives
6. **Apply + version bump** -- Merge the change and increment the skill's patch or minor version
7. **Return to step 1** -- Continue monitoring to verify the improvement's effect

### Types of Adaptation

1. **Description tuning** -- If a skill should trigger but does not, widen the description triggers. If it triggers when it should not, narrow them.

2. **Signal mapping** -- If users in Go projects consistently invoke `tailscale-expert`, add `go+tailscale` as a compound signal in the hook configuration.

3. **Skill gaps** -- If users repeatedly ask about a topic with no matching skill, flag it as a candidate for a new skill. Log the topic and frequency in the usage JSONL file.

4. **Content evolution** -- If a skill's references are outdated (API changes, new features), flag for refresh. Compare reference file timestamps against upstream release dates when possible.

5. **Combination discovery** -- If skills A and B are always used together in the same session, suggest creating a combined workflow or meta-skill that bundles both.

### Running Analysis

Use the `/skill-evolve` command or the MCP tool `analyze_usage`:

```bash
# Via command
/skill-evolve

# Via MCP tool (if MCP server running)
# Tool: skill_master.analyze_usage

# Via the analysis script directly
python3 scripts/analyze-usage.py
```

## MCP Server Tools

The MCP server exposes these tools when running. Configuration is defined in `.mcp.json` at the plugin root:

```json
{
  "mcpServers": {
    "skill-master": {
      "command": "python3",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-server/server.py"]
    }
  }
}
```

| Tool | Description | Example Use |
|------|-------------|-------------|
| `search_skills` | Search all available skills by keyword or domain | Find skills related to "infrastructure" or "testing" |
| `recommend_stack` | Given a project path, recommend a skill stack | Analyze `/mnt/godata/projects/myapp` and suggest relevant skills |
| `analyze_usage` | Analyze usage.jsonl and propose improvements | Review last 30 days of skill invocations for optimization |
| `skill_health` | Check skill quality scores across the marketplace | Audit all skills for description quality, reference freshness |
| `propose_evolution` | Generate a specific improvement proposal for a skill | Suggest description changes for a skill with low trigger accuracy |

Start the server by ensuring the `.mcp.json` file is present in the plugin root. Claude Code automatically discovers and starts MCP servers defined in plugin `.mcp.json` files. The server implementation is at `mcp-server/server.py`.

## Integration with Other Skills

Skill Master serves as the coordination layer across the entire skill ecosystem:

- **With marketplace-creator**: After identifying a skill gap via usage analysis, invoke marketplace-creator to scaffold and register the new skill
- **With superpowers:writing-skills**: Use the TDD-for-skills methodology to validate proposed description changes before applying them
- **With plugin-dev:skill-development**: Follow plugin development patterns when creating new skills identified by the gap analysis
- **With any domain skill**: Skill Master's recommendations point users to the correct domain skill, reducing time spent searching for the right tool

## Progressive Disclosure

- Full skill catalog with descriptions and categories: `references/skill-catalog.md`
- Adaptive growth system deep dive: `references/adaptive-growth.md`
- Usage analysis script: `scripts/analyze-usage.py`

## Additional Resources

- Skill catalog and category reference: `references/skill-catalog.md`
- Adaptive growth system documentation: `references/adaptive-growth.md`
- MCP server implementation: `mcp-server/server.py`
- Usage analysis script: `scripts/analyze-usage.py`
- Hook configuration: `hooks/` directory at the plugin root
