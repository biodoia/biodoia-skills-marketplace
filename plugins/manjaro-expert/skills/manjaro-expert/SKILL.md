---
name: manjaro-expert
description: Use when someone needs help with Manjaro or Arch Linux system administration, package management with pacman or yay, AUR builds, systemd services, filesystem management, networking with NetworkManager, user permissions, kernel management, GPU drivers, boot repair, or system troubleshooting. Also use when the user mentions "pacman", "yay", "paru", "makepkg", "PKGBUILD", "mhwd", "systemctl", "journalctl", "mkinitcpio", "grub", "manjaro-chroot", "arch-chroot", or any Arch/Manjaro-specific tool.
---

# Manjaro Expert

Manjaro Linux is a rolling-release distribution based on Arch Linux. It inherits Arch's package manager (pacman), the AUR ecosystem, and systemd-based init, but adds its own tools for hardware detection (mhwd), kernel management, and curated stable/testing/unstable branches.

This skill covers the full breadth of Manjaro/Arch system administration: package management, AUR, systemd, filesystems, networking, user management, maintenance, and troubleshooting.

## Package Management with pacman

pacman is the core package manager. All official Manjaro/Arch packages flow through it.

### Install, Remove, Search

```bash
# Install packages
sudo pacman -S <package>                    # install from repos
sudo pacman -S <pkg1> <pkg2> <pkg3>         # install multiple
sudo pacman -S --needed <package>           # skip if already installed (idempotent)
sudo pacman -S --noconfirm <package>        # no prompts (scripting)
sudo pacman -U /path/to/package.pkg.tar.zst # install local .pkg.tar.zst file

# Remove packages
sudo pacman -R <package>                    # remove, keep dependencies
sudo pacman -Rs <package>                   # remove + unused dependencies
sudo pacman -Rns <package>                  # remove + deps + config files (clean)
sudo pacman -Rdd <package>                  # force remove, ignore dependency checks (dangerous)

# Search
pacman -Ss <query>                          # search remote repos (name + description)
pacman -Qs <query>                          # search installed packages
pacman -F <filename>                        # which package owns a file (needs pacman -Fy first)

# Info
pacman -Si <package>                        # remote package info (repo, size, deps)
pacman -Qi <package>                        # installed package info (size, install date, deps)
pacman -Ql <package>                        # list all files installed by a package
pacman -Qo /path/to/file                    # which installed package owns this file
```

### System Update

Manjaro is rolling-release. Always do a full system upgrade, never partial:

```bash
sudo pacman -Syu                            # sync repos + upgrade all packages
sudo pacman -Syyu                           # force refresh + upgrade (after mirror change)
```

Never run `pacman -Sy <package>` (sync without upgrade) -- this causes partial upgrades and breaks shared library dependencies.

### Cache Management

```bash
sudo pacman -Sc                             # remove cached packages not currently installed
sudo pacman -Scc                            # remove ALL cached packages (nuclear)
paccache -r                                 # keep last 3 versions of each package (from pacman-contrib)
paccache -rk 1                              # keep only the latest version
ls /var/cache/pacman/pkg/ | wc -l           # count cached packages
du -sh /var/cache/pacman/pkg/               # cache disk usage
```

### Downgrading Packages

```bash
# From local cache
sudo pacman -U /var/cache/pacman/pkg/<package>-<old-version>.pkg.tar.zst

# Using the downgrade tool (AUR)
yay -S downgrade
sudo downgrade <package>                    # interactive version picker

# Add to IgnorePkg in /etc/pacman.conf to hold the version:
# IgnorePkg = <package>
```

### pacman.conf Configuration

Edit `/etc/pacman.conf` for global settings:

```ini
[options]
ParallelDownloads = 5       # concurrent downloads (default 1, set 5-10)
Color                       # colorized output
ILoveCandy                  # progress bar easter egg
VerbosePkgLists             # show old→new version on upgrade
CheckSpace                  # check disk space before installing

# Hold packages at current version
IgnorePkg = linux510 nvidia-utils

# Repositories (order = priority)
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[multilib]                  # uncomment for 32-bit support (Steam, Wine)
Include = /etc/pacman.d/mirrorlist
```

### Mirror Management

```bash
# Manjaro-specific: auto-rank by speed and status
sudo pacman-mirrors --fasttrack 5           # top 5 fastest mirrors
sudo pacman-mirrors --fasttrack             # all mirrors, ranked
sudo pacman-mirrors --geoip                 # mirrors by geolocation
sudo pacman-mirrors -c Germany,France       # specific countries
sudo pacman -Syyu                           # always refresh after mirror change

# Manual mirror editing: /etc/pacman.d/mirrorlist
```

### pamac (Manjaro GUI/CLI Package Manager)

pamac is Manjaro's frontend that wraps pacman + AUR:

```bash
pamac search <query>                        # search repos + AUR
pamac install <package>                     # install from repos
pamac build <aur-package>                   # build + install from AUR
pamac remove <package>                      # remove
pamac update                                # full system update
pamac list --installed                      # list installed packages
pamac checkupdates                          # check for available updates
```

## AUR (Arch User Repository)

The AUR contains user-submitted PKGBUILDs for packages not in official repos.

### yay (AUR Helper)

```bash
# Install yay (if not pre-installed)
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

# Usage
yay -S <aur-package>                        # install AUR package
yay -Ss <query>                             # search repos + AUR
yay -Sua                                    # upgrade AUR packages only
yay -Syu                                    # upgrade everything (repos + AUR)
yay --devel --save                          # track -git packages for updates
yay --cleanafter --save                     # auto-clean build dirs
yay --removemake --save                     # remove makedeps after build
yay -Yc                                     # clean unneeded dependencies
```

### paru (Rust-based Alternative)

```bash
# Install paru
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si

# Usage is nearly identical to yay
paru -S <aur-package>
paru -Sua                                   # upgrade AUR only
paru --fm=vim                               # review PKGBUILD with vim before building
```

### Manual AUR Build

```bash
git clone https://aur.archlinux.org/<package>.git
cd <package>
# ALWAYS review the PKGBUILD before building
less PKGBUILD
makepkg -si                                 # build + install
namcap PKGBUILD                             # lint the PKGBUILD
namcap <package>.pkg.tar.zst                # lint the built package
```

### PKGBUILD Basics

A PKGBUILD defines how to fetch, build, and package software. Key variables:

- `pkgname`, `pkgver`, `pkgrel` -- package identity
- `source=()` -- download URLs
- `sha256sums=()` -- integrity checksums
- `depends=()`, `makedepends=()` -- runtime and build dependencies
- `build()` -- compile step
- `package()` -- install into `$pkgdir`

## System Management with systemd

### Service Control

```bash
sudo systemctl start <unit>                 # start now
sudo systemctl stop <unit>                  # stop now
sudo systemctl restart <unit>               # restart
sudo systemctl reload <unit>                # reload config without restart (if supported)
sudo systemctl enable <unit>                # start on boot
sudo systemctl enable --now <unit>          # enable + start immediately
sudo systemctl disable <unit>               # don't start on boot
sudo systemctl mask <unit>                  # completely prevent starting (even manually)
sudo systemctl unmask <unit>                # reverse mask
systemctl status <unit>                     # show status, recent logs, PID
systemctl is-active <unit>                  # quick active check
systemctl is-enabled <unit>                 # quick enabled check
systemctl list-units --type=service         # all loaded services
systemctl list-unit-files --type=service    # all installed services
systemctl --failed                          # show failed units
```

### systemd Unit Types

- `.service` -- daemons and one-shot scripts
- `.timer` -- scheduled execution (replaces cron)
- `.socket` -- socket activation
- `.mount` / `.automount` -- filesystem mounts
- `.path` -- file/directory watch triggers
- `.target` -- grouping units (like runlevels)
- `.slice` -- resource control groups

### User Services

Run services as your user (no sudo), managed in `~/.config/systemd/user/`:

```bash
systemctl --user start <unit>
systemctl --user enable <unit>
systemctl --user status <unit>
systemctl --user daemon-reload              # after editing unit files
loginctl enable-linger <username>           # keep user services running after logout
```

See `references/systemd-recipes.md` for unit file templates and timer examples.

### journalctl (Log Viewer)

```bash
journalctl -u <unit>                        # logs for a specific unit
journalctl -u <unit> -f                     # follow (tail) logs
journalctl -u <unit> --since "1 hour ago"   # time-filtered
journalctl -u <unit> --since "2024-01-01" --until "2024-01-02"
journalctl -p err                           # only errors and above
journalctl -p warning -b                    # warnings since last boot
journalctl -b -1                            # logs from previous boot
journalctl --disk-usage                     # journal disk usage
sudo journalctl --vacuum-size=500M          # shrink journal to 500MB
sudo journalctl --vacuum-time=2weeks        # remove entries older than 2 weeks
journalctl --list-boots                     # list all recorded boots
```

### Bootloader

**GRUB** (most Manjaro installs):

```bash
sudo vim /etc/default/grub                  # edit boot options
sudo grub-mkconfig -o /boot/grub/grub.cfg   # regenerate config
# Key settings: GRUB_TIMEOUT, GRUB_CMDLINE_LINUX_DEFAULT, GRUB_THEME
```

**mkinitcpio** (initial ramdisk):

```bash
sudo vim /etc/mkinitcpio.conf               # HOOKS, MODULES, FILES arrays
sudo mkinitcpio -P                          # regenerate all initramfs images
sudo mkinitcpio -p linux610                 # regenerate for specific kernel
```

## Filesystem and Storage

### Partitioning

```bash
lsblk                                       # list block devices with tree
lsblk -f                                    # show filesystems and UUIDs
blkid                                       # detailed block device attributes
sudo fdisk /dev/sdX                          # MBR/GPT interactive partitioning
sudo gdisk /dev/sdX                          # GPT-only partitioning
sudo cfdisk /dev/sdX                         # ncurses partition editor
sudo parted /dev/sdX                         # scriptable partitioning
findmnt                                      # show mount tree
```

### Filesystems

```bash
sudo mkfs.ext4 /dev/sdXn                    # create ext4
sudo mkfs.btrfs /dev/sdXn                   # create btrfs
sudo mkfs.xfs /dev/sdXn                     # create xfs
sudo mkfs.vfat -F32 /dev/sdXn              # FAT32 (EFI partition)
```

### fstab

Edit `/etc/fstab` for persistent mounts. Always use UUID:

```
# <device>                                  <mount>     <type>  <options>                    <dump> <pass>
UUID=xxxx-xxxx-xxxx                         /           ext4    defaults,noatime             0      1
UUID=yyyy-yyyy-yyyy                         /home       btrfs   defaults,noatime,compress=zstd 0    0
UUID=zzzz-zzzz-zzzz                         /boot/efi   vfat    umask=0077                   0      2
/dev/nvme1n1p2                              /mnt/data   ext4    defaults,noatime             0      2
```

After editing: `sudo systemctl daemon-reload && sudo mount -a` to test.

### BTRFS Operations

```bash
sudo btrfs subvolume list /                  # list subvolumes
sudo btrfs subvolume create /mnt/@snapshots  # create subvolume
sudo btrfs subvolume snapshot / /mnt/@snapshots/root-$(date +%F) # snapshot
sudo btrfs subvolume delete /mnt/@old        # delete subvolume
sudo btrfs scrub start /                     # verify data integrity
sudo btrfs scrub status /                    # check scrub progress
sudo btrfs balance start /                   # rebalance data across devices
sudo btrfs filesystem df /                   # space usage by profile
sudo btrfs filesystem usage /                # detailed space report
```

### Disk Usage

```bash
df -h                                        # filesystem usage overview
du -sh /path                                 # size of a directory
du -sh /* 2>/dev/null | sort -rh | head -20  # biggest top-level dirs
ncdu /                                       # interactive disk usage explorer
```

## Networking

### NetworkManager (nmcli)

```bash
nmcli device status                          # list all network interfaces
nmcli connection show                        # list saved connection profiles
nmcli connection show --active               # active connections only
nmcli connection up <name>                   # activate a connection
nmcli connection down <name>                 # deactivate
nmcli device wifi list                       # scan Wi-Fi networks
nmcli device wifi connect <SSID> password <pw>  # connect to Wi-Fi
nmcli connection add type ethernet con-name my-eth ifname eth0  # create profile
nmcli connection modify <name> ipv4.addresses 192.168.1.100/24  # static IP
nmcli connection modify <name> ipv4.method manual
nmcli connection modify <name> ipv4.dns "8.8.8.8 1.1.1.1"
nmtui                                        # ncurses TUI for NetworkManager
```

### Firewall

```bash
# ufw (simple firewall)
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
sudo ufw status verbose
sudo ufw delete allow 80/tcp

# firewalld (Fedora-style, zone-based)
sudo firewall-cmd --state
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### SSH

```bash
sudo systemctl enable --now sshd             # start SSH server
ssh-keygen -t ed25519 -C "user@host"         # generate key pair
ssh-copy-id user@remote                      # copy public key
ssh -L 8080:localhost:80 user@remote         # local port forward
ssh -R 8080:localhost:80 user@remote         # remote port forward
ssh -D 1080 user@remote                      # SOCKS proxy
```

Key config files: `/etc/ssh/sshd_config` (server), `~/.ssh/config` (client).

### DNS

```bash
resolvectl status                            # systemd-resolved status
resolvectl query example.com                 # resolve a name
cat /etc/resolv.conf                         # check resolver config
```

## User and Permissions

```bash
# User management
sudo useradd -m -G wheel -s /bin/bash <user> # create user with home, wheel group
sudo usermod -aG docker,libvirt <user>        # add to groups
sudo userdel -r <user>                        # remove user + home
sudo passwd <user>                            # set password

# Groups
sudo groupadd <group>
sudo gpasswd -a <user> <group>               # add user to group
groups <user>                                 # list user's groups
id <user>                                     # uid, gid, all groups

# sudo
sudo visudo                                   # edit sudoers safely
# Or drop-in file: /etc/sudoers.d/<username>
# user ALL=(ALL:ALL) ALL                      # full sudo
# user ALL=(ALL:ALL) NOPASSWD: ALL            # no-password sudo

# File permissions
chmod 755 /path                              # rwxr-xr-x
chmod u+x script.sh                          # add execute for owner
chown -R user:group /path                    # recursive ownership
setfacl -m u:user:rwx /path                  # ACL: grant user access
getfacl /path                                # show ACLs
```

## Kernel and Hardware

### Kernel Management (Manjaro-specific)

```bash
mhwd-kernel -li                              # list installed kernels
mhwd-kernel -l                               # list available kernels
sudo mhwd-kernel -i linux610                 # install kernel 6.10
sudo mhwd-kernel -r linux66                  # remove kernel 6.6
uname -r                                      # currently running kernel
```

Always keep at least two kernels installed as fallback.

### Hardware Detection (mhwd)

```bash
mhwd -li                                     # list installed drivers
mhwd -l                                      # list available drivers
sudo mhwd -a pci nonfree 0300               # auto-install GPU driver (non-free)
sudo mhwd -i pci video-nvidia                # install specific driver
sudo mhwd -r pci video-nvidia                # remove driver
```

### GPU Drivers

For NVIDIA: `mhwd` handles driver selection. After install, reboot. Check with `nvidia-smi`.
For AMD: the `video-linux` (open-source) driver usually works out of the box.

## Desktop and Display

```bash
# Display managers
sudo systemctl enable sddm                   # KDE default
sudo systemctl enable gdm                    # GNOME default
sudo systemctl enable lightdm                # XFCE/other default

# Xorg vs Wayland: check current session
echo $XDG_SESSION_TYPE                        # x11 or wayland
loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type

# Font management
fc-cache -fv                                 # rebuild font cache
fc-list                                      # list installed fonts
# Install fonts to ~/.local/share/fonts/ (user) or /usr/share/fonts/ (system)

# Environment variables
# /etc/environment          — system-wide
# ~/.profile                — login shell
# ~/.xprofile               — X11 session
# ~/.config/environment.d/  — systemd user environment
```

## Maintenance and Troubleshooting

### System Rescue

```bash
# From a live USB — chroot into installed system
sudo manjaro-chroot -a                       # auto-detect and mount
# Or manually:
sudo mount /dev/sdXn /mnt
sudo mount /dev/sdXn /mnt/boot/efi
sudo arch-chroot /mnt
# Now run repairs: pacman -Syu, grub-mkconfig, mkinitcpio -P, etc.
```

### Common Repair Tasks

```bash
# Orphaned packages (installed as deps, no longer needed)
pacman -Qtd                                  # list orphans
sudo pacman -Rns $(pacman -Qtdq)             # remove all orphans

# Verify package integrity
pacman -Qk                                   # check all packages for missing files
pacman -Qk <package>                         # check specific package

# Broken packages after partial upgrade
sudo pacman -Syu --overwrite '*'             # force overwrite conflicts (last resort)

# Lock file stuck
sudo rm /var/lib/pacman/db.lck               # only if pacman is NOT running

# Failed services
systemctl --failed                           # list failed units
sudo systemctl reset-failed                  # clear failed state
journalctl -u <failed-unit> -b              # check logs

# Filesystem check
sudo fsck /dev/sdXn                          # must be unmounted first
sudo fsck.ext4 -f /dev/sdXn                  # force check ext4
sudo btrfs check /dev/sdXn                   # btrfs check (read-only by default)
```

### Timeshift (Snapshots)

```bash
sudo timeshift --create --comments "before update"  # create snapshot
sudo timeshift --list                                # list snapshots
sudo timeshift --restore                             # interactive restore
sudo timeshift --delete --snapshot '2024-01-01_00-00-00'
```

Timeshift works best with BTRFS (uses btrfs snapshots) or RSYNC mode for ext4.

### Boot Failures

If the system fails to boot:

1. Boot from live USB
2. Use `manjaro-chroot -a` to enter the installed system
3. Run `sudo pacman -Syu` to fix partial upgrades
4. Run `sudo mkinitcpio -P` to rebuild initramfs
5. Run `sudo grub-mkconfig -o /boot/grub/grub.cfg` to fix GRUB
6. Check `/etc/fstab` for incorrect UUIDs (compare with `blkid`)

For kernel panic: boot an older kernel from GRUB advanced options, then install a known-good kernel with `mhwd-kernel`.

## Progressive Disclosure

- Complete pacman and yay command reference: `references/pacman-cheatsheet.md`
- systemd unit file templates and timer recipes: `references/systemd-recipes.md`
- Common Manjaro issues with step-by-step fixes: `references/troubleshooting-guide.md`
- Quick system admin reference: `/manjaro-help` command
- For Tailscale VPN on Manjaro: reference the `tailscale-expert` skill
