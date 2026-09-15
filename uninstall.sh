#!/usr/bin/env bash

set -euo pipefail

bin_dir="$HOME/.local/bin"

uninstall_linux() {
    local config_home unit_dir app_dir flavor desktop
    config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
    unit_dir="$config_home/systemd/user"
    app_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/applications

    for flavor in discord discordcanary discordptb; do
        systemctl --user disable --now "equipatch@$flavor.path" "equipatch@$flavor.timer" 2>/dev/null || true
        [[ -x "$bin_dir/equipatch" && -d "$config_home/$flavor" ]] && "$bin_dir/equipatch" unpatch "$flavor" || true
    done
    systemctl --user disable --now equipatch.path equipatch.timer 2>/dev/null || true

    rm -f "$unit_dir"/equipatch@.{service,path,timer} "$unit_dir"/equipatch.{service,path,timer}
    for desktop in "$app_dir"/discord.desktop "$app_dir"/discord-canary.desktop "$app_dir"/discord-ptb.desktop; do
        [[ -f "$desktop" ]] && grep -q "equipatch launch" "$desktop" && rm -f "$desktop"
    done
    systemctl --user daemon-reload
}

uninstall_macos() {
    local flavor label plist
    for flavor in discord discordcanary discordptb; do
        label="com.equipatch.$flavor"
        plist="$HOME/Library/LaunchAgents/$label.plist"
        [[ -f "$plist" ]] || continue
        launchctl bootout "gui/$UID/$label" 2>/dev/null || true
        [[ -x "$bin_dir/equipatch" ]] && "$bin_dir/equipatch" unpatch "$flavor" || true
        rm -f "$plist"
    done
}

case $(uname -s) in
    Darwin) uninstall_macos ;;
    *)      uninstall_linux ;;
esac
rm -f "$bin_dir/equipatch"

printf 'equipatch removed; Discord restored to its original state.\n'
