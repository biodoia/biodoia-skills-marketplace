#!/usr/bin/env bash
# ============================================================================
# Toolbox Activation Script
# Applies recommended configurations for tools and integrations.
# Usage: activate-tools.sh <tool-or-category> [--dry-run] [--no-backup]
# ============================================================================

set -euo pipefail

# --- Configuration ---
VERSION="0.1.0"
DRY_RUN=false
NO_BACKUP=false
BACKUP_DIR="$HOME/.config/toolbox-discovery/backups/$(date +%Y%m%d_%H%M%S)"
CHANGES_MADE=0
TARGET=""

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
        --dry-run)    DRY_RUN=true; shift ;;
        --no-backup)  NO_BACKUP=true; shift ;;
        --version)    echo "activate-tools $VERSION"; exit 0 ;;
        --help|-h)
            echo "Usage: activate-tools.sh <target> [OPTIONS]"
            echo ""
            echo "Targets (tools):"
            echo "  fzf          Configure fzf with zsh/bash integration"
            echo "  bat          Set bat as MANPAGER, configure aliases"
            echo "  eza          Set up eza aliases for ls"
            echo "  delta        Configure delta as git pager"
            echo "  zoxide       Enable zoxide smart cd"
            echo "  direnv       Enable direnv per-directory envs"
            echo "  atuin        Enable atuin shell history"
            echo "  starship     Configure starship prompt"
            echo "  ripgrep      Create ripgrep config file"
            echo "  tmux         Apply sensible tmux configuration"
            echo "  ollama       Enable ollama systemd service"
            echo ""
            echo "Targets (categories):"
            echo "  shell        All shell integrations (fzf, zoxide, direnv, starship)"
            echo "  git          All git improvements (delta, aliases, config)"
            echo "  modern       All modern tool aliases (bat, eza, fd, rg, dust, duf)"
            echo "  completions  Install shell completions for detected tools"
            echo "  all          Apply all safe activations"
            echo ""
            echo "Options:"
            echo "  --dry-run      Show what would be done without making changes"
            echo "  --no-backup    Skip backing up existing configs"
            echo "  --version      Show version"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *)
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
            else
                echo "Error: Multiple targets not supported. Use a category instead."
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo "Error: No target specified. Use --help for usage."
    exit 1
fi

# --- Utility functions ---

log_info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$1"
}

log_ok() {
    printf "${GREEN}[OK]${RESET}   %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
}

log_skip() {
    printf "${DIM}[SKIP]${RESET} %s\n" "$1"
}

log_dry() {
    printf "${CYAN}[DRY]${RESET}  %s\n" "$1"
}

# Check if tool is installed
require_tool() {
    if ! command -v "$1" &>/dev/null; then
        log_warn "$1 is not installed. Skipping activation."
        return 1
    fi
    return 0
}

# Backup a file before modifying
backup_file() {
    local file="$1"
    if [[ -f "$file" ]] && ! $NO_BACKUP; then
        if $DRY_RUN; then
            log_dry "Would backup $file -> $BACKUP_DIR/"
        else
            mkdir -p "$BACKUP_DIR"
            cp "$file" "$BACKUP_DIR/$(basename "$file")"
            log_info "Backed up $file -> $BACKUP_DIR/$(basename "$file")"
        fi
    fi
}

# Append a block to a file if the marker is not already present
# Usage: append_block <file> <marker> <content>
append_block() {
    local file="$1"
    local marker="$2"
    local content="$3"

    if [[ -f "$file" ]] && grep -qF "$marker" "$file" 2>/dev/null; then
        log_skip "$marker already present in $file"
        return 0
    fi

    if $DRY_RUN; then
        log_dry "Would append to $file:"
        echo "$content" | sed 's/^/       /'
    else
        backup_file "$file"
        {
            echo ""
            echo "$content"
        } >> "$file"
        log_ok "Added $marker to $file"
        ((CHANGES_MADE++)) || true
    fi
}

# Detect the shell rc file
detect_shell_rc() {
    local shell="${SHELL##*/}"
    case "$shell" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.bashrc" ;;
    esac
}

SHELL_RC=$(detect_shell_rc)

# --- Activation functions ---

activate_fzf() {
    require_tool fzf || return 0
    log_info "Activating fzf integration..."

    local block
    IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: fzf ---
if command -v fzf &>/dev/null; then
  [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
  [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
  [ -f /usr/share/fzf/key-bindings.bash ] && source /usr/share/fzf/key-bindings.bash
  [ -f /usr/share/fzf/completion.bash ] && source /usr/share/fzf/completion.bash
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:60%"
  fi
  export FZF_DEFAULT_OPTS='--height=60% --layout=reverse --border=rounded --info=inline'
fi
BLOCK
    append_block "$SHELL_RC" "toolbox-discovery: fzf" "$block"
}

activate_bat() {
    require_tool bat || return 0
    log_info "Activating bat configuration..."

    local block
    IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: bat ---
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat'
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi
BLOCK
    append_block "$SHELL_RC" "toolbox-discovery: bat" "$block"
}

activate_eza() {
    require_tool eza || return 0
    log_info "Activating eza aliases..."

    local block
    IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: eza ---
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
  alias lt='eza --tree --icons --level=2 --group-directories-first'
fi
BLOCK
    append_block "$SHELL_RC" "toolbox-discovery: eza" "$block"
}

activate_delta() {
    require_tool delta || return 0
    require_tool git || return 0
    log_info "Activating delta as git pager..."

    if $DRY_RUN; then
        log_dry "Would run: git config --global core.pager delta"
        log_dry "Would run: git config --global interactive.diffFilter 'delta --color-only'"
        log_dry "Would run: git config --global delta.navigate true"
        log_dry "Would run: git config --global delta.dark true"
        log_dry "Would run: git config --global delta.line-numbers true"
        log_dry "Would run: git config --global delta.side-by-side false"
        log_dry "Would run: git config --global merge.conflictstyle diff3"
        log_dry "Would run: git config --global diff.colorMoved default"
    else
        backup_file "$HOME/.gitconfig"
        git config --global core.pager delta
        git config --global interactive.diffFilter 'delta --color-only'
        git config --global delta.navigate true
        git config --global delta.dark true
        git config --global delta.line-numbers true
        git config --global delta.side-by-side false
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
        log_ok "Delta configured as git pager"
        ((CHANGES_MADE++)) || true
    fi
}

activate_zoxide() {
    require_tool zoxide || return 0
    log_info "Activating zoxide..."

    local shell="${SHELL##*/}"
    local block
    case "$shell" in
        zsh)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: zoxide ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi
BLOCK
            ;;
        bash)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: zoxide ---
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi
BLOCK
            ;;
        fish)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: zoxide ---
if command -v zoxide &>/dev/null
  zoxide init fish | source
end
BLOCK
            ;;
        *)
            log_warn "Unsupported shell for zoxide: $shell"
            return 0
            ;;
    esac
    append_block "$SHELL_RC" "toolbox-discovery: zoxide" "$block"
}

activate_direnv() {
    require_tool direnv || return 0
    log_info "Activating direnv..."

    local shell="${SHELL##*/}"
    local block
    case "$shell" in
        zsh)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: direnv ---
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi
BLOCK
            ;;
        bash)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: direnv ---
if command -v direnv &>/dev/null; then
  eval "$(direnv hook bash)"
fi
BLOCK
            ;;
        fish)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: direnv ---
if command -v direnv &>/dev/null
  direnv hook fish | source
end
BLOCK
            ;;
        *)
            log_warn "Unsupported shell for direnv: $shell"
            return 0
            ;;
    esac
    append_block "$SHELL_RC" "toolbox-discovery: direnv" "$block"
}

activate_atuin() {
    require_tool atuin || return 0
    log_info "Activating atuin..."

    local shell="${SHELL##*/}"
    local block
    case "$shell" in
        zsh)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: atuin ---
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi
BLOCK
            ;;
        bash)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: atuin ---
if command -v atuin &>/dev/null; then
  eval "$(atuin init bash)"
fi
BLOCK
            ;;
        fish)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: atuin ---
if command -v atuin &>/dev/null
  atuin init fish | source
end
BLOCK
            ;;
        *)
            log_warn "Unsupported shell for atuin: $shell"
            return 0
            ;;
    esac
    append_block "$SHELL_RC" "toolbox-discovery: atuin" "$block"
}

activate_starship() {
    require_tool starship || return 0
    log_info "Activating starship prompt..."

    local shell="${SHELL##*/}"
    local block
    case "$shell" in
        zsh)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: starship ---
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
BLOCK
            ;;
        bash)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: starship ---
if command -v starship &>/dev/null; then
  eval "$(starship init bash)"
fi
BLOCK
            ;;
        fish)
            IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: starship ---
if command -v starship &>/dev/null
  starship init fish | source
end
BLOCK
            ;;
        *)
            log_warn "Unsupported shell for starship: $shell"
            return 0
            ;;
    esac
    append_block "$SHELL_RC" "toolbox-discovery: starship" "$block"

    # Create starter starship config if none exists
    local starship_config="$HOME/.config/starship.toml"
    if [[ ! -f "$starship_config" ]]; then
        if $DRY_RUN; then
            log_dry "Would create $starship_config with starter config"
        else
            mkdir -p "$(dirname "$starship_config")"
            cat > "$starship_config" << 'TOML'
# Starship configuration (generated by toolbox-discovery)
format = "$all"
add_newline = true

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = "[$symbol$branch]($style) "

[git_status]
format = '([$all_status$ahead_behind]($style) )'

[golang]
format = "[$symbol($version)]($style) "

[nodejs]
format = "[$symbol($version)]($style) "

[python]
format = "[$symbol($version)]($style) "

[rust]
format = "[$symbol($version)]($style) "

[time]
disabled = false
format = "[$time]($style) "
time_format = "%H:%M"
TOML
            log_ok "Created starter $starship_config"
            ((CHANGES_MADE++)) || true
        fi
    else
        log_skip "starship config already exists at $starship_config"
    fi
}

activate_ripgrep() {
    require_tool rg || return 0
    log_info "Activating ripgrep configuration..."

    local rg_config="$HOME/.ripgreprc"
    if [[ ! -f "$rg_config" ]]; then
        if $DRY_RUN; then
            log_dry "Would create $rg_config"
        else
            cat > "$rg_config" << 'EOF'
# ripgrep configuration (generated by toolbox-discovery)
--smart-case
--follow
--glob=!.git/
--glob=!node_modules/
--glob=!vendor/
--glob=!.venv/
--glob=!dist/
--glob=!build/
--glob=!target/
--glob=!__pycache__/
--max-columns=200
--max-columns-preview
EOF
            log_ok "Created $rg_config"
            ((CHANGES_MADE++)) || true
        fi
    else
        log_skip "ripgrep config already exists at $rg_config"
    fi

    # Set environment variable
    local block
    IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: ripgrep ---
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
BLOCK
    append_block "$SHELL_RC" "toolbox-discovery: ripgrep" "$block"
}

activate_tmux() {
    require_tool tmux || return 0
    log_info "Activating tmux configuration..."

    local tmux_conf="$HOME/.tmux.conf"
    if [[ ! -f "$tmux_conf" ]]; then
        if $DRY_RUN; then
            log_dry "Would create $tmux_conf with sensible defaults"
        else
            cat > "$tmux_conf" << 'EOF'
# tmux configuration (generated by toolbox-discovery)

# Better prefix
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Mouse support
set -g mouse on

# Start at 1
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# History
set -g history-limit 50000

# Colors
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Fast escape
set -sg escape-time 0
set -g focus-events on

# Split shortcuts
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Reload
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Status bar
set -g status-position top
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[bg=#89b4fa,fg=#1e1e2e,bold] #S '
set -g status-right '#[bg=#89b4fa,fg=#1e1e2e,bold] %H:%M '
setw -g window-status-format ' #I:#W '
setw -g window-status-current-format '#[bg=#f38ba8,fg=#1e1e2e,bold] #I:#W '
EOF
            log_ok "Created $tmux_conf"
            ((CHANGES_MADE++)) || true
        fi
    else
        log_skip "tmux config already exists at $tmux_conf"
    fi
}

activate_ollama() {
    require_tool ollama || return 0
    log_info "Activating ollama service..."

    if $DRY_RUN; then
        log_dry "Would run: sudo systemctl enable --now ollama"
    else
        if systemctl is-active --quiet ollama 2>/dev/null; then
            log_skip "ollama service is already running"
        else
            log_info "Enabling ollama service..."
            sudo systemctl enable --now ollama 2>/dev/null || {
                log_warn "Failed to enable ollama service (may need sudo)"
            }
            if systemctl is-active --quiet ollama 2>/dev/null; then
                log_ok "Ollama service started and enabled"
                ((CHANGES_MADE++)) || true
            fi
        fi
    fi
}

activate_git_aliases() {
    require_tool git || return 0
    log_info "Activating git aliases..."

    local aliases=(
        "s:status -sb"
        "co:checkout"
        "br:branch"
        "ci:commit"
        "ca:commit --amend"
        "d:diff"
        "ds:diff --staged"
        "lg:log --oneline --graph --decorate --all"
        "last:log -1 HEAD --stat"
        "unstage:reset HEAD --"
        "aliases:config --get-regexp alias"
        "branches:branch -a --sort=-committerdate"
    )

    if $DRY_RUN; then
        for alias_def in "${aliases[@]}"; do
            local name="${alias_def%%:*}"
            local value="${alias_def#*:}"
            log_dry "Would run: git config --global alias.$name '$value'"
        done
    else
        backup_file "$HOME/.gitconfig"
        for alias_def in "${aliases[@]}"; do
            local name="${alias_def%%:*}"
            local value="${alias_def#*:}"
            git config --global "alias.$name" "$value"
        done
        log_ok "Added ${#aliases[@]} git aliases"
        ((CHANGES_MADE++)) || true
    fi
}

activate_modern_aliases() {
    log_info "Activating modern tool aliases..."

    local block
    IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: modern-aliases ---
# Modern replacements (only activate if installed)
command -v eza &>/dev/null && alias ls='eza --icons --group-directories-first'
command -v eza &>/dev/null && alias ll='eza -l --icons --group-directories-first --git'
command -v eza &>/dev/null && alias la='eza -la --icons --group-directories-first --git'
command -v eza &>/dev/null && alias lt='eza --tree --icons --level=2 --group-directories-first'
command -v bat &>/dev/null && alias cat='bat --paging=never'
command -v dust &>/dev/null && alias du='dust'
command -v duf &>/dev/null && alias df='duf'
command -v btop &>/dev/null && alias top='btop'
BLOCK
    append_block "$SHELL_RC" "toolbox-discovery: modern-aliases" "$block"
}

activate_completions() {
    log_info "Installing shell completions..."

    local shell="${SHELL##*/}"
    if [[ "$shell" != "zsh" && "$shell" != "bash" ]]; then
        log_warn "Shell completions automation supports zsh and bash. Current shell: $shell"
        return 0
    fi

    local block
    IFS= read -r -d '' block <<'BLOCK' || true
# --- toolbox-discovery: completions ---
# Auto-load completions for detected tools
command -v kubectl &>/dev/null && source <(kubectl completion ${SHELL##*/} 2>/dev/null) || true
command -v helm &>/dev/null && source <(helm completion ${SHELL##*/} 2>/dev/null) || true
command -v gh &>/dev/null && eval "$(gh completion -s ${SHELL##*/} 2>/dev/null)" || true
command -v rustup &>/dev/null && eval "$(rustup completions ${SHELL##*/} 2>/dev/null)" || true
BLOCK
    append_block "$SHELL_RC" "toolbox-discovery: completions" "$block"
}

# --- Category dispatchers ---

activate_shell_category() {
    activate_fzf
    activate_zoxide
    activate_direnv
    activate_atuin
    activate_starship
    activate_completions
}

activate_git_category() {
    activate_delta
    activate_git_aliases
}

activate_modern_category() {
    activate_bat
    activate_eza
    activate_ripgrep
    activate_modern_aliases
}

activate_all() {
    activate_shell_category
    activate_git_category
    activate_modern_category
    activate_tmux
    activate_ollama
}

# --- Main execution ---

echo ""
printf "${BOLD}TOOLBOX ACTIVATION${RESET}\n"
printf "${DIM}%s${RESET}\n" "$(printf '%.0s-' {1..50})"
printf "Target:    %s\n" "$TARGET"
printf "Shell RC:  %s\n" "$SHELL_RC"
printf "Dry run:   %s\n" "$DRY_RUN"
printf "Backup:    %s\n" "$( $NO_BACKUP && echo 'disabled' || echo 'enabled' )"
echo ""

case "$TARGET" in
    # Individual tools
    fzf)         activate_fzf ;;
    bat)         activate_bat ;;
    eza)         activate_eza ;;
    delta)       activate_delta ;;
    zoxide)      activate_zoxide ;;
    direnv)      activate_direnv ;;
    atuin)       activate_atuin ;;
    starship)    activate_starship ;;
    ripgrep|rg)  activate_ripgrep ;;
    tmux)        activate_tmux ;;
    ollama)      activate_ollama ;;

    # Categories
    shell)       activate_shell_category ;;
    git)         activate_git_category ;;
    modern)      activate_modern_category ;;
    completions) activate_completions ;;
    all)         activate_all ;;

    *)
        echo "Error: Unknown target '$TARGET'. Use --help for available targets."
        exit 1
        ;;
esac

# --- Summary ---
echo ""
printf "${DIM}%s${RESET}\n" "$(printf '%.0s-' {1..50})"
if $DRY_RUN; then
    printf "${CYAN}Dry run complete.${RESET} No changes were made.\n"
else
    printf "${GREEN}Activation complete.${RESET} %d change(s) applied.\n" "$CHANGES_MADE"
    if [[ $CHANGES_MADE -gt 0 ]]; then
        echo ""
        printf "${YELLOW}Restart your shell or run:${RESET}\n"
        printf "  source %s\n" "$SHELL_RC"
    fi
    if ! $NO_BACKUP && [[ -d "$BACKUP_DIR" ]]; then
        echo ""
        printf "${BLUE}Backups saved to:${RESET} %s\n" "$BACKUP_DIR"
    fi
fi
echo ""
