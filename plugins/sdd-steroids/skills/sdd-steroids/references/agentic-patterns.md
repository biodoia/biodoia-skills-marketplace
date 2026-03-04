# Agentic Coding Patterns

Emerging patterns in AI-assisted and agentic software development. This reference is designed for the RECON phase when the development task involves building with or for AI agents, and for the BUILD phase when using AI agents as development tools.

---

## 1. Multi-Agent Orchestration

### The Dispatcher-Specialist-Reviewer Architecture

The most proven pattern for complex tasks: a dispatcher agent decomposes the work, specialist agents execute focused subtasks, and a reviewer agent validates the output.

```
                    +-- Specialist A (frontend) --+
                    |                              |
User --> Dispatcher +-- Specialist B (backend)  --+--> Reviewer --> Output
                    |                              |
                    +-- Specialist C (tests)    --+
```

**When to use:** Tasks that naturally decompose into independent subtasks with different expertise requirements.

**Key principles:**
- Dispatcher should be a lightweight routing agent, not a domain expert
- Specialists should have narrow, focused context (only what they need)
- Reviewer should have access to the full specification and all specialist outputs
- Communication between agents should be structured (JSON, not natural language)

**Anti-pattern:** Having one agent do everything sequentially when subtasks are independent. This wastes time and risks context window exhaustion.

### Parallel Agent Execution

When subtasks are independent, run specialist agents in parallel:

```
Task: "Add user authentication with tests and documentation"

  Parallel:
    Agent 1: Implement auth module (backend specialist)
    Agent 2: Write unit tests (testing specialist)
    Agent 3: Write API documentation (documentation specialist)

  Sequential (after parallel):
    Agent 4: Integration review (reviewer)
    Agent 5: Integration tests (testing specialist)
```

**Key principles:**
- Identify true independence — agents must not need each other's output
- Define clear interfaces before parallelization
- Merge step must resolve conflicts
- Each parallel agent gets the shared specification but NOT each other's work-in-progress

### Hierarchical Decomposition

For very large tasks, use recursive decomposition:

```
Lead Agent
  |
  +-- Module A Lead
  |     +-- Component A1 Agent
  |     +-- Component A2 Agent
  |
  +-- Module B Lead
        +-- Component B1 Agent
        +-- Component B2 Agent
```

**When to use:** Project-scale work where a single dispatcher would be overwhelmed. Each "lead" manages a coherent module.

---

## 2. Context Window Management Strategies

The context window is the most constrained resource in agentic coding. Effective management is the difference between success and failure.

### The Minimal Context Principle

Give each agent the MINIMUM context needed for its task:

| Good | Bad |
|------|-----|
| Relevant function signatures + spec section | Entire codebase dump |
| Interface definitions | Full implementation details |
| Test requirements for this module | All project tests |
| Error context + surrounding code | Full file contents |

### Context Layering

Structure context in layers of increasing detail:

1. **Layer 0 (always included):** Project summary, tech stack, coding conventions
2. **Layer 1 (task-specific):** Relevant specification sections, ADRs
3. **Layer 2 (implementation):** Relevant source files, interfaces, types
4. **Layer 3 (on-demand):** Full file contents, test results, error logs

Start with Layer 0+1, add Layer 2 as needed, Layer 3 only when debugging.

### Context Rotation

For long-running tasks that exceed the context window:

1. **Checkpoint:** Save current state to files (progress, decisions, partial outputs)
2. **Compact:** Summarize what was done and what remains
3. **Resume:** New context with summary + remaining work + fresh Layer 2 context

**Key principle:** The checkpoint must be self-contained. Another agent (or the same agent with a fresh context) should be able to continue from the checkpoint without any "memory" of the previous conversation.

### Smart File Reading

Instead of reading entire files, use targeted strategies:

- Read only function signatures and type definitions first
- Use grep/search to find relevant sections
- Read specific line ranges around points of interest
- Build a mental model from structure, then dive into details

---

## 3. Tool-Augmented Generation

### Tool Selection Strategy

When multiple tools can accomplish a task, choose based on:

| Factor | Preference |
|--------|-----------|
| Precision | Prefer specialized tools over general-purpose |
| Verification | Prefer tools that produce verifiable output |
| Atomicity | Prefer tools with clear success/failure signals |
| Reversibility | Prefer non-destructive tools when exploring |

### Tool Chaining Patterns

**Sequential chain:** Each tool's output feeds the next
```
Read file --> Analyze code --> Edit file --> Run tests --> Verify
```

**Branching chain:** Use tool output to decide next action
```
Search for pattern
  |
  Found --> Read and edit
  |
  Not found --> Search with alternative pattern
                  |
                  Found --> Read and edit
                  |
                  Not found --> Create new file
```

**Verification chain:** Every mutation is followed by verification
```
Edit file --> Run linter --> Run tests --> Verify change
                |               |
                Fail            Fail
                |               |
                Fix lint      Fix test
                |               |
                +-- retry --+--+
```

### The Read-Before-Write Rule

ALWAYS read a file's current state before modifying it. This applies to:
- Editing source code
- Modifying configuration files
- Updating documentation
- Changing test files

**Why:** The file may have changed since the agent last saw it (other agents, user edits, automated processes). Writing without reading risks overwriting important changes.

---

## 4. Verification Loops and Guardrails

### The Generate-Test-Iterate Cycle

The core loop for reliable code generation:

```
Step 1: Generate code from specification
Step 2: Run compiler/linter -- syntactic correctness
Step 3: Run unit tests -- functional correctness
Step 4: Run integration tests -- system correctness
Step 5: Check against spec -- requirement compliance

If any step fails:
  Analyze the failure
  Identify the root cause
  Determine if it's a code issue or spec issue
  If code issue: fix and restart from Step 2
  If spec issue: STOP, return to Phase 1 (SPEC)
```

**Key principle:** Never skip verification steps to save time. Every skipped check compounds the risk of shipping broken code.

### Self-Correction Patterns

When an agent produces incorrect output:

1. **Error analysis:** Don't just retry. Analyze WHAT went wrong and WHY.
2. **Root cause identification:** Is it a misunderstanding of the requirement? A missing context? A wrong assumption?
3. **Targeted fix:** Fix the root cause, not the symptom.
4. **Regression check:** After fixing, verify that the fix doesn't break what was working.

**Anti-pattern:** Blind retry — running the same generation again hoping for a different result. This wastes tokens and rarely works.

### Guardrails

Hard constraints that should NEVER be violated:

- **No destructive operations without explicit confirmation** (git force push, rm -rf, database drops)
- **No secret exposure** (API keys, passwords, tokens must never appear in output)
- **No unbounded loops** (every retry must have a maximum count)
- **No silent failures** (every error must be reported, even if handled)
- **Spec compliance** (no ad-hoc deviations from the specification)

---

## 5. Human-in-the-Loop Design Patterns

### Checkpoint Gates

Define explicit points where human review is required:

| Gate | When | What to Present |
|------|------|----------------|
| **RECON Review** | After Phase 0 | Intelligence brief, recommended actions |
| **Spec Approval** | After Phase 1+2 | Complete specification, highlighted decisions |
| **Architecture Review** | Before major refactors | ADRs, risk assessment |
| **Pre-Ship Review** | After Phase 4 | Test results, spec compliance, known issues |

**Key principle:** Make gates lightweight. Present a clear summary with actionable options (approve / revise / reject). Don't dump raw data on the human.

### Escalation Patterns

When to stop and ask for human input:

- **Ambiguous requirements** — The spec can be interpreted multiple ways
- **Conflicting evidence** — RECON findings contradict each other
- **High-risk decisions** — Security-critical, data-destructive, or irreversible actions
- **Unexpected complexity** — Task is significantly harder than estimated
- **Novel territory** — No precedent or established pattern exists

### Decision Framing

When presenting decisions to humans, structure as:

```
DECISION REQUIRED: [one-line summary]

Context: [2-3 sentences of background]

Options:
  A) [option] — Pros: [list] / Cons: [list]
  B) [option] — Pros: [list] / Cons: [list]
  C) [option] — Pros: [list] / Cons: [list]

Recommendation: [which option and why]

Risk if deferred: [what happens if we don't decide now]
```

---

## 6. MCP Integration Patterns

### Server Design

Model Context Protocol (MCP) servers expose tools, resources, and prompts to AI agents. Key patterns:

**Single-responsibility servers:** Each MCP server should do one thing well
```
Good: mcp-database (CRUD operations on your database)
Good: mcp-deployment (deploy, rollback, status)
Bad:  mcp-everything (database + deployment + monitoring + ...)
```

**Idempotent tools:** MCP tools should be safe to retry
```
Good: "set_config(key, value)" — always produces the same result
Bad:  "increment_counter()" — different result on each call
```

**Structured errors:** Return errors with enough context for the agent to self-correct
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Field 'email' must be a valid email address",
    "field": "email",
    "received": "not-an-email",
    "suggestion": "Provide a value matching the pattern: user@domain.tld"
  }
}
```

### Resource Exposure

Expose read-only context as MCP resources:
- Project configuration
- Schema definitions
- API documentation
- Environment information

**Key principle:** Resources are for READING context. Tools are for TAKING actions. Don't conflate them.

### Prompt Templates

Expose reusable prompt templates as MCP prompts:
- Code review checklist
- Debugging workflow
- Refactoring guide
- Test generation template

---

## 7. Prompt Chaining vs Agent Delegation

### When to Chain Prompts

Use prompt chaining (sequential prompts to the SAME model) when:
- Each step requires the full context of previous steps
- The task is inherently sequential (step 2 depends on step 1's output)
- The context window can accommodate the entire chain

```
Prompt 1: "Analyze this code and identify the bug"
  --> Output 1: "The bug is in the null check on line 42..."
Prompt 2: "Given this analysis, write a fix: {Output 1}"
  --> Output 2: [fixed code]
Prompt 3: "Write a test that catches this bug: {Output 1}"
  --> Output 3: [test code]
```

### When to Delegate to Agents

Use agent delegation (spawning separate agent instances) when:
- Subtasks are independent and can run in parallel
- Different subtasks benefit from different context
- The total context would exceed a single agent's window
- Subtasks require different specializations

```
Main Agent: "Build user authentication"
  Delegate to Agent A: "Implement the auth middleware" (gets: API spec, security requirements)
  Delegate to Agent B: "Write auth tests" (gets: test strategy, API spec)
  Delegate to Agent C: "Write auth documentation" (gets: API spec, doc templates)
Main Agent: Review and integrate all outputs
```

### Hybrid Approach

Most real-world tasks use both:
- Chain prompts within a single subtask for coherence
- Delegate across subtasks for parallelism and context efficiency

---

## 8. Memory and Persistence Patterns

### Session-Scoped Memory

Information that persists within a single session:
- Current task context and progress
- Decisions made and rationale
- Files read and their summaries
- Errors encountered and fixes applied

**Implementation:** Maintained in the conversation context. Use compaction/summarization when approaching context limits.

### Project-Scoped Memory

Information that persists across sessions for a project:
- Architecture decisions (ADRs)
- Coding conventions and patterns
- Known issues and workarounds
- RECON findings from previous iterations

**Implementation:** Store in project files (CLAUDE.md, memory files, ADR directory). Read at session start.

### Cross-Project Memory

Information that applies across all projects:
- User preferences and workflow patterns
- Common tool configurations
- Reusable templates and snippets
- Lessons learned

**Implementation:** Store in user-level configuration (e.g., `~/.claude/` memory files). Reference when starting any new task.

### Memory Hygiene

- **Prune regularly:** Remove outdated or superseded information
- **Version memory:** Track when information was recorded and last validated
- **Separate facts from opinions:** "Go 1.22 added range over functions" (fact) vs "This approach is better" (opinion, may not age well)
- **Link to sources:** Every memory entry should trace back to evidence

---

## 9. Error Recovery in Agentic Workflows

### Error Classification

| Category | Examples | Recovery Strategy |
|----------|---------|-------------------|
| **Transient** | Network timeout, rate limit, temporary file lock | Retry with exponential backoff |
| **Input error** | Wrong file path, invalid argument, missing dependency | Fix input, retry |
| **Logic error** | Generated code doesn't compile, test fails | Analyze, fix root cause, retry |
| **Spec error** | Requirements are contradictory or incomplete | STOP, escalate to human |
| **Environment error** | Missing tool, wrong version, permission denied | Fix environment or adapt approach |
| **Catastrophic** | Data loss, corrupted state, security breach | STOP immediately, report, do not attempt recovery |

### Recovery Strategies

**Retry with backoff:**
```
Attempt 1: immediate
Attempt 2: wait 1s
Attempt 3: wait 3s
Max retries: 3
After max: escalate
```

**Rollback and retry:**
```
1. Save current state
2. Attempt operation
3. If failure: restore saved state
4. Analyze failure
5. Modify approach
6. Retry from step 1
```

**Graceful degradation:**
```
1. Try optimal approach (e.g., semantic search)
2. If unavailable: fall back to keyword search
3. If unavailable: fall back to manual browsing
4. Always report which approach was used
```

### The Three-Strikes Rule

If an approach fails three times:
1. Do NOT retry a fourth time
2. Step back and reconsider the approach entirely
3. Try a fundamentally different strategy
4. If no alternative works, escalate to the human

---

## 10. Cost Optimization

### Model Routing

Use the right model for each subtask:

| Task | Model Tier | Rationale |
|------|-----------|-----------|
| Architecture decisions | Most capable | High-stakes, needs broad knowledge |
| Code generation | Capable | Needs to write correct, idiomatic code |
| Code review | Capable | Needs to understand nuance and catch subtle bugs |
| Simple edits | Fast | Mechanical changes, low risk |
| File searching | Tools preferred | Don't use a model when a tool (grep, glob) suffices |
| Documentation | Capable | Needs clarity and accuracy |
| Test generation | Capable | Needs to understand edge cases |

### Caching Strategies

- **Cache RECON results:** Intelligence briefs are valid for days, not minutes. Don't re-research the same topic in the same session.
- **Cache file reads:** If you read a file and it hasn't changed, don't re-read it.
- **Cache search results:** Store search results for reuse across subtasks.

### Token Efficiency

- Use structured output (JSON, tables) instead of prose when communicating between agents
- Summarize large inputs before processing
- Strip comments and whitespace from code when only analyzing logic
- Use references ("as defined in ADR-003") instead of repeating information

### When NOT to Optimize

- **Security-critical decisions:** Always use the most capable model
- **User-facing output:** Quality matters more than cost
- **Debugging:** Saving tokens by providing less context leads to worse debugging
- **Specification writing:** The spec is the foundation; skimping here is false economy
