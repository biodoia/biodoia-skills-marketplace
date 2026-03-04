---
name: wayland-multimonitor
description: This skill should be used when the user asks about "wayland", "multi monitor", "display setup", "hyprland monitor", "sway output", "KDE wayland", "fractional scaling", "wlr-randr", "kanshi", "screen tearing", "VRR", or "gamescope". Make sure to use this skill whenever the user wants to set up, configure, or troubleshoot multi-monitor displays on Wayland, including compositor configuration, resolution, scaling, positioning, hotplugging, gaming, screen sharing, or XWayland blurriness, even if they just mention display issues or monitor setup without explicitly saying Wayland.
---

# Wayland Multi-Monitor Expert

Complete reference for setting up, configuring, and troubleshooting multi-monitor displays on Wayland compositors. Covers Hyprland, Sway, KDE Plasma, and GNOME with deep dives into fractional scaling, gaming, screen sharing, and hardware-specific issues.

## Wayland Fundamentals

### Wayland vs X11: What Changed for Multi-Monitor

In X11, a single X server manages all displays through a monolithic coordinate system. xrandr is the universal tool. In Wayland, the compositor IS the display server -- each compositor implements monitor management differently, with its own configuration syntax, tools, and capabilities.

Key differences:
- **No universal xrandr.** Each compositor has its own tool (wlr-randr, kscreen-doctor, hyprctl, swaymsg).
- **Per-monitor scaling.** Wayland natively supports different scale factors on each display.
- **Fractional scaling.** Wayland protocols support non-integer scales (1.25, 1.5, 1.75).
- **Per-monitor refresh rates.** Each output runs its own rendering loop independently.
- **Buffer management.** Clients render to buffers that the compositor places on outputs.

### Display Detection Tools

**wlr-randr** -- For wlroots-based compositors (Sway, Hyprland, river, dwl):
```bash
wlr-randr                          # list all outputs with modes
wlr-randr --output DP-1 --mode 2560x1440@165Hz  # set mode
wlr-randr --output DP-2 --scale 1.5              # set scale
wlr-randr --output HDMI-A-1 --off                # disable output
```

**Compositor-specific commands:**
```bash
# Sway
swaymsg -t get_outputs              # JSON output of all displays

# Hyprland
hyprctl monitors                    # detailed monitor info
hyprctl monitors -j                 # JSON format

# KDE Plasma
kscreen-doctor --outputs            # list outputs

# GNOME
gnome-randr                         # list outputs (if installed)
```

**Low-level diagnostic tools:**
```bash
wayland-info                        # protocol and interface info
drm_info                            # kernel DRM device info
edid-decode < /sys/class/drm/card1-DP-1/edid  # decode monitor EDID data
cat /sys/class/drm/card1-*/status   # connector status (connected/disconnected)
```

## Compositor Configuration Quick Reference

Detailed, complete configuration examples for all compositors are in `references/compositor-configs.md`. Below is the essential syntax for each.

### Hyprland

Monitor configuration goes in `~/.config/hypr/hyprland.conf`.

```
monitor = name, resolution@refresh, position, scale
```

**Multi-monitor example:**
```conf
monitor = DP-1, 2560x1440@165, 0x0, 1
monitor = DP-2, 2560x1440@165, 2560x0, 1
monitor = HDMI-A-1, 1920x1080@60, 5120x0, 1
monitor = , preferred, auto, 1                # fallback for hotplugged monitors
```

**Workspace assignment:**
```conf
workspace = 1, monitor:DP-1
workspace = 3, monitor:DP-2
workspace = 5, monitor:HDMI-A-1
```

**Fractional scaling and rotation:**
```conf
monitor = DP-1, 3840x2160@60, 0x0, 1.5       # 4K at 150%
monitor = DP-2, 2560x1440@165, 2560x0, 1, transform, 1  # 90 degrees
```

**Runtime changes:**
```bash
hyprctl keyword monitor DP-2,2560x1440@165,2560x0,1
hyprctl dispatch moveworkspacetomonitor 3 DP-2
hyprctl dispatch focusmonitor DP-1
```

### Sway

Output configuration goes in `~/.config/sway/config`.

```conf
output DP-1 mode 2560x1440@165Hz pos 0 0 scale 1
output DP-2 mode 2560x1440@165Hz pos 2560 0 scale 1
workspace 1 output DP-1
workspace 3 output DP-2
```

**Runtime changes:**
```bash
swaymsg output DP-1 mode 2560x1440@165Hz pos 0 0 scale 1
swaymsg output HDMI-A-1 disable
swaymsg move workspace to output DP-2
```

### KDE Plasma

Manage monitors through System Settings -> Display and Monitor, or via kscreen-doctor CLI. Profiles are stored in `~/.local/share/kscreen/` and auto-applied when the same monitor combination is detected.

### GNOME

Use Settings -> Displays for arrangement, resolution, scale, and refresh rate. Enable fractional scaling with:
```bash
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
```
Layout is saved in `~/.config/monitors.xml`.

## kanshi -- Dynamic Output Configuration

kanshi auto-switches profiles when monitors are connected or disconnected. Ideal for laptops with docking stations. Runs on wlroots compositors (Sway, Hyprland).

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
```

Start kanshi as a daemon (`exec kanshi` in Sway, `exec-once = kanshi` in Hyprland). See `references/compositor-configs.md` for advanced kanshi profile examples.

## Fractional Scaling

### Integer vs Fractional

Integer scaling (1x, 2x, 3x) is pixel-perfect. Fractional scaling (1.25x, 1.5x, 1.75x) requires interpolation, which can cause slight blurring on non-fractional-aware toolkits.

### XWayland Scaling Issues

XWayland renders at scale 1 by default. The compositor upscales the result, making X11 apps blurry at non-integer scales.

**Hyprland fix:**
```conf
xwayland {
    force_zero_scaling = true
}
env = GDK_SCALE,2
```

### Toolkit Environment Variables

```bash
# GTK
export GDK_SCALE=2                     # integer scale for GTK3
export GDK_DPI_SCALE=0.5               # DPI adjustment (use with GDK_SCALE=2)

# Qt
export QT_AUTO_SCREEN_SCALE_FACTOR=1   # auto-detect from compositor
export QT_SCALE_FACTOR=1.5             # manual override

# Electron apps (Chrome, VS Code, Discord, Slack)
--force-device-scale-factor=1.5         # per-app flag
export ELECTRON_OZONE_PLATFORM_HINT=wayland  # force Wayland backend

# Cursor size (must match across all toolkits)
export XCURSOR_SIZE=32                  # adjust per scale (24 at 1x, 32 at 1.5x, 48 at 2x)
```

## Gaming and Performance

### VRR (Variable Refresh Rate)

VRR allows the monitor refresh rate to match the GPU frame rate, eliminating tearing.

**Hyprland:** `misc { vrr = 1 }` (0=off, 1=on, 2=fullscreen only)

**KDE Plasma:** System Settings -> Display and Monitor -> check "Adaptive Sync" per output.

**Verify VRR:**
```bash
cat /sys/class/drm/card1-DP-1/vrr_capable    # 1 = monitor supports VRR
```

### Tearing Control

The wp-tearing-control-v1 protocol allows clients to opt into tearing for lowest-latency gaming:
```conf
general {
    allow_tearing = true
}
windowrulev2 = immediate, class:^(cs2)$
```

### gamescope

gamescope is a micro-compositor by Valve for gaming, providing precise control over resolution, refresh rate, and scaling:
```bash
gamescope -W 2560 -H 1440 -r 165 -f -- game_executable
gamescope --adaptive-sync -r 165 -- game_executable
gamescope -w 1920 -h 1080 -W 2560 -H 1440 -F fsr -- game_executable  # FSR upscaling
```

gamescope only manages one display. Use it for the gaming monitor while the compositor manages the rest.

### Multi-GPU (PRIME)

```bash
ls /dev/dri/render*                     # check available GPUs
DRI_PRIME=1 application                 # run app on discrete GPU
vulkaninfo --summary                    # list Vulkan devices
```

## Screen Sharing and Recording

### PipeWire + xdg-desktop-portal

Screen sharing on Wayland uses PipeWire and xdg-desktop-portal. Install the correct portal for the compositor:
```bash
# Hyprland
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal

# Sway / wlroots
sudo pacman -S xdg-desktop-portal-wlr xdg-desktop-portal

# KDE
sudo pacman -S xdg-desktop-portal-kde xdg-desktop-portal
```

**Verify PipeWire:**
```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

### Recording and Screenshots

```bash
# wf-recorder (wlroots compositors)
wf-recorder -o DP-1                  # record specific output
wf-recorder -g "$(slurp)"           # record selected region
wf-recorder -o DP-1 -c h264_vaapi   # hardware-accelerated encoding

# grim: screenshot tool for Wayland
grim -o DP-1 screenshot.png          # specific output
grim -g "$(slurp)" - | wl-copy       # region to clipboard
```

### Electron App Screen Sharing (Discord, Slack)

Launch with these flags for PipeWire screen sharing support:
```bash
--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland
```

## Color Management

- **KDE Plasma:** Full ICC profile support in System Settings -> Display and Monitor -> Color Profile.
- **GNOME:** ICC profiles in Settings -> Color for each display.
- **Hyprland/Sway:** Limited. Use `dispwin` from ArgyllCMS or wait for color-management-v1 protocol.

**Night light:**
```bash
gammastep -l 45.0:9.0 -t 6500:3500   # lat:lon, day:night temperature
# Add to compositor autostart: exec gammastep / exec-once = gammastep
```

HDR on Wayland is experimental. KDE Plasma 6+ has initial HDR support. gamescope has the most mature HDR support for gaming.

## Troubleshooting Quick Reference

For comprehensive step-by-step solutions to 15+ issues including GPU-specific guides, see `references/troubleshooting.md`. Summary of common issues:

| Issue | Quick Fix |
|-------|-----------|
| Black screen after adding monitor | Check `cat /sys/class/drm/card1-*/status`, force safe mode with `wlr-randr --output DP-2 --mode 1920x1080@60Hz` |
| Wrong resolution detected | Check cable bandwidth (DP 1.2 vs 1.4, HDMI 2.0 vs 2.1), verify EDID with `edid-decode` |
| XWayland apps blurry | Set `xwayland { force_zero_scaling = true }`, set `GDK_SCALE`, `QT_SCALE_FACTOR` |
| Cursor size inconsistent | Set `XCURSOR_SIZE=32` globally and in compositor env config |
| Screen tearing | Enable VRR (`misc { vrr = 1 }`), check GPU driver |
| Screen sharing black screen | Verify PipeWire + portal: `systemctl --user status pipewire xdg-desktop-portal` |
| Nvidia issues | Set `nvidia-drm.modeset=1`, set `GBM_BACKEND=nvidia-drm`, `WLR_NO_HARDWARE_CURSORS=1` |
| VRR not working | Check `vrr_capable` sysfs, check cable (DP or HDMI 2.1 required), enable in monitor OSD |

## Additional Resources

- **`references/compositor-configs.md`** -- Complete, production-ready configuration examples for Hyprland, Sway, KDE, kanshi, and waybar multi-monitor setups. Includes keybinds, autostart, Nvidia env vars, and universal environment variables. Consult when setting up a new multi-monitor configuration from scratch.
- **`references/troubleshooting.md`** -- Comprehensive 15+ issue troubleshooting guide with step-by-step solutions, diagnostic command checklist, and GPU-specific guides for Nvidia, AMD, and Intel. Includes PRIME multi-GPU setup, sleep/resume fixes, and Electron Wayland migration. Consult when diagnosing any display issue.
