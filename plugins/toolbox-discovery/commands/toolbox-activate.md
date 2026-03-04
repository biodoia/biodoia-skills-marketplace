---
description: Apply activation recipes to configure and integrate tools — set up shell integrations, git improvements, modern aliases, and more
allowed-tools: ["Bash", "Read"]
---

# Toolbox Activate

Apply activation recipes to configure, integrate, and optimize tools on the system.

## Steps

1. Read the activation recipes reference:
   ```
   Read: skills/toolbox-discovery/references/activation-recipes.md
   ```

2. Determine what the user wants to activate. Common targets:
   - **Specific tool**: `fzf`, `bat`, `eza`, `delta`, `zoxide`, `direnv`, `atuin`, `starship`, `ripgrep`, `tmux`, `ollama`
   - **Category**: `shell` (all shell integrations), `git` (git improvements), `modern` (modern tool aliases), `completions`
   - **Everything**: `all`

3. First, do a dry run to show what would change:
   ```bash
   bash skills/toolbox-discovery/scripts/activate-tools.sh <target> --dry-run
   ```

4. Ask the user to confirm before applying changes.

5. Apply the activation:
   ```bash
   bash skills/toolbox-discovery/scripts/activate-tools.sh <target>
   ```

6. Verify the changes were applied:
   ```bash
   # Check what was added to shell rc
   tail -30 ~/.zshrc  # or ~/.bashrc

   # Check git config if git target
   git config --global --list | grep -E 'delta|alias|pager|merge|diff'

   # Check if new config files were created
   ls -la ~/.config/starship.toml ~/.ripgreprc ~/.tmux.conf 2>/dev/null
   ```

7. Remind the user to reload their shell:
   ```bash
   source ~/.zshrc  # or source ~/.bashrc
   ```

## Available Targets

### Individual Tools
| Target | What it does |
|--------|-------------|
| `fzf` | Configures fzf keybindings, preview with bat, fd integration |
| `bat` | Sets bat as MANPAGER, creates cat alias |
| `eza` | Creates ls/ll/la/lt aliases using eza |
| `delta` | Configures delta as git diff pager with line numbers |
| `zoxide` | Enables zoxide smart cd in shell |
| `direnv` | Enables per-directory environment loading |
| `atuin` | Enables atuin shell history search |
| `starship` | Enables starship prompt, creates starter config |
| `ripgrep` | Creates ~/.ripgreprc with smart defaults |
| `tmux` | Creates ~/.tmux.conf with sensible defaults |
| `ollama` | Enables and starts ollama systemd service |

### Categories
| Target | What it does |
|--------|-------------|
| `shell` | fzf + zoxide + direnv + atuin + starship + completions |
| `git` | delta + git aliases |
| `modern` | bat + eza + ripgrep + modern aliases (dust, duf, btop) |
| `completions` | Shell completions for kubectl, helm, gh, rustup |
| `all` | Everything above + tmux + ollama |

## Safety

- All existing configs are backed up before modification (to `~/.config/toolbox-discovery/backups/`)
- Each activation block has a unique marker to prevent duplicate additions
- Use `--dry-run` to preview changes without applying them
- Use `--no-backup` only if you are sure you do not need backups
