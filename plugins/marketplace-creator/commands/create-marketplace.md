---
description: Create a new Claude Code plugin marketplace repository on GitHub
argument-hint: <repo-name> [github-user]
allowed-tools: ["Read", "Write", "Bash", "Skill", "AskUserQuestion"]
---

# Create Marketplace

Initialize a new plugin marketplace repository and push to GitHub.

**Arguments:** $ARGUMENTS

## Workflow

1. Parse arguments for repo name and GitHub user
2. Verify `gh auth status`
3. Run `init-marketplace-repo.sh` from the marketplace-creator skill
4. Verify the repo was created and pushed
5. Report the marketplace URL

If no arguments provided, ask the user for the repo name and GitHub user.
