# Stack Presets

Pre-built LSP configurations for common project types. Each preset lists the servers to install, the rationale for each, and example editor configurations.

Use these presets directly with the install script:

```bash
./scripts/install-lsp.sh --preset go-full-stack
./scripts/install-lsp.sh --preset biodoia-ecosystem
```

---

## Go Full Stack

**Target**: Go backend with web frontend, database, and infrastructure.

**Typical project**: Go HTTP/gRPC server + HTML templates + SQL migrations + Protocol Buffers + Docker + YAML config + shell scripts.

### Servers

| Server | Language | Rationale |
|--------|----------|-----------|
| gopls | Go | Core Go language intelligence |
| templ | Go templ | Go HTML template files (if using templ) |
| vscode-html-language-server | HTML | HTML template completion and diagnostics |
| vscode-css-language-server | CSS | CSS/SCSS styling support |
| yaml-language-server | YAML | Config files, docker-compose, CI/CD |
| docker-langserver | Docker | Dockerfile syntax and best practices |
| sqls | SQL | SQL migration and query files |
| bash-language-server | Shell | Build scripts, CI scripts |
| buf | Proto | Protocol Buffer linting and formatting |
| marksman | Markdown | README, docs, ADRs |
| vscode-json-language-server | JSON | package.json, config files |

### Install

```bash
# All at once
go install golang.org/x/tools/gopls@latest
go install github.com/a-h/templ/cmd/templ@latest
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/sqls-server/sqls@latest
npm i -g vscode-langservers-extracted yaml-language-server dockerfile-language-server-nodejs bash-language-server
# marksman: download binary from GitHub releases
```

### Neovim Config

```lua
local servers = {
  'gopls', 'templ', 'html', 'cssls', 'yamlls', 'jsonls',
  'dockerls', 'sqls', 'bashls', 'marksman', 'bufls',
}
for _, server in ipairs(servers) do
  require('lspconfig')[server].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

-- gopls with full settings
require('lspconfig').gopls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    gopls = {
      staticcheck = true,
      gofumpt = true,
      usePlaceholders = true,
      completeUnimported = true,
      analyses = { unusedparams = true, shadow = true, nilness = true },
      hints = { parameterNames = true, assignVariableTypes = true },
      codelenses = { test = true, tidy = true, gc_details = true },
    },
  },
})
```

---

## Node.js Full Stack

**Target**: Node.js/TypeScript frontend and backend with modern tooling.

**Typical project**: Next.js/React/Vue + TypeScript + Tailwind CSS + REST/GraphQL API + Docker.

### Servers

| Server | Language | Rationale |
|--------|----------|-----------|
| typescript-language-server | TypeScript/JS | Core TS/JS intelligence |
| tailwindcss-language-server | Tailwind CSS | Tailwind class completion |
| vscode-html-language-server | HTML | HTML/JSX template support |
| vscode-css-language-server | CSS | CSS/SCSS/Less support |
| vscode-json-language-server | JSON | package.json, tsconfig, configs |
| yaml-language-server | YAML | docker-compose, CI/CD configs |
| docker-langserver | Docker | Dockerfile support |
| bash-language-server | Shell | npm scripts, CI scripts |
| marksman | Markdown | Documentation |

**Alternative**: If the project uses `biome.json`, replace eslint + prettier with biome:

| Server | Language | Rationale |
|--------|----------|-----------|
| biome | JS/TS/JSON/CSS | Unified linting and formatting |

**Alternative**: If the project uses `deno.json`, replace typescript-language-server with deno:

| Server | Language | Rationale |
|--------|----------|-----------|
| deno | TypeScript/JS | Deno built-in LSP |

### Install

```bash
npm i -g typescript-language-server typescript \
  @tailwindcss/language-server \
  vscode-langservers-extracted \
  yaml-language-server \
  dockerfile-language-server-nodejs \
  bash-language-server
```

### Neovim Config

```lua
require('lspconfig').ts_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayVariableTypeHints = true,
      },
    },
  },
})

require('lspconfig').tailwindcss.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

require('lspconfig').html.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').cssls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').jsonls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').yamlls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').dockerls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').bashls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').marksman.setup({ capabilities = capabilities, on_attach = on_attach })
```

---

## Rust Full Stack

**Target**: Rust backend with database, config, and infrastructure.

**Typical project**: Rust HTTP server (actix/axum) + SQL database + TOML config + Docker + CI/CD.

### Servers

| Server | Language | Rationale |
|--------|----------|-----------|
| rust-analyzer | Rust | Core Rust intelligence |
| taplo | TOML | Cargo.toml, config files |
| yaml-language-server | YAML | CI/CD configs, docker-compose |
| docker-langserver | Docker | Dockerfile support |
| sqls | SQL | SQL migration files |
| bash-language-server | Shell | Build scripts |
| marksman | Markdown | Documentation |
| vscode-json-language-server | JSON | Config files |

### Install

```bash
rustup component add rust-analyzer
cargo install taplo-cli --locked
go install github.com/sqls-server/sqls@latest
npm i -g vscode-langservers-extracted yaml-language-server \
  dockerfile-language-server-nodejs bash-language-server
```

### Neovim Config

```lua
require('lspconfig').rust_analyzer.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    ['rust-analyzer'] = {
      check = { command = "clippy" },
      cargo = { features = "all" },
      procMacro = { enable = true },
      inlayHints = {
        typeHints = { enable = true },
        parameterHints = { enable = true },
        chainingHints = { enable = true },
      },
      lens = {
        enable = true,
        references = { adt = { enable = true }, method = { enable = true } },
        run = { enable = true },
      },
    },
  },
})

require('lspconfig').taplo.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').yamlls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').dockerls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').sqls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').bashls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').marksman.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').jsonls.setup({ capabilities = capabilities, on_attach = on_attach })
```

---

## Python Full Stack

**Target**: Python backend with modern tooling.

**Typical project**: FastAPI/Django + SQLAlchemy + Docker + YAML config.

### Servers

| Server | Language | Rationale |
|--------|----------|-----------|
| pyright | Python | Type checking, completion, diagnostics |
| ruff | Python | Fast linting and formatting (replaces flake8+black+isort) |
| yaml-language-server | YAML | Config files, docker-compose |
| docker-langserver | Docker | Dockerfile support |
| sqls | SQL | SQL files |
| bash-language-server | Shell | Scripts |
| vscode-json-language-server | JSON | Config files |
| marksman | Markdown | Documentation |

### Install

```bash
pip install pyright ruff
go install github.com/sqls-server/sqls@latest
npm i -g vscode-langservers-extracted yaml-language-server \
  dockerfile-language-server-nodejs bash-language-server
```

### Neovim Config

```lua
require('lspconfig').pyright.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

-- ruff as a secondary LSP (linting + formatting only, no completion)
require('lspconfig').ruff.setup({
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- Disable hover (pyright handles it)
    client.server_capabilities.hoverProvider = false
    on_attach(client, bufnr)
  end,
})

require('lspconfig').yamlls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').dockerls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').sqls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').bashls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').jsonls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').marksman.setup({ capabilities = capabilities, on_attach = on_attach })
```

---

## DevOps

**Target**: Infrastructure, CI/CD, and platform engineering.

**Typical project**: Terraform + Kubernetes YAML + Docker + shell scripts + GitHub Actions.

### Servers

| Server | Language | Rationale |
|--------|----------|-----------|
| terraform-ls | Terraform/HCL | Terraform provider schemas, completion |
| yaml-language-server | YAML | Kubernetes, Helm, CI/CD configs |
| docker-langserver | Docker | Dockerfile support |
| bash-language-server | Shell | Automation scripts |
| vscode-json-language-server | JSON | Config files, AWS/GCP configs |
| taplo | TOML | Config files |
| actionlint | GitHub Actions | Workflow linting (via efm-langserver) |
| marksman | Markdown | Runbooks, documentation |

### Install

```bash
# Terraform-ls: varies by OS
# Arch: yay -S terraform-ls
# macOS: brew install hashicorp/tap/terraform-ls

go install github.com/rhysd/actionlint/cmd/actionlint@latest
go install github.com/mattn/efm-langserver@latest
cargo install taplo-cli --locked
npm i -g yaml-language-server vscode-langservers-extracted \
  dockerfile-language-server-nodejs bash-language-server
```

### Neovim Config

```lua
require('lspconfig').terraformls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').yamlls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://json.schemastore.org/docker-compose.json"] = "/docker-compose*.yml",
        ["https://json.schemastore.org/chart.json"] = "/Chart.yaml",
        ["https://json.schemastore.org/kustomization.json"] = "/kustomization.yaml",
        ["kubernetes"] = "/*.k8s.yaml",
      },
    },
  },
})
require('lspconfig').dockerls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').bashls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').jsonls.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').taplo.setup({ capabilities = capabilities, on_attach = on_attach })
require('lspconfig').marksman.setup({ capabilities = capabilities, on_attach = on_attach })

-- efm for actionlint
require('lspconfig').efm.setup({
  capabilities = capabilities,
  init_options = { documentFormatting = false },
  filetypes = { "yaml" },
  settings = {
    languages = {
      yaml = {
        {
          lintCommand = "actionlint -stdin-filename ${INPUT} -",
          lintStdin = true,
          lintFormats = { "%f:%l:%c: %m" },
          rootMarkers = { ".github/" },
        },
      },
    },
  },
})
```

---

## biodoia Ecosystem

**Target**: The biodoia project stack -- Go projects built with framegotui, using memogo, gRPC, HTMX, and the full biodoia toolchain.

**Typical project**: framegotui-based TUI+WebUI application with gRPC backend, memogo integration, HTMX web interface, SQL storage, and Docker deployment.

### Servers

| Server | Language | Rationale |
|--------|----------|-----------|
| gopls | Go | Core Go intelligence for framegotui, memogo, and all Go projects |
| templ | Go templ | `.templ` files for HTMX-based WebUI (framegotui pkg/web) |
| vscode-html-language-server | HTML | HTMX templates, WebUI HTML |
| vscode-css-language-server | CSS | Cyberpunk CSS themes, framegotui styling |
| buf | Proto | gRPC service definitions, buf linting |
| yaml-language-server | YAML | docker-compose, CI/CD, config files |
| docker-langserver | Docker | Dockerfile for service deployment |
| bash-language-server | Shell | Build scripts, systemd setup scripts |
| sqls | SQL | Database migrations, memogo/archigo storage |
| marksman | Markdown | Documentation (critical in the ecosystem) |
| vscode-json-language-server | JSON | Config files, MCP tool definitions |
| actionlint | GitHub Actions | CI/CD workflow validation |

### Install

```bash
# Go tools
go install golang.org/x/tools/gopls@latest
go install github.com/a-h/templ/cmd/templ@latest
go install github.com/bufbuild/buf/cmd/buf@latest
go install github.com/sqls-server/sqls@latest
go install github.com/rhysd/actionlint/cmd/actionlint@latest

# npm tools
npm i -g vscode-langservers-extracted \
  yaml-language-server \
  dockerfile-language-server-nodejs \
  bash-language-server

# marksman (Arch/Manjaro)
yay -S marksman-bin
# or: gh release download -R artempyanykh/marksman -p marksman-linux-x64 -O ~/.local/bin/marksman && chmod +x ~/.local/bin/marksman
```

### Neovim Config (Complete biodoia Setup)

```lua
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

local on_attach = function(client, bufnr)
  local opts = { buffer = bufnr }
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts)
  if client.supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

-- Go (the heart of the ecosystem)
lspconfig.gopls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
        nilness = true,
        unusedwrite = true,
        unusedvariable = true,
      },
      staticcheck = true,
      gofumpt = true,
      usePlaceholders = true,
      completeUnimported = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      codelenses = {
        gc_details = true,
        generate = true,
        test = true,
        tidy = true,
        run_govulncheck = true,
      },
      directoryFilters = { "-node_modules", "-vendor", "-.git", "-dist" },
    },
  },
})

-- Templ (framegotui WebUI templates)
lspconfig.templ.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- HTML (HTMX templates -- hx-get, hx-post, hx-swap attributes)
lspconfig.html.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "html", "templ" },
})

-- CSS (cyberpunk themes)
lspconfig.cssls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Proto (gRPC services)
lspconfig.bufls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- YAML (docker-compose, CI/CD, config)
lspconfig.yamlls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://json.schemastore.org/docker-compose.json"] = "/docker-compose*.yml",
      },
    },
  },
})

-- JSON
lspconfig.jsonls.setup({ capabilities = capabilities, on_attach = on_attach })

-- Docker
lspconfig.dockerls.setup({ capabilities = capabilities, on_attach = on_attach })

-- Bash
lspconfig.bashls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "sh", "bash", "zsh" },
})

-- SQL (memogo/archigo, migrations)
lspconfig.sqls.setup({ capabilities = capabilities, on_attach = on_attach })

-- Markdown (documentation is critical)
lspconfig.marksman.setup({ capabilities = capabilities, on_attach = on_attach })
```

### Claude Code Config (.claude/settings.json)

```json
{
  "lsp": {
    "gopls": {
      "command": "gopls",
      "args": ["serve"],
      "languages": ["go"],
      "settings": {
        "gopls": {
          "staticcheck": true,
          "gofumpt": true,
          "analyses": {
            "unusedparams": true,
            "shadow": true,
            "nilness": true,
            "unusedvariable": true
          }
        }
      }
    },
    "yaml-language-server": {
      "command": "yaml-language-server",
      "args": ["--stdio"],
      "languages": ["yaml"]
    },
    "bash-language-server": {
      "command": "bash-language-server",
      "args": ["start"],
      "languages": ["shellscript"]
    },
    "docker-langserver": {
      "command": "docker-langserver",
      "args": ["--stdio"],
      "languages": ["dockerfile"]
    }
  }
}
```

### Helix Config (languages.toml)

```toml
[[language]]
name = "go"
auto-format = true
language-servers = ["gopls"]
formatter = { command = "gofumpt" }

[language-server.gopls]
command = "gopls"
args = ["serve"]
[language-server.gopls.config]
gofumpt = true
staticcheck = true
hints.parameterNames = true
hints.assignVariableTypes = true
analyses.unusedparams = true
analyses.shadow = true

[[language]]
name = "templ"
auto-format = true
language-servers = ["templ"]
[language-server.templ]
command = "templ"
args = ["lsp"]

[[language]]
name = "protobuf"
auto-format = true
language-servers = ["buf"]
[language-server.buf]
command = "buf"
args = ["beta", "lsp"]

[[language]]
name = "yaml"
auto-format = true
language-servers = ["yaml-language-server"]
[language-server.yaml-language-server]
command = "yaml-language-server"
args = ["--stdio"]

[[language]]
name = "dockerfile"
language-servers = ["docker-langserver"]
[language-server.docker-langserver]
command = "docker-langserver"
args = ["--stdio"]

[[language]]
name = "bash"
language-servers = ["bash-language-server"]
[language-server.bash-language-server]
command = "bash-language-server"
args = ["start"]

[[language]]
name = "sql"
language-servers = ["sqls"]
[language-server.sqls]
command = "sqls"

[[language]]
name = "html"
language-servers = ["vscode-html-language-server"]
[language-server.vscode-html-language-server]
command = "vscode-html-language-server"
args = ["--stdio"]

[[language]]
name = "css"
language-servers = ["vscode-css-language-server"]
[language-server.vscode-css-language-server]
command = "vscode-css-language-server"
args = ["--stdio"]

[[language]]
name = "markdown"
language-servers = ["marksman"]
[language-server.marksman]
command = "marksman"
args = ["server"]

[[language]]
name = "json"
language-servers = ["vscode-json-language-server"]
[language-server.vscode-json-language-server]
command = "vscode-json-language-server"
args = ["--stdio"]
```

This preset covers the entire biodoia ecosystem: from framegotui TUI/WebUI development with HTMX and cyberpunk CSS, through gRPC service definitions with buf, to memogo database integrations with SQL, all wrapped in Docker for deployment with systemd services.
