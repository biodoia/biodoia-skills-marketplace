#!/usr/bin/env bash
# Track skill invocations for adaptive learning
# Triggered by PostToolUse on Skill tool
set -euo pipefail

USAGE_LOG="${SKILL_MASTER_USAGE_LOG:-$HOME/.claude/skill-master-usage.jsonl}"
PROJECT=$(basename "$PWD")

# Read the tool input from stdin (PostToolUse passes tool_input)
SKILL_NAME="${TOOL_INPUT_skill:-unknown}"

echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"skill_used\",\"skill\":\"$SKILL_NAME\",\"project\":\"$PROJECT\"}" >> "$USAGE_LOG" 2>/dev/null || true

echo "{}"
