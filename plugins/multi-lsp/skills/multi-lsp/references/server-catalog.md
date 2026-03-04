# LSP Server Catalog

Exhaustive reference for all LSP servers supported by the Multi-LSP Combiner. Each entry includes installation methods, configuration options, capabilities, performance characteristics, and known issues.

---

## Go: gopls

The official Go language server, maintained by the Go team.

### Installation

| Method | Command |
|--------|---------|
| go install | `go install golang.org/x/tools/gopls@latest` |
| Arch/Manjaro | `pacman -S gopls` |
| macOS | `brew install gopls` |
| Ubuntu | `snap install gopls --classic` |

### Binary

`gopls` (stdio mode by default, `gopls serve` for daemon mode)

### Configuration (init_options / settings)

```json
{
  "gopls": {
    "analyses": {
      "unusedparams": true,
      "shadow": true,
      "nilness": true,
      "unusedwrite": true,
      "useany": true,
      "unusedvariable": true
    },
    "staticcheck": true,
    "gofumpt": true,
    "usePlaceholders": true,
    "completeUnimported": true,
    "deepCompletion": true,
    "matcher": "Fuzzy",
    "symbolMatcher": "FastFuzzy",
    "diagnosticsDelay": "500ms",
    "hints": {
      "assignVariableTypes": true,
      "compositeLiteralFields": true,
      "compositeLiteralTypes": true,
      "constantValues": true,
      "functionTypeParameters": true,
      "parameterNames": true,
      "rangeVariableTypes": true
    },
    "vulncheck": "Imports",
    "codelenses": {
      "gc_details": true,
      "generate": true,
      "regenerate_cgo": true,
      "run_govulncheck": true,
      "tidy": true,
      "upgrade_dependency": true,
      "vendor": true,
      "test": true
    },
    "buildFlags": [],
    "directoryFilters": ["-node_modules", "-vendor", "-.git"]
  }
}
```

### Capabilities

- Completion (with deep completion and unimported packages)
- Diagnostics (go vet, staticcheck, vulncheck)
- Formatting (gofmt, gofumpt, goimports)
- Refactoring (extract function/variable, inline, rename)
- Code lens (run tests, gc details, tidy, generate)
- Inlay hints (types, parameter names, composite literals)
- Semantic tokens
- Call hierarchy
- Workspace symbols
- Folding ranges
- Document links
- Selection ranges

### Performance

- **Memory**: 200-800 MB for medium projects, 1-2 GB for large monorepos
- **Startup**: 2-10 seconds (initial indexing)
- **Tip**: Use `-remote=auto` to share a single gopls instance across editor windows
- **Tip**: Set `GOGC=100` to limit memory growth (default is 100, lower = more frequent GC)
- **Tip**: Use `directoryFilters` to exclude irrelevant directories

### Known Issues

- Large monorepos can cause high memory usage. Use workspace folders instead of opening the monorepo root.
- Build tags require `GOFLAGS=-tags=...` or `buildFlags` setting.
- CGO-heavy projects need CGO_ENABLED=1 and a C compiler.
- If diagnostics are slow, increase `diagnosticsDelay`.

---

## TypeScript/JavaScript: typescript-language-server

Wraps TypeScript's `tsserver` in the LSP protocol. The standard TypeScript/JavaScript language server.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g typescript-language-server typescript` |
| pnpm | `pnpm add -g typescript-language-server typescript` |
| Arch/Manjaro | `pacman -S typescript-language-server` |

**Important**: `typescript` must be installed alongside `typescript-language-server` (either globally or in the project).

### Binary

`typescript-language-server --stdio`

### Configuration

```json
{
  "typescript": {
    "tsserver": {
      "maxTsServerMemory": 4096
    },
    "inlayHints": {
      "includeInlayParameterNameHints": "all",
      "includeInlayParameterNameHintsWhenArgumentMatchesName": false,
      "includeInlayFunctionParameterTypeHints": true,
      "includeInlayVariableTypeHints": true,
      "includeInlayPropertyDeclarationTypeHints": true,
      "includeInlayFunctionLikeReturnTypeHints": true,
      "includeInlayEnumMemberValueHints": true
    },
    "suggest": {
      "completeFunctionCalls": true,
      "includeAutomaticOptionalChainCompletions": true
    },
    "implementationsCodeLens": { "enabled": true },
    "referencesCodeLens": { "enabled": true }
  }
}
```

### Capabilities

- Completion (with auto-imports)
- Diagnostics (type errors, unused variables)
- Formatting
- Refactoring (extract function/constant, move to file, organize imports)
- Code lens (references, implementations)
- Inlay hints (types, parameter names, return types)
- Semantic tokens
- Call hierarchy
- Go to definition/implementation/type definition
- Find references
- Document symbols

### Performance

- **Memory**: 300 MB-2 GB depending on project size
- **Startup**: 3-15 seconds for large projects
- **Tip**: Set `maxTsServerMemory` for large projects (default 3072 MB)
- **Tip**: Use project references for monorepos
- **Tip**: Exclude `node_modules` and `dist` from watching

### Known Issues

- High memory usage in large monorepos. Use project references.
- Auto-imports can be slow. Tune `typescript.suggest.autoImports`.
- The server wraps tsserver, so tsserver bugs propagate.

---

## Python: pyright

Microsoft's fast Python type checker and language server.

### Installation

| Method | Command |
|--------|---------|
| pip | `pip install pyright` |
| npm | `npm i -g pyright` |
| Arch/Manjaro | `yay -S pyright` |
| macOS | `brew install pyright` |

### Binary

`pyright-langserver --stdio`

### Configuration

Configured via `pyrightconfig.json` in project root:

```json
{
  "typeCheckingMode": "basic",
  "reportMissingImports": true,
  "reportMissingTypeStubs": false,
  "reportUnusedImport": true,
  "reportUnusedVariable": true,
  "pythonVersion": "3.12",
  "venvPath": ".",
  "venv": ".venv",
  "exclude": ["**/node_modules", "**/__pycache__", "**/build", "**/dist"]
}
```

LSP settings:

```json
{
  "python": {
    "analysis": {
      "typeCheckingMode": "basic",
      "autoSearchPaths": true,
      "useLibraryCodeForTypes": true,
      "diagnosticMode": "openFilesOnly"
    }
  }
}
```

### Capabilities

- Completion (type-aware)
- Diagnostics (type errors, missing imports)
- Hover (type information, docstrings)
- Go to definition/type definition
- Find references
- Rename
- Code actions (organize imports, add type annotations)
- Inlay hints (variable types, parameter types)
- Semantic tokens

### Performance

- **Memory**: 100-500 MB
- **Startup**: 1-5 seconds
- **Tip**: Use `diagnosticMode: "openFilesOnly"` for large projects
- **Tip**: `typeCheckingMode: "basic"` is a good balance; `"strict"` is verbose

### Known Issues

- Does not handle formatting (use ruff or black for that).
- Virtual environments must be correctly configured for imports to resolve.
- `typeCheckingMode: "strict"` generates many diagnostics in untyped code.

---

## Python: ruff

An extremely fast Python linter and formatter, written in Rust.

### Installation

| Method | Command |
|--------|---------|
| pip | `pip install ruff` |
| Arch/Manjaro | `pacman -S ruff` |
| macOS | `brew install ruff` |
| cargo | `cargo install ruff` |

### Binary

`ruff server` (LSP mode, built-in since ruff 0.4.5)

### Configuration

Configured via `ruff.toml` or `pyproject.toml`:

```toml
# ruff.toml
line-length = 100
target-version = "py312"

[lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM", "TCH"]
ignore = ["E501"]

[format]
quote-style = "double"
indent-style = "space"
```

### Capabilities

- Diagnostics (500+ lint rules from flake8, isort, pyupgrade, etc.)
- Formatting (replaces black)
- Code actions (auto-fix lint violations, organize imports)
- Fast (10-100x faster than flake8 + black + isort combined)

### Performance

- **Memory**: 50-150 MB
- **Startup**: <1 second
- **Note**: ruff is the fastest Python linting/formatting tool available

### Known Issues

- Does not provide completion or type checking (use pyright for that).
- Some complex auto-fixes may need manual review.
- The LSP mode (`ruff server`) replaced the older `ruff-lsp` package.

---

## Rust: rust-analyzer

The official Rust language server (replaced rls).

### Installation

| Method | Command |
|--------|---------|
| rustup | `rustup component add rust-analyzer` |
| Arch/Manjaro | `pacman -S rust-analyzer` |
| macOS | `brew install rust-analyzer` |
| Binary | Download from https://github.com/rust-lang/rust-analyzer/releases |

### Binary

`rust-analyzer`

### Configuration

```json
{
  "rust-analyzer": {
    "check": {
      "command": "clippy"
    },
    "cargo": {
      "buildScripts": { "enable": true },
      "features": "all"
    },
    "procMacro": { "enable": true },
    "inlayHints": {
      "typeHints": { "enable": true },
      "parameterHints": { "enable": true },
      "chainingHints": { "enable": true },
      "closingBraceHints": { "minLines": 25 }
    },
    "lens": {
      "enable": true,
      "references": { "adt": { "enable": true }, "method": { "enable": true } },
      "run": { "enable": true },
      "debug": { "enable": true }
    },
    "diagnostics": {
      "enable": true,
      "experimental": { "enable": true }
    }
  }
}
```

### Capabilities

- Completion (with postfix completions)
- Diagnostics (cargo check/clippy, lifetime errors)
- Formatting (rustfmt)
- Refactoring (extract function/variable/module, inline, unwrap)
- Code lens (run/debug test, references)
- Inlay hints (types, lifetimes, chaining, parameter names)
- Semantic tokens (unsafe highlighting)
- Macro expansion (expand macro to view generated code)
- Call hierarchy
- Workspace symbols

### Performance

- **Memory**: 500 MB-3 GB for large projects
- **Startup**: 5-30 seconds (proc macro expansion, build scripts)
- **Tip**: Disable `cargo.buildScripts.enable` for faster initial load
- **Tip**: Use `cargo.features = "all"` to analyze all feature combinations

### Known Issues

- High memory and CPU during initial indexing.
- proc-macro support requires a running proc-macro server.
- Workspace member errors can cascade.

---

## Protocol Buffers: buf

The modern Protocol Buffer tool, providing linting, formatting, breaking change detection, and LSP support.

### Installation

| Method | Command |
|--------|---------|
| go install | `go install github.com/bufbuild/buf/cmd/buf@latest` |
| Arch/Manjaro | `yay -S buf` |
| macOS | `brew install bufbuild/buf/buf` |
| npm | `npm i -g @bufbuild/buf` |
| Binary | https://github.com/bufbuild/buf/releases |

### Binary

`buf` (LSP features are part of the buf CLI via editor integrations)

### Capabilities

- Linting (STANDARD, COMMENTS, UNARY_RPC rules)
- Formatting (`buf format`)
- Breaking change detection (`buf breaking`)
- Completion (proto syntax, imports)
- Diagnostics (lint violations, syntax errors)

### Performance

- **Memory**: 50-200 MB
- **Startup**: <2 seconds

---

## YAML: yaml-language-server

Red Hat's YAML language server with JSON Schema support.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g yaml-language-server` |
| Arch/Manjaro | `pacman -S yaml-language-server` |
| macOS | `brew install yaml-language-server` |

### Binary

`yaml-language-server --stdio`

### Configuration

```json
{
  "yaml": {
    "schemas": {
      "https://json.schemastore.org/github-workflow.json": "/.github/workflows/*",
      "https://json.schemastore.org/docker-compose.json": "/docker-compose*.yml",
      "https://json.schemastore.org/chart.json": "/Chart.yaml",
      "https://json.schemastore.org/kustomization.json": "/kustomization.yaml",
      "kubernetes": "/k8s/**/*.yaml"
    },
    "validate": true,
    "completion": true,
    "hover": true,
    "format": {
      "enable": true,
      "singleQuote": false,
      "bracketSpacing": true
    }
  }
}
```

### Capabilities

- Completion (schema-aware)
- Diagnostics (schema validation, syntax errors)
- Hover (schema documentation)
- Formatting
- Document symbols
- Custom schema association

### Performance

- **Memory**: 50-150 MB
- **Startup**: <2 seconds

### Known Issues

- Some schemas can be slow to download on first use.
- Custom schema associations may need manual configuration per project.

---

## JSON: vscode-json-language-server

Part of `vscode-langservers-extracted`. Provides JSON schema validation and completion.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g vscode-langservers-extracted` |

### Binary

`vscode-json-language-server --stdio`

### Configuration

```json
{
  "json": {
    "schemas": [
      {
        "fileMatch": ["package.json"],
        "url": "https://json.schemastore.org/package.json"
      },
      {
        "fileMatch": ["tsconfig*.json"],
        "url": "https://json.schemastore.org/tsconfig.json"
      }
    ],
    "validate": { "enable": true },
    "format": { "enable": true }
  }
}
```

### Capabilities

- Completion (schema-aware)
- Diagnostics (schema validation, syntax errors)
- Formatting
- Hover (schema documentation)
- Document symbols

### Performance

- **Memory**: 30-80 MB
- **Startup**: <1 second

---

## Docker: docker-langserver

Language server for Dockerfiles.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g dockerfile-language-server-nodejs` |

### Binary

`docker-langserver --stdio`

### Capabilities

- Completion (Dockerfile directives, image names)
- Diagnostics (syntax errors, best practice warnings)
- Hover (directive documentation)
- Formatting

### Performance

- **Memory**: 30-60 MB
- **Startup**: <1 second

---

## HTML: vscode-html-language-server

Part of `vscode-langservers-extracted`.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g vscode-langservers-extracted` |

### Binary

`vscode-html-language-server --stdio`

### Capabilities

- Completion (tags, attributes, attribute values, entities)
- Diagnostics (syntax errors)
- Formatting (via js-beautify)
- Hover (MDN documentation)
- Document links
- Embedded CSS/JS support

### Performance

- **Memory**: 30-80 MB
- **Startup**: <1 second

---

## CSS: vscode-css-language-server

Part of `vscode-langservers-extracted`. Handles CSS, SCSS, and Less.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g vscode-langservers-extracted` |

### Binary

`vscode-css-language-server --stdio`

### Capabilities

- Completion (properties, values, selectors)
- Diagnostics (syntax errors, unknown properties)
- Hover (MDN documentation)
- Color decorators
- Document symbols
- Go to definition (custom properties)

### Performance

- **Memory**: 30-80 MB
- **Startup**: <1 second

---

## Tailwind CSS: tailwindcss-language-server

Tailwind CSS IntelliSense for completions, hover, and diagnostics.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g @tailwindcss/language-server` |

### Binary

`tailwindcss-language-server --stdio`

### Configuration

Requires a `tailwind.config.js` / `tailwind.config.ts` in the project root.

```json
{
  "tailwindCSS": {
    "validate": true,
    "classAttributes": ["class", "className", "ngClass"],
    "lint": {
      "cssConflict": "warning",
      "invalidApply": "error",
      "invalidConfigPath": "error",
      "invalidScreen": "error",
      "invalidTailwindDirective": "error",
      "invalidVariant": "error"
    }
  }
}
```

### Capabilities

- Completion (class names with preview)
- Diagnostics (invalid classes, CSS conflicts)
- Hover (generated CSS for each class)
- Color decorators

### Performance

- **Memory**: 80-200 MB
- **Startup**: 1-3 seconds (reads tailwind config)

---

## Bash: bash-language-server

Language server for Bash/Shell scripts, powered by Tree-sitter and ShellCheck.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g bash-language-server` |
| Arch/Manjaro | `pacman -S bash-language-server` |

**Recommended**: Install `shellcheck` alongside for better diagnostics.

### Binary

`bash-language-server start`

### Capabilities

- Completion (commands, variables, functions)
- Diagnostics (ShellCheck integration)
- Hover (man page excerpts)
- Go to definition (functions, variables)
- Find references
- Document symbols
- Rename

### Performance

- **Memory**: 30-80 MB
- **Startup**: <1 second

---

## SQL: sqls

Language server for SQL with database connection support.

### Installation

| Method | Command |
|--------|---------|
| go install | `go install github.com/sqls-server/sqls@latest` |

### Binary

`sqls`

### Configuration

`sqls` can connect to databases for schema-aware completion:

```json
{
  "sqls": {
    "connections": [
      {
        "driver": "postgresql",
        "dataSourceName": "host=127.0.0.1 port=5432 user=postgres dbname=mydb sslmode=disable"
      }
    ]
  }
}
```

### Capabilities

- Completion (keywords, table/column names from connected DB)
- Diagnostics (basic SQL syntax)
- Formatting
- Hover (table/column information)

### Performance

- **Memory**: 20-60 MB
- **Startup**: <1 second (longer if connecting to database)

---

## Lua: lua-language-server

The standard Lua language server (LuaLS/sumneko_lua).

### Installation

| Method | Command |
|--------|---------|
| Arch/Manjaro | `pacman -S lua-language-server` |
| macOS | `brew install lua-language-server` |
| Binary | https://github.com/LuaLS/lua-language-server/releases |

### Binary

`lua-language-server`

### Configuration

```json
{
  "Lua": {
    "runtime": { "version": "LuaJIT" },
    "workspace": {
      "library": [],
      "checkThirdParty": false
    },
    "diagnostics": {
      "globals": ["vim"]
    },
    "telemetry": { "enable": false }
  }
}
```

### Capabilities

- Completion (type-aware with EmmyLua annotations)
- Diagnostics (type errors, unused variables, style)
- Formatting
- Hover (type information, documentation)
- Go to definition
- Find references
- Rename
- Inlay hints
- Semantic tokens

### Performance

- **Memory**: 80-300 MB
- **Startup**: 1-5 seconds

### Known Issues

- Neovim plugin authors: add `vim` to `diagnostics.globals` to suppress false positives.
- Large Lua projects with many require paths can cause slow indexing.

---

## Markdown: marksman

Language server for Markdown with cross-file link support.

### Installation

| Method | Command |
|--------|---------|
| Arch/Manjaro | `yay -S marksman-bin` |
| macOS | `brew install marksman` |
| Binary | https://github.com/artempyanykh/marksman/releases |

### Binary

`marksman server`

### Capabilities

- Completion (headings, links, references)
- Diagnostics (broken links)
- Go to definition (cross-file links)
- Document symbols (headings)
- Workspace symbols
- Rename (headings, links)
- Code actions (create missing file for broken link)

### Performance

- **Memory**: 20-50 MB
- **Startup**: <1 second

---

## TOML: taplo

TOML language server with schema support.

### Installation

| Method | Command |
|--------|---------|
| cargo | `cargo install taplo-cli --locked` |
| Arch/Manjaro | `pacman -S taplo-cli` |
| macOS | `brew install taplo` |
| npm | `npm i -g @taplo/cli` |

### Binary

`taplo lsp stdio`

### Capabilities

- Completion (schema-aware)
- Diagnostics (syntax errors, schema validation)
- Formatting
- Hover (schema documentation)
- Semantic tokens

### Performance

- **Memory**: 20-50 MB
- **Startup**: <1 second

---

## Zig: zls

Official Zig language server.

### Installation

| Method | Command |
|--------|---------|
| Binary | https://github.com/zigtools/zls/releases |
| Arch/Manjaro | `pacman -S zls` |

### Binary

`zls`

### Capabilities

- Completion
- Diagnostics
- Formatting
- Hover
- Go to definition
- Find references
- Inlay hints
- Semantic tokens

### Performance

- **Memory**: 100-400 MB
- **Startup**: 1-3 seconds

---

## Nix: nil

Language server for Nix expressions.

### Installation

| Method | Command |
|--------|---------|
| nix | `nix profile install nixpkgs#nil` |
| cargo | `cargo install nil` |

### Binary

`nil`

### Capabilities

- Completion (attributes, builtins, paths)
- Diagnostics (syntax errors, unused bindings)
- Formatting (via nixpkgs-fmt or alejandra)
- Go to definition
- Find references
- Rename

### Performance

- **Memory**: 50-150 MB
- **Startup**: <2 seconds

---

## Terraform: terraform-ls

HashiCorp's official Terraform language server.

### Installation

| Method | Command |
|--------|---------|
| Arch/Manjaro | `yay -S terraform-ls` |
| macOS | `brew install hashicorp/tap/terraform-ls` |
| Binary | https://releases.hashicorp.com/terraform-ls/ |

### Binary

`terraform-ls serve`

### Capabilities

- Completion (providers, resources, attributes, modules)
- Diagnostics (HCL syntax, provider schema validation)
- Hover (attribute documentation)
- Formatting
- Go to definition
- Find references
- Semantic tokens

### Performance

- **Memory**: 100-500 MB (downloads provider schemas)
- **Startup**: 2-10 seconds (provider schema initialization)

### Known Issues

- Requires `terraform` CLI installed for provider schema download.
- Large state files can slow diagnostics.

---

## GraphQL: graphql-lsp

Language server for GraphQL schemas and queries.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g graphql-language-service-cli` |

### Binary

`graphql-lsp server -m stream`

### Capabilities

- Completion (types, fields, arguments, directives)
- Diagnostics (query validation against schema)
- Hover (type documentation)
- Go to definition
- Find references

### Performance

- **Memory**: 50-150 MB
- **Startup**: 1-3 seconds (schema parsing)

---

## Go Templ: templ

Language server for Go templ files (HTML templates in Go).

### Installation

| Method | Command |
|--------|---------|
| go install | `go install github.com/a-h/templ/cmd/templ@latest` |

### Binary

`templ lsp`

### Capabilities

- Completion (Go expressions, HTML elements, templ syntax)
- Diagnostics (syntax errors)
- Formatting
- Go to definition (Go expressions)
- Embedded HTML/CSS support (delegates to html/css LSP)

### Performance

- **Memory**: 50-150 MB
- **Startup**: 1-3 seconds

---

## GitHub Actions: actionlint

Linter for GitHub Actions workflow files. Not a full LSP but integrates with efm-langserver.

### Installation

| Method | Command |
|--------|---------|
| go install | `go install github.com/rhysd/actionlint/cmd/actionlint@latest` |
| Arch/Manjaro | `yay -S actionlint` |
| macOS | `brew install actionlint` |

### Binary

`actionlint` (CLI linter, not an LSP server directly)

### Integration

Use with efm-langserver or diagnostic-languageserver:

```yaml
# efm-langserver config
languages:
  yaml:
    - lintCommand: "actionlint -stdin-filename ${INPUT} -"
      lintStdin: true
      lintFormats:
        - "%f:%l:%c: %m"
      rootMarkers:
        - ".github/workflows/"
```

---

## Biome: biome

Unified formatter and linter for JavaScript, TypeScript, JSON, and CSS.

### Installation

| Method | Command |
|--------|---------|
| npm | `npm i -g @biomejs/biome` |
| Arch/Manjaro | `yay -S biome` |
| macOS | `brew install biome` |

### Binary

`biome lsp-proxy`

### Capabilities

- Formatting (JS, TS, JSON, CSS)
- Diagnostics (lint rules, a11y, correctness, style)
- Code actions (auto-fix)

### Performance

- **Memory**: 50-150 MB
- **Startup**: <1 second
- **Note**: Extremely fast -- written in Rust, replaces eslint + prettier

---

## Meta-LSP: efm-langserver

General-purpose LSP that runs external linters and formatters.

### Installation

| Method | Command |
|--------|---------|
| go install | `go install github.com/mattn/efm-langserver@latest` |
| Arch/Manjaro | `yay -S efm-langserver` |
| macOS | `brew install efm-langserver` |

### Binary

`efm-langserver`

### Configuration

`~/.config/efm-langserver/config.yaml`:

```yaml
version: 2
tools:
  shellcheck: &shellcheck
    lint-command: "shellcheck -f gcc -x"
    lint-source: "shellcheck"
    lint-formats:
      - "%f:%l:%c: %t%*[^:]: %m"

  hadolint: &hadolint
    lint-command: "hadolint"
    lint-formats:
      - "%f:%l %m"

  markdownlint: &markdownlint
    lint-command: "markdownlint -s"
    lint-stdin: true
    lint-formats:
      - "%f:%l %m"
      - "%f:%l:%c %m"

languages:
  sh:
    - <<: *shellcheck
  dockerfile:
    - <<: *hadolint
  markdown:
    - <<: *markdownlint
```

### Capabilities

- Diagnostics (aggregated from external linters)
- Formatting (via external formatters)
- Code actions (if linter provides fix suggestions)

### Performance

- **Memory**: 20-50 MB
- **Startup**: <1 second

### Use Case

efm-langserver fills gaps where dedicated LSP servers do not exist or where you want additional linting from tools like shellcheck, hadolint, actionlint, markdownlint, and vale.
