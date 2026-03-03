# Tailscale CLI Reference

Complete reference for the `tailscale` and `tailscaled` binaries.

## Global Flags

```
--socket <path>     Path to tailscaled unix socket (default: /var/run/tailscale/tailscaled.sock)
--version           Print version and exit
--help              Show help
```

---

## tailscale up

Connect to the tailnet or update settings. Re-runs with new flags merge with current config.

```
tailscale up [flags]
```

| Flag | Description |
|------|-------------|
| `--accept-dns` | Accept DNS configuration from the tailnet (default true) |
| `--accept-routes` | Accept subnet routes advertised by other peers (default false) |
| `--advertise-exit-node` | Offer to route all internet traffic for tailnet peers |
| `--advertise-routes=<cidrs>` | Comma-separated subnets to expose to tailnet, e.g. `192.168.1.0/24,10.0.0.0/8` |
| `--advertise-tags=<tags>` | Comma-separated tags to apply, e.g. `tag:server,tag:prod` |
| `--auth-key=<key>` | Auth key for headless/automated auth (from admin console) |
| `--exit-node=<host-or-ip>` | Route all internet traffic through this exit node |
| `--exit-node-allow-lan-access` | When using exit node, still allow access to local LAN |
| `--force-reauth` | Force re-authentication without rotating keys |
| `--host-routes` | Install host routes for all peers (default true) |
| `--hostname=<name>` | Override the hostname reported to tailnet |
| `--login-server=<url>` | Use alternate control server (e.g. Headscale at `https://headscale.example.com`) |
| `--netfilter-mode=<mode>` | Netfilter mode: `on`, `nodivert`, `off` |
| `--operator=<user>` | Unix user allowed to operate Tailscale without root |
| `--qr` | Show QR code for auth URL |
| `--reset` | Reset unspecified settings to defaults |
| `--shields-up` | Block all incoming connections from tailnet peers |
| `--ssh` | Enable Tailscale SSH server on this device |
| `--timeout=<duration>` | Max time to wait for connection (default 0 = wait forever) |

**Examples:**
```bash
# Basic connect
sudo tailscale up

# Headless auth with key
sudo tailscale up --auth-key=tskey-auth-xxxx

# Subnet router
sudo tailscale up --advertise-routes=192.168.1.0/24 --accept-routes

# Exit node server
sudo tailscale up --advertise-exit-node

# Use exit node
sudo tailscale up --exit-node=my-vps --exit-node-allow-lan-access

# Tagged server with SSH, no key expiry managed via admin
sudo tailscale up --advertise-tags=tag:server --ssh --hostname=web-01

# Headscale
sudo tailscale up --login-server=https://headscale.example.com

# Reset all flags to default except hostname
sudo tailscale up --reset --hostname=myhost
```

---

## tailscale down

Disconnect from the tailnet. The `tailscaled` daemon keeps running.

```bash
tailscale down
```

---

## tailscale status

Show the current status of the tailnet and all peers.

```
tailscale status [flags]
```

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |
| `--peers` | Show peer details (default true) |
| `--self` | Show self node info (default true) |
| `--active` | Only show active peers (with recent traffic) |

**Output columns:** IP address, hostname, OS, online status, exit node indicator, last seen.

**Examples:**
```bash
tailscale status
tailscale status --json | jq '.Peer | to_entries[] | .value | {HostName, TailscaleIPs, Online}'
tailscale status --active     # only peers with recent traffic
```

---

## tailscale ip

Print the tailnet IP address(es) of this device.

```
tailscale ip [flags] [<peer>]
```

| Flag | Description |
|------|-------------|
| `-4` | Only IPv4 (100.x.x.x) |
| `-6` | Only IPv6 (fd7a:115c:.../128) |

**Examples:**
```bash
tailscale ip              # both v4 and v6
tailscale ip -4           # just 100.x.x.x
tailscale ip my-server    # get IP of a peer by hostname
```

---

## tailscale ping

Test connectivity and latency to a tailnet peer.

```
tailscale ping [flags] <hostname-or-ip>
```

| Flag | Description |
|------|-------------|
| `--c=<n>` | Number of pings (default 10) |
| `--icmp` | Use ICMP ping instead of Tailscale ping |
| `--peerapi` | Ping the peer's peerapi endpoint |
| `--timeout=<duration>` | Timeout per ping |
| `--until-direct` | Keep pinging until a direct connection is established |
| `--verbose` | Show extra path info |

**Examples:**
```bash
tailscale ping my-server                # shows path: direct or DERP relay + latency
tailscale ping --until-direct my-server # wait for WireGuard direct path
tailscale ping --c=3 100.64.0.1
```

---

## tailscale netcheck

Check your network conditions: NAT type, DERP relay latency, UDP availability.

```
tailscale netcheck [flags]
```

| Flag | Description |
|------|-------------|
| `--format=<fmt>` | Output format: `text` (default) or `json` |
| `--every=<duration>` | Repeat check at interval |
| `--verbose` | Verbose output |

**Examples:**
```bash
tailscale netcheck
tailscale netcheck --format=json | jq '.RegionLatency'
tailscale netcheck --every=5s    # continuous monitoring
```

**Key output fields:**
- `UDP`: whether UDP is available (required for direct WireGuard)
- `IPv4`, `IPv6`: connectivity type
- `MappingVariesByDestIP`: indicates hard NAT (may prevent direct connections)
- `PreferredDERP`: closest relay region
- `RegionLatency`: latency to each DERP region

---

## tailscale whois

Look up identity information for a tailnet IP address.

```
tailscale whois [flags] <ip-or-hostname>
```

| Flag | Description |
|------|-------------|
| `--json` | JSON output |

**Examples:**
```bash
tailscale whois 100.64.0.5
tailscale whois my-server.tailnet-name.ts.net
tailscale whois --json 100.64.0.5 | jq '{Node: .Node.Name, User: .UserProfile.LoginName}'
```

---

## tailscale ssh

Open an SSH session to a tailnet device via Tailscale SSH.

```
tailscale ssh [<user>@]<host> [command]
```

**Examples:**
```bash
tailscale ssh root@my-server
tailscale ssh user@my-server "systemctl status nginx"
```

---

## tailscale file

Taildrop: peer-to-peer file transfers within the tailnet.

```
tailscale file send [flags] <file> <target>
tailscale file get [flags]
```

**Send flags:**
| Flag | Description |
|------|-------------|
| `--targets` | List available targets |
| `--verbose` | Verbose output |

**Get flags:**
| Flag | Description |
|------|-------------|
| `--output-dir=<dir>` | Directory for received files |
| `--conflict=<mode>` | Conflict resolution: `overwrite`, `rename`, `skip` |
| `--verbose` | Verbose output |
| `--wait` | Wait for incoming files |

**Examples:**
```bash
tailscale file send report.pdf my-laptop          # send to peer
tailscale file send --targets                      # list devices that can receive
tailscale file get --output-dir=/tmp/received      # collect received files
tailscale file get --wait --output-dir=~/Downloads # wait and receive
```

---

## tailscale cert

Get a TLS certificate for a MagicDNS hostname (via Let's Encrypt, DNS-01).

```
tailscale cert [flags] <domain>
```

| Flag | Description |
|------|-------------|
| `--cert-file=<path>` | Output path for certificate PEM |
| `--key-file=<path>` | Output path for key PEM |

**Examples:**
```bash
tailscale cert my-server.tailnet-name.ts.net
tailscale cert --cert-file=/etc/nginx/ts.crt --key-file=/etc/nginx/ts.key my-server.tailnet-name.ts.net
```

Certificates are valid for the device's MagicDNS name. Renew before expiry (90-day LE certs).

---

## tailscale lock

Tailnet lock — require cryptographic approval for new devices joining.

```
tailscale lock <subcommand>
```

| Subcommand | Description |
|------------|-------------|
| `init <key> [keys...]` | Initialize tailnet lock with trusted signing keys |
| `status` | Show lock status and trusted keys |
| `add <key>` | Add a trusted signing key |
| `remove <key>` | Remove a trusted signing key |
| `sign <node-key>` | Sign a new device's node key |
| `disable <key>` | Disable tailnet lock |
| `disablements` | Manage disablement secrets |
| `local-unlock` | Unlock this device locally |

**Examples:**
```bash
tailscale lock status
tailscale lock init $(tailscale lock genkey)
tailscale lock sign <node-key-from-new-device>
```

---

## tailscale switch

Switch between multiple tailnets (accounts).

```
tailscale switch [<account>]
tailscale switch --list
```

**Examples:**
```bash
tailscale switch --list           # show available accounts
tailscale switch user@example.com # switch to a specific account
```

---

## tailscale logout

Deauthenticate this device from the tailnet.

```
tailscale logout
```

---

## tailscale debug

Low-level diagnostics. Mostly for debugging and support.

```
tailscale debug <subcommand>
```

| Subcommand | Description |
|------------|-------------|
| `daemon-goroutines` | Show goroutine dump of tailscaled |
| `derp-map` | Show DERP relay map |
| `local-creds` | Show local API credentials |
| `metrics` | Show prometheus-format metrics |
| `peer-endpoint-changes <ip>` | Show endpoint change history for a peer |
| `portmap` | Debug NAT portmapping |
| `set` | Set debug flags (verbosity, etc.) |
| `ts2021` | Test ts2021 protocol connectivity |

**Examples:**
```bash
tailscale debug metrics            # prometheus metrics from tailscaled
tailscale debug derp-map           # see all DERP servers
tailscale debug peer-endpoint-changes 100.64.0.5
```

---

## tailscale version

Print the running version of Tailscale.

```
tailscale version [--daemon]
```

```bash
tailscale version         # client binary version
tailscale version --daemon  # version of running tailscaled
```

---

## tailscaled (daemon)

The background daemon. Usually managed by systemd.

```
tailscaled [flags]
```

| Flag | Description |
|------|-------------|
| `--state=<path>` | State file path (default: `/var/lib/tailscale/tailscaled.state`) |
| `--socket=<path>` | Unix socket path |
| `--port=<n>` | UDP port for WireGuard (default 41641, 0 = random) |
| `--tun=<name>` | TUN interface name (default `tailscale0`, use `userspace-networking` for no TUN) |
| `--socks5-server=<addr>` | Enable SOCKS5 proxy on this address |
| `--outbound-http-proxy-listen=<addr>` | Enable HTTP proxy |
| `--verbose=<n>` | Log verbosity (1-5) |

**Userspace networking (no TUN, unprivileged):**
```bash
tailscaled --tun=userspace-networking --socks5-server=localhost:1080 &
tailscale up --auth-key=tskey-auth-xxx
# Then: curl --proxy socks5://localhost:1080 http://100.64.x.x/
```

Useful in containers or environments without TUN access.

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `TS_AUTHKEY` | Auth key for `tailscale up` (same as `--auth-key`) |
| `TS_EXTRA_ARGS` | Extra flags appended to `tailscale up` |
| `TS_STATE_DIR` | Override state directory |
| `TS_SOCKET` | Override socket path |
| `TS_USERSPACE` | Set to `1` for userspace networking mode |
| `TS_ROUTES` | Advertised routes (same as `--advertise-routes`) |
| `TS_DEST_IP` | Specific IP to route traffic to (for sidecar pattern) |
| `TS_HOSTNAME` | Override hostname |
| `TS_SOCKS5_SERVER` | SOCKS5 listen address |
| `TS_ACCEPT_DNS` | Set to `false` to reject DNS config |

Commonly used in Docker/Kubernetes sidecars:
```bash
docker run -e TS_AUTHKEY=tskey-auth-xxx -e TS_ROUTES=10.0.0.0/8 tailscale/tailscale
```

---

## API: tailscale policy (ACL management)

```
tailscale policy get              # print current ACL policy to stdout
tailscale policy set [--file=<path>] # update ACL from file (or stdin)
```

```bash
tailscale policy get > acl.hujson
# edit acl.hujson
tailscale policy set --file=acl.hujson
```

Requires the device to be authenticated as an admin of the tailnet.
