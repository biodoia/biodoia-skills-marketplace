# Plugin Anatomy — Complete Structural Reference

## Directory Layout

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json              # REQUIRED: plugin manifest
├── skills/                       # Skill directories
│   └── skill-name/
│       ├── SKILL.md             # Required per skill
│       ├── references/          # Detailed docs (loaded on demand)
│       ├── examples/            # Working code examples
│       ├── scripts/             # Executable utilities
│       └── assets/              # Templates, images, fonts
├── commands/                     # Slash command .md files
│   └── command-name.md
├── agents/                       # Agent definition .md files
│   └── agent-name.md
├── hooks/
│   └── hooks.json               # Event hook configuration
├── .mcp.json                     # MCP server config (optional)
├── README.md
└── LICENSE
```

## plugin.json — Full Reference

```json
{
  "name": "my-plugin",
  "description": "50-200 character description for marketplace",
  "version": "0.1.0",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://author.dev"
  },
  "homepage": "https://github.com/user/my-plugin",
  "repository": "https://github.com/user/my-plugin",
  "license": "MIT",
  "keywords": ["skill-tag-1", "skill-tag-2"]
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | YES | kebab-case: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$` |
| `version` | string | no | semver MAJOR.MINOR.PATCH, default "0.1.0" |
| `description` | string | no | 50-200 chars for display |
| `author` | object/string | no | `{name, email?, url?}` or `"Name <email>"` |
| `homepage` | URL | no | Plugin docs/landing page |
| `repository` | URL/object | no | Source code repo |
| `license` | SPDX string | no | e.g. "MIT", "Apache-2.0" |
| `keywords` | string[] | no | 5-10 tags for discovery |
| `commands` | string/array | no | Extra command dirs beyond `./commands/` |
| `agents` | string/array | no | Extra agent dirs beyond `./agents/` |
| `hooks` | string/object | no | Path to hooks.json or inline config |
| `mcpServers` | string/object | no | Path to .mcp.json or inline config |

**Minimal valid plugin.json:** `{ "name": "hello-world" }`

## SKILL.md — Frontmatter

Only two fields are parsed by the core library:

```yaml
---
name: skill-name
description: Use when [specific triggering conditions]
---
```

Optional but recognized:
- `disable-model-invocation: true` — only user can invoke (slash command only)
- `user-invocable: false` — only Claude can invoke (background knowledge)
- `allowed-tools: Read, Grep, Glob` — restrict available tools
- `context: fork` — run in isolated subagent
- `agent: Explore` — which agent type when forked

**Max 1024 characters total for frontmatter.**

### Description Best Practices

**DO:**
- Start with "Use when..."
- List specific triggering conditions and symptoms
- Include phrases users would say in quotes
- Keep under 500 characters

**DON'T:**
- Summarize the workflow (Claude shortcuts descriptions)
- Use first person
- Be vague ("helps with coding")

### SKILL.md Body Best Practices

- Target 1,500-2,000 words (max ~5,000)
- Use imperative form ("Create the file" not "You should create")
- Include a flowchart for non-obvious decision points
- Reference bundled resources explicitly
- One excellent example beats many mediocre ones

## Command Files (.md)

Commands are slash-command entry points. Frontmatter:

```yaml
---
description: What this command does (shown in command list)
argument-hint: Optional description of expected arguments
allowed-tools: ["Read", "Write", "Bash", "Skill"]
model: sonnet
---
```

| Field | Type | Notes |
|-------|------|-------|
| `description` | string | Shown when user types `/` |
| `argument-hint` | string | Hint for expected input |
| `allowed-tools` | string[] | Restrict available tools |
| `model` | string | sonnet/opus/haiku |
| `disable-model-invocation` | bool | Only user can invoke |

Access user input via `$ARGUMENTS` in the body.

## Agent Files (.md)

Agents are specialized subagents. Frontmatter:

```yaml
---
description: When to use this agent (triggering conditions)
allowed-tools: ["Read", "Grep", "Glob", "Bash"]
---
```

The body contains the agent's system prompt — instructions for how the subagent should behave.

## hooks.json — Plugin Format

**Important:** Plugin hooks use a wrapper object different from settings.json:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/my-script.sh'",
            "async": false
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Validate this bash command is safe"
          }
        ]
      }
    ]
  }
}
```

### Hook Events

| Event | When | Use For |
|-------|------|---------|
| SessionStart | Session starts/resumes | Context injection, setup |
| SessionEnd | Session ends | Cleanup |
| PreToolUse | Before tool executes | Validation, blocking |
| PostToolUse | After tool executes | Logging, post-processing |
| UserPromptSubmit | User sends message | Input preprocessing |
| Stop | Agent stops | Final checks |
| SubagentStop | Subagent completes | Result processing |
| PreCompact | Before context compaction | Memory preservation |
| Notification | Background task completes | Alerting |

### Hook Types

**Command hook** (bash script):
```json
{
  "type": "command",
  "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/script.sh'",
  "async": false
}
```

**Prompt hook** (LLM reasoning):
```json
{
  "type": "prompt",
  "prompt": "Evaluate whether this action is safe"
}
```

`${CLAUDE_PLUGIN_ROOT}` expands to the plugin's installed directory.

## .mcp.json — MCP Server Config

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp-server/index.js"],
      "env": {
        "API_KEY": "..."
      }
    }
  }
}
```

Server types: stdio (command+args), SSE (url), HTTP (url).

## Progressive Disclosure Levels

| Level | What | When Loaded | Size Target |
|-------|------|-------------|-------------|
| 1. Metadata | name + description | Always in context | ~100 words |
| 2. SKILL.md body | Core workflow | When skill triggers | <2,000 words |
| 3. References | Detailed docs | On demand | Unlimited |
| 4. Scripts | Executable code | On execution | N/A (not loaded) |
| 5. Assets | Output resources | On use | N/A (not loaded) |

## Auto-Discovery

Claude Code discovers plugin components automatically:
- `skills/*/SKILL.md` — found by recursive scan (maxDepth=3)
- `commands/*.md` — found in commands directory
- `agents/*.md` — found in agents directory
- `hooks/hooks.json` — loaded from hooks config
- `.mcp.json` — loaded at plugin init

Personal skills (`~/.claude/skills/`) override plugin skills with the same name. Use `pluginname:skillname` prefix to force the plugin version.
