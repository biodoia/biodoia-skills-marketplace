#!/usr/bin/env bash
# Scaffold a new Claude Code plugin with selected components
# Usage: scaffold-plugin.sh <plugin-name> [options]
#   --with-skills      Include skills/ skeleton
#   --with-commands    Include commands/ skeleton
#   --with-hooks       Include hooks/ skeleton
#   --with-agents      Include agents/ skeleton
#   --with-mcp         Include .mcp.json skeleton
#   --author "Name"    Author name (default: git user.name)
#   --email "email"    Author email (default: git user.email)
#   --description "d"  Plugin description
#   --dir <path>       Parent directory (default: current dir)
#   --all              Include all components
set -euo pipefail

PLUGIN_NAME="${1:?Usage: scaffold-plugin.sh <plugin-name> [--with-skills] [--with-commands] [--with-hooks] [--with-agents] [--with-mcp] [--all]}"

# Validate plugin name
if ! echo "$PLUGIN_NAME" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
    echo "ERROR: Plugin name must be kebab-case: ^[a-z][a-z0-9]*(-[a-z0-9]+)*$"
    echo "  Got: $PLUGIN_NAME"
    exit 1
fi

# Defaults
WITH_SKILLS=false
WITH_COMMANDS=false
WITH_HOOKS=false
WITH_AGENTS=false
WITH_MCP=false
AUTHOR_NAME="$(git config user.name 2>/dev/null || echo 'Author')"
AUTHOR_EMAIL="$(git config user.email 2>/dev/null || echo 'author@example.com')"
DESCRIPTION="A Claude Code plugin"
PARENT_DIR="."

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-skills)   WITH_SKILLS=true; shift ;;
        --with-commands) WITH_COMMANDS=true; shift ;;
        --with-hooks)    WITH_HOOKS=true; shift ;;
        --with-agents)   WITH_AGENTS=true; shift ;;
        --with-mcp)      WITH_MCP=true; shift ;;
        --all)           WITH_SKILLS=true; WITH_COMMANDS=true; WITH_HOOKS=true; WITH_AGENTS=true; WITH_MCP=true; shift ;;
        --author)        AUTHOR_NAME="$2"; shift 2 ;;
        --email)         AUTHOR_EMAIL="$2"; shift 2 ;;
        --description)   DESCRIPTION="$2"; shift 2 ;;
        --dir)           PARENT_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

PLUGIN_DIR="$PARENT_DIR/$PLUGIN_NAME"

echo "=== Scaffolding plugin: $PLUGIN_NAME ==="

# Create base structure
mkdir -p "$PLUGIN_DIR/.claude-plugin"

# plugin.json
cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << MANIFEST
{
  "name": "$PLUGIN_NAME",
  "description": "$DESCRIPTION",
  "version": "0.1.0",
  "author": {
    "name": "$AUTHOR_NAME",
    "email": "$AUTHOR_EMAIL"
  },
  "license": "MIT",
  "keywords": []
}
MANIFEST

echo "  Created .claude-plugin/plugin.json"

# Skills
if $WITH_SKILLS; then
    SKILL_DIR="$PLUGIN_DIR/skills/$PLUGIN_NAME"
    mkdir -p "$SKILL_DIR"/{references,scripts}
    cat > "$SKILL_DIR/SKILL.md" << 'SKILLMD'
---
name: PLUGIN_NAME_PLACEHOLDER
description: Use when [describe specific triggering conditions here]
---

# PLUGIN_NAME_PLACEHOLDER

## Overview

Brief description of what this skill enables.

## When to Use

- Condition 1
- Condition 2

## Workflow

Describe the core workflow here.

## Additional Resources

### Reference Files
- **`references/guide.md`** - Detailed documentation
SKILLMD
    # Replace placeholder
    sed -i "s/PLUGIN_NAME_PLACEHOLDER/$PLUGIN_NAME/g" "$SKILL_DIR/SKILL.md"
    echo "  Created skills/$PLUGIN_NAME/SKILL.md"
fi

# Commands
if $WITH_COMMANDS; then
    mkdir -p "$PLUGIN_DIR/commands"
    cat > "$PLUGIN_DIR/commands/$PLUGIN_NAME.md" << 'CMDMD'
---
description: Brief description of what this command does
argument-hint: Optional argument description
allowed-tools: ["Read", "Write", "Bash", "Skill"]
---

# Command Name

Handle the user's request: $ARGUMENTS
CMDMD
    echo "  Created commands/$PLUGIN_NAME.md"
fi

# Hooks
if $WITH_HOOKS; then
    mkdir -p "$PLUGIN_DIR/hooks"
    cat > "$PLUGIN_DIR/hooks/hooks.json" << 'HOOKSJSON'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Plugin loaded'",
            "async": true
          }
        ]
      }
    ]
  }
}
HOOKSJSON
    echo "  Created hooks/hooks.json"
fi

# Agents
if $WITH_AGENTS; then
    mkdir -p "$PLUGIN_DIR/agents"
    cat > "$PLUGIN_DIR/agents/$PLUGIN_NAME.md" << AGENTMD
---
description: When to launch this agent (triggering conditions)
allowed-tools: ["Read", "Grep", "Glob", "Bash"]
---

# $PLUGIN_NAME Agent

System prompt for the specialized subagent.

## Instructions

Describe what this agent should do and how it should behave.
AGENTMD
    echo "  Created agents/$PLUGIN_NAME.md"
fi

# MCP
if $WITH_MCP; then
    cat > "$PLUGIN_DIR/.mcp.json" << 'MCPJSON'
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-server/index.js"],
      "env": {}
    }
  }
}
MCPJSON
    echo "  Created .mcp.json"
fi

# README
cat > "$PLUGIN_DIR/README.md" << README
# $PLUGIN_NAME

$DESCRIPTION

## Installation

\`\`\`bash
claude /plugin  # Search for "$PLUGIN_NAME"
\`\`\`

## Features

- TODO: List plugin features

## License

MIT
README

echo ""
echo "=== Plugin scaffolded at: $PLUGIN_DIR ==="
echo ""
echo "Components:"
$WITH_SKILLS   && echo "  - skills/$PLUGIN_NAME/SKILL.md"
$WITH_COMMANDS && echo "  - commands/$PLUGIN_NAME.md"
$WITH_HOOKS    && echo "  - hooks/hooks.json"
$WITH_AGENTS   && echo "  - agents/$PLUGIN_NAME.md"
$WITH_MCP      && echo "  - .mcp.json"
echo ""
echo "Next: Edit the generated files, then register in marketplace."
