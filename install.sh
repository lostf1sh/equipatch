#!/usr/bin/env bash

set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bin_dir="$HOME/.local/bin"

install_linux() {
    local config_home unit_dir app_dir enabled flavor desktop system_desktop
    config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
    unit_dir="$config_home/systemd/user"
    app_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/applications

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
}

install_macos() {
    local agent_dir log_file enabled flavor app label plist
    agent_dir="$HOME/Library/LaunchAgents"
    log_file="$HOME/Library/Logs/equipatch.log"
    mkdir -p "$agent_dir" "$HOME/Library/Logs"

    enabled=()
    for flavor in discord discordcanary discordptb; do
        case $flavor in
            discord)       app='Discord.app' ;;
            discordcanary) app='Discord Canary.app' ;;
            discordptb)    app='Discord PTB.app' ;;
        esac
        if [[ -d "$HOME/Applications/$app" ]]; then
            app="$HOME/Applications/$app"
        elif [[ -d "/Applications/$app" ]]; then
            app="/Applications/$app"
        else
            continue
        fi

        label="com.equipatch.$flavor"
        plist="$agent_dir/$label.plist"
        sed -e "s|@FLAVOR@|$flavor|g" -e "s|@BIN@|$bin_dir/equipatch|g" \
            -e "s|@APP@|$app|g" -e "s|@LOG@|$log_file|g" \
            "$project_dir/launchd/com.equipatch.plist.in" > "$plist"

        # RunAtLoad applies the patch immediately.
        launchctl bootout "gui/$UID/$label" 2>/dev/null || true
        launchctl bootstrap "gui/$UID" "$plist"
        enabled+=("$flavor")
    done

    if [[ ${#enabled[@]} -eq 0 ]]; then
        printf 'No Discord installation found (/Applications or ~/Applications).\n' >&2
        exit 1
    fi
    printf 'Equicord auto-patch agent installed for: %s (log: %s)\n' "${enabled[*]}" "$log_file"
}

mkdir -p "$bin_dir"
install -m755 "$project_dir/equipatch" "$bin_dir/equipatch"

case $(uname -s) in
    Darwin) install_macos ;;
    *)      install_linux ;;
esac
