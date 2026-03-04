# Wayland Multi-Monitor Troubleshooting Guide

Comprehensive troubleshooting for multi-monitor setups on Wayland. Covers 15+ common issues with step-by-step solutions, GPU-specific guides, and a diagnostic commands checklist.

## Diagnostic Commands Checklist

Run these commands first to gather system information before troubleshooting:

```bash
# ============================================================
# SYSTEM INFORMATION
# ============================================================
uname -r                                         # kernel version
cat /etc/os-release                              # distro info

# ============================================================
# GPU AND DRIVER
# ============================================================
lspci -k | grep -A 3 -i vga                     # GPU hardware + driver
lsmod | grep -E 'nvidia|amdgpu|i915|xe'         # loaded GPU modules
cat /proc/driver/nvidia/version 2>/dev/null      # Nvidia driver version
glxinfo | grep "OpenGL renderer"                 # GL renderer
vulkaninfo --summary 2>/dev/null                 # Vulkan support
vainfo 2>/dev/null                               # VA-API (hw video accel)

# ============================================================
# DRM / DISPLAY INFO
# ============================================================
ls /sys/class/drm/                               # list DRM connectors
cat /sys/class/drm/card*/device/vendor           # GPU vendor IDs
cat /sys/class/drm/card1-*/status                # connector status
cat /sys/class/drm/card1-*/modes                 # available modes
cat /sys/class/drm/card1-*/edid | edid-decode    # EDID data
drm_info 2>/dev/null                             # full DRM info

# ============================================================
# COMPOSITOR INFO
# ============================================================
echo $XDG_SESSION_TYPE                           # should be "wayland"
echo $XDG_CURRENT_DESKTOP                        # compositor name
echo $WAYLAND_DISPLAY                            # wayland socket

# Compositor-specific
hyprctl monitors 2>/dev/null                     # Hyprland
hyprctl monitors -j 2>/dev/null | jq .           # Hyprland JSON
swaymsg -t get_outputs 2>/dev/null               # Sway
swaymsg -t get_outputs 2>/dev/null | jq .        # Sway JSON
wlr-randr 2>/dev/null                            # wlroots generic
kscreen-doctor --outputs 2>/dev/null             # KDE

# ============================================================
# SCREEN SHARING / PORTALS
# ============================================================
systemctl --user status pipewire                 # PipeWire
systemctl --user status wireplumber              # WirePlumber
systemctl --user status xdg-desktop-portal       # portal daemon
systemctl --user status xdg-desktop-portal-hyprland  # Hyprland portal
systemctl --user status xdg-desktop-portal-wlr       # wlr portal
systemctl --user status xdg-desktop-portal-kde       # KDE portal
pw-cli ls Node 2>/dev/null | grep -i screen      # PipeWire screen nodes

# ============================================================
# KERNEL LOGS
# ============================================================
dmesg | grep -i drm                              # DRM messages
dmesg | grep -i -E 'nvidia|amdgpu|i915'         # GPU driver messages
journalctl --user -u xdg-desktop-portal --since "10 min ago"  # portal logs

# ============================================================
# VRR / ADAPTIVE SYNC
# ============================================================
cat /sys/class/drm/card1-DP-1/vrr_capable        # monitor VRR capability
cat /sys/class/drm/card1-DP-1/vrr_enabled 2>/dev/null  # VRR active
```

## Issue 1: Black Screen After Adding Monitor

**Symptoms:** Newly connected monitor shows no image, stays black, or shows "No Signal."

**Steps:**
1. Check if the kernel sees the connection:
   ```bash
   cat /sys/class/drm/card1-DP-2/status    # should say "connected"
   ```
2. Check kernel logs for errors:
   ```bash
   dmesg | tail -30 | grep -i drm
   ```
3. Try forcing a safe mode:
   ```bash
   wlr-randr --output DP-2 --mode 1920x1080@60Hz
   # Or in Hyprland:
   hyprctl keyword monitor DP-2,1920x1080@60,auto,1
   ```
4. Check EDID readability:
   ```bash
   cat /sys/class/drm/card1-DP-2/edid | edid-decode 2>&1 | head -20
   ```
5. Try a different cable. DP cables are passive and can be bandwidth-limited. HDMI cables may not support 4K@120Hz without HDMI 2.1 certification.
6. Try a different port on the GPU. Some GPUs have fewer high-bandwidth ports.
7. If using Nvidia, ensure `nvidia-drm.modeset=1` is set (see Nvidia section below).

## Issue 2: Wrong Resolution Detected

**Symptoms:** Monitor runs at lower resolution than expected, or the desired mode is missing.

**Steps:**
1. List available modes:
   ```bash
   wlr-randr    # or hyprctl monitors -j | jq '.[].availableModes'
   ```
2. If the desired mode is missing, check cable bandwidth:
   - DP 1.2: max 4K@60Hz (17.28 Gbps)
   - DP 1.4: max 4K@120Hz with DSC (25.92 Gbps)
   - HDMI 2.0: max 4K@60Hz (14.4 Gbps)
   - HDMI 2.1: max 4K@120Hz (42.67 Gbps)
3. Check EDID for the monitor's actual capabilities:
   ```bash
   edid-decode < /sys/class/drm/card1-DP-1/edid
   ```
4. Force a custom mode (advanced, wlroots):
   ```bash
   # Calculate modeline
   cvt 2560 1440 165
   # Add custom mode via compositor config if supported
   ```
5. Some monitors need firmware updates for full resolution over specific ports.

## Issue 3: XWayland Apps Blurry at Fractional Scale

**Symptoms:** X11 applications (identified by `xprop` or `hyprctl clients` showing `xwayland: 1`) appear blurry when the compositor scale is non-integer.

**Steps:**
1. **Hyprland:** Force XWayland to render at native resolution:
   ```conf
   xwayland {
       force_zero_scaling = true
   }
   ```
   Then set toolkit-level scaling:
   ```conf
   env = GDK_SCALE,2
   env = QT_SCALE_FACTOR,1.5
   ```
2. **Sway:** XWayland scaling is compositor-managed. Set toolkit variables in your environment:
   ```bash
   export GDK_SCALE=2
   export GDK_DPI_SCALE=0.5
   export QT_SCALE_FACTOR=1.5
   ```
3. For Electron apps (VS Code, Discord, Slack), add to the `.desktop` file Exec line:
   ```
   --force-device-scale-factor=1.5
   ```
4. For Steam, set launch options per game or use gamescope to handle scaling.
5. Consider whether the app has a native Wayland mode. Many GTK4, Qt6, and Electron apps support Wayland natively.

## Issue 4: Cursor Size Inconsistent Across Monitors

**Symptoms:** Cursor appears too large on one monitor, too small on another, or changes size when moving between monitors.

**Steps:**
1. Set `XCURSOR_SIZE` globally:
   ```bash
   export XCURSOR_SIZE=32
   ```
2. In Hyprland config:
   ```conf
   env = XCURSOR_SIZE,32
   env = XCURSOR_THEME,Adwaita
   ```
3. In Sway config:
   ```conf
   seat seat0 xcursor_theme Adwaita 32
   ```
4. Ensure the cursor theme is installed and supports the requested size:
   ```bash
   ls /usr/share/icons/Adwaita/cursors/
   ```
5. If using Nvidia, the hardware cursor may glitch. Set:
   ```conf
   env = WLR_NO_HARDWARE_CURSORS,1    # forces software cursor
   ```

## Issue 5: Screen Tearing

**Symptoms:** Horizontal lines/tearing visible during motion, especially on one monitor.

**Steps:**
1. Verify you are running on Wayland (not X11):
   ```bash
   echo $XDG_SESSION_TYPE    # must be "wayland"
   ```
2. Wayland compositors should not tear by default. If tearing occurs:
   - Check if `allow_tearing = true` is set (Hyprland). This opts games into tearing mode. Remove if not desired.
   - Check VRR status. VRR eliminates tearing when frame rate is within the monitor's VRR range.
3. Ensure the GPU driver is properly loaded:
   ```bash
   glxinfo | grep "OpenGL renderer"
   ```
4. For Nvidia: ensure `nvidia-drm.modeset=1` and the correct driver version.
5. Multi-GPU: ensure the compositor is running on the correct GPU.

## Issue 6: Compositor Crashes on Hotplug

**Symptoms:** Plugging/unplugging a monitor causes the compositor to crash or freeze.

**Steps:**
1. Check compositor logs:
   ```bash
   # Hyprland
   cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log | tail -50
   # Sway
   journalctl --user -u sway --since "5 min ago"
   ```
2. Ensure you have a fallback monitor rule:
   ```conf
   # Hyprland
   monitor = , preferred, auto, 1
   ```
3. Update your compositor to the latest version. Hotplug bugs are frequently fixed.
4. Check kernel logs for DRM errors:
   ```bash
   dmesg | grep -i drm | tail -20
   ```
5. If using Nvidia, update to the latest driver. Nvidia hotplug support on Wayland has improved significantly in driver 545+.

## Issue 7: wlr-randr "Failed to Get Display"

**Symptoms:** Running `wlr-randr` produces "failed to get wlr-output-management" or "failed to get display."

**Steps:**
1. Ensure you are running a wlroots-based compositor (Sway, Hyprland, river). wlr-randr does not work on KDE or GNOME.
2. Check `WAYLAND_DISPLAY` is set:
   ```bash
   echo $WAYLAND_DISPLAY    # should be "wayland-0" or similar
   ```
3. If running inside a nested session (e.g., terminal multiplexer started before Wayland), the variable may not be set. Export it:
   ```bash
   export WAYLAND_DISPLAY=wayland-1   # check with ls /run/user/$(id -u)/wayland-*
   ```
4. Ensure the compositor supports the `wlr-output-management-unstable-v1` protocol:
   ```bash
   wayland-info | grep wlr-output-management
   ```

## Issue 8: Gaming Stuttering / Frame Drops

**Symptoms:** Games stutter, have frame drops, or do not maintain expected FPS on multi-monitor setup.

**Steps:**
1. Check if the compositor is throttling to the slowest monitor. On some compositors, a 60Hz secondary monitor can throttle the primary 165Hz monitor.
   - Hyprland: set `misc { vfr = true }` to allow variable frame rate per monitor.
   - Use gamescope for the game to isolate it from compositor rendering.
2. Verify direct scanout is working for fullscreen games:
   ```bash
   # Hyprland
   misc {
       no_direct_scanout = false
   }
   ```
3. Check GPU utilization:
   ```bash
   # AMD
   cat /sys/class/drm/card1/device/gpu_busy_percent
   # Nvidia
   nvidia-smi
   # Intel
   intel_gpu_top
   ```
4. Use MangoHud to monitor FPS and frame times:
   ```bash
   MANGOHUD=1 game_executable
   ```
5. Try gamescope:
   ```bash
   gamescope -W 2560 -H 1440 -r 165 -f --adaptive-sync -- game_executable
   ```

## Issue 9: VRR / Adaptive Sync Not Working

**Symptoms:** Monitor reports VRR capable, but VRR is not active. Tearing or stuttering persists.

**Steps:**
1. Check monitor capability:
   ```bash
   cat /sys/class/drm/card1-DP-1/vrr_capable    # must be 1
   ```
2. Check compositor config:
   ```conf
   # Hyprland
   misc { vrr = 1 }    # or vrr = 2 for fullscreen only
   ```
3. VRR typically only works over DisplayPort or HDMI 2.1. HDMI 2.0 does not support VRR (some monitors have proprietary exceptions).
4. Check the monitor's OSD menu. FreeSync/VRR may need to be enabled in the monitor settings.
5. AMD: VRR should work out of the box with amdgpu. Check:
   ```bash
   cat /sys/class/drm/card1-DP-1/vrr_enabled 2>/dev/null
   ```
6. Nvidia: VRR on Wayland requires driver 545+ and `nvidia-drm.modeset=1`. G-Sync Compatible monitors should work.
7. Some games must be fullscreen (not borderless windowed) for VRR to activate.

## Issue 10: Screen Sharing Shows Black Screen

**Symptoms:** Screen sharing in browsers (Google Meet, Teams) or apps (Discord, Slack, Zoom) shows a black rectangle.

**Steps:**
1. Verify PipeWire is running:
   ```bash
   systemctl --user status pipewire wireplumber
   ```
2. Verify the correct portal is installed and running:
   ```bash
   # For Hyprland:
   pacman -Qs xdg-desktop-portal-hyprland
   systemctl --user status xdg-desktop-portal-hyprland

   # For Sway:
   pacman -Qs xdg-desktop-portal-wlr

   # For KDE:
   pacman -Qs xdg-desktop-portal-kde
   ```
3. Restart portals:
   ```bash
   systemctl --user restart xdg-desktop-portal
   systemctl --user restart xdg-desktop-portal-hyprland   # or your compositor's portal
   ```
4. Ensure `XDG_CURRENT_DESKTOP` is set correctly:
   ```bash
   echo $XDG_CURRENT_DESKTOP   # must match: Hyprland, sway, KDE, GNOME
   ```
5. For Chromium-based browsers, ensure PipeWire capture is enabled:
   ```
   chrome://flags/#enable-webrtc-pipewire-capturer   -> Enabled
   ```
6. For Firefox, ensure `media.peerconnection.enabled` is true and PipeWire support is built in (default on Manjaro).
7. Try `WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR` environment in the portal service.

## Issue 11: Monitor Positioning / Alignment Wrong

**Symptoms:** Mouse cursor jumps when moving between monitors. Windows snap to wrong edges.

**Steps:**
1. Verify physical arrangement matches config:
   ```bash
   hyprctl monitors -j | jq '.[] | {name, x: .x, y: .y, width: .width, height: .height}'
   ```
2. Adjust positions in config to match physical layout. Remember:
   - Position is in scaled coordinates for Hyprland.
   - A 2560px monitor at scale 1 is 2560 logical pixels wide.
   - A 3840px monitor at scale 1.5 is 2560 logical pixels wide.
3. For vertical alignment with different resolution monitors, adjust the Y offset:
   ```conf
   # Align bottom edges of a 1440p and 1080p monitor
   monitor = DP-1, 2560x1440@165, 0x0, 1
   monitor = DP-2, 1920x1080@60, 2560x360, 1    # 1440-1080=360 offset
   ```

## Issue 12: Second Monitor Not Waking from Sleep

**Symptoms:** After system sleep/resume, one or more monitors do not turn on.

**Steps:**
1. Check connector status after resume:
   ```bash
   cat /sys/class/drm/card1-*/status
   ```
2. Try forcing a mode reset:
   ```bash
   wlr-randr --output DP-2 --off && sleep 1 && wlr-randr --output DP-2 --on
   ```
3. Some monitors need a DDC/CI wake command:
   ```bash
   ddcutil detect                        # list detected monitors
   ddcutil setvcp D6 01 --display 2      # power on display 2
   ```
4. Check for kernel power management issues:
   ```bash
   dmesg | grep -i -E 'drm|resume|suspend' | tail -20
   ```
5. For Nvidia: add `nvidia.NVreg_PreserveVideoMemoryAllocations=1` to kernel parameters and enable `nvidia-suspend.service`, `nvidia-resume.service`.

## Issue 13: Workspace Numbering Confusion

**Symptoms:** Workspaces appear on wrong monitors or switch monitors unexpectedly.

**Steps:**
1. Explicitly bind workspaces to monitors:
   ```conf
   # Hyprland
   workspace = 1, monitor:DP-1, default:true
   workspace = 2, monitor:DP-1
   workspace = 3, monitor:DP-2, default:true
   workspace = 4, monitor:DP-2
   ```
2. Use `default:true` to set the initial workspace for each monitor.
3. In Sway:
   ```conf
   workspace 1 output DP-1
   workspace 2 output DP-1
   ```
4. Verify workspace assignments:
   ```bash
   hyprctl workspaces -j | jq '.[] | {id, monitor}'
   ```

## Issue 14: Flickering or Artifacts

**Symptoms:** Screen flickers, shows artifacts, or has visual corruption on one or more monitors.

**Steps:**
1. Check kernel logs for DRM errors:
   ```bash
   dmesg | grep -i -E 'drm|error|fault' | tail -30
   ```
2. Test with a different cable. Faulty or low-quality cables cause artifacts.
3. Reduce refresh rate to see if the issue is bandwidth-related:
   ```bash
   wlr-randr --output DP-1 --mode 2560x1440@60Hz
   ```
4. For AMD: check if DC (Display Core) is loaded:
   ```bash
   cat /sys/module/amdgpu/parameters/dc    # should be 1
   ```
5. For Nvidia: try disabling hardware cursors and check driver version:
   ```bash
   env WLR_NO_HARDWARE_CURSORS=1
   nvidia-smi    # check driver version, update if old
   ```
6. Check for overheating:
   ```bash
   sensors    # check GPU temperature
   ```

## Issue 15: Audio Does Not Follow Monitor

**Symptoms:** Audio output does not switch when a monitor with built-in speakers or an HDMI/DP audio sink is connected.

**Steps:**
1. List PipeWire sinks:
   ```bash
   wpctl status | grep -A 20 "Audio"
   pw-cli ls Node | grep -i hdmi
   ```
2. Set the default sink:
   ```bash
   wpctl set-default <sink-id>
   ```
3. Use `pavucontrol` for GUI audio output management.
4. For automatic switching, use WirePlumber's routing policies or `pactl` scripts triggered by monitor connect/disconnect.

## Nvidia on Wayland: Complete Guide

### Kernel Parameters (REQUIRED)

Add to your bootloader configuration (GRUB, systemd-boot, or kernel command line):

```
nvidia-drm.modeset=1
```

**GRUB** (`/etc/default/grub`):
```bash
GRUB_CMDLINE_LINUX_DEFAULT="... nvidia-drm.modeset=1"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

**systemd-boot** (`/boot/loader/entries/*.conf`):
```
options ... nvidia-drm.modeset=1
```

### Required Environment Variables

```bash
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1           # fix invisible/glitchy cursor
export LIBVA_DRIVER_NAME=nvidia            # hardware video acceleration
```

In Hyprland config:
```conf
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = LIBVA_DRIVER_NAME,nvidia
```

### Required Packages (Manjaro)

```bash
sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils
sudo pacman -S egl-wayland                  # EGL support for Wayland
```

### Verify Nvidia DRM Modeset

```bash
cat /sys/module/nvidia_drm/parameters/modeset    # must be Y
lsmod | grep nvidia_drm                          # must be loaded
```

### Nvidia Sleep/Resume Fix

```bash
sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate
# Add kernel parameter:
nvidia.NVreg_PreserveVideoMemoryAllocations=1
```

### Known Nvidia Issues

| Issue | Status | Workaround |
|-------|--------|------------|
| Hardware cursor glitches | Fixed in driver 545+ | `WLR_NO_HARDWARE_CURSORS=1` |
| Flickering with VRR | Partially fixed 545+ | Update driver, test |
| Screen sharing black screen | Fixed with portals | Install correct portal |
| Suspend/resume crashes | Fixed with services | Enable nvidia-suspend/resume |
| XWayland blurry | By design | `force_zero_scaling = true` |
| Explicit sync | Supported 555+ | Ensure compositor supports it |
| Multi-GPU (Nvidia + Intel/AMD) | Works | Set PRIME correctly |

### Nvidia Driver Version Recommendations

- **Minimum for Wayland:** 510+
- **Recommended:** 545+ (hardware cursor fix, explicit sync prep)
- **Best:** 555+ (explicit sync, improved VRR, better stability)

## AMD on Wayland: AMDGPU Setup

AMD GPUs work with the open-source `amdgpu` kernel driver. Wayland support is excellent.

### Verify Driver

```bash
lspci -k | grep -A 3 -i vga         # should show "amdgpu" as kernel driver
lsmod | grep amdgpu
```

### Required Packages (Manjaro)

```bash
sudo pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
sudo pacman -S libva-mesa-driver lib32-libva-mesa-driver    # VA-API
```

### Performance Tuning

```bash
# Check current GPU clock
cat /sys/class/drm/card1/device/pp_dpm_sclk

# Enable performance mode
echo "high" | sudo tee /sys/class/drm/card1/device/power_dpm_force_performance_level

# OverDrive (if supported)
echo "s 1 1800" | sudo tee /sys/class/drm/card1/device/pp_od_clk_voltage
echo "c" | sudo tee /sys/class/drm/card1/device/pp_od_clk_voltage
```

### VRR on AMD

VRR works natively with AMD. Ensure:
1. Monitor has FreeSync enabled in OSD
2. Connected via DisplayPort (or HDMI 2.1 for HDMI VRR)
3. Compositor VRR is enabled
4. Check: `cat /sys/class/drm/card1-DP-1/vrr_capable`

## Intel on Wayland

Intel GPUs (integrated and Arc discrete) use the `i915` or `xe` kernel driver.

### Verify Driver

```bash
lspci -k | grep -A 3 -i vga         # should show "i915" or "xe"
```

### Required Packages (Manjaro)

```bash
sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel
sudo pacman -S intel-media-driver                # VA-API (modern Intel)
# Or for older Intel:
sudo pacman -S libva-intel-driver
```

### Intel-Specific Notes

- VRR: Supported on Intel 12th gen+ with i915/xe and DisplayPort
- PSR (Panel Self-Refresh): Can cause flickering. Disable if needed:
  ```bash
  # Add kernel parameter:
  i915.enable_psr=0
  ```
- Intel Arc (discrete): Use `xe` driver on newer kernels or `i915` on older ones

## Mixed GPU: PRIME and Render Offloading

### Detect GPUs

```bash
ls /dev/dri/render*                   # renderD128, renderD129, etc.
cat /sys/class/drm/card*/device/vendor
# 0x10de = Nvidia, 0x1002 = AMD, 0x8086 = Intel
```

### PRIME Render Offloading

Run specific apps on the discrete GPU while the integrated GPU handles the display:

```bash
# AMD/Intel integrated + Nvidia discrete
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia application
# Or for Vulkan:
__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only application

# AMD/Intel integrated + AMD discrete
DRI_PRIME=1 application

# Check which GPU is being used
DRI_PRIME=1 glxinfo | grep "OpenGL renderer"
```

### Compositor GPU Selection

Force the compositor to run on a specific GPU:

```bash
# Sway: specify DRM device
WLR_DRM_DEVICES=/dev/dri/card1 sway              # use specific GPU
WLR_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1 sway  # primary:secondary

# Hyprland: same mechanism
WLR_DRM_DEVICES=/dev/dri/card1 Hyprland

# KDE: handled by kwin_wayland automatically, respects PRIME
```

### Multi-GPU Monitor Assignment

You can connect different monitors to different GPUs. The compositor must support multi-GPU rendering:
- **Hyprland:** Supports multi-GPU (wlroots handles it)
- **Sway:** Supports multi-GPU via wlroots
- **KDE:** Supports multi-GPU via KWin
- **GNOME:** Supports multi-GPU via Mutter

Monitors on the secondary GPU may have slightly higher latency due to buffer copies between GPUs. This is normal.

## Issue 16: Wayland Session Won't Start (Falls Back to X11)

**Symptoms:** Login manager starts X11 instead of Wayland, or Wayland session crashes immediately.

**Steps:**
1. Check if Wayland session is available:
   ```bash
   ls /usr/share/wayland-sessions/
   ```
2. Try starting manually from TTY:
   ```bash
   # Hyprland
   Hyprland
   # Sway
   sway
   # KDE
   startplasma-wayland
   ```
3. Check the error output for missing dependencies.
4. For Nvidia: ensure `nvidia-drm.modeset=1` is set and EGL Wayland is installed.
5. Check SDDM/GDM configuration allows Wayland sessions.

## Issue 17: Electron Apps Not Using Wayland

**Symptoms:** VS Code, Discord, Slack, etc. run under XWayland instead of native Wayland.

**Steps:**
1. Check if the app is running on XWayland:
   ```bash
   hyprctl clients -j | jq '.[] | select(.class == "code") | .xwayland'
   ```
2. Force Wayland:
   ```bash
   # Global environment variable
   export ELECTRON_OZONE_PLATFORM_HINT=wayland

   # Per-app flag (add to Exec in .desktop file)
   --ozone-platform=wayland --enable-features=UseOzonePlatform,WaylandWindowDecorations
   ```
3. For VS Code specifically, add to `argv.json`:
   ```json
   { "enable-features": "UseOzonePlatform,WaylandWindowDecorations", "ozone-platform": "wayland" }
   ```
4. Note: some Electron apps may have bugs on Wayland. Test before committing to Wayland mode.
