# Editor Configuration Templates

Complete LSP configuration templates for all major editors. Each config targets a typical polyglot stack: Go + Proto + YAML + Docker + HTML + Shell + SQL + Markdown.

Adapt these templates by removing servers for languages not in your project and adding servers for languages that are.

---

## Neovim: nvim-lspconfig (Native LSP)

This is the standard configuration using the `nvim-lspconfig` plugin. Place in your Neovim config (typically `~/.config/nvim/init.lua` or a dedicated `lsp.lua` file).

### Prerequisites

```lua
-- lazy.nvim plugin spec
{
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
  },
}
```

### Full Configuration

```lua
local lspconfig = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Shared on_attach for keymaps
local on_attach = function(client, bufnr)
  local opts = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)

  -- Inlay hints (Neovim 0.10+)
  if client.supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
  end
end

-- Go
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
      },
      directoryFilters = { "-node_modules", "-vendor", "-.git" },
    },
  },
})

-- Templ (Go HTML templates)
lspconfig.templ.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- YAML
lspconfig.yamlls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    yaml = {
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        ["https://json.schemastore.org/docker-compose.json"] = "/docker-compose*.yml",
        ["https://json.schemastore.org/chart.json"] = "/Chart.yaml",
        ["https://json.schemastore.org/kustomization.json"] = "/kustomization.yaml",
      },
      validate = true,
      completion = true,
      hover = true,
    },
  },
})

-- JSON
lspconfig.jsonls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    json = {
      schemas = require('schemastore').schemas(),  -- optional: nvim-schemastore plugin
      validate = { enable = true },
    },
  },
})

-- Docker
lspconfig.dockerls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- HTML
lspconfig.html.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "html", "templ" },
})

-- CSS
lspconfig.cssls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Bash
lspconfig.bashls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  filetypes = { "sh", "bash", "zsh" },
})

-- SQL
lspconfig.sqls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Markdown
lspconfig.marksman.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- Buf (Proto)
lspconfig.bufls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

-- efm-langserver (additional linters)
lspconfig.efm.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  init_options = { documentFormatting = true },
  filetypes = { "sh", "dockerfile", "markdown", "yaml" },
  settings = {
    rootMarkers = { ".git/" },
    languages = {
      sh = {
        {
          lintCommand = "shellcheck -f gcc -x",
          lintSource = "shellcheck",
          lintFormats = { "%f:%l:%c: %t%*[^:]: %m" },
        },
      },
      dockerfile = {
        {
          lintCommand = "hadolint",
          lintFormats = { "%f:%l %m" },
        },
      },
    },
  },
})

-- Diagnostic configuration
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = "~" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
})
```

---

## Neovim: mason.nvim (Auto-Install)

mason.nvim automatically installs LSP servers. This is easier to maintain but less transparent.

### Prerequisites

```lua
-- lazy.nvim plugin spec
{
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "neovim/nvim-lspconfig",
  },
}
```

### Configuration

```lua
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "gopls",
    "templ",
    "yamlls",
    "jsonls",
    "dockerls",
    "html",
    "cssls",
    "bashls",
    "sqls",
    "marksman",
    "bufls",
    "efm",
    -- Add more as needed:
    -- "pyright",
    -- "ruff",
    -- "rust_analyzer",
    -- "ts_ls",
    -- "tailwindcss",
    -- "lua_ls",
    -- "taplo",
    -- "terraformls",
  },
  automatic_installation = true,
})

-- After mason installs servers, configure them via lspconfig
-- (use the same lspconfig.*.setup({}) calls as above)
require("mason-lspconfig").setup_handlers({
  function(server_name)
    require("lspconfig")[server_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end,
  -- Override specific servers with custom settings
  ["gopls"] = function()
    require("lspconfig").gopls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        gopls = {
          staticcheck = true,
          gofumpt = true,
          -- ... (same settings as above)
        },
      },
    })
  end,
})
```

---

## VS Code (settings.json)

Place in `.vscode/settings.json` at the project root, or in your user settings.

### Configuration

```json
{
  "editor.formatOnSave": true,
  "editor.inlayHints.enabled": "on",
  "editor.codeLens": true,

  "[go]": {
    "editor.defaultFormatter": "golang.go",
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },
  "go.lintTool": "staticcheck",
  "go.lintFlags": [],
  "go.useLanguageServer": true,
  "gopls": {
    "ui.semanticTokens": true,
    "ui.completion.usePlaceholders": true,
    "formatting.gofumpt": true,
    "ui.diagnostic.staticcheck": true,
    "ui.diagnostic.analyses": {
      "unusedparams": true,
      "shadow": true,
      "nilness": true,
      "unusedwrite": true,
      "unusedvariable": true
    },
    "ui.inlayhint.hints": {
      "assignVariableTypes": true,
      "compositeLiteralFields": true,
      "functionTypeParameters": true,
      "parameterNames": true,
      "rangeVariableTypes": true
    }
  },

  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "yaml.schemas": {
    "https://json.schemastore.org/github-workflow.json": "/.github/workflows/*",
    "https://json.schemastore.org/docker-compose.json": "/docker-compose*.yml"
  },

  "[json][jsonc]": {
    "editor.defaultFormatter": "vscode.json-language-features"
  },

  "[dockerfile]": {
    "editor.defaultFormatter": "ms-azuretools.vscode-docker"
  },

  "[html]": {
    "editor.defaultFormatter": "vscode.html-language-features"
  },

  "[css][scss][less]": {
    "editor.defaultFormatter": "vscode.css-language-features"
  },

  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format"
  },

  "[sql]": {
    "editor.defaultFormatter": "mtxr.sqltools"
  },

  "[markdown]": {
    "editor.defaultFormatter": "DavidAnson.vscode-markdownlint"
  },

  "[proto3]": {
    "editor.defaultFormatter": "bufbuild.vscode-buf"
  },

  "files.associations": {
    "*.tmpl": "html",
    "*.templ": "templ",
    "Dockerfile.*": "dockerfile",
    "docker-compose*.yml": "dockercompose"
  },

  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/vendor": true,
    "**/__pycache__": true
  }
}
```

### Recommended Extensions

```json
{
  "recommendations": [
    "golang.go",
    "redhat.vscode-yaml",
    "ms-azuretools.vscode-docker",
    "foxundermoon.shell-format",
    "bufbuild.vscode-buf",
    "DavidAnson.vscode-markdownlint",
    "timonwong.shellcheck",
    "mtxr.sqltools"
  ]
}
```

---

## Helix (languages.toml)

Place at `~/.config/helix/languages.toml` or at `<project>/.helix/languages.toml` for project-specific config.

### Configuration

```toml
# Go
[[language]]
name = "go"
auto-format = true
language-servers = ["gopls"]
formatter = { command = "gofumpt" }

[language-server.gopls]
command = "gopls"
args = ["serve"]

[language-server.gopls.config]
hints.assignVariableTypes = true
hints.compositeLiteralFields = true
hints.functionTypeParameters = true
hints.parameterNames = true
hints.rangeVariableTypes = true
gofumpt = true
staticcheck = true
analyses.unusedparams = true
analyses.shadow = true
analyses.nilness = true
analyses.unusedvariable = true

# Templ
[[language]]
name = "templ"
auto-format = true
language-servers = ["templ"]

[language-server.templ]
command = "templ"
args = ["lsp"]

# Proto
[[language]]
name = "protobuf"
auto-format = true
language-servers = ["buf"]
formatter = { command = "buf", args = ["format", "-w"] }

[language-server.buf]
command = "buf"
args = ["beta", "lsp"]

# YAML
[[language]]
name = "yaml"
auto-format = true
language-servers = ["yaml-language-server"]

[language-server.yaml-language-server]
command = "yaml-language-server"
args = ["--stdio"]

[language-server.yaml-language-server.config.yaml]
validation = true
completion = true
schemas = { "https://json.schemastore.org/github-workflow.json" = "/.github/workflows/*" }

# JSON
[[language]]
name = "json"
auto-format = true
language-servers = ["vscode-json-language-server"]

[language-server.vscode-json-language-server]
command = "vscode-json-language-server"
args = ["--stdio"]

# Docker
[[language]]
name = "dockerfile"
auto-format = true
language-servers = ["docker-langserver"]

[language-server.docker-langserver]
command = "docker-langserver"
args = ["--stdio"]

# HTML
[[language]]
name = "html"
auto-format = true
language-servers = ["vscode-html-language-server"]

[language-server.vscode-html-language-server]
command = "vscode-html-language-server"
args = ["--stdio"]

# CSS
[[language]]
name = "css"
auto-format = true
language-servers = ["vscode-css-language-server"]

[language-server.vscode-css-language-server]
command = "vscode-css-language-server"
args = ["--stdio"]

# Bash
[[language]]
name = "bash"
auto-format = true
language-servers = ["bash-language-server"]

[language-server.bash-language-server]
command = "bash-language-server"
args = ["start"]

# SQL
[[language]]
name = "sql"
auto-format = true
language-servers = ["sqls"]

[language-server.sqls]
command = "sqls"

# Markdown
[[language]]
name = "markdown"
auto-format = false
language-servers = ["marksman"]

[language-server.marksman]
command = "marksman"
args = ["server"]

# TOML
[[language]]
name = "toml"
auto-format = true
language-servers = ["taplo"]

[language-server.taplo]
command = "taplo"
args = ["lsp", "stdio"]
```

---

## Zed (settings.json)

Place in `~/.config/zed/settings.json` or project-level `.zed/settings.json`.

### Configuration

```json
{
  "lsp": {
    "gopls": {
      "binary": {
        "path": "gopls",
        "arguments": ["serve"]
      },
      "initialization_options": {
        "hints": {
          "assignVariableTypes": true,
          "compositeLiteralFields": true,
          "functionTypeParameters": true,
          "parameterNames": true
        },
        "gofumpt": true,
        "staticcheck": true,
        "analyses": {
          "unusedparams": true,
          "shadow": true,
          "nilness": true
        }
      }
    },
    "yaml-language-server": {
      "binary": {
        "path": "yaml-language-server",
        "arguments": ["--stdio"]
      },
      "settings": {
        "yaml": {
          "schemas": {
            "https://json.schemastore.org/github-workflow.json": "/.github/workflows/*"
          }
        }
      }
    },
    "docker-langserver": {
      "binary": {
        "path": "docker-langserver",
        "arguments": ["--stdio"]
      }
    },
    "bash-language-server": {
      "binary": {
        "path": "bash-language-server",
        "arguments": ["start"]
      }
    }
  },
  "languages": {
    "Go": {
      "tab_size": 4,
      "hard_tabs": true,
      "format_on_save": "on"
    },
    "YAML": {
      "tab_size": 2,
      "format_on_save": "on"
    },
    "JSON": {
      "tab_size": 2,
      "format_on_save": "on"
    },
    "Shell Script": {
      "tab_size": 2,
      "format_on_save": "on"
    },
    "Markdown": {
      "format_on_save": "off"
    }
  }
}
```

---

## Emacs: lsp-mode

For Emacs users with `lsp-mode`. Place in `init.el` or equivalent.

### Configuration

```elisp
;; Package installation (use-package)
(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((go-mode . lsp-deferred)
         (yaml-mode . lsp-deferred)
         (json-mode . lsp-deferred)
         (dockerfile-mode . lsp-deferred)
         (html-mode . lsp-deferred)
         (css-mode . lsp-deferred)
         (sh-mode . lsp-deferred)
         (sql-mode . lsp-deferred)
         (markdown-mode . lsp-deferred)
         (protobuf-mode . lsp-deferred))
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq lsp-idle-delay 0.5
        lsp-enable-symbol-highlighting t
        lsp-enable-snippet t
        lsp-enable-indentation t
        lsp-enable-on-type-formatting nil
        lsp-headerline-breadcrumb-enable t
        lsp-modeline-diagnostics-enable t
        lsp-inlay-hint-enable t))

(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-show-with-cursor t
        lsp-ui-sideline-enable t
        lsp-ui-sideline-show-diagnostics t
        lsp-ui-sideline-show-code-actions t))

;; Go
(use-package go-mode
  :ensure t
  :hook (go-mode . lsp-deferred)
  :config
  (setq lsp-go-analyses '((unusedparams . t)
                           (shadow . t)
                           (nilness . t)
                           (unusedwrite . t)
                           (unusedvariable . t))
        lsp-go-use-gofumpt t
        lsp-go-codelens '((gc_details . t)
                          (generate . t)
                          (test . t)
                          (tidy . t))))

;; YAML
(use-package yaml-mode
  :ensure t
  :hook (yaml-mode . lsp-deferred))

;; Docker
(use-package dockerfile-mode
  :ensure t
  :hook (dockerfile-mode . lsp-deferred))

;; Shell
(add-hook 'sh-mode-hook #'lsp-deferred)

;; Markdown
(use-package markdown-mode
  :ensure t
  :hook (markdown-mode . lsp-deferred))
```

### eglot (Built-in, Emacs 29+)

```elisp
;; eglot is built into Emacs 29+
(use-package eglot
  :ensure nil
  :hook ((go-mode . eglot-ensure)
         (yaml-mode . eglot-ensure)
         (json-mode . eglot-ensure)
         (dockerfile-mode . eglot-ensure)
         (html-mode . eglot-ensure)
         (css-mode . eglot-ensure)
         (sh-mode . eglot-ensure)
         (sql-mode . eglot-ensure)
         (markdown-mode . eglot-ensure)
         (protobuf-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '(go-mode . ("gopls" "serve")))
  (add-to-list 'eglot-server-programs '(yaml-mode . ("yaml-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs '(dockerfile-mode . ("docker-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs '(sh-mode . ("bash-language-server" "start")))
  (add-to-list 'eglot-server-programs '(sql-mode . ("sqls")))
  (add-to-list 'eglot-server-programs '(markdown-mode . ("marksman" "server")))
  (add-to-list 'eglot-server-programs '(protobuf-mode . ("buf" "beta" "lsp")))

  (setq eglot-autoshutdown t
        eglot-confirm-server-initiated-edits nil))
```

---

## Kakoune: kak-lsp

Place in `~/.config/kak-lsp/kak-lsp.toml`.

### Configuration

```toml
snippet_support = true
verbosity = 2

[server]
timeout = 1800

[language.go]
filetypes = ["go"]
roots = ["go.mod", ".git"]
command = "gopls"
args = ["serve"]
settings_section = "gopls"

[language.go.settings.gopls]
gofumpt = true
staticcheck = true
usePlaceholders = true
"analyses.unusedparams" = true
"analyses.shadow" = true
"hints.assignVariableTypes" = true
"hints.parameterNames" = true

[language.yaml]
filetypes = ["yaml"]
roots = [".git"]
command = "yaml-language-server"
args = ["--stdio"]
settings_section = "yaml"

[language.yaml.settings.yaml]
validation = true
completion = true

[language.json]
filetypes = ["json"]
roots = [".git"]
command = "vscode-json-language-server"
args = ["--stdio"]

[language.dockerfile]
filetypes = ["dockerfile"]
roots = ["Dockerfile", ".git"]
command = "docker-langserver"
args = ["--stdio"]

[language.html]
filetypes = ["html"]
roots = [".git"]
command = "vscode-html-language-server"
args = ["--stdio"]

[language.css]
filetypes = ["css", "scss", "less"]
roots = [".git"]
command = "vscode-css-language-server"
args = ["--stdio"]

[language.sh]
filetypes = ["sh"]
roots = [".git"]
command = "bash-language-server"
args = ["start"]

[language.sql]
filetypes = ["sql"]
roots = [".git"]
command = "sqls"

[language.markdown]
filetypes = ["markdown"]
roots = [".git"]
command = "marksman"
args = ["server"]

[language.protobuf]
filetypes = ["protobuf"]
roots = ["buf.yaml", ".git"]
command = "buf"
args = ["beta", "lsp"]

[language.toml]
filetypes = ["toml"]
roots = [".git"]
command = "taplo"
args = ["lsp", "stdio"]
```

### kakrc additions

```kak
eval %sh{kak-lsp --kakoune -s $kak_session}
lsp-enable

hook global WinSetOption filetype=(go|yaml|json|dockerfile|html|css|sh|sql|markdown|protobuf|toml) %{
    lsp-enable-window
}

map global user l ':enter-user-mode lsp<ret>' -docstring "LSP"
map global lsp a ':lsp-code-actions<ret>' -docstring "code actions"
map global lsp d ':lsp-diagnostics<ret>' -docstring "diagnostics"
map global lsp f ':lsp-formatting<ret>' -docstring "format"
map global lsp h ':lsp-hover<ret>' -docstring "hover"
map global lsp r ':lsp-rename-prompt<ret>' -docstring "rename"
map global lsp R ':lsp-references<ret>' -docstring "references"
```

---

## Claude Code (.claude/settings.json)

Claude Code supports LSP integration to provide language context during coding sessions.

### Configuration

Place in `.claude/settings.json` at the project root:

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
            "shadow": true
          }
        }
      }
    },
    "typescript-language-server": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "languages": ["typescript", "javascript", "typescriptreact", "javascriptreact"]
    },
    "yaml-language-server": {
      "command": "yaml-language-server",
      "args": ["--stdio"],
      "languages": ["yaml"],
      "settings": {
        "yaml": {
          "schemas": {
            "https://json.schemastore.org/github-workflow.json": "/.github/workflows/*"
          }
        }
      }
    },
    "bash-language-server": {
      "command": "bash-language-server",
      "args": ["start"],
      "languages": ["shellscript", "bash"]
    },
    "docker-langserver": {
      "command": "docker-langserver",
      "args": ["--stdio"],
      "languages": ["dockerfile"]
    },
    "pyright": {
      "command": "pyright-langserver",
      "args": ["--stdio"],
      "languages": ["python"]
    },
    "ruff": {
      "command": "ruff",
      "args": ["server"],
      "languages": ["python"]
    },
    "rust-analyzer": {
      "command": "rust-analyzer",
      "args": [],
      "languages": ["rust"]
    }
  }
}
```

This gives Claude Code access to diagnostics, completions, and type information from each configured LSP server, improving the quality of AI-assisted coding for the project.
