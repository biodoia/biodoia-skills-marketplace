#!/usr/bin/env python3
"""
Skill Master — Usage Analyzer & Evolution Proposer

Analyzes ~/.claude/skill-master-usage.jsonl to compute:
- Skill usage frequency and trends
- Recommendation accuracy (trigger rate vs organic rate)
- Skill gaps (topics without matching skills)
- Co-occurrence patterns (skills used together)
- Evolution proposals

Usage:
    python3 analyze-usage.py [--period 30] [--skill NAME] [--gaps] [--combinations]
"""

import json
import sys
import os
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from pathlib import Path

USAGE_LOG = os.environ.get(
    "SKILL_MASTER_USAGE_LOG",
    os.path.expanduser("~/.claude/skill-master-usage.jsonl")
)


def load_events(path, period_days=90):
    """Load events from JSONL, filtering by period."""
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


def analyze(events):
    """Core analysis: compute all metrics."""
    sessions = [e for e in events if e.get("event") == "session_start"]
    usages = [e for e in events if e.get("event") == "skill_used"]

    # Skill usage counts
    skill_counts = Counter(e.get("skill", "unknown") for e in usages)

    # Project type detection
    project_skills = defaultdict(list)
    for e in usages:
        project_skills[e.get("project", "unknown")].append(e.get("skill"))

    # Recommendation tracking
    recommended_skills = Counter()
    for s in sessions:
        for skill in s.get("recommended", "").split():
            if skill:
                recommended_skills[skill] += 1

    # Trigger rate: how often recommended skills get used
    trigger_rates = {}
    for skill, rec_count in recommended_skills.items():
        used_count = skill_counts.get(skill, 0)
        trigger_rates[skill] = used_count / rec_count if rec_count > 0 else 0

    # Organic rate: skills used without recommendation
    organic_skills = Counter()
    for e in usages:
        skill = e.get("skill", "")
        if skill and skill not in recommended_skills:
            organic_skills[skill] += 1

    # Co-occurrence: skills used in the same project/session
    co_occur = defaultdict(int)
    for project, skills in project_skills.items():
        unique_skills = list(set(skills))
        for i, a in enumerate(unique_skills):
            for b in unique_skills[i+1:]:
                pair = tuple(sorted([a, b]))
                co_occur[pair] += 1

    # Signal patterns per project
    signal_map = defaultdict(Counter)
    for s in sessions:
        signals = s.get("signals", "").split()
        recommended = s.get("recommended", "").split()
        for sig in signals:
            for skill in recommended:
                signal_map[sig][skill] += 1

    return {
        "total_sessions": len(sessions),
        "total_usages": len(usages),
        "skill_counts": skill_counts,
        "recommended_skills": recommended_skills,
        "trigger_rates": trigger_rates,
        "organic_skills": organic_skills,
        "co_occurrence": co_occur,
        "signal_map": signal_map,
        "project_skills": project_skills,
    }


def propose_evolutions(metrics):
    """Generate evolution proposals from metrics."""
    proposals = []

    # High organic rate → missing signal
    for skill, count in metrics["organic_skills"].most_common():
        if count >= 3:
            proposals.append({
                "type": "signal_expansion",
                "severity": "!",
                "skill": skill,
                "msg": f"high organic rate ({count} uses without recommendation) — add signal mapping"
            })

    # Low trigger rate → noisy recommendation
    for skill, rate in metrics["trigger_rates"].items():
        rec_count = metrics["recommended_skills"].get(skill, 0)
        if rate < 0.05 and rec_count >= 5:
            proposals.append({
                "type": "signal_contraction",
                "severity": "!",
                "skill": skill,
                "msg": f"low trigger rate ({rate:.0%} of {rec_count} recommendations) — narrow or remove signal"
            })

    # High co-occurrence → combination template
    for (a, b), count in sorted(metrics["co_occurrence"].items(), key=lambda x: -x[1]):
        total_a = metrics["skill_counts"].get(a, 1)
        total_b = metrics["skill_counts"].get(b, 1)
        co_rate = count / min(total_a, total_b) if min(total_a, total_b) > 0 else 0
        if co_rate > 0.7 and count >= 3:
            proposals.append({
                "type": "combination",
                "severity": "~",
                "skill": f"{a} + {b}",
                "msg": f"co-occurrence {co_rate:.0%} ({count} times) — consider stack template"
            })

    return proposals


def print_report(metrics, proposals):
    """Print formatted analytics report."""
    print()
    print("=" * 50)
    print("  SKILL MASTER ANALYTICS")
    print("=" * 50)
    print()
    print(f"  Sessions analyzed: {metrics['total_sessions']}")
    print(f"  Total skill uses:  {metrics['total_usages']}")
    print()

    if metrics["skill_counts"]:
        print("  Top skills by usage:")
        for i, (skill, count) in enumerate(metrics["skill_counts"].most_common(10), 1):
            pct = count / max(metrics["total_sessions"], 1) * 100
            print(f"    {i:2}. {skill:45} ({count} uses, {pct:.0f}% of sessions)")
        print()

    if metrics["trigger_rates"]:
        triggered = sum(1 for r in metrics["trigger_rates"].values() if r > 0.1)
        total = len(metrics["trigger_rates"])
        overall = triggered / total if total > 0 else 0
        organic_total = sum(metrics["organic_skills"].values())
        organic_pct = organic_total / max(metrics["total_usages"], 1) * 100
        print(f"  Recommendation accuracy:")
        print(f"    Trigger rate: {overall:.0%} (recommended → used)")
        print(f"    Organic rate: {organic_pct:.0f}% (used without recommendation)")
        print()

    if proposals:
        print("  Proposed evolutions:")
        for p in proposals:
            print(f"    [{p['severity']}] {p['skill']}: {p['msg']}")
        print()
    else:
        print("  No evolutions proposed (insufficient data or all healthy)")
        print()

    print("=" * 50)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Skill Master Usage Analyzer")
    parser.add_argument("--period", type=int, default=90, help="Analysis period in days")
    parser.add_argument("--skill", help="Analyze specific skill")
    parser.add_argument("--gaps", action="store_true", help="Show skill gaps only")
    parser.add_argument("--combinations", action="store_true", help="Show co-occurrences only")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    events = load_events(USAGE_LOG, args.period)

    if not events:
        print(f"No usage data found at {USAGE_LOG}")
        print("Usage data is collected automatically by the skill-master hooks.")
        print("Run some sessions first, then come back.")
        sys.exit(0)

    metrics = analyze(events)
    proposals = propose_evolutions(metrics)

    if args.json:
        output = {
            "total_sessions": metrics["total_sessions"],
            "total_usages": metrics["total_usages"],
            "top_skills": dict(metrics["skill_counts"].most_common(20)),
            "proposals": proposals,
        }
        print(json.dumps(output, indent=2))
    else:
        print_report(metrics, proposals)


if __name__ == "__main__":
    main()
