#!/usr/bin/env python3
"""
Skill Master MCP Server

Exposes tools for skill discovery, recommendation, usage analysis,
health checking, and evolution proposals via the Model Context Protocol.

Runs as a stdio MCP server (launched by Claude Code via .mcp.json).
"""

import json
import os
import sys
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
from collections import Counter, defaultdict

# MCP protocol constants
JSONRPC = "2.0"

# Paths
PLUGIN_ROOT = os.environ.get("CLAUDE_PLUGIN_ROOT", str(Path(__file__).parent.parent))
USAGE_LOG = os.environ.get(
    "SKILL_MASTER_USAGE_LOG",
    os.path.expanduser("~/.claude/skill-master-usage.jsonl")
)
PLUGINS_DIR = os.path.join(PLUGIN_ROOT, "..", "..")  # marketplace/plugins/
MARKETPLACE_JSON = os.path.join(PLUGIN_ROOT, "..", "..", ".claude-plugin", "marketplace.json")


def read_jsonl(path, period_days=90):
    """Read JSONL usage log, filtering by period."""
    events = []
    cutoff = datetime.now() - timedelta(days=period_days)
    if not Path(path).exists():
        return events
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
                ts = datetime.fromisoformat(ev.get("ts", "2000-01-01"))
                if ts >= cutoff:
                    events.append(ev)
            except (json.JSONDecodeError, ValueError):
                continue
    return events


def load_marketplace():
    """Load marketplace.json if available."""
    path = MARKETPLACE_JSON
    if not Path(path).exists():
        # Try alternative paths
        for candidate in [
            os.path.expanduser("~/.claude/plugins/cache/biodoia-skills-marketplace/.claude-plugin/marketplace.json"),
            os.path.join(PLUGIN_ROOT, "..", "..", "marketplace.json"),
        ]:
            if Path(candidate).exists():
                path = candidate
                break
    if not Path(path).exists():
        return {"plugins": []}
    with open(path) as f:
        return json.load(f)


def scan_installed_skills():
    """Scan all installed plugins for skills."""
    skills = []
    cache_dir = Path.home() / ".claude" / "plugins" / "cache"
    if not cache_dir.exists():
        return skills

    for plugin_dir in cache_dir.iterdir():
        if not plugin_dir.is_dir():
            continue
        skills_dir = plugin_dir / "skills"
        if not skills_dir.exists():
            continue
        for skill_dir in skills_dir.iterdir():
            skill_md = skill_dir / "SKILL.md"
            if skill_md.exists():
                name, description = parse_skill_frontmatter(skill_md)
                skills.append({
                    "plugin": plugin_dir.name,
                    "skill": name or skill_dir.name,
                    "description": description or "",
                    "path": str(skill_dir),
                    "has_references": (skill_dir / "references").is_dir(),
                    "has_scripts": (skill_dir / "scripts").is_dir(),
                })
    return skills


def parse_skill_frontmatter(path):
    """Extract name and description from SKILL.md YAML frontmatter."""
    name = None
    description = None
    try:
        with open(path) as f:
            content = f.read()
        if not content.startswith("---"):
            return name, description
        end = content.index("---", 3)
        frontmatter = content[3:end]
        for line in frontmatter.split("\n"):
            if line.startswith("name:"):
                name = line[5:].strip().strip('"').strip("'")
            elif line.startswith("description:"):
                description = line[12:].strip().strip('"').strip("'")
    except (ValueError, OSError):
        pass
    return name, description


def detect_project_signals(project_path):
    """Detect technology signals in a project directory."""
    signals = []
    p = Path(project_path)
    if not p.exists():
        return signals

    checks = [
        ("go.mod", "go"), ("go.sum", "go"),
        ("package.json", "nodejs"), ("tsconfig.json", "typescript"),
        ("Cargo.toml", "rust"), ("pyproject.toml", "python"), ("setup.py", "python"),
        ("Dockerfile", "docker"), ("docker-compose.yml", "docker"), ("compose.yaml", "docker"),
        (".claude-plugin", "claude-plugin"), ("plugin.json", "claude-plugin"),
        (".mcp.json", "mcp"), ("mcp.json", "mcp"),
        ("CLAUDE.md", "claude-md"),
        ("buf.yaml", "grpc"), ("proto", "grpc"),
        ("Makefile", "make"), ("justfile", "just"),
        (".github", "github-actions"),
    ]
    for filename, signal in checks:
        if (p / filename).exists():
            signals.append(signal)

    # Deep checks
    if "go" in signals:
        go_mod = p / "go.mod"
        if go_mod.exists():
            content = go_mod.read_text()
            if "framegotui" in content:
                signals.append("framegotui")
            if "google.golang.org/grpc" in content:
                signals.append("grpc")

    # Tailscale
    if any((p / f).exists() for f in ["tailscale.json", ".tailscale"]):
        signals.append("tailscale")

    # Web UI
    if any((p / d).exists() for d in ["web", "pkg/web", "frontend", "src/web"]):
        signals.append("web-ui")

    return list(set(signals))


# --- MCP Tool Handlers ---

def handle_search_skills(params):
    """Search all available skills by keyword."""
    query = params.get("query", "").lower()
    skills = scan_installed_skills()

    if not query:
        return {"skills": skills, "total": len(skills)}

    matched = []
    for s in skills:
        score = 0
        if query in s["skill"].lower():
            score += 10
        if query in s["description"].lower():
            score += 5
        if query in s["plugin"].lower():
            score += 3
        if score > 0:
            s["relevance"] = score
            matched.append(s)

    matched.sort(key=lambda x: -x.get("relevance", 0))
    return {"skills": matched, "total": len(matched), "query": query}


def handle_recommend_stack(params):
    """Recommend a skill stack for a project."""
    project_path = params.get("path", os.getcwd())
    signals = detect_project_signals(project_path)
    skills = scan_installed_skills()

    # Signal → skill mapping
    signal_map = {
        "go": ["superpowers:test-driven-development", "superpowers:brainstorming"],
        "framegotui": ["framegotui-sdk"],
        "nodejs": ["frontend-design"],
        "typescript": ["frontend-design"],
        "docker": ["superpowers:writing-plans"],
        "claude-plugin": ["marketplace-creator", "plugin-dev:skill-development", "plugin-dev:plugin-structure"],
        "grpc": ["grpc-patterns"],
        "mcp": ["plugin-dev:mcp-integration"],
        "claude-md": ["claude-md-management:claude-md-improver"],
        "tailscale": ["tailscale-expert"],
        "web-ui": ["frontend-design"],
    }

    recommended = {}
    for signal in signals:
        for skill in signal_map.get(signal, []):
            if skill not in recommended:
                recommended[skill] = {"skill": skill, "signals": [], "confidence": "recommended"}
            recommended[skill]["signals"].append(signal)

    # Boost based on usage history
    events = read_jsonl(USAGE_LOG, 90)
    project_name = Path(project_path).name
    project_usage = [e for e in events if e.get("project") == project_name and e.get("event") == "skill_used"]
    usage_counts = Counter(e.get("skill", "") for e in project_usage)

    for skill, count in usage_counts.most_common():
        if skill in recommended:
            recommended[skill]["confidence"] = "critical"
            recommended[skill]["usage_count"] = count
        elif count >= 2:
            recommended[skill] = {
                "skill": skill,
                "signals": ["usage-history"],
                "confidence": "recommended",
                "usage_count": count,
            }

    return {
        "project": project_path,
        "signals": signals,
        "recommendations": list(recommended.values()),
        "total": len(recommended),
    }


def handle_analyze_usage(params):
    """Analyze usage patterns and propose improvements."""
    period = params.get("period", 90)
    events = read_jsonl(USAGE_LOG, period)

    if not events:
        return {"error": "no_data", "message": f"No usage data found at {USAGE_LOG}"}

    sessions = [e for e in events if e.get("event") == "session_start"]
    usages = [e for e in events if e.get("event") == "skill_used"]

    skill_counts = Counter(e.get("skill", "unknown") for e in usages)

    # Trigger rates
    recommended_skills = Counter()
    for s in sessions:
        for skill in s.get("recommended", "").split():
            if skill:
                recommended_skills[skill] += 1

    trigger_rates = {}
    for skill, rec_count in recommended_skills.items():
        used_count = skill_counts.get(skill, 0)
        trigger_rates[skill] = round(used_count / rec_count, 3) if rec_count > 0 else 0

    # Organic
    organic = Counter()
    for e in usages:
        skill = e.get("skill", "")
        if skill and skill not in recommended_skills:
            organic[skill] += 1

    # Co-occurrence
    project_skills = defaultdict(list)
    for e in usages:
        project_skills[e.get("project", "unknown")].append(e.get("skill"))

    co_occur = defaultdict(int)
    for proj, skills in project_skills.items():
        unique = list(set(skills))
        for i, a in enumerate(unique):
            for b in unique[i + 1:]:
                pair = tuple(sorted([a, b]))
                co_occur[pair] += 1

    # Proposals
    proposals = []
    for skill, count in organic.most_common():
        if count >= 3:
            proposals.append({
                "type": "signal_expansion",
                "skill": skill,
                "message": f"High organic rate ({count} uses without recommendation) — add signal mapping",
            })

    for skill, rate in trigger_rates.items():
        if rate < 0.05 and recommended_skills.get(skill, 0) >= 5:
            proposals.append({
                "type": "signal_contraction",
                "skill": skill,
                "message": f"Low trigger rate ({rate:.0%}) — narrow or remove signal",
            })

    top_co = sorted(co_occur.items(), key=lambda x: -x[1])[:10]
    for (a, b), count in top_co:
        if count >= 3:
            proposals.append({
                "type": "combination",
                "skills": [a, b],
                "count": count,
                "message": f"Co-occurrence {count} times — consider stack template",
            })

    return {
        "period_days": period,
        "total_sessions": len(sessions),
        "total_usages": len(usages),
        "top_skills": dict(skill_counts.most_common(20)),
        "trigger_rates": trigger_rates,
        "organic_skills": dict(organic.most_common(10)),
        "top_co_occurrences": [{"pair": list(p), "count": c} for p, c in top_co[:10]],
        "proposals": proposals,
    }


def handle_skill_health(params):
    """Check quality scores for all installed skills."""
    skills = scan_installed_skills()
    health = []

    for s in skills:
        score = 0
        issues = []

        # Description quality
        desc = s.get("description", "")
        if desc.startswith("Use when"):
            score += 30
        elif desc.lower().startswith("use "):
            score += 20
        else:
            issues.append("description should start with 'Use when...'")
            score += 5

        if len(desc) > 50:
            score += 10
        else:
            issues.append("description too short (<50 chars)")

        if len(desc) > 500:
            issues.append("description too long (>500 chars)")
        else:
            score += 10

        # Structure quality
        if s.get("has_references"):
            score += 20
        if s.get("has_scripts"):
            score += 10

        # Skill body exists and has content
        skill_md = Path(s["path"]) / "SKILL.md"
        if skill_md.exists():
            content = skill_md.read_text()
            word_count = len(content.split())
            if word_count > 200:
                score += 20
            elif word_count > 50:
                score += 10
                issues.append(f"skill body light ({word_count} words)")
            else:
                issues.append(f"skill body very light ({word_count} words)")

        grade = "A" if score >= 80 else "B" if score >= 60 else "C" if score >= 40 else "D"
        health.append({
            "plugin": s["plugin"],
            "skill": s["skill"],
            "score": score,
            "grade": grade,
            "issues": issues,
        })

    health.sort(key=lambda x: -x["score"])
    avg_score = sum(h["score"] for h in health) / max(len(health), 1)
    return {
        "skills": health,
        "total": len(health),
        "average_score": round(avg_score, 1),
        "grade_distribution": dict(Counter(h["grade"] for h in health)),
    }


def handle_propose_evolution(params):
    """Generate a specific improvement proposal for a skill."""
    skill_name = params.get("skill", "")
    if not skill_name:
        return {"error": "missing_param", "message": "skill parameter required"}

    # Find the skill
    skills = scan_installed_skills()
    target = None
    for s in skills:
        if s["skill"] == skill_name or skill_name in s["skill"]:
            target = s
            break

    if not target:
        return {"error": "not_found", "message": f"Skill '{skill_name}' not found"}

    # Analyze usage for this skill
    events = read_jsonl(USAGE_LOG, 90)
    usages = [e for e in events if e.get("skill") == skill_name]
    sessions = [e for e in events if e.get("event") == "session_start"]

    # Count recommendations
    rec_count = 0
    for s in sessions:
        if skill_name in s.get("recommended", ""):
            rec_count += 1

    use_count = len(usages)
    trigger_rate = use_count / rec_count if rec_count > 0 else None

    proposals = []

    # Check trigger rate
    if trigger_rate is not None:
        if trigger_rate < 0.05 and rec_count >= 5:
            proposals.append({
                "type": "signal_contraction",
                "message": f"Low trigger rate ({trigger_rate:.0%} of {rec_count} recommendations). Consider narrowing the signal mapping.",
            })
        elif trigger_rate > 0.5:
            proposals.append({
                "type": "healthy",
                "message": f"Good trigger rate ({trigger_rate:.0%}). Signal mapping is effective.",
            })

    # Check organic usage
    organic_count = 0
    for e in events:
        if e.get("event") == "skill_used" and e.get("skill") == skill_name:
            # Check if any session recommended this skill
            organic_count += 1

    if rec_count == 0 and use_count > 0:
        proposals.append({
            "type": "signal_expansion",
            "message": f"Used {use_count} times but never recommended. Add signal mapping to SessionStart hook.",
        })

    # Description check
    desc = target.get("description", "")
    if not desc.startswith("Use when"):
        proposals.append({
            "type": "description_tuning",
            "message": "Description should start with 'Use when...' for optimal triggering.",
            "current": desc[:100],
        })

    return {
        "skill": skill_name,
        "plugin": target["plugin"],
        "usage_count": use_count,
        "recommendation_count": rec_count,
        "trigger_rate": trigger_rate,
        "proposals": proposals,
    }


# --- MCP Protocol Handler ---

TOOLS = [
    {
        "name": "search_skills",
        "description": "Search all available skills by keyword or domain. Returns matching skills with relevance scores.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Search keyword (empty = list all)",
                }
            },
        },
    },
    {
        "name": "recommend_stack",
        "description": "Recommend a skill stack for a project based on detected signals and usage history.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Project directory path (default: current directory)",
                }
            },
        },
    },
    {
        "name": "analyze_usage",
        "description": "Analyze skill usage patterns from the usage log and propose improvements.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "period": {
                    "type": "integer",
                    "description": "Analysis period in days (default: 90)",
                    "default": 90,
                }
            },
        },
    },
    {
        "name": "skill_health",
        "description": "Check quality scores for all installed skills. Returns grades (A-D) and issues.",
        "inputSchema": {
            "type": "object",
            "properties": {},
        },
    },
    {
        "name": "propose_evolution",
        "description": "Generate a specific improvement proposal for a skill based on usage data.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "skill": {
                    "type": "string",
                    "description": "Skill name to analyze",
                }
            },
            "required": ["skill"],
        },
    },
]

TOOL_HANDLERS = {
    "search_skills": handle_search_skills,
    "recommend_stack": handle_recommend_stack,
    "analyze_usage": handle_analyze_usage,
    "skill_health": handle_skill_health,
    "propose_evolution": handle_propose_evolution,
}


def send_response(id, result):
    """Send a JSON-RPC response."""
    msg = json.dumps({"jsonrpc": JSONRPC, "id": id, "result": result})
    sys.stdout.write(f"Content-Length: {len(msg)}\r\n\r\n{msg}")
    sys.stdout.flush()


def send_error(id, code, message):
    """Send a JSON-RPC error response."""
    msg = json.dumps({
        "jsonrpc": JSONRPC,
        "id": id,
        "error": {"code": code, "message": message},
    })
    sys.stdout.write(f"Content-Length: {len(msg)}\r\n\r\n{msg}")
    sys.stdout.flush()


def handle_request(req):
    """Handle a single JSON-RPC request."""
    method = req.get("method", "")
    id = req.get("id")
    params = req.get("params", {})

    if method == "initialize":
        send_response(id, {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": "skill-master", "version": "0.1.0"},
        })
    elif method == "notifications/initialized":
        pass  # No response needed
    elif method == "tools/list":
        send_response(id, {"tools": TOOLS})
    elif method == "tools/call":
        tool_name = params.get("name", "")
        tool_args = params.get("arguments", {})
        handler = TOOL_HANDLERS.get(tool_name)
        if handler:
            try:
                result = handler(tool_args)
                send_response(id, {
                    "content": [{"type": "text", "text": json.dumps(result, indent=2)}],
                })
            except Exception as e:
                send_response(id, {
                    "content": [{"type": "text", "text": json.dumps({"error": str(e)})}],
                    "isError": True,
                })
        else:
            send_error(id, -32601, f"Unknown tool: {tool_name}")
    elif method == "ping":
        send_response(id, {})
    else:
        if id is not None:
            send_error(id, -32601, f"Method not found: {method}")


def main():
    """Main loop: read JSON-RPC messages from stdin."""
    buf = ""
    while True:
        try:
            # Read headers
            content_length = 0
            while True:
                line = sys.stdin.readline()
                if not line:
                    return  # EOF
                line = line.strip()
                if not line:
                    break
                if line.lower().startswith("content-length:"):
                    content_length = int(line.split(":")[1].strip())

            if content_length == 0:
                continue

            # Read body
            body = sys.stdin.read(content_length)
            if not body:
                return

            req = json.loads(body)
            handle_request(req)

        except json.JSONDecodeError:
            continue
        except KeyboardInterrupt:
            return
        except Exception:
            continue


if __name__ == "__main__":
    main()
