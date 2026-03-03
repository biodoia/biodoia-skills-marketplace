# Tailscale ACL Policy Reference

ACL policies are written in HuJSON (JSON with C-style comments and trailing commas allowed). Manage them in the Tailscale admin console under "Access controls", or via `tailscale policy set`.

Official schema: https://tailscale.com/kb/1337/acl-syntax

---

## Policy File Structure

```jsonc
{
  // Define groups of users
  "groups": {},

  // Define tag owners (required before any tag:* can be used)
  "tagOwners": {},

  // Define named host sets for reuse in rules
  "hosts": {},

  // The core access rules
  "acls": [],

  // Auto-approve advertised routes and exit nodes without admin action
  "autoApprovers": {},

  // Tailscale SSH configuration
  "ssh": [],

  // Named test cases to validate the policy
  "tests": []
}
```

All top-level keys are optional except `acls`.

---

## Groups

Groups map to sets of users (by email or login name).

```jsonc
{
  "groups": {
    "group:admins":    ["alice@example.com", "bob@example.com"],
    "group:devs":      ["carol@example.com", "dave@example.com"],
    "group:staging":   ["group:devs", "eve@example.com"],
    "group:readonly":  ["frank@example.com"]
  }
}
```

- Groups can reference other groups (nested, not circular).
- Users are identified by their identity provider login (email or GitHub/Google handle).

---

## Tag Owners

Tags are applied to devices (via `tailscale up --advertise-tags=tag:name`). `tagOwners` defines who is allowed to apply each tag.

```jsonc
{
  "tagOwners": {
    "tag:server":     ["group:admins"],
    "tag:prod":       ["group:admins"],
    "tag:staging":    ["group:admins", "group:devs"],
    "tag:dev":        ["group:devs"],
    "tag:exit-node":  ["group:admins"],
    "tag:ci":         ["autogroup:admin"]  // only org admins
  }
}
```

`autogroup:admin` refers to users with admin role in the Tailscale admin console.

---

## Hosts (Named Subnets/IPs)

Define reusable host aliases:

```jsonc
{
  "hosts": {
    "homelab":         "192.168.1.0/24",
    "office-wifi":     "10.0.0.0/8",
    "monitoring":      "100.64.0.10",    // specific tailnet IP
    "k8s-pods":        "10.96.0.0/12"
  }
}
```

---

## ACL Rules

Each rule specifies: source(s), destination(s)+ports, and action.

```jsonc
{
  "acls": [
    {
      "action": "accept",     // "accept" is the only action currently
      "src":    [...],        // sources: users, groups, tags, IPs, CIDRs, autogroups
      "dst":    [...],        // dest:port pairs
      "proto":  "tcp"         // optional: "tcp", "udp", "icmp"
    }
  ]
}
```

**Default behavior:** deny-all. Rules are additive — if any rule matches, traffic is accepted.

### Source Types

| Source | Description |
|--------|-------------|
| `"*"` | All tailnet members and tagged devices |
| `"alice@example.com"` | A specific user |
| `"group:admins"` | All members of a group |
| `"tag:server"` | All devices with that tag |
| `"100.64.0.10"` | Specific tailnet IP |
| `"192.168.1.0/24"` | CIDR range (for subnet members) |
| `"autogroup:self"` | The same device as the destination |
| `"autogroup:admin"` | Org admins |
| `"autogroup:member"` | All authenticated members |
| `"autogroup:tagged"` | All tagged (non-user-owned) devices |

### Destination Types (with ports)

```jsonc
"dst": [
  "tag:server:22",           // tag + port
  "tag:server:22,80,443",    // multiple ports
  "tag:server:0-65535",      // all ports (use * instead: "tag:server:*")
  "tag:server:*",            // all ports
  "100.64.0.10:8080",        // specific IP + port
  "192.168.1.0/24:*",        // subnet, all ports
  "homelab:22",              // named host alias + port
  "*:*"                      // everything, all ports
]
```

---

## Common Patterns

### 1. Fully Open (everyone talks to everyone)

```jsonc
{
  "acls": [
    {"action": "accept", "src": ["*"], "dst": ["*:*"]}
  ]
}
```

Use for personal tailnets where you trust all devices.

### 2. Admin Full Access + User Self-Only

```jsonc
{
  "groups": {
    "group:admins": ["alice@example.com"]
  },
  "acls": [
    // Admins can reach everything
    {"action": "accept", "src": ["group:admins"], "dst": ["*:*"]},
    // Users can reach their own devices only
    {"action": "accept", "src": ["autogroup:member"], "dst": ["autogroup:self:*"]}
  ]
}
```

### 3. Dev / Staging / Prod Separation

```jsonc
{
  "tagOwners": {
    "tag:dev":     ["group:devs"],
    "tag:staging": ["group:devs", "group:admins"],
    "tag:prod":    ["group:admins"]
  },
  "acls": [
    // Devs can reach dev and staging
    {"action": "accept", "src": ["group:devs"],  "dst": ["tag:dev:*", "tag:staging:*"]},
    // Admins can reach everything
    {"action": "accept", "src": ["group:admins"], "dst": ["*:*"]},
    // Servers can initiate to each other within same tier
    {"action": "accept", "src": ["tag:prod"],    "dst": ["tag:prod:*"]},
    {"action": "accept", "src": ["tag:staging"], "dst": ["tag:staging:*"]},
    {"action": "accept", "src": ["tag:dev"],     "dst": ["tag:dev:*"]}
  ]
}
```

### 4. Role-Based Access (Web + DB + SSH)

```jsonc
{
  "groups": {
    "group:admins":   ["alice@example.com"],
    "group:devs":     ["carol@example.com", "dave@example.com"],
    "group:ops":      ["group:admins", "eve@example.com"],
    "group:readonly": ["frank@example.com"]
  },
  "tagOwners": {
    "tag:web":  ["group:ops"],
    "tag:db":   ["group:ops"],
    "tag:jump": ["group:admins"]
  },
  "acls": [
    // Ops: full SSH access to all servers
    {"action": "accept", "src": ["group:ops"],      "dst": ["tag:web:22", "tag:db:22"]},
    // Devs: SSH to web servers only, read DB port
    {"action": "accept", "src": ["group:devs"],     "dst": ["tag:web:22", "tag:db:5432"]},
    // All members: HTTPS to web
    {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:web:443,80"]},
    // Readonly: only monitoring port
    {"action": "accept", "src": ["group:readonly"], "dst": ["tag:web:9090", "tag:db:9090"]}
  ]
}
```

### 5. CI/CD Pipeline Tags

```jsonc
{
  "tagOwners": {
    "tag:ci":   ["autogroup:admin"],
    "tag:prod": ["autogroup:admin"]
  },
  "acls": [
    // CI runners can deploy to prod
    {"action": "accept", "src": ["tag:ci"],  "dst": ["tag:prod:22,8080"]},
    // Prod servers can pull from internal registry
    {"action": "accept", "src": ["tag:prod"], "dst": ["tag:ci:5000"]}
  ]
}
```

---

## autoApprovers

Automatically approve advertised routes and exit nodes without manual admin action in the console.

```jsonc
{
  "autoApprovers": {
    // Auto-approve exit node advertisement from any admin user or tagged device
    "exitNode": ["group:admins", "tag:exit-node"],

    // Auto-approve specific subnet routes
    "routes": {
      "192.168.1.0/24": ["tag:homelab-router"],
      "10.0.0.0/8":     ["group:admins"],
      "0.0.0.0/0":      ["tag:exit-node"],   // default route = exit node
      "::/0":           ["tag:exit-node"]     // IPv6 exit node
    }
  }
}
```

With `autoApprovers`, a server can run:
```bash
sudo tailscale up --advertise-exit-node --advertise-tags=tag:exit-node
```
...and be approved automatically without admin intervention.

---

## SSH Policy

Tailscale SSH rules define who can SSH to which devices, with what user, and optional re-auth requirements.

```jsonc
{
  "ssh": [
    {
      "action":      "accept",         // "accept" or "check"
      "src":         ["group:admins"], // who is connecting
      "dst":         ["tag:server"],   // destination devices
      "users":       ["root", "ubuntu", "autogroup:nonroot"],
      "checkPeriod": "12h"             // require re-auth every 12h (only with "check" action)
    }
  ]
}
```

### SSH action types

| Action | Description |
|--------|-------------|
| `"accept"` | Allow SSH immediately |
| `"check"` | Allow SSH but require periodic Tailscale re-auth |

### SSH user values

| Value | Description |
|-------|-------------|
| `"root"` | The root user |
| `"ubuntu"`, `"ec2-user"` | Named system users |
| `"autogroup:nonroot"` | Any non-root user |
| `"autogroup:self"` | Same username as the Tailscale user's login |

### SSH Examples

**Admins can SSH as root or ubuntu, re-auth every 24h:**
```jsonc
{
  "ssh": [
    {
      "action":      "check",
      "src":         ["group:admins"],
      "dst":         ["tag:prod"],
      "users":       ["root", "ubuntu"],
      "checkPeriod": "24h"
    }
  ]
}
```

**Devs can SSH as ubuntu (not root) to staging:**
```jsonc
{
  "ssh": [
    {
      "action": "accept",
      "src":    ["group:devs"],
      "dst":    ["tag:staging"],
      "users":  ["ubuntu"]
    }
  ]
}
```

**Users can SSH to their own devices:**
```jsonc
{
  "ssh": [
    {
      "action": "accept",
      "src":    ["autogroup:member"],
      "dst":    ["autogroup:self"],
      "users":  ["autogroup:nonroot"]
    }
  ]
}
```

---

## Policy Tests

Embed test cases in the policy file to validate rules:

```jsonc
{
  "tests": [
    {
      "src":    "alice@example.com",
      "accept": ["tag:prod:22", "tag:prod:443"],
      "deny":   ["tag:db:5432"]
    },
    {
      "src":    "carol@example.com",
      "accept": ["tag:dev:*"],
      "deny":   ["tag:prod:22"]
    },
    {
      "src":    "tag:ci",
      "accept": ["tag:prod:22"],
      "deny":   ["tag:db:3306"]
    }
  ]
}
```

Tests are evaluated by the Tailscale control plane when you save the policy. A failing test blocks the policy update.

---

## Full Production Example

```jsonc
{
  // Groups
  "groups": {
    "group:admins":   ["alice@example.com"],
    "group:devs":     ["carol@example.com", "dave@example.com"],
    "group:ci":       ["ci-bot@example.com"],
    "group:ops":      ["group:admins", "eve@example.com"]
  },

  // Tag ownership
  "tagOwners": {
    "tag:prod":       ["group:admins"],
    "tag:staging":    ["group:ops"],
    "tag:dev":        ["group:devs", "group:ops"],
    "tag:exit-node":  ["group:admins"],
    "tag:ci":         ["group:ci", "group:admins"],
    "tag:monitoring": ["group:ops"]
  },

  // Named subnets
  "hosts": {
    "office-lan": "10.10.0.0/16",
    "homelab":    "192.168.100.0/24"
  },

  // Route auto-approval
  "autoApprovers": {
    "exitNode": ["tag:exit-node"],
    "routes": {
      "10.10.0.0/16":    ["group:admins"],
      "192.168.100.0/24": ["group:admins"]
    }
  },

  // Access rules
  "acls": [
    // Admins: unrestricted
    {"action": "accept", "src": ["group:admins"],     "dst": ["*:*"]},

    // Ops: SSH + monitoring to all tagged servers
    {"action": "accept", "src": ["group:ops"],        "dst": ["tag:prod:22,9090", "tag:staging:22,9090"]},

    // Devs: SSH to dev/staging, no prod
    {"action": "accept", "src": ["group:devs"],       "dst": ["tag:dev:*", "tag:staging:22,80,443,5432"]},

    // CI runners: deploy to staging and prod
    {"action": "accept", "src": ["tag:ci"],           "dst": ["tag:staging:22", "tag:prod:22"]},

    // Prod servers: talk to each other (DB replication, service mesh)
    {"action": "accept", "src": ["tag:prod"],         "dst": ["tag:prod:*"]},

    // Monitoring can scrape everything
    {"action": "accept", "src": ["tag:monitoring"],   "dst": ["tag:prod:9090", "tag:staging:9090", "tag:dev:9090"]},

    // All members: HTTPS to prod web
    {"action": "accept", "src": ["autogroup:member"], "dst": ["tag:prod:443,80"]},

    // Office LAN access via subnet router
    {"action": "accept", "src": ["autogroup:member"], "dst": ["office-lan:*"]}
  ],

  // SSH rules
  "ssh": [
    // Admins: SSH to everything, check every 24h
    {
      "action":      "check",
      "src":         ["group:admins"],
      "dst":         ["tag:prod", "tag:staging", "tag:dev"],
      "users":       ["root", "ubuntu"],
      "checkPeriod": "24h"
    },
    // Devs: SSH to dev/staging as ubuntu
    {
      "action": "accept",
      "src":    ["group:devs"],
      "dst":    ["tag:dev", "tag:staging"],
      "users":  ["ubuntu"]
    }
  ],

  // Validation tests
  "tests": [
    {
      "src":    "alice@example.com",
      "accept": ["tag:prod:22", "tag:staging:*", "tag:dev:*"]
    },
    {
      "src":    "carol@example.com",
      "accept": ["tag:dev:22", "tag:staging:5432"],
      "deny":   ["tag:prod:22", "tag:prod:5432"]
    },
    {
      "src":    "tag:ci",
      "accept": ["tag:staging:22", "tag:prod:22"],
      "deny":   ["tag:prod:443", "tag:monitoring:9090"]
    }
  ]
}
```

---

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| Tag not in `tagOwners` | Cannot apply tag via `--advertise-tags` | Add tag to `tagOwners` |
| Missing port in `dst` | Policy editor error | Always include port: `tag:server:22` not `tag:server` |
| ACL allows but `--shields-up` is set | Connection blocked | Remove `--shields-up` or remove device from shielded group |
| User email wrong case | Rule never matches | Email matching is case-sensitive, verify in admin console |
| Route not approved | Subnet unreachable | Add to `autoApprovers.routes` or approve manually in console |
| `checkPeriod` used with `"accept"` | Policy error | `checkPeriod` is only valid with `"check"` action |
| Circular group reference | Policy save error | Groups can nest but not circularly |

---

## Useful Links

- ACL syntax reference: https://tailscale.com/kb/1337/acl-syntax
- Tailscale SSH: https://tailscale.com/kb/1193/tailscale-ssh
- autoApprovers: https://tailscale.com/kb/1018/acls#auto-approvers-for-routes-and-exit-nodes
- Tag-based access: https://tailscale.com/kb/1068/acl-tags
- Policy tests: https://tailscale.com/kb/1337/acl-syntax#tests
