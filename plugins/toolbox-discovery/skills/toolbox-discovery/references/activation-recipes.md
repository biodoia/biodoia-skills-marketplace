# Activation Recipes

Ready-to-apply configuration recipes for activating, integrating, and optimizing tools. Each recipe includes the configuration snippet, where to apply it, and what it does.

**Important:** Always back up existing configuration before applying any recipe.

---

## Shell Configuration (zsh)

### fzf Integration (zsh)

**What it does:** Enables ctrl-R (history search), ctrl-T (file finder), and alt-C (cd into directory) with fuzzy matching. Adds preview windows using bat and fd.

**Prerequisites:** `fzf`, optionally `fd`, `bat`, `eza`

**Add to `~/.zshrc`:**
```bash
# fzf configuration
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

# Use fd instead of find for fzf
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Preview with bat for files, eza for directories
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:60%"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --level=2 {}' --preview-window=right:50%"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=up:3:hidden:wrap --bind '?:toggle-preview'"

# Default fzf options
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline
  --margin=1
  --padding=1
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
'
```

---

### zoxide Integration (zsh)

**What it does:** Smart `cd` that learns your most-used directories. Type `z foo` to jump to the most frequently visited directory matching "foo".

**Prerequisites:** `zoxide`

**Add to `~/.zshrc`:**
```bash
# zoxide - smart cd
eval "$(zoxide init zsh)"

# Optional: replace cd entirely
# alias cd='z'
```

---

### direnv Integration (zsh)

**What it does:** Automatically loads/unloads environment variables when entering/leaving directories with `.envrc` files.

**Prerequisites:** `direnv`

**Add to `~/.zshrc`:**
```bash
# direnv - per-directory environments
eval "$(direnv hook zsh)"
```

---

### atuin Integration (zsh)

**What it does:** Replaces ctrl-R with a powerful, searchable, synced shell history database.

**Prerequisites:** `atuin`

**Add to `~/.zshrc`:**
```bash
# atuin - enhanced shell history
eval "$(atuin init zsh)"
```

---

### starship Prompt (any shell)

**What it does:** Fast, customizable, cross-shell prompt showing git status, language versions, command duration, and more.

**Prerequisites:** `starship`

**Add to `~/.zshrc` (zsh):**
```bash
eval "$(starship init zsh)"
```

**Add to `~/.bashrc` (bash):**
```bash
eval "$(starship init bash)"
```

**Add to `~/.config/fish/config.fish` (fish):**
```fish
starship init fish | source
```

**Starter config at `~/.config/starship.toml`:**
```toml
# Cyberpunk-style prompt
format = """
[](#9A348E)$os$username\
[](bg:#DA627D fg:#9A348E)$directory\
[](fg:#DA627D bg:#FCA17D)$git_branch$git_status\
[](fg:#FCA17D bg:#86BBD8)$golang$nodejs$python$rust\
[](fg:#86BBD8 bg:#06969A)$docker_context$kubernetes\
[](fg:#06969A bg:#33658A)$time\
[ ](fg:#33658A)\
\n$character"""

[directory]
style = "bg:#DA627D fg:#1e1e2e"
format = "[ $path ]($style)"
truncation_length = 3

[git_branch]
style = "bg:#FCA17D fg:#1e1e2e"
format = "[ $symbol$branch ]($style)"

[git_status]
style = "bg:#FCA17D fg:#1e1e2e"
format = "[$all_status$ahead_behind ]($style)"

[golang]
style = "bg:#86BBD8 fg:#1e1e2e"
format = "[ $symbol($version) ]($style)"

[nodejs]
style = "bg:#86BBD8 fg:#1e1e2e"
format = "[ $symbol($version) ]($style)"

[python]
style = "bg:#86BBD8 fg:#1e1e2e"
format = "[ $symbol($version) ]($style)"

[rust]
style = "bg:#86BBD8 fg:#1e1e2e"
format = "[ $symbol($version) ]($style)"

[time]
disabled = false
time_format = "%R"
style = "bg:#33658A fg:#1e1e2e"
format = "[  $time ]($style)"

[character]
success_symbol = "[>](bold green)"
error_symbol = "[>](bold red)"
```

---

## Shell Completions

### Install completions for common tools

**Add to `~/.zshrc`:**
```bash
# Docker completions
if command -v docker &>/dev/null; then
  # Docker provides completions via the CLI
  # Ensure the completions directory exists
  mkdir -p ~/.zsh/completions
  docker completion zsh > ~/.zsh/completions/_docker 2>/dev/null
fi

# kubectl completions
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
fi

# helm completions
if command -v helm &>/dev/null; then
  source <(helm completion zsh)
fi

# gh (GitHub CLI) completions
if command -v gh &>/dev/null; then
  eval "$(gh completion -s zsh)"
fi

# rustup and cargo completions
if command -v rustup &>/dev/null; then
  eval "$(rustup completions zsh)"
  eval "$(rustup completions zsh cargo)"
fi

# Add custom completions directory to fpath
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

---

## Modern Tool Aliases

### Replace classic tools with modern alternatives

**Add to `~/.zshrc` or `~/.bash_aliases`:**
```bash
# Modern replacements (only if installed)

# eza replaces ls
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
  alias lt='eza --tree --icons --level=2 --group-directories-first'
  alias lta='eza --tree --icons --level=2 --group-directories-first -a'
fi

# bat replaces cat
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat'  # with pager
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
  # Use bat for --help output
  alias bathelp='bat --plain --language=help'
  help() { "$@" --help 2>&1 | bathelp; }
fi

# fd replaces find
if command -v fd &>/dev/null; then
  alias find='fd'
fi

# ripgrep replaces grep
if command -v rg &>/dev/null; then
  alias grep='rg'
fi

# dust replaces du
if command -v dust &>/dev/null; then
  alias du='dust'
fi

# duf replaces df
if command -v duf &>/dev/null; then
  alias df='duf'
fi

# btop replaces top/htop
if command -v btop &>/dev/null; then
  alias top='btop'
  alias htop='btop'
fi

# procs replaces ps
if command -v procs &>/dev/null; then
  alias ps='procs'
fi
```

---

## Git Configuration

### Delta as git pager

**What it does:** Beautiful syntax-highlighted diffs, side-by-side view, line numbers, and git log integration.

**Prerequisites:** `delta`, optionally `bat`

**Run these commands:**
```bash
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate true
git config --global delta.dark true
git config --global delta.line-numbers true
git config --global delta.side-by-side false
git config --global delta.syntax-theme "Dracula"
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default
```

**Or add to `~/.gitconfig`:**
```ini
[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    dark = true
    line-numbers = true
    side-by-side = false
    syntax-theme = Dracula

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default
```

---

### Git aliases for productivity

**Add to `~/.gitconfig`:**
```ini
[alias]
    s = status -sb
    co = checkout
    br = branch
    ci = commit
    ca = commit --amend
    cp = cherry-pick
    d = diff
    ds = diff --staged
    lg = log --oneline --graph --decorate --all
    lga = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all
    last = log -1 HEAD --stat
    unstage = reset HEAD --
    undo = reset --soft HEAD~1
    stash-all = stash save --include-untracked
    aliases = config --get-regexp alias
    branches = branch -a --sort=-committerdate
    tags = tag -l --sort=-version:refname
    remotes = remote -v
    contributors = shortlog --summary --numbered
    # Quick fixup
    fixup = "!f() { git commit --fixup=$1; }; f"
    # Delete merged branches
    cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d"
```

---

### Git hooks with pre-commit

**Prerequisites:** `pre-commit`

**Setup:**
```bash
# Install pre-commit hooks in a repo
cd /path/to/repo
pre-commit install

# Create a starter config
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: detect-private-key
EOF

# Run on all files once
pre-commit run --all-files
```

---

## tmux Configuration

### Sensible tmux defaults

**Write to `~/.tmux.conf`:**
```bash
# Better prefix
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows on close
set -g renumber-windows on

# Increase history
set -g history-limit 50000

# Better colors
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Fast escape time
set -sg escape-time 0

# Focus events
set -g focus-events on

# Easy split
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Easy pane navigation (vim-style)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Status bar
set -g status-position top
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[bg=#89b4fa,fg=#1e1e2e,bold] #S '
set -g status-right '#[bg=#89b4fa,fg=#1e1e2e,bold] %H:%M '
set -g status-left-length 50
set -g status-right-length 50

# Window status
setw -g window-status-format ' #I:#W '
setw -g window-status-current-format '#[bg=#f38ba8,fg=#1e1e2e,bold] #I:#W '
```

---

## Environment Variables

### Essential environment setup

**Add to `~/.zshrc` or `~/.bashrc`:**
```bash
# Editor
export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"

# Pager
export PAGER="less"
export LESS="-R --quit-if-one-screen"

# MANPAGER with bat
if command -v bat &>/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Node (pnpm)
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Python
export PYTHONDONTWRITEBYTECODE=1

# ripgrep config
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# GPG
export GPG_TTY=$(tty)

# Docker (rootless)
# export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
```

---

## Integration Chains

### ripgrep + fzf: Fuzzy Code Search

**Add to `~/.zshrc`:**
```bash
# Interactive ripgrep with fzf preview
rgf() {
  rg --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(nvim {1} +{2})'
}
```

---

### Git + fzf: Fuzzy Git Operations

**Add to `~/.zshrc`:**
```bash
# Fuzzy checkout branch
gcob() {
  local branches branch
  branches=$(git branch --all --sort=-committerdate | grep -v HEAD) &&
  branch=$(echo "$branches" | fzf --height=40% --reverse --info=inline) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# Fuzzy git log browser
glog() {
  git log --oneline --graph --color=always --all |
    fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'git show --color=always $(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1)' \
        --bind 'enter:become(git show --color=always $(echo {} | grep -o "[a-f0-9]\{7,\}" | head -1) | less -R)'
}

# Fuzzy git add
gadd() {
  local files
  files=$(git status -s | fzf --multi --preview 'git diff --color=always {2}' | awk '{print $2}')
  [ -n "$files" ] && echo "$files" | xargs git add && git status -sb
}
```

---

### Docker + fzf: Fuzzy Docker Operations

**Add to `~/.zshrc`:**
```bash
# Fuzzy docker container operations
dps() {
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" |
    fzf --header-lines=1 --preview 'docker logs --tail=50 $(echo {} | awk "{print \$1}")' \
        --bind 'ctrl-s:execute(docker stop $(echo {} | awk "{print \$1}"))' \
        --bind 'ctrl-r:execute(docker restart $(echo {} | awk "{print \$1}"))' \
        --bind 'enter:execute(docker exec -it $(echo {} | awk "{print \$1}") sh)'
}

# Fuzzy docker image selection
dimg() {
  docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" |
    fzf --header-lines=1
}
```

---

## Ollama (Local AI)

### Setup and optimization

**Start and enable ollama service:**
```bash
sudo systemctl enable --now ollama
```

**Pull common models:**
```bash
# Code models
ollama pull codellama
ollama pull deepseek-coder-v2

# General models
ollama pull llama3.1
ollama pull mistral

# Embedding models
ollama pull nomic-embed-text

# Small/fast models
ollama pull phi3
ollama pull gemma2
```

**Environment setup for ollama:**
```bash
# Add to ~/.zshrc
export OLLAMA_HOST="127.0.0.1:11434"
# For GPU layers (adjust based on VRAM)
# export OLLAMA_NUM_GPU=99
```

---

## ripgrep Configuration

**Write to `~/.ripgreprc`:**
```
# Smart case search
--smart-case

# Follow symlinks
--follow

# Add file types
--type-add=web:*.{html,css,js,ts,jsx,tsx,vue,svelte}
--type-add=config:*.{json,yaml,yml,toml,ini,conf}
--type-add=doc:*.{md,rst,txt,adoc}

# Exclude directories
--glob=!.git/
--glob=!node_modules/
--glob=!vendor/
--glob=!.venv/
--glob=!dist/
--glob=!build/
--glob=!target/
--glob=!__pycache__/

# Max columns for display
--max-columns=200
--max-columns-preview
```

---

## Productivity Functions

### General-purpose shell functions

**Add to `~/.zshrc`:**
```bash
# Create directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"    ;;
      *.tar.gz)    tar xzf "$1"    ;;
      *.tar.xz)    tar xJf "$1"    ;;
      *.bz2)       bunzip2 "$1"    ;;
      *.rar)       unrar x "$1"    ;;
      *.gz)        gunzip "$1"     ;;
      *.tar)       tar xf "$1"     ;;
      *.tbz2)      tar xjf "$1"    ;;
      *.tgz)       tar xzf "$1"    ;;
      *.zip)       unzip "$1"      ;;
      *.Z)         uncompress "$1" ;;
      *.7z)        7z x "$1"       ;;
      *.zst)       unzstd "$1"     ;;
      *)           echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Quick HTTP server
serve() { python3 -m http.server "${1:-8000}"; }

# Show PATH entries, one per line
path() { echo "$PATH" | tr ':' '\n' | sort -u; }

# Weather
weather() { curl "wttr.in/${1:-}"; }

# Cheat sheet
cheat() { curl "cheat.sh/$1"; }

# Quick notes
note() {
  local notes_dir="$HOME/.notes"
  mkdir -p "$notes_dir"
  if [ $# -eq 0 ]; then
    ls -1t "$notes_dir"
  else
    echo "$(date +%Y-%m-%d\ %H:%M): $*" >> "$notes_dir/quick.md"
    echo "Note saved."
  fi
}

# Port check
port() { ss -tlnp | grep ":$1 " || echo "Port $1 is free"; }

# Process on port
whoport() { lsof -i ":$1" 2>/dev/null || ss -tlnp | grep ":$1 "; }
```
