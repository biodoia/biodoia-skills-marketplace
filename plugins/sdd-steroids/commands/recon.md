---
description: Run ONLY the RECON (Research & Intelligence Gathering) phase — scout tech news, extract emerging practices, and produce an intelligence brief without starting the full SDD workflow
argument-hint: <topic-or-task-description> [--deep] [--sources=hn,reddit,github]
allowed-tools: ["Read", "WebSearch", "WebFetch", "Write", "Bash", "Glob", "Grep"]
---

# RECON: Research & Intelligence Gathering

Run the RECON phase standalone to research emerging best practices, new tools, anti-patterns, and security advisories for a given topic or development task.

**Arguments:** $ARGUMENTS

## When to Use

- Before starting any development task to check what's new in the field
- When evaluating technology choices and wanting evidence-based decisions
- When a previously written specification needs to be updated with fresh intelligence
- As a standalone research tool — "What are the latest best practices for X?"
- Before a technical decision meeting to arm yourself with current data

## Workflow

### 1. Parse Arguments

Extract the topic or task description from $ARGUMENTS. If no arguments provided, ask the user what topic or technology domain they want to research.

Optional flags:
- `--deep` — Extended research: search more sources, include YouTube talks and ArXiv papers
- `--sources=hn,reddit,github` — Limit research to specific sources (comma-separated). Valid sources: `hn`, `reddit`, `github`, `lobsters`, `devto`, `daily`, `changelog`, `twitter`, `youtube`, `arxiv`

### 2. Identify Search Domain

From the topic/task description, determine:
- Primary technology/language (e.g., Go, React, Kubernetes)
- Problem domain (e.g., authentication, deployment, testing)
- Relevant subreddits, GitHub languages, and conference channels
- Appropriate search queries (use templates from `references/recon-sources.md`)

### 3. Scout Sources

Use WebSearch and WebFetch to research. Follow the source-specific guidance in `references/recon-sources.md`.

**Standard RECON (default):**
Search at minimum 4 sources:
1. Hacker News — front page + topic search
2. GitHub Trending — trending repos in the relevant language
3. Reddit — 2 relevant subreddits, sorted by top/month
4. One additional source based on domain (Dev.to for web, ArXiv for AI/ML, lobste.rs for systems)

**Deep RECON (--deep flag):**
Search at minimum 7 sources:
1. All standard sources above
2. lobste.rs — tag-filtered search
3. YouTube — recent conference talks
4. Changelog.com or TLDR archives
5. Additional Reddit subreddits
6. X/Twitter for practitioner insights
7. ArXiv/Papers (if AI/ML related)

### 4. Extract Patterns

From all scouted content, systematically extract:
- New libraries/tools that solve the problem
- Emerging architectural patterns
- Anti-patterns recently identified
- Performance insights from production
- Security advisories
- Testing strategies being adopted

### 5. Score and Filter

For each finding, assess:
- **Direct relevance:** HIGH / MEDIUM / LOW
- **Maturity:** Bleeding edge / Early adopter / Mainstream
- **Community validation:** Stars, upvotes, adoption metrics
- **Risk:** Proven in production / Experimental / Unproven

Filter: Only HIGH and MEDIUM relevance findings make it into the brief.

### 6. Produce Intelligence Brief

Generate a structured RECON BRIEF using the template from `references/spec-templates.md`.

Include:
- All sources consulted and queries used
- Emerging practices (directly relevant)
- New tools and libraries with adoption metrics
- Anti-patterns to avoid
- Security advisories
- Confidence level (HIGH/MEDIUM/LOW)
- Action summary: ADOPT / EVALUATE / WATCH / IGNORE for each finding

### 7. Present and Save

1. Present the RECON BRIEF to the user
2. Offer to save the brief to a file (suggested: `recon-brief-[topic]-[date].md`)
3. Ask if the user wants to proceed to the full SDD workflow (invoke `/sdd --skip-recon`)

## Output Format

The RECON BRIEF is presented inline and optionally saved to a file. The brief follows the RECON Brief template from `references/spec-templates.md` exactly.

## Tips for Effective RECON

- Replace `[year]` in all search queries with the current year
- When a source returns no results, try broader or alternative queries before skipping it
- Prioritize production experience reports over theoretical articles
- Cross-reference findings across sources — if multiple independent sources agree, confidence is higher
- Time-box: standard RECON should take 10-15 minutes, deep RECON 20-30 minutes
- It's OK to find nothing new — "no significant emerging changes" IS a valid finding
