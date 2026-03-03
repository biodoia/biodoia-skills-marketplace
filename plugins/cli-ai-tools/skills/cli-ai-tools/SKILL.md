---
name: cli-ai-tools
description: Use when the user needs help with CLI-based AI coding assistants, their commands, flags, configuration, model selection, comparison, installation, or troubleshooting. Also use when the user mentions Claude Code, Codex CLI, Gemini CLI, Aider, Goose, amp, OpenCode, Cody CLI, Copilot CLI, qodo, Jules, Continue, avante, Cline, Roo Code, Cursor CLI, Windsurf, or Trae, or asks about AI coding tools in the terminal.
---

# CLI AI Coding Tools Reference

Comprehensive reference for all major command-line AI coding assistants. This covers installation, key commands, flags, configuration, and model selection for each tool.

## Tool Index

| Tool | Provider | Primary Use |
|------|----------|-------------|
| Claude Code | Anthropic | Agentic coding, full codebase understanding |
| Codex CLI | OpenAI | Agentic coding with sandboxed execution |
| Gemini CLI | Google | Agentic coding with Gemini models |
| Aider | Open Source | AI pair programming, git-integrated |
| Goose | Block | Extensible AI agent with plugins |
| amp | Sourcegraph | AI agent for large codebases |
| Copilot CLI | GitHub | Command-line suggestions and explanations |
| Cody CLI | Sourcegraph | Codebase-aware AI assistant |
| OpenCode | Open Source | Go-based terminal AI coding |
| qodo | Qodo | AI code quality and testing |
| Jules | Google | Async coding agent (GitHub-integrated) |
| Continue | Open Source | AI code assistant (IDE + CLI) |
| avante | Open Source | Neovim AI plugin (CLI-adjacent) |

---

## Anthropic: Claude Code

The CLI agent you are running inside right now. Agentic AI coding with deep codebase understanding, tool use, and MCP integration.

**Install:**
```bash
npm install -g @anthropic-ai/claude-code
```

**Basic usage:**
```bash
claude                          # interactive REPL
claude "explain this codebase"  # start with a prompt
claude -p "what does main do"   # print mode (non-interactive, outputs to stdout)
claude --resume                 # resume last conversation
claude --continue               # continue last conversation with new input
```

**Key flags:**

| Flag | Description |
|------|-------------|
| `--model <model>` | Select model (e.g. `claude-sonnet-4-20250514`) |
| `-p, --print` | Print mode: non-interactive, single response to stdout |
| `--resume` | Resume the most recent conversation |
| `--continue` | Continue last conversation with new input |
| `--dangerously-skip-permissions` | Skip all permission prompts (use with caution) |
| `--allowedTools <tools>` | Comma-separated list of allowed tools |
| `--output-format <fmt>` | Output format: `text`, `json`, `stream-json` |
| `--max-turns <n>` | Limit autonomous turns in non-interactive mode |
| `--verbose` | Enable verbose logging |

**Slash commands (interactive mode):**

| Command | Description |
|---------|-------------|
| `/help` | Show all available commands |
| `/compact` | Compress conversation to save context |
| `/clear` | Clear conversation history |
| `/config` | View/edit configuration |
| `/permissions` | Manage tool permissions |
| `/install-plugin <url>` | Install a plugin from GitHub |
| `/mcp` | Manage MCP server connections |
| `/model` | Switch model mid-conversation |
| `/cost` | Show token usage and cost |
| `/doctor` | Diagnose installation issues |

**Configuration:**
- Project config: `.claude/settings.json` in project root
- User config: `~/.claude/settings.json`
- Memory: `CLAUDE.md` files (project root, `~/.claude/CLAUDE.md`)
- MCP servers: `.claude/mcp.json`

**Environment variables:**
```bash
ANTHROPIC_API_KEY=sk-ant-...        # API key
CLAUDE_MODEL=claude-sonnet-4-20250514  # Default model
ANTHROPIC_BASE_URL=...              # Custom API endpoint
```

---

## OpenAI: Codex CLI

OpenAI's open-source agentic coding CLI. Runs code in a sandboxed environment with network-disabled containers.

**Install:**
```bash
npm install -g @openai/codex
```

**Basic usage:**
```bash
codex                           # interactive mode
codex "refactor the auth module"  # start with prompt
codex --approval-mode full-auto "fix all tests"  # fully autonomous
```

**Key flags:**

| Flag | Description |
|------|-------------|
| `--model <model>` | Select model (default: `codex-mini-latest`) |
| `--approval-mode <mode>` | `suggest` (default), `auto-edit`, `full-auto` |
| `--quiet` | Minimal output |
| `-p, --prompt` | Non-interactive single prompt |

**Approval modes:**
- `suggest` — asks before every action
- `auto-edit` — auto-approves file edits, asks for commands
- `full-auto` — auto-approves everything (sandboxed)

**Configuration:**
- Config file: `~/.codex/config.yaml` or `~/.codex/config.json`
- Instructions: `AGENTS.md` in project root (similar to CLAUDE.md)

**Environment variables:**
```bash
OPENAI_API_KEY=sk-...               # API key
CODEX_MODEL=codex-mini-latest       # Default model
```

---

## Google: Gemini CLI

Google's CLI coding assistant powered by Gemini models. Free tier available with Google account.

**Install:**
```bash
npm install -g @google/gemini-cli
# Or run without installing:
npx @google/gemini-cli
```

**Basic usage:**
```bash
gemini                          # interactive mode
gemini "explain this function"  # start with prompt
gemini -p "summarize README"   # non-interactive print mode
```

**Key flags:**

| Flag | Description |
|------|-------------|
| `--model <model>` | Select model (e.g. `gemini-2.5-pro`) |
| `-p` | Non-interactive print mode |
| `--sandbox` | Run in sandboxed mode |
| `--debug` | Enable debug output |

**Configuration:**
- Config: `~/.gemini/settings.json`
- Memory: `GEMINI.md` in project root
- Supports MCP servers via `.gemini/mcp.json`

**Environment variables:**
```bash
GOOGLE_API_KEY=...                  # API key (or use Google auth)
GEMINI_MODEL=gemini-2.5-pro        # Default model
```

---

## Google: Jules

Google's asynchronous coding agent. Integrates with GitHub — you assign issues and Jules works on them in the background, creating PRs.

**Usage:**
- Accessed via [jules.google.com](https://jules.google.com) or GitHub integration
- Not a traditional CLI tool — operates asynchronously on GitHub repos
- Assign tasks via GitHub issues or the Jules web interface
- Jules creates branches, makes changes, submits PRs

**Key features:**
- Async operation (works while you do other things)
- GitHub-native integration
- Multi-file changes with PR creation
- Powered by Gemini models

---

## Open Source: Aider

The most popular open-source AI pair programming CLI. Deep git integration, multi-model support, architect/editor pattern.

**Install:**
```bash
pip install aider-chat
# Or:
pipx install aider-chat
# Or with uv:
uv tool install aider-chat
```

**Basic usage:**
```bash
aider                               # interactive, auto-detects git repo
aider --model claude-3.5-sonnet     # specify model
aider file1.py file2.py             # add files to context
aider --architect                   # architect mode (plan then edit)
```

**Key slash commands (interactive):**

| Command | Description |
|---------|-------------|
| `/add <file>` | Add file(s) to the chat context |
| `/drop <file>` | Remove file(s) from context |
| `/run <cmd>` | Run a shell command and share output |
| `/diff` | Show pending diffs |
| `/commit` | Commit changes with AI-generated message |
| `/undo` | Undo the last change |
| `/model <name>` | Switch model |
| `/architect` | Toggle architect mode |
| `/ask` | Ask without editing (question-only mode) |
| `/lint` | Lint changed files |
| `/test` | Run tests |
| `/tokens` | Show token usage |
| `/clear` | Clear chat history |
| `/exit` | Exit aider |

**Key flags:**

| Flag | Description |
|------|-------------|
| `--model <model>` | Main model for editing |
| `--architect` | Use architect mode (separate planning model) |
| `--editor-model <model>` | Model for code edits (in architect mode) |
| `--auto-commits` | Auto-commit after each change (default: on) |
| `--no-auto-commits` | Disable auto-commits |
| `--watch-files` | Watch files for changes and auto-add |
| `--dark-mode` | Dark terminal theme |
| `--no-git` | Disable git integration |
| `--yes` | Auto-confirm prompts |
| `--map-tokens <n>` | Tokens for repo map (0 to disable) |
| `--edit-format <fmt>` | `whole`, `diff`, `udiff`, `diff-fenced` |

**Configuration:**
- Config file: `.aider.conf.yml` (project root or `~/.aider.conf.yml`)
- Environment: `.env` file in project root
- Model aliases: `.aider.model.settings.yml`

**Environment variables:**
```bash
ANTHROPIC_API_KEY=sk-ant-...        # For Claude models
OPENAI_API_KEY=sk-...               # For OpenAI models
GEMINI_API_KEY=...                  # For Gemini models
OPENROUTER_API_KEY=...              # For OpenRouter
AIDER_MODEL=claude-3.5-sonnet      # Default model
```

---

## Block: Goose

Block's open-source AI agent CLI. Extensible with a plugin system called "extensions" (formerly "toolkits").

**Install:**
```bash
# macOS
brew install block/tap/goose

# Or from source
cargo install goose-cli

# Or via installer script
curl -fsSL https://github.com/block/goose/releases/latest/download/install.sh | bash
```

**Basic usage:**
```bash
goose session             # start interactive session
goose session -r          # resume last session
goose run "fix tests"     # run with a prompt
goose configure           # configure settings
```

**Key commands:**

| Command | Description |
|---------|-------------|
| `goose session` | Start a new session |
| `goose session -r` | Resume last session |
| `goose run <prompt>` | Run a single task |
| `goose configure` | Interactive configuration |
| `goose info` | Show current configuration |

**Configuration:**
- Config file: `~/.config/goose/config.yaml`
- Supports multiple providers: OpenAI, Anthropic, Google, Ollama, local models
- Extensions (plugins) for additional capabilities

---

## Sourcegraph: amp

Sourcegraph's AI coding agent for the terminal. Designed for large codebase understanding.

**Install:**
```bash
# Download from https://ampcode.com
# Or via npm (check current package name):
npm install -g @anthropic-ai/amp
```

**Basic usage:**
```bash
amp                         # interactive mode
amp "explain the auth flow" # start with prompt
amp --continue              # continue last conversation
```

**Key features:**
- Thread-based conversations (similar to Claude Code)
- Codebase indexing and search
- Multi-file editing
- Git-aware operations

**Configuration:**
- Config: `~/.amp/settings.json`
- Memory: `AMP.md` in project root

---

## GitHub: Copilot CLI

GitHub Copilot's CLI integration. Provides command suggestions and explanations via the `gh` CLI extension.

**Install:**
```bash
gh extension install github/gh-copilot
```

**Key commands:**

| Command | Description |
|---------|-------------|
| `gh copilot suggest "find large files"` | Get command suggestions |
| `gh copilot explain "tar -xzf file.tar.gz"` | Explain a command |

**Flags:**

| Flag | Description |
|------|-------------|
| `-t shell` | Target: generic shell command |
| `-t git` | Target: git command |
| `-t gh` | Target: GitHub CLI command |

**Examples:**
```bash
gh copilot suggest -t git "squash last 3 commits"
gh copilot explain "find . -name '*.log' -mtime +30 -delete"
gh copilot suggest -t shell "monitor CPU usage"
```

---

## Sourcegraph: Cody CLI

Sourcegraph's AI coding assistant with CLI capabilities. Strong at codebase search and understanding.

**Install:**
```bash
npm install -g @sourcegraph/cody
```

**Basic usage:**
```bash
cody chat "explain this repo"    # ask questions
cody auth login                  # authenticate
cody auth status                 # check auth
```

**Configuration:**
- Auth: Sourcegraph access token or `SRC_ACCESS_TOKEN` env var
- Endpoint: `SRC_ENDPOINT` for self-hosted Sourcegraph

---

## Open Source: OpenCode

Go-based AI coding assistant for the terminal. Lightweight TUI with multi-provider support.

**Install:**
```bash
go install github.com/opencode-ai/opencode@latest
# Or download binary from releases
```

**Basic usage:**
```bash
opencode                        # launch TUI
```

**Configuration:**
- Config file: `opencode.json` in project root
- Supports: OpenAI, Anthropic, Google, Groq, local models
- Provider-specific API keys via environment variables

---

## Qodo: qodo

AI-powered code quality and test generation tool.

**Install:**
```bash
pip install qodo
# Or:
npm install -g qodo
```

**Key commands:**
```bash
qodo test <file>                # generate tests
qodo review <file>              # code review
qodo improve <file>             # suggest improvements
```

---

## Neovim: avante.nvim

AI-powered Neovim plugin. CLI-adjacent — operates within Neovim's terminal-based interface.

**Install:**
Add to Neovim plugin manager (lazy.nvim, packer, etc.):
```lua
{ "yetone/avante.nvim", build = "make" }
```

**Key bindings (in Neovim):**
- `<leader>aa` — Open Avante chat
- `<leader>ae` — Edit selected code with AI
- `<leader>ar` — Refresh AI response

**Configuration:**
- In Neovim config (`init.lua`)
- Supports: OpenAI, Anthropic, Azure, Ollama, Copilot

---

## Other CLI-Adjacent Tools

### Cline / Roo Code
Primarily VS Code extensions. Cline has been forked as Roo Code. No standalone CLI binary, but operates through VS Code's terminal integration. Can be used via the VS Code CLI `code` command with extensions.

### Cursor CLI
Cursor is an IDE (VS Code fork). No standalone CLI agent, but Cursor settings can be accessed via the `cursor` command to open the editor from terminal.

### Windsurf
Windsurf (by Codeium) is an IDE. No standalone CLI agent. Use the `windsurf` command to open the editor from terminal.

### Trae
Trae (by ByteDance) is an IDE. No standalone CLI agent. Has a `trae` command to open the editor.

### Continue
Continue is primarily a VS Code / JetBrains extension. Offers a local server mode and config-based setup, but no dedicated CLI agent binary.
- Config: `~/.continue/config.json`
- Supports: All major model providers

---

## Quick Model Selection Reference

| Tool | Flag/Config | Example |
|------|-------------|---------|
| Claude Code | `--model` | `claude --model claude-sonnet-4-20250514` |
| Codex CLI | `--model` | `codex --model o4-mini` |
| Gemini CLI | `--model` | `gemini --model gemini-2.5-pro` |
| Aider | `--model` | `aider --model claude-3.5-sonnet` |
| Goose | config file | `goose configure` then select provider/model |
| Copilot CLI | N/A | Uses GitHub Copilot model |
| OpenCode | config file | Set in `opencode.json` |

---

## Progressive Disclosure

- For a detailed feature comparison table: read `references/tools-comparison.md`
- For common patterns across all CLI AI tools: read `references/common-patterns.md`
