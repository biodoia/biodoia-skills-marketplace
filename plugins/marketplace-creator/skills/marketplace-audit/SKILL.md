---
name: marketplace-audit
description: This skill should be used when the user asks to "audit the marketplace", "validate all plugins", "check skill quality", "run quality checks", "verify marketplace integrity", or "audit SKILL.md files". Make sure to use this skill whenever the user wants to validate plugin structure, check writing style compliance, verify word counts, find broken references, or ensure marketplace.json consistency, even if they just mention wanting to check or improve the marketplace without explicitly saying audit.
disable-model-invocation: true
---

# Marketplace Audit

Comprehensive validation of the biodoia-skills-marketplace. Run the automated audit script for a quick pass, then follow up with targeted manual checks for issues the script flags.

## Quick Start

Run the full automated audit:

```bash
bash plugins/marketplace-creator/skills/marketplace-audit/scripts/audit-all.sh
```

The script exits with code 0 if all checks pass, 1 if any issues are found. Output is structured by category with pass/fail markers per check.

## Audit Categories

### 1. Registry Integrity (marketplace.json)

Verify the central registry:
- Valid JSON with `$schema`, `name`, `description`, `owner`, `plugins[]`
- Every plugin entry has `name`, `description`, `category`, `source`
- No duplicate plugin names
- Every `source: "./plugins/<name>"` path exists on disk
- Every plugin directory on disk is registered in marketplace.json (no orphans)

### 2. Plugin Structure

For each plugin directory:
- `.claude-plugin/plugin.json` exists and contains valid JSON
- `plugin.json` has at least `name` field
- `name` matches pattern `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`
- At least one `skills/<name>/SKILL.md` exists
- No empty directories (skills/, references/, scripts/ without content)

### 3. SKILL.md Quality

For each SKILL.md file:
- **Frontmatter**: Valid YAML with exactly `name` and `description` fields
- **Description format**: Starts with "This skill should be used when" (third-person)
- **Trigger phrases**: Description contains quoted trigger phrases
- **Writing style**: Zero `you/your/you're/yourself` violations (imperative form required)
- **Word count**: Body between 1000-3000 words (target 1500-2000)
- **Additional Resources**: Section exists referencing bundled files
- **No orphan references**: Every file cited in "Additional Resources" exists on disk

### 4. Reference Integrity

For each plugin with references/:
- Every `.md` file in references/ is cited somewhere in SKILL.md
- Every reference path mentioned in SKILL.md exists on disk
- Reference files are non-empty

### 5. Script Validation

For each plugin with scripts/:
- Scripts are executable (`chmod +x`)
- Bash scripts have proper shebang (`#!/usr/bin/env bash` or `#!/bin/bash`)
- Python scripts have shebang and are syntactically valid (`python3 -c "import ast; ast.parse(open('file').read())"`)

### 6. Agent Validation

For plugins with agents/:
- Agent `.md` files have YAML frontmatter with `name` and `description`
- `tools:` field lists only valid tool names

### 7. Hooks Validation

For plugins with hooks/:
- `hooks.json` is valid JSON
- Has outer `{"hooks": {...}}` wrapper
- Event names are valid (PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop, SessionStart, SessionEnd, PreCompact, Notification)
- Hook entries have `type`, `command` fields

## Manual Follow-up

After the automated audit, review these areas manually — they require judgment that scripts cannot provide.

### Description Effectiveness

Read each description and assess triggering quality:

- **Coverage**: Would the description trigger on realistic user queries? Test with varied phrasings ("set up LSP", "configure language server", "why isn't gopls working") to verify the description catches different ways of asking the same thing.
- **Specificity**: Are trigger phrases specific enough to avoid false positives? A description that triggers on "configure" alone would fire too broadly.
- **Pushiness**: Skills tend to under-trigger rather than over-trigger. Descriptions should be slightly aggressive — including phrases like "even if they just mention X without explicitly saying Y" combats this tendency.
- **Edge cases**: Consider whether users from adjacent domains might trigger the wrong skill (e.g., "Docker networking" triggering tailscale-expert instead of the Docker-related skill).

### Content Accuracy

For domain-specific skills (gRPC, QUIC, Tailscale, XCP-ng, etc.):

- **Version currency**: Do commands and flags reflect current CLI versions? Check `--version` output against documented commands.
- **Code correctness**: Run or mentally trace code examples to verify they work. Common issues: deprecated API fields, changed default ports, renamed CLI flags.
- **Best practices**: Does the skill recommend current best practices? Technologies evolve — what was recommended 6 months ago might have better alternatives now.
- **External links**: If any skill references external URLs, verify they still resolve and point to the intended content.

### Progressive Disclosure Balance

Evaluate the split between SKILL.md body and references/:

- **SKILL.md leanness**: The body should contain essential workflow, not exhaustive reference. If a section reads like a reference manual, move it to references/.
- **Reference completeness**: Each references/ file should be self-contained — readable without SKILL.md context. Missing context in references forces readers back to the main file.
- **Pointer quality**: The "Additional Resources" section should describe WHEN to consult each reference, not just list filenames. Good: "Consult when configuring Neovim LSP servers". Bad: "See editor-configs.md".

### Cross-Skill Consistency

When auditing the full marketplace:

- **Terminology**: Consistent naming across skills (e.g., "Additional Resources" not "Reference Files" or "Progressive Disclosure").
- **Depth parity**: Skills at similar complexity levels should have similar depth. A 600-word skill next to a 2500-word skill signals imbalance.
- **Category accuracy**: Verify each plugin's `category` in marketplace.json matches its actual domain.
- **Script coverage**: Plugins with complex workflows should bundle automation scripts. If a skill describes a multi-step process that is repeated often, consider adding a script to reduce manual effort and ensure consistency across invocations.

## Interpreting Results

The audit script outputs a structured report with pass/warn/fail counts per category:

```
MARKETPLACE AUDIT REPORT
===============================
  Pass: 199
  Warn: 1
  Fail: 0
===============================

Issues found:
  - WARN: plugins/example/skills/example/SKILL.md: 626 words (target 1000-3000)

Result: WARN (1 items need attention)
```

**Severity levels:**
- **FAIL**: Critical structural issues — broken JSON, missing required files, invalid schemas. These block plugin functionality.
- **WARN**: Quality issues — style violations, word count out of range, uncited references. The plugin works but does not meet quality standards.
- **PASS**: All checks satisfied.

**Resolution workflow:**
1. Fix all FAIL items first (structural integrity)
2. Address WARN items by category (style, then word count, then references)
3. Re-run the audit to verify fixes
4. Proceed to manual review for subjective quality

Target: zero FAIL, zero WARN, all PASS. Use `--verbose` flag to see per-file detail when debugging specific issues.

## Additional Resources

- **`scripts/audit-all.sh`** — Full automated audit script covering all 7 categories. Run with `--verbose` for per-file detail or `--json` for machine-readable output.
- **`../marketplace-creator/SKILL.md`** — Plugin scaffolding and registration workflow (consult when audit finds structural issues).
- **`../marketplace-creator/references/plugin-anatomy.md`** — Detailed plugin component specifications (consult for structure validation rules).
- **`../marketplace-creator/references/marketplace-schema.md`** — marketplace.json schema reference (consult for registry validation).
