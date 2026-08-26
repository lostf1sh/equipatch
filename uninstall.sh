#!/usr/bin/env bash

set -euo pipefail

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
bin_dir="$HOME/.local/bin"
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
rm -f "$bin_dir/equipatch"
systemctl --user daemon-reload

printf 'equipatch removed; Discord restored to its original state.\n'
