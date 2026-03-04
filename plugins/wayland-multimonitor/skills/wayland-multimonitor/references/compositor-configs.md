# Compositor Configuration Reference

Complete configuration examples for multi-monitor setups across all major Wayland compositors.

## Hyprland: Full Multi-Monitor Configuration

```conf
# ~/.config/hypr/hyprland.conf
# ============================================================
# MULTI-MONITOR CONFIGURATION
# ============================================================

# --- Monitor Layout ---
# Triple monitor setup: two 1440p flanking a center 4K
monitor = DP-1, 2560x1440@165, 0x0, 1             # left
monitor = DP-2, 3840x2160@144, 2560x0, 1.5         # center (4K with fractional scale)
monitor = HDMI-A-1, 2560x1440@60, 5120x0, 1        # right
monitor = , preferred, auto, 1                       # fallback for hotplugged monitors

# --- Workspace Assignment ---
workspace = 1, monitor:DP-1, default:true
workspace = 2, monitor:DP-1
workspace = 3, monitor:DP-1
workspace = 4, monitor:DP-2, default:true
workspace = 5, monitor:DP-2
workspace = 6, monitor:DP-2
workspace = 7, monitor:HDMI-A-1, default:true
workspace = 8, monitor:HDMI-A-1
workspace = 9, monitor:HDMI-A-1

# --- XWayland Scaling Fix ---
xwayland {
    force_zero_scaling = true
}

# --- Environment Variables ---
env = XCURSOR_SIZE,32
env = GDK_SCALE,2
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = ELECTRON_OZONE_PLATFORM_HINT,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland

# --- Nvidia (uncomment if using Nvidia GPU) ---
# env = GBM_BACKEND,nvidia-drm
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# env = WLR_NO_HARDWARE_CURSORS,1
# env = LIBVA_DRIVER_NAME,nvidia

# --- VRR / Adaptive Sync ---
misc {
    vrr = 2                    # 0=off, 1=always, 2=fullscreen only
    vfr = true                 # variable frame rate (save power when idle)
    no_direct_scanout = false  # enable direct scanout for fullscreen apps
}

# --- Tearing Control (for competitive gaming) ---
general {
    allow_tearing = true
}
# Apply tearing to specific games
windowrulev2 = immediate, class:^(cs2)$
windowrulev2 = immediate, class:^(steam_app_)(.*)$

# --- Monitor Management Keybinds ---
$mainMod = SUPER

# Focus monitor
bind = $mainMod, comma, focusmonitor, l       # focus left monitor
bind = $mainMod, period, focusmonitor, r      # focus right monitor

# Move window to monitor
bind = $mainMod SHIFT, comma, movewindow, mon:l
bind = $mainMod SHIFT, period, movewindow, mon:r

# Move workspace to monitor
bind = $mainMod CTRL, comma, movecurrentworkspacetomonitor, l
bind = $mainMod CTRL, period, movecurrentworkspacetomonitor, r

# Swap workspaces between monitors
bind = $mainMod ALT, comma, swapactiveworkspaces, DP-1 DP-2
bind = $mainMod ALT, period, swapactiveworkspaces, DP-2 HDMI-A-1

# Mirror toggle (bind to key for quick mirror)
# bind = $mainMod, M, exec, hyprctl keyword monitor DP-2,2560x1440@60,0x0,1,mirror,DP-1

# --- Autostart ---
exec-once = kanshi                             # dynamic output switching
exec-once = waybar                             # status bar
exec-once = gammastep -l 45.0:9.0              # night light
exec-once = /usr/lib/xdg-desktop-portal-hyprland  # screen sharing
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# --- Animations for Monitor Transitions ---
animations {
    enabled = true
    bezier = monitorSwitch, 0.25, 1, 0.5, 1
    animation = workspaces, 1, 4, monitorSwitch, slidevert
}
```

### Hyprland: Laptop with Dock Profile

```conf
# Laptop monitor (lid open, no external)
monitor = eDP-1, 2880x1800@90, 0x0, 1.5

# When docked: disable laptop screen, use externals
# Uncomment when docked:
# monitor = eDP-1, disable
# monitor = DP-3, 3840x2160@60, 0x0, 1.5
# monitor = DP-4, 2560x1440@165, 2560x0, 1

# Fallback
monitor = , preferred, auto, 1
```

### Hyprland: Vertical Monitor Setup

```conf
# Horizontal primary
monitor = DP-1, 2560x1440@165, 0x0, 1

# Vertical secondary (rotated 90 degrees)
monitor = DP-2, 2560x1440@165, 2560x0, 1, transform, 1

# Position: vertical monitor is 1440px wide after rotation
# Adjust Y offset to align top edges or center
```

## Sway: Full Multi-Monitor Configuration

```conf
# ~/.config/sway/config
# ============================================================
# MULTI-MONITOR CONFIGURATION
# ============================================================

# --- Output Configuration ---
output DP-1 {
    mode 2560x1440@165Hz
    pos 0 0
    scale 1
    bg ~/wallpapers/left.png fill
    adaptive_sync on
}

output DP-2 {
    mode 2560x1440@165Hz
    pos 2560 0
    scale 1
    bg ~/wallpapers/center.png fill
    adaptive_sync on
}

output HDMI-A-1 {
    mode 1920x1080@60Hz
    pos 5120 0
    scale 1
    bg ~/wallpapers/right.png fill
}

# --- Laptop lid (close lid = disable internal display) ---
# output eDP-1 mode 1920x1080@60Hz pos 0 0 scale 1.25
# bindswitch --reload --locked lid:on output eDP-1 disable
# bindswitch --reload --locked lid:off output eDP-1 enable

# --- Workspace to Output ---
workspace 1 output DP-1
workspace 2 output DP-1
workspace 3 output DP-1
workspace 4 output DP-2
workspace 5 output DP-2
workspace 6 output DP-2
workspace 7 output HDMI-A-1
workspace 8 output HDMI-A-1
workspace 9 output HDMI-A-1

# --- Disable Output ---
# output HDMI-A-1 disable

# --- Transform (rotation) ---
# output DP-2 transform 90

# --- Focus / Move between outputs ---
set $mod Mod4

bindsym $mod+comma focus output left
bindsym $mod+period focus output right
bindsym $mod+Shift+comma move container to output left
bindsym $mod+Shift+period move container to output right
bindsym $mod+Ctrl+comma move workspace to output left
bindsym $mod+Ctrl+period move workspace to output right

# --- Autostart ---
exec kanshi
exec gammastep -l 45.0:9.0
exec /usr/lib/xdg-desktop-portal-wlr
exec waybar

# --- Environment ---
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway
```

### Sway: Runtime Commands Reference

```bash
# List outputs
swaymsg -t get_outputs
swaymsg -t get_outputs | jq '.[].name'

# Change output mode at runtime
swaymsg output DP-1 mode 2560x1440@165Hz
swaymsg output DP-1 scale 1.5
swaymsg output DP-1 pos 0 0
swaymsg output DP-1 transform 90
swaymsg output DP-1 enable
swaymsg output DP-1 disable

# Move focused workspace to output
swaymsg move workspace to output DP-2

# Move specific workspace to output
swaymsg '[workspace=3]' move workspace to output DP-2
```

## KDE Plasma: kscreen-doctor Commands Reference

```bash
# ============================================================
# KDE PLASMA WAYLAND - kscreen-doctor REFERENCE
# ============================================================

# --- List outputs and their modes ---
kscreen-doctor --outputs

# --- Set mode (by index from --outputs listing) ---
kscreen-doctor output.DP-1.mode.0              # first mode (usually highest)
kscreen-doctor output.DP-1.mode.1              # second mode

# --- Set scale ---
kscreen-doctor output.DP-1.scale.1             # 100%
kscreen-doctor output.DP-1.scale.1.25          # 125%
kscreen-doctor output.DP-1.scale.1.5           # 150%
kscreen-doctor output.DP-1.scale.2             # 200%

# --- Set position ---
kscreen-doctor output.DP-1.position.0,0
kscreen-doctor output.DP-2.position.2560,0

# --- Set rotation ---
kscreen-doctor output.DP-1.rotation.none       # normal
kscreen-doctor output.DP-1.rotation.right      # 90 degrees
kscreen-doctor output.DP-1.rotation.inverted   # 180 degrees
kscreen-doctor output.DP-1.rotation.left       # 270 degrees

# --- Enable / Disable ---
kscreen-doctor output.DP-1.enable
kscreen-doctor output.DP-1.disable

# --- Set primary ---
kscreen-doctor output.DP-1.primary

# --- Multiple changes at once ---
kscreen-doctor \
    output.DP-1.mode.0 \
    output.DP-1.position.0,0 \
    output.DP-1.scale.1 \
    output.DP-2.mode.0 \
    output.DP-2.position.2560,0 \
    output.DP-2.scale.1.5

# --- Saved profiles location ---
# ~/.local/share/kscreen/
# Profiles are saved automatically when you change display configuration
# KDE matches profiles by monitor EDID serial numbers

# --- Adaptive Sync ---
# Enabled via System Settings -> Display and Monitor -> per output checkbox
# Or via kscreen-doctor (KDE 6+):
# kscreen-doctor output.DP-1.vrr.automatic
```

### KDE: Environment Variables

```bash
# Force Wayland for Qt apps
export QT_QPA_PLATFORM=wayland

# Wayland for GTK apps (KDE sets this)
export GDK_BACKEND=wayland

# KDE session variables (usually set by startplasma-wayland)
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=KDE
```

## kanshi: Dynamic Output Profiles

```conf
# ~/.config/kanshi/config
# ============================================================
# DYNAMIC OUTPUT CONFIGURATION
# ============================================================

# --- Triple Monitor (Desktop) ---
profile triple-desktop {
    output DP-1 mode 2560x1440@165Hz position 0,0 scale 1
    output DP-2 mode 2560x1440@165Hz position 2560,0 scale 1
    output HDMI-A-1 mode 1920x1080@60Hz position 5120,0 scale 1
    exec notify-send "Triple monitor desktop"
    exec swaymsg workspace 1, move workspace to output DP-1
}

# --- Dual Monitor ---
profile dual {
    output DP-1 mode 2560x1440@165Hz position 0,0 scale 1
    output DP-2 mode 2560x1440@165Hz position 2560,0 scale 1
    exec notify-send "Dual monitor setup"
}

# --- Docked Laptop (lid closed, external monitors) ---
profile docked-lid-closed {
    output eDP-1 disable
    output DP-3 mode 3840x2160@60Hz position 0,0 scale 1.5
    output DP-4 mode 2560x1440@165Hz position 2560,0 scale 1
    exec notify-send "Docked mode (lid closed)"
}

# --- Docked Laptop (lid open, external + laptop) ---
profile docked-lid-open {
    output eDP-1 mode 1920x1080@60Hz position 0,1440 scale 1
    output DP-3 mode 3840x2160@60Hz position 0,0 scale 1.5
    output DP-4 mode 2560x1440@165Hz position 2560,0 scale 1
    exec notify-send "Docked mode (lid open)"
}

# --- Undocked (laptop only) ---
profile undocked {
    output eDP-1 mode 1920x1080@60Hz position 0,0 scale 1.25
    exec notify-send "Undocked - laptop only"
}

# --- Presentation Mode (external projector) ---
profile presentation {
    output eDP-1 mode 1920x1080@60Hz position 0,0 scale 1
    output HDMI-A-1 mode 1920x1080@60Hz position 1920,0 scale 1
    exec notify-send "Presentation mode"
}

# --- Vertical + Horizontal ---
profile vertical-horizontal {
    output DP-1 mode 2560x1440@165Hz position 0,0 scale 1
    output DP-2 mode 2560x1440@165Hz position 2560,0 scale 1 transform 90
    exec notify-send "Vertical + horizontal layout"
}

# --- Single External (conference room) ---
profile single-external {
    output eDP-1 disable
    output HDMI-A-1 mode 1920x1080@60Hz position 0,0 scale 1
    exec notify-send "Single external display"
}
```

### kanshi: Usage and Tips

```bash
# Start kanshi (add to compositor autostart)
kanshi &

# Reload config
kanshictl reload

# Switch profile manually (kanshi 1.4+)
kanshictl switch triple-desktop

# Debug: run in foreground with verbose output
kanshi -v

# systemd user service
# ~/.config/systemd/user/kanshi.service
# [Unit]
# Description=Dynamic output configuration
# PartOf=graphical-session.target
# After=graphical-session.target
#
# [Service]
# ExecStart=/usr/bin/kanshi
# Restart=on-failure
#
# [Install]
# WantedBy=graphical-session.target
```

## waybar: Multi-Monitor Status Bar Configuration

```jsonc
// ~/.config/waybar/config
// Each monitor gets its own waybar instance
[
    {
        "output": "DP-1",
        "position": "top",
        "height": 30,
        "modules-left": ["hyprland/workspaces", "hyprland/window"],
        "modules-center": ["clock"],
        "modules-right": ["pulseaudio", "network", "cpu", "memory", "tray"],
        "hyprland/workspaces": {
            "format": "{name}",
            "on-click": "activate",
            "sort-by-number": true
        },
        "clock": {
            "format": "{:%H:%M}",
            "format-alt": "{:%Y-%m-%d %H:%M:%S}",
            "tooltip-format": "<tt>{calendar}</tt>"
        },
        "cpu": {
            "format": "CPU {usage}%",
            "interval": 2
        },
        "memory": {
            "format": "RAM {percentage}%"
        },
        "network": {
            "format-wifi": "{essid} ({signalStrength}%)",
            "format-ethernet": "ETH {ipaddr}",
            "format-disconnected": "Disconnected"
        },
        "pulseaudio": {
            "format": "VOL {volume}%",
            "on-click": "pavucontrol"
        }
    },
    {
        "output": "DP-2",
        "position": "top",
        "height": 30,
        "modules-left": ["hyprland/workspaces"],
        "modules-center": ["clock"],
        "modules-right": ["cpu", "memory"],
        "hyprland/workspaces": {
            "format": "{name}",
            "on-click": "activate",
            "sort-by-number": true
        }
    },
    {
        "output": "HDMI-A-1",
        "position": "top",
        "height": 30,
        "modules-left": ["hyprland/workspaces"],
        "modules-center": [],
        "modules-right": ["clock"],
        "hyprland/workspaces": {
            "format": "{name}",
            "on-click": "activate",
            "sort-by-number": true
        }
    }
]
```

### waybar for Sway

```jsonc
// Replace "hyprland/workspaces" with "sway/workspaces"
// Replace "hyprland/window" with "sway/window"
{
    "output": "DP-1",
    "modules-left": ["sway/workspaces", "sway/window"],
    "sway/workspaces": {
        "disable-scroll": false,
        "format": "{name}"
    }
}
```

## Environment Variables for All Compositors

```bash
# ============================================================
# UNIVERSAL WAYLAND ENVIRONMENT VARIABLES
# Set in ~/.profile, ~/.bashrc, or compositor env config
# ============================================================

# --- Core Wayland ---
export XDG_SESSION_TYPE=wayland
# XDG_CURRENT_DESKTOP should match your compositor:
#   Hyprland, sway, KDE, GNOME

# --- Toolkit Backends ---
export QT_QPA_PLATFORM=wayland           # Qt: use Wayland
export GDK_BACKEND=wayland               # GTK: use Wayland
export SDL_VIDEODRIVER=wayland            # SDL2: use Wayland
export CLUTTER_BACKEND=wayland           # Clutter: use Wayland
export MOZ_ENABLE_WAYLAND=1              # Firefox: native Wayland
export ELECTRON_OZONE_PLATFORM_HINT=wayland  # Electron: Wayland (auto-detect)

# --- Scaling ---
export XCURSOR_SIZE=24                   # cursor size (adjust for scale)
export QT_AUTO_SCREEN_SCALE_FACTOR=1     # Qt: auto scale from compositor
# export QT_SCALE_FACTOR=1.5            # Qt: manual scale override
# export GDK_SCALE=2                    # GTK3: integer scale
# export GDK_DPI_SCALE=0.5             # GTK3: DPI adjustment

# --- Qt Theming ---
export QT_QPA_PLATFORMTHEME=qt6ct       # or qt5ct, kde, gnome
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1  # use compositor decorations

# --- Nvidia (if applicable) ---
# export GBM_BACKEND=nvidia-drm
# export __GLX_VENDOR_LIBRARY_NAME=nvidia
# export WLR_NO_HARDWARE_CURSORS=1
# export LIBVA_DRIVER_NAME=nvidia

# --- Screen Sharing / Portals ---
# These are usually set by the compositor's startup script
# export XDG_CURRENT_DESKTOP=Hyprland   # match your compositor
# Ensure xdg-desktop-portal and the compositor-specific portal are running

# --- Java (for Java GUI apps on Wayland) ---
export _JAVA_AWT_WM_NONREPARENTING=1

# --- Input Method ---
export GTK_IM_MODULE=fcitx              # or ibus
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```
