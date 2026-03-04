---
name: tmux-expert
description: This skill should be used when the user asks about "tmux", "terminal multiplexer", "tmux.conf", "tmux plugins", "tpm", "tmuxinator", "tmuxp", "detach", "attach", or "pane splitting". Make sure to use this skill whenever the user needs help with tmux sessions, windows, panes, configuration, scripting, keybindings, copy mode, status bar customization, or troubleshooting, even if they just mention persistent terminal sessions, window management in the terminal, or surviving SSH disconnections without explicitly saying tmux.
---

# tmux Expert

tmux (terminal multiplexer) runs multiple terminal sessions inside a single window, detaches them from the controlling terminal, and reattaches later. Sessions survive disconnections, making tmux essential for remote work, long-running processes, and complex development workflows.

## Core Concepts

### Server / Client Model

tmux operates as a client-server system. The **server** holds all sessions in memory and runs in the background. Each terminal that connects is a **client**. On detach, the client disconnects but the server (and all sessions) keeps running. The server starts automatically on the first tmux command and exits when the last session is destroyed.

The server socket lives at `/tmp/tmux-$UID/default` by default. Run multiple servers with `tmux -L <socket-name>` for complete isolation.

### Sessions, Windows, Panes

tmux has a three-level hierarchy:

- **Session**: A named collection of windows. Sessions are the top-level unit for attach/detach. Each session has one active window.
- **Window**: A single full-screen view within a session, similar to tabs. Each window has one or more panes.
- **Pane**: A rectangular subdivision of a window. Each pane runs its own shell (or any process). Panes share the window space via splits.

Typical usage: one session per project, multiple windows per task area (editor, server, logs), panes for side-by-side views.

### The Prefix Key

tmux keybindings start with a **prefix** key combination. The default prefix is `C-b` (Ctrl+b). Press the prefix, release it, then press the action key. For example, `C-b c` creates a new window: press Ctrl+b, release, press c.

Popular rebindings include `C-a` (like GNU screen, closer to home row) and `C-Space` (easy to reach, no conflict with readline).

Rebind in `.tmux.conf`:
```
unbind C-b
set -g prefix C-a
bind C-a send-prefix
```

The `send-prefix` binding sends the prefix key itself to programs inside tmux (press prefix twice).

For the complete keybinding reference, see `references/keybindings-cheatsheet.md`.

## Command Line Usage

### Session Operations

```bash
tmux                              # Start new unnamed session
tmux new -s work                  # New session named "work"
tmux new -s work -d               # New session, detached (background)
tmux ls                           # List all sessions
tmux attach -t work               # Attach to session "work"
tmux attach -t work -d            # Attach and detach other clients
tmux switch -t work               # Switch client to session "work"
tmux kill-session -t work         # Destroy session "work"
tmux kill-server                  # Destroy ALL sessions and the server
tmux rename-session -t old new    # Rename session
tmux has-session -t work          # Check if session exists (exit code)
```

### Window and Pane Operations

```bash
tmux new-window -t work           # New window in session "work"
tmux split-window -h              # Split current pane horizontally (left/right)
tmux split-window -v              # Split current pane vertically (top/bottom)
tmux select-pane -t 0             # Select pane 0
tmux select-pane -L/-R/-U/-D      # Select pane by direction
tmux resize-pane -L 5             # Resize pane 5 cells left
tmux swap-pane -s 0 -t 1          # Swap panes 0 and 1
tmux join-pane -s 1 -t 0          # Move pane from window 1 to window 0
tmux break-pane                   # Move current pane to its own window
```

### Scripting Essentials

```bash
tmux send-keys -t work:0.1 "make build" Enter   # Type and execute in pane
tmux source-file ~/.tmux.conf                     # Reload configuration
tmux display-message "#{session_name}"            # Show format variable
tmux capture-pane -p -t 0                         # Print pane content to stdout
tmux save-buffer /tmp/tmux-buf.txt                # Save paste buffer to file
tmux list-keys                                    # Dump all keybindings
tmux show-options -g                              # Show all global options
```

## Configuration (.tmux.conf)

tmux reads `~/.tmux.conf` on server start. Reload without restarting with `tmux source-file ~/.tmux.conf` or bind a reload key.

### Option Types

```bash
set -g option value       # Set a global session option
setw -g option value      # Set a global window option (alias: set-window-option)
set -s option value       # Set a server option
set -g -a option value    # Append to an option value
```

### Essential Settings

```bash
set -g default-terminal "tmux-256color"    # Proper terminal type
set -ga terminal-overrides ",*256col*:Tc"  # Enable true color
set -g mouse on                            # Enable mouse (scroll, click, resize)
set -g history-limit 50000                 # Scrollback buffer size
set -sg escape-time 0                      # No delay after Escape (critical for vim)
set -g base-index 1                        # Windows start at 1, not 0
setw -g pane-base-index 1                  # Panes start at 1
set -g renumber-windows on                 # Renumber windows when one is closed
setw -g mode-keys vi                       # vi keys in copy mode
set -g status-keys vi                      # vi keys in command prompt
```

### Key Bindings

```bash
bind key command           # Bind prefix + key
bind -n key command        # Bind key directly (no prefix needed)
bind -r key command        # Repeatable binding (hold prefix, press key multiple times)
bind -T copy-mode-vi key command   # Bind in vi copy mode table
unbind key                 # Remove a binding
```

For complete ready-to-use configurations (minimal, power user, cyberpunk themed, developer workflow), see `references/config-recipes.md`.

## Popular Plugins (via TPM)

TPM (Tmux Plugin Manager) is the standard plugin manager. Install it:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Add to `.tmux.conf`:
```bash
set -g @plugin 'tmux-plugins/tpm'
# ... other plugins ...
run '~/.tmux/plugins/tpm/tpm'
```

Install plugins: `prefix + I`. Update: `prefix + U`. Uninstall removed plugins: `prefix + alt + u`.

### Key Plugins

| Plugin | Purpose |
|--------|---------|
| `tmux-plugins/tmux-sensible` | Universal sane defaults |
| `tmux-plugins/tmux-resurrect` | Save and restore sessions across restarts (`prefix + C-s` save, `prefix + C-r` restore) |
| `tmux-plugins/tmux-continuum` | Automatic session saving (every 15 min) and auto-restore on server start |
| `tmux-plugins/tmux-yank` | Clipboard integration (copies to system clipboard automatically) |
| `tmux-plugins/tmux-pain-control` | Intuitive pane bindings: `prefix + h/j/k/l` navigate, `prefix + H/J/K/L` resize |
| `sainnhe/tmux-fzf` | Fuzzy finder for sessions, windows, panes, keybindings, and commands |
| `tmux-plugins/tmux-prefix-highlight` | Status bar indicator when prefix is active |
| `tmux-plugins/tmux-open` | Open highlighted file/URL from copy mode |

## Scripting and Automation

### Session Templates (tmuxinator / tmuxp)

**tmuxinator** (Ruby) uses YAML templates:
```yaml
# ~/.config/tmuxinator/dev.yml
name: dev
root: ~/projects/myapp
windows:
  - editor:
      layout: main-vertical
      panes:
        - vim
        - # empty shell
  - server: npm start
  - logs: tail -f log/development.log
```
Run: `tmuxinator start dev`

**tmuxp** (Python) is similar:
```yaml
# ~/.config/tmuxp/dev.yaml
session_name: dev
start_directory: ~/projects/myapp
windows:
  - window_name: editor
    layout: main-vertical
    panes:
      - shell_command: vim
      - shell_command: ""
  - window_name: server
    panes:
      - shell_command: npm start
```
Run: `tmuxp load dev`

### Shell Script Layout

```bash
#!/bin/bash
SESSION="dev"
tmux new-session -d -s "$SESSION" -n editor
tmux send-keys -t "$SESSION:editor" "vim ." Enter
tmux split-window -h -t "$SESSION:editor"
tmux new-window -t "$SESSION" -n server
tmux send-keys -t "$SESSION:server" "npm start" Enter
tmux new-window -t "$SESSION" -n logs
tmux send-keys -t "$SESSION:logs" "tail -f /var/log/app.log" Enter
tmux select-window -t "$SESSION:editor"
tmux attach -t "$SESSION"
```

### Hooks

tmux supports hooks that run commands on events:
```bash
set-hook -g after-new-window 'rename-window ""'
set-hook -g after-split-window 'select-layout tiled'
set-hook -g pane-died 'respawn-pane -k'
set-hook -g session-created 'display-message "Session created"'
```

Available hooks include: `after-new-session`, `after-new-window`, `after-split-window`, `pane-died`, `pane-focus-in`, `pane-focus-out`, `window-renamed`, `session-closed`, and many more.

### Format Variables

tmux exposes rich format variables for scripting and status bars:

| Variable | Description |
|----------|-------------|
| `#{session_name}` | Current session name |
| `#{window_index}` | Current window index |
| `#{window_name}` | Current window name |
| `#{pane_current_path}` | Current pane working directory |
| `#{pane_current_command}` | Command running in pane |
| `#{pane_pid}` | PID of the pane process |
| `#{pane_width}` / `#{pane_height}` | Pane dimensions |
| `#{client_termtype}` | Client terminal type |
| `#{host}` | Hostname |

Use conditionals: `#{?condition,true-value,false-value}` and string comparison: `#{==:#{pane_current_command},vim}`.

## Advanced Topics

### Nested tmux (SSH)

When running tmux inside tmux (e.g., local tmux + remote tmux over SSH), send the prefix to the inner session with a common pattern:

```bash
# In local .tmux.conf: press prefix twice to send prefix to inner tmux
bind C-a send-prefix   # if the prefix is C-a
```

Alternatively, use a different prefix on the remote machine (e.g., local uses `C-a`, remote uses `C-b`).

A more sophisticated approach toggles the outer session off when working in the inner one. See `references/config-recipes.md` (Shared Snippets > Nested tmux Toggle) for the full F12 toggle recipe.

### Popup Windows (tmux 3.2+)

```bash
# Open a popup running a command
tmux display-popup -E "htop"
tmux display-popup -w 80% -h 80% -E "lazygit"

# Bind popup to a key
bind g display-popup -w 80% -h 80% -E "lazygit"
bind f display-popup -w 80% -h 80% -E "fzf --preview 'cat {}'"
```

Popup flags: `-w` width, `-h` height, `-x`/`-y` position, `-d` starting directory, `-E` close popup when command exits.

### Clipboard on Remote Servers

On headless servers where no X11/Wayland is available, use OSC 52 escape sequences to copy to the local terminal's clipboard:
```bash
set -g set-clipboard on       # Enable OSC 52 (most modern terminals support it)
```

This allows `tmux-yank` and copy-mode to work even over SSH without `xclip`.

## Troubleshooting

**tmux not using 256 colors or true color:**
```bash
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
# Verify: tmux info | grep Tc
```

**Escape key has delay (vim users):**
```bash
set -sg escape-time 0
```

**Mouse scroll opens copy mode but does not scroll in vim/less:**
```bash
set -g mouse on
# Modern tmux handles this automatically; ensure the terminal supports it
```

**Pane content garbled after resize:**
```bash
# Force redraw
tmux refresh-client
# Or press prefix + r if a refresh binding exists
```

**Session lost after reboot:**
Install `tmux-resurrect` and `tmux-continuum` to auto-save and auto-restore sessions.

**Cannot attach to session ("sessions should be nested"):**
```bash
unset TMUX   # Clear the TMUX env var, then attach
tmux attach -t session-name
```

## Additional Resources

- Complete keybinding reference: `references/keybindings-cheatsheet.md`
- Ready-to-use configuration recipes (minimal, power user, cyberpunk, developer workflow): `references/config-recipes.md`
- Quick tmux help: `/tmux-help` command
