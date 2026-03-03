#!/usr/bin/env bash
# Audit and validate a Claude Code plugin marketplace
# Usage: audit-marketplace.sh [marketplace-path]
# Default: current directory
set -euo pipefail

MARKETPLACE_DIR="${1:-.}"
ERRORS=0
WARNINGS=0
PLUGINS_CHECKED=0
SKILLS_CHECKED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

error() { echo -e "${RED}[ERROR]${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; ((WARNINGS++)); }
pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
info() { echo -e "${CYAN}[INFO]${NC} $1"; }

echo ""
echo "============================================="
echo "  MARKETPLACE AUDIT"
echo "  Path: $MARKETPLACE_DIR"
echo "============================================="
echo ""

# 1. Check marketplace.json exists
REGISTRY="$MARKETPLACE_DIR/.claude-plugin/marketplace.json"
if [ ! -f "$REGISTRY" ]; then
    error "marketplace.json not found at $REGISTRY"
    echo ""
    echo "Score: F (no registry found)"
    exit 1
fi
pass "marketplace.json found"

# 2. Validate JSON
if ! python3 -c "import json; json.load(open('$REGISTRY'))" 2>/dev/null; then
    error "marketplace.json is not valid JSON"
    exit 1
fi
pass "Valid JSON"

# 3. Check required fields
MISSING_FIELDS=$(python3 -c "
import json
data = json.load(open('$REGISTRY'))
required = ['name', 'description', 'owner', 'plugins']
missing = [f for f in required if f not in data]
if missing:
    print(', '.join(missing))
" 2>/dev/null || echo "parse_error")

if [ -n "$MISSING_FIELDS" ] && [ "$MISSING_FIELDS" != "" ]; then
    error "Missing required fields: $MISSING_FIELDS"
else
    pass "All required registry fields present"
fi

# 4. Check $schema
HAS_SCHEMA=$(python3 -c "
import json
data = json.load(open('$REGISTRY'))
print('yes' if '\$schema' in data else 'no')
" 2>/dev/null || echo "no")
if [ "$HAS_SCHEMA" = "no" ]; then
    warn "Missing \$schema field (recommended)"
else
    pass "\$schema field present"
fi

echo ""
echo "--- Checking plugins ---"
echo ""

# 5. Check each registered plugin
PLUGIN_COUNT=$(python3 -c "
import json
data = json.load(open('$REGISTRY'))
print(len(data.get('plugins', [])))
" 2>/dev/null || echo "0")

if [ "$PLUGIN_COUNT" = "0" ]; then
    warn "No plugins registered in marketplace"
fi

python3 -c "
import json
data = json.load(open('$REGISTRY'))
for p in data.get('plugins', []):
    print(p.get('name', 'UNNAMED') + '|' + str(p.get('source', '')))" 2>/dev/null | while IFS='|' read -r PNAME PSOURCE; do
    ((PLUGINS_CHECKED++)) || true
    info "Checking plugin: $PNAME"

    # Check if source is a local path
    if [[ "$PSOURCE" == ./* ]]; then
        PLUGIN_PATH="$MARKETPLACE_DIR/$PSOURCE"
        if [ ! -d "$PLUGIN_PATH" ]; then
            error "  Plugin path does not exist: $PLUGIN_PATH"
            continue
        fi
        pass "  Plugin directory exists"

        # Check plugin.json
        PJSON="$PLUGIN_PATH/.claude-plugin/plugin.json"
        if [ ! -f "$PJSON" ]; then
            error "  Missing plugin.json at $PJSON"
        else
            pass "  plugin.json found"

            # Validate name is kebab-case
            PJNAME=$(python3 -c "import json; print(json.load(open('$PJSON')).get('name',''))" 2>/dev/null)
            if echo "$PJNAME" | grep -qE '^[a-z][a-z0-9]*(-[a-z0-9]+)*$'; then
                pass "  Name is valid kebab-case: $PJNAME"
            else
                error "  Name is not kebab-case: $PJNAME"
            fi
        fi

        # Check skills
        if [ -d "$PLUGIN_PATH/skills" ]; then
            for SKILL_DIR in "$PLUGIN_PATH/skills"/*/; do
                [ -d "$SKILL_DIR" ] || continue
                ((SKILLS_CHECKED++)) || true
                SKILL_NAME=$(basename "$SKILL_DIR")

                if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
                    error "  Skill '$SKILL_NAME' missing SKILL.md"
                    continue
                fi
                pass "  Skill '$SKILL_NAME' has SKILL.md"

                # Check frontmatter
                HAS_FM=$(head -1 "$SKILL_DIR/SKILL.md")
                if [ "$HAS_FM" != "---" ]; then
                    error "  Skill '$SKILL_NAME' missing YAML frontmatter"
                    continue
                fi

                # Check name and description in frontmatter
                HAS_NAME=$(grep -c '^name:' "$SKILL_DIR/SKILL.md" || true)
                HAS_DESC=$(grep -c '^description:' "$SKILL_DIR/SKILL.md" || true)
                if [ "$HAS_NAME" -eq 0 ]; then
                    error "  Skill '$SKILL_NAME' frontmatter missing 'name'"
                fi
                if [ "$HAS_DESC" -eq 0 ]; then
                    error "  Skill '$SKILL_NAME' frontmatter missing 'description'"
                fi
                if [ "$HAS_NAME" -gt 0 ] && [ "$HAS_DESC" -gt 0 ]; then
                    pass "  Skill '$SKILL_NAME' frontmatter valid"
                fi

                # Check word count
                WORDS=$(wc -w < "$SKILL_DIR/SKILL.md")
                if [ "$WORDS" -gt 5000 ]; then
                    warn "  Skill '$SKILL_NAME' is $WORDS words (recommend < 2000)"
                elif [ "$WORDS" -gt 2000 ]; then
                    info "  Skill '$SKILL_NAME' is $WORDS words (consider splitting)"
                else
                    pass "  Skill '$SKILL_NAME' word count OK ($WORDS)"
                fi

                # Check referenced files exist
                for REF_DIR in references scripts assets; do
                    if grep -q "$REF_DIR/" "$SKILL_DIR/SKILL.md" 2>/dev/null; then
                        if [ ! -d "$SKILL_DIR/$REF_DIR" ]; then
                            warn "  Skill '$SKILL_NAME' references $REF_DIR/ but directory missing"
                        fi
                    fi
                done
            done
        fi
    fi
done

echo ""
echo "============================================="
echo "  AUDIT RESULTS"
echo "============================================="
echo -e "  Plugins checked: ${CYAN}$PLUGIN_COUNT${NC}"
echo -e "  Errors:   ${RED}$ERRORS${NC}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "  Score: ${GREEN}A${NC} — All checks passed"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "  Score: ${YELLOW}B${NC} — Valid with warnings"
else
    echo -e "  Score: ${RED}F${NC} — Has errors that must be fixed"
fi
echo ""
