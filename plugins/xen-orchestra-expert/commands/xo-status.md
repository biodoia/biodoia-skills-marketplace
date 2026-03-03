# /xo-status

Check the status of a Xen Orchestra server and all connected pools, hosts, and VMs.

## Usage

Run `/xo-status` when you want a quick overview of the XO environment: server health, connected pools, host status, VM counts, SR usage, and recent alerts.

## What This Command Does

When the user invokes `/xo-status`, gather and display the following information:

### 1. XO Server Health

```bash
# Check xo-server process (from-sources install)
systemctl --user status xo-server
# or PM2
pm2 status xo-server

# Check XOA appliance
systemctl status xo-server

# Test API reachability
curl -s https://xo.example.com/rest/v0/ -o /dev/null -w "%{http_code}"
```

### 2. Authentication

```bash
# Authenticate and store token
TOKEN=$(curl -s -X POST https://xo.example.com/rest/v0/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@admin.net","password":"yourpassword"}' \
  | jq -r '.token')
echo "Auth OK: ${TOKEN:0:12}..."
```

Or use xo-cli (uses stored credentials automatically):

```bash
xo-cli --list-objects type=pool | jq 'length' | xargs echo "Connected pools:"
```

### 3. Pool and Host Summary

```bash
# List all pools
echo "=== POOLS ==="
xo-cli --list-objects type=pool | jq '.[] | {uuid:.uuid, name:.name_label, master:.master}'

# List all hosts with status
echo "=== HOSTS ==="
xo-cli --list-objects type=host | jq '.[] | {
  name: .name_label,
  ip: .address,
  enabled: .enabled,
  power: .power_state,
  cpus: .cpu_info.cpu_count,
  memFreeGB: (.memory_free // 0 | . / 1073741824 | floor)
}'
```

### 4. VM Summary

```bash
echo "=== VMs ==="
xo-cli --list-objects type=VM | jq '
  group_by(.power_state) |
  map({state: .[0].power_state, count: length}) |
  .[]
'

# Running VMs
echo "--- Running VMs ---"
xo-cli --list-objects type=VM power_state=Running | jq '.[] | {name:.name_label, host:.resident_on}'
```

### 5. Storage Repository Usage

```bash
echo "=== STORAGE ==="
xo-cli --list-objects type=SR | jq '
  .[] |
  select(.physical_size > 0) |
  {
    name: .name_label,
    type: .type,
    usedGB: (.physical_utilisation / 1073741824 | floor),
    totalGB: (.physical_size / 1073741824 | floor),
    pctUsed: ((.physical_utilisation / .physical_size * 100) | floor)
  }
'
```

Flag SRs over 85% utilization as warnings.

### 6. Recent Alerts/Messages

```bash
echo "=== RECENT ALERTS ==="
xo-cli --list-objects type=message | jq '.[] | {name:.name, body:.body, timestamp:.timestamp}' | head -20
```

### 7. Backup Job Health (if applicable)

```bash
echo "=== BACKUP JOBS ==="
xo-cli backupNg.getAllJobs | jq '.[] | {name:.name, mode:.mode, enabled:(.schedules | to_entries | .[].value.enabled)}'
```

## Full Status Script

Save and run for a complete one-shot status report:

```bash
#!/bin/bash
set -euo pipefail

XO_HOST="${XO_HOST:-https://xo.example.com}"
XO_USER="${XO_USER:-admin@admin.net}"
XO_PASS="${XO_PASS:-yourpassword}"

echo ""
echo "=================================================="
echo "  XEN ORCHESTRA STATUS REPORT"
echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "  Server: $XO_HOST"
echo "=================================================="

# Authenticate
TOKEN=$(curl -sk -X POST "$XO_HOST/rest/v0/sessions" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$XO_USER\",\"password\":\"$XO_PASS\"}" \
  | jq -r '.token // empty')

if [ -z "$TOKEN" ]; then
  echo "ERROR: Authentication failed."
  exit 1
fi

api() { curl -sk -H "Authorization: Bearer $TOKEN" "$XO_HOST/rest/v0/$1"; }

echo ""
echo "--- POOLS ---"
api pools | jq -r '.[] | "  Pool: \(.name_label) (master: \(.master))"'

echo ""
echo "--- HOSTS ---"
api hosts | jq -r '.[] | "  \(if .enabled then "UP  " else "DOWN" end) \(.name_label) [\(.address)] CPUs:\(.cpu_info.cpu_count) FreeMem:\(.memory_free // 0 | . / 1073741824 | floor)GB"'

echo ""
echo "--- VMs ---"
api "vms?power_state=Running" | jq -r 'length | "  Running: \(.)"'
api "vms?power_state=Halted"  | jq -r 'length | "  Halted:  \(.)"'
api "vms?power_state=Paused"  | jq -r 'length | "  Paused:  \(.)"' 2>/dev/null || true

echo ""
echo "--- STORAGE ---"
api srs | jq -r '
  .[] |
  select(.physical_size > 0) |
  .pct = (.physical_utilisation / .physical_size * 100 | floor) |
  "  \(if .pct > 85 then "WARN" else "OK  " end) \(.name_label) [\(.type)] \(.physical_utilisation / 1073741824 | floor)GB / \(.physical_size / 1073741824 | floor)GB (\(.pct)%)"
'

echo ""
echo "=================================================="
echo "  Status check complete."
echo "=================================================="
```

Run with environment variables:

```bash
XO_HOST="https://xo.example.com" \
XO_USER="admin@admin.net" \
XO_PASS="secret" \
bash xo-status.sh
```

## xo-cli Quick Check (no script needed)

```bash
# One-liner status summary
echo "Pools: $(xo-cli --list-objects type=pool | jq length)" && \
echo "Hosts UP: $(xo-cli --list-objects type=host | jq '[.[] | select(.enabled==true)] | length')" && \
echo "VMs Running: $(xo-cli --list-objects type=VM power_state=Running | jq length)" && \
echo "VMs Halted: $(xo-cli --list-objects type=VM power_state=Halted | jq length)"
```

## Interpreting Results

| Indicator | Action |
|-----------|--------|
| Host `enabled: false` | Host is in maintenance mode or unreachable — investigate IPMI/iDRAC |
| SR utilization > 85% | Clean orphaned snapshots, expand SR, or migrate VMs |
| VM `power_state: Paused` unexpectedly | Check if host ran out of memory; unpause and investigate |
| No pools listed | xo-server lost XAPI connection — check Settings > Servers in XO Web UI |
| Auth failure | Token expired or credentials changed — re-register xo-cli or rotate API token |
| Backup job `enabled: false` | Schedule was disabled — re-enable from Backup section of XO Web UI |
