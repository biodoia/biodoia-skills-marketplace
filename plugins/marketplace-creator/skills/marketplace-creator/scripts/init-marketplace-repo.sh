#!/usr/bin/env bash
# Initialize a new Claude Code plugin marketplace repository
# Usage: init-marketplace-repo.sh <repo-name> <github-user> [--private] [--description "desc"]
set -euo pipefail

REPO_NAME="${1:?Usage: init-marketplace-repo.sh <repo-name> <github-user> [--private]}"
GITHUB_USER="${2:?Usage: init-marketplace-repo.sh <repo-name> <github-user> [--private]}"
VISIBILITY="public"
DESCRIPTION="Claude Code plugin marketplace"

shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --private) VISIBILITY="private"; shift ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

WORK_DIR="${3:-$(pwd)/$REPO_NAME}"

echo "=== Initializing marketplace: $REPO_NAME ==="
echo "    GitHub user: $GITHUB_USER"
echo "    Visibility: $VISIBILITY"
echo "    Directory: $WORK_DIR"

# Create directory structure
mkdir -p "$WORK_DIR"/{.claude-plugin,plugins,external_plugins}

# Create marketplace.json
cat > "$WORK_DIR/.claude-plugin/marketplace.json" << MARKETPLACE
{
  "\$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "$REPO_NAME",
  "description": "$DESCRIPTION",
  "owner": {
    "name": "$GITHUB_USER",
    "email": "$GITHUB_USER@users.noreply.github.com"
  },
  "plugins": []
}
MARKETPLACE

# Create README
cat > "$WORK_DIR/README.md" << 'README'
# Claude Code Plugin Marketplace

A curated collection of Claude Code plugins and skills.

## Installation

```bash
# Register this marketplace in Claude Code
claude /plugin  # then select "Add marketplace" and enter this repo URL
```

## Available Plugins

See `.claude-plugin/marketplace.json` for the full plugin registry.

## Contributing

1. Fork this repository
2. Add your plugin to `plugins/` or create an external reference
3. Register it in `.claude-plugin/marketplace.json`
4. Submit a pull request
README

# Create .gitignore
cat > "$WORK_DIR/.gitignore" << 'GITIGNORE'
node_modules/
.env
*.log
.DS_Store
GITIGNORE

# Create LICENSE (MIT)
cat > "$WORK_DIR/LICENSE" << LICENSE
MIT License

Copyright (c) $(date +%Y) $GITHUB_USER

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LICENSE

# Init git
cd "$WORK_DIR"
git init -b main
git add -A
git commit -m "feat: initialize marketplace repository

Scaffolded by marketplace-creator skill.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

# Create GitHub repo and push
echo "=== Creating GitHub repo: $GITHUB_USER/$REPO_NAME ==="
gh repo create "$GITHUB_USER/$REPO_NAME" \
    --"$VISIBILITY" \
    --description "$DESCRIPTION" \
    --source . \
    --remote origin \
    --push

echo ""
echo "=== Marketplace created successfully! ==="
echo "    Repo: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "    Local: $WORK_DIR"
echo ""
echo "Next steps:"
echo "  1. Add plugins with scaffold-plugin.sh"
echo "  2. Register them in .claude-plugin/marketplace.json"
echo "  3. Users can install via: claude /plugin"
