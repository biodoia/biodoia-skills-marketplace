---
description: Quick Manjaro/Arch Linux system administration reference — package management, systemd, filesystem, networking, troubleshooting
allowed-tools: ["Read", "Bash"]
---

# Manjaro Help

Quick reference for Manjaro/Arch Linux system administration. Provide concise, actionable guidance for the user's query.

## If the user provided arguments

Interpret `$ARGUMENTS` as a topic or problem description and provide targeted help.

**Topic routing:**

- **pacman / package / install / remove / update**: Show relevant pacman commands. Read `references/pacman-cheatsheet.md` if deeper detail is needed.
- **yay / aur / paru / makepkg**: Show AUR helper commands. Read `references/pacman-cheatsheet.md` for the AUR section.
- **systemd / systemctl / service / timer / journal**: Show systemd commands. Read `references/systemd-recipes.md` for templates.
- **disk / mount / fstab / btrfs / partition**: Show filesystem commands from the main skill.
- **network / nmcli / wifi / firewall / ssh**: Show networking commands from the main skill.
- **user / permission / sudo / chmod / chown**: Show user management commands from the main skill.
- **kernel / mhwd / driver / gpu / nvidia**: Show kernel/hardware commands from the main skill.
- **troubleshoot / fix / broken / error / rescue**: Read `references/troubleshooting-guide.md` and find the matching issue.
- **mirror / mirrorlist**: Show mirror management commands.

## If no arguments provided

Run a quick system health check:

```bash
# System info
uname -r && cat /etc/os-release | grep PRETTY_NAME

# Disk usage
df -h / /home /boot 2>/dev/null

# Failed services
systemctl --failed 2>/dev/null

# Updates available
checkupdates 2>/dev/null | wc -l

# Orphaned packages
pacman -Qtdq 2>/dev/null | wc -l

# Journal size
journalctl --disk-usage 2>/dev/null
```

Present the results as a formatted system health summary:

- **OS**: Manjaro version + kernel
- **Disk**: usage of key partitions, warn if >85%
- **Services**: list any failed systemd units
- **Updates**: number of available updates
- **Orphans**: number of orphaned packages (suggest cleanup if >10)
- **Journal**: size (suggest vacuum if >500MB)

Then suggest common maintenance actions based on the findings.

## Reference files

For detailed information beyond this quick reference, read these files on demand:

- `skills/manjaro-expert/references/pacman-cheatsheet.md` -- full pacman/yay/paru command reference
- `skills/manjaro-expert/references/systemd-recipes.md` -- unit templates, timers, journal management
- `skills/manjaro-expert/references/troubleshooting-guide.md` -- common issues with step-by-step fixes
