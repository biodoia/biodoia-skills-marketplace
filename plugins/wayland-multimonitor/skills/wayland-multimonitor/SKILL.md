---
name: wayland-multimonitor
description: "Use when setting up, configuring, or troubleshooting multi-monitor displays on Wayland, including compositor configuration, resolution, scaling, positioning, hotplugging, gaming, and screen sharing. Also use when mentioning 'wayland', 'multi monitor', 'display setup', 'hyprland monitor', 'sway output', 'KDE wayland', 'fractional scaling', 'wlr-randr', 'kanshi', 'screen tearing', or 'VRR'."
---

# Wayland Multi-Monitor Expert

Complete reference for setting up, configuring, and troubleshooting multi-monitor displays on Wayland compositors. Covers Hyprland, Sway, KDE Plasma, and GNOME with deep dives into fractional scaling, gaming, screen sharing, and hardware-specific issues.

## Wayland Fundamentals

### Wayland vs X11: What Changed for Multi-Monitor

In X11, a single X server manages all displays through a monolithic coordinate system. xrandr is the universal tool. In Wayland, the compositor IS the display server. There is no separate X server process. Each compositor implements monitor management differently, with its own configuration syntax, tools, and capabilities.

Key differences:
- **No universal xrandr.** Each compositor has its own tool (wlr-randr, kscreen-doctor, hyprctl, swaymsg).
- **Per-monitor scaling.** Wayland natively supports different scale factors on each display. X11 fakes this badly.
- **Fractional scaling.** Wayland protocols support non-integer scales (1.25, 1.5, 1.75). X11 only does integer scaling natively.
- **Per-monitor refresh rates.** Each output runs its own rendering loop. A 165Hz monitor and a 60Hz monitor work independently without throttling each other.
- **Buffer management.** Clients render to buffers that the compositor places on outputs. No more tearing from the display server side (though tearing control is now an opt-in protocol).

### Compositor = Display Server

On Wayland, the compositor is the display server. There is no separate layer. Hyprland, Sway, KDE KWin, and GNOME Mutter each implement the Wayland protocol directly. This means monitor configuration is compositor-specific. A Hyprland config does not work on Sway. Tools built for wlroots compositors (wlr-randr) do not work on KDE or GNOME.

### Per-Monitor Scaling and Fractional Scaling

Wayland compositors can set different scale factors per output. A 4K 27" monitor at scale 1.5 and a 1080p 24" monitor at scale 1 work side by side. The wp-fractional-scale-v1 protocol allows clients to render at fractional scales without blurring. XWayland apps (X11 apps running under Wayland) may not honor fractional scaling and can appear blurry unless the compositor upscales them.

## Display Detection and Information

### Detection Tools by Compositor

**wlr-randr** -- For wlroots-based compositors (Sway, Hyprland, river, dwl):
```bash
wlr-randr                          # list all outputs with modes
wlr-randr --output DP-1 --mode 2560x1440@165Hz  # set mode
wlr-randr --output DP-2 --scale 1.5              # set scale
wlr-randr --output HDMI-A-1 --off                # disable output
```

**kscreen-doctor** -- For KDE Plasma:
```bash
kscreen-doctor --outputs            # list outputs
kscreen-doctor output.DP-1.mode.0   # set mode by index
kscreen-doctor output.DP-1.scale.1.5  # set scale
kscreen-doctor output.DP-1.disable    # disable
```

**gnome-randr** / gsettings -- For GNOME:
```bash
gnome-randr                         # list outputs (if installed)
gsettings get org.gnome.mutter experimental-features  # check fractional scaling
```

**Compositor-specific commands:**
```bash
# Sway
swaymsg -t get_outputs              # JSON output of all displays
swaymsg -t get_outputs | jq '.[].name'  # just output names

# Hyprland
hyprctl monitors                    # detailed monitor info
hyprctl monitors -j                 # JSON format
hyprctl monitors -j | jq '.[].name' # just names
```

**Low-level diagnostic tools:**
```bash
wayland-info                        # protocol and interface info
drm_info                            # kernel DRM device info (modes, connectors, encoders)
edid-decode < /sys/class/drm/card1-DP-1/edid  # decode monitor EDID data
cat /sys/class/drm/card1-*/status   # connector status (connected/disconnected)
cat /sys/class/drm/card1-*/modes    # available modes from kernel
```

## Hyprland Configuration

Hyprland is the most popular tiling Wayland compositor. Monitor configuration goes in `~/.config/hypr/hyprland.conf`.

### Monitor Syntax

```
monitor = name, resolution@refresh, position, scale
```

**Full multi-monitor example:**
```conf
# ~/.config/hypr/hyprland.conf

# Primary monitor: 2560x1440 at 165Hz, top-left origin
monitor = DP-1, 2560x1440@165, 0x0, 1

# Second monitor: same res, positioned to the right of DP-1
monitor = DP-2, 2560x1440@165, 2560x0, 1

# Third monitor: 1080p at 60Hz, to the right of DP-2
monitor = HDMI-A-1, 1920x1080@60, 5120x0, 1

# Fallback: any unrecognized monitor gets auto-configured
monitor = , preferred, auto, 1
```

**Workspace assignment:**
```conf
workspace = 1, monitor:DP-1
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-2
workspace = 4, monitor:DP-2
workspace = 5, monitor:HDMI-A-1
```

**Fractional scaling:**
```conf
monitor = DP-1, 3840x2160@60, 0x0, 1.5       # 4K at 150%
monitor = eDP-1, 2880x1800@90, 2560x0, 1.25   # laptop at 125%
```

**Transform (rotation):**
```conf
monitor = DP-2, 2560x1440@165, 2560x0, 1, transform, 1  # 90 degrees
# 0=normal, 1=90, 2=180, 3=270, 4=flipped, 5=flipped-90, 6=flipped-180, 7=flipped-270
```

**Mirror mode:**
```conf
monitor = DP-2, 2560x1440@60, 0x0, 1, mirror, DP-1
```

**Disable a monitor:**
```conf
monitor = HDMI-A-1, disable
```

**Adaptive sync / VRR:**
```conf
misc {
    vrr = 1    # 0=off, 1=on, 2=fullscreen only
}
```

**Hotplugging:** Hyprland handles hotplugging automatically. The `monitor = , preferred, auto, 1` fallback rule ensures any newly connected monitor gets configured. To run commands on connect/disconnect, use `hyprctl dispatch` in a script triggered by a udev rule or use the IPC socket.

**Runtime changes:**
```bash
hyprctl keyword monitor DP-2,2560x1440@165,2560x0,1    # change monitor config
hyprctl dispatch moveworkspacetomonitor 3 DP-2           # move workspace 3 to DP-2
hyprctl dispatch focusmonitor DP-1                       # focus a monitor
hyprctl dispatch swapactiveworkspaces DP-1 DP-2          # swap workspaces between monitors
```

## Sway Configuration

Sway uses the `output` directive in `~/.config/sway/config`.

### Output Syntax

```conf
output <name> mode <WxH>@<refresh>Hz pos <X> <Y> scale <factor>
```

**Full multi-monitor example:**
```conf
# ~/.config/sway/config

output DP-1 mode 2560x1440@165Hz pos 0 0 scale 1
output DP-2 mode 2560x1440@165Hz pos 2560 0 scale 1
output HDMI-A-1 mode 1920x1080@60Hz pos 5120 0 scale 1

# Workspace to output binding
workspace 1 output DP-1
workspace 2 output DP-1
workspace 3 output DP-2
workspace 4 output DP-2
workspace 5 output HDMI-A-1

# Background per output
output DP-1 bg ~/wallpapers/left.png fill
output DP-2 bg ~/wallpapers/center.png fill

# Disable output
output HDMI-A-1 disable

# Transform (rotation)
output DP-2 transform 90
```

**Runtime changes with swaymsg:**
```bash
swaymsg output DP-1 mode 2560x1440@165Hz pos 0 0 scale 1
swaymsg output HDMI-A-1 disable
swaymsg output HDMI-A-1 enable
swaymsg move workspace to output DP-2
```

**Scale:**
```conf
output eDP-1 scale 1.5   # fractional scaling (Sway 1.8+)
```

Note: Sway does not natively support VRR/Adaptive Sync as of the latest stable release. Check `sway --version` and release notes for updates.

## KDE Plasma Wayland

KDE Plasma manages monitors through System Settings or kscreen-doctor.

**GUI:** System Settings -> Display and Monitor -> Display Configuration. Drag monitors to arrange them, set resolution, refresh rate, scale, and rotation per monitor.

**kscreen-doctor CLI:**
```bash
kscreen-doctor --outputs                          # list all outputs and modes
kscreen-doctor output.DP-1.mode.0                 # set first available mode
kscreen-doctor output.DP-1.scale.1.5              # set scale
kscreen-doctor output.DP-1.position.0,0           # set position
kscreen-doctor output.DP-1.rotation.right          # rotate
kscreen-doctor output.DP-1.disable                 # disable
kscreen-doctor output.DP-1.enable                  # enable
```

**Saved profiles:** KDE stores display profiles in `~/.local/share/kscreen/`. These are auto-applied when the same monitor combination is detected.

**Fractional scaling:** Supported per-monitor in System Settings. KDE handles XWayland scaling through its own upscaling mechanism.

**Night light:** Per-monitor night color temperature in System Settings -> Display and Monitor -> Night Color.

**Adaptive sync:** System Settings -> Display and Monitor -> check "Adaptive Sync" per output (KDE 6+).

## GNOME Wayland

**GUI:** Settings -> Displays. Arrange monitors, set resolution, scale, and refresh rate. Primary monitor selection available.

**Fractional scaling (not enabled by default):**
```bash
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
```

After enabling, fractional options (125%, 150%, 175%) appear in Settings -> Displays.

**Saved layout:** `~/.config/monitors.xml` stores the display configuration. GNOME applies it automatically on login.

**gnome-randr (third-party):**
```bash
pip install gnome-randr
gnome-randr                         # list outputs
gnome-randr modify DP-1 --mode 2560x1440@165  # set mode
gnome-randr modify DP-1 --scale 1.5            # set scale
```

## kanshi -- Dynamic Output Configuration

kanshi is a dynamic output configuration daemon for wlroots compositors (Sway, Hyprland). It auto-switches profiles when monitors are connected or disconnected. Ideal for laptops with docking stations.

```conf
# ~/.config/kanshi/config

profile docked {
    output DP-1 mode 2560x1440@165Hz position 0,0 scale 1
    output DP-2 mode 2560x1440@165Hz position 2560,0 scale 1
    exec notify-send "Docked mode activated"
}

profile undocked {
    output eDP-1 mode 1920x1080@60Hz position 0,0 scale 1.25
    exec notify-send "Undocked mode"
}

profile home-office {
    output eDP-1 disable
    output HDMI-A-1 mode 3840x2160@60Hz position 0,0 scale 1.5
    exec notify-send "Home office mode"
}
```

**Usage:**
```bash
kanshi &                            # start daemon (add to compositor autostart)
# In Sway config:
exec kanshi
# In Hyprland config:
exec-once = kanshi
```

kanshi monitors for output changes via the Wayland protocol and applies the matching profile. Profiles match by the set of connected output names and models.

## Fractional Scaling Deep Dive

### Integer vs Fractional Scaling

Integer scaling (1x, 2x, 3x) is pixel-perfect: each logical pixel maps to NxN physical pixels. Fractional scaling (1.25x, 1.5x, 1.75x) requires interpolation, which can cause slight blurring on non-fractional-aware toolkits.

### XWayland Scaling Issues

XWayland (the X11 compatibility layer) renders at scale 1 by default. The compositor then upscales the result, making X11 apps blurry at non-integer scales. Workarounds:

**Hyprland:**
```conf
xwayland {
    force_zero_scaling = true
}
env = GDK_SCALE,2
```

**Sway:** XWayland apps are upscaled by the compositor. No per-app fix, but setting toolkit variables helps.

### Toolkit Environment Variables

```bash
# GTK apps
export GDK_SCALE=2                     # integer scale for GTK3 (rounded)
export GDK_DPI_SCALE=0.5               # DPI adjustment (use with GDK_SCALE=2)

# Qt apps
export QT_AUTO_SCREEN_SCALE_FACTOR=1   # auto-detect from compositor
export QT_SCALE_FACTOR=1.5             # manual override
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1  # use compositor decorations

# Electron apps (Chrome, VS Code, Discord, Slack)
--force-device-scale-factor=1.5         # per-app flag
# Or globally:
export ELECTRON_OZONE_PLATFORM_HINT=wayland  # force Wayland backend

# Cursor size (must match across all toolkits)
export XCURSOR_SIZE=32                  # adjust for your scale (24 at 1x, 32 at 1.5x, 48 at 2x)
```

### Mixed DPI Setup

When combining a 4K monitor at scale 1.5 with a 1080p monitor at scale 1, ensure each toolkit respects per-monitor DPI. Most modern Wayland compositors handle this natively. Problems arise with XWayland and older toolkits that read a single global DPI value.

## Gaming and Performance

### VRR (Variable Refresh Rate) / Adaptive Sync

VRR allows the monitor refresh rate to match the GPU frame rate, eliminating tearing and reducing stuttering.

**Hyprland:**
```conf
misc {
    vrr = 1       # 0=off, 1=on (always), 2=fullscreen only
}
```

**KDE Plasma:** System Settings -> Display and Monitor -> check "Adaptive Sync" per output.

**Sway:** VRR is not yet supported in stable Sway. Experimental patches exist.

**Verify VRR is active:**
```bash
cat /sys/class/drm/card1-DP-1/vrr_capable    # 1 = monitor supports VRR
hyprctl monitors -j | jq '.[].vrr'            # check Hyprland VRR state
```

### Direct Scanout

When a fullscreen application is the only visible surface on a monitor, the compositor can bypass its own rendering and present the application buffer directly to the display (direct scanout). This reduces latency and GPU overhead. Most compositors do this automatically for fullscreen games.

### Tearing Control

The wp-tearing-control-v1 Wayland protocol allows clients to opt into tearing (immediate presentation) for lowest-latency gaming. Hyprland supports this via:
```conf
general {
    allow_tearing = true
}
# Per window rule:
windowrulev2 = immediate, class:^(cs2)$
```

### gamescope

gamescope is a micro-compositor by Valve designed for gaming. It creates a nested Wayland session with precise control over resolution, refresh rate, and scaling.

```bash
# Run a game in gamescope on a specific output
gamescope -W 2560 -H 1440 -r 165 -f -- game_executable

# With Steam
gamescope -W 2560 -H 1440 -r 165 -e -- steam -gamepadui

# VRR in gamescope
gamescope --adaptive-sync -r 165 -- game_executable

# Upscaling (FSR)
gamescope -w 1920 -h 1080 -W 2560 -H 1440 -F fsr -- game_executable
```

**Multi-monitor with gamescope:** gamescope only manages one display. Use it for the gaming monitor while the compositor manages the rest.

**MangoHud on Wayland:**
```bash
MANGOHUD=1 game_executable           # enable HUD overlay
mangohud game_executable             # alternative
```

### Multi-GPU (PRIME)

```bash
# Check available GPUs
ls /dev/dri/render*
cat /sys/class/drm/card*/device/vendor

# Run app on specific GPU
DRI_PRIME=1 application               # switch to discrete GPU
__VK_LAYER_NV_optimus=NVIDIA_only application   # Nvidia PRIME

# Vulkan GPU selection
vulkaninfo --summary                   # list Vulkan devices
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json application
```

## Screen Sharing and Recording

### PipeWire + xdg-desktop-portal

Screen sharing on Wayland uses PipeWire and xdg-desktop-portal. Install the correct portal for your compositor:

```bash
# Hyprland
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal

# Sway / wlroots
sudo pacman -S xdg-desktop-portal-wlr xdg-desktop-portal

# KDE
sudo pacman -S xdg-desktop-portal-kde xdg-desktop-portal

# GNOME
sudo pacman -S xdg-desktop-portal-gtk xdg-desktop-portal
```

**Verify PipeWire is running:**
```bash
systemctl --user status pipewire pipewire-pulse wireplumber
pw-cli ls Node | grep -i screen      # check for screen capture nodes
```

### OBS Studio on Wayland

OBS on Wayland uses PipeWire capture:
1. Add source -> Screen Capture (PipeWire)
2. Select the monitor or window to capture
3. Ensure `QT_QPA_PLATFORM=wayland` or run OBS with Wayland backend

```bash
QT_QPA_PLATFORM=wayland obs          # force Wayland backend
```

### wf-recorder

Screen recorder for wlroots compositors:
```bash
wf-recorder -o DP-1                  # record specific output
wf-recorder -g "$(slurp)"           # record selected region
wf-recorder -o DP-1 -f output.mp4   # specify output file
wf-recorder -o DP-1 -c h264_vaapi   # hardware-accelerated encoding
```

### Screenshots

```bash
# grim: screenshot tool for Wayland
grim screenshot.png                   # all outputs
grim -o DP-1 screenshot.png          # specific output
grim -g "$(slurp)" screenshot.png    # region selection with slurp

# Copy to clipboard
grim -g "$(slurp)" - | wl-copy

# flameshot (Wayland support varies)
flameshot gui                         # may need XDG_CURRENT_DESKTOP set
```

### Discord / Slack Screen Sharing

Both apps use Electron and support Wayland screen sharing via xdg-desktop-portal when launched with:
```bash
--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland
```

Add these flags to the `.desktop` file or launch script. Discord screen share works via PipeWire when xdg-desktop-portal is properly configured. Audio sharing requires PipeWire.

## Color Management

### ICC Profiles

Wayland color management is evolving. Current state:
- **KDE Plasma:** Full ICC profile support in System Settings -> Display and Monitor -> Color Profile.
- **GNOME:** ICC profiles in Settings -> Color for each display.
- **Hyprland/Sway:** Limited. Use `dispwin` from ArgyllCMS or wait for the color-management-v1 protocol.

```bash
# Apply ICC profile (colord)
colormgr get-devices                  # list devices
colormgr device-add-profile device_id profile.icc
```

### Night Light / Blue Light Filter

```bash
# gammastep (Wayland-native, successor to redshift)
gammastep -l 45.0:9.0 -t 6500:3500   # lat:lon, day:night temperature

# In Sway config:
exec gammastep -l 45.0:9.0

# In Hyprland config:
exec-once = gammastep -l 45.0:9.0

# KDE: built-in Night Color in System Settings
# GNOME: built-in Night Light in Settings -> Display
```

### HDR

HDR on Wayland is experimental. KDE Plasma 6+ has initial HDR support for capable monitors. Hyprland has experimental HDR support behind feature flags. Check compositor release notes for current status. Gamescope has the most mature HDR support for gaming.

## Troubleshooting

### Black Screen After Adding Monitor

1. Check connector status: `cat /sys/class/drm/card1-*/status`
2. Check kernel logs: `dmesg | grep -i drm`
3. Try a different cable or port
4. Force a mode: `wlr-randr --output DP-2 --mode 1920x1080@60Hz`
5. Check EDID: `edid-decode < /sys/class/drm/card1-DP-2/edid`

### Wrong Resolution Detected

1. List available modes: `wlr-randr` or `hyprctl monitors`
2. Manually set the correct mode in config
3. If the desired mode is missing, check EDID and cable bandwidth (DP 1.2 vs 1.4, HDMI 2.0 vs 2.1)

### XWayland Apps Blurry (Scaling)

1. Set `xwayland { force_zero_scaling = true }` in Hyprland
2. Set toolkit variables: `GDK_SCALE`, `QT_SCALE_FACTOR`
3. For Electron apps: use `--force-device-scale-factor`
4. Check `XCURSOR_SIZE` matches your scale

### Cursor Size Inconsistent

```bash
export XCURSOR_SIZE=32                # set globally in your shell profile
# In Hyprland:
env = XCURSOR_SIZE,32
```

### Screen Tearing

1. Ensure compositor is not using X11 backend
2. Enable VRR if supported: `misc { vrr = 1 }`
3. For games: enable tearing control protocol (Hyprland `allow_tearing = true`)
4. Check GPU driver: `glxinfo | grep "OpenGL renderer"` or `vulkaninfo --summary`

### Screen Sharing Black Screen

1. Verify PipeWire: `systemctl --user status pipewire wireplumber`
2. Verify portal: `systemctl --user status xdg-desktop-portal xdg-desktop-portal-hyprland`
3. Restart portals: `systemctl --user restart xdg-desktop-portal`
4. Check `XDG_CURRENT_DESKTOP` is set correctly
5. For Hyprland: `env = XDG_CURRENT_DESKTOP,Hyprland`

### Nvidia-Specific Issues

```bash
# Required kernel parameters
nvidia-drm.modeset=1                  # MUST be set (GRUB/systemd-boot)

# Required environment variables
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1      # if cursor is invisible or glitchy

# In Hyprland:
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
env = LIBVA_DRIVER_NAME,nvidia

# Check nvidia-drm loaded
lsmod | grep nvidia_drm
cat /sys/module/nvidia_drm/parameters/modeset  # should be Y
```

### VRR Not Working

1. Check monitor capability: `cat /sys/class/drm/card1-DP-1/vrr_capable`
2. Check compositor config (vrr = 1 in Hyprland)
3. Check cable: VRR requires DisplayPort or HDMI 2.1
4. Check GPU driver supports VRR
5. Some monitors need VRR/FreeSync enabled in OSD menu

See `references/troubleshooting.md` for a comprehensive 15+ issue troubleshooting guide with step-by-step solutions.

See `references/compositor-configs.md` for complete configuration examples for all compositors.
