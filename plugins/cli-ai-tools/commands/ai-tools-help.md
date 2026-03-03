---
description: Quick reference for any CLI AI coding tool — usage, commands, flags, and configuration
allowed-tools: ["Read"]
---

# AI Tools Help

Provide quick reference information for CLI AI coding tools.

## Steps

1. Determine which tool the user is asking about. If no specific tool is mentioned, provide a summary of all available tools.

2. Read the main skill file for comprehensive information:
   ```
   Read: skills/cli-ai-tools/SKILL.md
   ```

3. If the user wants a comparison between tools:
   ```
   Read: skills/cli-ai-tools/references/tools-comparison.md
   ```

4. If the user wants general patterns and best practices:
   ```
   Read: skills/cli-ai-tools/references/common-patterns.md
   ```

## Quick Reference

### Most Common Tools

| Tool | Start Command | Get Help |
|------|--------------|----------|
| Claude Code | `claude` | `claude --help` or `/help` |
| Codex CLI | `codex` | `codex --help` |
| Gemini CLI | `gemini` | `gemini --help` |
| Aider | `aider` | `aider --help` or `/help` |
| Goose | `goose session` | `goose --help` |
| Copilot CLI | `gh copilot suggest` | `gh copilot --help` |

### Install Any Tool

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# Codex CLI
npm install -g @openai/codex

# Gemini CLI
npm install -g @google/gemini-cli

# Aider
pip install aider-chat

# Goose
brew install block/tap/goose

# Copilot CLI
gh extension install github/gh-copilot

# OpenCode
go install github.com/opencode-ai/opencode@latest
```

## Output Format

Present the information as:
1. **Tool name and provider**
2. **Installation** (one-liner)
3. **Basic usage** (2-3 examples)
4. **Key commands/flags** (table)
5. **Configuration** (config file location and key env vars)
6. **Model selection** (if applicable)

Keep it concise and practical. Focus on the commands the user will actually type.
