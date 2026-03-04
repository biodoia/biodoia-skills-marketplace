---
name: sdd-steroids
description: "Use when starting any non-trivial development task, feature implementation, or project architecture decision — especially when wanting cutting-edge practices. This skill enriches Specification-Driven Development with real-time research of emerging best practices from tech news, agentic coding patterns, and community insights before writing any spec or code. Also use when mentioning 'SDD', 'specification driven', 'research before coding', 'latest best practices', 'agentic development', 'cutting edge patterns', or wanting to ensure development follows the most current industry practices."
---

# SDD on Steroids: Specification-Driven Development with Real-Time Intelligence

> **Research before you spec, spec before you code, verify before you ship.**

## Philosophy

Traditional Specification-Driven Development is a proven methodology: write the specification first, validate it, then implement against it. But traditional SDD has a blind spot — it relies on static knowledge. The developer (human or AI agent) writes the spec using whatever practices they already know, which may be months or years out of date.

**SDD on Steroids** fixes this by adding a critical Phase 0: RECON. Before writing a single line of specification, the agent actively researches what is NEW and EMERGING in the relevant technology domain. It scours tech news, community discussions, trending repositories, conference talks, and recent papers to discover:

- New libraries that obsolete old approaches
- Architectural patterns gaining traction
- Anti-patterns recently identified by the community
- Security advisories that affect the chosen stack
- Performance insights from production war stories
- Testing strategies being adopted by leading teams

This is not busywork. This is the difference between building with yesterday's best practices and building with tomorrow's. The RECON phase is what makes this "on steroids."

**Agent-Native Design**: This workflow is designed specifically for AI coding agents that CAN search the web, synthesize findings across multiple sources, and integrate discoveries into structured output. A human developer would spend hours doing this research. An AI agent does it in minutes, producing a structured intelligence brief that directly feeds into the specification.

## The 5-Phase Workflow

```
Phase 0: RECON ──> Phase 1: SPEC ──> Phase 2: VALIDATE ──> Phase 3: BUILD ──> Phase 4: VERIFY
   |                  ^                                        |                    |
   |                  |                                        |                    |
   +--- intelligence  +--- if spec issues found ---------------+                    |
         feeds spec         return to SPEC, not ad-hoc fixes                        |
                                                                                    |
                                                               retrospective -------+
                                                               feeds future RECON
```

---

### Phase 0: RECON (Research & Intelligence Gathering)

This is the "steroids" part. Before writing ANY specification, conduct targeted intelligence gathering across multiple sources. The goal is not to read everything — it is to find signals relevant to the task at hand.

#### Step 1: News Scouting

Search these sources for emerging practices relevant to the development task. Use WebSearch and WebFetch tools to access them:

- **Hacker News** (news.ycombinator.com) — Filter the front page and recent top stories. HN is the fastest signal for what experienced developers are excited or worried about.
- **daily.dev** — Aggregated developer news with curated feeds. Good for trending articles across the ecosystem.
- **lobste.rs** — High-quality, invite-only tech discussion. Higher signal-to-noise than most sources.
- **Reddit** — r/programming, r/golang, r/webdev, r/devops, r/ExperiencedDevs. Sort by top/week for recent validated content.
- **Dev.to, Hashnode** — Developer blog platforms. Search for "[technology] best practices [current year]".
- **GitHub Trending** — Trending repositories in the relevant language. New tools often surface here before anywhere else.
- **Changelog.com, TLDR Newsletter** — Curated tech news archives. Good for catching things the agent might have missed.
- **X/Twitter** — Search for the topic combined with "best practice", "TIL", "game changer", "just discovered". Developers share real production insights here.
- **YouTube** — Recent conference talks: GopherCon, KubeCon, Strange Loop, QCon, NDC, FOSDEM. Look for talks from the last 6 months.
- **ArXiv/Papers** — For ML/AI-related tasks, check recent papers on the specific technique or model architecture.

Refer to `references/recon-sources.md` for detailed search strategies, API endpoints, and query templates for each source.

#### Step 2: Pattern Extraction

From the scouted content, systematically extract:

- **New libraries/tools** that solve the problem better than established alternatives
- **Emerging architectural patterns** (e.g., new approaches to state management, API design, deployment)
- **Anti-patterns recently identified** by the community (things that seemed fine but turned out problematic)
- **Performance insights** from production war stories (real numbers, not theory)
- **Security advisories** relevant to the chosen stack (CVEs, supply chain issues, dependency risks)
- **Testing strategies** being adopted by leading teams (new frameworks, coverage approaches, mutation testing)

#### Step 3: Relevance Filtering

Score each finding along these axes:

| Axis | Values | Criteria |
|------|--------|----------|
| **Direct relevance** | HIGH / MEDIUM / LOW | Does this finding directly affect the task's architecture, implementation, or technology choices? |
| **Maturity** | Bleeding edge / Early adopter / Mainstream | How battle-tested is this? Bleeding edge = interesting but risky. Mainstream = safe but maybe not news. |
| **Community validation** | Stars, upvotes, adoption numbers | Is the community actually using this, or is it hype? |
| **Risk assessment** | Proven in production / Experimental / Unproven | Would you bet your production system on this? |

Filter aggressively. Only HIGH and MEDIUM relevance findings make it into the intelligence brief. LOW relevance findings are logged but not acted on.

#### Step 4: Intelligence Brief

Produce a structured RECON brief (see `references/spec-templates.md` for the full template):

```
RECON BRIEF: [task/project name]
Date: [today]
Sources consulted: [list of sources searched]
Search queries used: [list of queries]

EMERGING PRACTICES (directly relevant):
  - [finding]: [source] [maturity] [recommendation]
  - [finding]: [source] [maturity] [recommendation]

NEW TOOLS/LIBRARIES:
  - [tool]: [what it solves] [stars/adoption] [recommend: adopt/evaluate/watch]
  - [tool]: [what it solves] [stars/adoption] [recommend: adopt/evaluate/watch]

ANTI-PATTERNS TO AVOID:
  - [pattern]: [why it's bad] [source]
  - [pattern]: [why it's bad] [source]

SECURITY ADVISORIES:
  - [advisory]: [impact] [action required]

CONFIDENCE: [HIGH/MEDIUM/LOW]
  HIGH = multiple corroborating sources, production-validated findings
  MEDIUM = some corroboration, mostly early-adopter stage
  LOW = limited sources, bleeding edge, take with caution

ACTION SUMMARY:
  ADOPT: [findings ready for immediate use]
  EVALUATE: [findings worth prototyping/testing]
  WATCH: [findings to monitor but not act on yet]
  IGNORE: [findings not relevant enough]
```

Present the RECON brief to the user before proceeding. The user may redirect, add context, or override recommendations.

---

### Phase 1: SPEC (Specification Writing)

Write the specification INFORMED by the RECON brief. This is not a generic spec — every section should reference specific findings that influenced the decisions.

Use the specification template from `references/spec-templates.md`. The key sections:

```markdown
# Specification: [feature/project name]

## Context & RECON Findings
[Summary of the intelligence brief. What did we learn? What are we adopting, evaluating, or ignoring?]

## Requirements
### Functional Requirements
[What the system must do]

### Non-Functional Requirements
[Performance, scalability, security, maintainability targets — informed by RECON production insights]

## Architecture Decision Records (ADRs)
[Each significant decision documented with:
  - Decision
  - Context (including RECON evidence)
  - Alternatives considered
  - Consequences
  - Status: Accepted/Proposed/Superseded]

## Technology Stack
[Every technology choice justified with evidence from RECON.
  - Why this library over alternatives?
  - What did the research say about maturity?
  - What are the known risks?]

## API/Interface Design
[Contracts, schemas, protocols, endpoint definitions]

## Test Strategy
[Informed by latest testing practices from RECON.
  - Unit testing approach
  - Integration testing
  - E2E strategy
  - Performance benchmarks
  - Security testing]

## Security Considerations
[Directly from RECON advisories + standard threat modeling]

## Implementation Plan
[Ordered phases with dependencies, estimated effort, checkpoint criteria]
```

Flag explicitly where emerging practices differ from established ones. If the RECON found a new approach that contradicts conventional wisdom, document both the old way and the new way, with evidence for why the spec chooses what it chooses.

---

### Phase 2: VALIDATE (Specification Review)

Before any code is written, validate the specification:

1. **Cross-check against RECON findings** — Did any finding get overlooked? Does the spec contradict any evidence?
2. **Anti-pattern scan** — Verify no identified anti-patterns slipped into the design
3. **Technology compatibility check** — Are all chosen technologies compatible with each other? Version conflicts? License issues?
4. **Risk identification** — What could go wrong? What are the fallback plans?
5. **Completeness check** — Are all requirements addressed? Are edge cases covered?
6. **User review checkpoint** — Present the validated spec to the user. This is a HARD GATE. Do not proceed to BUILD without explicit user approval.

If validation reveals issues, return to Phase 1 with specific corrections. Do not patch — revise the spec properly.

---

### Phase 3: BUILD (Implementation)

With an approved, validated specification in hand, implement:

1. **Follow the spec strictly.** The spec is the contract. If the implementation reveals that the spec is wrong, STOP and return to Phase 1. Do not make ad-hoc fixes that deviate from the spec.
2. **TDD where applicable.** Write tests before implementation for each module. Use the test strategy from the spec.
3. **Module-by-module verification.** After implementing each module, verify it against the spec before moving to the next.
4. **Checkpoint commits.** Make granular commits at each phase boundary and at each significant module completion. Every commit should be a valid, buildable state.
5. **Continuous spec reference.** Regularly re-read relevant spec sections while implementing. Drift is the enemy.

For agentic coding patterns during BUILD, refer to `references/agentic-patterns.md` for multi-agent orchestration, verification loops, context management, and error recovery strategies.

---

### Phase 4: VERIFY (Verification & Retrospective)

The final phase ensures everything works and captures learnings:

1. **Run all tests.** Unit, integration, E2E. Everything green.
2. **Verify against original requirements.** Walk through each requirement and confirm it is met.
3. **Performance check.** Run benchmarks if the spec defined performance targets.
4. **Security scan.** Check dependencies, run any security tools specified in the test strategy.
5. **Spec compliance audit.** Does the implementation match the spec? Document any approved deviations.
6. **Retrospective.** Capture learnings:
   - Which RECON findings were actually useful?
   - Which were noise?
   - What would we search for differently next time?
   - Feed insights back for future RECON phases (adaptive learning)

---

## RECON Search Strategies by Domain

Provide targeted search queries based on the development domain:

| Domain | Search Queries |
|--------|---------------|
| **Web backend** | "[language] best practices [year]", "API design patterns [year]", "microservices antipatterns", "[framework] production tips" |
| **Frontend** | "react patterns [year]", "htmx vs spa [year]", "web performance optimization", "CSS architecture [year]" |
| **Infrastructure** | "kubernetes alternatives [year]", "deployment patterns", "observability stack [year]", "platform engineering" |
| **AI/ML** | "LLM integration patterns", "agentic coding workflow", "RAG best practices [year]", "AI code review tools" |
| **Security** | "OWASP [year]", "supply chain security", "dependency scanning tools", "zero trust architecture" |
| **Go** | "golang best practices [year]", "Go project structure [year]", "Go concurrency patterns", "Go error handling [year]" |
| **Database** | "database scaling patterns", "PostgreSQL performance [year]", "vector database comparison [year]" |
| **Testing** | "mutation testing", "property-based testing", "testing in production [year]", "contract testing" |

Always replace `[year]` with the current year to get the freshest results.

## Integration with Other Skills

This skill works best when combined with complementary skills:

- **`superpowers:brainstorming`** — Use during Phase 1 for divergent thinking on architecture options
- **`superpowers:writing-plans`** — Use during Phase 1 for structured plan generation
- **`superpowers:test-driven-development`** — Use during Phase 3 for TDD implementation
- **`superpowers:verification-before-completion`** — Use during Phase 4 for systematic verification
- **`skill-master`** — Use to discover additional relevant skills for the specific domain

When these skills are available, invoke them at the appropriate phase. When they are not, follow the equivalent methodology described in this skill.

## Agentic Coding Intelligence

When the task involves AI-assisted development, the RECON phase should pay special attention to:

- **Prompt engineering patterns** for code generation — what prompt structures produce the best code?
- **Agent orchestration patterns** — dispatcher/specialist/reviewer architectures, parallel agent execution
- **Context management** — what to include in context, what to leave out, how to handle large codebases
- **Verification loops** — generate-test-iterate cycles, self-correction patterns
- **Human-in-the-loop checkpoints** — where to pause for human judgment
- **MCP server patterns** — tool integration, resource exposure, protocol compliance
- **Memory and persistence** — how agents maintain state across sessions
- **Cost optimization** — model routing, caching strategies, token efficiency

See `references/agentic-patterns.md` for comprehensive coverage of these patterns.

## Progressive Disclosure

- For detailed source-by-source research guidance: read `references/recon-sources.md`
- For ready-to-use specification and brief templates: read `references/spec-templates.md`
- For agentic coding patterns and AI-assisted development: read `references/agentic-patterns.md`

## Anti-Patterns in SDD

| Anti-Pattern | Why It Fails | What to Do Instead |
|-------------|-------------|-------------------|
| Skipping RECON because "I already know this" | Static knowledge degrades. The industry moves fast. | Always run RECON, even for familiar domains. You'll be surprised. |
| Writing vague specs ("make it fast") | Unverifiable requirements lead to endless debate | Quantify: "P99 latency under 200ms at 1000 RPS" |
| Spec becomes shelfware | Nobody reads a 50-page doc | Keep specs actionable, reference them during BUILD |
| Ad-hoc fixes during BUILD | Undermines the entire spec-driven approach | Return to Phase 1 if the spec is wrong |
| Skipping VALIDATE | "It compiles, ship it" | VERIFY catches integration issues, security gaps, spec drift |
| RECON paralysis | Researching forever, never starting | Time-box RECON to 15-30 minutes. Capture what you found, move on. |
| Adopting bleeding-edge without evaluation | Latest != greatest. Production readiness matters. | Use the maturity/risk scoring. Default to EVALUATE, not ADOPT. |
