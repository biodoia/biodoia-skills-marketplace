#!/usr/bin/env bash
#
# install-lsp.sh — Install LSP servers for a detected or specified stack.
#
# Usage:
#   install-lsp.sh                    # Auto-detect stack and install missing servers
#   install-lsp.sh --preset NAME      # Install servers for a named preset
#   install-lsp.sh --server NAME      # Install a single server by name
#   install-lsp.sh --list-presets     # List available presets
#   install-lsp.sh --list-servers     # List all known servers
#   install-lsp.sh --editor EDITOR    # Generate config for EDITOR after install
#   install-lsp.sh --dry-run          # Show what would be installed without doing it
#
# Presets: go-full-stack, node-full-stack, rust-full-stack, python-full-stack,
#          devops, biodoia-ecosystem

set -euo pipefail

# --- Colors ---
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

# --- Globals ---
DRY_RUN=false
PRESET=""
SINGLE_SERVER=""
EDITOR_TARGET=""
LIST_PRESETS=false
LIST_SERVERS=false

# --- OS Detection ---
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|manjaro|endeavouros|garuda)
                echo "arch"
                ;;
            ubuntu|debian|pop|linuxmint|elementary)
                echo "debian"
                ;;
            fedora|rhel|centos|rocky|alma)
                echo "fedora"
                ;;
            opensuse*|sles)
                echo "suse"
                ;;
            nixos)
                echo "nixos"
                ;;
            *)
                echo "unknown-linux"
                ;;
        esac
    elif [ "$(uname)" = "Darwin" ]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS="$(detect_os)"

# --- Package manager helpers ---

has_cmd() {
    command -v "$1" &>/dev/null
}

install_with_go() {
    local pkg="$1"
    if has_cmd go; then
        echo -e "  ${BLUE}[go]${NC} go install $pkg"
        if [ "$DRY_RUN" = false ]; then
            go install "$pkg"
        fi
    else
        echo -e "  ${RED}[error]${NC} Go not installed. Install Go first: https://go.dev/dl/"
        return 1
    fi
}

install_with_npm() {
    local pkg="$1"
    if has_cmd npm; then
        echo -e "  ${BLUE}[npm]${NC} npm i -g $pkg"
        if [ "$DRY_RUN" = false ]; then
            npm i -g "$pkg"
        fi
    elif has_cmd pnpm; then
        echo -e "  ${BLUE}[pnpm]${NC} pnpm add -g $pkg"
        if [ "$DRY_RUN" = false ]; then
            pnpm add -g "$pkg"
        fi
    else
        echo -e "  ${RED}[error]${NC} npm/pnpm not installed. Install Node.js first."
        return 1
    fi
}

install_with_pip() {
    local pkg="$1"
    if has_cmd pip3; then
        echo -e "  ${BLUE}[pip]${NC} pip3 install $pkg"
        if [ "$DRY_RUN" = false ]; then
            pip3 install "$pkg"
        fi
    elif has_cmd pip; then
        echo -e "  ${BLUE}[pip]${NC} pip install $pkg"
        if [ "$DRY_RUN" = false ]; then
            pip install "$pkg"
        fi
    else
        echo -e "  ${RED}[error]${NC} pip not installed. Install Python first."
        return 1
    fi
}

install_with_cargo() {
    local pkg="$1"
    local flags="${2:-}"
    if has_cmd cargo; then
        echo -e "  ${BLUE}[cargo]${NC} cargo install $pkg $flags"
        if [ "$DRY_RUN" = false ]; then
            cargo install $pkg $flags
        fi
    else
        echo -e "  ${RED}[error]${NC} Cargo not installed. Install Rust first: https://rustup.rs/"
        return 1
    fi
}

install_with_pacman() {
    local pkg="$1"
    echo -e "  ${BLUE}[pacman]${NC} sudo pacman -S --noconfirm $pkg"
    if [ "$DRY_RUN" = false ]; then
        sudo pacman -S --noconfirm "$pkg"
    fi
}

install_with_yay() {
    local pkg="$1"
    echo -e "  ${BLUE}[yay]${NC} yay -S --noconfirm $pkg"
    if [ "$DRY_RUN" = false ]; then
        yay -S --noconfirm "$pkg"
    fi
}

install_with_brew() {
    local pkg="$1"
    echo -e "  ${BLUE}[brew]${NC} brew install $pkg"
    if [ "$DRY_RUN" = false ]; then
        brew install "$pkg"
    fi
}

install_with_apt() {
    local pkg="$1"
    echo -e "  ${BLUE}[apt]${NC} sudo apt install -y $pkg"
    if [ "$DRY_RUN" = false ]; then
        sudo apt install -y "$pkg"
    fi
}

# --- Server Installation Functions ---

install_server() {
    local server="$1"

    if has_cmd "$server" && [ "$server" != "templ" ]; then
        echo -e "  ${GREEN}[skip]${NC} $server already installed"
        return 0
    fi

    # Special case: some servers have different binary names
    case "$server" in
        pyright-langserver|pyright)
            if has_cmd pyright-langserver || has_cmd pyright; then
                echo -e "  ${GREEN}[skip]${NC} pyright already installed"
                return 0
            fi
            ;;
        vscode-html-language-server|vscode-css-language-server|vscode-json-language-server)
            if has_cmd "$server"; then
                echo -e "  ${GREEN}[skip]${NC} $server already installed"
                return 0
            fi
            ;;
    esac

    echo -e "\n  ${BOLD}Installing $server...${NC}"

    case "$server" in
        gopls)
            install_with_go "golang.org/x/tools/gopls@latest"
            ;;
        typescript-language-server)
            install_with_npm "typescript-language-server typescript"
            ;;
        pyright-langserver|pyright)
            install_with_pip "pyright"
            ;;
        ruff)
            install_with_pip "ruff"
            ;;
        rust-analyzer)
            if has_cmd rustup; then
                echo -e "  ${BLUE}[rustup]${NC} rustup component add rust-analyzer"
                if [ "$DRY_RUN" = false ]; then
                    rustup component add rust-analyzer
                fi
            else
                echo -e "  ${RED}[error]${NC} rustup not installed. Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            fi
            ;;
        buf)
            install_with_go "github.com/bufbuild/buf/cmd/buf@latest"
            ;;
        yaml-language-server)
            install_with_npm "yaml-language-server"
            ;;
        vscode-json-language-server|vscode-html-language-server|vscode-css-language-server)
            install_with_npm "vscode-langservers-extracted"
            ;;
        docker-langserver)
            install_with_npm "dockerfile-language-server-nodejs"
            ;;
        tailwindcss-language-server)
            install_with_npm "@tailwindcss/language-server"
            ;;
        bash-language-server)
            install_with_npm "bash-language-server"
            ;;
        sqls)
            install_with_go "github.com/sqls-server/sqls@latest"
            ;;
        lua-language-server)
            case "$OS" in
                arch) install_with_pacman "lua-language-server" ;;
                macos) install_with_brew "lua-language-server" ;;
                debian) install_with_npm "lua-language-server" ;;
                *) echo -e "  ${YELLOW}[manual]${NC} Download from https://github.com/LuaLS/lua-language-server/releases" ;;
            esac
            ;;
        marksman)
            case "$OS" in
                arch)
                    if has_cmd yay; then
                        install_with_yay "marksman-bin"
                    else
                        echo -e "  ${BLUE}[gh]${NC} Downloading marksman binary..."
                        if [ "$DRY_RUN" = false ]; then
                            mkdir -p ~/.local/bin
                            gh release download -R artempyanykh/marksman -p "marksman-linux-x64" -O ~/.local/bin/marksman 2>/dev/null && chmod +x ~/.local/bin/marksman || echo -e "  ${YELLOW}[manual]${NC} Download from https://github.com/artempyanykh/marksman/releases"
                        fi
                    fi
                    ;;
                macos) install_with_brew "marksman" ;;
                *) echo -e "  ${YELLOW}[manual]${NC} Download from https://github.com/artempyanykh/marksman/releases" ;;
            esac
            ;;
        taplo)
            install_with_cargo "taplo-cli" "--locked"
            ;;
        zls)
            echo -e "  ${YELLOW}[manual]${NC} Download from https://github.com/zigtools/zls/releases"
            ;;
        nil)
            if [ "$OS" = "nixos" ] || has_cmd nix; then
                echo -e "  ${BLUE}[nix]${NC} nix profile install nixpkgs#nil"
                if [ "$DRY_RUN" = false ]; then
                    nix profile install nixpkgs#nil
                fi
            else
                echo -e "  ${YELLOW}[manual]${NC} Requires Nix package manager"
            fi
            ;;
        terraform-ls)
            case "$OS" in
                arch) install_with_yay "terraform-ls" ;;
                macos) install_with_brew "hashicorp/tap/terraform-ls" ;;
                *) echo -e "  ${YELLOW}[manual]${NC} Download from https://releases.hashicorp.com/terraform-ls/" ;;
            esac
            ;;
        graphql-lsp)
            install_with_npm "graphql-language-service-cli"
            ;;
        templ)
            install_with_go "github.com/a-h/templ/cmd/templ@latest"
            ;;
        actionlint)
            install_with_go "github.com/rhysd/actionlint/cmd/actionlint@latest"
            ;;
        biome)
            install_with_npm "@biomejs/biome"
            ;;
        deno)
            echo -e "  ${BLUE}[curl]${NC} Installing Deno..."
            if [ "$DRY_RUN" = false ]; then
                curl -fsSL https://deno.land/install.sh | sh
            fi
            ;;
        efm-langserver)
            install_with_go "github.com/mattn/efm-langserver@latest"
            ;;
        *)
            echo -e "  ${RED}[error]${NC} Unknown server: $server"
            return 1
            ;;
    esac
}

# --- Presets ---

get_preset_servers() {
    local preset="$1"
    case "$preset" in
        go-full-stack)
            echo "gopls templ vscode-html-language-server vscode-css-language-server yaml-language-server docker-langserver sqls bash-language-server buf marksman vscode-json-language-server"
            ;;
        node-full-stack)
            echo "typescript-language-server tailwindcss-language-server vscode-html-language-server vscode-css-language-server vscode-json-language-server yaml-language-server docker-langserver bash-language-server marksman"
            ;;
        rust-full-stack)
            echo "rust-analyzer taplo yaml-language-server docker-langserver sqls bash-language-server marksman vscode-json-language-server"
            ;;
        python-full-stack)
            echo "pyright ruff yaml-language-server docker-langserver sqls bash-language-server vscode-json-language-server marksman"
            ;;
        devops)
            echo "terraform-ls yaml-language-server docker-langserver bash-language-server vscode-json-language-server taplo actionlint marksman"
            ;;
        biodoia-ecosystem)
            echo "gopls templ vscode-html-language-server vscode-css-language-server buf yaml-language-server docker-langserver bash-language-server sqls marksman vscode-json-language-server actionlint"
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
}

list_presets() {
    echo -e "${BOLD}${CYAN}Available Presets:${NC}\n"
    echo -e "  ${BOLD}go-full-stack${NC}"
    echo "    gopls, templ, html/css, yaml, docker, sql, bash, buf, markdown, json"
    echo ""
    echo -e "  ${BOLD}node-full-stack${NC}"
    echo "    typescript, tailwind, html/css, json, yaml, docker, bash, markdown"
    echo ""
    echo -e "  ${BOLD}rust-full-stack${NC}"
    echo "    rust-analyzer, toml, yaml, docker, sql, bash, markdown, json"
    echo ""
    echo -e "  ${BOLD}python-full-stack${NC}"
    echo "    pyright, ruff, yaml, docker, sql, bash, json, markdown"
    echo ""
    echo -e "  ${BOLD}devops${NC}"
    echo "    terraform, yaml, docker, bash, json, toml, actionlint, markdown"
    echo ""
    echo -e "  ${BOLD}biodoia-ecosystem${NC}"
    echo "    gopls, templ, html/css, buf/proto, yaml, docker, bash, sql, markdown, json, actionlint"
    echo ""
}

list_servers() {
    echo -e "${BOLD}${CYAN}Known LSP Servers:${NC}\n"
    printf "  ${BOLD}%-35s %s${NC}\n" "Server" "Language"
    echo "  $(printf '%.0s-' {1..60})"
    printf "  %-35s %s\n" "gopls" "Go"
    printf "  %-35s %s\n" "typescript-language-server" "TypeScript/JavaScript"
    printf "  %-35s %s\n" "pyright" "Python (type checking)"
    printf "  %-35s %s\n" "ruff" "Python (linting/formatting)"
    printf "  %-35s %s\n" "rust-analyzer" "Rust"
    printf "  %-35s %s\n" "buf" "Protocol Buffers"
    printf "  %-35s %s\n" "yaml-language-server" "YAML"
    printf "  %-35s %s\n" "vscode-json-language-server" "JSON"
    printf "  %-35s %s\n" "vscode-html-language-server" "HTML"
    printf "  %-35s %s\n" "vscode-css-language-server" "CSS/SCSS/Less"
    printf "  %-35s %s\n" "docker-langserver" "Dockerfile"
    printf "  %-35s %s\n" "tailwindcss-language-server" "Tailwind CSS"
    printf "  %-35s %s\n" "bash-language-server" "Shell/Bash"
    printf "  %-35s %s\n" "sqls" "SQL"
    printf "  %-35s %s\n" "lua-language-server" "Lua"
    printf "  %-35s %s\n" "marksman" "Markdown"
    printf "  %-35s %s\n" "taplo" "TOML"
    printf "  %-35s %s\n" "zls" "Zig"
    printf "  %-35s %s\n" "nil" "Nix"
    printf "  %-35s %s\n" "terraform-ls" "Terraform/HCL"
    printf "  %-35s %s\n" "graphql-lsp" "GraphQL"
    printf "  %-35s %s\n" "templ" "Go Templ"
    printf "  %-35s %s\n" "actionlint" "GitHub Actions"
    printf "  %-35s %s\n" "biome" "JS/TS/JSON/CSS (unified)"
    printf "  %-35s %s\n" "deno" "Deno/TypeScript"
    printf "  %-35s %s\n" "efm-langserver" "General (linter aggregator)"
    echo ""
}

# --- Argument Parsing ---

while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)
            PRESET="$2"
            shift 2
            ;;
        --server)
            SINGLE_SERVER="$2"
            shift 2
            ;;
        --editor)
            EDITOR_TARGET="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --list-presets)
            LIST_PRESETS=true
            shift
            ;;
        --list-servers)
            LIST_SERVERS=true
            shift
            ;;
        --help|-h)
            echo "Usage: install-lsp.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --preset NAME     Install servers for a named preset"
            echo "  --server NAME     Install a single server by name"
            echo "  --editor EDITOR   Generate config for EDITOR after install"
            echo "  --dry-run         Show what would be installed"
            echo "  --list-presets    List available presets"
            echo "  --list-servers    List all known servers"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Presets: go-full-stack, node-full-stack, rust-full-stack,"
            echo "         python-full-stack, devops, biodoia-ecosystem"
            echo ""
            echo "Editors: neovim, vscode, helix, zed, emacs, claude-code"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# --- List modes ---

if [ "$LIST_PRESETS" = true ]; then
    list_presets
    exit 0
fi

if [ "$LIST_SERVERS" = true ]; then
    list_servers
    exit 0
fi

# --- Main ---

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       Multi-LSP Server Installer         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  OS detected: ${BOLD}$OS${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "  Mode: ${YELLOW}${BOLD}DRY RUN${NC} (no changes will be made)"
fi

# Single server mode
if [ -n "$SINGLE_SERVER" ]; then
    echo -e "\n  Installing single server: ${BOLD}$SINGLE_SERVER${NC}\n"
    install_server "$SINGLE_SERVER"
    echo -e "\n  ${GREEN}${BOLD}Done.${NC}"
    exit 0
fi

# Determine server list
servers=""
if [ -n "$PRESET" ]; then
    echo -e "\n  Using preset: ${BOLD}$PRESET${NC}\n"
    servers="$(get_preset_servers "$PRESET")"
    if [ -z "$servers" ]; then
        echo -e "  ${RED}Unknown preset: $PRESET${NC}"
        echo "  Run with --list-presets to see available presets."
        exit 1
    fi
else
    echo -e "\n  ${BOLD}Auto-detecting stack...${NC}\n"

    # Run detect-stack.sh if available, otherwise do inline detection
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -x "$SCRIPT_DIR/detect-stack.sh" ]; then
        # Run detection and extract missing servers
        echo -e "  Running detect-stack.sh for analysis...\n"
        # We'll do a simpler inline detection for the install script
    fi

    # Inline detection (works without detect-stack.sh)
    detected_servers=""

    [ -f "go.mod" ] && detected_servers="$detected_servers gopls"
    [ -f "package.json" ] && detected_servers="$detected_servers typescript-language-server"
    [ -f "Cargo.toml" ] && detected_servers="$detected_servers rust-analyzer taplo"
    ([ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]) && detected_servers="$detected_servers pyright ruff"
    (compgen -G "*.proto" >/dev/null 2>&1 || [ -f "buf.yaml" ]) && detected_servers="$detected_servers buf"
    ([ -f "Dockerfile" ] || [ -f "compose.yaml" ] || [ -f "docker-compose.yml" ]) && detected_servers="$detected_servers docker-langserver"
    (compgen -G "*.yaml" >/dev/null 2>&1 || compgen -G "*.yml" >/dev/null 2>&1) && detected_servers="$detected_servers yaml-language-server"
    compgen -G "*.sh" >/dev/null 2>&1 && detected_servers="$detected_servers bash-language-server"
    find . -maxdepth 3 -name "*.sql" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers sqls"
    find . -maxdepth 3 -name "*.html" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers vscode-html-language-server"
    (find . -maxdepth 3 -name "*.css" -print -quit 2>/dev/null | grep -q . || find . -maxdepth 3 -name "*.scss" -print -quit 2>/dev/null | grep -q .) && detected_servers="$detected_servers vscode-css-language-server"
    compgen -G "*.md" >/dev/null 2>&1 && detected_servers="$detected_servers marksman"
    find . -maxdepth 3 -name "*.lua" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers lua-language-server"
    find . -maxdepth 3 -name "*.tf" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers terraform-ls"
    find . -maxdepth 3 -name "*.graphql" -o -name "*.gql" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers graphql-lsp"
    find . -maxdepth 3 -name "*.zig" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers zls"
    find . -maxdepth 3 -name "*.nix" -print -quit 2>/dev/null | grep -q . && detected_servers="$detected_servers nil"
    [ -d ".github/workflows" ] && detected_servers="$detected_servers actionlint"

    # Framework detection
    [ -f "go.mod" ] && grep -q "biodoia/framegotui" go.mod 2>/dev/null && detected_servers="$detected_servers templ vscode-html-language-server vscode-css-language-server"
    ([ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ] || [ -f "tailwind.config.mjs" ]) && detected_servers="$detected_servers tailwindcss-language-server"
    ([ -f "biome.json" ] || [ -f "biome.jsonc" ]) && detected_servers="$detected_servers biome"

    # Deduplicate
    servers=$(echo "$detected_servers" | tr ' ' '\n' | sort -u | tr '\n' ' ')

    if [ -z "$(echo "$servers" | tr -d ' ')" ]; then
        echo -e "  ${YELLOW}No languages detected in current directory.${NC}"
        echo "  Try running from your project root, or use --preset to install a specific stack."
        exit 0
    fi

    echo -e "  Detected servers to install: ${BOLD}$(echo $servers | tr ' ' ', ')${NC}"
fi

# Install each server
echo ""
install_count=0
skip_count=0
fail_count=0

for server in $servers; do
    if install_server "$server"; then
        if has_cmd "$server" || [ "$DRY_RUN" = true ]; then
            install_count=$((install_count + 1))
        else
            skip_count=$((skip_count + 1))
        fi
    else
        fail_count=$((fail_count + 1))
    fi
done

# --- Validation ---

echo -e "\n${BOLD}${CYAN}=== Validation ===${NC}\n"

for server in $servers; do
    # Handle servers with different binary names
    check_cmd="$server"
    case "$server" in
        pyright) check_cmd="pyright-langserver" ;;
        vscode-html-language-server|vscode-css-language-server|vscode-json-language-server) check_cmd="$server" ;;
    esac

    if has_cmd "$check_cmd" || has_cmd "$server"; then
        printf "  ${GREEN}%-35s OK${NC}\n" "$server"
    else
        printf "  ${RED}%-35s NOT FOUND${NC}\n" "$server"
    fi
done

# --- Summary ---

echo -e "\n${BOLD}${CYAN}=== Summary ===${NC}\n"
echo -e "  Processed: $(echo $servers | wc -w | tr -d ' ') servers"
if [ "$DRY_RUN" = true ]; then
    echo -e "  Mode: ${YELLOW}DRY RUN${NC} -- no changes were made"
fi

if [ -n "$EDITOR_TARGET" ]; then
    echo -e "\n  ${YELLOW}Editor config generation for '$EDITOR_TARGET' is not yet automated.${NC}"
    echo -e "  See references/editor-configs.md for configuration templates."
fi

echo -e "\n  ${GREEN}${BOLD}Installation complete.${NC}\n"
