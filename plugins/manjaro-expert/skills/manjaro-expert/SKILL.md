---
name: manjaro-expert
description: This skill should be used when the user asks about "Manjaro", "Arch Linux", "pacman", "yay", "paru", "makepkg", "PKGBUILD", "mhwd", "systemctl", "journalctl", "mkinitcpio", "grub", "manjaro-chroot", "arch-chroot", or "pamac". Make sure to use this skill whenever the user mentions package management, AUR builds, systemd services, filesystem management, networking with NetworkManager, user permissions, kernel management, GPU drivers, boot repair, mirror configuration, or any Arch/Manjaro system administration task, even if they just mention Linux system issues without specifying the distro.
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
paccache -r                                 # keep last 3 versions (from pacman-contrib)
paccache -rk 1                              # keep only the latest version
```

### Downgrading Packages

```bash
# From local cache
sudo pacman -U /var/cache/pacman/pkg/<package>-<old-version>.pkg.tar.zst

# Using the downgrade tool (AUR)
sudo downgrade <package>                    # interactive version picker
# Pin version: add to IgnorePkg in /etc/pacman.conf
```

### pacman.conf Configuration

Edit `/etc/pacman.conf` for global settings. Key options:

```ini
[options]
ParallelDownloads = 5       # concurrent downloads (default 1, set 5-10)
Color                       # colorized output
VerbosePkgLists             # show old/new version on upgrade
CheckSpace                  # check disk space before installing
IgnorePkg = linux510 nvidia-utils  # hold packages at current version
```

Enable `[multilib]` for 32-bit support (Steam, Wine). Repositories are defined by priority order in pacman.conf.

### Mirror Management

```bash
sudo pacman-mirrors --fasttrack 5           # top 5 fastest mirrors
sudo pacman-mirrors --geoip                 # mirrors by geolocation
sudo pacman -Syyu                           # always refresh after mirror change
```

### pamac (Manjaro GUI/CLI Package Manager)

pamac wraps pacman + AUR in a single interface:

```bash
pamac search <query>                        # search repos + AUR
pamac install <package>                     # install from repos
pamac build <aur-package>                   # build + install from AUR
pamac update                                # full system update
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

Common types: `.service` (daemons), `.timer` (scheduled execution, replaces cron), `.socket` (socket activation), `.mount`/`.automount` (filesystem mounts), `.path` (file watch triggers), `.target` (unit groups), `.slice` (resource control).

### User Services

Run services as the current user (no sudo), managed in `~/.config/systemd/user/`:

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
journalctl -p err                           # only errors and above
journalctl -b -1                            # logs from previous boot
journalctl --disk-usage                     # journal disk usage
sudo journalctl --vacuum-size=500M          # shrink journal to 500MB
```

### Bootloader (GRUB) and Initramfs

```bash
sudo vim /etc/default/grub                  # edit GRUB options
sudo grub-mkconfig -o /boot/grub/grub.cfg   # regenerate GRUB config
sudo vim /etc/mkinitcpio.conf               # edit HOOKS, MODULES, FILES
sudo mkinitcpio -P                          # regenerate all initramfs images
```

## Filesystem and Storage

### Partitioning and Filesystems

```bash
lsblk                                       # list block devices with tree
lsblk -f                                    # show filesystems and UUIDs
blkid                                       # detailed block device attributes
sudo fdisk /dev/sdX                          # MBR/GPT interactive partitioning
sudo cfdisk /dev/sdX                         # ncurses partition editor
findmnt                                      # show mount tree
sudo mkfs.ext4 /dev/sdXn                    # create ext4
sudo mkfs.btrfs /dev/sdXn                   # create btrfs
sudo mkfs.vfat -F32 /dev/sdXn              # FAT32 (EFI partition)
```

### fstab

Edit `/etc/fstab` for persistent mounts. Always use UUID (from `blkid`):

```
UUID=xxxx-xxxx  /          ext4   defaults,noatime              0 1
UUID=yyyy-yyyy  /home      btrfs  defaults,noatime,compress=zstd 0 0
UUID=zzzz-zzzz  /boot/efi  vfat   umask=0077                    0 2
```

After editing: `sudo systemctl daemon-reload && sudo mount -a` to test.

### BTRFS Operations

```bash
sudo btrfs subvolume list /                  # list subvolumes
sudo btrfs subvolume create /mnt/@snapshots  # create subvolume
sudo btrfs subvolume snapshot / /mnt/@snapshots/root-$(date +%F) # snapshot
sudo btrfs subvolume delete /mnt/@old        # delete subvolume
sudo btrfs scrub start /                     # verify data integrity
sudo btrfs filesystem usage /                # detailed space report
```

### Disk Usage

```bash
df -h                                        # filesystem usage overview
du -sh /path                                 # size of a directory
ncdu /                                       # interactive disk usage explorer
```

## Networking

### NetworkManager (nmcli)

```bash
nmcli device status                          # list all network interfaces
nmcli connection show                        # list saved connection profiles
nmcli connection up <name>                   # activate a connection
nmcli connection down <name>                 # deactivate
nmcli device wifi list                       # scan Wi-Fi networks
nmcli device wifi connect <SSID> password <pw>  # connect to Wi-Fi
nmcli connection modify <name> ipv4.addresses 192.168.1.100/24  # static IP
nmcli connection modify <name> ipv4.method manual
nmtui                                        # ncurses TUI for NetworkManager
```

### Firewall (ufw)

```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80,443/tcp
sudo ufw status verbose
```

### SSH

```bash
sudo systemctl enable --now sshd             # start SSH server
ssh-keygen -t ed25519 -C "user@host"         # generate key pair
ssh-copy-id user@remote                      # copy public key
ssh -L 8080:localhost:80 user@remote         # local port forward
```

Key config files: `/etc/ssh/sshd_config` (server), `~/.ssh/config` (client).

## User and Permissions

```bash
# User management
sudo useradd -m -G wheel -s /bin/bash <user> # create user with home, wheel group
sudo usermod -aG docker,libvirt <user>        # add to groups
sudo userdel -r <user>                        # remove user + home
sudo passwd <user>                            # set password

# Groups
sudo gpasswd -a <user> <group>               # add user to group
groups <user>                                 # list user's groups
id <user>                                     # uid, gid, all groups

# sudo — edit with visudo or drop-in file: /etc/sudoers.d/<username>

# File permissions
chmod 755 /path                              # rwxr-xr-x
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

NVIDIA: `mhwd` handles driver selection; reboot after install; verify with `nvidia-smi`. AMD: `video-linux` (open-source) works out of the box.

## Desktop and Display

```bash
# Display managers
sudo systemctl enable sddm                   # KDE default
sudo systemctl enable gdm                    # GNOME default
sudo systemctl enable lightdm                # XFCE/other default

# Check current session type
echo $XDG_SESSION_TYPE                        # x11 or wayland

# Font management
fc-cache -fv                                 # rebuild font cache
fc-list                                      # list installed fonts
```

Environment variable locations: `/etc/environment` (system-wide), `~/.profile` (login shell), `~/.xprofile` (X11 session), `~/.config/environment.d/` (systemd user environment).

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
pacman -Qtd                                  # list orphaned packages
sudo pacman -Rns $(pacman -Qtdq)             # remove all orphans
pacman -Qk                                   # check all packages for missing files
sudo pacman -Syu --overwrite '*'             # force overwrite conflicts (last resort)
sudo rm /var/lib/pacman/db.lck               # remove stale lock (only if pacman NOT running)
systemctl --failed                           # list failed units
journalctl -u <failed-unit> -b              # check logs for failed service
sudo fsck /dev/sdXn                          # filesystem check (must be unmounted)
```

### Timeshift (Snapshots)

```bash
sudo timeshift --create --comments "before update"  # create snapshot
sudo timeshift --list                                # list snapshots
sudo timeshift --restore                             # interactive restore
```

Timeshift works best with BTRFS (native snapshots) or RSYNC mode for ext4.

### Boot Failures

Recovery steps from a live USB:

1. `manjaro-chroot -a` to enter the installed system
2. `sudo pacman -Syu` to fix partial upgrades
3. `sudo mkinitcpio -P` to rebuild initramfs
4. `sudo grub-mkconfig -o /boot/grub/grub.cfg` to fix GRUB
5. Verify `/etc/fstab` UUIDs match `blkid` output

For kernel panic: boot an older kernel from GRUB advanced options, then install a known-good kernel with `mhwd-kernel`.

## Additional Resources

- **`references/pacman-cheatsheet.md`** — Complete pacman and yay command reference with advanced query options, package signing, repository management, and hook configuration.
- **`references/systemd-recipes.md`** — systemd unit file templates, timer recipes, socket activation examples, and user service patterns.
- **`references/troubleshooting-guide.md`** — Common Manjaro issues with step-by-step fixes: broken boots, partial upgrades, GPU driver conflicts, audio problems, and dependency resolution.
- For Tailscale VPN on Manjaro: reference the `tailscale-expert` skill.
