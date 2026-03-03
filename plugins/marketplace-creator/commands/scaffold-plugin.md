---
description: Scaffold a new Claude Code plugin with selected components (skills, commands, hooks, agents, MCP)
argument-hint: <plugin-name> [--all | --with-skills --with-commands --with-hooks --with-agents --with-mcp]
allowed-tools: ["Read", "Write", "Bash", "Skill", "AskUserQuestion"]
---

# Scaffold Plugin

Generate the full directory structure for a new Claude Code plugin.

**Arguments:** $ARGUMENTS

## Workflow

1. Parse plugin name from arguments
2. If no component flags provided, ask the user which components to include
3. Run `scaffold-plugin.sh` from the marketplace-creator skill
4. Review the generated structure
5. If inside a marketplace repo, offer to register the plugin in marketplace.json

## Interactive Mode

If invoked without arguments, guide the user through:
- Plugin name (kebab-case validation)
- Description
- Components: skills, commands, hooks, agents, MCP
- Author info (default from git config)
