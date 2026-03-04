---
name: multi-lsp
description: Use when setting up language servers for a project, configuring LSP for multiple languages, combining LSP servers, optimizing IDE/editor language support, or troubleshooting LSP issues. Also use when mentioning 'LSP', 'language server', 'gopls', 'pyright', 'typescript-language-server', 'multi-language project', 'code completion', 'diagnostics', or wanting comprehensive language intelligence across a polyglot codebase.
---

# Multi-LSP Combiner

The Language Server Protocol (LSP) transformed how editors and IDEs provide language intelligence. Instead of every editor implementing Go support, Python support, and Rust support independently, each language provides a single server that speaks LSP, and every editor connects to it. The result: one implementation per language, universal editor support.

But modern software projects are not monolingual. A typical Go microservice project includes Go source files, Protocol Buffer definitions, SQL migrations, YAML configuration, Dockerfiles, shell scripts, HTML templates, and markdown documentation. Each of these languages and formats has its own LSP server. Configuring them individually is tedious, error-prone, and fragile. When you add a new `.proto` file to your Go project, you should not need to manually install and configure `buf` or `pbls` -- it should just work.

The Multi-LSP Combiner solves this problem. It scans your project, identifies every language and framework in use, determines which LSP servers are needed, installs missing ones, and generates a unified configuration for your editor. The goal is zero manual LSP configuration: clone a repo, run the setup, and every file type has full language intelligence.

## Philosophy

**Modern projects are polyglot by default.** A Go backend with gRPC uses at minimum: Go, Protocol Buffers, YAML, SQL, Docker, Shell, and Markdown. A Node.js frontend adds TypeScript, HTML, CSS, Tailwind, JSON, and possibly GraphQL. The biodoia ecosystem (framegotui, memogo, govai, cligolist) combines Go + templ + HTMX + HTML/CSS + Protocol Buffers + YAML + Docker + Shell + SQL. Each language deserves first-class editor support.

**Each language has a best-in-class LSP server.** gopls for Go, rust-analyzer for Rust, pyright for Python, typescript-language-server for TypeScript. These servers are maintained by their respective language communities and represent years of engineering. The Multi-LSP approach uses the best tool for each job rather than one mediocre tool for everything.

**Auto-detection eliminates configuration drift.** When you add Terraform files to your project, the LSP configuration should update automatically. When you remove Python, the Python LSP should no longer load. Detection is based on file presence, not manual declaration.

**The combined experience should feel unified.** A developer should not notice that seven different LSP servers are running. Completion, diagnostics, formatting, and refactoring should work seamlessly regardless of which server provides the intelligence.

## Stack Detection Algorithm

Stack detection is the foundation of the Multi-LSP Combiner. The algorithm scans the project root and key subdirectories for language markers -- specific files and file extensions that indicate which languages and tools are in use.

### Primary Language Detection

The detection proceeds in three phases: language identification, framework detection, and auxiliary tool detection.

**Phase 1: Language markers.** Each marker maps to one or more LSP servers:

| Marker | Language | LSP Server(s) |
|--------|----------|----------------|
| `go.mod` | Go | gopls |
| `package.json` | JavaScript/TypeScript | typescript-language-server, eslint |
| `tsconfig.json` | TypeScript (confirmed) | typescript-language-server |
| `Cargo.toml` | Rust | rust-analyzer |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python | pyright, ruff |
| `*.proto` / `buf.yaml` | Protocol Buffers | buf, pbls |
| `Dockerfile` / `compose.yaml` / `docker-compose.yml` | Docker | docker-langserver |
| `*.yaml` / `*.yml` | YAML | yaml-language-server |
| `*.json` | JSON | vscode-json-languageserver |
| `*.toml` | TOML | taplo |
| `*.md` | Markdown | marksman |
| `*.sql` | SQL | sqls, pgFormatter |
| `*.html` / `*.css` | HTML/CSS | vscode-html-language-server, vscode-css-language-server |
| `*.lua` | Lua | lua-language-server |
| `*.sh` / `*.bash` | Shell | bash-language-server |
| `*.zig` | Zig | zls |
| `*.nix` | Nix | nil, nixd |
| `Makefile` | Make | (linting only, no LSP) |
| `.github/workflows/*.yml` | GitHub Actions | actionlint |
| `*.tf` / `terraform/` | Terraform | terraform-ls |
| `*.graphql` | GraphQL | graphql-language-server |

**Phase 2: Framework-specific detection.** Certain framework combinations require additional LSP servers or special configuration:

- **framegotui projects** (detected by `github.com/biodoia/framegotui` in `go.mod`): gopls + templ LSP + vscode-html-language-server + vscode-css-language-server. The templ LSP handles `.templ` files and delegates HTML/CSS completions to their respective servers.

- **Next.js projects** (detected by `next` in `package.json` dependencies): typescript-language-server + tailwindcss-language-server + eslint. The typescript-language-server needs Next.js plugin configuration.

- **gRPC projects** (detected by `google.golang.org/grpc` in `go.mod` or `*.proto` files): gopls + buf + proto LSP. buf handles proto linting and formatting, gopls handles generated Go code.

- **HTMX projects** (detected by `htmx` references in HTML files or Go templates): vscode-html-language-server configured with HTMX attribute completions. If using Go templ, the templ LSP handles HTMX within `.templ` files.

**Phase 3: Auxiliary tool detection.** These files indicate formatting and linting preferences that affect LSP configuration:

- `.editorconfig` -- editorconfig support (most LSP servers respect it)
- `.prettierrc` / `.prettierrc.json` / `prettier.config.js` -- prettier as formatter
- `.eslintrc` / `.eslintrc.json` / `eslint.config.js` -- eslint LSP integration
- `biome.json` / `biome.jsonc` -- biome LSP (replaces eslint + prettier for JS/TS/JSON/CSS)
- `deno.json` / `deno.jsonc` -- deno LSP (replaces typescript-language-server)
- `tailwind.config.js` / `tailwind.config.ts` -- tailwindcss-language-server

When `biome.json` is present, the combiner prefers biome over separate eslint + prettier configurations. When `deno.json` is present, it uses the deno built-in LSP instead of typescript-language-server.

## LSP Server Catalog

The full server catalog with installation instructions, configuration options, and capabilities is maintained in `references/server-catalog.md`. Here is a summary of the most important servers:

| Language | Server | Install Command | Key Capabilities |
|----------|--------|-----------------|------------------|
| Go | gopls | `go install golang.org/x/tools/gopls@latest` | completion, diagnostics, refactoring, code lens, inlay hints |
| TypeScript/JS | typescript-language-server | `npm i -g typescript-language-server typescript` | full TS/JS support, auto-imports, refactoring |
| Python | pyright | `pip install pyright` or `npm i -g pyright` | type checking, completion, diagnostics |
| Python | ruff | `pip install ruff` | fast linting, formatting (replaces flake8+black+isort) |
| Rust | rust-analyzer | `rustup component add rust-analyzer` | full Rust support, macro expansion, inlay hints |
| Proto | buf | `go install github.com/bufbuild/buf/cmd/buf@latest` | linting, formatting, breaking change detection |
| YAML | yaml-language-server | `npm i -g yaml-language-server` | schema validation, completion |
| JSON | vscode-json-languageserver | `npm i -g vscode-langservers-extracted` | schema validation, formatting |
| Docker | docker-langserver | `npm i -g dockerfile-language-server-nodejs` | Dockerfile syntax, directives |
| HTML | vscode-html-language-server | `npm i -g vscode-langservers-extracted` | HTML completion, embedded CSS/JS |
| CSS | vscode-css-language-server | `npm i -g vscode-langservers-extracted` | CSS/SCSS/Less completion, diagnostics |
| Tailwind | tailwindcss-language-server | `npm i -g @tailwindcss/language-server` | Tailwind class completion, hover |
| Bash | bash-language-server | `npm i -g bash-language-server` | shell script analysis, completion |
| SQL | sqls | `go install github.com/sqls-server/sqls@latest` | SQL completion, formatting |
| Lua | lua-language-server | `pacman -S lua-language-server` | Lua completion, diagnostics |
| Markdown | marksman | binary from GitHub releases | markdown links, TOC, cross-references |
| TOML | taplo | `cargo install taplo-cli` | TOML validation, formatting, schema |
| Zig | zls | zig package manager or binary | Zig completion, diagnostics |
| Terraform | terraform-ls | `brew install terraform-ls` or binary | HCL support, provider schemas |
| GraphQL | graphql-lsp | `npm i -g graphql-language-service-cli` | GraphQL completion, validation |
| Templ | templ | `go install github.com/a-h/templ/cmd/templ@latest` | Go templ files, HTML in Go |

## Configuration Generation

The combiner generates editor-specific configuration based on the detected stack. Each editor has different mechanisms for configuring LSP servers.

### Neovim (nvim-lspconfig)

Neovim's native LSP client with the `nvim-lspconfig` plugin is the most flexible configuration target. Each server gets its own `lspconfig.SERVERNAME.setup({})` call with server-specific settings:

```lua
local lspconfig = require('lspconfig')

-- Go
lspconfig.gopls.setup({
  settings = {
    gopls = {
      analyses = { unusedparams = true, shadow = true },
      staticcheck = true,
      gofumpt = true,
      usePlaceholders = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
        parameterNames = true,
      },
    },
  },
})

-- YAML with schema support
lspconfig.yamlls.setup({
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://json.schemastore.org/docker-compose.json"] = "/docker-compose*.yml",
      },
    },
  },
})
```

### VS Code (settings.json)

VS Code uses per-language settings in `.vscode/settings.json`. Each language maps to a formatter and extension configuration. The generated config includes file associations, formatter selection, and extension recommendations.

### Helix (languages.toml)

Helix uses a declarative `languages.toml` file. Each language block specifies the language server, formatter, and file patterns. Helix supports multiple language servers per language natively.

### Zed (settings.json)

Zed configures LSP servers in its `settings.json` under the `"lsp"` key. Each server has command, args, and initialization options.

### Claude Code (.claude/settings.json)

Claude Code supports LSP integration through its settings file. Configured servers provide completion and diagnostic context to Claude during coding sessions.

Full editor configuration templates are available in `references/editor-configs.md`.

## Combination Strategies

Running multiple LSP servers simultaneously requires a strategy for combining their results. There are three main approaches.

### Side-by-Side (Recommended)

Each LSP server runs independently. The editor routes requests to the appropriate server based on file type. This is the default approach for Neovim, VS Code, Helix, and Zed. It requires per-filetype routing but provides the most reliable results since each server handles only its own language.

The editor's LSP client manages the lifecycle of each server: starting it when a matching file is opened, sending requests to the correct server, and merging completions/diagnostics from multiple servers when a file matches more than one (e.g., HTML files can receive completions from both the HTML LSP and the Tailwind LSP).

### Multiplexer Approach

A meta-LSP server proxies requests to multiple backend servers. This approach is useful when the editor does not natively support multiple LSP servers per file type.

Key multiplexer tools:
- **efm-langserver**: A general-purpose LSP that integrates external linters and formatters. It does not replace dedicated LSP servers but augments them with additional diagnostics from tools like shellcheck, hadolint, markdownlint, and actionlint.
- **diagnostic-languageserver**: Similar to efm-langserver, aggregates diagnostics from multiple linters into a single LSP stream.
- **mcp-language-server**: Exposes LSP features (completion, diagnostics, hover, references) as MCP tools, making them available to AI coding assistants.

### Unified Approach

Some tools provide LSP support for multiple languages in a single server:
- **biome**: Handles JavaScript, TypeScript, JSON, and CSS in one server. When the project uses biome, it replaces separate eslint, prettier, and json LSP configurations.
- **vscode-langservers-extracted**: Provides HTML, CSS, and JSON language servers in one npm package (but they still run as separate processes).

The recommended approach for most projects is **side-by-side** with **efm-langserver** for additional linting. This provides the best combination of reliability, performance, and coverage.

## Installation Workflow

The installation workflow is automated through two scripts in the `scripts/` directory.

**`detect-stack.sh`** scans the current directory and outputs a structured report of detected languages, required LSP servers, installed servers, and missing servers with install commands.

**`install-lsp.sh`** takes either a preset name or auto-detects the stack, then installs all missing LSP servers using the appropriate package manager for the current OS. It supports Arch/Manjaro (pacman/yay), macOS (brew), and Ubuntu/Debian (apt) with fallbacks to npm, pip, go install, and cargo install.

The full installation flow:
1. Run `detect-stack.sh` to identify the stack
2. Review the detection results
3. Run `install-lsp.sh` to install missing servers
4. Choose an editor target for configuration generation
5. Validate all servers with a version check

Pre-built stack presets are available in `references/stack-presets.md` for common project types.

## Troubleshooting

### LSP Server Not Starting

The most common issue. Check in order:
1. **Binary exists**: `which gopls` or `command -v gopls`. If missing, the server is not installed or not in PATH.
2. **Permissions**: `ls -la $(which gopls)`. The binary must be executable.
3. **Dependencies**: Some servers need runtime dependencies. typescript-language-server needs `typescript` installed. pyright needs `python3`.
4. **Log output**: Start the server manually with verbose logging. Most servers support `--log-level debug` or `--verbose` flags.
5. **Port conflicts**: If the server runs on a port (e.g., sqls), check for conflicts with `ss -tlnp | grep PORT`.

### Slow Diagnostics

When diagnostics take too long or the editor feels sluggish:
1. **Tune diagnostic delay**: Many servers support a diagnostic delay setting (e.g., gopls `diagnosticsDelay`). Increase it to 500ms-1000ms for large projects.
2. **Limit workspace scope**: Exclude irrelevant directories. Most servers respect `.gitignore`. Additionally configure explicit excludes for `node_modules/`, `.git/`, `vendor/`, `dist/`, `build/`.
3. **Reduce enabled analyses**: gopls has many optional analyzers (shadow, unusedparams, nilness). Disable non-essential ones in large codebases.
4. **Separate workspace folders**: Instead of opening a monorepo root, open each sub-project as a separate workspace folder.

### Conflicting Formatters

When format-on-save produces unexpected results or fights between formatters:
1. **Identify all formatters**: Multiple tools may claim the same file type. For example, both prettier and biome can format TypeScript. Both gofumpt and goimports can format Go.
2. **Set explicit priority**: In your editor config, designate one formatter per file type. In Neovim, use `vim.lsp.buf.format({ name = "specific_server" })`.
3. **Disable formatting on non-primary servers**: Configure secondary LSP servers with `capabilities.documentFormattingProvider = false`.

### Memory Usage

Each LSP server consumes memory. A polyglot project with 10+ servers can use significant resources:
1. **Monitor per-server memory**: `ps aux | grep -E 'gopls|pyright|typescript'` to see memory consumption.
2. **Lazy loading**: Configure servers to start only when a matching file is opened, not at editor startup.
3. **Limit gopls memory**: Set `GOGC=100` or lower. Use `-remote=auto` for shared gopls instances across projects.
4. **Limit typescript-language-server memory**: Set `--tsserver.maxTsServerMemory` (default 3072 MB).
5. **Kill idle servers**: Some editors support stopping servers for languages not currently open.

### Server-Specific Tips

**gopls**: Set `GOFLAGS=-tags=...` for build tag support. Use `gc_details` for compiler optimization hints. Enable `vulncheck` for vulnerability scanning. Use `gofumpt` for stricter formatting.

**pyright vs pylsp vs ruff**: Use pyright for type checking and completion, ruff for linting and formatting. pylsp is an alternative to pyright with plugin support but is slower. The recommended Python setup is pyright + ruff (two servers).

**typescript-language-server**: Increase max heap size for large projects: `--tsserver.maxTsServerMemory 4096`. Use project references for monorepos. Enable `implementationsCodeLens` and `referencesCodeLens` for navigation.

**rust-analyzer**: The `checkOnSave` command defaults to `cargo check`. Change to `clippy` for more diagnostics: `"rust-analyzer.check.command": "clippy"`. For large projects, set `cargo.buildScripts.enable: false` during initial loading.

## Advanced Topics

### Custom LSP Configuration Per Project

Create a `.lspconfig` directory in the project root with server-specific overrides:

```
.lspconfig/
  gopls.json        # gopls init_options override
  pyright.json      # pyright settings override
  eslint.json       # eslint configuration override
```

The combiner reads these files and merges them with the default configuration during generation.

### LSP Logging and Debugging

Enable verbose logging to diagnose protocol-level issues:

```bash
# gopls with full logging
gopls -rpc.trace -v serve 2>/tmp/gopls.log

# typescript-language-server
typescript-language-server --stdio --log-level 4 2>/tmp/tsserver.log

# Generic: capture stderr from any LSP
EDITOR_LSP_LOG=/tmp/lsp.log nvim  # (varies by editor)
```

In Neovim, set `vim.lsp.set_log_level("debug")` and check `:LspLog` for detailed protocol traces.

### Performance Profiling

Measure LSP response times to identify bottleneck servers:

```lua
-- Neovim: log LSP request durations
vim.lsp.handlers["textDocument/completion"] = function(err, result, ctx, config)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  vim.notify(string.format("%s completion: %dms", client.name, vim.loop.hrtime() / 1e6))
  return vim.lsp.handlers["textDocument/completion"](err, result, ctx, config)
end
```

### Semantic Tokens and Inlay Hints

Most modern LSP servers support semantic tokens (richer syntax highlighting) and inlay hints (inline type annotations, parameter names). These features are opt-in in most editors:

- **Semantic tokens**: Provides language-aware highlighting that goes beyond regex-based syntax. gopls highlights imported vs local symbols differently. rust-analyzer highlights unsafe code.
- **Inlay hints**: Shows inferred types, parameter names, and chain types inline. Extremely useful for Go (shows `:=` inferred types), Rust (shows turbofish types), and TypeScript (shows inferred return types).

Enable both in your editor config for the best experience. Disable inlay hints if the visual noise is distracting -- they are a preference, not a requirement.

### Code Actions and Refactoring

Each LSP server provides different code actions. Knowing what each server offers helps you use them effectively:

- **gopls**: Extract function/variable, inline function, fill struct, add/remove tags, organize imports, generate test
- **rust-analyzer**: Extract function/variable/module, inline function/variable, generate impl/derive, unwrap Result, add missing match arms
- **pyright**: Organize imports, add type annotations, extract variable
- **typescript-language-server**: Extract function/constant, move to new file, organize imports, convert between named/default export, add missing imports

The Multi-LSP Combiner ensures all these capabilities are available for every language in your project without manual configuration.

## Reference Files

For detailed information, read these reference files on demand:

- `skills/multi-lsp/references/server-catalog.md` -- exhaustive catalog of LSP servers with installation, configuration, capabilities, and known issues
- `skills/multi-lsp/references/editor-configs.md` -- complete configuration templates for Neovim, VS Code, Helix, Zed, Emacs, Kakoune, and Claude Code
- `skills/multi-lsp/references/stack-presets.md` -- pre-built LSP configurations for Go Full Stack, Node.js Full Stack, Rust Full Stack, Python Full Stack, DevOps, and the biodoia Ecosystem
