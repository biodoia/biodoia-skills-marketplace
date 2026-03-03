---
name: xen-orchestra-expert
description: Use when managing Xen Orchestra (XO), XCP-ng hypervisors, creating/managing VMs, configuring backups, using xo-cli, or automating infrastructure with Xen Orchestra REST API. Also use when the user mentions "xen orchestra", "XO", "XCP-ng", "xo-cli", "VM management", "xo-server", "xo-web", or virtualization with Xen.
---

# Xen Orchestra Expert

## Overview

Xen Orchestra (XO) is the official management platform for XCP-ng and XenServer hypervisors. It provides a web UI, a REST API, a JSON-RPC API, and a CLI tool (`xo-cli`). XCP-ng is the open-source XenServer fork maintained by Vates, the same company behind XO.

The stack:
- **XCP-ng**: the hypervisor (bare-metal, runs on servers)
- **xo-server**: the Node.js backend that connects to XCP-ng pools via XAPI
- **xo-web**: the React frontend served by xo-server
- **xo-cli**: the CLI that communicates with xo-server's JSON-RPC API
- **XOA**: the official turnkey virtual appliance (free tier + paid plans)

## Installation Methods

### From Sources (community edition, fully free)

```bash
# Install Node.js 20+ via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Install yarn
npm install -g yarn

# Clone and build
git clone https://github.com/vatesfr/xen-orchestra
cd xen-orchestra
yarn
yarn build

# Start xo-server
cd packages/xo-server
cp sample.config.toml .xo-server.toml
# Edit .xo-server.toml: set hostname, port, admin credentials
node dist/cli.mjs
```

Keep the process alive with PM2 or a systemd unit.

### XOA Appliance (official, recommended for production)

Download the XVA from https://xen-orchestra.com/#!/xoa and import it into XCP-ng:

```bash
xe vm-import filename=xoa.xva
```

Then run the first-run wizard from the console. XOA Free tier covers basic management. Premium plans unlock backups, ACLs, and advanced features.

### Docker (community, unofficial)

```bash
docker run -d \
  --name xo-server \
  -p 80:80 \
  -v xo-data:/var/lib/xo-server \
  ezka77/xen-orchestra-ce:latest
```

Not recommended for production. Use from-sources or XOA for stability.

## xo-cli Setup and Authentication

Install globally:

```bash
npm install -g xo-cli
```

Register against your XO server:

```bash
xo-cli --register https://xo.example.com admin@admin.net password
# Stores token in ~/.config/xo-cli/config.json
```

For self-signed certs:

```bash
xo-cli --register --allowUnauthorized https://xo.example.com admin@admin.net password
```

List available methods:

```bash
xo-cli --list-commands
xo-cli --list-commands | grep vm
```

See full reference: `references/xo-cli-reference.md`

## VM Lifecycle

### Create a VM

```bash
# From template
xo-cli vm.create \
  name_label="my-vm" \
  template=<template-uuid> \
  VCPUs_at_startup=2 \
  memory_dynamic_max=2147483648

# Get template UUIDs
xo-cli --list-objects type=VM-template | jq '.[].uuid'
```

### Start / Stop / Reboot

```bash
xo-cli vm.start id=<vm-uuid>
xo-cli vm.stop id=<vm-uuid>            # clean shutdown
xo-cli vm.stop id=<vm-uuid> force=true # hard power off
xo-cli vm.reboot id=<vm-uuid>
xo-cli vm.reboot id=<vm-uuid> force=true
```

### Snapshot

```bash
# Create snapshot
xo-cli vm.snapshot id=<vm-uuid> name_label="snap-before-upgrade"

# List snapshots
xo-cli --list-objects type=VM is_a_snapshot=true

# Revert
xo-cli vm.revert id=<snapshot-uuid>

# Delete snapshot
xo-cli vm.delete id=<snapshot-uuid>
```

### Clone and Copy

```bash
# Full copy (independent clone)
xo-cli vm.copy id=<vm-uuid> name_label="cloned-vm" full_copy=true

# Linked clone (COW, fast, stays linked to base)
xo-cli vm.copy id=<vm-uuid> name_label="linked-clone" full_copy=false
```

### Migrate

```bash
# Live migrate within same pool (no storage migration)
xo-cli vm.migrate id=<vm-uuid> targetHost=<host-uuid>

# Cross-pool migration (XO premium or use REST API)
xo-cli vm.migrate id=<vm-uuid> targetHost=<host-uuid> \
  migrationNetwork=<network-uuid> \
  sr=<target-sr-uuid>
```

## Backup Strategies

Configure all backups from XO Web UI under Backup menu, or via the API. Backup jobs run on xo-server and pull data from XCP-ng.

### Full Backup

Full export of VM disk. Stored as XVA on a remote (NFS, SMB, S3). Large but self-contained. Schedule via UI or API.

```bash
# Trigger manual backup via API
curl -X POST https://xo.example.com/rest/v0/backups/jobs/<job-id>/run \
  -H "Authorization: Bearer <token>"
```

### Delta Backup

Incremental backups using XenServer changed block tracking (CBT). Only diffs are transferred after first full. Efficient for large disks. Requires XO premium.

- First run: full export
- Subsequent runs: only changed blocks
- Point-in-time restore available

### Continuous Replication (CR)

Replicates VMs from one pool to another in near-real-time using delta snapshots. Used for disaster recovery. The replica VM is kept powered off, ready to start if primary fails.

### Disaster Recovery (DR)

Similar to CR but explicitly designed for failover. Configure in XO Web UI under Backup > Disaster Recovery. Set RPO (recovery point objective) to match your schedule interval.

### Backup Remotes

Add remotes (NFS, SMB, S3, local) under Settings > Remotes:

```bash
# NFS remote example via API
curl -X POST https://xo.example.com/rest/v0/remotes \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"nas-backup","url":"nfs://192.168.1.100//backups/xo"}'
```

## Storage Management

### Storage Repositories (SR)

An SR is a storage container (pool, LUN, NFS share) that holds VDIs (virtual disk images).

```bash
# List SRs
xo-cli --list-objects type=SR

# Scan SR (detect new disks)
xo-cli sr.scan id=<sr-uuid>

# Forget SR (detach without destroying)
xo-cli sr.forget id=<sr-uuid>

# Destroy SR (deletes data)
xo-cli sr.destroy id=<sr-uuid>
```

### Create NFS SR

```bash
xo-cli sr.create \
  host=<host-uuid> \
  nameLabel="NFS-backup" \
  type=nfs \
  deviceConfig='{"server":"192.168.1.100","serverpath":"/export/vms"}'
```

### Create iSCSI SR

```bash
xo-cli sr.create \
  host=<host-uuid> \
  nameLabel="iSCSI-SR" \
  type=lvmoiscsi \
  deviceConfig='{"target":"192.168.1.50","targetIQN":"iqn.2024-01.com.example:storage","SCSIid":"<id>"}'
```

### VDI Operations

```bash
# List VDIs
xo-cli --list-objects type=VDI

# Resize VDI
xo-cli vdi.resize id=<vdi-uuid> size=53687091200  # 50 GB in bytes
```

## Networking

### List Networks

```bash
xo-cli --list-objects type=network
```

### Create VLAN

In XO Web UI: Home > Networks > Add Network > select host/pool, set VLAN tag.

Via API:

```bash
curl -X POST https://xo.example.com/rest/v0/networks \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"pool":"<pool-uuid>","name":"VLAN-100","vlan":100}'
```

### Create Bond

Bonds aggregate multiple NICs for redundancy or throughput. Create from XO Web UI under Home > Hosts > [Host] > Network tab > Add Bond. Choose LACP, active-backup, or balance-slb mode.

### Add VIF to VM

```bash
xo-cli vm.createInterface \
  id=<vm-uuid> \
  network=<network-uuid> \
  mac=""  # empty for auto-assign
```

## REST API Basics

XO exposes a REST API at `https://xo.example.com/rest/v0/`.

### Authentication

```bash
# Get token (store and reuse)
curl -X POST https://xo.example.com/rest/v0/sessions \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@admin.net","password":"yourpassword"}'
# Response: {"token": "..."}

# Use token in all subsequent requests
curl https://xo.example.com/rest/v0/vms \
  -H "Authorization: Bearer <token>"
```

### Common Endpoints

| Resource | Endpoint |
|---|---|
| VMs | `GET /rest/v0/vms` |
| Hosts | `GET /rest/v0/hosts` |
| Pools | `GET /rest/v0/pools` |
| SRs | `GET /rest/v0/srs` |
| Networks | `GET /rest/v0/networks` |
| Tasks | `GET /rest/v0/tasks` |

Full reference: `references/xo-api-reference.md`

## Troubleshooting

### xo-server not connecting to pool

1. Check XAPI is reachable: `curl -k https://<xcp-host>/`
2. Verify credentials in XO Web UI > Settings > Servers
3. Check xo-server logs: `journalctl -u xo-server -f` or PM2 logs
4. Test from xo-server host: `curl -k https://<xcp-host>/session`

### VM stuck in unknown/halted state

```bash
# Force state refresh
xo-cli host.refresh id=<host-uuid>

# Check XAPI tasks on XCP-ng host
xe task-list
xe task-cancel uuid=<task-uuid>
```

### Storage full / SR in emergency mode

```bash
# Check SR usage
xo-cli --list-objects type=SR | jq '.[] | {name:.name_label, free:.physical_size}'

# Clean orphaned snapshots
# XO Web: Health > Orphaned snapshots

# Delete old snapshots via CLI
xo-cli vm.delete id=<snapshot-uuid>
```

### High Availability (HA) split-brain

HA requires a heartbeat SR (iSCSI or FC recommended). If hosts lose quorum:
1. Disable HA from XO or `xe pool-ha-disable`
2. Investigate network and storage connectivity
3. Re-enable HA after root cause resolution

### XCP-ng host unreachable after update

Boot into rescue mode from IPMI/iDRAC. Check `/var/log/xensource.log` on the host. Roll back using Xen Boot Menu (select previous kernel from GRUB).

## XCP-ng Pool Management

### Pool Operations

```bash
# List pools
xo-cli --list-objects type=pool

# Add host to pool (from XO Web UI: Home > Add Host)
# Or via xe on master:
xe pool-join master-address=<master-ip> master-username=root master-password=<pass>

# Eject host from pool
xo-cli host.detach id=<host-uuid>

# Set pool master
xo-cli pool.setMaster id=<host-uuid>
```

### Updates and Patches

XCP-ng uses yum-based update system. Apply updates from XO Web UI under Patches, or directly on each host:

```bash
# On XCP-ng host
yum update -y
# Then reboot rolling (one host at a time, live-migrate VMs first)
```

Use XO's Rolling Pool Update feature (premium) to automate rolling reboots with VM migration.

### Pool GPU Passthrough

Enable VT-d/IOMMU in host BIOS. Then in XO Web UI: Host > PCI Devices > assign to VM. Or via xe:

```bash
xe vm-param-set uuid=<vm-uuid> other-config:pci=0/0000:01:00.0
```
