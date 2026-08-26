#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
bin_dir="$HOME/.local/bin"
unit_dir="$config_home/systemd/user"
app_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/applications

install -Dm755 "$project_dir/equipatch" "$bin_dir/equipatch"
for unit in service path timer; do
    install -Dm644 "$project_dir/systemd/equipatch@.$unit" "$unit_dir/equipatch@.$unit"
done

# Clean up the old non-template units.
systemctl --user disable --now equipatch.path equipatch.timer 2>/dev/null || true
rm -f "$unit_dir"/equipatch.{service,path,timer}

systemctl --user daemon-reload

enabled=()
for flavor in discord discordcanary discordptb; do
    [[ -d "$config_home/$flavor" ]] || continue
    systemctl --user enable --now "equipatch@$flavor.path" "equipatch@$flavor.timer"
    systemctl --user start "equipatch@$flavor.service" || true
    enabled+=("$flavor")

    # Override the desktop entry to launch through equipatch so the patch is
    # guaranteed to be in place right before Discord starts.
    case $flavor in
        discord)       desktop=discord.desktop ;;
        discordcanary) desktop=discord-canary.desktop ;;
        discordptb)    desktop=discord-ptb.desktop ;;
    esac
    system_desktop=$(find /usr/share/applications /usr/local/share/applications -maxdepth 1 -name "$desktop" 2>/dev/null | head -n 1 || true)
    [[ -n "$system_desktop" ]] || continue
    mkdir -p "$app_dir"
    sed -E "s|^Exec=[^ ]+|Exec=$bin_dir/equipatch launch $flavor --|" "$system_desktop" > "$app_dir/$desktop"
done

if [[ ${#enabled[@]} -eq 0 ]]; then
    printf 'No Discord installation found (%s/discord*).\n' "$config_home" >&2
    exit 1
fi

printf 'Equicord auto-patch service installed for: %s\n' "${enabled[*]}"
