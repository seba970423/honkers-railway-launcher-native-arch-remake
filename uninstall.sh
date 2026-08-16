#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

readonly package='honkers-railway-launcher-native-arch'

if ((EUID == 0)); then
    printf 'Run this uninstaller as your regular user; it requests elevation only for Pacman.\n' >&2
    exit 1
fi

if [[ ! -f /etc/arch-release ]] || ! command -v pacman >/dev/null; then
    printf 'This uninstaller supports Arch Linux and Arch-based distributions.\n' >&2
    exit 1
fi

if ! pacman -Q "$package" >/dev/null 2>&1; then
    printf '%s is not installed; nothing was changed.\n' "$package"
    exit 0
fi

if command -v sudo >/dev/null; then
    elevate=(sudo)
elif command -v doas >/dev/null; then
    elevate=(doas)
else
    printf 'Neither sudo nor doas is available for the package removal.\n' >&2
    exit 1
fi

printf 'This removes only %s and its now-unused package dependencies.\n' "$package"
printf 'GameMode, System76 Scheduler, launcher data, Wine prefixes, components, and game files are preserved.\n'
read -r -p 'Continue with package removal? [Y/n] ' answer

if [[ ! ${answer:-y} =~ ^[Yy]$ ]]; then
    printf 'Uninstallation cancelled; nothing was changed.\n'
    exit 0
fi

scheduler_config=/etc/system76-scheduler/config.kdl
scheduler_backup=${scheduler_config}.honkers-backup
if [[ -f $scheduler_backup && ! -L $scheduler_backup ]]; then
    printf '\nHonkers previously disabled System76 Scheduler\047s crashing PipeWire monitor.\n'
    printf 'Restoring the exact original configuration may make its D-Bus service unresponsive again.\n'
    read -r -p 'Restore the original System76 Scheduler configuration? [y/N] ' restore_answer

    if [[ ${restore_answer:-n} =~ ^[Yy]$ ]]; then
        if "${elevate[@]}" /usr/bin/bash "$PWD/install-optional-dependency" \
            system76-scheduler-restore; then
            printf 'Original System76 Scheduler configuration restored.\n'
        else
            printf 'The scheduler backup could not be restored; it has been preserved.\n' >&2
            read -r -p 'Continue removing the launcher anyway? [y/N] ' continue_answer
            if [[ ! ${continue_answer:-n} =~ ^[Yy]$ ]]; then
                printf 'Uninstallation stopped; the launcher and scheduler backup were preserved.\n'
                exit 1
            fi
        fi
    else
        printf 'Keeping the working scheduler configuration and its Honkers backup.\n'
    fi
fi

"${elevate[@]}" pacman -Rns -- "$package"

printf '\n%s was removed. User data and optional integrations were preserved.\n' "$package"
