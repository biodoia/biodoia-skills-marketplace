---
name: multi-lsp
description: This skill should be used when the user asks about "LSP", "language server", "gopls", "pyright", "rust-analyzer", "typescript-language-server", "multi-language project", "code completion", "diagnostics", or "editor language support". Make sure to use this skill whenever the user wants to set up language servers, configure LSP for multiple languages, combine LSP servers in a polyglot project, optimize IDE/editor language intelligence, troubleshoot LSP issues, or detect and install LSP servers for their codebase, even if they just mention code completion or diagnostics without explicitly saying LSP.
---

# Multi-LSP Combiner

The Language Server Protocol (LSP) transformed how editors and IDEs provide language intelligence. Instead of every editor implementing Go support, Python support, and Rust support independently, each language provides a single server that speaks LSP, and every editor connects to it. The result: one implementation per language, universal editor support.

But modern software projects are not monolingual. A typical Go microservice project includes Go source files, Protocol Buffer definitions, SQL migrations, YAML configuration, Dockerfiles, shell scripts, HTML templates, and markdown documentation. Each of these languages and formats has its own LSP server. Configuring them individually is tedious, error-prone, and fragile. Adding a new `.proto` file to a Go project should not require manual installation and configuration of `buf` or `pbls` -- it should just work.

The Multi-LSP Combiner solves this problem. It scans the project, identifies every language and framework in use, determines which LSP servers are needed, installs missing ones, and generates a unified configuration for the editor. The goal is zero manual LSP configuration: clone a repo, run the setup, and every file type has full language intelligence.

## Philosophy

**Modern projects are polyglot by default.** A Go backend with gRPC uses at minimum: Go, Protocol Buffers, YAML, SQL, Docker, Shell, and Markdown. A Node.js frontend adds TypeScript, HTML, CSS, Tailwind, JSON, and possibly GraphQL. The biodoia ecosystem (framegotui, memogo, govai, cligolist) combines Go + templ + HTMX + HTML/CSS + Protocol Buffers + YAML + Docker + Shell + SQL. Each language deserves first-class editor support.

**Each language has a best-in-class LSP server.** gopls for Go, rust-analyzer for Rust, pyright for Python, typescript-language-server for TypeScript. These servers are maintained by their respective language communities and represent years of engineering. The Multi-LSP approach uses the best tool for each job rather than one mediocre tool for everything.

**Auto-detection eliminates configuration drift.** When Terraform files are added to a project, the LSP configuration should update automatically. When Python is removed, the Python LSP should no longer load. Detection is based on file presence, not manual declaration.

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
| `Cargo.toml` | Rust | rust-analyzer |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python | pyright, ruff |
| `*.proto` / `buf.yaml` | Protocol Buffers | buf, pbls |
| `Dockerfile` / `compose.yaml` | Docker | docker-langserver |
| `*.yaml` / `*.yml` | YAML | yaml-language-server |
| `*.html` / `*.css` | HTML/CSS | vscode-html/css-language-server |
| `*.sh` / `*.bash` | Shell | bash-language-server |
| `.github/workflows/*.yml` | GitHub Actions | actionlint |
| `*.tf` / `terraform/` | Terraform | terraform-ls |

For the complete marker list covering all 20+ supported languages (Lua, Zig, Nix, GraphQL, TOML, Markdown, SQL, JSON, and more), see `references/server-catalog.md`.

**Phase 2: Framework-specific detection.** Certain framework combinations require additional LSP servers or special configuration:

- **framegotui projects** (detected by `github.com/biodoia/framegotui` in `go.mod`): gopls + templ LSP + vscode-html-language-server + vscode-css-language-server. The templ LSP handles `.templ` files and delegates HTML/CSS completions to their respective servers.

- **Next.js projects** (detected by `next` in `package.json` dependencies): typescript-language-server + tailwindcss-language-server + eslint.

- **gRPC projects** (detected by `google.golang.org/grpc` in `go.mod` or `*.proto` files): gopls + buf + proto LSP. buf handles proto linting and formatting, gopls handles generated Go code.

- **HTMX projects** (detected by `htmx` references in HTML files or Go templates): vscode-html-language-server configured with HTMX attribute completions. If using Go templ, the templ LSP handles HTMX within `.templ` files.

**Phase 3: Auxiliary tool detection.** These files indicate formatting and linting preferences that affect LSP configuration:

- `.prettierrc` / `prettier.config.js` -- prettier as formatter
- `.eslintrc` / `eslint.config.js` -- eslint LSP integration
- `biome.json` -- biome LSP (replaces eslint + prettier for JS/TS/JSON/CSS)
- `deno.json` -- deno LSP (replaces typescript-language-server)
- `tailwind.config.js` / `tailwind.config.ts` -- tailwindcss-language-server

When `biome.json` is present, the combiner prefers biome over separate eslint + prettier configurations. When `deno.json` is present, it uses the deno built-in LSP instead of typescript-language-server.

## Configuration Generation

The combiner generates editor-specific configuration based on the detected stack. Supported editors:

- **Neovim (nvim-lspconfig)**: Each server gets its own `lspconfig.SERVERNAME.setup({})` call with server-specific settings. Also supports mason.nvim for auto-installation.
- **VS Code (settings.json)**: Per-language settings with formatter selection and extension recommendations.
- **Helix (languages.toml)**: Declarative language blocks with native multi-LSP support.
- **Zed (settings.json)**: LSP servers configured under the `"lsp"` key with command, args, and init options.
- **Emacs**: Both lsp-mode and eglot (built-in for Emacs 29+) configurations.
- **Kakoune**: kak-lsp TOML configuration.
- **Claude Code (.claude/settings.json)**: LSP integration providing completion and diagnostic context during AI coding sessions.

Full editor configuration templates are available in `references/editor-configs.md`.

## Combination Strategies

Running multiple LSP servers simultaneously requires a strategy for combining their results.

### Side-by-Side (Recommended)

Each LSP server runs independently. The editor routes requests to the appropriate server based on file type. The editor's LSP client manages the lifecycle of each server: starting it when a matching file is opened, sending requests to the correct server, and merging completions/diagnostics from multiple servers when a file matches more than one (e.g., HTML files receiving completions from both the HTML LSP and the Tailwind LSP).

### Multiplexer Approach

A meta-LSP server proxies requests to multiple backend servers:
- **efm-langserver**: Integrates external linters and formatters (shellcheck, hadolint, markdownlint, actionlint).
- **diagnostic-languageserver**: Aggregates diagnostics from multiple linters into a single LSP stream.
- **mcp-language-server**: Exposes LSP features as MCP tools for AI coding assistants.

### Unified Approach

Some tools provide multi-language LSP support in a single server:
- **biome**: Handles JavaScript, TypeScript, JSON, and CSS in one server.
- **vscode-langservers-extracted**: Provides HTML, CSS, and JSON servers in one npm package.

The recommended approach for most projects is **side-by-side** with **efm-langserver** for additional linting.

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

Check in order:
1. **Binary exists**: Run `which gopls` or `command -v gopls`. If missing, the server is not installed or not in PATH.
2. **Permissions**: The binary must be executable.
3. **Dependencies**: Some servers need runtime dependencies (typescript-language-server needs `typescript`, pyright needs `python3`).
4. **Log output**: Start the server manually with `--log-level debug` or `--verbose` flags.
5. **Port conflicts**: Check for conflicts with `ss -tlnp | grep PORT`.

### Slow Diagnostics

1. **Tune diagnostic delay**: Increase gopls `diagnosticsDelay` to 500ms-1000ms for large projects.
2. **Limit workspace scope**: Configure explicit excludes for `node_modules/`, `.git/`, `vendor/`, `dist/`, `build/`.
3. **Reduce enabled analyses**: Disable non-essential analyzers in large codebases.
4. **Separate workspace folders**: Open each sub-project as a separate workspace folder instead of the monorepo root.

### Conflicting Formatters

1. **Identify all formatters**: Multiple tools may claim the same file type (e.g., both prettier and biome for TypeScript).
2. **Set explicit priority**: Designate one formatter per file type. In Neovim, use `vim.lsp.buf.format({ name = "specific_server" })`.
3. **Disable formatting on non-primary servers**: Set `capabilities.documentFormattingProvider = false` on secondary servers.

### Memory Usage

1. **Monitor per-server memory**: Run `ps aux | grep -E 'gopls|pyright|typescript'`.
2. **Lazy loading**: Configure servers to start only when a matching file is opened.
3. **Limit gopls memory**: Set `GOGC=100` or lower. Use `-remote=auto` for shared instances.
4. **Limit typescript-language-server memory**: Set `--tsserver.maxTsServerMemory` (default 3072 MB).

### Server-Specific Tips

**gopls**: Set `GOFLAGS=-tags=...` for build tag support. Enable `vulncheck` for vulnerability scanning. Use `gofumpt` for stricter formatting.

**pyright vs ruff**: Use pyright for type checking and completion, ruff for linting and formatting. The recommended Python setup is pyright + ruff (two servers).

**typescript-language-server**: Increase max heap size for large projects: `--tsserver.maxTsServerMemory 4096`. Use project references for monorepos.

**rust-analyzer**: Change check command to clippy for more diagnostics: `"rust-analyzer.check.command": "clippy"`. For large projects, set `cargo.buildScripts.enable: false` during initial loading.

## Advanced Topics

### Custom LSP Configuration Per Project

Create a `.lspconfig` directory in the project root with server-specific overrides (`gopls.json`, `pyright.json`, `eslint.json`). The combiner reads these files and merges them with the default configuration during generation.

### LSP Logging and Debugging

Enable verbose logging to diagnose protocol-level issues:

```bash
gopls -rpc.trace -v serve 2>/tmp/gopls.log
typescript-language-server --stdio --log-level 4 2>/tmp/tsserver.log
```

In Neovim, set `vim.lsp.set_log_level("debug")` and check `:LspLog` for detailed protocol traces.

### Semantic Tokens and Inlay Hints

Most modern LSP servers support semantic tokens (language-aware highlighting beyond regex-based syntax) and inlay hints (inline type annotations, parameter names). Enable both in the editor config for the best experience. Disable inlay hints if the visual noise is distracting.

### Code Actions and Refactoring

Each LSP server provides different code actions:
- **gopls**: Extract function/variable, fill struct, add/remove tags, organize imports, generate test
- **rust-analyzer**: Extract function/variable/module, generate impl/derive, unwrap Result, add missing match arms
- **pyright**: Organize imports, add type annotations, extract variable
- **typescript-language-server**: Extract function/constant, move to file, organize imports, add missing imports

The Multi-LSP Combiner ensures all these capabilities are available for every language in the project without manual configuration.

## Additional Resources

For detailed information, consult these reference files and scripts:

- `references/server-catalog.md` -- exhaustive catalog of LSP servers with installation, configuration, capabilities, and known issues
- `references/editor-configs.md` -- complete configuration templates for Neovim, VS Code, Helix, Zed, Emacs, Kakoune, and Claude Code
- `references/stack-presets.md` -- pre-built LSP configurations for Go Full Stack, Node.js Full Stack, Rust Full Stack, Python Full Stack, DevOps, and the biodoia Ecosystem
- `scripts/detect-stack.sh` -- automated stack detection script
- `scripts/install-lsp.sh` -- automated LSP server installation script
