---
description: Audit and validate a marketplace registry and all its plugins for quality and correctness
argument-hint: [marketplace-path]
allowed-tools: ["Read", "Write", "Bash", "Grep", "Glob", "Skill"]
---

# Audit Marketplace

Validate the structure and quality of a marketplace and all registered plugins.

**Arguments:** $ARGUMENTS

## Checks Performed

### Registry Level
- marketplace.json has valid JSON with required fields ($schema, name, description, owner, plugins)
- No duplicate plugin names
- All source paths resolve (local paths exist, URLs are valid)

### Plugin Level (for each registered plugin)
- plugin.json exists with at least `name` field
- `name` is kebab-case: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`
- Version is valid semver (if present)

### Skill Level (for each skill in each plugin)
- SKILL.md exists with valid YAML frontmatter
- Frontmatter has `name` and `description`
- Description starts with "Use when" or describes triggering conditions
- Description does NOT summarize the workflow
- SKILL.md body is under 5000 words
- All referenced files in references/, scripts/, assets/ exist
- Scripts are executable

### Quality Score
Each plugin gets a score:
- **A**: All checks pass, description follows best practices, progressive disclosure used
- **B**: Structure valid, minor description issues
- **C**: Missing optional components or weak descriptions
- **F**: Structural issues, missing required files

## Output

Generate a markdown report with:
- Overall marketplace health
- Per-plugin scores and issues
- Actionable fix suggestions
