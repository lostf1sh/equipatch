# equipatch

Automatically reapplies the Equicord patch after Discord updates itself, on
Linux (`~/.config/<flavor>/app-*`) and macOS (`/Applications/<Flavor>.app`).
The patch is identical to what Equicord's official Equilotl installer writes
(an `app.asar` directory with a two-line loader, original kept as `_app.asar`)
and reuses the existing Equicord file offline, so it also recognises an
installation that Equilotl patched.

Supports `discord`, `discordcanary` and `discordptb`. Only bash is required
(the stock bash 3.2 on macOS is fine); `notify-send` is optional on Linux.

## One-time setup

1. **Install Equicord once with [Equilotl](https://github.com/Equicord/Equilotl).**
   equipatch never downloads anything; it reuses the `equicord.asar` Equilotl
   leaves behind:
   - Linux: `~/.config/Equicord/equicord.asar`
   - macOS: `~/Library/Application Support/Equicord/equicord.asar`

   Equicord updates itself from inside Discord; equipatch only restores the
   loader that a Discord update removes.

2. **macOS only: allow writes into the Discord bundle.** macOS's *App
   Management* protection blocks changes to apps under `/Applications`
   (`Operation not permitted`). Do one of:
   - System Settings → Privacy & Security → App Management: add your terminal
     app (for `./install.sh` and manual `equipatch patch`) **and** `/bin/bash`
     (the launch agent's interpreter; press ⌘⇧G in the file picker and type
     the path), or
   - move `Discord.app` to `~/Applications`, which is not protected. Discord
     keeps updating itself there.

3. **Install:**

   ```bash
   ./install.sh     # ./uninstall.sh restores the original app.asar and removes everything
   ```

4. **Restart Discord** if it was running. That's it; nothing else to do after
   future Discord updates.

## What the installer sets up

### Linux

For every flavor found under `~/.config`, the installer:

- enables `equipatch@<flavor>.path`, which applies the patch when the active
  `Discord` symlink changes;
- enables `equipatch@<flavor>.timer`, a five-minute fallback for missed events;
- overrides the desktop entry (`~/.local/share/applications/<flavor>.desktop`)
  so that launching Discord runs `equipatch launch` first: the patch is
  guaranteed to be in place before Discord starts.

Discord is never closed. If it is already running when a patch lands, a desktop
notification asks you to restart it.

### macOS

For every flavor found in `/Applications` or `~/Applications`, the installer
writes a launch agent (`~/Library/LaunchAgents/com.equipatch.<flavor>.plist`)
that runs `equipatch patch` on login, whenever the bundle changes (`WatchPaths`;
Discord's updater swaps the whole `.app`) and every five minutes as a fallback.
Output goes to `~/Library/Logs/equipatch.log`.

Patching invalidates the bundle's code signature, exactly as Equilotl does;
Discord still launches and updates normally. There is no Dock-launch hook on
macOS, but `equipatch launch` patches and then `open -a`s the bundle.

## Usage

```bash
equipatch status [flavor]     # patched? loader target? running?
equipatch patch [flavor]      # default when no command is given
equipatch unpatch [flavor]    # restore the original app.asar
equipatch launch [flavor] -- [args]
```

Paths can be overridden with `DISCORD_DIR` and `EQUICORD_ASAR`. Defaults on
Linux: `$XDG_CONFIG_HOME/<flavor>` and `$XDG_CONFIG_HOME/Equicord/equicord.asar`;
on macOS: the `.app` bundle and `~/Library/Application Support/Equicord/equicord.asar`.

```bash
systemctl --user status 'equipatch@*'            # Linux
journalctl --user -u 'equipatch@*'
launchctl print gui/$UID/com.equipatch.discord   # macOS
tail -f ~/Library/Logs/equipatch.log
```

## License

MIT
