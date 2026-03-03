# Pacman & AUR Helpers — Complete Command Reference

## pacman Operation Flags

pacman uses a single uppercase flag to select the operation, followed by lowercase modifiers.

| Operation | Flag | Purpose |
|-----------|------|---------|
| Sync | `-S` | Install/upgrade from remote repos |
| Remove | `-R` | Remove installed packages |
| Query | `-Q` | Query the local package database |
| Files | `-F` | Query the file database |
| Upgrade | `-U` | Install a local .pkg.tar.zst file |
| Database | `-D` | Modify the package database |

---

## Install Packages (-S)

```bash
# Basic install
sudo pacman -S vim                           # single package
sudo pacman -S vim git curl htop             # multiple packages
sudo pacman -S extra/vim                     # from a specific repo

# Flags
sudo pacman -S --needed vim                  # skip if already installed at latest version
sudo pacman -S --noconfirm vim               # no interactive prompts (scripting)
sudo pacman -S --asdeps libfoo               # mark as dependency (not explicitly installed)
sudo pacman -S --overwrite '/usr/lib/*' pkg  # overwrite conflicting files (careful!)

# Install local package file
sudo pacman -U ./my-package-1.0-1-x86_64.pkg.tar.zst
sudo pacman -U https://example.com/pkg.tar.zst  # from URL
```

### Package Groups

```bash
pacman -Sg                                   # list all groups
pacman -Sg base-devel                        # list packages in a group
sudo pacman -S base-devel                    # install entire group (pick or accept all)
```

Common groups: `base-devel` (build tools), `xfce4` (desktop), `kde-applications`.

---

## Remove Packages (-R)

```bash
sudo pacman -R vim                           # remove package only
sudo pacman -Rs vim                          # remove + orphaned dependencies
sudo pacman -Rns vim                         # remove + orphaned deps + config files (cleanest)
sudo pacman -Rdd vim                         # remove, skip dependency checks (DANGEROUS)
sudo pacman -Rc vim                          # remove + all packages that depend on it (CASCADE)
```

### Comparison Table

| Command | Package | Unused Deps | Config Files | Dep Check |
|---------|---------|-------------|--------------|-----------|
| `-R` | removed | kept | kept | yes |
| `-Rs` | removed | removed | kept | yes |
| `-Rns` | removed | removed | removed | yes |
| `-Rdd` | removed | kept | kept | SKIPPED |

---

## Query Installed Packages (-Q)

```bash
pacman -Q                                    # list ALL installed packages
pacman -Qe                                   # explicitly installed (not deps)
pacman -Qd                                   # installed as dependencies
pacman -Qm                                   # foreign packages (AUR, manual)
pacman -Qn                                   # native packages (from repos)
pacman -Qdt                                  # orphans: deps no longer needed
pacman -Qdtq                                 # orphans: names only (for piping)

# Search installed
pacman -Qs vim                               # search name+description
pacman -Qi vim                               # detailed info (version, size, deps, install date)
pacman -Ql vim                               # list all files from this package
pacman -Qo /usr/bin/vim                      # which package owns this file
pacman -Qk vim                               # verify package files (missing/modified)
pacman -Qkk vim                              # deep verify (checksum + permissions)

# Count
pacman -Q | wc -l                            # total installed packages
pacman -Qe | wc -l                           # explicitly installed count
pacman -Qm | wc -l                           # AUR/foreign count
```

---

## Search Remote Repos (-Ss / -Si)

```bash
pacman -Ss vim                               # search repos by name+description
pacman -Ss '^vim$'                           # exact name match (regex)
pacman -Si vim                               # detailed remote info (repo, deps, size)
pacman -Sl                                   # list all packages in all repos
pacman -Sl extra                             # list all packages in a specific repo
```

---

## File Database (-F)

```bash
sudo pacman -Fy                              # sync file database (run first)
pacman -F libGL.so                           # find which package provides a file
pacman -Fl mesa                              # list files in a remote package
```

---

## System Upgrade (-Syu)

```bash
sudo pacman -Syu                             # sync databases + full system upgrade
sudo pacman -Syyu                            # force-refresh databases + upgrade
sudo pacman -Syyuu                           # force-refresh + allow downgrades (branch switch)
```

**Critical rules:**
- NEVER run `sudo pacman -Sy <package>` -- this syncs repos but only installs one package, causing partial upgrade.
- ALWAYS upgrade the full system: `-Syu`.
- After a mirror change, use `-Syyu` to force-refresh.

---

## Cache Management

```bash
# pacman built-in
sudo pacman -Sc                              # remove packages no longer installed from cache
sudo pacman -Scc                             # remove ALL cached packages (reclaim space)

# paccache (from pacman-contrib, recommended)
sudo pacman -S pacman-contrib                # install paccache
paccache -d                                  # dry run: show what would be removed
paccache -r                                  # remove all but last 3 versions
paccache -rk 1                              # keep only latest version
paccache -ruk 0                             # remove all uninstalled package cache

# Cache location
ls /var/cache/pacman/pkg/                    # cached .pkg.tar.zst files
du -sh /var/cache/pacman/pkg/                # cache disk usage
```

---

## Database Operations (-D)

```bash
sudo pacman -D --asdeps <package>            # mark as dependency
sudo pacman -D --asexplicit <package>        # mark as explicitly installed
```

Useful when you installed a package that was meant to be a dependency, or vice versa.

---

## Downgrading

```bash
# From local cache (if old version still cached)
sudo pacman -U /var/cache/pacman/pkg/<package>-<old-version>.pkg.tar.zst

# Using downgrade tool
yay -S downgrade
sudo downgrade <package>                     # interactive version selector
sudo DOWNGRADE_FROM_ALA=1 downgrade <pkg>    # include Arch Linux Archive versions

# Arch Linux Archive (manual)
# https://archive.archlinux.org/packages/
# Download the specific version .pkg.tar.zst and install with pacman -U

# Pin version (prevent upgrade)
# Add to /etc/pacman.conf under [options]:
# IgnorePkg = <package>
# IgnoreGroup = <group>
```

---

## pacman.conf Reference

Key settings in `/etc/pacman.conf`:

```ini
[options]
# Performance
ParallelDownloads = 5          # number of concurrent downloads (default: 1)

# Display
Color                          # colorized output
ILoveCandy                     # Pac-Man progress bar
VerbosePkgLists                # show old→new version on upgrade
CheckSpace                     # verify disk space before installing

# Security
SigLevel = Required DatabaseOptional   # require package signatures

# Hold packages
IgnorePkg = linux66 nvidia-utils       # skip these during -Syu
IgnoreGroup = gnome                     # skip entire group

# Architecture
Architecture = auto                     # or: x86_64

# Repositories (order = priority)
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]                             # merged into [extra] in recent Arch
Include = /etc/pacman.d/mirrorlist

[multilib]                              # 32-bit packages (Steam, Wine)
Include = /etc/pacman.d/mirrorlist

# Custom repo example
# [myrepo]
# SigLevel = Optional TrustAll
# Server = file:///home/user/repo
# Server = https://example.com/repo/$arch
```

---

## yay — AUR Helper Reference

```bash
# Install
yay -S <package>                             # install (repos or AUR)
yay -S --noconfirm <package>                 # no prompts
yay                                          # alias for yay -Syu (upgrade all)

# Search
yay -Ss <query>                              # search repos + AUR
yay -Si <package>                            # info (repo or AUR)
yay -Ps                                      # print stats (installed, AUR count, sizes)

# Upgrade
yay -Syu                                     # upgrade repos + AUR
yay -Sua                                     # upgrade AUR packages only

# Clean
yay -Yc                                      # remove unneeded dependencies
yay -Sc                                      # clean cache (pacman + yay)

# Configuration (save to ~/.config/yay/config.json)
yay --devel --save                           # track -git packages
yay --cleanafter --save                      # auto-clean build files
yay --removemake --save                      # remove makedeps after install
yay --batchinstall --save                    # batch install (faster)
yay --sudoloop --save                        # keep sudo alive during long builds

# Build options
yay -S <pkg> --mflags "--nocheck"            # skip check() in PKGBUILD
yay -S <pkg> --editmenu                      # review PKGBUILD before building
```

### yay Directories

- Build directory: `~/.cache/yay/<package>/`
- Config: `~/.config/yay/config.json`

---

## paru — AUR Helper Reference

paru is a Rust-based alternative to yay with similar syntax:

```bash
# Install
paru -S <package>                            # install
paru                                         # alias for paru -Syu

# Search
paru -Ss <query>                             # search
paru -Si <package>                           # info

# Upgrade
paru -Syu                                    # upgrade all
paru -Sua                                    # AUR only

# Unique paru features
paru --fm=vim                                # set file manager for PKGBUILD review
paru -Ua                                     # upgrade AUR + rebuild devel packages
paru --skipreview                            # skip PKGBUILD review prompt

# Config: ~/.config/paru/paru.conf
# [options]
# BottomUp                                   # show search results bottom-up
# NewsOnUpgrade                              # show Arch news on upgrade
```

---

## makepkg — Build Packages Manually

```bash
makepkg                                      # build the package (reads PKGBUILD in cwd)
makepkg -s                                   # auto-install missing dependencies
makepkg -i                                   # install after building
makepkg -si                                  # install deps + build + install (most common)
makepkg -c                                   # clean build directory after
makepkg -f                                   # force rebuild even if package exists
makepkg -e                                   # skip extract + build, just package (debugging)
makepkg -C                                   # clean sources
makepkg --nocheck                            # skip check() function
makepkg --skipchecksums                      # skip integrity checks (DANGEROUS)
makepkg --skippgpcheck                       # skip PGP signature checks

# Environment
PKGDEST=/path/to/packages makepkg            # output built packages elsewhere
SRCDEST=/path/to/sources makepkg             # store sources elsewhere
BUILDDIR=/tmp/makepkg makepkg                # build in tmpfs for speed
```

Configuration: `/etc/makepkg.conf` or `~/.makepkg.conf`

Key settings:
```bash
MAKEFLAGS="-j$(nproc)"                       # parallel compilation
COMPRESSZST=(zstd -c -T0 --ultra -20 -)     # maximum zstd compression
PACKAGER="Your Name <email@example.com>"     # identify yourself in packages
BUILDDIR=/tmp/makepkg                        # build in RAM
```

---

## namcap — Package Linter

```bash
namcap PKGBUILD                              # lint the build recipe
namcap my-package.pkg.tar.zst               # lint the built package
```

Checks for: missing dependencies, unnecessary dependencies, incorrect permissions, ELF issues, and more.

---

## Useful One-Liners

```bash
# Remove all orphaned packages
sudo pacman -Rns $(pacman -Qtdq)

# List explicitly installed packages not in any repo (AUR + manual)
pacman -Qem

# List 20 largest installed packages
pacman -Qi | awk '/^Name/{name=$3} /^Installed Size/{print $4 $5, name}' | sort -rh | head -20

# Export list of explicitly installed packages (for migration)
pacman -Qqe > pkglist.txt

# Restore packages from list
sudo pacman -S --needed - < pkglist.txt

# List recently installed packages
expac --timefmt='%Y-%m-%d %T' '%l\t%n' | sort -r | head -20

# Check for .pacnew and .pacsave files (config changes after update)
find /etc -name "*.pacnew" -o -name "*.pacsave" 2>/dev/null
# Or: pacdiff (from pacman-contrib) to interactively merge
sudo pacdiff

# Verify all installed packages for corruption
pacman -Qk 2>/dev/null | grep -v ' 0 missing'
```
