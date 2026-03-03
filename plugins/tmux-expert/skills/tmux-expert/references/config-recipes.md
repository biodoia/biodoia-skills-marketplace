# tmux Configuration Recipes

Ready-to-use `.tmux.conf` configurations. Copy the desired recipe into `~/.tmux.conf` and reload with `tmux source-file ~/.tmux.conf`.

---

## 1. Minimal Modern Config

A clean starting point with sensible defaults. No plugins required.

```bash
# ── Minimal Modern tmux Config ──────────────────────────────────────

# Prefix: C-a (like screen, easier to reach)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Terminal and colors
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Basics
set -g mouse on
set -g history-limit 10000
set -sg escape-time 0
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# vi mode in copy mode
setw -g mode-keys vi

# Intuitive splits (in current pane's directory)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind %
unbind '"'

# New window in current directory
bind c new-window -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"

# Status bar
set -g status-position bottom
set -g status-style "bg=default,fg=white"
set -g status-left "#[fg=green,bold] #S "
set -g status-right "#[fg=cyan]%H:%M "
setw -g window-status-current-style "fg=green,bold"
setw -g window-status-format " #I:#W "
setw -g window-status-current-format " #I:#W "
```

---

## 2. Power User Config

Full-featured config with vi navigation, mouse, true color, clipboard integration, and TPM plugins.

```bash
# ── Power User tmux Config ──────────────────────────────────────────

# ── Prefix ──
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# ── Terminal ──
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -ga terminal-overrides ",alacritty:Tc"
set -ga terminal-overrides ",xterm-kitty:Tc"

# ── General ──
set -g mouse on
set -g history-limit 50000
set -sg escape-time 0
set -g repeat-time 600
set -g display-time 2000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g focus-events on
set -g aggressive-resize on
set -g set-clipboard on

# ── Vi Mode ──
setw -g mode-keys vi
set -g status-keys vi

# Copy mode vi bindings
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi V send -X select-line
bind -T copy-mode-vi C-v send -X rectangle-toggle
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null || pbcopy"
bind -T copy-mode-vi Escape send -X cancel

# ── Splits and Windows ──
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind \\ split-window -fh -c "#{pane_current_path}"  # Full-width vertical
bind _ split-window -fv -c "#{pane_current_path}"    # Full-height horizontal
bind c new-window -c "#{pane_current_path}"
unbind %
unbind '"'

# ── Pane Navigation (vim-like) ──
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# ── Pane Resizing (vim-like, repeatable) ──
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ── Window Navigation ──
bind -r [ previous-window
bind -r ] next-window
bind Tab last-window

# ── Swap Panes ──
bind -r < swap-pane -U
bind -r > swap-pane -D

# ── Join/Break Panes ──
bind @ join-pane -h -s !    # Join last pane horizontally
bind B break-pane            # Break pane to window

# ── Reload ──
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"

# ── Popup (tmux 3.2+) ──
bind g display-popup -w 80% -h 80% -d "#{pane_current_path}" -E "lazygit"
bind f display-popup -w 80% -h 80% -d "#{pane_current_path}" -E "fzf --preview 'head -80 {}'"

# ── Status Bar ──
set -g status-position top
set -g status-interval 5
set -g status-style "bg=colour235,fg=colour248"
set -g status-left-length 30
set -g status-right-length 50
set -g status-left "#[fg=colour232,bg=colour39,bold] #S #[fg=colour39,bg=colour235,nobold] "
set -g status-right "#{?client_prefix,#[fg=colour232,bg=colour208,bold] PREFIX ,}#[fg=colour248,bg=colour235] %H:%M #[fg=colour232,bg=colour248,bold] %d %b "
setw -g window-status-format "#[fg=colour248,bg=colour235] #I #W "
setw -g window-status-current-format "#[fg=colour232,bg=colour39,bold] #I #W "

# Pane borders
set -g pane-border-style "fg=colour238"
set -g pane-active-border-style "fg=colour39"

# Message style
set -g message-style "bg=colour39,fg=colour232,bold"

# ── Plugins (TPM) ──
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

# Resurrect settings
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim 'session'

# Continuum settings
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Initialize TPM (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
```

---

## 3. Cyberpunk Themed Config

Neon colors, aggressive styling, and visual flair. Uses a magenta/cyan/green neon palette against dark backgrounds.

```bash
# ── Cyberpunk tmux Config ───────────────────────────────────────────
# Neon palette: magenta=#ff00ff, cyan=#00ffff, green=#00ff00
# Background: #0d0d0d, panel: #1a1a2e, border: #16213e

# ── Prefix ──
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix

# ── Terminal ──
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# ── General ──
set -g mouse on
set -g history-limit 50000
set -sg escape-time 0
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g focus-events on
set -g set-clipboard on
setw -g mode-keys vi

# ── Splits ──
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
unbind %
unbind '"'

# ── Vim Navigation ──
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ── Reload ──
bind r source-file ~/.tmux.conf \; display-message "#[fg=#00ff00,bold]>> SYSTEM RELOADED <<"

# ── Popup ──
bind g display-popup -w 80% -h 80% -d "#{pane_current_path}" -E "lazygit"

# ── Copy Mode ──
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null"

# ──────────────────────────────────────────────────────────────────────
# ── CYBERPUNK STATUS BAR ─────────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────

set -g status-position top
set -g status-interval 1
set -g status-justify left

# Status bar base
set -g status-style "bg=#0d0d0d,fg=#00ffff"

# Left: session name in neon box
set -g status-left-length 40
set -g status-left "\
#[fg=#0d0d0d,bg=#ff00ff,bold] #S \
#[fg=#ff00ff,bg=#1a1a2e] \
#[fg=#00ffff,bg=#1a1a2e] #{?client_prefix,#[fg=#00ff00]ACTIVE,#[fg=#555555]IDLE} \
#[fg=#1a1a2e,bg=#0d0d0d] "

# Right: time and host in neon
set -g status-right-length 60
set -g status-right "\
#[fg=#1a1a2e,bg=#0d0d0d]\
#[fg=#00ffff,bg=#1a1a2e] #(whoami)@#H \
#[fg=#ff00ff,bg=#1a1a2e]\
#[fg=#0d0d0d,bg=#ff00ff,bold] %H:%M:%S \
#[fg=#00ff00,bg=#ff00ff]\
#[fg=#0d0d0d,bg=#00ff00,bold] %d/%m "

# Window tabs
setw -g window-status-format "\
#[fg=#0d0d0d,bg=#1a1a2e]\
#[fg=#555555,bg=#1a1a2e] #I:#W \
#[fg=#1a1a2e,bg=#0d0d0d]"

setw -g window-status-current-format "\
#[fg=#0d0d0d,bg=#00ffff]\
#[fg=#0d0d0d,bg=#00ffff,bold] #I:#W \
#[fg=#00ffff,bg=#0d0d0d]"

setw -g window-status-separator ""

# Pane borders
set -g pane-border-style "fg=#1a1a2e"
set -g pane-active-border-style "fg=#ff00ff"

# Pane number display
set -g display-panes-active-colour "#ff00ff"
set -g display-panes-colour "#00ffff"
set -g display-panes-time 2000

# Message and command prompt
set -g message-style "bg=#ff00ff,fg=#0d0d0d,bold"
set -g message-command-style "bg=#00ffff,fg=#0d0d0d,bold"

# Clock
setw -g clock-mode-colour "#00ff00"
setw -g clock-mode-style 24

# Copy mode highlight
setw -g mode-style "bg=#ff00ff,fg=#0d0d0d,bold"

# Bell
set -g visual-bell on
set -g bell-action any
setw -g window-status-bell-style "bg=#00ff00,fg=#0d0d0d,bold"

# ── Plugins ──
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

set -g @resurrect-capture-pane-contents 'on'
set -g @continuum-restore 'on'

run '~/.tmux/plugins/tpm/tpm'
```

---

## 4. Developer Workflow Config

Focused on development workflows: git info in status bar, smart pane management, project-oriented bindings.

```bash
# ── Developer Workflow tmux Config ──────────────────────────────────

# ── Prefix ──
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# ── Terminal ──
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# ── General ──
set -g mouse on
set -g history-limit 50000
set -sg escape-time 0
set -g repeat-time 800
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g focus-events on
set -g aggressive-resize on
set -g set-clipboard on
setw -g mode-keys vi
set -g status-keys vi

# ── Directory-Aware Splits ──
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind \\ split-window -fh -c "#{pane_current_path}"
bind _ split-window -fv -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
unbind %
unbind '"'

# ── Pane Navigation ──
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ── Window Navigation ──
bind Tab last-window
bind -r [ previous-window
bind -r ] next-window

# ── Quick Layouts ──
# Three-column layout (editor | terminal | terminal)
bind M-e select-layout "bdc5,240x60,0,0{120x60,0,0,0,60x60,120,0,1,59x60,181,0,2}"
# Main-vertical (big editor left, small terminals right)
bind M-v select-layout main-vertical
# Main-horizontal (big top, small bottom)
bind M-h select-layout main-horizontal
# Tiled (equal panes)
bind M-t select-layout tiled

# ── Copy Mode ──
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi V send -X select-line
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "xclip -selection clipboard 2>/dev/null || wl-copy 2>/dev/null || pbcopy"

# ── Reload ──
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"

# ── Popup Tools (tmux 3.2+) ──
bind g display-popup -w 85% -h 85% -d "#{pane_current_path}" -E "lazygit"
bind f display-popup -w 80% -h 80% -d "#{pane_current_path}" -E "fzf --preview 'bat --color=always --style=numbers --line-range=:80 {} 2>/dev/null || head -80 {}'"
bind G display-popup -w 60% -h 40% -d "#{pane_current_path}" -E "git log --oneline -20"
bind T display-popup -w 80% -h 80% -d "#{pane_current_path}" -E "htop"

# ── Session Shortcuts ──
# Quick switch between recent sessions
bind Space switch-client -l
# Create new session from current directory
bind N command-prompt -p "New session name:" "new-session -s '%%' -c '#{pane_current_path}'"
# Kill session without switching to another
bind X confirm-before -p "Kill session #S? (y/n)" kill-session

# ── Pane Sync (type in all panes at once) ──
bind S setw synchronize-panes \; display-message "#{?pane_synchronized,Sync ON,Sync OFF}"

# ── Mark and Swap ──
bind m select-pane -m      # Mark current pane
bind M swap-pane            # Swap with marked pane

# ── Project Launcher ──
# Bind prefix + P to pick a project directory and open it in a new session
bind P display-popup -w 60% -h 60% -E "\
  dir=$(find ~/projects /mnt/godata/projects -maxdepth 1 -type d 2>/dev/null | fzf --header='Select Project') && \
  name=$(basename \"$dir\") && \
  tmux new-session -d -s \"$name\" -c \"$dir\" 2>/dev/null; \
  tmux switch-client -t \"$name\""

# ──────────────────────────────────────────────────────────────────────
# ── STATUS BAR WITH GIT INFO ─────────────────────────────────────────
# ──────────────────────────────────────────────────────────────────────

set -g status-position top
set -g status-interval 5
set -g status-justify left

# Colors
set -g status-style "bg=colour234,fg=colour250"

# Left: session + window/pane indicator
set -g status-left-length 50
set -g status-left "\
#[fg=colour232,bg=colour214,bold] #S \
#[fg=colour214,bg=colour238]\
#[fg=colour250,bg=colour238] #I:#P \
#[fg=colour238,bg=colour234] "

# Right: git branch + status + time
# Uses a shell command to get the git branch from the active pane's directory
set -g status-right-length 80
set -g status-right "\
#[fg=colour238,bg=colour234]\
#[fg=colour214,bg=colour238] \
#(cd #{pane_current_path} && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')\
#{?#{==:#(cd #{pane_current_path} && git status --porcelain 2>/dev/null | head -1),},#[fg=colour34] ok,#[fg=colour196] dirty} \
#[fg=colour234,bg=colour238]\
#[fg=colour250,bg=colour234] \
#[fg=colour232,bg=colour250,bold] %H:%M "

# Window tabs
setw -g window-status-format " #[fg=colour244]#I:#[fg=colour250]#W#[fg=colour244]#F "
setw -g window-status-current-format "#[fg=colour234,bg=colour214]#[fg=colour232,bg=colour214,bold] #I:#W#F #[fg=colour214,bg=colour234]"
setw -g window-status-separator ""

# Pane borders
set -g pane-border-style "fg=colour238"
set -g pane-active-border-style "fg=colour214"

# Messages
set -g message-style "bg=colour214,fg=colour232,bold"

# ── Hooks ──
# Auto-rename window to current directory basename
set-hook -g after-select-pane "run-shell 'tmux rename-window \"$(basename #{pane_current_path})\"'"

# ── Plugins ──
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'sainnhe/tmux-fzf'

# Resurrect settings
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-processes ':all:'

# Continuum
set -g @continuum-restore 'on'
set -g @continuum-save-interval '10'

# Initialize TPM (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
```

---

## Shared Snippets

These snippets can be appended to any config above.

### Nested tmux Toggle (F12)

For SSH into remote tmux sessions. Pressing F12 disables the outer tmux so all keys go to the inner one:

```bash
bind -T root F12  \
  set prefix None \;\
  set key-table off \;\
  set status-style "bg=colour238,fg=colour242" \;\
  set window-status-current-format "#[fg=colour242,bg=colour238] #I:#W " \;\
  if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
  refresh-client -S

bind -T off F12 \
  set -u prefix \;\
  set -u key-table \;\
  set -u status-style \;\
  set -u window-status-current-format \;\
  refresh-client -S
```

### Automatic Window Renaming

```bash
setw -g automatic-rename on
setw -g automatic-rename-format "#{?#{==:#{pane_current_command},zsh},#{b:pane_current_path},#{pane_current_command}}"
```

### Pane Synchronization Indicator

Show a visible indicator when pane sync is on:

```bash
# Add to status-right:
#{?pane_synchronized,#[fg=colour232,bg=colour196,bold] SYNC ,}
```

### Session Persistence Across Reboots

Requires `tmux-resurrect` and `tmux-continuum`:

```bash
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim 'session'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '10'
set -g @continuum-boot 'on'           # auto-start tmux on boot (macOS/systemd)
```

### Logging Pane Output

```bash
# Bind prefix + P to toggle logging the current pane to a file
bind P pipe-pane -o "cat >> ~/tmux-logs/#W-#P-$(date +%Y%m%d%H%M%S).log" \; display-message "#{?#{==:#{pane_pipe},},Logging OFF,Logging ON}"
```
