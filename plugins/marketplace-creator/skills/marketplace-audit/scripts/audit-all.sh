#!/usr/bin/env bash
# Marketplace Audit — Comprehensive validation of biodoia-skills-marketplace
# Usage: bash audit-all.sh [--verbose] [--json]
# Exit code: 0 = all pass, 1 = warnings/failures found

set -euo pipefail

# --- Config ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
PLUGINS_DIR="$REPO_ROOT/plugins"
VERBOSE=false
JSON_OUTPUT=false

for arg in "$@"; do
  case "$arg" in
    --verbose) VERBOSE=true ;;
    --json) JSON_OUTPUT=true ;;
  esac
done

# --- Counters ---
PASS=0
WARN=0
FAIL=0
DETAILS=()

pass() { PASS=$((PASS + 1)); if $VERBOSE; then echo "  [PASS] $1"; fi; }
warn() { WARN=$((WARN + 1)); DETAILS+=("WARN: $1"); if $VERBOSE; then echo "  [WARN] $1"; fi; }
fail() { FAIL=$((FAIL + 1)); DETAILS+=("FAIL: $1"); echo "  [FAIL] $1"; }

section() { echo; echo "=== $1 ==="; }

# ============================================================
# 1. REGISTRY INTEGRITY
# ============================================================
section "1. Registry Integrity"

if [ ! -f "$MARKETPLACE_JSON" ]; then
  fail "marketplace.json not found at $MARKETPLACE_JSON"
else
  # Valid JSON
  if jq empty "$MARKETPLACE_JSON" 2>/dev/null; then
    pass "marketplace.json is valid JSON"
  else
    fail "marketplace.json is invalid JSON"
  fi

  # Required fields
  for field in name description owner plugins; do
    if jq -e ".$field" "$MARKETPLACE_JSON" >/dev/null 2>&1; then
      pass "marketplace.json has '$field' field"
    else
      fail "marketplace.json missing '$field' field"
    fi
  done

  # Plugin entries
  REGISTERED_PLUGINS=$(jq -r '.plugins[].name' "$MARKETPLACE_JSON" 2>/dev/null)
  REG_COUNT=$(echo "$REGISTERED_PLUGINS" | wc -l)
  pass "$REG_COUNT plugins registered"

  # Duplicate check
  DUPES=$(echo "$REGISTERED_PLUGINS" | sort | uniq -d)
  if [ -z "$DUPES" ]; then
    pass "No duplicate plugin names"
  else
    fail "Duplicate plugin names: $DUPES"
  fi

  # Required fields per plugin entry
  for name in $REGISTERED_PLUGINS; do
    for field in name description category source; do
      if ! jq -e ".plugins[] | select(.name==\"$name\") | .$field" "$MARKETPLACE_JSON" >/dev/null 2>&1; then
        warn "Plugin '$name' missing '$field' in marketplace.json"
      fi
    done
  done

  # Source paths exist
  jq -r '.plugins[] | select(.source | type == "string") | .source' "$MARKETPLACE_JSON" 2>/dev/null | while read -r src; do
    resolved="$REPO_ROOT/${src#./}"
    if [ -d "$resolved" ]; then
      pass "Source path exists: $src"
    else
      fail "Source path missing: $src -> $resolved"
    fi
  done

  # Orphan check (dirs not in registry)
  if [ -d "$PLUGINS_DIR" ]; then
    for dir in "$PLUGINS_DIR"/*/; do
      dirname=$(basename "$dir")
      if ! echo "$REGISTERED_PLUGINS" | grep -qx "$dirname"; then
        warn "Orphan plugin directory: $dirname (not in marketplace.json)"
      fi
    done
  fi
fi

# ============================================================
# 2. PLUGIN STRUCTURE
# ============================================================
section "2. Plugin Structure"

PLUGIN_COUNT=0
VALID_PLUGINS=0

if [ -d "$PLUGINS_DIR" ]; then
  for dir in "$PLUGINS_DIR"/*/; do
    PLUGIN_COUNT=$((PLUGIN_COUNT + 1))
    name=$(basename "$dir")
    pjson="$dir.claude-plugin/plugin.json"

    if [ ! -f "$pjson" ]; then
      fail "$name: missing .claude-plugin/plugin.json"
      continue
    fi

    if ! jq empty "$pjson" 2>/dev/null; then
      fail "$name: plugin.json is invalid JSON"
      continue
    fi

    # Name field
    pname=$(jq -r '.name // empty' "$pjson" 2>/dev/null)
    if [ -z "$pname" ]; then
      fail "$name: plugin.json missing 'name'"
    elif ! echo "$pname" | grep -qP '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
      warn "$name: plugin name '$pname' doesn't match kebab-case pattern"
    else
      pass "$name: valid plugin.json"
    fi

    # At least one SKILL.md
    skill_count=$(find "$dir" -name "SKILL.md" 2>/dev/null | wc -l)
    if [ "$skill_count" -eq 0 ]; then
      fail "$name: no SKILL.md found"
    else
      pass "$name: $skill_count SKILL.md file(s)"
    fi

    VALID_PLUGINS=$((VALID_PLUGINS + 1))
  done
fi

echo "  Plugins: $VALID_PLUGINS/$PLUGIN_COUNT valid"

# ============================================================
# 3. SKILL.MD QUALITY
# ============================================================
section "3. SKILL.md Quality"

SKILL_FILES=$(find "$PLUGINS_DIR" -name "SKILL.md" 2>/dev/null | sort)
SKILL_COUNT=$(echo "$SKILL_FILES" | grep -c . || echo 0)
STYLE_CLEAN=0
STYLE_DIRTY=0
WC_OK=0
WC_BAD=0

for skill in $SKILL_FILES; do
  rel=$(echo "$skill" | sed "s|$REPO_ROOT/||")

  # Frontmatter check (has --- delimiters)
  if head -1 "$skill" | grep -q '^---'; then
    # Extract frontmatter
    fm=$(sed -n '2,/^---$/p' "$skill" | head -n -1)

    # name field
    if echo "$fm" | grep -q '^name:'; then
      pass "$rel: frontmatter has 'name'"
    else
      fail "$rel: frontmatter missing 'name'"
    fi

    # description field
    if echo "$fm" | grep -q '^description:'; then
      pass "$rel: frontmatter has 'description'"

      # Third person check
      desc=$(echo "$fm" | grep '^description:' | sed 's/^description:\s*//')
      if echo "$desc" | grep -qi 'This skill should be used when'; then
        pass "$rel: description uses third person"
      else
        warn "$rel: description should start with 'This skill should be used when'"
      fi

      # Trigger phrases
      if echo "$desc" | grep -q '"'; then
        pass "$rel: description has trigger phrases"
      else
        warn "$rel: description lacks quoted trigger phrases"
      fi
    else
      fail "$rel: frontmatter missing 'description'"
    fi
  else
    fail "$rel: missing YAML frontmatter"
  fi

  # Extract full body after second --- delimiter (for word count)
  full_body=$(awk 'BEGIN{f=0} /^---$/{f++; next} f>=2' "$skill")

  # Style check (you/your) — exclude fenced code blocks and inline code
  prose_body=$(awk 'BEGIN{f=0; code=0} /^---$/{f++; next} f<2{next} /^```/{code=!code; next} code{next} {gsub(/`[^`]+`/, ""); print}' "$skill")
  violations=$(echo "$prose_body" | grep -ciP '\byou\b|\byour\b|\byou.re\b|\byourself\b' || true)
  violations=${violations:-0}
  if [ "$violations" -eq 0 ]; then
    STYLE_CLEAN=$((STYLE_CLEAN + 1))
    pass "$rel: zero you/your violations"
  else
    STYLE_DIRTY=$((STYLE_DIRTY + 1))
    warn "$rel: $violations you/your violation(s)"
  fi

  # Word count (full body including code blocks)
  words=$(echo "$full_body" | wc -w)
  if [ "$words" -ge 1000 ] && [ "$words" -le 3000 ]; then
    WC_OK=$((WC_OK + 1))
    pass "$rel: $words words (in range)"
  else
    WC_BAD=$((WC_BAD + 1))
    warn "$rel: $words words (target 1000-3000)"
  fi

  # Additional Resources section
  if grep -q '## Additional Resources' "$skill"; then
    pass "$rel: has Additional Resources section"
  else
    warn "$rel: missing '## Additional Resources' section"
  fi
done

echo "  Style: $STYLE_CLEAN/$SKILL_COUNT clean"
echo "  Word count: $WC_OK/$SKILL_COUNT in range"

# ============================================================
# 4. REFERENCE INTEGRITY
# ============================================================
section "4. Reference Integrity"

REF_OK=0
REF_BAD=0

for skill in $SKILL_FILES; do
  skill_dir=$(dirname "$skill")
  ref_dir="$skill_dir/references"

  if [ -d "$ref_dir" ]; then
    # Check each reference file is cited in SKILL.md
    for ref in "$ref_dir"/*.md; do
      [ -f "$ref" ] || continue
      ref_name=$(basename "$ref")
      if grep -q "$ref_name" "$skill"; then
        REF_OK=$((REF_OK + 1))
        pass "$(basename "$(dirname "$skill_dir")"): $ref_name cited in SKILL.md"
      else
        REF_BAD=$((REF_BAD + 1))
        warn "$(basename "$(dirname "$skill_dir")"): $ref_name NOT cited in SKILL.md"
      fi
    done
  fi

  # Check cited references exist on disk (handles ../sibling/references/ paths too)
  grep -oP '(?:\.\./[a-zA-Z0-9_-]+/)?references/[a-zA-Z0-9_-]+\.md' "$skill" 2>/dev/null | sort -u | while read -r ref_path; do
    full_path=$(realpath "$skill_dir/$ref_path" 2>/dev/null || echo "")
    if [ -n "$full_path" ] && [ -f "$full_path" ]; then
      pass "$(basename "$(dirname "$skill_dir")"): $ref_path exists"
    else
      fail "$(basename "$(dirname "$skill_dir")"): $ref_path MISSING on disk"
    fi
  done
done

echo "  References: $REF_OK cited, $REF_BAD uncited"

# ============================================================
# 5. SCRIPT VALIDATION
# ============================================================
section "5. Script Validation"

SCRIPT_FILES=$(find "$PLUGINS_DIR" -name "*.sh" -o -name "*.py" 2>/dev/null | sort)
SCRIPT_OK=0
SCRIPT_BAD=0

for script in $SCRIPT_FILES; do
  rel=$(echo "$script" | sed "s|$REPO_ROOT/||")

  # Executable check
  if [ ! -x "$script" ]; then
    warn "$rel: not executable"
  fi

  # Shebang check
  first_line=$(head -1 "$script")
  if echo "$script" | grep -q '\.sh$'; then
    if echo "$first_line" | grep -q '^#!.*bash\|^#!.*sh'; then
      SCRIPT_OK=$((SCRIPT_OK + 1))
      pass "$rel: valid bash shebang"
    else
      SCRIPT_BAD=$((SCRIPT_BAD + 1))
      warn "$rel: missing/invalid shebang"
    fi
  elif echo "$script" | grep -q '\.py$'; then
    if python3 -c "import ast; ast.parse(open('$script').read())" 2>/dev/null; then
      SCRIPT_OK=$((SCRIPT_OK + 1))
      pass "$rel: valid Python syntax"
    else
      SCRIPT_BAD=$((SCRIPT_BAD + 1))
      warn "$rel: Python syntax error"
    fi
  fi
done

echo "  Scripts: $SCRIPT_OK valid, $SCRIPT_BAD issues"

# ============================================================
# 6. AGENT VALIDATION
# ============================================================
section "6. Agent Validation"

AGENT_FILES=$(find "$PLUGINS_DIR" -path "*/agents/*.md" 2>/dev/null | sort)
AGENT_COUNT=$(echo "$AGENT_FILES" | grep -c . 2>/dev/null || echo 0)

for agent in $AGENT_FILES; do
  [ -f "$agent" ] || continue
  rel=$(echo "$agent" | sed "s|$REPO_ROOT/||")

  if head -1 "$agent" | grep -q '^---'; then
    fm=$(sed -n '2,/^---$/p' "$agent" | head -n -1)
    if echo "$fm" | grep -q 'name:\|description:'; then
      pass "$rel: valid agent frontmatter"
    else
      warn "$rel: agent missing name/description in frontmatter"
    fi
  else
    warn "$rel: agent missing YAML frontmatter"
  fi
done

echo "  Agents: $AGENT_COUNT found"

# ============================================================
# 7. HOOKS VALIDATION
# ============================================================
section "7. Hooks Validation"

HOOKS_FILES=$(find "$PLUGINS_DIR" -name "hooks.json" 2>/dev/null | sort)

for hooks in $HOOKS_FILES; do
  [ -f "$hooks" ] || continue
  rel=$(echo "$hooks" | sed "s|$REPO_ROOT/||")

  if jq empty "$hooks" 2>/dev/null; then
    pass "$rel: valid JSON"
  else
    fail "$rel: invalid JSON"
    continue
  fi

  if jq -e '.hooks' "$hooks" >/dev/null 2>&1; then
    pass "$rel: has outer 'hooks' wrapper"
  else
    fail "$rel: missing outer 'hooks' wrapper"
  fi

  # Validate event names
  VALID_EVENTS="PreToolUse PostToolUse UserPromptSubmit Stop SubagentStop SessionStart SessionEnd PreCompact Notification"
  jq -r '.hooks | keys[]' "$hooks" 2>/dev/null | while read -r event; do
    if echo "$VALID_EVENTS" | grep -qw "$event"; then
      pass "$rel: valid event '$event'"
    else
      warn "$rel: unknown event '$event'"
    fi
  done
done

# ============================================================
# SUMMARY
# ============================================================
echo
echo "==============================="
echo "  MARKETPLACE AUDIT REPORT"
echo "==============================="
echo "  Pass: $PASS"
echo "  Warn: $WARN"
echo "  Fail: $FAIL"
echo "==============================="

if [ ${#DETAILS[@]} -gt 0 ]; then
  echo
  echo "Issues found:"
  for d in "${DETAILS[@]}"; do
    echo "  - $d"
  done
fi

echo
if [ "$FAIL" -gt 0 ]; then
  echo "Result: FAIL ($FAIL critical issues)"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "Result: WARN ($WARN items need attention)"
  exit 1
else
  echo "Result: ALL PASS"
  exit 0
fi
