---
description: Run tailscale status and format the output with peer details, route info, and connection path
allowed-tools: ["Bash"]
---

# Tailscale Status

Run `tailscale status` and present a structured summary of the tailnet state.

## Steps

1. Run `tailscale status --json` to get machine-readable output.
2. Run `tailscale netcheck` to get NAT and relay info.
3. Format and display the results as a clean summary.

## Execution

```bash
tailscale status --json 2>/dev/null || tailscale status
```

```bash
tailscale netcheck 2>/dev/null
```

## Output Format

Present the results as:

### This Device
- Tailnet IP(s)
- Hostname
- Operating state (Connected / Offline)
- MagicDNS name (if MagicDNS enabled)

### Peers Table

| Hostname | IP | OS | Status | Exit Node | Routes |
|----------|----|----|--------|-----------|--------|
| (parsed from JSON) | | | | | |

Mark peers as:
- Online (last handshake < 3 minutes ago)
- Idle (last handshake 3-15 minutes ago)
- Offline (last handshake > 15 minutes ago or never seen)

Highlight:
- Active exit node in use (with a note if routing all traffic)
- Peers advertising subnet routes
- Peers with Tailscale SSH enabled

### Network Quality
- UDP availability
- Preferred DERP relay and latency
- NAT type (easy / hard)
- Warn if `MappingVariesByDestIP = true` (hard NAT, may prevent direct connections)

### Quick Actions

If peers are offline or DERP-only, suggest:
```bash
tailscale ping <peer>            # diagnose connection
tailscale netcheck               # check UDP/NAT
sudo systemctl restart tailscaled  # restart daemon
```
