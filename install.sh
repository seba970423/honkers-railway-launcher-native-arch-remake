#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if ((EUID == 0)); then
    printf 'Run this installer as your regular user; it requests elevation only when needed.\n' >&2
    exit 1
fi

if command -v sudo >/dev/null; then
    elevate=(sudo)
elif command -v doas >/dev/null; then
    elevate=(doas)
else
    printf 'Neither sudo nor doas is available for required package operations.\n' >&2
    exit 1
fi

if [[ ! -f /etc/arch-release ]] || ! command -v pacman >/dev/null; then
    printf 'This installer supports Arch Linux and Arch-based distributions.\n' >&2
    exit 1
fi

required=(base-devel git rust gtk4 libadwaita gdk-pixbuf2 pango xz bzip2 cairo p7zip wayland libwebp-utils winetricks)
missing=()
for package in "${required[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 || missing+=("$package")
done

if ((${#missing[@]})); then
    printf 'Missing required packages:\n  %s\n' "${missing[*]}"
    read -r -p 'Install missing required dependencies? [Y/n] ' answer
    if [[ ${answer:-y} =~ ^[Yy]$ ]]; then
        "${elevate[@]}" pacman -S --needed -- "${missing[@]}"
    else
        printf 'Installation stopped: required dependencies were declined.\n' >&2
        exit 1
    fi
else
    printf 'All required dependencies are available.\n'
fi

offer_repo_packages() {
    local feature=$1 description=$2
    shift 2
    local packages=("$@") missing_optional=() package

    for package in "${packages[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 || missing_optional+=("$package")
    done

    ((${#missing_optional[@]})) || {
        printf '%s: available\n' "$feature"
        return
    }

    printf '\n%s is optional. %s\n' "$feature" "$description"
    printf 'Missing optional packages: %s\n' "${missing_optional[*]}"
    read -r -p "Install ${feature}? [y/N] " answer
    if [[ ! ${answer:-n} =~ ^[Yy]$ ]]; then
        printf 'Skipping optional feature: %s\n' "$feature"
        return 0
    fi

    for package in "${missing_optional[@]}"; do
        if ! pacman -Si "$package" >/dev/null 2>&1; then
            printf '%s is unavailable from the configured Pacman repositories; skipping %s.\n' \
                "$package" "$feature"
            return 0
        fi
    done

    "${elevate[@]}" pacman -S --needed -- "${missing_optional[@]}"
}

offer_repo_packages gamemode \
    'Temporarily applies gaming-oriented system optimizations.' \
    gamemode lib32-gamemode
offer_repo_packages system76-scheduler \
    'Lets Honkers assign the running game as the foreground process over D-Bus.' \
    system76-scheduler

if pacman -Q system76-scheduler >/dev/null 2>&1; then
    scheduler_config=/etc/system76-scheduler/config.kdl
    [[ -r $scheduler_config ]] || scheduler_config=/usr/share/system76-scheduler/config.kdl
fi

if [[ -n ${scheduler_config:-} ]] \
    && grep -Eq '^[[:space:]]*pipewire[[:space:]]+nice=' "$scheduler_config"; then
    printf '\nSystem76 Scheduler\047s PipeWire monitor is enabled and is known to crash the service on this system.\n'
    read -r -p 'Disable only the scheduler PipeWire monitor and restart System76 Scheduler? [Y/n] ' answer
    if [[ ${answer:-y} =~ ^[Yy]$ ]]; then
        "${elevate[@]}" /usr/bin/bash "$PWD/install-optional-dependency" \
            system76-scheduler-repair
        printf 'System76 Scheduler PipeWire monitor disabled; execsnoop and foreground D-Bus assignment remain enabled.\n'
    else
        printf 'Leaving System76 Scheduler unchanged. Its D-Bus service may continue crashing while the monitor remains enabled.\n'
    fi
fi

makepkg -Csi

printf '\nHonkers Railway Launcher + Arch enhancements installed successfully.\n'
