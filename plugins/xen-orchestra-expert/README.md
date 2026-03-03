# xen-orchestra-expert

A Claude Code skill plugin providing expert guidance for Xen Orchestra (XO) and XCP-ng infrastructure management.

## What It Covers

- Xen Orchestra installation (from sources, XOA appliance, Docker)
- XCP-ng hypervisor pool management
- VM lifecycle: create, start, stop, snapshot, clone, migrate
- Backup strategies: full, delta, continuous replication, disaster recovery
- Storage management: NFS, iSCSI, SMB, local SR
- Networking: bonds, VLANs, bridges
- xo-cli command reference with filtering and jq recipes
- REST API and JSON-RPC API for automation and CI/CD
- Terraform and Ansible integration patterns
- Troubleshooting: HA, storage, networking, XAPI issues

## Plugin Structure

```
xen-orchestra-expert/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── skills/
│   └── xen-orchestra-expert/
│       ├── SKILL.md             # Main skill — loaded when XO topics are detected
│       └── references/
│           ├── xo-cli-reference.md   # Complete xo-cli command reference
│           └── xo-api-reference.md   # REST API + JSON-RPC API reference
├── commands/
│   └── xo-status.md             # /xo-status slash command
└── README.md
```

## Skill Activation

The `xen-orchestra-expert` skill activates when the user's message contains topics related to:

- Xen Orchestra / XO / XOA / xo-server / xo-web
- XCP-ng / XenServer / Xen hypervisor
- xo-cli commands
- VM management with Xen
- Backup jobs in XO
- XAPI / XCP pool management

## Commands

### /xo-status

Checks the health of a Xen Orchestra server and all connected pools. Outputs:
- Pool list and masters
- Host status (enabled/disabled, CPU, free memory)
- VM counts by power state
- SR usage with warnings above 85%
- Recent XAPI alerts
- Backup job health

## References

### xo-cli-reference.md

Complete reference for `xo-cli` covering:
- Installation and authentication
- VM commands (lifecycle, clone, snapshot, migrate, network, disks)
- Host commands (reboot, evacuate, maintenance mode)
- Pool commands (HA, master, updates)
- Storage commands (create NFS/iSCSI/SMB/local SRs, VDI resize)
- Backup commands (jobs, remotes, logs)
- Object filtering with `--list-objects` and jq recipes
- Batch operation patterns via shell loops

### xo-api-reference.md

REST API (`/rest/v0/`) and JSON-RPC API reference covering:
- Token authentication and API token management
- CRUD operations on VMs, hosts, pools, SRs, networks, VDIs
- VM action endpoints (start, stop, reboot, snapshot, suspend)
- Backup job creation and management via JSON-RPC
- Backup remote management
- Webhook and event subscription via WebSocket
- Bash helper functions for scripting
- Terraform provider and Ansible integration
- Error handling and rate limiting

## Author

Sergio Martinelli (biodoia@users.noreply.github.com)

## License

MIT
