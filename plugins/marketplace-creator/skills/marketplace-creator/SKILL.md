---
name: marketplace-creator
description: This skill should be used when the user asks about "marketplace", "scaffold plugin", "create plugin", "plugin registry", "marketplace.json", "publish skills", or "manage skills". Make sure to use this skill whenever the user wants to create a skill marketplace repository, scaffold new Claude Code plugins, register plugins in a marketplace, validate plugin structure, manage plugin versions, or organize a collection of Claude Code plugins and skills, even if they just mention creating or publishing a plugin without explicitly saying marketplace.
---

# Marketplace Creator

Create and manage Claude Code plugin marketplaces -- from initializing the repository to scaffolding plugins, registering them in the marketplace registry, and maintaining quality.

## Overview

A **marketplace** is a GitHub repository containing:
1. A `marketplace.json` registry listing all available plugins
2. Optionally, first-party plugin source code in `plugins/`
3. External plugin references (pointing to other GitHub repos)

This skill handles the full lifecycle: create the repo, scaffold plugins, register them, validate quality.

## When to Use

- Creating a new marketplace repository from scratch
- Scaffolding a new Claude Code plugin (with skills, commands, hooks, agents)
- Adding a plugin to an existing marketplace registry
- Auditing/validating marketplace or plugin structure
- Managing plugin versions and metadata
- Registering external plugins from third-party repositories

## Core Workflow

1. **Initialize marketplace repo** -- Create the repository structure with registry and plugin directories
2. **Scaffold new plugin** -- Generate the directory layout and config files for a new plugin
3. **Register in marketplace.json** -- Add the plugin entry to the marketplace registry
4. **Validate structure** -- Run quality checks on all plugins and the registry
5. **Push to GitHub** -- Commit and push the validated marketplace

## 1. Initialize Marketplace Repository

Create a new GitHub repo as a plugin marketplace:

```bash
# Use the init-marketplace-repo.sh script
bash ~/.claude/skills/marketplace-creator/scripts/init-marketplace-repo.sh <repo-name> <github-user>
```

The script creates:
- `.claude-plugin/marketplace.json` -- the registry (see `references/marketplace-schema.md`)
- `plugins/` -- directory for first-party plugins
- `external_plugins/` -- manifests for third-party plugins
- `README.md` -- marketplace documentation
- Initializes git and pushes to GitHub via `gh`

## 2. Scaffold a New Plugin

Generate the full structure for a new Claude Code plugin:

```bash
# Use the scaffold-plugin.sh script
bash ~/.claude/skills/marketplace-creator/scripts/scaffold-plugin.sh <plugin-name> [--with-skills] [--with-commands] [--with-hooks] [--with-agents] [--with-mcp]
```

This generates a complete plugin directory. See `references/plugin-anatomy.md` for the full structural reference.

**Minimum viable plugin:**
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json       # name is the only required field
└── skills/
    └── main-skill/
        └── SKILL.md
```

**Full plugin (all components):**
```
plugin-name/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── skill-name/
│       ├── SKILL.md
│       ├── references/
│       ├── scripts/
│       └── assets/
├── commands/
│   └── command-name.md
├── agents/
│   └── agent-name.md
├── hooks/
│   └── hooks.json
├── .mcp.json              # MCP server config (optional)
├── README.md
└── LICENSE
```

### plugin.json Requirements

```json
{
  "name": "kebab-case-name",
  "description": "50-200 chars for marketplace display",
  "version": "0.1.0",
  "author": { "name": "Author Name", "email": "email@example.com" },
  "repository": "https://github.com/user/repo",
  "license": "MIT",
  "keywords": ["tag1", "tag2"]
}
```

Name must match: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`

### SKILL.md Frontmatter

Only two fields: `name` and `description` (max 1024 chars total).

**Description rules:**
- Describe WHEN to use, not what it does
- Start with "Use when..." for triggering conditions
- Include specific trigger phrases users would say
- Keep under 500 characters
- Never summarize the workflow (Claude shortcuts the description instead of reading the body)

### Hooks Format (plugin-level)

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "pattern",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/script.sh'",
            "async": false
          }
        ]
      }
    ]
  }
}
```

Events: PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop, SessionStart, SessionEnd, PreCompact, Notification.

## 3. Register Plugin in Marketplace

Add a plugin to `marketplace.json`:

**First-party (source in marketplace repo):**
```json
{
  "name": "plugin-name",
  "description": "What this plugin does",
  "category": "development",
  "source": "./plugins/plugin-name"
}
```

**External (separate GitHub repo):**
```json
{
  "name": "plugin-name",
  "description": "What this plugin does",
  "category": "development",
  "source": {
    "source": "url",
    "url": "https://github.com/user/repo.git"
  },
  "homepage": "https://github.com/user/repo"
}
```

**Pin to specific commit:**
```json
{
  "source": {
    "source": "url",
    "url": "https://github.com/user/repo.git",
    "sha": "abc123def456"
  }
}
```

### External Plugin Registration Workflow

To register a third-party plugin hosted in a separate repository:

1. **Verify the external repo** -- Confirm the repository contains a valid `.claude-plugin/plugin.json` with at least a `name` field, and at least one skill with a proper SKILL.md
2. **Create an external manifest** -- Add a JSON file in `external_plugins/<plugin-name>.json` with the plugin metadata and source URL
3. **Add to marketplace.json** -- Insert a registry entry using the URL source format (see above), optionally pinning to a specific commit SHA for stability
4. **Validate accessibility** -- Ensure the GitHub repo is public or that the marketplace consumer has access to clone it
5. **Test installation** -- Clone the external plugin and verify the directory structure matches expectations

## 4. Plugin Quality Validation Checklist

Before pushing, validate every plugin against these criteria:

**Registry-level checks:**
- [ ] `marketplace.json` has valid JSON with `$schema`, `name`, `description`, `owner`, `plugins[]`
- [ ] Every plugin in `plugins[]` has `name`, `description`, `source`
- [ ] First-party plugin paths exist on disk
- [ ] No duplicate plugin names in the registry

**Plugin-level checks:**
- [ ] Valid `plugin.json` with at least `name` field
- [ ] Plugin name follows kebab-case pattern: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`
- [ ] Description is 50-200 characters (informative but concise)
- [ ] Version follows semantic versioning (MAJOR.MINOR.PATCH)

**Skill-level checks:**
- [ ] SKILL.md files have valid YAML frontmatter with `name` and `description`
- [ ] No orphaned directories (skills without SKILL.md)
- [ ] Description follows triggering best practices (starts with "Use when..." or lists trigger phrases)
- [ ] Body content uses imperative form (no second-person pronouns)
- [ ] Reference files mentioned in SKILL.md actually exist

**Hook checks (if present):**
- [ ] `hooks.json` has the outer `{"hooks": {...}}` wrapper
- [ ] Event names are valid (PreToolUse, PostToolUse, etc.)
- [ ] Hook commands use `${CLAUDE_PLUGIN_ROOT}` for portability

## 5. Version Management

Follow semantic versioning for all plugins:

- **MAJOR** (1.0.0 -> 2.0.0): Breaking changes to skill triggers, removed commands, restructured plugin layout
- **MINOR** (1.0.0 -> 1.1.0): New skills, commands, or hooks added; expanded reference material
- **PATCH** (1.0.0 -> 1.0.1): Typo fixes, description tuning, minor content updates

**Version bump workflow:**
1. Update `version` in `.claude-plugin/plugin.json`
2. Update the marketplace entry if the description or category changed
3. For external plugins, update the `sha` in marketplace.json to pin the new version
4. Commit with a message referencing the version: `plugin-name: v1.2.0 - added X skill`

**Tracking versions across the marketplace:**
- Each plugin manages its own version in `plugin.json`
- The marketplace registry does not duplicate version numbers -- it references the plugin source
- For pinned external plugins, the `sha` field serves as the version anchor

## 6. Interactive Web Creator

Open the visual skill/plugin creator in a browser:

```bash
open assets/skill-creator-web.html
# Or: xdg-open, python3 -m http.server, etc.
```

The cyberpunk-themed web UI provides:
- Live plugin configuration (name, description, version, components)
- Skill editor with trigger phrase management
- Real-time structure preview (file tree, SKILL.md, plugin.json)
- Automatic validation with quality scoring (A/B/F grades)
- Copy-to-clipboard for generated output

## Common Marketplace Patterns

**Single-domain marketplace**: All plugins serve one technology stack (e.g., infrastructure tools). Keep categories broad (setup, monitoring, troubleshooting).

**Multi-domain marketplace**: Plugins span different domains (dev tools, infra, AI). Use clear categories and ensure skill descriptions include enough trigger phrases to avoid cross-domain misfires.

**Monorepo marketplace**: All plugins live in `plugins/` within the marketplace repo. Simplifies versioning and CI but increases repo size.

**Hybrid marketplace**: First-party core plugins in `plugins/`, specialized or community plugins as external references. Balances control with extensibility.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Description summarizes workflow | Rewrite to describe ONLY triggering conditions |
| plugin.json `name` has uppercase | Use kebab-case only |
| SKILL.md has extra frontmatter fields | Only `name` and `description` are parsed |
| hooks.json missing wrapper `{"hooks": {...}}` | Plugin hooks need the outer `hooks` key |
| Marketplace source path wrong | Use `./plugins/name` for local, URL object for external |
| Version not updated after changes | Always bump version in plugin.json on meaningful changes |
| External plugin SHA not pinned | Pin to a commit SHA for reproducible installations |

## Additional Resources

- Complete marketplace.json schema: `references/marketplace-schema.md`
- Detailed plugin anatomy and all component specs: `references/plugin-anatomy.md`
- Visual creator tool: `assets/skill-creator-web.html`
- Claude Code plugin documentation: https://docs.anthropic.com/en/docs/claude-code/plugins
