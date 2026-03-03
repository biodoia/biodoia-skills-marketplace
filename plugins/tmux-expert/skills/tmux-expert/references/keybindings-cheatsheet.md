# tmux Keybindings Cheatsheet

Complete keybinding reference for tmux. All bindings use the default prefix `C-b` (Ctrl+b) unless noted otherwise. Press the prefix, release it, then press the action key.

---

## Session Management

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix d` | `detach-client` | Detach from current session |
| `prefix s` | `choose-tree -s` | Interactive session/window chooser |
| `prefix $` | `rename-session` | Rename current session |
| `prefix (` | `switch-client -p` | Switch to previous session |
| `prefix )` | `switch-client -n` | Switch to next session |
| `prefix L` | `switch-client -l` | Switch to last (most recent) session |
| `prefix :new` | `new-session` | Create a new session (from command prompt) |

---

## Window Management

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix c` | `new-window` | Create a new window |
| `prefix n` | `next-window` | Go to next window |
| `prefix p` | `previous-window` | Go to previous window |
| `prefix l` | `last-window` | Go to last active window |
| `prefix 0-9` | `select-window -t :N` | Jump to window by number |
| `prefix w` | `choose-tree -w` | Interactive window chooser |
| `prefix ,` | `rename-window` | Rename current window |
| `prefix &` | `kill-window` | Kill current window (confirm) |
| `prefix .` | `move-window` | Move window to a different index |
| `prefix f` | `find-window` | Find window by name/content |
| `prefix '` | `select-window` | Prompt for window index to jump to |

---

## Pane Management

### Splitting

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix %` | `split-window -h` | Split vertically (left/right) |
| `prefix "` | `split-window -v` | Split horizontally (top/bottom) |

### Navigation

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix Up` | `select-pane -U` | Move to pane above |
| `prefix Down` | `select-pane -D` | Move to pane below |
| `prefix Left` | `select-pane -L` | Move to pane left |
| `prefix Right` | `select-pane -R` | Move to pane right |
| `prefix o` | `select-pane -t :.+` | Cycle to next pane |
| `prefix ;` | `last-pane` | Toggle to last active pane |
| `prefix q` | `display-panes` | Show pane numbers (type number to jump) |

### Resizing

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix C-Up` | `resize-pane -U 1` | Resize pane up (1 cell) |
| `prefix C-Down` | `resize-pane -D 1` | Resize pane down (1 cell) |
| `prefix C-Left` | `resize-pane -L 1` | Resize pane left (1 cell) |
| `prefix C-Right` | `resize-pane -R 1` | Resize pane right (1 cell) |
| `prefix M-Up` | `resize-pane -U 5` | Resize pane up (5 cells) |
| `prefix M-Down` | `resize-pane -D 5` | Resize pane down (5 cells) |
| `prefix M-Left` | `resize-pane -L 5` | Resize pane left (5 cells) |
| `prefix M-Right` | `resize-pane -R 5` | Resize pane right (5 cells) |

### Layout and Organization

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix Space` | `next-layout` | Cycle through preset layouts |
| `prefix M-1` | `select-layout even-horizontal` | Even horizontal layout |
| `prefix M-2` | `select-layout even-vertical` | Even vertical layout |
| `prefix M-3` | `select-layout main-horizontal` | Main pane top, others bottom |
| `prefix M-4` | `select-layout main-vertical` | Main pane left, others right |
| `prefix M-5` | `select-layout tiled` | Tiled layout (equal size) |
| `prefix z` | `resize-pane -Z` | Zoom/unzoom pane (fullscreen toggle) |
| `prefix {` | `swap-pane -U` | Swap pane with previous |
| `prefix }` | `swap-pane -D` | Swap pane with next |
| `prefix !` | `break-pane` | Break pane into its own window |
| `prefix x` | `kill-pane` | Kill current pane (confirm) |

---

## Copy Mode (vi keys)

Enter copy mode with `prefix [`. These keys apply when `mode-keys` is set to `vi`.

### Navigation

| Key | Description |
|-----|-------------|
| `h j k l` | Move cursor left/down/up/right |
| `w` | Move forward one word |
| `b` | Move backward one word |
| `e` | Move to end of word |
| `0` | Move to start of line |
| `$` | Move to end of line |
| `^` | Move to first non-blank character |
| `g` | Move to top of scrollback |
| `G` | Move to bottom of scrollback |
| `H` | Move to top of visible area |
| `M` | Move to middle of visible area |
| `L` | Move to bottom of visible area |
| `C-u` | Scroll up half page |
| `C-d` | Scroll down half page |
| `C-b` | Scroll up full page |
| `C-f` | Scroll down full page |

### Search

| Key | Description |
|-----|-------------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next search match |
| `N` | Previous search match |

### Selection and Copy

| Key | Description |
|-----|-------------|
| `Space` or `v` | Begin selection |
| `V` | Select entire line |
| `C-v` | Toggle rectangle (block) selection |
| `Enter` or `y` | Copy selection and exit copy mode |
| `Escape` | Clear selection |
| `q` | Exit copy mode |

### Paste

| Key (from normal mode) | Description |
|------------------------|-------------|
| `prefix ]` | Paste most recent buffer |
| `prefix =` | Choose buffer to paste from list |

---

## Copy Mode (emacs keys)

Enter copy mode with `prefix [`. These keys apply when `mode-keys` is set to `emacs` (the default).

### Navigation

| Key | Description |
|-----|-------------|
| `C-p` / `Up` | Move up |
| `C-n` / `Down` | Move down |
| `C-b` / `Left` | Move left |
| `C-f` / `Right` | Move right |
| `M-f` | Move forward one word |
| `M-b` | Move backward one word |
| `C-a` | Move to start of line |
| `C-e` | Move to end of line |
| `M-<` | Move to top of scrollback |
| `M->` | Move to bottom of scrollback |
| `C-v` | Scroll down full page |
| `M-v` | Scroll up full page |

### Search

| Key | Description |
|-----|-------------|
| `C-s` | Search forward (incremental) |
| `C-r` | Search backward (incremental) |

### Selection and Copy

| Key | Description |
|-----|-------------|
| `C-Space` | Begin selection |
| `M-w` | Copy selection and exit copy mode |
| `C-w` | Copy selection, exit, and kill (cut) |
| `C-g` | Clear selection |
| `q` | Exit copy mode |

---

## Command Prompt and Miscellaneous

| Keybinding | Command | Description |
|------------|---------|-------------|
| `prefix :` | `command-prompt` | Open the tmux command prompt |
| `prefix ?` | `list-keys` | List all keybindings |
| `prefix t` | `clock-mode` | Show a clock in the current pane |
| `prefix ~` | `show-messages` | Show tmux message log |
| `prefix i` | `display-message` | Show window/pane info |
| `prefix r` | (custom) | Commonly bound to `source-file ~/.tmux.conf` |
| `prefix C-z` | `suspend-client` | Suspend tmux client (like Ctrl+Z) |

---

## Mouse Actions (when `set -g mouse on`)

| Action | Description |
|--------|-------------|
| Click pane | Select pane |
| Click window in status bar | Select window |
| Drag pane border | Resize pane |
| Scroll wheel | Enter copy mode and scroll (or scroll in programs that support it) |
| Right-click | Context menu (tmux 3.0+) |
| Middle-click | Paste from tmux buffer |

---

## tmux-pain-control Plugin Additions

When using `tmux-plugins/tmux-pain-control`, these bindings are added:

| Keybinding | Description |
|------------|-------------|
| `prefix h` | Select pane left |
| `prefix j` | Select pane down |
| `prefix k` | Select pane up |
| `prefix l` | Select pane right |
| `prefix H` | Resize pane left (5 cells) |
| `prefix J` | Resize pane down (5 cells) |
| `prefix K` | Resize pane up (5 cells) |
| `prefix L` | Resize pane right (5 cells) |
| `prefix |` | Split vertically |
| `prefix -` | Split horizontally |
| `prefix \` | Split full-width vertically |
| `prefix _` | Split full-width horizontally |

---

## Target Syntax for Commands

When specifying targets in tmux commands, use this syntax:

| Target | Meaning |
|--------|---------|
| `session:` | A session by name |
| `session:window` | A window by name or index |
| `session:window.pane` | A specific pane |
| `:` | Current session |
| `:.` | Current pane |
| `:{last}` | Last window |
| `:.{left}` | Pane to the left |
| `:.{right}` | Pane to the right |
| `:.{up}` | Pane above |
| `:.{down}` | Pane below |
| `:{next}` | Next window |
| `:{previous}` | Previous window |
| `+` / `-` | Next / previous (relative) |

Examples:
```bash
tmux send-keys -t mysession:0.1 "ls" Enter    # Session "mysession", window 0, pane 1
tmux select-pane -t :.+                         # Next pane in current window
tmux kill-window -t :2                           # Window 2 in current session
```
