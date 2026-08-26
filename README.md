# equipatch

Automatically reapplies the Equicord patch after Discord updates its
`~/.config/<flavor>/app-*` directory on Linux. The patch is identical to what
Equicord's official Equilotl installer writes (an `app.asar` directory with a
two-line loader, original kept as `_app.asar`) and reuses the existing Equicord
file offline, so it also recognises an installation that Equilotl patched.

Supports `discord`, `discordcanary` and `discordptb`. Only bash and coreutils
are required; `notify-send` is optional.

## Installation

```bash
./install.sh     # ./uninstall.sh restores the original app.asar and removes everything
```

For every flavor found under `~/.config`, the installer:

- enables `equipatch@<flavor>.path`, which applies the patch when the active
  `Discord` symlink changes;
- enables `equipatch@<flavor>.timer`, a five-minute fallback for missed events;
- overrides the desktop entry (`~/.local/share/applications/<flavor>.desktop`)
  so that launching Discord runs `equipatch launch` first: the patch is
  guaranteed to be in place before Discord starts.

Discord is never closed. If it is already running when a patch lands, a desktop
notification asks you to restart it.

## Usage

```bash
equipatch status [flavor]     # patched? loader target? running?
equipatch patch [flavor]      # default when no command is given
equipatch unpatch [flavor]    # restore the original app.asar
equipatch launch [flavor] -- [args]
```

Paths can be overridden with `DISCORD_DIR` and `EQUICORD_ASAR`
(defaults: `$XDG_CONFIG_HOME/<flavor>`, `$XDG_CONFIG_HOME/Equicord/equicord.asar`).

```bash
systemctl --user status 'equipatch@*'
journalctl --user -u 'equipatch@*'
```

## License

MIT
