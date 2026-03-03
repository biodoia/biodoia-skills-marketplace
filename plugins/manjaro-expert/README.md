# manjaro-expert

A Claude Code plugin providing comprehensive Manjaro/Arch Linux system administration expertise: package management, AUR, systemd, filesystems, networking, user management, kernel/hardware, and troubleshooting.

## What This Plugin Does

When loaded, Claude gains deep knowledge about:

- Installing, removing, searching, and upgrading packages with pacman
- Building and managing AUR packages with yay, paru, or manual makepkg
- Configuring pacman.conf, mirrors, parallel downloads, and package holds
- Managing systemd services, timers, user units, and journal logs
- Partitioning, formatting, mounting, fstab, BTRFS operations
- NetworkManager, firewall (ufw/firewalld), SSH, DNS
- User management, permissions, sudoers, ACLs
- Kernel management with mhwd-kernel, GPU drivers with mhwd
- Desktop/display managers, Xorg vs Wayland, fonts
- System rescue via manjaro-chroot/arch-chroot, timeshift snapshots
- Diagnosing and fixing broken updates, boot failures, dependency conflicts

## Structure

```
manjaro-expert/
├── .claude-plugin/
│   └── plugin.json                              # Plugin metadata
├── skills/
│   └── manjaro-expert/
│       ├── SKILL.md                             # Core skill (auto-loaded by Claude)
│       └── references/
│           ├── pacman-cheatsheet.md             # Complete pacman/yay/paru reference
│           ├── systemd-recipes.md               # Unit templates, timers, journal mgmt
│           └── troubleshooting-guide.md         # Common issues with step-by-step fixes
├── commands/
│   └── manjaro-help.md                          # /manjaro-help slash command
└── README.md
```

## Skills

### `manjaro-expert`

Triggered when the user asks about Manjaro, Arch Linux, pacman, yay, systemd, kernel management, GPU drivers, system maintenance, or Linux troubleshooting.

Covers: package management, AUR, systemd, filesystems, networking, users, kernels, desktop, maintenance, and rescue.

References (loaded on demand):
- `pacman-cheatsheet.md` -- every pacman, yay, paru, and makepkg command with flags and examples
- `systemd-recipes.md` -- unit file templates (daemon, oneshot, user, timer, socket, path, mount), journal management, boot analysis, hardening
- `troubleshooting-guide.md` -- 12 common issues: broken updates, GPU failures, lock files, filesystem corruption, boot failures, dependency conflicts, sound, network, permissions, disk space, clock issues

## Commands

### `/manjaro-help`

Quick system administration reference. Without arguments, runs a system health check (disk usage, failed services, pending updates, orphaned packages, journal size). With a topic argument, provides targeted guidance for that area.

Examples:
- `/manjaro-help` -- system health overview
- `/manjaro-help pacman` -- package management reference
- `/manjaro-help systemd` -- service management help
- `/manjaro-help troubleshoot broken update` -- fix guidance

## Installation

### Via Claude Code (manual install)

```bash
cp -r manjaro-expert ~/.claude/skills/

# Or install from the marketplace
claude install biodoia/biodoia-skills-marketplace#manjaro-expert
```

### In a project `.claude/settings.json`

```json
{
  "plugins": [
    {
      "source": "url",
      "url": "https://github.com/biodoia/biodoia-skills-marketplace.git",
      "subpath": "plugins/manjaro-expert"
    }
  ]
}
```

## Author

Sergio Martinelli -- [biodoia](https://github.com/biodoia)

## License

MIT
