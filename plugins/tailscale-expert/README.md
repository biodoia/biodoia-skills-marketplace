# tailscale-expert

A Claude Code plugin providing expert-level guidance for Tailscale VPN: setup, ACL policies, exit nodes, subnet routing, MagicDNS, Taildrop, Tailscale SSH, and troubleshooting.

## What This Plugin Does

When loaded, Claude gains deep knowledge about:

- Installing and authenticating Tailscale on any Linux distro
- Configuring exit nodes (both server and client side)
- Setting up subnet routers to expose non-Tailscale networks
- Writing ACL policies in HuJSON (groups, tags, autoApprovers, SSH rules)
- MagicDNS and split DNS configuration
- Diagnosing connectivity issues (DERP relays, NAT traversal, firewall rules)
- Tailscale SSH with re-auth policies
- Taildrop file sharing
- TLS certificates for MagicDNS hostnames

## Structure

```
tailscale-expert/
├── .claude-plugin/
│   └── plugin.json                          # Plugin metadata
├── skills/
│   └── tailscale-expert/
│       ├── SKILL.md                         # Core skill (auto-loaded by Claude)
│       └── references/
│           ├── tailscale-cli.md             # Complete CLI reference
│           └── tailscale-acls.md            # ACL policy patterns and examples
├── commands/
│   └── tailscale-status.md                  # /tailscale-status slash command
└── README.md
```

## Skills

### `tailscale-expert`

Triggered when the user asks about Tailscale, tailnets, exit nodes, subnet routing, MagicDNS, WireGuard mesh, or VPN connectivity.

Covers: installation, core commands, exit nodes, subnet routing, MagicDNS, SSH, Taildrop, troubleshooting.

References (loaded on demand):
- `tailscale-cli.md` — all flags for every `tailscale` subcommand
- `tailscale-acls.md` — ACL patterns: dev/staging/prod, roles, autoApprovers, SSH policies

## Commands

### `/tailscale-status`

Runs `tailscale status --json` and `tailscale netcheck`, then formats a structured summary:
- This device's tailnet IPs and state
- Peer table (online/idle/offline, exit nodes, subnet routes)
- Network quality (DERP relay, NAT type, UDP availability)
- Suggested quick-fix commands when issues are detected

## Installation

### Via Claude Code (manual install)

```bash
# Clone or copy this plugin into your Claude skills directory
cp -r tailscale-expert ~/.claude/skills/

# Or install from the marketplace
claude install biodoia/biodoia-skills-marketplace#tailscale-expert
```

### In a project `.claude/settings.json`

```json
{
  "plugins": [
    {
      "source": "url",
      "url": "https://github.com/biodoia/biodoia-skills-marketplace.git",
      "subpath": "plugins/tailscale-expert"
    }
  ]
}
```

## Author

Sergio Martinelli — [biodoia](https://github.com/biodoia)

## License

MIT
