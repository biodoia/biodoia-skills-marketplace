# xo-cli Complete Reference

xo-cli is the official command-line interface for Xen Orchestra. It communicates with xo-server via the JSON-RPC API over WebSockets.

## Installation

```bash
npm install -g xo-cli
# or
yarn global add xo-cli
```

Requires Node.js 16+. Verify:

```bash
xo-cli --version
```

## Authentication

### Register a Server

```bash
xo-cli --register https://xo.example.com admin@admin.net password
```

This writes credentials and a session token to `~/.config/xo-cli/config.json`. Subsequent commands reuse this token automatically.

Options:
- `--allowUnauthorized` / `-au`: accept self-signed TLS certificates
- `--unregister`: remove stored credentials

```bash
# Self-signed cert
xo-cli --register --allowUnauthorized https://192.168.1.50 admin@admin.net adminpass

# Remove registration
xo-cli --unregister
```

### Multiple Servers

xo-cli supports one active server at a time. To switch, re-register with `--register`.

### Token-Based Auth (API tokens)

Create a token in XO Web UI under My Account > Authentication Tokens. Then:

```bash
xo-cli --register https://xo.example.com --token <your-api-token>
```

## General Usage Patterns

```bash
# Call any JSON-RPC method
xo-cli <method> [param=value ...]

# List all available methods
xo-cli --list-commands

# Filter methods by keyword
xo-cli --list-commands | grep vm
xo-cli --list-commands | grep backup

# List objects (inventory query)
xo-cli --list-objects [type=<type>] [filter...]

# Output as JSON (pipe to jq)
xo-cli --list-objects type=VM | jq '.[] | {uuid:.uuid, name:.name_label}'

# Watch a task
xo-cli task.wait id=<task-uuid>
```

## Object Types

Use these with `--list-objects type=`:

| Type | Description |
|------|-------------|
| `VM` | Virtual machines (running/halted) |
| `VM-template` | Templates for creating VMs |
| `host` | XCP-ng hypervisor hosts |
| `pool` | XCP-ng pools (group of hosts) |
| `SR` | Storage repositories |
| `VDI` | Virtual disk images |
| `network` | Networks / bridges |
| `VIF` | Virtual network interfaces |
| `VBD` | Virtual block devices (disk attachments) |
| `PIF` | Physical network interfaces |
| `task` | XAPI tasks |
| `message` | System messages/alerts |

## VM Commands

### Lifecycle

```bash
# Start VM
xo-cli vm.start id=<vm-uuid>

# Start paused VM
xo-cli vm.start id=<vm-uuid> paused=true

# Stop VM (clean ACPI shutdown)
xo-cli vm.stop id=<vm-uuid>

# Force stop (hard power off)
xo-cli vm.stop id=<vm-uuid> force=true

# Reboot (clean)
xo-cli vm.reboot id=<vm-uuid>

# Force reboot
xo-cli vm.reboot id=<vm-uuid> force=true

# Suspend (save state to disk)
xo-cli vm.suspend id=<vm-uuid>

# Resume from suspend
xo-cli vm.resume id=<vm-uuid>

# Pause (freeze in RAM)
xo-cli vm.pause id=<vm-uuid>
```

### Create and Delete

```bash
# Create VM from template
xo-cli vm.create \
  name_label="web-server-01" \
  template=<template-uuid> \
  VCPUs_at_startup=4 \
  VCPUs_max=4 \
  memory_dynamic_max=4294967296 \
  memory_dynamic_min=2147483648 \
  memory_static_max=4294967296

# Delete VM (must be halted)
xo-cli vm.delete id=<vm-uuid>

# Delete and destroy disks
xo-cli vm.delete id=<vm-uuid> deleteDisks=true
```

### Clone and Copy

```bash
# Linked clone (COW, shares base disk blocks)
xo-cli vm.copy id=<vm-uuid> name_label="vm-clone" full_copy=false

# Full independent copy
xo-cli vm.copy id=<vm-uuid> name_label="vm-full-copy" full_copy=true

# Copy to specific SR
xo-cli vm.copy id=<vm-uuid> name_label="vm-copy" full_copy=true sr=<sr-uuid>
```

### Snapshots

```bash
# Create snapshot
xo-cli vm.snapshot id=<vm-uuid> name_label="pre-upgrade-$(date +%Y%m%d)"

# Revert VM to snapshot
xo-cli vm.revert id=<snapshot-uuid>

# Export snapshot as XVA
xo-cli vm.export id=<snapshot-uuid> > backup.xva

# Delete snapshot
xo-cli vm.delete id=<snapshot-uuid>

# List all snapshots
xo-cli --list-objects type=VM is_a_snapshot=true | jq '.[] | {uuid:.uuid, name:.name_label, parent:.snapshot_of}'
```

### Migrate

```bash
# Intra-pool live migration (no storage move)
xo-cli vm.migrate id=<vm-uuid> targetHost=<host-uuid>

# Intra-pool live migration with storage migration
xo-cli vm.migrate id=<vm-uuid> targetHost=<host-uuid> sr=<target-sr-uuid>

# Cross-pool migration
xo-cli vm.migrate id=<vm-uuid> \
  targetHost=<host-uuid> \
  migrationNetwork=<network-uuid> \
  sr=<sr-uuid>
```

### VM Configuration

```bash
# Set CPU count
xo-cli vm.set id=<vm-uuid> VCPUs_at_startup=8

# Set memory (bytes)
xo-cli vm.set id=<vm-uuid> memory_dynamic_max=8589934592

# Set name
xo-cli vm.set id=<vm-uuid> name_label="new-name"

# Set description
xo-cli vm.set id=<vm-uuid> name_description="Production web server"

# Set HA policy
xo-cli vm.set id=<vm-uuid> ha_restart_priority=restart

# Enable nested virtualization
xo-cli vm.set id=<vm-uuid> expNestedHvm=true

# Set boot order (cd = cdrom, d = disk, n = network)
xo-cli vm.set id=<vm-uuid> HVM_boot_params='{"order":"dc"}'
```

### Networking

```bash
# Add network interface (VIF)
xo-cli vm.createInterface id=<vm-uuid> network=<network-uuid>

# Add VIF with specific MAC
xo-cli vm.createInterface id=<vm-uuid> network=<network-uuid> mac="02:00:00:aa:bb:cc"

# Delete VIF
xo-cli vif.delete id=<vif-uuid>

# Connect/disconnect VIF at runtime
xo-cli vif.connect id=<vif-uuid>
xo-cli vif.disconnect id=<vif-uuid>
```

### Disk Management

```bash
# Create VDI and attach to VM
xo-cli disk.create \
  name_label="data-disk-01" \
  size=107374182400 \
  sr=<sr-uuid>

# Attach existing VDI to VM
xo-cli vm.attachDisk id=<vm-uuid> vdi=<vdi-uuid> mode=RW

# Detach disk
xo-cli vbd.delete id=<vbd-uuid>

# Resize VDI (VM must be halted or disk detached)
xo-cli vdi.resize id=<vdi-uuid> size=214748364800
```

## Host Commands

```bash
# List hosts
xo-cli --list-objects type=host | jq '.[] | {uuid:.uuid, name:.name_label, ip:.address}'

# Reboot host (evacuates VMs first if HA is on)
xo-cli host.reboot id=<host-uuid>

# Shutdown host
xo-cli host.shutdown id=<host-uuid>

# Enable/disable host (maintenance mode)
xo-cli host.disable id=<host-uuid>
xo-cli host.enable id=<host-uuid>

# Evacuate host (live-migrate all VMs off)
xo-cli host.evacuate id=<host-uuid>

# Detach from pool
xo-cli host.detach id=<host-uuid>

# Get host metrics
xo-cli --list-objects type=host_metrics

# Refresh host state
xo-cli host.refresh id=<host-uuid>
```

## Pool Commands

```bash
# List pools
xo-cli --list-objects type=pool

# Set default SR for pool
xo-cli pool.set id=<pool-uuid> default_SR=<sr-uuid>

# Set pool name
xo-cli pool.set id=<pool-uuid> name_label="production-pool"

# Set pool master
xo-cli pool.setMaster id=<host-uuid>

# Enable/disable HA
xo-cli pool.enableHa id=<pool-uuid> heartbeatSrs='["<sr-uuid>"]' ntol=1
xo-cli pool.disableHa id=<pool-uuid>

# Patch/update pool (triggers xapi-update)
xo-cli pool.installPatches id=<pool-uuid>
```

## Storage Commands

```bash
# List SRs
xo-cli --list-objects type=SR | jq '.[] | {uuid:.uuid, name:.name_label, type:.type, free:.physical_size}'

# Scan SR for new VDIs
xo-cli sr.scan id=<sr-uuid>

# Forget SR (detach, keep data)
xo-cli sr.forget id=<sr-uuid>

# Destroy SR (delete data)
xo-cli sr.destroy id=<sr-uuid>

# Create NFS SR
xo-cli sr.create \
  host=<host-uuid> \
  nameLabel="NAS-VMs" \
  type=nfs \
  deviceConfig='{"server":"192.168.1.100","serverpath":"/export/xcp"}'

# Create local storage SR
xo-cli sr.create \
  host=<host-uuid> \
  nameLabel="Local-LVM" \
  type=lvm \
  deviceConfig='{"device":"/dev/sdb"}'

# Create iSCSI SR
xo-cli sr.create \
  host=<host-uuid> \
  nameLabel="iSCSI-LUN" \
  type=lvmoiscsi \
  deviceConfig='{"target":"192.168.1.50","targetIQN":"iqn.2024-01.com.example:lun1","SCSIid":"<scsi-id>"}'

# Create SMB SR
xo-cli sr.create \
  host=<host-uuid> \
  nameLabel="SMB-Backup" \
  type=smb \
  deviceConfig='{"server":"\\\\192.168.1.100\\share","username":"user","password":"pass"}'
```

## Backup Commands

```bash
# List backup jobs
xo-cli backupNg.getAllJobs

# Get specific job
xo-cli backupNg.getJob id=<job-id>

# Run a backup job immediately
xo-cli backupNg.runJob id=<job-id>

# Delete a backup job
xo-cli backupNg.deleteJob id=<job-id>

# List backup logs
xo-cli backupNg.getLogs

# List remotes
xo-cli remote.getAll

# Test remote connectivity
xo-cli remote.test id=<remote-id>
```

## Filtering and Output Formatting

### Filter by Field

```bash
# VMs on a specific host
xo-cli --list-objects type=VM resident_on=<host-uuid>

# VMs in a specific pool
xo-cli --list-objects type=VM $pool=<pool-uuid>

# Powered-on VMs only
xo-cli --list-objects type=VM power_state=Running

# Templates only
xo-cli --list-objects type=VM is_a_template=true
```

### jq Recipes

```bash
# Get all VM names and UUIDs
xo-cli --list-objects type=VM | jq '.[] | {name:.name_label, uuid:.uuid}'

# Get VM count per host
xo-cli --list-objects type=VM | jq 'group_by(.resident_on) | map({host:.[0].resident_on, count:length})'

# Get SRs sorted by free space
xo-cli --list-objects type=SR | jq 'sort_by(.physical_utilisation) | .[] | {name:.name_label, usedGB:(.physical_utilisation/1073741824|floor), totalGB:(.physical_size/1073741824|floor)}'

# Get all running VMs with IP addresses
xo-cli --list-objects type=VM power_state=Running | jq '.[] | {name:.name_label, ips:[.addresses | to_entries[] | .value]}'

# Find VMs with no snapshots
xo-cli --list-objects type=VM is_a_snapshot=false is_a_template=false | jq '[.[] | select(.snapshots | length == 0)] | .[].name_label'
```

### Batch Operations via Shell Loop

```bash
# Stop all VMs with "test-" prefix
xo-cli --list-objects type=VM power_state=Running | \
  jq -r '.[] | select(.name_label | startswith("test-")) | .uuid' | \
  while read uuid; do
    echo "Stopping $uuid"
    xo-cli vm.stop id="$uuid"
  done

# Snapshot all production VMs
xo-cli --list-objects type=VM power_state=Running | \
  jq -r '.[] | select(.name_label | startswith("prod-")) | .uuid' | \
  while read uuid; do
    xo-cli vm.snapshot id="$uuid" name_label="auto-snap-$(date +%Y%m%d)"
  done
```

## Task Management

```bash
# List pending tasks
xo-cli --list-objects type=task

# Wait for a task to complete
xo-cli task.wait id=<task-uuid>

# Cancel a task
xo-cli task.destroy id=<task-uuid>
```

## Common UUIDs — How to Find Them

```bash
# Find VM UUID by name
xo-cli --list-objects type=VM | jq -r '.[] | select(.name_label=="my-vm") | .uuid'

# Find host UUID by IP
xo-cli --list-objects type=host | jq -r '.[] | select(.address=="192.168.1.10") | .uuid'

# Find SR UUID by name
xo-cli --list-objects type=SR | jq -r '.[] | select(.name_label=="NAS-VMs") | .uuid'

# Find network UUID by name
xo-cli --list-objects type=network | jq -r '.[] | select(.name_label=="VLAN-100") | .uuid'
```
