#!/usr/bin/env bash
# Proactive onboarding hook — fires on every session start
# Analyzes the current project and recommends relevant skills
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DB="$PLUGIN_ROOT/skills/skill-master/references/skill-catalog.md"
USAGE_LOG="${SKILL_MASTER_USAGE_LOG:-$HOME/.claude/skill-master-usage.jsonl}"

# Detect project characteristics
detect_project() {
    local cwd="$PWD"
    local signals=""

    # Language/framework detection
    [ -f "go.mod" ] && signals="$signals go"
    [ -f "go.sum" ] && signals="$signals go"
    [ -f "package.json" ] && signals="$signals node"
    [ -f "Cargo.toml" ] && signals="$signals rust"
    [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] && signals="$signals python"
    [ -f "Gemfile" ] && signals="$signals ruby"

    # Infrastructure detection
    [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] && signals="$signals docker"
    [ -f "Taskfile.yml" ] || [ -f "Taskfile.yaml" ] && signals="$signals taskfile"
    [ -f "Makefile" ] && signals="$signals make"
    [ -d ".github/workflows" ] && signals="$signals github-actions"
    [ -f "tailscale.json" ] || [ -d "/var/lib/tailscale" ] && signals="$signals tailscale"

    # Claude Code detection
    [ -f "CLAUDE.md" ] && signals="$signals claude-md"
    [ -d ".claude" ] && signals="$signals claude-project"
    [ -f ".claude-plugin/plugin.json" ] && signals="$signals claude-plugin"
    [ -d "skills" ] && signals="$signals has-skills"

    # Frameworks
    [ -f "pkg/core/app.go" ] || grep -q "framegotui" go.mod 2>/dev/null && signals="$signals framegotui"
    [ -f "cmd/*/main.go" ] 2>/dev/null && signals="$signals go-cli"
    [ -d "proto" ] || [ -f "buf.yaml" ] && signals="$signals grpc"
    [ -d "pkg/web" ] || [ -d "web" ] && signals="$signals web-ui"
    [ -d "pkg/mcp" ] || [ -f ".mcp.json" ] && signals="$signals mcp"

    # Virtualization
    [ -f "xo-cli.conf" ] || grep -qi "xen" /etc/hostname 2>/dev/null && signals="$signals xen-orchestra"

    # Git info
    local branch=""
    branch=$(git branch --show-current 2>/dev/null || echo "")
    [ -n "$branch" ] && signals="$signals git:$branch"

    echo "$signals"
}

# Map signals to recommended skills
recommend_skills() {
    local signals="$1"
    local recs=""

    case "$signals" in
        *go*framegotui*) recs="$recs framegotui-sdk(critical)" ;;
        *go*) recs="$recs go-development" ;;
    esac

    case "$signals" in
        *claude-plugin*|*has-skills*) recs="$recs marketplace-creator plugin-dev:skill-development plugin-dev:plugin-structure" ;;
    esac

    case "$signals" in
        *tailscale*) recs="$recs tailscale-expert" ;;
    esac

    case "$signals" in
        *xen-orchestra*) recs="$recs xen-orchestra-expert" ;;
    esac

    case "$signals" in
        *docker*) recs="$recs docker-deployment" ;;
    esac

    case "$signals" in
        *web-ui*) recs="$recs frontend-design:frontend-design" ;;
    esac

    case "$signals" in
        *mcp*) recs="$recs plugin-dev:mcp-integration" ;;
    esac

    case "$signals" in
        *grpc*) recs="$recs grpc-patterns" ;;
    esac

    case "$signals" in
        *claude-md*) recs="$recs claude-md-management:claude-md-improver" ;;
    esac

    # Always recommend core skills
    recs="$recs superpowers:verification-before-completion"

    echo "$recs"
}

# Build onboarding context
build_context() {
    local signals=$(detect_project)
    local skills=$(recommend_skills "$signals")
    local project_name=$(basename "$PWD")

    # Log this session for adaptive learning
    if [ -n "$signals" ]; then
        echo "{\"ts\":\"$(date -Iseconds)\",\"project\":\"$project_name\",\"signals\":\"$signals\",\"recommended\":\"$skills\"}" >> "$USAGE_LOG" 2>/dev/null || true
    fi

    # Count skills
    local count=$(echo "$skills" | wc -w)

    if [ "$count" -eq 0 ]; then
        echo ""
        return
    fi

    local ctx="[skill-master] Project: $project_name | Detected: $signals | Recommended skills ($count): $skills"
    echo "$ctx"
}

# Output as JSON for hook system
CONTEXT=$(build_context)

if [ -n "$CONTEXT" ]; then
    # Escape for JSON
    CONTEXT_ESCAPED=$(echo "$CONTEXT" | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
    cat <<HOOKJSON
{
  "additionalContext": "$CONTEXT_ESCAPED"
}
HOOKJSON
else
    echo "{}"
fi
