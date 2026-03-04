# RECON Sources: Detailed Research Guide

This reference provides comprehensive guidance for each intelligence source used in the RECON phase of SDD on Steroids. For each source: what it is, how to access it, what to search for, and how to assess the findings.

---

## Freshness Criteria

"Recent" means different things for different purposes:

| Context | Freshness Window | Rationale |
|---------|-----------------|-----------|
| Security advisories | Last 30 days | Vulnerabilities have immediate impact |
| New tools/libraries | Last 6 months | Need time to stabilize but shouldn't be ancient |
| Architectural patterns | Last 12 months | Patterns take time to validate in production |
| Anti-patterns | Last 12 months | Post-mortems often come months after incidents |
| Conference talks | Last 12 months | Conferences happen annually |
| Best practice articles | Last 6 months | Sweet spot between fresh and validated |

---

## Source-by-Source Guide

### 1. Hacker News (news.ycombinator.com)

**What it is:** The premier tech community for experienced developers, founders, and researchers. High signal for emerging tools and thoughtful technical discussion.

**How to search:**
- Front page: `https://news.ycombinator.com/` — current top stories
- Search via Algolia HN API: `https://hn.algolia.com/api/v1/search?query=[topic]&tags=story&numericFilters=created_at_i>[unix_timestamp]`
- Web search: `site:news.ycombinator.com [topic]`
- WebFetch the front page and filter for relevant keywords

**What to look for:**
- Stories with 100+ points — community-validated signal
- "Show HN" posts for new tools directly relevant to the task
- Comment threads where experienced developers share production experience
- "Ask HN" threads about best practices for the technology in question

**API endpoints:**
```
# Search stories from the last 7 days
https://hn.algolia.com/api/v1/search?query=[topic]&tags=story&numericFilters=created_at_i>[timestamp_7_days_ago]

# Top stories (IDs only)
https://hacker-news.firebaseio.com/v0/topstories.json

# Individual story
https://hacker-news.firebaseio.com/v0/item/[id].json
```

**Credibility assessment:** Very high. The voting system and community norms filter out low-quality content effectively. Comments often more valuable than the linked article.

---

### 2. daily.dev

**What it is:** Aggregated developer news feed. Pulls from many sources and uses community curation.

**How to search:**
- Web search: `site:daily.dev [topic] [year]`
- Browse trending: `https://app.daily.dev/`
- Tags and topic filters available on the platform

**What to look for:**
- Trending articles in the relevant language/framework
- Cross-posted articles that appear on multiple platforms (higher signal)
- Articles from recognized authors or companies

**Credibility assessment:** Medium-high. Aggregation means varied quality, but trending/popular filtering helps. Verify claims against other sources.

---

### 3. lobste.rs

**What it is:** Invite-only link aggregation focused on computing. Much higher signal-to-noise ratio than most forums. Community is small but deeply technical.

**How to search:**
- Homepage: `https://lobste.rs/`
- Search: `https://lobste.rs/search?q=[topic]&what=stories&order=relevance`
- Tags: `https://lobste.rs/t/[tag]` (e.g., `/t/go`, `/t/security`, `/t/devops`)
- Web search: `site:lobste.rs [topic]`

**What to look for:**
- Anything with 20+ votes is exceptional for this community
- Tag-filtered results for the specific technology
- Discussion threads — the commentary is often more insightful than the linked content

**Credibility assessment:** Very high. Invite-only community with strong technical depth. One of the most reliable sources for genuine technical insight.

---

### 4. Reddit

**What it is:** Massive forum platform with topic-specific subreddits. Quality varies dramatically by subreddit.

**Relevant subreddits:**
- `r/programming` — General programming discussion
- `r/golang` — Go-specific
- `r/webdev` — Web development
- `r/devops` — DevOps and infrastructure
- `r/ExperiencedDevs` — Senior developer perspectives (highest quality)
- `r/netsec` — Security
- `r/MachineLearning` — ML/AI research
- `r/LocalLLaMA` — Local LLM deployment and optimization

**How to search:**
- Web search: `site:reddit.com/r/[subreddit] [topic] [year]`
- Sort by top/week or top/month for recent validated content
- Reddit search: `https://www.reddit.com/r/[subreddit]/search/?q=[topic]&sort=top&t=month`

**What to look for:**
- Posts with high upvotes AND substantial comment discussion
- "War stories" — real production experience reports
- "What have you switched to?" or "What are you using for X?" threads
- Threads where multiple people confirm the same experience

**Credibility assessment:** Varies. r/ExperiencedDevs and r/netsec are high quality. r/programming can be noisy. Always check comment quality, not just upvotes. Beware of hype cycles.

---

### 5. Dev.to and Hashnode

**What it is:** Developer blogging platforms. Wide range of authors from beginners to staff engineers at major companies.

**How to search:**
- Dev.to: `https://dev.to/search?q=[topic]` or web search `site:dev.to [topic] [year]`
- Hashnode: web search `site:hashnode.dev [topic] [year]`
- Filter for recent posts (last 6 months)

**What to look for:**
- Posts by verified staff engineers at known companies
- Tutorial-style posts with working code examples
- Posts that reference benchmarks or production metrics
- Series posts that go deep on a topic

**Credibility assessment:** Medium. Wide range of quality. Check the author's profile — years of experience, company, other posts. Beginner tutorials may contain anti-patterns. Cross-reference claims with other sources.

---

### 6. GitHub Trending

**What it is:** GitHub's view of repositories gaining stars rapidly. The best early signal for new tools and libraries.

**How to search:**
- Trending repos: `https://github.com/trending/[language]?since=weekly`
- Search API: `https://api.github.com/search/repositories?q=[topic]+language:[lang]&sort=stars&order=desc`
- Via `gh` CLI: `gh search repos "[topic]" --language=[lang] --sort=stars --limit=10`

**What to look for:**
- Repos gaining stars rapidly (trending) in the relevant language
- README quality — well-documented repos with clear problem statements
- Issue/PR activity — active maintenance vs abandoned
- Star count vs age — a 6-month-old repo with 5K stars is more signal than a 5-year-old repo with 5K stars
- Used-by count and dependents — actual adoption

**API for deeper analysis:**
```bash
# Search for repos
gh api search/repositories -f q="[topic] language:[lang]" -f sort=stars -f per_page=10

# Check repo details
gh api repos/[owner]/[repo]

# Check recent releases
gh api repos/[owner]/[repo]/releases --jq '.[0:3] | .[].tag_name'
```

**Credibility assessment:** High for adoption signals. Star count is a proxy for interest, not quality. Check issues, documentation, and actual usage before recommending adoption.

---

### 7. Changelog.com and TLDR Newsletter

**What it is:** Curated tech news. Changelog covers podcasts, newsletters, and community news. TLDR is a daily tech newsletter.

**How to search:**
- Changelog: `https://changelog.com/search?q=[topic]`
- TLDR archives: web search `site:tldr.tech [topic]`
- Changelog podcasts: search for episode topics on the specific technology

**What to look for:**
- Interview episodes with tool/library creators
- "State of [technology]" episodes
- Weekly news roundups mentioning the relevant stack

**Credibility assessment:** High. Professionally curated content. Editors filter for significance.

---

### 8. X/Twitter

**What it is:** Real-time developer commentary. Often where production insights first surface before becoming blog posts.

**How to search:**
- Web search: `site:x.com [topic] "best practice"` or `site:twitter.com [topic] "TIL"`
- Search queries: `[topic] (best practice OR "game changer" OR TIL OR "just discovered" OR "switched from" OR "switched to")`
- Follow-up: check the author's profile for credibility

**What to look for:**
- Threads by recognized developers sharing production experience
- "I switched from X to Y because..." posts
- Performance comparison screenshots with real numbers
- Tips and tricks from maintainers of popular projects

**Credibility assessment:** Highly variable. Verify the author's credentials. Anecdotal evidence is common. Best used as a signal to investigate further, not as definitive evidence.

---

### 9. YouTube (Conference Talks)

**What it is:** Recorded conference presentations. Some of the deepest technical content available.

**Key conferences by domain:**
- **Go:** GopherCon, GopherCon EU, GoLab
- **Infrastructure:** KubeCon, HashiConf, FOSDEM
- **General:** Strange Loop, QCon, NDC, GOTO
- **Security:** DEF CON, Black Hat, BSides
- **AI/ML:** NeurIPS, ICML, PyTorch Conference
- **Web:** React Conf, ViteConf, JSConf

**How to search:**
- Web search: `site:youtube.com [conference] [topic] [year]`
- YouTube search with date filter: "Last year" or "This year"

**What to look for:**
- Talks by practitioners (not vendor pitches)
- Post-mortems and war stories
- "Lessons learned" talks
- Talks with high view counts relative to the conference channel average

**Credibility assessment:** Generally high. Conference talk proposals are reviewed. Speakers usually have real-world experience. Watch for vendor-sponsored talks that are thinly disguised sales pitches.

---

### 10. ArXiv and Research Papers

**What it is:** Preprint server for academic research. Essential for AI/ML tasks, occasionally relevant for systems and algorithms.

**How to search:**
- ArXiv search: `https://arxiv.org/search/?query=[topic]&searchtype=all`
- Semantic Scholar: `https://api.semanticscholar.org/graph/v1/paper/search?query=[topic]&limit=10&sort=citationCount:desc`
- Papers With Code: `https://paperswithcode.com/search?q=[topic]` — links papers to implementations

**What to look for:**
- Papers with accompanying code (more actionable)
- Citation count relative to age (rapidly cited = high impact)
- Papers from known research labs (Google, Meta, DeepMind, OpenAI, Anthropic)
- Survey/overview papers for getting up to speed on a domain

**Credibility assessment:** Varies. ArXiv is not peer-reviewed. Check citation count, author reputation, and whether results have been reproduced. Papers With Code implementations add credibility.

---

## Search Query Templates

### By Domain

```
# Web Backend
"[language] API design patterns [year]"
"[framework] production best practices"
"[language] microservices [year]"
"[language] error handling patterns [year]"
"REST vs GraphQL vs gRPC [year]"

# Frontend
"[framework] state management [year]"
"web performance optimization [year]"
"[framework] server components"
"accessibility best practices [year]"
"htmx [language] [year]"

# Infrastructure
"platform engineering [year]"
"kubernetes alternatives [year]"
"infrastructure as code [year]"
"observability [year] best practices"
"deployment strategy [year]"

# AI/ML
"LLM integration patterns [year]"
"RAG architecture [year]"
"agentic coding workflow [year]"
"AI code review [year]"
"prompt engineering [year]"
"MCP server [year]"

# Security
"OWASP top 10 [year]"
"supply chain security [year]"
"[language] security best practices"
"dependency scanning [year]"
"secrets management [year]"

# Testing
"[language] testing best practices [year]"
"mutation testing [language]"
"property-based testing [year]"
"testing in production [year]"
"contract testing [year]"

# Database
"[database] performance tuning [year]"
"vector database comparison [year]"
"database migration patterns"
"[database] scaling [year]"
```

### Generic Patterns

```
# Find anti-patterns
"[topic] antipattern" OR "[topic] mistakes" OR "[topic] pitfalls"

# Find production experience
"[topic] in production" OR "[topic] at scale" OR "[topic] war story"

# Find comparisons
"[tool A] vs [tool B] [year]" OR "[tool A] alternative [year]"

# Find emerging trends
"[topic] trends [year]" OR "future of [topic]" OR "[topic] roadmap [year]"
```

---

## Credibility Assessment Framework

When evaluating any source, score on these dimensions:

| Dimension | High | Medium | Low |
|-----------|------|--------|-----|
| **Author credibility** | Known expert, maintainer, or researcher | Experienced developer with track record | Anonymous or new author |
| **Evidence quality** | Benchmarks, metrics, reproducible | Code examples, case studies | Opinions, claims without evidence |
| **Community validation** | Widely discussed, independently confirmed | Some discussion, generally positive | Unconfirmed, single source |
| **Recency** | Within freshness window for the category | Slightly outside window but still relevant | Outdated |
| **Conflict of interest** | Independent analysis | Minor affiliation | Vendor marketing, paid promotion |

**Minimum threshold for inclusion in RECON brief:** At least MEDIUM on 3 of 5 dimensions, and no LOW on author credibility or evidence quality.
