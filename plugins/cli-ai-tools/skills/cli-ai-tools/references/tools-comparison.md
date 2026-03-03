# CLI AI Coding Tools — Detailed Comparison

## Feature Comparison Matrix

| Tool | Provider | Language | License | Models Supported | Key Feature | Config File | Install Method |
|------|----------|----------|---------|------------------|-------------|-------------|----------------|
| Claude Code | Anthropic | TypeScript | Proprietary | Claude 4, Sonnet 4, Haiku | Agentic coding with MCP, plugins, deep codebase understanding | `.claude/settings.json` | `npm i -g @anthropic-ai/claude-code` |
| Codex CLI | OpenAI | TypeScript | Apache 2.0 | Codex Mini, o4-mini, o3 | Sandboxed execution, network-disabled containers | `~/.codex/config.yaml` | `npm i -g @openai/codex` |
| Gemini CLI | Google | TypeScript | Apache 2.0 | Gemini 2.5 Pro, Flash | Free tier with Google account, MCP support | `~/.gemini/settings.json` | `npm i -g @google/gemini-cli` |
| Aider | Open Source | Python | Apache 2.0 | Any (OpenAI, Anthropic, Gemini, Ollama, OpenRouter) | Git-native pair programming, architect mode, repo map | `.aider.conf.yml` | `pip install aider-chat` |
| Goose | Block | Rust | Apache 2.0 | Any (OpenAI, Anthropic, Google, Ollama) | Extension system, session management | `~/.config/goose/config.yaml` | `brew install block/tap/goose` |
| amp | Sourcegraph | TypeScript | Proprietary | Claude, GPT, Gemini | Large codebase indexing, thread conversations | `~/.amp/settings.json` | Download from ampcode.com |
| Copilot CLI | GitHub | Go | Proprietary | GitHub Copilot | Command suggestions and explanations via `gh` | N/A (gh extension) | `gh extension install github/gh-copilot` |
| Cody CLI | Sourcegraph | TypeScript | Apache 2.0 | Multiple (via Sourcegraph) | Codebase search, Sourcegraph integration | `SRC_ACCESS_TOKEN` env | `npm i -g @sourcegraph/cody` |
| OpenCode | Open Source | Go | MIT | Any (OpenAI, Anthropic, Google, Groq, local) | Lightweight TUI, Go-native | `opencode.json` | `go install github.com/opencode-ai/opencode@latest` |
| qodo | Qodo | Python | Proprietary | Multiple | Test generation, code review, quality focus | `.qodo.toml` | `pip install qodo` |
| Jules | Google | N/A | Proprietary | Gemini | Async agent, GitHub integration, auto-PRs | N/A (web-based) | jules.google.com |
| avante.nvim | Open Source | Lua | Apache 2.0 | Any (OpenAI, Anthropic, Ollama, Copilot) | Neovim-native AI, inline editing | Neovim config (`init.lua`) | Neovim plugin manager |

## Capability Comparison

| Capability | Claude Code | Codex CLI | Gemini CLI | Aider | Goose | amp | Copilot CLI |
|------------|:-----------:|:---------:|:----------:|:-----:|:-----:|:---:|:-----------:|
| Interactive REPL | Yes | Yes | Yes | Yes | Yes | Yes | No |
| Non-interactive / Print mode | Yes | Yes | Yes | Yes (message flag) | Yes | Yes | Yes |
| Multi-file editing | Yes | Yes | Yes | Yes | Yes | Yes | No |
| Git integration | Yes | Yes | Yes | Deep | Yes | Yes | No |
| Auto-commit | No (manual) | No | No | Yes (default) | No | No | No |
| MCP support | Yes | No | Yes | No | No | No | No |
| Plugin system | Yes | No | Yes | No | Yes (extensions) | No | No |
| Sandboxed execution | No | Yes | Yes | No | No | No | No |
| Conversation resume | Yes | Yes | Yes | No | Yes | Yes | No |
| Context compaction | Yes | No | No | No | No | No | No |
| Custom instructions file | CLAUDE.md | AGENTS.md | GEMINI.md | .aider.conf.yml | config.yaml | AMP.md | N/A |
| Bash/shell execution | Yes | Yes (sandboxed) | Yes | Yes (/run) | Yes | Yes | Suggest only |
| Image input | Yes | Yes | Yes | Yes | No | Yes | No |
| Web search | Yes | No | Yes | No | Yes | No | No |
| Local/offline models | Via API proxy | No | No | Yes (Ollama) | Yes (Ollama) | No | No |
| Free tier | No | No | Yes | No | No | No | Copilot sub |

## Pricing Model

| Tool | Pricing | Free Tier |
|------|---------|-----------|
| Claude Code | Pay per token (Anthropic API) or Claude Pro/Max subscription | No |
| Codex CLI | Pay per token (OpenAI API) or ChatGPT Pro subscription | No |
| Gemini CLI | Pay per token or free with Google account (rate-limited) | Yes (generous) |
| Aider | Free (bring your own API key) | Tool is free |
| Goose | Free (bring your own API key) | Tool is free |
| amp | Free tier + paid plans | Yes (limited) |
| Copilot CLI | GitHub Copilot subscription ($10-39/mo) | Free for OSS/students |
| Cody CLI | Free tier + Sourcegraph plans | Yes (limited) |
| OpenCode | Free (bring your own API key) | Tool is free |
| qodo | Free tier + paid plans | Yes (limited) |
| Jules | Free (Google account) | Yes |

## Platform Support

| Tool | macOS | Linux | Windows | Docker/Container |
|------|:-----:|:-----:|:-------:|:----------------:|
| Claude Code | Yes | Yes | WSL | Yes |
| Codex CLI | Yes | Yes | WSL | Yes |
| Gemini CLI | Yes | Yes | WSL | Yes |
| Aider | Yes | Yes | Yes | Yes (official image) |
| Goose | Yes | Yes | WSL | Yes |
| amp | Yes | Yes | WSL | N/A |
| Copilot CLI | Yes | Yes | Yes | Yes |
| OpenCode | Yes | Yes | Yes | Yes |

## Architecture Patterns

| Pattern | Tools Using It |
|---------|---------------|
| **Instruction files** (project-level AI context) | Claude Code (CLAUDE.md), Codex (AGENTS.md), Gemini (GEMINI.md), amp (AMP.md) |
| **Architect/Editor split** (separate planning and editing models) | Aider, Claude Code (via prompt) |
| **Sandboxed execution** (isolated from host) | Codex CLI, Gemini CLI |
| **MCP protocol** (tool server integration) | Claude Code, Gemini CLI |
| **Session persistence** (resume conversations) | Claude Code, Codex CLI, Goose, amp |
| **Extension/Plugin system** | Claude Code (plugins), Goose (extensions), Gemini CLI (tools) |
| **Repository map** (AST-based file indexing) | Aider (repo map), Claude Code (codebase search) |
