# Honkers Railway Launcher — native Arch enhancements

Native Arch package for upstream Honkers Railway Launcher `1.15.2`, using a separately pinned and patched Anime Launcher SDK `1.35.12`.

## Status

- Package revision: `1.15.2 + Arch enhancements r11`
- Tested on Arch-compatible CachyOS with KDE Plasma and Wayland
- DXVK remains the recommended graphics backend
- WineD3D support is experimental
- Existing launcher configuration, Wine prefixes, components, and game files remain compatible

## Capabilities

| Feature | Default behavior | Missing or unavailable behavior |
| --- | --- | --- |
| NTSYNC | `Auto` uses it when Wine and the kernel support it | Falls back safely without blocking launch |
| GameMode | Optional and disabled by default | Enabling the toggle offers Pacman installation |
| System76 Scheduler | Optional foreground assignment over D-Bus | Enabling the toggle offers installation and any required repair |
| WineD3D | Experimental and disabled by default | DXVK remains installed and configured |
| MangoHud | Optional | Uses OpenGL `--dlsym` injection with WineD3D |

## Enhancements

- Synchronization selector: `Auto / Prefer NTSYNC / FSYNC / ESYNC / Wine default`.
- `Prefer NTSYNC` validates Wine 11+ and a usable `/dev/ntsync`, then falls back to `Auto` without refusing to launch the game.
- System76 Scheduler integration calls `com.system76.Scheduler.SetForegroundProcess` directly on the system bus.
- GameMode and System76 Scheduler remain optional and are offered separately during installation.
- Missing optional integrations remain visible in the UI. Enabling one offers installation and activates it only after capability re-detection succeeds.
- Deferred System76 Scheduler installation treats its expected repair as a separate stage instead of reporting a false installation failure.
- GameMode installation includes both `gamemode` and `lib32-gamemode`.
- The WineD3D toggle is located under `General → Components → Wine options` and uses per-launch builtin DLL overrides without removing DXVK.
- MangoHud automatically selects its OpenGL injection path when WineD3D is enabled.
- Strict `--fuzz=0` patch application and structural source verification stop incompatible upstream updates.

## Privilege boundary

The launcher itself is never elevated. UI installation and scheduler repair use a narrowly scoped polkit helper that accepts only predefined operations and validates them before invoking Pacman or changing the scheduler configuration.

Runtime foreground assignment uses System76 Scheduler's existing D-Bus interface and does not elevate the game or launcher.

## Install

Run from the extracted project directory:

```bash
./install.sh
```

The installer checks mandatory dependencies and asks before Pacman installs anything missing. GameMode and System76 Scheduler use separate opt-in `[y/N]` prompts. Declining either does not prevent launcher installation.

Optional packages are installed only from configured Pacman repositories. Neither the installer nor the launcher invokes AUR helpers automatically.

### System76 Scheduler compatibility repair

On the tested system, System76 Scheduler repeatedly crashes inside its PipeWire process-monitoring thread. Systemd may restart it briefly, making D-Bus appear healthy between crashes.

When this incompatibility is detected, both `install.sh` and the later UI-toggle flow ask before applying a targeted repair. The helper:

1. Creates a one-time backup of the effective scheduler configuration.
2. Comments only the scheduler's `pipewire nice=...` process-assignment profile.
3. Preserves system audio, `execsnoop`, and foreground assignment over D-Bus.
4. Restarts only `com.system76.Scheduler.service`.
5. Verifies the resulting configuration and service state.

Refusing the repair leaves the scheduler configuration unchanged.

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes only the native Arch package and dependencies that Pacman considers unused. It preserves:

- GameMode and System76 Scheduler packages
- Launcher configuration and user data
- Wine prefixes and downloaded components
- Game installations

If Honkers previously backed up the scheduler configuration, uninstallation offers to restore that exact backup. Restoration is optional because the original PipeWire monitor may make the scheduler crash again. Declining preserves both the working configuration and its backup.

The installer and uninstaller use the matching helper bundled beside their scripts, so repair and restoration remain compatible while replacing an older package revision.

## Troubleshooting

Run the launcher with verbose logging:

```bash
honkers-railway-launcher --debug
```

Check System76 Scheduler's current state:

```bash
systemctl status com.system76.Scheduler.service --no-pager
```

Check whether its PipeWire monitoring profile is enabled or commented out:

```bash
sudo grep -nE '^[[:space:]]*(//[[:space:]]*)?pipewire[[:space:]]' \
  /etc/system76-scheduler/config.kdl
```

An uncommented `pipewire nice=...` line means the monitor is enabled. A `// pipewire nice=...` line means the compatibility repair disabled it.

Inspect recent scheduler activity without deleting journal history:

```bash
sudo journalctl -u com.system76.Scheduler.service \
  --since "5 minutes ago" --no-pager
```

A successful game launch with the integration enabled includes a line similar to:

```text
System76 Scheduler: foreground PID 12345 assigned
```

## Known limitations

- Star Rail may display a brief white frame before its animated splash when WineD3D is enabled. Multiple working Wine runners reproduce it; DXVK does not.
- WineD3D is provided as an experimental alternative and may behave differently from DXVK depending on the runner, driver, and game update.
- Background-video GStreamer warnings and telemetry lookup warnings originate upstream and do not prevent game launch.

## Non-goals

This package does not bundle or compile custom Wine runners, automatically install packages from the AUR, modify the game's anti-cheat, or attempt to repair unrelated upstream warnings.

## Update policy

Change pinned upstream versions and hashes deliberately. If either patch stops applying exactly, inspect upstream changes and regenerate the patch. Do not enable fuzzy patch application.
