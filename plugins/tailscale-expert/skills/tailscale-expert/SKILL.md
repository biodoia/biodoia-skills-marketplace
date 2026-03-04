---
name: tailscale-expert
description: This skill should be used when the user asks about "tailscale", "tailnet", "VPN mesh", "exit node", "subnet router", "MagicDNS", "wireguard mesh", "taildrop", "tailscale SSH", or "ACL policy". Make sure to use this skill whenever the user mentions Tailscale configuration, ACL policies, mesh networking, VPN troubleshooting, exit node setup, subnet routing, MagicDNS, Tailscale SSH, or managing tailnet devices, even if they don't explicitly ask for Tailscale help and just mention VPN or mesh networking.
---

# Tailscale Expert

Tailscale is a WireGuard-based mesh VPN that creates a zero-config private network (tailnet) across all connected devices. Every device gets a stable 100.x.x.x IP (CGNAT range). No port forwarding, no static IPs, no VPN concentrators required.

## Core Concepts

- **Tailnet**: the private network encompassing all devices running Tailscale under one account or organization
- **MagicDNS**: automatic DNS resolution (`device-name.tailnet-name.ts.net`) for all tailnet members
- **Coordination server**: Tailscale's control plane (or self-hosted Headscale for full self-hosting)
- **DERP relays**: encrypted fallback relay servers used when direct WireGuard connection fails due to NAT or firewall restrictions
- **ACL policy**: HuJSON file controlling which devices and users can communicate within the tailnet
- **Auth keys**: pre-authentication keys for headless or automated device enrollment without interactive login
- **Tailnet lock**: optional feature to prevent unauthorized devices from joining, requiring node approval by trusted signers

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

**Alpine/Docker/NixOS:** consult `tailscale up --help` or https://tailscale.com/download for platform-specific instructions.

After running `tailscale up`, authenticate via the printed URL. The device appears in the admin console at https://login.tailscale.com/admin/machines.

**Headless / auth key enrollment (servers, containers):**
```bash
sudo tailscale up --authkey=tskey-auth-XXXX --hostname=my-server
```

Generate auth keys from the admin console under Settings > Keys. Optionally set keys as reusable, ephemeral, or pre-approved for specific tags.

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
tailscale cert <hostname>        # Obtain HTTPS certificate for a device
tailscale debug prefs            # Dump current client preferences (advanced)
```

Full CLI reference: see `references/tailscale-cli.md`.

## MagicDNS Configuration

MagicDNS assigns every device a DNS name: `<machine-name>.<tailnet-name>.ts.net`. Enable it from the admin console under DNS tab > Enable MagicDNS.

**Key configuration options:**

- **Global nameservers**: Admin console > DNS > Add nameserver. Set DNS servers for the entire tailnet (e.g., 1.1.1.1, 8.8.8.8, or internal DNS).
- **Override local DNS**: Toggle "Override local DNS" to force tailnet DNS settings on all devices, replacing system-configured resolvers.
- **Split DNS**: Admin console > DNS > Add nameserver > restrict to domain (e.g., `internal.corp`). Only queries for specified domains route through the designated nameserver; all other queries use the default resolver.
- **Short names**: Enable short hostnames (drop the tailnet suffix) under DNS settings. After enabling, `ping my-server` resolves directly via the quad100 resolver (100.100.100.100).

```bash
# Verify MagicDNS resolution:
ping my-server                    # resolves via 100.100.100.100 (quad100)
ssh my-server                     # direct WireGuard, no port forwarding needed
resolvectl status                 # check 100.100.100.100 is listed as DNS server
```

**Custom HTTPS certificates** for MagicDNS names:
```bash
tailscale cert my-server.tailnet-name.ts.net
# Generates a Let's Encrypt certificate valid for the MagicDNS hostname
```

## Exit Nodes

An exit node routes all internet traffic from a client through itself, functioning as a traditional VPN for browsing privacy or geo-location purposes.

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

**Exit node best practices:**
- Place exit nodes in different geographic regions for latency control
- Use `autoApprovers` in ACL policy to auto-approve exit node advertisements for tagged devices
- Combine with `--exit-node-allow-lan-access` to maintain local network printing and file sharing
- Monitor exit node load via `tailscale status` on the exit node device

## Subnet Routing

Subnet routers expose non-Tailscale networks to the tailnet without requiring an agent on each host.

**On the router machine:**
```bash
# Enable IP forwarding (same as exit node above)
sudo tailscale up --advertise-routes=192.168.1.0/24,10.0.0.0/8
```

Approve in admin console: Machines > machine > Edit route settings, or via `autoApprovers` in ACL.

**On clients -- accept routes:**
```bash
sudo tailscale up --accept-routes
```

**Key subnet routing patterns:**
- Multiple subnet routers can advertise the same range for **HA failover** -- Tailscale automatically routes through the available node
- Use `--advertise-routes` with multiple CIDR ranges separated by commas
- Subnet routes enable access to legacy devices (printers, IoT, NAS) without installing Tailscale on them
- Combine subnet routing with ACL tags to restrict which users can reach specific subnets

## ACL Policy

ACLs are defined in HuJSON (JSON with comments) in the admin console (Access controls tab) or via `tailscale policy` CLI. See `references/tailscale-acls.md` for full patterns and examples.

**Minimal permissive policy (everyone talks to everyone):**
```json
{
  "acls": [
    {"action": "accept", "src": ["*"], "dst": ["*:*"]}
  ]
}
```

**Role-based access example (restrict prod servers):**
```json
{
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:prod":   ["autogroup:admin"]
  },
  "acls": [
    {"action": "accept", "src": ["group:devs"], "dst": ["tag:server:22,443"]},
    {"action": "accept", "src": ["group:ops"],  "dst": ["tag:prod:*"]},
    {"action": "accept", "src": ["autogroup:member"], "dst": ["autogroup:self:*"]}
  ],
  "autoApprovers": {
    "routes": {
      "10.0.0.0/8": ["tag:server"]
    },
    "exitNode": ["tag:server"]
  }
}
```

**Tag a device at auth time:**
```bash
sudo tailscale up --advertise-tags=tag:server,tag:prod
```

Tags must be defined in ACL `tagOwners` before use. For complete ACL pattern reference including SSH rules, grants, and autoApprovers, see `references/tailscale-acls.md`.

## Taildrop (File Sharing)

Send files peer-to-peer between tailnet devices:
```bash
tailscale file send <file> <target-device>
tailscale file get [--output-dir=<dir>]   # receive pending files
```

Must be enabled per-device and accepted manually or via policy.

## Tailscale SSH

Tailscale can manage SSH access without keys -- auth is tied to tailnet identity.

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

## Troubleshooting Quick Reference

| Symptom | Diagnosis | Resolution |
|---------|-----------|------------|
| Device shows offline | `systemctl status tailscaled` | Restart daemon: `systemctl restart tailscaled`, re-auth if token expired |
| High latency / DERP relay | `tailscale ping <peer>` shows "via DERP" | Open UDP 41641 on firewall for direct WireGuard connections |
| Cannot reach subnet routes | `tailscale status --peers` missing route | Run `tailscale up --accept-routes` on client, approve routes in admin console |
| DNS not resolving | `resolvectl status` missing quad100 | Restart systemd-resolved, verify MagicDNS enabled in admin console |
| Key expired / re-auth needed | `tailscale status` shows "needs login" | Run `tailscale up --force-reauth` or disable key expiry for servers |

**Detailed troubleshooting steps:**

```bash
# Full diagnostic
tailscale netcheck               # check UDP blocked, DERP latency, NAT type
tailscale bugreport              # generate detailed diagnostic bundle

# Firewall checklist:
# - Allow UDP 41641 (WireGuard direct)
# - Allow TCP 443 (DERP fallback + control plane)
# - For subnet routers: allow forwarding between tailscale0 and LAN interface
```

## Additional Resources

- Complete CLI flags and examples: `references/tailscale-cli.md`
- ACL policy patterns (dev/prod/roles, SSH rules, autoApprovers): `references/tailscale-acls.md`
- Official documentation: https://tailscale.com/kb/
- Headscale (self-hosted control server): https://github.com/juanfont/headscale
- Check tailnet status interactively: `/tailscale-status` command
