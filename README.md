# biodoia-skills-marketplace

Curated Claude Code plugin marketplace by **biodoia** — cyberpunk skills ecosystem.

## Installation

Register this marketplace in Claude Code:

```bash
# Via Claude Code CLI
claude /plugin
# Select "Add marketplace" → enter: biodoia/biodoia-skills-marketplace
```

## Available Plugins

| Plugin | Description | Category |
|--------|-------------|----------|
| **marketplace-creator** | Create and manage plugin marketplaces — scaffold plugins, manage registries, audit quality, interactive web creator | development |

## Plugin: marketplace-creator

Full lifecycle management for Claude Code plugin marketplaces:

- **Initialize** marketplace repositories on GitHub
- **Scaffold** new plugins with skills, commands, hooks, agents, MCP
- **Register** plugins in the marketplace registry
- **Audit** marketplace structure and plugin quality
- **Visual Creator** — cyberpunk web UI for designing skills interactively

### Commands
- `/create-marketplace` — Create a new marketplace repo
- `/scaffold-plugin` — Generate a plugin structure
- `/audit-marketplace` — Validate marketplace quality

### Web Creator
Open `plugins/marketplace-creator/skills/marketplace-creator/assets/skill-creator-web.html` for the interactive skill designer.

## Contributing

1. Fork this repository
2. Add your plugin to `plugins/` or reference an external repo
3. Register it in `.claude-plugin/marketplace.json`
4. Submit a pull request

## License

MIT
