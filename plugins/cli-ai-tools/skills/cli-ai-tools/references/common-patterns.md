# Common Patterns Across CLI AI Coding Tools

Patterns, best practices, and tips that apply across most or all CLI AI coding tools.

---

## 1. API Key Setup

Almost every tool requires an API key from the model provider. The pattern is consistent: export an environment variable.

```bash
# Anthropic (Claude Code, Aider, Goose, OpenCode)
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# OpenAI (Codex CLI, Aider, Goose, OpenCode)
export OPENAI_API_KEY="sk-..."

# Google (Gemini CLI, Aider, Goose)
export GOOGLE_API_KEY="AIza..."
# Or use Google OAuth (Gemini CLI supports `gcloud auth`)

# OpenRouter (Aider, OpenCode — access multiple providers via one key)
export OPENROUTER_API_KEY="sk-or-..."

# GitHub Copilot (Copilot CLI)
gh auth login  # then gh extension install github/gh-copilot

# Sourcegraph (Cody CLI)
export SRC_ACCESS_TOKEN="sgp_..."
export SRC_ENDPOINT="https://sourcegraph.example.com"
```

**Best practice:** Store keys in `~/.bashrc`, `~/.zshrc`, or a dedicated `~/.env` file sourced by your shell. Never commit keys to git.

```bash
# ~/.config/ai-keys.env (chmod 600)
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GOOGLE_API_KEY="AIza..."

# In ~/.bashrc or ~/.zshrc:
source ~/.config/ai-keys.env
```

---

## 2. Project-Level Instructions

Most modern CLI AI tools support a file in your project root that provides context, conventions, and instructions to the AI.

| Tool | File | Format |
|------|------|--------|
| Claude Code | `CLAUDE.md` | Markdown |
| Codex CLI | `AGENTS.md` | Markdown |
| Gemini CLI | `GEMINI.md` | Markdown |
| amp | `AMP.md` | Markdown |
| Aider | `.aider.conf.yml` + `.aider.model.settings.yml` | YAML |
| Goose | `~/.config/goose/config.yaml` | YAML |
| Continue | `.continue/config.json` | JSON |
| OpenCode | `opencode.json` | JSON |

**Universal pattern for instruction files:**
```markdown
# Project Context

## Tech Stack
- Language: Go 1.24
- Framework: framegotui
- Database: memogo (localhost:8081)

## Conventions
- Use kebab-case for file names
- Write tests for all public functions
- Commit messages: conventional commits format

## Architecture
- cmd/ — entry points
- pkg/ — library code
- internal/ — private packages

## Do NOT
- Modify generated files in gen/
- Change the CI pipeline without approval
```

---

## 3. Model Selection

Tools that support multiple models generally follow the same patterns:

**Via CLI flag:**
```bash
claude --model claude-sonnet-4-20250514
codex --model o4-mini
gemini --model gemini-2.5-pro
aider --model claude-3.5-sonnet
```

**Via environment variable:**
```bash
export CLAUDE_MODEL=claude-sonnet-4-20250514
export CODEX_MODEL=codex-mini-latest
export GEMINI_MODEL=gemini-2.5-pro
export AIDER_MODEL=claude-3.5-sonnet
```

**Via config file:**
```yaml
# .aider.conf.yml
model: claude-3.5-sonnet
editor-model: claude-3-haiku

# opencode.json
{ "model": "claude-3.5-sonnet", "provider": "anthropic" }
```

**Multi-model strategy (Aider architect mode):**
```bash
# Use a powerful model for planning, cheaper one for editing
aider --architect --model claude-3.5-sonnet --editor-model claude-3-haiku
```

---

## 4. Git Integration

### Auto-commit patterns

```bash
# Aider: auto-commits by default, disable with:
aider --no-auto-commits

# Claude Code: manual commit workflow
claude -p "commit these changes with a good message"

# Most tools: integrate with standard git
git add -A && git commit -m "message"
```

### Working with branches

```bash
# Create a feature branch before starting AI work
git checkout -b feature/ai-refactor

# Run your AI tool
claude "refactor the auth module"
# or
aider --model claude-3.5-sonnet auth.py

# Review changes
git diff
git log --oneline

# Merge when satisfied
git checkout main && git merge feature/ai-refactor
```

### Undoing AI changes

```bash
# Aider: built-in undo
/undo

# Claude Code: use git
git checkout -- .          # discard unstaged
git reset --hard HEAD~1    # undo last commit

# General: always work on a branch so main is safe
```

---

## 5. Working with Different Languages

CLI AI tools are generally language-agnostic, but some tips help:

**Adding context for the AI:**
```bash
# Claude Code: reads the whole repo automatically
claude "add error handling to all Go functions"

# Aider: explicitly add files to context
aider src/main.py src/utils.py src/models.py
/add tests/test_main.py

# Codex: reads repo, point to specific areas in prompt
codex "look at src/auth/ and add JWT validation"
```

**Language-specific tips:**

| Language | Tip |
|----------|-----|
| Python | Include `requirements.txt` or `pyproject.toml` in context |
| Go | The AI can read `go.mod` for dependency context |
| JavaScript/TypeScript | Include `package.json` and `tsconfig.json` |
| Rust | Include `Cargo.toml` |
| Java | Include `pom.xml` or `build.gradle` |

---

## 6. Piping and Scripting

Most tools support non-interactive modes for scripting:

```bash
# Claude Code print mode
claude -p "generate a Dockerfile for this project" > Dockerfile

# Pipe input to AI
cat error.log | claude -p "explain these errors"

# Chain with other tools
git diff | claude -p "review this diff for bugs"
find . -name "*.go" -exec grep -l "TODO" {} \; | claude -p "list all TODOs"

# Codex non-interactive
codex -p "write unit tests for utils.py"

# Aider message mode (non-interactive)
aider --message "add type hints to all functions" --yes src/*.py
```

---

## 7. Using with MCP (Model Context Protocol)

MCP allows AI tools to connect to external data sources and tools.

**Claude Code MCP setup:**
```json
// .claude/mcp.json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-filesystem", "/path/to/dir"]
    },
    "database": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-postgres", "postgresql://..."]
    }
  }
}
```

**Gemini CLI MCP setup:**
```json
// .gemini/mcp.json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["path/to/server.js"]
    }
  }
}
```

---

## 8. Performance and Cost Tips

### Reduce token usage
- Use context compaction (`/compact` in Claude Code)
- Add only relevant files to context (Aider: `/add` selectively)
- Use smaller models for simple tasks
- Use print mode (`-p`) for one-shot questions

### Model selection strategy
| Task | Recommended Approach |
|------|---------------------|
| Simple edits, formatting | Smaller/cheaper model (Haiku, Flash, GPT-4o-mini) |
| Complex refactoring | Larger model (Sonnet, Gemini Pro, GPT-4o) |
| Architecture planning | Most capable model (Opus, o3, Gemini 2.5 Pro) |
| Test generation | Mid-tier model with good instruction following |
| Code review | Any model, focus on clear prompts |

### Context management
```bash
# Claude Code: compact when context gets large
/compact

# Aider: use repo map with token budget
aider --map-tokens 2048

# General: start fresh sessions for unrelated tasks
# Don't reuse a session about auth to work on database code
```

---

## 9. Troubleshooting Common Issues

| Issue | Solution |
|-------|----------|
| "API key not found" | Check env var is exported, not just set. Use `echo $ANTHROPIC_API_KEY` to verify |
| "Model not found" | Check exact model name. Models get renamed/deprecated. Check provider docs |
| "Rate limited" | Wait and retry. Consider using a different model or provider |
| "Context too long" | Compact conversation, remove unnecessary files, start fresh session |
| Tool hangs on startup | Check network connectivity, API endpoint, proxy settings |
| "Permission denied" on tool use | Check tool permissions in config (Claude Code: `/permissions`) |
| Git conflicts after AI edits | Always work on a branch. Use `git stash` before AI sessions |
| Inconsistent output | Set temperature to 0 if available, use deterministic mode |

### Debug modes
```bash
# Claude Code
claude --verbose

# Gemini CLI
gemini --debug

# Aider
aider --verbose

# Goose
RUST_LOG=debug goose session

# General: check tool version
claude --version
codex --version
aider --version
```

---

## 10. Tool Chaining and Workflows

### Multi-tool development workflow
```bash
# 1. Plan with Claude Code (best at architecture)
claude "design the API for a user management service"

# 2. Generate code with Aider (best at focused file edits)
aider --model claude-3.5-sonnet api/users.go api/users_test.go

# 3. Get command suggestions with Copilot CLI
gh copilot suggest "deploy Go service to kubernetes"

# 4. Review with qodo
qodo review api/users.go
```

### CI/CD integration
```bash
# Use print mode in CI pipelines
claude -p "review this PR for security issues" --output-format json

# Aider in CI for auto-fixing
aider --message "fix all linting errors" --yes --no-auto-commits

# Generate commit messages
git diff --staged | claude -p "write a conventional commit message for these changes"
```
