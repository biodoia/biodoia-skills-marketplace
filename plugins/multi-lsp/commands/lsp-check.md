---
description: Validate all LSP servers are running correctly for the current project — checks binaries, versions, configurations, and diagnoses issues
allowed-tools: ["Read", "Bash", "Glob", "Grep"]
---

# LSP Check

Validate that all LSP servers required by the current project are installed, configured, and functioning correctly.

## Workflow

### Step 1: Detect the project stack

Scan the current project for language markers to determine which LSP servers should be present. Use the same detection logic as `/lsp-setup`.

### Step 2: Check each required server

For every detected language, run a health check on the corresponding LSP server:

```bash
#!/bin/bash
echo "=== LSP Server Health Check ==="
echo ""

# Go
if [ -f "go.mod" ]; then
    printf "%-30s" "gopls:"
    if command -v gopls &>/dev/null; then
        echo "OK ($(gopls version 2>&1 | head -1))"
    else
        echo "MISSING -- go install golang.org/x/tools/gopls@latest"
    fi
fi

# TypeScript/JavaScript
if [ -f "package.json" ]; then
    printf "%-30s" "typescript-language-server:"
    if command -v typescript-language-server &>/dev/null; then
        echo "OK ($(typescript-language-server --version 2>&1))"
    else
        echo "MISSING -- npm i -g typescript-language-server typescript"
    fi
fi

# Python
if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    printf "%-30s" "pyright:"
    if command -v pyright &>/dev/null; then
        echo "OK ($(pyright --version 2>&1 | head -1))"
    else
        echo "MISSING -- pip install pyright"
    fi
    printf "%-30s" "ruff:"
    if command -v ruff &>/dev/null; then
        echo "OK ($(ruff --version 2>&1))"
    else
        echo "MISSING -- pip install ruff"
    fi
fi

# Rust
if [ -f "Cargo.toml" ]; then
    printf "%-30s" "rust-analyzer:"
    if command -v rust-analyzer &>/dev/null; then
        echo "OK ($(rust-analyzer --version 2>&1))"
    else
        echo "MISSING -- rustup component add rust-analyzer"
    fi
fi

# YAML
if compgen -G "*.yaml" >/dev/null 2>&1 || compgen -G "*.yml" >/dev/null 2>&1; then
    printf "%-30s" "yaml-language-server:"
    if command -v yaml-language-server &>/dev/null; then
        echo "OK ($(yaml-language-server --version 2>&1))"
    else
        echo "MISSING -- npm i -g yaml-language-server"
    fi
fi

# Docker
if [ -f "Dockerfile" ] || [ -f "compose.yaml" ] || [ -f "docker-compose.yml" ]; then
    printf "%-30s" "docker-langserver:"
    if command -v docker-langserver &>/dev/null; then
        echo "OK"
    else
        echo "MISSING -- npm i -g dockerfile-language-server-nodejs"
    fi
fi

# Bash
if compgen -G "*.sh" >/dev/null 2>&1; then
    printf "%-30s" "bash-language-server:"
    if command -v bash-language-server &>/dev/null; then
        echo "OK ($(bash-language-server --version 2>&1))"
    else
        echo "MISSING -- npm i -g bash-language-server"
    fi
fi

# Proto
if compgen -G "*.proto" >/dev/null 2>&1 || [ -f "buf.yaml" ]; then
    printf "%-30s" "buf:"
    if command -v buf &>/dev/null; then
        echo "OK ($(buf --version 2>&1))"
    else
        echo "MISSING -- go install github.com/bufbuild/buf/cmd/buf@latest"
    fi
fi

# SQL
if compgen -G "*.sql" >/dev/null 2>&1; then
    printf "%-30s" "sqls:"
    if command -v sqls &>/dev/null; then
        echo "OK"
    else
        echo "MISSING -- go install github.com/sqls-server/sqls@latest"
    fi
fi

# HTML
if compgen -G "*.html" >/dev/null 2>&1; then
    printf "%-30s" "vscode-html-language-server:"
    if command -v vscode-html-language-server &>/dev/null; then
        echo "OK"
    else
        echo "MISSING -- npm i -g vscode-langservers-extracted"
    fi
fi

# Markdown
if compgen -G "*.md" >/dev/null 2>&1; then
    printf "%-30s" "marksman:"
    if command -v marksman &>/dev/null; then
        echo "OK ($(marksman --version 2>&1 | head -1))"
    else
        echo "MISSING -- install from https://github.com/artempyanykh/marksman/releases"
    fi
fi

echo ""
echo "=== Check Complete ==="
```

### Step 3: Check editor configuration

Look for existing editor LSP configurations:

- `.vscode/settings.json` -- VS Code
- `~/.config/nvim/` -- Neovim
- `~/.config/helix/languages.toml` -- Helix
- `~/.config/zed/settings.json` -- Zed
- `.claude/settings.json` -- Claude Code

Report whether LSP config exists for detected editors and whether it covers all detected languages.

### Step 4: Diagnose common issues

If any server is present but may have issues, check for:

- **PATH issues**: Server binary installed but not in PATH
- **Version conflicts**: Multiple versions of the same server
- **Configuration conflicts**: Conflicting formatter settings (e.g., prettier vs biome)
- **Memory concerns**: Large projects with many servers running
- **Missing dependencies**: LSP server installed but runtime dependency missing (e.g., typescript for typescript-language-server)

### Step 5: Report

Present a formatted summary:

```
=== Multi-LSP Health Report ===

Project: /path/to/project
Detected Stack: Go, Proto, YAML, Docker, Shell, SQL, HTML

| Server                       | Status  | Version    | Notes           |
|------------------------------|---------|------------|-----------------|
| gopls                        | OK      | v0.16.1    |                 |
| buf                          | OK      | 1.30.0     |                 |
| yaml-language-server         | OK      | 1.15.0     |                 |
| docker-langserver            | MISSING |            | npm install     |
| bash-language-server         | OK      | 5.4.0      |                 |
| sqls                         | OK      |            |                 |
| vscode-html-language-server  | MISSING |            | npm install     |

Editor Config: Neovim (found), VS Code (not found)
Issues: 2 servers missing -- run /lsp-setup to install
```

## If the user provided arguments

Interpret `$ARGUMENTS` as:
- A specific server name (e.g., "gopls", "pyright") -- check only that server in detail
- "verbose" -- show full version output and configuration details for each server
- "fix" -- attempt to automatically fix any detected issues

## Reference files

- `skills/multi-lsp/references/server-catalog.md` -- full server details for troubleshooting
- `skills/multi-lsp/references/editor-configs.md` -- expected editor configurations
