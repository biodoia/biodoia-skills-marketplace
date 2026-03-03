# Skill Master

Intelligent orchestrator for the Claude Code skill ecosystem. Combines proactive onboarding, adaptive learning, and persistent tools to ensure the right skills are always available at the right time.

## Architecture

Three integrated layers:

| Layer | Component | Role |
|-------|-----------|------|
| **Proactive** | SessionStart Hook | Scans project signals, injects recommendations |
| **Knowledge** | SKILL.md | Meta-skill with ecosystem knowledge, patterns, combinations |
| **Tools** | MCP Server | Persistent tools for search, recommend, analyze, evolve |

## Quick Start

### Install from marketplace
```
/install-plugin biodoia-skills-marketplace skill-master
```

### Automatic (hook-driven)
The SessionStart hook fires automatically on every conversation, detecting project signals and recommending relevant skills.

### Manual (commands)
```
/skill-recommend          # Get skill recommendations for current project
/skill-evolve             # Run adaptive analysis and propose improvements
```

### Programmatic (MCP tools)
The MCP server exposes 5 tools:
- `search_skills` — Search by keyword
- `recommend_stack` — Project-aware recommendations
- `analyze_usage` — Usage analytics + proposals
- `skill_health` — Quality scores for all skills
- `propose_evolution` — Improvement proposal for a specific skill

## Adaptive Growth

The system learns from usage:

1. **SessionStart hook** logs signals and recommendations to `~/.claude/skill-master-usage.jsonl`
2. **PostToolUse hook** logs actual skill invocations
3. **analyze-usage.py** computes metrics (trigger rates, organic rates, co-occurrence)
4. **Evolution proposals** identify gaps, noisy signals, and combination opportunities

See `skills/skill-master/references/adaptive-growth.md` for the full algorithm documentation.

## Signal Detection

| Signal | Detection | Skills |
|--------|-----------|--------|
| Go | go.mod | go-development, framegotui-sdk |
| Node.js | package.json | frontend-design |
| Docker | Dockerfile | docker-deployment |
| Plugin | .claude-plugin | marketplace-creator, plugin-dev |
| Tailscale | tailscale.json | tailscale-expert |
| Xen Orchestra | xo-cli.conf | xen-orchestra-expert |
| gRPC | proto/, buf.yaml | grpc-patterns |
| MCP | .mcp.json | plugin-dev:mcp-integration |

## Components

```
skill-master/
├── .claude-plugin/plugin.json     # Plugin manifest
├── .mcp.json                      # MCP server config
├── hooks/
│   ├── hooks.json                 # Hook definitions
│   ├── session-start.sh           # Proactive signal detection
│   └── track-skill-usage.sh       # Usage tracking
├── skills/skill-master/
│   ├── SKILL.md                   # Meta-skill knowledge base
│   ├── references/
│   │   ├── skill-catalog.md       # Complete ecosystem map
│   │   └── adaptive-growth.md     # Adaptation algorithms
│   └── scripts/
│       └── analyze-usage.py       # Usage analyzer CLI
├── commands/
│   ├── skill-recommend.md         # /skill-recommend
│   └── skill-evolve.md            # /skill-evolve
├── agents/
│   ├── skill-analyzer.md          # Deep project analysis
│   └── skill-evolver.md           # Evolution implementation
├── mcp-server/
│   └── server.py                  # MCP stdio server
└── README.md
```

## License

MIT
