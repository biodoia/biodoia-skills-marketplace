---
description: Quick tmux reference — show essential commands, keybindings, or help with a specific tmux topic
allowed-tools: ["Bash"]
---

# tmux Help

Provide quick tmux help based on what the user asks. If no specific topic is given, show a general quick-reference.

## Steps

1. Determine what the user needs help with (sessions, windows, panes, config, plugins, or general).
2. If they ask about their current tmux state, gather information from the system.
3. Provide a focused, actionable response.

## Gathering System State

If the user wants to know about their running tmux environment:

```bash
tmux list-sessions 2>/dev/null || echo "No tmux server running"
```

```bash
tmux list-windows -a 2>/dev/null
```

```bash
tmux display-message -p "tmux #{version}" 2>/dev/null || tmux -V 2>/dev/null || echo "tmux not found"
```

```bash
test -f ~/.tmux.conf && echo "Config: ~/.tmux.conf exists" || echo "No ~/.tmux.conf found"
```

```bash
ls ~/.tmux/plugins/ 2>/dev/null && echo "TPM plugins installed" || echo "No TPM plugins directory"
```

## Quick Reference

When the user asks for general help, present this summary:

### Sessions
```
tmux new -s name          Create named session
tmux ls                   List sessions
tmux attach -t name       Attach to session
tmux kill-session -t name Kill session
prefix d                  Detach
prefix s                  Session chooser
prefix $                  Rename session
```

### Windows
```
prefix c                  New window
prefix n / p              Next / Previous window
prefix 0-9                Jump to window
prefix w                  Window chooser
prefix ,                  Rename window
prefix &                  Kill window
```

### Panes
```
prefix %                  Split vertical (left/right)
prefix "                  Split horizontal (top/bottom)
prefix arrow              Navigate panes
prefix z                  Zoom/unzoom pane
prefix x                  Kill pane
prefix !                  Break pane to window
prefix Space              Cycle layouts
```

### Copy Mode
```
prefix [                  Enter copy mode
prefix ]                  Paste
/ or ?                    Search (vi mode)
v then y                  Select and copy (vi mode)
```

### Useful Commands
```
tmux source-file ~/.tmux.conf       Reload config
tmux list-keys                       Show all bindings
tmux display-message -p "#{...}"     Show format variable
tmux capture-pane -p                 Print pane to stdout
```

## Topic-Specific Help

When the user asks about a specific topic, provide detailed guidance from the tmux-expert skill knowledge base. Cover:

- **Configuration**: Show relevant `.tmux.conf` options with explanations
- **Plugins**: Explain TPM installation and plugin usage
- **Scripting**: Show tmux command patterns for automation
- **Troubleshooting**: Diagnose and fix common issues (colors, escape delay, clipboard, etc.)
- **Keybindings**: Reference the keybindings cheatsheet for the relevant category

Always include runnable commands the user can copy-paste.
