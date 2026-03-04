# Specification Templates

Ready-to-use templates for every document produced during the SDD on Steroids workflow. Copy and fill in the bracketed sections.

---

## 1. RECON Brief Template

```markdown
# RECON BRIEF: [Task/Project Name]

**Date:** [YYYY-MM-DD]
**Analyst:** [agent or human name]
**Task context:** [1-2 sentence description of the development task]
**Time spent on RECON:** [minutes]

## Sources Consulted

| Source | Queries Used | Findings |
|--------|-------------|----------|
| Hacker News | [queries] | [count] relevant |
| GitHub Trending | [queries] | [count] relevant |
| Reddit ([subreddits]) | [queries] | [count] relevant |
| [other sources] | [queries] | [count] relevant |

## Emerging Practices (Directly Relevant)

### [Finding 1 Title]
- **Source:** [URL or reference]
- **Summary:** [What was discovered]
- **Maturity:** [Bleeding edge / Early adopter / Mainstream]
- **Community validation:** [stars, upvotes, adoption metrics]
- **Recommendation:** [ADOPT / EVALUATE / WATCH / IGNORE]
- **Rationale:** [Why this recommendation]

### [Finding 2 Title]
[Same structure...]

## New Tools & Libraries

| Tool/Library | Problem It Solves | Stars/Adoption | Maturity | Recommend |
|-------------|-------------------|----------------|----------|-----------|
| [name] | [problem] | [metrics] | [maturity] | [action] |
| [name] | [problem] | [metrics] | [maturity] | [action] |

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Problematic | Source | Impact |
|-------------|---------------------|--------|--------|
| [pattern] | [explanation] | [source] | [HIGH/MEDIUM/LOW] |
| [pattern] | [explanation] | [source] | [HIGH/MEDIUM/LOW] |

## Security Advisories

| Advisory | Affected Components | Impact | Action Required |
|----------|-------------------|--------|-----------------|
| [advisory] | [components] | [severity] | [action] |

## Overall Assessment

**Confidence:** [HIGH / MEDIUM / LOW]
- HIGH = multiple corroborating sources, production-validated findings
- MEDIUM = some corroboration, mostly early-adopter stage
- LOW = limited sources, bleeding edge, exercise caution

**Action Summary:**
- **ADOPT** (ready for immediate use): [list]
- **EVALUATE** (worth prototyping/testing): [list]
- **WATCH** (monitor but don't act yet): [list]
- **IGNORE** (not relevant enough): [list]

## Impact on Specification

[How these findings should influence the specification. What design decisions are affected? What alternatives should be considered?]
```

---

## 2. Feature Specification Template

```markdown
# Specification: [Feature/Project Name]

**Version:** [1.0 / draft]
**Date:** [YYYY-MM-DD]
**Author:** [name]
**Status:** [Draft / Under Review / Approved / Superseded]
**RECON Brief:** [link or inline reference]

---

## 1. Context & RECON Findings

### Background
[Why this feature/project exists. What problem does it solve?]

### RECON Summary
[Key findings from the RECON phase that influence this specification:
- Emerging practices adopted
- New tools/libraries chosen
- Anti-patterns being avoided
- Security considerations surfaced]

### Assumptions
[What assumptions are we making? What could invalidate them?]

---

## 2. Requirements

### 2.1 Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|------------|----------|-------------------|
| FR-001 | [requirement] | [MUST/SHOULD/COULD] | [testable criteria] |
| FR-002 | [requirement] | [MUST/SHOULD/COULD] | [testable criteria] |

### 2.2 Non-Functional Requirements

| ID | Requirement | Target | Measurement |
|----|------------|--------|-------------|
| NFR-001 | Latency | P99 < [X]ms | [how to measure] |
| NFR-002 | Throughput | [X] RPS | [how to measure] |
| NFR-003 | Availability | [X]% uptime | [how to measure] |
| NFR-004 | [other] | [target] | [measurement] |

---

## 3. Architecture Decision Records (ADRs)

### ADR-001: [Decision Title]

**Status:** Accepted
**Date:** [YYYY-MM-DD]

**Context:**
[What is the issue? What forces are at play? Include RECON evidence.]

**Decision:**
[What was decided]

**Alternatives Considered:**
1. [Alternative 1] — rejected because [reason]
2. [Alternative 2] — rejected because [reason]

**Consequences:**
- Positive: [benefits]
- Negative: [tradeoffs]
- Risks: [risks and mitigations]

**Evidence:**
[Links to RECON findings, benchmarks, case studies that support this decision]

---

## 4. Technology Stack

| Component | Technology | Version | Justification |
|-----------|-----------|---------|---------------|
| Language | [lang] | [ver] | [why, with RECON evidence] |
| Framework | [framework] | [ver] | [why, with RECON evidence] |
| Database | [db] | [ver] | [why, with RECON evidence] |
| [other] | [tech] | [ver] | [why, with RECON evidence] |

### Known Risks
[Technology-specific risks identified during RECON, with mitigation strategies]

---

## 5. API/Interface Design

### Endpoints / Functions / Interfaces

[Define the public contract. Use OpenAPI, protobuf, Go interfaces, or whatever is appropriate.]

```
[API definition here]
```

### Data Models

```
[Schema definitions]
```

### Error Handling

| Error Code | Condition | Response |
|-----------|-----------|----------|
| [code] | [when] | [what happens] |

---

## 6. Test Strategy

### Unit Tests
[What to test, coverage targets, mocking strategy]

### Integration Tests
[Component integration points, test environment requirements]

### E2E Tests
[User-facing scenarios, test data management]

### Performance Tests
[Benchmark definitions, load test scenarios, targets from NFRs]

### Security Tests
[SAST/DAST tools, penetration testing scope, dependency scanning]

**Testing insights from RECON:**
[Any new testing approaches or tools discovered during research]

---

## 7. Security Considerations

[From RECON advisories + standard threat modeling]

### Threat Model
[STRIDE or equivalent analysis]

### Mitigations
| Threat | Mitigation | Implementation |
|--------|-----------|----------------|
| [threat] | [mitigation] | [how] |

### Dependencies
[Known vulnerabilities in dependencies, update strategy]

---

## 8. Implementation Plan

### Phase 1: [Name]
- **Scope:** [what's included]
- **Dependencies:** [what must be done first]
- **Deliverables:** [concrete outputs]
- **Checkpoint criteria:** [how to verify this phase is done]
- **Estimated effort:** [time estimate]

### Phase 2: [Name]
[Same structure...]

### Phase N: [Name]
[Same structure...]

---

## 9. Open Questions

| # | Question | Owner | Deadline | Resolution |
|---|----------|-------|----------|------------|
| 1 | [question] | [who] | [when] | [resolved?] |

---

## 10. Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | [date] | Initial specification |
```

---

## 3. API Design Specification Template

```markdown
# API Design Specification: [API Name]

**Version:** [API version, e.g., v1]
**Date:** [YYYY-MM-DD]
**Status:** [Draft / Approved / Deprecated]

## Overview
[What this API does, who consumes it, key design principles]

## Base URL
```
[protocol]://[host]:[port]/[base-path]
```

## Authentication
[Auth mechanism: API key, OAuth2, JWT, mTLS]

## Common Headers
| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | [auth scheme] |
| `Content-Type` | Yes | `application/json` |
| `X-Request-ID` | Recommended | Correlation ID for tracing |

## Endpoints

### [METHOD] [path]

**Description:** [what it does]
**Auth required:** [yes/no]
**Rate limit:** [requests/window]

**Request:**
```json
{
  "field": "type — description"
}
```

**Response (200):**
```json
{
  "field": "type — description"
}
```

**Error Responses:**
| Status | Code | Description |
|--------|------|-------------|
| 400 | INVALID_REQUEST | [when] |
| 404 | NOT_FOUND | [when] |
| 500 | INTERNAL_ERROR | [when] |

[Repeat for each endpoint...]

## Pagination
[Cursor-based, offset-based, or keyset. Include examples.]

## Rate Limiting
[Limits, headers, retry strategy]

## Versioning Strategy
[URL versioning, header versioning, or both. Migration policy.]

## Webhooks (if applicable)
[Event types, payload format, retry policy, signature verification]
```

---

## 4. Architecture Decision Record (ADR) Template

```markdown
# ADR-[NNN]: [Decision Title]

**Status:** [Proposed / Accepted / Deprecated / Superseded by ADR-XXX]
**Date:** [YYYY-MM-DD]
**Deciders:** [who was involved]

## Context

[What is the issue that we're seeing that is motivating this decision or change?
Include relevant RECON findings that informed the decision.]

## Decision

[What is the change that we're proposing and/or doing?]

## Alternatives Considered

### Option A: [Name]
- **Pros:** [list]
- **Cons:** [list]
- **RECON evidence:** [what research said about this option]

### Option B: [Name]
[Same structure...]

## Consequences

### Positive
[What becomes easier or possible as a result of this change?]

### Negative
[What becomes harder or is lost as a result of this change?]

### Risks
[What could go wrong? How do we mitigate?]

## Evidence & References
- [RECON finding 1: URL]
- [RECON finding 2: URL]
- [Benchmark results]
- [Related ADRs]
```

---

## 5. Retrospective Template

```markdown
# Retrospective: [Task/Project Name]

**Date:** [YYYY-MM-DD]
**Participants:** [who]
**Spec version used:** [version]

## Summary
[1-2 sentence summary of what was built]

## RECON Effectiveness

### Findings That Were Useful
| Finding | How It Helped | Impact |
|---------|--------------|--------|
| [finding] | [how it influenced the implementation] | [HIGH/MEDIUM/LOW] |

### Findings That Were Noise
| Finding | Why It Wasn't Useful | Lesson |
|---------|---------------------|--------|
| [finding] | [why it didn't apply] | [what to search differently] |

### Things We Wish We Had Found
| Gap | What We Needed | Where It Might Have Been |
|-----|---------------|------------------------|
| [gap] | [what info was missing] | [source to try next time] |

## Spec Quality

### What the Spec Got Right
[Areas where the spec accurately predicted implementation needs]

### Where the Spec Was Wrong
[Areas where implementation diverged from spec, and why]

### Spec Improvements for Next Time
[How to write better specs based on this experience]

## Implementation Notes

### What Went Well
- [item]

### What Was Difficult
- [item]

### Technical Debt Created
| Debt | Severity | Remediation Plan |
|------|----------|-----------------|
| [debt] | [HIGH/MEDIUM/LOW] | [plan] |

## Metrics

| Metric | Target (from spec) | Actual | Status |
|--------|-------------------|--------|--------|
| [metric] | [target] | [actual] | [met/unmet] |

## Action Items for Future RECON
[What to search for, watch, or investigate in future iterations]
```

---

## 6. Technology Evaluation Matrix Template

```markdown
# Technology Evaluation: [Category]

**Date:** [YYYY-MM-DD]
**Context:** [What problem we're solving, what role this technology fills]
**RECON findings:** [Summary of what research surfaced]

## Candidates

| Criterion | Weight | [Option A] | [Option B] | [Option C] |
|-----------|--------|-----------|-----------|-----------|
| **Functional fit** | 25% | [score 1-5] | [score 1-5] | [score 1-5] |
| **Performance** | 20% | [score 1-5] | [score 1-5] | [score 1-5] |
| **Community/ecosystem** | 15% | [score 1-5] | [score 1-5] | [score 1-5] |
| **Learning curve** | 10% | [score 1-5] | [score 1-5] | [score 1-5] |
| **Maintenance/longevity** | 15% | [score 1-5] | [score 1-5] | [score 1-5] |
| **Security track record** | 10% | [score 1-5] | [score 1-5] | [score 1-5] |
| **License compatibility** | 5% | [score 1-5] | [score 1-5] | [score 1-5] |
| **Weighted total** | 100% | [total] | [total] | [total] |

## Detailed Assessment

### [Option A]
- **Strengths:** [list]
- **Weaknesses:** [list]
- **RECON evidence:** [what research says]
- **Production references:** [who's using it, at what scale]
- **Risk factors:** [list]

### [Option B]
[Same structure...]

## Recommendation

**Selected:** [Option]
**Rationale:** [Why, referencing scores and RECON evidence]
**Risks and mitigations:** [What could go wrong with this choice]
**Fallback plan:** [What to do if this choice doesn't work out]
```
