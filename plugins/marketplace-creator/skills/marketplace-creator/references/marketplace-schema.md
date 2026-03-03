# Marketplace JSON Schema Reference

## Full marketplace.json Structure

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "marketplace-name",
  "description": "Human-readable description of this marketplace",
  "owner": {
    "name": "Owner Name",
    "email": "owner@example.com"
  },
  "plugins": [
    {
      "name": "plugin-name",
      "description": "What this plugin provides (50-200 chars)",
      "category": "development",
      "source": "./plugins/plugin-name",
      "homepage": "https://github.com/user/plugin-name"
    }
  ]
}
```

## Field Reference

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `$schema` | string | recommended | Schema URL for validation |
| `name` | string | yes | Marketplace identifier (kebab-case) |
| `description` | string | yes | Human-readable description |
| `owner` | object | yes | Marketplace maintainer info |
| `owner.name` | string | yes | Maintainer name |
| `owner.email` | string | recommended | Contact email |
| `plugins` | array | yes | List of available plugins |

### Plugin Entry Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Plugin name (kebab-case, must match plugin.json) |
| `description` | string | yes | 50-200 chars for marketplace display |
| `category` | string | recommended | One of: development, productivity, integration, testing, security, utilities |
| `source` | string or object | yes | Where to find the plugin |
| `homepage` | string | recommended | Plugin documentation URL |

### Source Formats

**Local (first-party):**
```json
"source": "./plugins/plugin-name"
```

**External URL:**
```json
"source": {
  "source": "url",
  "url": "https://github.com/user/repo.git"
}
```

**Pinned commit:**
```json
"source": {
  "source": "url",
  "url": "https://github.com/user/repo.git",
  "sha": "full-commit-sha"
}
```

**GitHub source:**
```json
"source": {
  "source": "github",
  "repo": "user/repo-name"
}
```

## Categories

Recommended categories for organizing plugins:

| Category | Description |
|----------|-------------|
| `development` | Code generation, scaffolding, build tools |
| `productivity` | Workflow automation, task management |
| `integration` | External service connections (Slack, Jira, etc.) |
| `testing` | Test generation, coverage, quality |
| `security` | Security scanning, vulnerability detection |
| `utilities` | General-purpose tools and helpers |
| `documentation` | Documentation generation and management |
| `ai` | AI/ML specific tools and integrations |

## Installation Mechanics

When a user installs from a marketplace:

1. Claude Code reads `marketplace.json` from the marketplace repo
2. User selects a plugin by name
3. If `source` is a local path: copies from marketplace repo
4. If `source` is a URL: clones the git repo at that URL
5. If `sha` is specified: checks out that specific commit
6. Plugin is stored in `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`
7. Entry added to `~/.claude/plugins/installed_plugins.json`

## known_marketplaces.json

Users register marketplaces in `~/.claude/plugins/known_marketplaces.json`:

```json
{
  "marketplace-name": {
    "source": {
      "source": "github",
      "repo": "user/marketplace-repo"
    },
    "installLocation": "/path/to/local/clone",
    "lastUpdated": "2026-01-01T00:00:00.000Z"
  }
}
```

## Validation Rules

1. `name` must be unique across all plugins in the marketplace
2. `name` must match regex: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`
3. `description` should be 50-200 characters
4. `source` paths must resolve to valid plugin directories
5. External URLs must be accessible git repositories
6. Each referenced plugin must have a valid `.claude-plugin/plugin.json`
