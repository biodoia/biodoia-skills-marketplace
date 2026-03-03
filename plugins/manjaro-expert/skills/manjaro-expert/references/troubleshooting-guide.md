# Manjaro/Arch Troubleshooting Guide

Common issues and step-by-step fixes for Manjaro Linux.

---

## 1. Broken System After Update (Partial Upgrade)

**Symptoms:** Libraries not found, applications crash, `error while loading shared libraries`, package conflicts during upgrade.

**Cause:** Running `pacman -Sy <package>` instead of `pacman -Syu`, or interrupted upgrade.

**Fix:**

```bash
# If you can still boot:
sudo pacman -Syu                             # complete the full upgrade
# If conflicts:
sudo pacman -Syu --overwrite '*'             # overwrite conflicting files (last resort)

# If you cannot boot — use a live USB:
# 1. Boot Manjaro live USB
# 2. Mount root partition
sudo manjaro-chroot -a                       # auto-detect and chroot
# 3. Inside chroot:
pacman -Syu                                  # complete upgrade
exit
reboot
```

**If specific package conflicts persist:**

```bash
# Identify the conflict
sudo pacman -Syu 2>&1 | grep "conflicting"

# Remove the conflicting package first
sudo pacman -Rdd <conflicting-package>       # remove without dependency check
sudo pacman -Syu                             # then upgrade

# Or force overwrite specific files
sudo pacman -S <package> --overwrite '/path/to/conflicting/file*'
```

---

## 2. No GUI After Reboot (GPU Driver Issues)

**Symptoms:** Black screen after login, dropped to TTY, display manager fails to start, Xorg/Wayland crash.

**Diagnosis:**

```bash
# Switch to TTY (Ctrl+Alt+F2)
# Login with your credentials

# Check display manager status
systemctl status sddm                        # or gdm, lightdm
journalctl -u sddm -b                        # display manager logs

# Check Xorg logs
cat /var/log/Xorg.0.log | grep "(EE)"        # Xorg errors
journalctl -b | grep -i "gpu\|nvidia\|amd\|radeon\|nouveau"

# Check installed GPU drivers
mhwd -li                                     # list installed drivers
lspci -k | grep -A 3 VGA                     # GPU + loaded kernel module
```

**Fix — NVIDIA:**

```bash
# Remove broken driver
sudo mhwd -r pci video-nvidia

# Reinstall correct driver
sudo mhwd -a pci nonfree 0300               # auto-detect and install

# Or install specific version
sudo mhwd -i pci video-nvidia               # latest
sudo mhwd -i pci video-nvidia-470xx         # legacy

# Regenerate initramfs (in case nvidia hook is needed)
sudo mkinitcpio -P

# Reboot
sudo reboot
```

**Fix — AMD (black screen with amdgpu):**

```bash
# Usually the open-source driver works
sudo mhwd -r pci video-amdgpu               # remove if installed
sudo mhwd -i pci video-linux                 # install open-source
sudo mkinitcpio -P
sudo reboot
```

**Fix — Fallback to software rendering:**

```bash
# Remove all GPU drivers
sudo mhwd -r pci <installed-driver>
# Install generic driver
sudo mhwd -i pci video-linux
sudo reboot
```

**Fix — Wayland issues (fall back to Xorg):**

```bash
# For SDDM/KDE: edit /etc/sddm.conf.d/10-wayland.conf
# Set: DisplayServer=x11
# Or: remove /usr/share/wayland-sessions/*.desktop temporarily

# For GDM/GNOME:
sudo ln -sf /usr/lib/systemd/system/gdm.service /etc/systemd/system/display-manager.service
# Edit /etc/gdm/custom.conf:
# WaylandEnable=false
```

---

## 3. pacman Lock File Stuck

**Symptoms:** `unable to lock database`, `could not lock database`, `/var/lib/pacman/db.lck exists`.

**Cause:** pacman was interrupted, crashed, or another instance is running.

**Fix:**

```bash
# FIRST: make sure no pacman process is running
ps aux | grep -i pacman
# Also check pamac:
ps aux | grep -i pamac

# If nothing is running, remove the lock:
sudo rm /var/lib/pacman/db.lck

# If pacman IS running, wait for it to finish or kill it:
sudo kill <pid>
sudo rm /var/lib/pacman/db.lck
```

**If database is corrupted after forced kill:**

```bash
# Re-sync databases
sudo pacman -Syy

# If that fails, remove and re-sync
sudo rm -r /var/lib/pacman/sync/
sudo pacman -Syy
```

---

## 4. Filesystem Corruption

**Symptoms:** Read-only filesystem, I/O errors, `structure needs cleaning`, kernel panic on mount.

**Fix — ext4:**

```bash
# MUST unmount the filesystem first (or boot from live USB for root partition)
sudo umount /dev/sdXn

# Run filesystem check
sudo fsck.ext4 -f /dev/sdXn                  # force check
sudo fsck.ext4 -fy /dev/sdXn                 # auto-yes to repairs (careful!)
sudo fsck.ext4 -fv /dev/sdXn                 # verbose output

# For root partition — boot from live USB:
sudo fsck.ext4 -f /dev/sdXn                  # check root partition while unmounted
```

**Fix — BTRFS:**

```bash
# Read-only check first (safe)
sudo btrfs check /dev/sdXn

# If errors found, try repair (DANGEROUS — backup first if possible):
sudo btrfs check --repair /dev/sdXn

# Scrub for bit-rot detection (can run on mounted filesystem):
sudo btrfs scrub start /
sudo btrfs scrub status /
```

**Fix — XFS:**

```bash
sudo umount /dev/sdXn
sudo xfs_repair /dev/sdXn
sudo xfs_repair -L /dev/sdXn                 # force log zeroing (data loss possible)
```

**If root filesystem is read-only after error:**

```bash
# Remount read-write (temporary fix)
sudo mount -o remount,rw /

# Then run proper fsck from live USB
```

---

## 5. Boot Failures

### GRUB Rescue Shell

**Symptoms:** `grub rescue>` prompt, `error: unknown filesystem`, `error: no such partition`.

**Fix from GRUB rescue:**

```bash
# List available partitions
ls
ls (hd0,gpt2)/                               # try each partition

# Find the one with /boot/grub/
ls (hd0,gpt2)/boot/grub/

# Set root and boot
set root=(hd0,gpt2)
set prefix=(hd0,gpt2)/boot/grub
insmod normal
normal                                        # should load GRUB menu
```

**Fix from live USB (reinstall GRUB):**

```bash
# Mount root partition
sudo mount /dev/sdXn /mnt
# Mount EFI partition (if UEFI)
sudo mount /dev/sdXn /mnt/boot/efi

# Chroot
sudo manjaro-chroot /mnt
# Or manually:
# sudo arch-chroot /mnt

# Reinstall GRUB
# For UEFI:
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=manjaro
grub-mkconfig -o /boot/grub/grub.cfg

# For BIOS/MBR:
grub-install --target=i386-pc /dev/sdX       # whole disk, not partition
grub-mkconfig -o /boot/grub/grub.cfg

exit
sudo reboot
```

### Kernel Panic / Missing Modules

**Symptoms:** `Kernel panic - not syncing`, `VFS: Unable to mount root fs`, `unable to find root device`.

**Cause:** Broken initramfs, missing kernel modules, wrong root= parameter.

**Fix:**

```bash
# Boot from GRUB advanced options → select an older kernel
# If that works, chroot isn't needed — just rebuild initramfs:
sudo mkinitcpio -P                           # regenerate all initramfs

# If no working kernel in GRUB — use live USB:
sudo manjaro-chroot -a

# Check mkinitcpio config
cat /etc/mkinitcpio.conf
# Ensure HOOKS has: base udev autodetect modconf block filesystems keyboard fsck
# For BTRFS root: add 'btrfs' to MODULES=()
# For NVME root: add 'nvme' to MODULES=()

# Rebuild
mkinitcpio -P

# If kernel is broken, install a known-good one:
mhwd-kernel -i linux610                      # install kernel 6.10
mhwd-kernel -li                              # verify installed kernels

# Regenerate GRUB to include the new kernel
grub-mkconfig -o /boot/grub/grub.cfg

exit
sudo reboot
```

### systemd-boot (alternative bootloader)

If using systemd-boot instead of GRUB:

```bash
# Reinstall from chroot
bootctl install
# Entries are in /boot/loader/entries/
# Main config: /boot/loader/loader.conf
```

---

## 6. Dependency Conflicts

**Symptoms:** `conflicting files`, `unable to satisfy dependency`, package A requires X but B requires Y.

### File Conflicts

```bash
# "package: /usr/lib/file exists in filesystem"
# Cause: a file was installed manually or by another package

# Find what owns the file
pacman -Qo /usr/lib/conflicting-file

# If owned by another package — that package needs updating too
sudo pacman -Syu

# If owned by no package (manually installed file)
sudo pacman -S <package> --overwrite '/usr/lib/conflicting-file'
```

### Dependency Version Conflicts

```bash
# "package X requires libfoo>=2.0 but installed is 1.9"
# This usually means partial upgrade. Fix:
sudo pacman -Syu                             # upgrade everything

# If circular dependency prevents upgrade:
sudo pacman -Rdd <package-with-old-dep>      # remove without dep check
sudo pacman -Syu                             # upgrade
sudo pacman -S <removed-package>             # reinstall
```

### AUR Package Conflicts

```bash
# AUR package conflicts with official package
# Option 1: remove the official package
sudo pacman -Rns <official-package>
yay -S <aur-replacement>

# Option 2: edit PKGBUILD to add conflicts=()
# In the AUR package directory, before makepkg
```

---

## 7. Pacman Database Issues

**Symptoms:** `invalid or corrupted package`, `GPGME error`, `failed to commit transaction`, signature errors.

### Keyring Issues

```bash
# Refresh keyring
sudo pacman -Sy archlinux-keyring manjaro-keyring
sudo pacman-key --init
sudo pacman-key --populate archlinux manjaro
sudo pacman-key --refresh-keys

# If that fails:
sudo rm -r /etc/pacman.d/gnupg/
sudo pacman-key --init
sudo pacman-key --populate archlinux manjaro
sudo pacman -Syu
```

### Corrupted Database

```bash
# Remove sync databases and re-download
sudo rm -r /var/lib/pacman/sync/
sudo pacman -Syy

# If local database is corrupted
# Backup first:
sudo cp -r /var/lib/pacman/local/ /var/lib/pacman/local.bak/
# Then try:
sudo pacman -Dk                              # check database consistency
sudo pacman -Dk 2>&1 | grep "no version"    # find issues
```

---

## 8. No Sound After Update

**Symptoms:** No audio output, PulseAudio/PipeWire crash, devices not detected.

```bash
# Check audio system
pactl info                                   # PulseAudio/PipeWire status
systemctl --user status pipewire             # PipeWire status
systemctl --user status pulseaudio           # PulseAudio status

# Restart audio
systemctl --user restart pipewire pipewire-pulse wireplumber  # PipeWire stack
# Or for PulseAudio:
systemctl --user restart pulseaudio

# Check ALSA
aplay -l                                     # list sound cards
speaker-test -c 2                            # test speakers
alsamixer                                    # check mute/volume levels

# If PipeWire replaced PulseAudio during update:
sudo pacman -S pipewire-pulse wireplumber    # ensure PipeWire compatibility
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

## 9. Network Not Working After Update

**Symptoms:** No internet, NetworkManager not running, Wi-Fi adapter missing.

```bash
# Check NetworkManager
systemctl status NetworkManager
sudo systemctl enable --now NetworkManager

# Check interfaces
ip link show                                 # list interfaces
nmcli device status                          # NetworkManager view

# Wi-Fi driver missing after kernel update
lspci -k | grep -A 3 Network                # check Wi-Fi hardware + driver
dmesg | grep -i wifi                         # kernel messages
dmesg | grep -i firmware                     # missing firmware?

# Reinstall Wi-Fi driver (if needed)
sudo pacman -S linux-firmware                # most Wi-Fi firmware
# For Broadcom:
sudo pacman -S broadcom-wl-dkms

# DNS issues
resolvectl status
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf  # temporary fix
```

---

## 10. /usr or /lib Ownership Broken

**Symptoms:** Many programs fail, `permission denied` on system binaries, sudo doesn't work.

**Cause:** Accidental `chown -R` on system directories.

```bash
# This is a serious issue. Best approach:

# Option A: Reinstall all packages to restore permissions
sudo pacman -S $(pacman -Qqn)                # reinstall all native packages
# This restores file permissions and ownership for all repo packages

# Option B: Fix specific ownership
sudo chown root:root /usr/bin/sudo
sudo chmod 4755 /usr/bin/sudo                # setuid for sudo

# Option C: From live USB if sudo is broken
sudo manjaro-chroot -a
pacman -S $(pacman -Qqn)                     # reinstall everything
exit
```

---

## 11. Disk Space Full

**Symptoms:** `No space left on device`, package installation fails, system slow.

```bash
# Find what's using space
df -h                                        # filesystem usage
du -sh /* 2>/dev/null | sort -rh | head -20  # biggest directories
ncdu /                                       # interactive explorer

# Common space hogs
du -sh /var/cache/pacman/pkg/                # pacman cache
du -sh /var/log/journal/                     # systemd journal
du -sh ~/.cache/                             # user cache
du -sh /tmp/                                 # temp files

# Clean up
sudo paccache -rk 1                          # keep only latest cached version
sudo journalctl --vacuum-size=100M           # shrink journal
sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null # remove orphans
yay -Sc                                      # clean yay build cache
rm -rf ~/.cache/yay/                         # nuclear: remove all AUR build files

# Find large files
find / -type f -size +100M 2>/dev/null | head -20
```

---

## 12. Time/Clock Issues

**Symptoms:** Wrong time, time jumps, dual-boot with Windows shows wrong time.

```bash
# Check current time settings
timedatectl status

# Enable NTP sync
sudo timedatectl set-ntp true

# Set timezone
sudo timedatectl set-timezone Europe/Rome
timedatectl list-timezones | grep Europe     # list available

# Dual-boot with Windows (Windows uses localtime, Linux uses UTC)
# Option A: Tell Linux to use localtime (easier)
sudo timedatectl set-local-rtc 1
# Option B: Tell Windows to use UTC (better)
# In Windows registry: HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation
# Add DWORD RealTimeIsUniversal = 1
```

---

## General Diagnostic Commands

```bash
# System info
uname -a                                     # kernel version
cat /etc/os-release                          # distro info
hostnamectl                                  # hostname + OS info
lscpu                                        # CPU info
free -h                                      # memory usage
uptime                                       # uptime + load

# Hardware
lspci                                        # PCI devices
lsusb                                        # USB devices
lsblk                                        # block devices
dmesg | tail -50                             # recent kernel messages
hwinfo --short                               # hardware summary (install hwinfo)

# Services
systemctl --failed                           # failed services
systemctl list-units --state=running         # running services

# Logs
journalctl -p err -b                         # errors since boot
journalctl -xe                               # last entries with explanation
dmesg -T | tail -50                          # timestamped kernel messages
```
