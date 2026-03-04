---
description: Full LSP detection, installation, and configuration workflow — detects project tech stack, installs missing LSP servers, generates editor config
allowed-tools: ["Read", "Bash", "Write", "Edit", "Glob", "Grep"]
---

# LSP Setup

Run the full multi-LSP detection, installation, and configuration workflow for the current project.

## Workflow

### Step 1: Detect the tech stack

Run the detection script to identify all languages and frameworks in the project:

```bash
bash skills/multi-lsp/scripts/detect-stack.sh
```

If the script is not available at that path, perform manual detection by scanning for these markers in the project root and subdirectories:

- `go.mod` -- Go (gopls)
- `package.json` -- JavaScript/TypeScript (typescript-language-server)
- `tsconfig.json` -- TypeScript specifically
- `Cargo.toml` -- Rust (rust-analyzer)
- `pyproject.toml` / `setup.py` / `requirements.txt` -- Python (pyright, ruff)
- `*.proto` / `buf.yaml` -- Protocol Buffers (buf, pbls)
- `Dockerfile` / `compose.yaml` / `docker-compose.yml` -- Docker (docker-langserver)
- `*.yaml` / `*.yml` -- YAML (yaml-language-server)
- `*.sql` -- SQL (sqls)
- `*.html` / `*.css` -- HTML/CSS (vscode-html-language-server, vscode-css-language-server)
- `*.sh` / `*.bash` -- Shell (bash-language-server)
- `*.lua` -- Lua (lua-language-server)
- `*.toml` -- TOML (taplo)
- `*.md` -- Markdown (marksman)
- `*.tf` -- Terraform (terraform-ls)
- `*.graphql` -- GraphQL (graphql-lsp)
- `*.zig` -- Zig (zls)
- `*.nix` -- Nix (nil, nixd)
- `.github/workflows/*.yml` -- GitHub Actions (actionlint)
- `.eslintrc*` / `eslint.config.*` -- ESLint (eslint-lsp)
- `.prettierrc*` -- Prettier
- `biome.json` -- Biome (biome)
- `deno.json` -- Deno (deno lsp)
- `tailwind.config.*` -- Tailwind CSS (tailwindcss-language-server)

Also detect framework-specific needs:
- framegotui projects -- gopls + templ + html/css LSP
- Next.js projects -- typescript + tailwind + eslint
- gRPC projects -- gopls + buf + proto LSP
- HTMX projects -- html LSP with HTMX completions

### Step 2: Check installed servers

For each detected language, check if the corresponding LSP server binary is available:

```bash
command -v gopls typescript-language-server pyright rust-analyzer 2>/dev/null
```

### Step 3: Install missing servers

Read `skills/multi-lsp/references/server-catalog.md` for full installation instructions per server.

Detect the OS and use the appropriate package manager:
- **Arch/Manjaro**: `pacman -S` or `yay -S`
- **macOS**: `brew install`
- **Ubuntu/Debian**: `apt install` or npm/pip/go install

For each missing server, present the install command and ask for confirmation before proceeding.

### Step 4: Generate editor configuration

Ask the user which editor they use, then read `skills/multi-lsp/references/editor-configs.md` and generate the appropriate configuration file.

Read `skills/multi-lsp/references/stack-presets.md` if the detected stack matches a known preset.

**Editor targets:**
- **Neovim**: Generate `lua` config for nvim-lspconfig
- **VS Code**: Generate `.vscode/settings.json` entries
- **Helix**: Generate `languages.toml` entries
- **Zed**: Generate `settings.json` LSP entries
- **Claude Code**: Generate `.claude/settings.json` LSP entries
- **Emacs**: Generate `init.el` lsp-mode or eglot config

### Step 5: Validate

For each installed server, verify it starts correctly:

```bash
# Test each server with a version/help check
gopls version 2>/dev/null
typescript-language-server --version 2>/dev/null
pyright --version 2>/dev/null
```

Report results as a summary table.

## If the user provided arguments

Interpret `$ARGUMENTS` as:
- An editor name (e.g., "neovim", "vscode", "helix") -- skip detection, generate config for that editor only
- A preset name (e.g., "go-full-stack", "node-full-stack") -- use that preset instead of auto-detection
- "install-only" -- detect and install, skip config generation
- "detect-only" -- detect only, skip installation and config

## Reference files

- `skills/multi-lsp/references/server-catalog.md` -- full server details and install commands
- `skills/multi-lsp/references/editor-configs.md` -- complete editor configuration templates
- `skills/multi-lsp/references/stack-presets.md` -- pre-built configurations for common stacks
- `skills/multi-lsp/scripts/detect-stack.sh` -- automated stack detection script
- `skills/multi-lsp/scripts/install-lsp.sh` -- automated installation script
