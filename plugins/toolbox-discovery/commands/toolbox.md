---
description: Run a full system toolbox discovery — scan all installed tools, assess health, identify gaps, and provide recommendations
allowed-tools: ["Bash", "Read"]
---

# Toolbox Discovery

Perform a comprehensive scan of the system to discover all installed tools, assess their health and configuration, and provide actionable recommendations.

## Steps

1. Read the full skill reference for methodology and output format:
   ```
   Read: skills/toolbox-discovery/SKILL.md
   ```

2. Run the automated discovery script to get a quick inventory:
   ```bash
   bash skills/toolbox-discovery/scripts/discover-tools.sh
   ```

3. For each category of tools found, perform a deeper assessment:

   **Check configurations exist:**
   ```bash
   # Git config
   git config --global --list 2>/dev/null | head -20

   # Check for key config files
   ls -la ~/.gitconfig ~/.tmux.conf ~/.config/starship.toml ~/.ripgreprc 2>/dev/null

   # Check shell config
   head -5 ~/.zshrc ~/.bashrc 2>/dev/null

   # Check for tool integrations (delta as git pager, bat as MANPAGER, etc.)
   git config --global core.pager 2>/dev/null
   echo $MANPAGER
   echo $EDITOR
   ```

   **Check service status for daemons:**
   ```bash
   # Check key services
   systemctl is-active docker ollama tailscaled 2>/dev/null || true
   systemctl --user is-active --no-pager 2>/dev/null | head -20 || true
   ```

   **Check for version managers:**
   ```bash
   # Active version managers
   command -v asdf mise proto nvm fnm pyenv rbenv goenv rustup 2>/dev/null
   ```

4. Analyze the results and produce a structured report following the output format in SKILL.md. Include:
   - Full inventory organized by category with status indicators
   - Health issues (misconfigured tools, broken binaries, stopped services)
   - Quick wins (easy activations that unlock productivity)
   - Missing tool recommendations based on the detected stack

5. If the user wants activation recommendations, read the recipes:
   ```
   Read: skills/toolbox-discovery/references/activation-recipes.md
   ```

6. If the user wants detailed install commands, read the catalog:
   ```
   Read: skills/toolbox-discovery/references/tool-catalog.md
   ```

## Output Format

Present results as the structured report defined in SKILL.md. Use checkmarks, crosses, and warning symbols. Group by category. Always end with Quick Wins and Missing Recommendations sections.

## Tips

- Run the discovery script first for speed, then do manual deep-dives on interesting findings
- Pay special attention to tools that are installed but not configured (partial status)
- Highlight integration opportunities (tools that work better together)
- Tailor install commands to the detected package manager (pacman for Arch/Manjaro, apt for Debian, brew for macOS)
