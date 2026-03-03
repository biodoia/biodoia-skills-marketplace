---
name: tailscale-expert
description: Use when configuring Tailscale VPN, setting up ACLs, troubleshooting mesh networking, configuring exit nodes, subnet routers, MagicDNS, or managing tailnet devices. Also use when the user mentions "tailscale", "tailnet", "wireguard mesh", "exit node", "subnet router", "MagicDNS", or VPN connectivity issues.
---

# Tailscale Expert

Tailscale is a WireGuard-based mesh VPN that creates a zero-config private network (tailnet) across all your devices. Every device gets a stable 100.x.x.x IP (CGNAT range). No port forwarding, no static IPs, no VPN concentrators.

## Core Concepts

- **Tailnet**: your private network — all devices running Tailscale under one account/org
- **MagicDNS**: automatic DNS resolution (`device-name.tailnet-name.ts.net`)
- **Coordination server**: Tailscale's control plane (or self-hosted Headscale)
- **DERP relays**: encrypted fallback relay servers when direct WireGuard connection fails
- **ACL policy**: HuJSON file controlling who can talk to what in the tailnet

## Installation

**Arch/Manjaro:**
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Ubuntu/Debian:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
sudo tailscale up
```

**Alpine/Docker/NixOS:** see `tailscale up --help` or https://tailscale.com/download

After `tailscale up`, authenticate via the printed URL. The device appears in the admin console at https://login.tailscale.com/admin/machines.

## Core Commands

```bash
tailscale up                     # Connect / re-authenticate
tailscale down                   # Disconnect (daemon keeps running)
tailscale status                 # Show all tailnet peers and their state
tailscale ip                     # Print this device's tailnet IP(s)
tailscale ping <host>            # Latency test + path info (DERP vs direct)
tailscale netcheck               # Check NAT type, DERP latency, UDP support
tailscale whois <ip-or-host>     # Identify a tailnet IP
tailscale logout                 # Deauthenticate this device
tailscale switch <account>       # Switch between multiple tailnets
```

Full CLI reference: see `references/tailscale-cli.md`.

## Exit Nodes

An exit node routes all internet traffic from a client through itself — replaces a traditional VPN for browsing.

**Configure a device as exit node:**
```bash
# Enable IP forwarding first
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Advertise as exit node
sudo tailscale up --advertise-exit-node
```

Approve in admin console: Machines > machine > Edit route settings > Use as exit node.

Or approve via ACL `autoApprovers` (see `references/tailscale-acls.md`).

**Use an exit node from a client:**
```bash
sudo tailscale up --exit-node=<hostname-or-ip>
sudo tailscale up --exit-node=<hostname> --exit-node-allow-lan-access  # still reach LAN
sudo tailscale up --exit-node=""          # disable exit node
```

## Subnet Routing

Subnet routers expose non-Tailscale networks to the tailnet — no agent needed on each host.

**On the router machine:**
```bash
# Enable IP forwarding (same as exit node above)
sudo tailscale up --advertise-routes=192.168.1.0/24,10.0.0.0/8
```

Approve in admin console: Machines > machine > Edit route settings, or via `autoApprovers` in ACL.

**On clients — accept routes:**
```bash
sudo tailscale up --accept-routes
```

Multiple subnet routers can advertise the same range for failover (HA subnets).

## MagicDNS and Split DNS

MagicDNS gives every device a name: `<machine-name>.<tailnet-name>.ts.net`.

Enable in admin console: DNS tab > Enable MagicDNS.

**Override global DNS via Tailscale:**
Admin console > DNS > Add nameserver > set as override-DNS.

**Split DNS** — only resolve specific domains through Tailscale nameservers:
Admin console > DNS > Add nameserver > restrict to domain (e.g. `internal.corp`).

**Short names** (drop the tail suffix): Admin console > DNS > Enable magic DNS > "Use tailnet name" toggle.

```bash
# After MagicDNS:
ping my-server                    # resolves via 100.100.100.100 (quad100)
ssh my-server                     # direct WireGuard, no port forwarding needed
```

## ACL Policy

ACLs are defined in HuJSON (JSON with comments) in the admin console (Access controls tab) or via `tailscale policy` CLI. See `references/tailscale-acls.md` for full patterns.

**Minimal permissive policy (everyone talks to everyone):**
```json
{
  "acls": [
    {"action": "accept", "src": ["*"], "dst": ["*:*"]}
  ]
}
```

**Tag a device at auth time:**
```bash
sudo tailscale up --advertise-tags=tag:server,tag:prod
```

Tags must be defined in ACL `tagOwners` before use.

## Taildrop (File Sharing)

Send files peer-to-peer between tailnet devices:
```bash
tailscale file send <file> <target-device>
tailscale file get [--output-dir=<dir>]   # receive pending files
```

Must be enabled per-device and accepted manually or via policy.

## Tailscale SSH

Tailscale can manage SSH access without keys — auth is tied to tailnet identity.

**Enable on the server:**
```bash
sudo tailscale up --ssh
```

Add SSH rules in the ACL policy (see `references/tailscale-acls.md` for full SSH policy syntax).

**Connect from client:**
```bash
ssh user@my-server          # direct over tailnet, no .ssh/config needed
tailscale ssh user@my-server  # explicit tailscale ssh binary
```

Connections are logged and visible in the admin console. Optionally require re-auth with `check-period`.

## Troubleshooting

**Device shows offline:**
```bash
sudo systemctl status tailscaled
sudo systemctl restart tailscaled
tailscale up          # re-auth if token expired
```

**High latency / DERP relay instead of direct:**
```bash
tailscale ping <peer>            # shows "via DERP" or "direct"
tailscale netcheck               # check UDP blocked, DERP latency
# Fix: open UDP 41641 on firewall (or any UDP for hairpin NAT)
```

**Cannot reach subnet routes:**
```bash
tailscale status --peers         # check peer has route advertised
sudo tailscale up --accept-routes  # must be set on client
# Verify routes approved in admin console
```

**DNS not resolving:**
```bash
resolvectl status                # check 100.100.100.100 in DNS servers
tailscale status                 # check MagicDNS enabled
sudo systemctl restart systemd-resolved
```

**Re-auth / key expiry:**
```bash
tailscale up --force-reauth      # force re-auth without key rotation
# Or disable key expiry for servers in admin console
```

**Firewall checklist:**
- Allow UDP 41641 (WireGuard direct)
- Allow TCP 443 (DERP fallback + control plane)
- For subnet routers: allow forwarding between tailscale0 and LAN interface

## Progressive Disclosure

- Complete CLI flags and examples: `references/tailscale-cli.md`
- ACL policy patterns (dev/prod/roles, SSH rules, autoApprovers): `references/tailscale-acls.md`
- Check tailnet status interactively: `/tailscale-status` command
