---
description: Run the full SDD on Steroids workflow — RECON research, specification writing, validation, implementation, and verification
argument-hint: <task-description> [--skip-recon] [--recon-only] [--spec-only]
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "WebSearch", "WebFetch", "Skill"]
---

# SDD on Steroids

Run the complete Specification-Driven Development workflow with real-time intelligence gathering.

**Arguments:** $ARGUMENTS

## Workflow

### 1. Parse Arguments

Extract the task description from $ARGUMENTS. If no arguments provided, ask the user to describe the development task, feature, or project they want to build.

Optional flags:
- `--skip-recon` — Skip Phase 0 (use when RECON was already done separately via `/recon`)
- `--recon-only` — Stop after Phase 0 (equivalent to `/recon`)
- `--spec-only` — Stop after Phase 2 (RECON + SPEC + VALIDATE, no implementation)

### 2. Phase 0: RECON

Follow the RECON phase from the `sdd-steroids` skill:

1. Identify the relevant technology domain from the task description
2. Use WebSearch and WebFetch to scout sources listed in `references/recon-sources.md`
3. Search at minimum: Hacker News, GitHub Trending, 2 Reddit subreddits relevant to the domain, and 1 additional source
4. Extract patterns, tools, anti-patterns, and security advisories
5. Score findings by relevance, maturity, community validation, and risk
6. Produce a structured RECON BRIEF using the template from `references/spec-templates.md`
7. Present the RECON BRIEF to the user for review
8. Wait for user approval before proceeding

### 3. Phase 1: SPEC

Write the specification informed by the RECON brief:

1. Use the Feature Specification template from `references/spec-templates.md`
2. Reference specific RECON findings in architecture decisions
3. Write ADRs for each significant technology choice
4. Define test strategy informed by latest testing practices
5. Include security considerations from RECON advisories
6. Create an ordered implementation plan with checkpoint criteria

### 4. Phase 2: VALIDATE

Cross-check the specification:

1. Verify all RECON findings are addressed (adopted, evaluated, or explicitly rejected)
2. Scan for anti-patterns identified during RECON
3. Check technology compatibility (versions, licenses, dependencies)
4. Identify risks and document mitigations
5. Present the validated specification to the user
6. HARD GATE: Do not proceed without explicit user approval

### 5. Phase 3: BUILD

Implement according to the specification:

1. Follow the implementation plan phase by phase
2. TDD: write tests before implementation for each module
3. Verify each module against the spec before proceeding
4. Make checkpoint commits at each phase boundary
5. If implementation reveals spec issues, STOP and return to Phase 1

Use patterns from `references/agentic-patterns.md` for effective implementation.

### 6. Phase 4: VERIFY

Run verification and retrospective:

1. Run all tests (unit, integration, E2E as applicable)
2. Verify against original requirements from the spec
3. Check performance against NFR targets (if defined)
4. Run security checks (dependency scan, known vulnerability check)
5. Produce a retrospective using the template from `references/spec-templates.md`
6. Report final status to the user

## Integration

If available, invoke complementary skills at the appropriate phases:
- Phase 1: `superpowers:brainstorming` for architecture ideation
- Phase 1: `superpowers:writing-plans` for structured planning
- Phase 3: `superpowers:test-driven-development` for TDD
- Phase 4: `superpowers:verification-before-completion` for systematic verification
