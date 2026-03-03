# Skill Catalog — Complete Ecosystem Map

## biodoia Marketplace Skills

### marketplace-creator (development)
- **Triggers**: "marketplace", "scaffold plugin", "create plugin registry", "manage skills", "publish skills"
- **Provides**: Marketplace repo init, plugin scaffolding, registry management, audit, web creator
- **Combines with**: plugin-dev:skill-development, plugin-dev:plugin-structure

### tailscale-expert (networking)
- **Triggers**: "tailscale", "tailnet", "wireguard mesh", "exit node", "subnet router", "MagicDNS"
- **Provides**: VPN setup, ACLs, exit nodes, subnet routing, MagicDNS, troubleshooting
- **Combines with**: xen-orchestra-expert (for VM networking)

### xen-orchestra-expert (infrastructure)
- **Triggers**: "xen orchestra", "XO", "XCP-ng", "xo-cli", "VM management"
- **Provides**: VM lifecycle, backups, storage, networking, REST API, pool management
- **Combines with**: tailscale-expert (for mesh VPN on VMs)

### skill-master (meta)
- **Triggers**: "which skill", "skill recommendations", "onboard me", "improve skills", "skill analytics"
- **Provides**: Proactive onboarding, skill recommendation, adaptive growth, usage analytics
- **Combines with**: Everything — this is the orchestrator

## Official Plugin Skills (claude-plugins-official)

### superpowers (core workflow)
- **brainstorming**: Creative work, feature design, building components
- **test-driven-development**: Implementing features or bugfixes
- **systematic-debugging**: Encountering bugs, test failures, unexpected behavior
- **writing-plans**: Multi-step tasks before touching code
- **executing-plans**: Running written implementation plans
- **subagent-driven-development**: Plans with independent tasks in current session
- **dispatching-parallel-agents**: 2+ independent tasks without shared state
- **writing-skills**: Creating, editing, or verifying skills
- **verification-before-completion**: About to claim work is done
- **requesting-code-review**: Completing tasks, before merging
- **receiving-code-review**: Got review feedback to implement
- **finishing-a-development-branch**: Implementation complete, ready to integrate
- **using-git-worktrees**: Need isolation for feature work

### skill-creator
- **Triggers**: "create a skill", "update skill", "run evals", "benchmark skill", "optimize description"
- **Provides**: Full skill creation lifecycle with TDD eval loop

### plugin-dev (plugin development)
- **skill-development**: Create/improve plugin skills
- **plugin-structure**: Plugin directory layout, manifest, components
- **hook-development**: Create hooks (PreToolUse, PostToolUse, SessionStart, etc.)
- **command-development**: Slash commands with frontmatter
- **agent-development**: Subagent definitions
- **mcp-integration**: MCP server config in plugins
- **plugin-settings**: .local.md files for plugin config

### frontend-design
- **Triggers**: "build web component", "create page", "web application"
- **Provides**: Production-grade frontend with high design quality

### claude-code-setup
- **claude-automation-recommender**: Analyze codebase, recommend automations

### claude-md-management
- **claude-md-improver**: Audit and improve CLAUDE.md files
- **revise-claude-md**: Update CLAUDE.md with session learnings

### figma
- **implement-design**: Figma to production code
- **code-connect-components**: Map Figma to code components
- **create-design-system-rules**: Generate design system rules

### coderabbit
- **code-review**: AI code review on changes

### commit-commands
- **commit**: Create git commit
- **commit-push-pr**: Commit, push, and open PR
- **clean_gone**: Clean up deleted remote branches

## Skill Stack Templates

### New Go Project (biodoia ecosystem)
```
1. superpowers:brainstorming       (design first)
2. superpowers:writing-plans       (plan the work)
3. superpowers:test-driven-development (TDD)
4. superpowers:verification-before-completion (verify)
5. commit-commands:commit          (checkpoint)
```

### Plugin Development
```
1. marketplace-creator             (scaffold)
2. plugin-dev:plugin-structure     (architecture)
3. plugin-dev:skill-development    (write skills)
4. plugin-dev:hook-development     (add hooks)
5. skill-creator:skill-creator     (test & iterate)
```

### Infrastructure Setup
```
1. tailscale-expert                (VPN mesh)
2. xen-orchestra-expert            (VMs)
3. superpowers:writing-plans       (plan)
4. superpowers:systematic-debugging (troubleshoot)
```

### Code Review Flow
```
1. superpowers:requesting-code-review  (prepare)
2. coderabbit:code-review              (AI review)
3. superpowers:receiving-code-review   (process feedback)
4. superpowers:verification-before-completion (verify fixes)
```
