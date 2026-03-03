# Xen Orchestra REST API Reference

XO exposes a REST API at `https://<xo-host>/rest/v0/`. It covers VMs, hosts, pools, storage, networks, and backup jobs. The JSON-RPC API (used by xo-cli) is at `/api/` and covers more methods, but the REST API is simpler for scripting and external integrations.

## Authentication

### Session Token (recommended)

```bash
# Create session — returns a token
curl -s -X POST https://xo.example.com/rest/v0/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@admin.net","password":"yourpassword"}' \
  | jq -r '.token'

# Store it
TOKEN=$(curl -s -X POST https://xo.example.com/rest/v0/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@admin.net","password":"yourpassword"}' \
  | jq -r '.token')

# Use in all subsequent requests
curl -H "Authorization: Bearer $TOKEN" https://xo.example.com/rest/v0/vms
```

### API Tokens (persistent, non-expiring)

Create API tokens from XO Web UI: My Account > Authentication Tokens > Add token.

```bash
curl -H "Authorization: Bearer <api-token>" https://xo.example.com/rest/v0/vms
```

API tokens do not expire (unless revoked). Use for automation and CI/CD pipelines.

### Cookie-Based Auth (browser sessions)

Not recommended for scripting. The REST API accepts the `authenticationToken` cookie set by the web UI, but tokens are short-lived.

### Self-Signed Certificates

```bash
# Skip TLS verification
curl -k -H "Authorization: Bearer $TOKEN" https://xo.example.com/rest/v0/vms

# Or trust your CA
curl --cacert /path/to/ca.crt -H "Authorization: Bearer $TOKEN" https://xo.example.com/rest/v0/vms
```

## Base URL and Versioning

```
https://<xo-host>/rest/v0/
```

All responses are JSON. The API version is currently `v0`. There is no stable v1 yet as of 2024.

## Common Headers

```http
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
```

## Resource Endpoints

### VMs

```bash
# List all VMs
GET /rest/v0/vms

# Get specific VM
GET /rest/v0/vms/<vm-uuid>

# List VM fields (discovery)
GET /rest/v0/vms/<vm-uuid>?fields=uuid,name_label,power_state,VCPUs_at_startup,memory_dynamic_max

# Filter running VMs
GET /rest/v0/vms?power_state=Running

# Filter by pool
GET /rest/v0/vms?$pool=<pool-uuid>
```

```bash
# Concrete examples
curl -H "Authorization: Bearer $TOKEN" \
  "https://xo.example.com/rest/v0/vms?power_state=Running" | jq '.'

# Get specific VM
curl -H "Authorization: Bearer $TOKEN" \
  "https://xo.example.com/rest/v0/vms/<vm-uuid>" | jq '.'
```

### VM Actions

```bash
# Start VM
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/start" \
  -H "Authorization: Bearer $TOKEN"

# Stop VM (clean)
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/clean_shutdown" \
  -H "Authorization: Bearer $TOKEN"

# Force stop
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/hard_shutdown" \
  -H "Authorization: Bearer $TOKEN"

# Reboot (clean)
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/clean_reboot" \
  -H "Authorization: Bearer $TOKEN"

# Force reboot
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/hard_reboot" \
  -H "Authorization: Bearer $TOKEN"

# Suspend
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/suspend" \
  -H "Authorization: Bearer $TOKEN"

# Resume
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/actions/resume" \
  -H "Authorization: Bearer $TOKEN"

# Create snapshot
curl -X POST "https://xo.example.com/rest/v0/vms/<vm-uuid>/snapshots" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name_label":"snap-before-deploy"}'
```

### Hosts

```bash
# List all hosts
GET /rest/v0/hosts

# Get specific host
GET /rest/v0/hosts/<host-uuid>

# Filter by pool
GET /rest/v0/hosts?$pool=<pool-uuid>
```

```bash
# List hosts with key fields
curl -H "Authorization: Bearer $TOKEN" \
  "https://xo.example.com/rest/v0/hosts?fields=uuid,name_label,address,enabled" | jq '.'

# Reboot host
curl -X POST "https://xo.example.com/rest/v0/hosts/<host-uuid>/actions/reboot" \
  -H "Authorization: Bearer $TOKEN"

# Enable host (exit maintenance mode)
curl -X POST "https://xo.example.com/rest/v0/hosts/<host-uuid>/actions/enable" \
  -H "Authorization: Bearer $TOKEN"

# Disable host (enter maintenance mode)
curl -X POST "https://xo.example.com/rest/v0/hosts/<host-uuid>/actions/disable" \
  -H "Authorization: Bearer $TOKEN"

# Evacuate host (migrate all VMs off)
curl -X POST "https://xo.example.com/rest/v0/hosts/<host-uuid>/actions/evacuate" \
  -H "Authorization: Bearer $TOKEN"
```

### Pools

```bash
# List pools
GET /rest/v0/pools

# Get specific pool
GET /rest/v0/pools/<pool-uuid>
```

```bash
curl -H "Authorization: Bearer $TOKEN" \
  "https://xo.example.com/rest/v0/pools" | jq '.[] | {uuid:.uuid, name:.name_label, master:.master}'
```

### Storage Repositories (SRs)

```bash
# List all SRs
GET /rest/v0/srs

# Get specific SR
GET /rest/v0/srs/<sr-uuid>

# Filter by pool
GET /rest/v0/srs?$pool=<pool-uuid>
```

```bash
# List SRs with usage stats
curl -H "Authorization: Bearer $TOKEN" \
  "https://xo.example.com/rest/v0/srs?fields=uuid,name_label,physical_size,physical_utilisation,type" \
  | jq '.[] | {name:.name_label, type:.type, usedGB:(.physical_utilisation/1073741824|floor), totalGB:(.physical_size/1073741824|floor)}'
```

### Networks

```bash
# List all networks
GET /rest/v0/networks

# Get specific network
GET /rest/v0/networks/<network-uuid>
```

```bash
# Create a VLAN network
curl -X POST "https://xo.example.com/rest/v0/networks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pool": "<pool-uuid>",
    "name_label": "VLAN-200",
    "VLAN": 200,
    "MTU": 1500
  }'

# Delete network
curl -X DELETE "https://xo.example.com/rest/v0/networks/<network-uuid>" \
  -H "Authorization: Bearer $TOKEN"
```

### VDIs (Virtual Disks)

```bash
# List VDIs
GET /rest/v0/vdis

# Get specific VDI
GET /rest/v0/vdis/<vdi-uuid>

# Create VDI
curl -X POST "https://xo.example.com/rest/v0/vdis" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name_label": "data-disk-01",
    "size": 107374182400,
    "SR": "<sr-uuid>",
    "type": "user"
  }'

# Delete VDI
curl -X DELETE "https://xo.example.com/rest/v0/vdis/<vdi-uuid>" \
  -H "Authorization: Bearer $TOKEN"
```

### Tasks

```bash
# List pending tasks
GET /rest/v0/tasks

# Get task status
GET /rest/v0/tasks/<task-uuid>

# Cancel task
curl -X DELETE "https://xo.example.com/rest/v0/tasks/<task-uuid>" \
  -H "Authorization: Bearer $TOKEN"
```

```bash
# Poll task until complete
watch -n 2 "curl -s -H 'Authorization: Bearer $TOKEN' \
  'https://xo.example.com/rest/v0/tasks/<task-uuid>' | jq '{status:.status,progress:.progress}'"
```

## Backup Job Management

Backup jobs are managed via the JSON-RPC API (not the REST API). Use xo-cli or direct JSON-RPC calls.

### List Backup Jobs (JSON-RPC)

```bash
curl -s -X POST https://xo.example.com/api/ \
  -H "Content-Type: application/json" \
  -H "Cookie: authenticationToken=<token>" \
  -d '{
    "jsonrpc": "2.0",
    "method": "backupNg.getAllJobs",
    "params": {},
    "id": 1
  }' | jq '.result'
```

### Create Backup Job (JSON-RPC)

```bash
curl -s -X POST https://xo.example.com/api/ \
  -H "Content-Type: application/json" \
  -H "Cookie: authenticationToken=<token>" \
  -d '{
    "jsonrpc": "2.0",
    "method": "backupNg.createJob",
    "params": {
      "name": "Daily VM Backup",
      "mode": "delta",
      "vms": {"id": {"__or": ["<vm-uuid-1>", "<vm-uuid-2>"]}},
      "settings": {
        "": {
          "deleteFirst": false,
          "exportRetention": 7,
          "snapshotRetention": 3,
          "reportWhen": "failure",
          "remotes": {"<remote-id>": {}}
        }
      },
      "schedules": {
        "daily": {
          "cron": "0 2 * * *",
          "timezone": "Europe/Rome",
          "enabled": true
        }
      }
    },
    "id": 2
  }' | jq '.result'
```

### Run Backup Job

```bash
curl -s -X POST https://xo.example.com/api/ \
  -H "Content-Type: application/json" \
  -H "Cookie: authenticationToken=<token>" \
  -d '{
    "jsonrpc": "2.0",
    "method": "backupNg.runJob",
    "params": {"id": "<job-id>"},
    "id": 3
  }'
```

### Delete Backup Job

```bash
curl -s -X POST https://xo.example.com/api/ \
  -H "Content-Type: application/json" \
  -H "Cookie: authenticationToken=<token>" \
  -d '{
    "jsonrpc": "2.0",
    "method": "backupNg.deleteJob",
    "params": {"id": "<job-id>"},
    "id": 4
  }'
```

### List Backup Remotes

```bash
curl -s -X POST https://xo.example.com/api/ \
  -H "Content-Type: application/json" \
  -H "Cookie: authenticationToken=<token>" \
  -d '{
    "jsonrpc": "2.0",
    "method": "remote.getAll",
    "params": {},
    "id": 5
  }' | jq '.result'
```

### Create Backup Remote

```bash
curl -s -X POST https://xo.example.com/api/ \
  -H "Content-Type: application/json" \
  -H "Cookie: authenticationToken=<token>" \
  -d '{
    "jsonrpc": "2.0",
    "method": "remote.create",
    "params": {
      "name": "NAS-Backups",
      "url": "nfs://192.168.1.100//backups/xo",
      "enabled": true
    },
    "id": 6
  }'
```

## Webhook / Event Integration

XO does not have native webhooks in the REST API, but you can poll the task endpoint or use the JSON-RPC event subscription.

### Subscribe to XAPI Events (JSON-RPC, WebSocket)

```javascript
// Node.js example using ws
const WebSocket = require('ws')
const ws = new WebSocket('wss://xo.example.com/api/', {
  rejectUnauthorized: false
})

ws.on('open', () => {
  // Authenticate
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'session.signIn',
    params: { email: 'admin@admin.net', password: 'pass' },
    id: 1
  }))
})

ws.on('message', (data) => {
  const msg = JSON.parse(data)
  if (msg.id === 1) {
    // Subscribe to object changes
    ws.send(JSON.stringify({
      jsonrpc: '2.0',
      method: 'xo.getAllObjects',
      params: { filter: { type: 'VM' } },
      id: 2
    }))
  }
  console.log(JSON.stringify(msg, null, 2))
})
```

### Polling Pattern for CI/CD

```bash
#!/bin/bash
# Wait for VM to reach Running state
VM_UUID="<vm-uuid>"
TOKEN="<token>"
XO_HOST="https://xo.example.com"

echo "Starting VM..."
curl -s -X POST "$XO_HOST/rest/v0/vms/$VM_UUID/actions/start" \
  -H "Authorization: Bearer $TOKEN"

echo "Waiting for VM to reach Running state..."
while true; do
  STATE=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "$XO_HOST/rest/v0/vms/$VM_UUID" | jq -r '.power_state')
  echo "State: $STATE"
  if [ "$STATE" = "Running" ]; then
    echo "VM is running."
    break
  fi
  sleep 5
done
```

## Automation Patterns

### Bash Helper Functions

```bash
# Source this file in your scripts

XO_HOST="https://xo.example.com"
XO_TOKEN=""

xo_auth() {
  local email="$1" pass="$2"
  XO_TOKEN=$(curl -s -X POST "$XO_HOST/rest/v0/sessions" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$pass\"}" \
    | jq -r '.token')
  echo "Authenticated. Token: ${XO_TOKEN:0:8}..."
}

xo_get() {
  curl -s -H "Authorization: Bearer $XO_TOKEN" "$XO_HOST/rest/v0/$1"
}

xo_post() {
  curl -s -X POST -H "Authorization: Bearer $XO_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$2" "$XO_HOST/rest/v0/$1"
}

xo_vm_start() {
  xo_post "vms/$1/actions/start" '{}'
}

xo_vm_stop() {
  xo_post "vms/$1/actions/clean_shutdown" '{}'
}

xo_vm_snapshot() {
  local uuid="$1" name="$2"
  xo_post "vms/$uuid/snapshots" "{\"name_label\":\"$name\"}"
}

xo_find_vm() {
  xo_get "vms" | jq -r --arg n "$1" '.[] | select(.name_label==$n) | .uuid'
}
```

### Terraform Integration

Terraform provider `terra-farm/xenorchestra` can provision XO resources:

```hcl
provider "xenorchestra" {
  url      = "wss://xo.example.com"
  username = "admin@admin.net"
  password = var.xo_password
  insecure = false
}

resource "xenorchestra_vm" "web" {
  name_label  = "web-server"
  template    = data.xenorchestra_template.debian.id
  network {
    network_id = data.xenorchestra_network.vlan100.id
  }
  disk {
    sr_id = data.xenorchestra_sr.nas.id
    name_label = "root"
    size = 21474836480
  }
}
```

### Ansible Integration

Use `community.general.xenserver_guest` for Ansible-based VM management, or call xo-cli directly via `ansible.builtin.command`.

```yaml
- name: Start XO VM
  ansible.builtin.command:
    cmd: "xo-cli vm.start id={{ vm_uuid }}"
  delegate_to: xo-server-host
```

## Error Handling

REST API returns standard HTTP status codes:

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No content (delete success) |
| 400 | Bad request (invalid params) |
| 401 | Unauthorized (bad/expired token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Resource not found |
| 409 | Conflict (resource already exists) |
| 500 | Internal server error |

JSON-RPC errors follow the JSON-RPC 2.0 spec with `error.code` and `error.message`.

```bash
# Check for errors in response
RESULT=$(curl -s -H "Authorization: Bearer $TOKEN" "$XO_HOST/rest/v0/vms/$UUID")
if echo "$RESULT" | jq -e '.error' > /dev/null 2>&1; then
  echo "Error: $(echo $RESULT | jq -r '.error.message')"
  exit 1
fi
```

## Rate Limiting and Concurrency

XO does not enforce strict API rate limits, but XAPI on XCP-ng hosts has internal task queue limits. Avoid issuing hundreds of concurrent VM operations. Implement concurrency control in scripts:

```bash
# Use GNU parallel with concurrency limit
xo-cli --list-objects type=VM power_state=Running | \
  jq -r '.[].uuid' | \
  parallel -j 4 xo-cli vm.snapshot id={} name_label="bulk-snap-$(date +%Y%m%d)"
```
