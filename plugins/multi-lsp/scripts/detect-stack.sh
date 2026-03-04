#!/usr/bin/env bash
#
# detect-stack.sh — Scan current directory for language markers and report
# required LSP servers, installed status, and install commands.
#
# Usage: detect-stack.sh [directory]
#   directory: path to scan (defaults to current directory)
#
# Output: structured report of detected languages, servers, and status.

set -euo pipefail

# --- Configuration ---

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Colors (disable if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# --- Counters ---
detected_count=0
installed_count=0
missing_count=0

# --- Detection arrays ---
declare -a detected_languages=()
declare -a required_servers=()
declare -a server_install_cmds=()
declare -a server_status=()

# --- Helper functions ---

log_header() {
    echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}\n"
}

log_detected() {
    local lang="$1"
    local marker="$2"
    echo -e "  ${GREEN}[+]${NC} ${BOLD}$lang${NC} (found: $marker)"
    detected_count=$((detected_count + 1))
}

log_not_detected() {
    local lang="$1"
    echo -e "  ${YELLOW}[-]${NC} $lang: not detected"
}

add_server() {
    local server="$1"
    local install_cmd="$2"

    # Check if already added
    for existing in "${required_servers[@]:-}"; do
        if [ "$existing" = "$server" ]; then
            return
        fi
    done

    required_servers+=("$server")
    server_install_cmds+=("$install_cmd")

    if command -v "$server" &>/dev/null; then
        server_status+=("installed")
        installed_count=$((installed_count + 1))
    else
        server_status+=("missing")
        missing_count=$((missing_count + 1))
    fi
}

has_file() {
    [ -f "$TARGET_DIR/$1" ]
}

has_glob() {
    compgen -G "$TARGET_DIR/$1" >/dev/null 2>&1
}

has_glob_recursive() {
    find "$TARGET_DIR" -maxdepth 3 -name "$1" -print -quit 2>/dev/null | grep -q .
}

# --- Main Detection ---

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        Multi-LSP Stack Detector          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Scanning: ${BOLD}$TARGET_DIR${NC}"

log_header "Phase 1: Language Detection"

# Go
if has_file "go.mod"; then
    log_detected "Go" "go.mod"
    detected_languages+=("go")
    add_server "gopls" "go install golang.org/x/tools/gopls@latest"
else
    log_not_detected "Go"
fi

# JavaScript / TypeScript
if has_file "package.json"; then
    if has_file "tsconfig.json" || has_file "tsconfig.base.json"; then
        log_detected "TypeScript" "package.json + tsconfig.json"
        detected_languages+=("typescript")
    else
        log_detected "JavaScript" "package.json"
        detected_languages+=("javascript")
    fi

    # Check for deno (overrides typescript-language-server)
    if has_file "deno.json" || has_file "deno.jsonc"; then
        log_detected "Deno" "deno.json"
        detected_languages+=("deno")
        add_server "deno" "curl -fsSL https://deno.land/install.sh | sh"
    else
        add_server "typescript-language-server" "npm i -g typescript-language-server typescript"
    fi
elif has_file "deno.json" || has_file "deno.jsonc"; then
    log_detected "Deno" "deno.json"
    detected_languages+=("deno")
    add_server "deno" "curl -fsSL https://deno.land/install.sh | sh"
fi

# Rust
if has_file "Cargo.toml"; then
    log_detected "Rust" "Cargo.toml"
    detected_languages+=("rust")
    add_server "rust-analyzer" "rustup component add rust-analyzer"
fi

# Python
if has_file "pyproject.toml" || has_file "setup.py" || has_file "requirements.txt" || has_file "setup.cfg"; then
    local_marker=""
    has_file "pyproject.toml" && local_marker="pyproject.toml"
    has_file "setup.py" && local_marker="setup.py"
    has_file "requirements.txt" && local_marker="requirements.txt"
    log_detected "Python" "$local_marker"
    detected_languages+=("python")
    add_server "pyright-langserver" "pip install pyright"
    add_server "ruff" "pip install ruff"
else
    log_not_detected "Python"
fi

# Protocol Buffers
if has_glob_recursive "*.proto" || has_file "buf.yaml" || has_file "buf.gen.yaml"; then
    local_marker=""
    has_file "buf.yaml" && local_marker="buf.yaml"
    has_glob_recursive "*.proto" && local_marker="*.proto files"
    log_detected "Protocol Buffers" "$local_marker"
    detected_languages+=("proto")
    add_server "buf" "go install github.com/bufbuild/buf/cmd/buf@latest"
fi

# Docker
if has_file "Dockerfile" || has_file "compose.yaml" || has_file "docker-compose.yml" || has_file "docker-compose.yaml"; then
    local_marker=""
    has_file "Dockerfile" && local_marker="Dockerfile"
    has_file "compose.yaml" && local_marker="compose.yaml"
    has_file "docker-compose.yml" && local_marker="docker-compose.yml"
    log_detected "Docker" "$local_marker"
    detected_languages+=("docker")
    add_server "docker-langserver" "npm i -g dockerfile-language-server-nodejs"
fi

# YAML
if has_glob "*.yaml" || has_glob "*.yml"; then
    log_detected "YAML" "*.yaml/*.yml files"
    detected_languages+=("yaml")
    add_server "yaml-language-server" "npm i -g yaml-language-server"
fi

# JSON (only if non-trivial JSON files beyond package.json)
json_count=$(find "$TARGET_DIR" -maxdepth 2 -name "*.json" ! -name "package.json" ! -name "package-lock.json" ! -name "tsconfig.json" 2>/dev/null | head -5 | wc -l)
if [ "$json_count" -gt 0 ]; then
    log_detected "JSON" "*.json files"
    detected_languages+=("json")
    add_server "vscode-json-language-server" "npm i -g vscode-langservers-extracted"
fi

# TOML
if has_glob "*.toml" && ! has_file "Cargo.toml"; then
    log_detected "TOML" "*.toml files"
    detected_languages+=("toml")
    add_server "taplo" "cargo install taplo-cli --locked"
elif has_file "Cargo.toml"; then
    # Rust projects always have Cargo.toml, add taplo for general TOML support
    log_detected "TOML" "Cargo.toml (Rust project)"
    detected_languages+=("toml")
    add_server "taplo" "cargo install taplo-cli --locked"
fi

# Markdown
if has_glob "*.md" || has_glob_recursive "*.md"; then
    log_detected "Markdown" "*.md files"
    detected_languages+=("markdown")
    add_server "marksman" "gh release download -R artempyanykh/marksman -p marksman-linux-x64 -O ~/.local/bin/marksman && chmod +x ~/.local/bin/marksman"
fi

# SQL
if has_glob_recursive "*.sql"; then
    log_detected "SQL" "*.sql files"
    detected_languages+=("sql")
    add_server "sqls" "go install github.com/sqls-server/sqls@latest"
fi

# HTML
if has_glob_recursive "*.html"; then
    log_detected "HTML" "*.html files"
    detected_languages+=("html")
    add_server "vscode-html-language-server" "npm i -g vscode-langservers-extracted"
fi

# CSS
if has_glob_recursive "*.css" || has_glob_recursive "*.scss" || has_glob_recursive "*.less"; then
    log_detected "CSS" "*.css/*.scss/*.less files"
    detected_languages+=("css")
    add_server "vscode-css-language-server" "npm i -g vscode-langservers-extracted"
fi

# Lua
if has_glob_recursive "*.lua"; then
    log_detected "Lua" "*.lua files"
    detected_languages+=("lua")
    add_server "lua-language-server" "pacman -S lua-language-server (Arch) / brew install lua-language-server (macOS)"
fi

# Shell
if has_glob "*.sh" || has_glob "*.bash" || has_glob_recursive "*.sh"; then
    log_detected "Shell" "*.sh/*.bash files"
    detected_languages+=("shell")
    add_server "bash-language-server" "npm i -g bash-language-server"
fi

# Zig
if has_glob_recursive "*.zig" || has_file "build.zig"; then
    log_detected "Zig" "*.zig files"
    detected_languages+=("zig")
    add_server "zls" "download from https://github.com/zigtools/zls/releases"
fi

# Nix
if has_glob "*.nix" || has_file "flake.nix"; then
    log_detected "Nix" "*.nix files"
    detected_languages+=("nix")
    add_server "nil" "nix profile install nixpkgs#nil"
fi

# Terraform
if has_glob_recursive "*.tf" || [ -d "$TARGET_DIR/terraform" ]; then
    log_detected "Terraform" "*.tf files"
    detected_languages+=("terraform")
    add_server "terraform-ls" "brew install hashicorp/tap/terraform-ls (macOS) / download binary (Linux)"
fi

# GraphQL
if has_glob_recursive "*.graphql" || has_glob_recursive "*.gql"; then
    log_detected "GraphQL" "*.graphql files"
    detected_languages+=("graphql")
    add_server "graphql-lsp" "npm i -g graphql-language-service-cli"
fi

# GitHub Actions
if [ -d "$TARGET_DIR/.github/workflows" ]; then
    yml_count=$(find "$TARGET_DIR/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    if [ "$yml_count" -gt 0 ]; then
        log_detected "GitHub Actions" ".github/workflows/*.yml ($yml_count workflows)"
        detected_languages+=("github-actions")
        add_server "actionlint" "go install github.com/rhysd/actionlint/cmd/actionlint@latest"
    fi
fi

# --- Phase 2: Framework Detection ---

log_header "Phase 2: Framework Detection"

# framegotui
if has_file "go.mod" && grep -q "biodoia/framegotui" "$TARGET_DIR/go.mod" 2>/dev/null; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}framegotui${NC} project detected"
    add_server "templ" "go install github.com/a-h/templ/cmd/templ@latest"
    add_server "vscode-html-language-server" "npm i -g vscode-langservers-extracted"
    add_server "vscode-css-language-server" "npm i -g vscode-langservers-extracted"
fi

# Next.js
if has_file "package.json" && grep -q '"next"' "$TARGET_DIR/package.json" 2>/dev/null; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}Next.js${NC} project detected"
    if has_file "tailwind.config.js" || has_file "tailwind.config.ts" || has_file "tailwind.config.mjs"; then
        add_server "tailwindcss-language-server" "npm i -g @tailwindcss/language-server"
    fi
fi

# gRPC (Go)
if has_file "go.mod" && grep -q "google.golang.org/grpc" "$TARGET_DIR/go.mod" 2>/dev/null; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}gRPC (Go)${NC} project detected"
    add_server "buf" "go install github.com/bufbuild/buf/cmd/buf@latest"
fi

# Tailwind (standalone check)
if has_file "tailwind.config.js" || has_file "tailwind.config.ts" || has_file "tailwind.config.mjs"; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}Tailwind CSS${NC} detected"
    add_server "tailwindcss-language-server" "npm i -g @tailwindcss/language-server"
fi

# HTMX
if has_glob_recursive "*.html" && grep -rl "hx-" "$TARGET_DIR" --include="*.html" --include="*.templ" -l 2>/dev/null | head -1 | grep -q .; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}HTMX${NC} detected (HTML LSP will include HTMX attributes)"
fi

# --- Phase 3: Auxiliary Tool Detection ---

log_header "Phase 3: Auxiliary Tools"

# Biome (overrides eslint + prettier for JS/TS)
if has_file "biome.json" || has_file "biome.jsonc"; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}Biome${NC} detected (replaces eslint + prettier)"
    add_server "biome" "npm i -g @biomejs/biome"
fi

# ESLint
if has_glob ".eslintrc*" || has_file "eslint.config.js" || has_file "eslint.config.mjs" || has_file "eslint.config.ts"; then
    if ! has_file "biome.json" && ! has_file "biome.jsonc"; then
        echo -e "  ${GREEN}[+]${NC} ${BOLD}ESLint${NC} detected"
    fi
fi

# Prettier
if has_glob ".prettierrc*" || has_file "prettier.config.js" || has_file "prettier.config.mjs"; then
    if ! has_file "biome.json" && ! has_file "biome.jsonc"; then
        echo -e "  ${GREEN}[+]${NC} ${BOLD}Prettier${NC} detected"
    fi
fi

# EditorConfig
if has_file ".editorconfig"; then
    echo -e "  ${GREEN}[+]${NC} ${BOLD}EditorConfig${NC} detected (most LSP servers will respect it)"
fi

# --- Summary ---

log_header "Detection Summary"

echo -e "  ${BOLD}Languages detected:${NC} ${detected_count}"
echo -e "  ${BOLD}LSP servers required:${NC} ${#required_servers[@]}"
echo -e "  ${GREEN}${BOLD}Installed:${NC} ${installed_count}"
echo -e "  ${RED}${BOLD}Missing:${NC} ${missing_count}"

if [ "${#required_servers[@]}" -gt 0 ]; then
    log_header "Server Status"
    printf "  ${BOLD}%-35s %-12s %s${NC}\n" "Server" "Status" "Install Command"
    echo "  $(printf '%.0s-' {1..90})"

    for i in "${!required_servers[@]}"; do
        server="${required_servers[$i]}"
        status="${server_status[$i]}"
        install="${server_install_cmds[$i]}"

        if [ "$status" = "installed" ]; then
            printf "  %-35s ${GREEN}%-12s${NC} %s\n" "$server" "INSTALLED" "--"
        else
            printf "  %-35s ${RED}%-12s${NC} %s\n" "$server" "MISSING" "$install"
        fi
    done
fi

echo ""

if [ "$missing_count" -gt 0 ]; then
    echo -e "  ${YELLOW}${BOLD}Action required:${NC} $missing_count server(s) missing."
    echo -e "  Run ${BOLD}install-lsp.sh${NC} to install missing servers."
else
    echo -e "  ${GREEN}${BOLD}All LSP servers are installed.${NC}"
fi

echo ""
