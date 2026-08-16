#!/usr/bin/env bash
set -euo pipefail

launcher=${1:?launcher source path required}
sdk=${2:?SDK source path required}

require_literal() {
    local file=$1 literal=$2
    if ! grep -Fq -- "$literal" "$file"; then
        printf 'Verification failed: %s does not contain %s\n' "$file" "$literal" >&2
        exit 1
    fi
}

require_literal "$launcher/Cargo.toml" 'path = "../anime-launcher-sdk"'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'Prefer NTSYNC'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'system76_scheduler'
require_literal "$launcher/src/ui/about.rs" 'Arch enhancements r11'
require_literal "$launcher/src/ui/preferences/general/components.rs" 'config.game.wine.wined3d'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'InstallGamemode'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'InstallSystem76Scheduler'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'RepairSystem76Scheduler'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'is_system76_scheduler_responsive'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'is_system76_scheduler_pipewire_monitor_enabled'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" 'requires repair, not an installation-failure toast'
require_literal "$launcher/src/ui/preferences/enhancements/mod.rs" '/usr/lib/honkers-railway-launcher/install-optional-dependency'
require_literal "$sdk/src/config/schema_blanks/wine/wine_sync.rs" 'NTSync'
require_literal "$sdk/src/games/star_rail/game.rs" 'Prefer NTSYNC unavailable; Auto will be used'
require_literal "$sdk/src/games/star_rail/game.rs" 'SetForegroundProcess'
require_literal "$sdk/src/games/star_rail/game.rs" 'game launch continues'
require_literal "$sdk/src/games/star_rail/game.rs" '"--timeout=2s"'
require_literal "$sdk/src/games/star_rail/game.rs" 'Graphics backend: WineD3D (experimental)'
require_literal "$sdk/src/games/star_rail/game.rs" 'mangohud --dlsym'

printf 'Source verification passed: synchronization and scheduler guards are present.\n'
