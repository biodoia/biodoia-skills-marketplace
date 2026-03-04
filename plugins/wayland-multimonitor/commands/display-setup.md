---
description: Detect current monitor setup and help configure multi-monitor displays on Wayland
argument-hint: "[action] (e.g. 'detect', 'configure hyprland', 'fix scaling', 'troubleshoot', 'kanshi profile', 'gaming setup', 'screen share fix')"
allowed-tools: ["Read", "Bash", "Glob", "Grep", "Write", "Edit"]
---

# Display Setup Assistant

Detect, configure, and troubleshoot Wayland multi-monitor displays.

**Arguments:** $ARGUMENTS

## Workflow

### Step 1: Detect Environment

Always start by detecting the current system state. Run these commands:

```bash
# Detect compositor
echo "=== COMPOSITOR ==="
echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
echo "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# Detect GPU
echo "=== GPU ==="
lspci -k | grep -A 3 -i vga

# Detect monitors
echo "=== MONITORS ==="
if command -v hyprctl &>/dev/null; then
    echo "[Hyprland detected]"
    hyprctl monitors
elif command -v swaymsg &>/dev/null; then
    echo "[Sway detected]"
    swaymsg -t get_outputs
elif command -v kscreen-doctor &>/dev/null; then
    echo "[KDE detected]"
    kscreen-doctor --outputs
elif command -v wlr-randr &>/dev/null; then
    echo "[wlroots compositor detected]"
    wlr-randr
else
    echo "[Unknown compositor - checking DRM]"
    for conn in /sys/class/drm/card1-*; do
        name=$(basename "$conn")
        status=$(cat "$conn/status" 2>/dev/null)
        echo "$name: $status"
    done
fi

# Check DRM connectors
echo "=== DRM CONNECTORS ==="
for conn in /sys/class/drm/card*-*; do
    name=$(basename "$conn")
    status=$(cat "$conn/status" 2>/dev/null)
    if [ "$status" = "connected" ]; then
        modes=$(head -3 "$conn/modes" 2>/dev/null | tr '\n' ', ')
        vrr=$(cat "$conn/vrr_capable" 2>/dev/null)
        echo "$name: CONNECTED | modes: $modes | vrr_capable: $vrr"
    fi
done

# Check PipeWire and portals (for screen sharing)
echo "=== SERVICES ==="
systemctl --user is-active pipewire 2>/dev/null && echo "PipeWire: active" || echo "PipeWire: inactive"
systemctl --user is-active wireplumber 2>/dev/null && echo "WirePlumber: active" || echo "WirePlumber: inactive"
systemctl --user is-active xdg-desktop-portal 2>/dev/null && echo "xdg-desktop-portal: active" || echo "xdg-desktop-portal: inactive"
```

### Step 2: Route by Action

Based on $ARGUMENTS, proceed with the appropriate action:

#### "detect" or no arguments
- Run detection commands from Step 1
- Present a summary: compositor, GPU vendor, connected monitors (names, resolutions, refresh rates, VRR capability)
- Identify the current configuration file location
- Suggest improvements if any issues are detected

#### "configure hyprland" / "configure sway" / "configure kde"
- Detect connected monitors
- Read the current config file:
  - Hyprland: `~/.config/hypr/hyprland.conf`
  - Sway: `~/.config/sway/config`
  - KDE: check `kscreen-doctor --outputs`
- Generate an optimized monitor configuration based on detected hardware
- Include workspace assignments, VRR settings, and scaling recommendations
- Show the config diff and ask before applying

#### "fix scaling"
- Detect current scale factors per monitor
- Check for XWayland blurriness issues
- Recommend toolkit environment variables (GDK_SCALE, QT_SCALE_FACTOR, XCURSOR_SIZE, Electron flags)
- Generate the env variable block for the compositor config
- Check if `force_zero_scaling` is needed (Hyprland)

#### "troubleshoot"
- Run the full diagnostic checklist from `references/troubleshooting.md`
- Check kernel logs for DRM errors: `dmesg | grep -i drm | tail -20`
- Check compositor logs
- Check GPU driver status
- Identify and report any issues found
- Suggest fixes referencing the troubleshooting guide

#### "kanshi profile"
- Detect all connected monitors
- Generate kanshi profile config for the current setup
- If `~/.config/kanshi/config` exists, read it and offer to add the new profile
- Include exec commands for notifications

#### "gaming setup"
- Check VRR capability per monitor
- Check GPU driver and Vulkan support
- Recommend VRR, tearing control, and gamescope settings
- Check if MangoHud is installed
- Generate compositor-specific gaming config

#### "screen share fix"
- Check PipeWire status
- Check xdg-desktop-portal and compositor-specific portal
- Check XDG_CURRENT_DESKTOP
- Restart portals if needed
- Test with `pw-cli ls Node | grep -i screen`
- Check browser flags for PipeWire support

#### "nvidia fix"
- Check nvidia-drm.modeset status
- Check required environment variables
- Check for missing packages (egl-wayland, nvidia-utils)
- Check nvidia-suspend/resume services
- Generate the complete Nvidia env block for the compositor

### Step 3: Present Results

After running the appropriate action:
1. Summarize findings clearly
2. Show the exact config changes needed (as diffs or complete blocks)
3. Ask for confirmation before writing any config files
4. After applying changes, verify the result by re-running detection

### Reference Files

When you need detailed information, read these skill reference files:
- `skills/wayland-multimonitor/SKILL.md` — main knowledge base
- `skills/wayland-multimonitor/references/compositor-configs.md` — complete config examples
- `skills/wayland-multimonitor/references/troubleshooting.md` — troubleshooting procedures
