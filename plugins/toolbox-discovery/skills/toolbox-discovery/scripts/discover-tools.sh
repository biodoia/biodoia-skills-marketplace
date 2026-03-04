#!/usr/bin/env bash
# ============================================================================
# Toolbox Discovery Script
# Scans the system for installed tools, reports versions, and identifies gaps.
# Usage: discover-tools.sh [--json] [--category <category>] [--quiet]
# ============================================================================

set -euo pipefail

# --- Configuration ---
VERSION="0.1.0"
OUTPUT_JSON=false
QUIET=false
FILTER_CATEGORY=""
FOUND_COUNT=0
MISSING_COUNT=0
ERROR_COUNT=0

# --- Colors ---
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" == "" ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' RESET=''
fi

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json)      OUTPUT_JSON=true; shift ;;
        --quiet|-q)  QUIET=true; shift ;;
        --category)  FILTER_CATEGORY="$2"; shift 2 ;;
        --version)   echo "discover-tools $VERSION"; exit 0 ;;
        --help|-h)
            echo "Usage: discover-tools.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --json              Output as JSON"
            echo "  --quiet, -q         Minimal output (only found tools)"
            echo "  --category <name>   Scan only one category"
            echo "  --version           Show version"
            echo "  --help, -h          Show this help"
            echo ""
            echo "Categories: languages, packages, containers, vcs, ai, editors,"
            echo "            terminal, networking, databases, monitoring, files,"
            echo "            media, system"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# --- JSON accumulator ---
JSON_ENTRIES=()

# --- Core functions ---

# Check if a tool exists and get its version
# Usage: check_tool <name> <command> [version_flag]
check_tool() {
    local name="$1"
    local cmd="$2"
    local ver_flag="${3:---version}"
    local path=""
    local version=""
    local status="missing"

    path=$(command -v "$cmd" 2>/dev/null) || true

    if [[ -n "$path" ]]; then
        # Try to get version
        version=$("$cmd" $ver_flag 2>&1 | head -1 | sed -E 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/' | head -c 50) || version="unknown"
        # Clean up version string
        version=$(echo "$version" | tr -d '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        if [[ -z "$version" ]] || [[ ${#version} -gt 50 ]]; then
            version="installed"
        fi
        status="found"
        ((FOUND_COUNT++)) || true
    else
        ((MISSING_COUNT++)) || true
    fi

    if $OUTPUT_JSON; then
        local json_entry
        if [[ "$status" == "found" ]]; then
            json_entry=$(printf '{"name":"%s","command":"%s","status":"found","path":"%s","version":"%s"}' \
                "$name" "$cmd" "$path" "$version")
        else
            json_entry=$(printf '{"name":"%s","command":"%s","status":"missing","path":"","version":""}' \
                "$name" "$cmd")
        fi
        JSON_ENTRIES+=("$json_entry")
    else
        if [[ "$status" == "found" ]]; then
            printf "  ${GREEN}✓${RESET} %-22s ${DIM}%-14s${RESET} %s\n" "$name" "$version" "$path"
        elif ! $QUIET; then
            printf "  ${RED}✗${RESET} %-22s ${DIM}%-14s${RESET}\n" "$name" "not installed"
        fi
    fi
}

# Check if a systemd service is running
# Usage: check_service <name>
check_service() {
    local name="$1"
    if systemctl is-active --quiet "$name" 2>/dev/null; then
        echo "running"
    elif systemctl --user is-active --quiet "$name" 2>/dev/null; then
        echo "running (user)"
    elif systemctl is-enabled --quiet "$name" 2>/dev/null; then
        echo "enabled (stopped)"
    elif systemctl --user is-enabled --quiet "$name" 2>/dev/null; then
        echo "enabled (user, stopped)"
    else
        echo "inactive"
    fi
}

# Print category header
print_category() {
    local name="$1"
    if ! $OUTPUT_JSON; then
        echo ""
        printf "${BOLD}${CYAN}%s${RESET}\n" "$name"
        printf "${DIM}%s${RESET}\n" "$(printf '%.0s─' {1..60})"
    fi
}

# --- System Info ---
print_system_info() {
    if ! $OUTPUT_JSON && ! $QUIET; then
        echo ""
        printf "${BOLD}TOOLBOX DISCOVERY REPORT${RESET}\n"
        printf "${DIM}%s${RESET}\n" "$(printf '%.0s═' {1..60})"

        local os_name=""
        if [[ -f /etc/os-release ]]; then
            os_name=$(. /etc/os-release && echo "${PRETTY_NAME:-$NAME}")
        elif command -v sw_vers &>/dev/null; then
            os_name="macOS $(sw_vers -productVersion)"
        else
            os_name="$(uname -s) $(uname -r)"
        fi

        local shell_name="${SHELL##*/}"
        local kernel="$(uname -r)"
        local hostname="$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo 'unknown')"

        printf "System:   %s\n" "$os_name"
        printf "Kernel:   %s\n" "$kernel"
        printf "Host:     %s\n" "$hostname"
        printf "Shell:    %s\n" "$shell_name"
        printf "Date:     %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
    fi
}

# --- Category scanners ---

scan_languages() {
    print_category "LANGUAGES & RUNTIMES"

    # Go
    check_tool "Go" "go" "version"
    check_tool "gopls" "gopls" "version"
    check_tool "golangci-lint" "golangci-lint" "--version"
    check_tool "air" "air" "-v"
    check_tool "templ" "templ" "version"
    check_tool "dlv (Delve)" "dlv" "version"
    check_tool "buf" "buf" "--version"
    check_tool "protoc" "protoc" "--version"
    check_tool "staticcheck" "staticcheck" "-version"

    # Node
    check_tool "Node.js" "node" "--version"
    check_tool "npm" "npm" "--version"
    check_tool "npx" "npx" "--version"
    check_tool "yarn" "yarn" "--version"
    check_tool "pnpm" "pnpm" "--version"
    check_tool "bun" "bun" "--version"
    check_tool "deno" "deno" "--version"
    check_tool "tsx" "tsx" "--version"

    # Python
    check_tool "Python 3" "python3" "--version"
    check_tool "pip" "pip3" "--version"
    check_tool "pipx" "pipx" "--version"
    check_tool "uv" "uv" "--version"
    check_tool "poetry" "poetry" "--version"
    check_tool "conda" "conda" "--version"
    check_tool "pyenv" "pyenv" "--version"
    check_tool "ruff" "ruff" "--version"
    check_tool "mypy" "mypy" "--version"
    check_tool "black" "black" "--version"

    # Rust
    check_tool "rustc" "rustc" "--version"
    check_tool "cargo" "cargo" "--version"
    check_tool "rustup" "rustup" "--version"
    check_tool "rust-analyzer" "rust-analyzer" "--version"

    # Java
    check_tool "java" "java" "--version"
    check_tool "javac" "javac" "--version"
    check_tool "gradle" "gradle" "--version"
    check_tool "maven (mvn)" "mvn" "--version"
    check_tool "kotlin" "kotlin" "-version"

    # Ruby
    check_tool "ruby" "ruby" "--version"
    check_tool "gem" "gem" "--version"
    check_tool "bundler" "bundler" "--version"

    # PHP
    check_tool "php" "php" "--version"
    check_tool "composer" "composer" "--version"

    # Other
    check_tool "zig" "zig" "version"
    check_tool "nim" "nim" "--version"
    check_tool "elixir" "elixir" "--version"
    check_tool "haskell (ghc)" "ghc" "--version"

    # C/C++
    check_tool "gcc" "gcc" "--version"
    check_tool "g++" "g++" "--version"
    check_tool "clang" "clang" "--version"
    check_tool "cmake" "cmake" "--version"
    check_tool "make" "make" "--version"
    check_tool "meson" "meson" "--version"
    check_tool "ninja" "ninja" "--version"
    check_tool "ccache" "ccache" "--version"

    # Lua
    check_tool "lua" "lua" "-v"
    check_tool "luajit" "luajit" "-v"
    check_tool "luarocks" "luarocks" "--version"

    # Perl
    check_tool "perl" "perl" "--version"
}

scan_packages() {
    print_category "PACKAGE MANAGERS"

    check_tool "pacman" "pacman" "--version"
    check_tool "yay" "yay" "--version"
    check_tool "paru" "paru" "--version"
    check_tool "pamac" "pamac" "--version"
    check_tool "apt" "apt" "--version"
    check_tool "dnf" "dnf" "--version"
    check_tool "brew" "brew" "--version"
    check_tool "flatpak" "flatpak" "--version"
    check_tool "snap" "snap" "--version"
    check_tool "nix" "nix" "--version"
    check_tool "asdf" "asdf" "--version"
    check_tool "mise" "mise" "--version"
    check_tool "proto" "proto" "--version"
    check_tool "nvm" "nvm" "--version"
    check_tool "fnm" "fnm" "--version"
}

scan_containers() {
    print_category "CONTAINERS & ORCHESTRATION"

    check_tool "docker" "docker" "--version"
    check_tool "docker-compose" "docker-compose" "--version"
    check_tool "podman" "podman" "--version"
    check_tool "buildah" "buildah" "--version"
    check_tool "skopeo" "skopeo" "--version"
    check_tool "nerdctl" "nerdctl" "--version"
    check_tool "kubectl" "kubectl" "version --client --short"
    check_tool "helm" "helm" "version --short"
    check_tool "k9s" "k9s" "version --short"
    check_tool "minikube" "minikube" "version --short"
    check_tool "kind" "kind" "version"
    check_tool "terraform" "terraform" "--version"
    check_tool "tofu (OpenTofu)" "tofu" "--version"
    check_tool "pulumi" "pulumi" "version"
    check_tool "ansible" "ansible" "--version"
    check_tool "vagrant" "vagrant" "--version"
    check_tool "packer" "packer" "--version"

    # Cloud CLIs
    check_tool "aws" "aws" "--version"
    check_tool "gcloud" "gcloud" "--version"
    check_tool "az (Azure)" "az" "--version"
    check_tool "doctl" "doctl" "version"
    check_tool "flyctl" "flyctl" "version"
    check_tool "railway" "railway" "--version"
    check_tool "vercel" "vercel" "--version"
    check_tool "netlify" "netlify" "--version"
    check_tool "wrangler" "wrangler" "--version"
}

scan_vcs() {
    print_category "VERSION CONTROL"

    check_tool "git" "git" "--version"
    check_tool "git-lfs" "git-lfs" "--version"
    check_tool "gh (GitHub CLI)" "gh" "--version"
    check_tool "glab (GitLab)" "glab" "--version"
    check_tool "lazygit" "lazygit" "--version"
    check_tool "tig" "tig" "--version"
    check_tool "gitui" "gitui" "--version"
    check_tool "delta" "delta" "--version"
    check_tool "difftastic" "difft" "--version"
    check_tool "pre-commit" "pre-commit" "--version"
}

scan_ai() {
    print_category "AI & CODING AGENTS"

    check_tool "claude" "claude" "--version"
    check_tool "codex" "codex" "--version"
    check_tool "gemini" "gemini" "--version"
    check_tool "aider" "aider" "--version"
    check_tool "goose" "goose" "--version"
    check_tool "amp" "amp" "--version"
    check_tool "opencode" "opencode" "--version"
    check_tool "ollama" "ollama" "--version"
    check_tool "llama-server" "llama-server" "--version"
    check_tool "sgpt" "sgpt" "--version"
    check_tool "mods" "mods" "--version"
    check_tool "glow" "glow" "--version"
    check_tool "fabric" "fabric" "--version"

    # Check ollama service and models
    if command -v ollama &>/dev/null && ! $OUTPUT_JSON; then
        local ollama_status
        ollama_status=$(check_service "ollama")
        printf "  ${BLUE}ℹ${RESET} %-22s %s\n" "ollama service" "$ollama_status"
        if [[ "$ollama_status" == running* ]]; then
            local models
            models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')
            if [[ -n "$models" ]]; then
                printf "  ${BLUE}ℹ${RESET} %-22s %s\n" "ollama models" "$models"
            fi
        fi
    fi
}

scan_editors() {
    print_category "EDITORS & IDEs"

    check_tool "Neovim" "nvim" "--version"
    check_tool "Vim" "vim" "--version"
    check_tool "Emacs" "emacs" "--version"
    check_tool "Helix" "hx" "--version"
    check_tool "Kakoune" "kak" "-version"
    check_tool "micro" "micro" "--version"
    check_tool "nano" "nano" "--version"
    check_tool "VS Code" "code" "--version"
    check_tool "Cursor" "cursor" "--version"
    check_tool "Windsurf" "windsurf" "--version"
    check_tool "Zed" "zed" "--version"
    check_tool "Sublime" "subl" "--version"
}

scan_terminal() {
    print_category "TERMINAL & SHELL"

    # Shells
    check_tool "bash" "bash" "--version"
    check_tool "zsh" "zsh" "--version"
    check_tool "fish" "fish" "--version"
    check_tool "nushell" "nu" "--version"

    # Multiplexers
    check_tool "tmux" "tmux" "-V"
    check_tool "zellij" "zellij" "--version"
    check_tool "screen" "screen" "--version"

    # Emulators
    check_tool "ghostty" "ghostty" "--version"
    check_tool "alacritty" "alacritty" "--version"
    check_tool "kitty" "kitty" "--version"
    check_tool "wezterm" "wezterm" "--version"
    check_tool "foot" "foot" "--version"

    # Prompts & utilities
    check_tool "starship" "starship" "--version"
    check_tool "fzf" "fzf" "--version"
    check_tool "zoxide" "zoxide" "--version"
    check_tool "direnv" "direnv" "--version"
    check_tool "atuin" "atuin" "--version"
    check_tool "mcfly" "mcfly" "--version"

    # Check oh-my-zsh
    if ! $OUTPUT_JSON; then
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            printf "  ${GREEN}✓${RESET} %-22s ${DIM}%-14s${RESET} %s\n" "oh-my-zsh" "installed" "$HOME/.oh-my-zsh"
        elif ! $QUIET; then
            printf "  ${RED}✗${RESET} %-22s ${DIM}%-14s${RESET}\n" "oh-my-zsh" "not installed"
        fi
    fi
}

scan_networking() {
    print_category "NETWORKING"

    check_tool "curl" "curl" "--version"
    check_tool "wget" "wget" "--version"
    check_tool "xh" "xh" "--version"
    check_tool "httpie" "http" "--version"
    check_tool "grpcurl" "grpcurl" "--version"
    check_tool "nmap" "nmap" "--version"
    check_tool "ssh" "ssh" "-V"
    check_tool "mosh" "mosh" "--version"
    check_tool "socat" "socat" "-V"
    check_tool "netcat" "nc" "-h"
    check_tool "tailscale" "tailscale" "--version"
    check_tool "wireguard (wg)" "wg" "--version"
    check_tool "openvpn" "openvpn" "--version"
    check_tool "caddy" "caddy" "version"
    check_tool "nginx" "nginx" "-v"
    check_tool "dig" "dig" "-v"
    check_tool "nslookup" "nslookup" "-version"
    check_tool "bandwhich" "bandwhich" "--version"
    check_tool "trippy" "trip" "--version"

    # Check tailscale service
    if command -v tailscale &>/dev/null && ! $OUTPUT_JSON; then
        local ts_status
        ts_status=$(check_service "tailscaled")
        printf "  ${BLUE}ℹ${RESET} %-22s %s\n" "tailscale service" "$ts_status"
    fi
}

scan_databases() {
    print_category "DATABASES"

    check_tool "sqlite3" "sqlite3" "--version"
    check_tool "psql" "psql" "--version"
    check_tool "mysql" "mysql" "--version"
    check_tool "mongosh" "mongosh" "--version"
    check_tool "redis-cli" "redis-cli" "--version"
    check_tool "pgcli" "pgcli" "--version"
    check_tool "mycli" "mycli" "--version"
    check_tool "litecli" "litecli" "--version"
    check_tool "usql" "usql" "--version"
}

scan_monitoring() {
    print_category "MONITORING & DEBUGGING"

    check_tool "htop" "htop" "--version"
    check_tool "btop" "btop" "--version"
    check_tool "glances" "glances" "--version"
    check_tool "gotop" "gotop" "--version"
    check_tool "bottom (btm)" "btm" "--version"
    check_tool "strace" "strace" "--version"
    check_tool "ltrace" "ltrace" "--version"
    check_tool "gdb" "gdb" "--version"
    check_tool "lnav" "lnav" "--version"
    check_tool "perf" "perf" "--version"
    check_tool "valgrind" "valgrind" "--version"
}

scan_files() {
    print_category "FILE & DISK UTILITIES"

    check_tool "fd" "fd" "--version"
    check_tool "ripgrep (rg)" "rg" "--version"
    check_tool "fzf" "fzf" "--version"
    check_tool "bat" "bat" "--version"
    check_tool "eza" "eza" "--version"
    check_tool "lsd" "lsd" "--version"
    check_tool "broot" "broot" "--version"
    check_tool "tree" "tree" "--version"
    check_tool "ranger" "ranger" "--version"
    check_tool "yazi" "yazi" "--version"
    check_tool "nnn" "nnn" "-V"
    check_tool "jq" "jq" "--version"
    check_tool "yq" "yq" "--version"
    check_tool "ncdu" "ncdu" "--version"
    check_tool "dust" "dust" "--version"
    check_tool "duf" "duf" "--version"
    check_tool "gdu" "gdu" "--version"
    check_tool "rsync" "rsync" "--version"
    check_tool "rclone" "rclone" "version"
    check_tool "borgbackup" "borg" "--version"
    check_tool "restic" "restic" "version"
    check_tool "tar" "tar" "--version"
    check_tool "zip" "zip" "--version"
    check_tool "unzip" "unzip" "-v"
    check_tool "7z" "7z" "--help"
    check_tool "zstd" "zstd" "--version"
}

scan_media() {
    print_category "MEDIA & DOCUMENTS"

    check_tool "ffmpeg" "ffmpeg" "-version"
    check_tool "ffprobe" "ffprobe" "-version"
    check_tool "imagemagick" "convert" "--version"
    check_tool "mpv" "mpv" "--version"
    check_tool "vlc" "vlc" "--version"
    check_tool "yt-dlp" "yt-dlp" "--version"
    check_tool "sox" "sox" "--version"
    check_tool "pandoc" "pandoc" "--version"
    check_tool "typst" "typst" "--version"
    check_tool "gimp" "gimp" "--version"
    check_tool "inkscape" "inkscape" "--version"
}

scan_system() {
    print_category "SYSTEM UTILITIES"

    check_tool "systemctl" "systemctl" "--version"
    check_tool "journalctl" "journalctl" "--version"
    check_tool "lsblk" "lsblk" "--version"
    check_tool "ip" "ip" "-V"
    check_tool "ss" "ss" "--version"
    check_tool "nmcli" "nmcli" "--version"
    check_tool "ufw" "ufw" "--version"
    check_tool "inxi" "inxi" "--version"
    check_tool "fastfetch" "fastfetch" "--version"
    check_tool "neofetch" "neofetch" "--version"
    check_tool "lscpu" "lscpu" "--version"
    check_tool "lspci" "lspci" "--version"
    check_tool "lsusb" "lsusb" "--version"
    check_tool "smartctl" "smartctl" "--version"
    check_tool "dmidecode" "dmidecode" "--version"
}

# --- Main execution ---

print_system_info

# Determine which categories to scan
ALL_CATEGORIES=(languages packages containers vcs ai editors terminal networking databases monitoring files media system)

if [[ -n "$FILTER_CATEGORY" ]]; then
    categories=("$FILTER_CATEGORY")
else
    categories=("${ALL_CATEGORIES[@]}")
fi

for cat in "${categories[@]}"; do
    case "$cat" in
        languages)   scan_languages ;;
        packages)    scan_packages ;;
        containers)  scan_containers ;;
        vcs)         scan_vcs ;;
        ai)          scan_ai ;;
        editors)     scan_editors ;;
        terminal)    scan_terminal ;;
        networking)  scan_networking ;;
        databases)   scan_databases ;;
        monitoring)  scan_monitoring ;;
        files)       scan_files ;;
        media)       scan_media ;;
        system)      scan_system ;;
        *) echo "Unknown category: $cat"; exit 1 ;;
    esac
done

# --- Summary ---

if $OUTPUT_JSON; then
    # Output JSON
    echo "{"
    echo "  \"version\": \"$VERSION\","
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"hostname\": \"$(hostname 2>/dev/null || echo unknown)\","
    echo "  \"os\": \"$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME" || uname -s)\","
    echo "  \"kernel\": \"$(uname -r)\","
    echo "  \"shell\": \"${SHELL##*/}\","
    echo "  \"found\": $FOUND_COUNT,"
    echo "  \"missing\": $MISSING_COUNT,"
    echo "  \"tools\": ["
    first=true
    for entry in "${JSON_ENTRIES[@]}"; do
        if $first; then
            first=false
        else
            echo ","
        fi
        printf "    %s" "$entry"
    done
    echo ""
    echo "  ]"
    echo "}"
else
    echo ""
    printf "${DIM}%s${RESET}\n" "$(printf '%.0s═' {1..60})"
    printf "${BOLD}SUMMARY${RESET}\n"
    printf "  ${GREEN}Found:${RESET}   %d tools\n" "$FOUND_COUNT"
    printf "  ${RED}Missing:${RESET} %d tools\n" "$MISSING_COUNT"
    printf "  ${BLUE}Total:${RESET}   %d tools scanned\n" "$((FOUND_COUNT + MISSING_COUNT))"
    echo ""
fi
