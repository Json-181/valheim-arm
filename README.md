## Base information
The goal of this build is to enable running Valheim with mods, on both arm64 and amd64 platforms.

In the logs folder, you can find startup logs of Valheim on the arm64 platform (Ampere Altra CPU).
The docker-compose-example folder contains a quickstart setup to launch.

Important note! ntsync support is available only in the latest Ubuntu version — 25.04, and even then it must be manually enabled on the host, with the `ntsync` kernel module loaded (`lsmod | grep ntsync`).
The build works perfectly fine without ntsync — the example docker-compose files ship with the device mapping commented out by default. If your host supports it, uncomment these two lines to pass `/dev/ntsync` through to the container:
```yaml
    devices:
      - /dev/ntsync:/dev/ntsync
```
This needs a full `docker compose down` + `up` to take effect, not just a restart — device passthrough is set at container creation time, not something a running container can pick up. The entrypoint script confirms whether ntsync is *actually* being used (not just available) right after the server process launches each time — look for `NTSYNC module is present in kernel, and the server is using it.` in the logs.

Autosave works correctly when using docker stop.

### Which build should I use?

Two builds exist, both sharing the same `entrypoint.sh` scheduling/plugin logic:

- **`Docker/`** (recommended) — runs the Windows Valheim build through Wine, translated to arm64 via box64. This is the actively tested path — everything else in this README (Cron Job scheduling, DiscordConnector, NTSYNC, etc.) has been confirmed working here.
- **`Docker-fex/`** — runs the native Linux Valheim build directly through FEX-emu, skipping Wine/Windows API emulation entirely. A simpler translation stack, plausibly more stable, but currently missing most of the bundled plugins (`Docker-fex/server/BepInEx/plugins/` only has Server Devcommands and Display BepInEx Info — no Cron Job, DiscordConnector, YamlDotNet, Riverheim, Seasons, Serverside Simulations, or ConditionalConfigSync), and it hasn't been tested end-to-end. Riverheim in particular generated existing worlds' terrain, so switching without it risks world-generation compatibility issues.

Stick with `Docker/` unless you're deliberately experimenting with `Docker-fex/` as a separate effort.

## Configuration

### Environment Variables

- `ENABLE_PLUGINS` - enables or disables plugin support(Default: false)
- `ENABLE_CROSSPLAY` - enables or disables crossplay(Default: false)
- `SERVER_NAME` - The name of the server as it should appear in the server browser (Default: "Valheim_Server")
- `SERVER_WORLD` - The name of the `.fwl` and `.db` files used to store the world (Default: "tsx_world")
- `SERVER_PASSWORD` - The password to enter the server. Must be 5 characters or longer
- `SERVER_VISIBILITY` - Whether or not to show the server in the server browser (Default: 1)
  - `1` - Visible in browser
  - `0` - Invisible, only joinable by "Join IP"
- `SERVER_SAVE_INTERVAL` - How often the world will save in seconds (Default: 1800)
- `SERVER_BACKUPS` - How many automatic backups will be kept (Default: 4)
- `SERVER_BACKUP_SHORT` - The interval between the first automatic backups (Default: 7200)
- `SERVER_BACKUP_LONG` - The interval between the subsequent automatic backups (Default: 43200)

### Update & restart scheduling

Modeled after [mbround18/valheim-docker](https://github.com/mbround18/valheim-docker#scheduled-restarts)'s scheduler, reimplemented in bash so it keeps using this project's wine/box64 and FEX-based arm64 server launch instead of a separate supervisor binary. Scheduled updates/restarts never exit the container — the entrypoint script gracefully stops the running server process and relaunches it in place, so `restart: unless-stopped` isn't what's doing the work here.

- `UPDATE_ON_STARTUP` - Run a Steam update check when the container starts (Default: 1). Only applies once the server is already installed — on a fresh/empty volume the first install always happens regardless of this setting, since there'd otherwise be nothing to launch.
- `AUTO_UPDATE` - Periodically re-check for updates while the server is running (Default: 0)
- `AUTO_UPDATE_SCHEDULE` - Cron expression for the periodic check (Default: "0 1 * * *")
- `AUTO_UPDATE_PAUSE_WITH_PLAYERS` - Skip a scheduled update if players are currently connected (Default: 0)
- `VALIDATE_ON_INSTALL` - Pass `validate` to SteamCMD's `app_update` (Default: 1)
- `USE_PUBLIC_BETA` - If `1`, lock installs to `BETA_BRANCH` via SteamCMD's `+set_beta`; if `0`, install whatever `app_update` serves by default (Default: 0)
- `BETA_BRANCH` - Steam beta branch to lock to when `USE_PUBLIC_BETA=1` (Default: "public"). `public` is treated as "no branch lock" and never gets passed to `+set_beta` — it's not an actual Steam branch name, just this project's way of saying "use the live/default branch." Use one of the other names below (or a raw Steam branch name) to actually lock a version.
- `SCHEDULED_RESTART` - Periodically restart the server process on a schedule (Default: 0)
- `SCHEDULED_RESTART_SCHEDULE` - Cron expression for the restart (Default: "0 2 * * *")
- `DISCORD_WEBHOOK_URL` - If set, posts server start/stop and cron job (restart warnings, greeting, etc.) events to this Discord webhook via the bundled [DiscordConnector](https://discord-connector.valheim.games.nwest.one/) mod. Left unset by default — **never commit a real webhook URL to this repo**, set it as an environment variable on your host/compose file instead. A `serverStart` message after a `serverStop` message is the signal that a scheduled restart actually succeeded.

Cron expressions are 5-field (`minute hour day-of-month month day-of-week`) and support `*`, `*/n`, ranges (`a-b`), and comma lists — numeric fields only, no month/weekday names and no `@daily`-style macros.

### Beta branch flags

`BETA_BRANCH` accepts a raw Steam branch name, or one of the names predefined in `beta_branches.conf`:

| Branch | About |
| :--- | :--- |
| public | Latest public version (Feb 19, 2026) |
| default_old | Previous stable (Feb 2, 2026) |
| default_preal | Before Ashlands (Oct 3, 2025) |
| default_prebw | Before Bog Witch (Oct 3, 2025) |
| default_precta | Before Call to Arms (Oct 3, 2025) |

### Ports

If ports 2456-2458/UDP are in use on your server, you can use a different port range by changing the left side of the port assignment like so:

### ARM
You can set your custom Box64 or Fex-emu configuration in  
`./valheim/persistentdata/settings/emulators.rc`  
This lets you fine-tune the emulator for your specific device or OS.

A list of available environment variables can be found here:  
https://github.com/ptitSeb/box64/blob/main/docs/USAGE.md  
and here (for arm64-fex tag):  
https://github.com/FEX-Emu/FEX/blob/main/FEXCore/Source/Interface/Config/Config.json.in

### Volumes

| Volume             | Container path              | Description                             |
| -------------------- | ----------------------------- | ----------------------------------------- |
| steam install path | /root/valheim-server         | path to hold the dedicated server files |
| world              | /root/.config/unity3d/IronGate/Valheim | path that holds the persistent world files         |
Place your plugins in the ./valheim/server/BepInEx/plugins folder.

### Bundled plugins

A few BepInEx mods ship in the image by default and drive the scheduling/notification features above. Once the server has booted once, their configs live under `./valheim/server/BepInEx/config/` on the host — the entrypoint script only copies defaults in on the very first boot against an empty volume, it won't overwrite your edits after that.

| Plugin | Config file | What it does |
| :--- | :--- | :--- |
| [Cron Job](https://github.com/JereKuusela/valheim-cron_job) | `BepInEx/config/cron.yaml` | Runs scheduled/join-triggered server commands. Powers the join greeting, the hand-written reboot warnings, and the `SCHEDULED_RESTART` warning block `entrypoint.sh` auto-generates and appends here. |
| [Server Devcommands](https://github.com/JereKuusela/valheim-dev) | `BepInEx/config/server_devcommands.cfg` | Adds server console commands, including `broadcast`/`say` which Cron Job uses to actually message players. **Requires `Server chat = true` under `[1. General]`** (default `false`) — without it, commands execute with no error logged anywhere, but nothing ever reaches players. Already set to `true` in this repo's default config. |
| [DiscordConnector](https://discord-connector.valheim.games.nwest.one/) | `BepInEx/config/games.nwest.valheim.discordconnector/discordconnector.cfg` | Posts server lifecycle (`serverStart`/`serverStop`/...) and Cron Job (`cronjob`) events to a Discord webhook. Set via `DISCORD_WEBHOOK_URL` above rather than editing this file directly, so the secret never lands in git. |
| [YamlDotNet](https://github.com/aaubry/YamlDotNet) | — | Library dependency Cron Job needs to parse `cron.yaml`. No config of its own. |

Several other gameplay/world-generation mods (Riverheim, Seasons, Serverside Simulations, and others) are also bundled — see `Docker/server/BepInEx/plugins/` for the full list.

## docker-compose.yml

```yaml
services:
  valheim_server:
    image: tsxcloud/valheim-arm:latest
    restart: unless-stopped
    stop_grace_period: 40s
    ports:
      - "2456:2456/udp"
      - "2457:2457/udp"
      - "2458:2458/udp"
    environment:
      - SERVER_NAME=Valheim_Server
      - SERVER_WORLD=tsx_world
      - SERVER_PASSWORD=123456780
      - ENABLE_PLUGINS=false
      - ENABLE_CROSSPLAY=false
      # Optional update/restart scheduling, see README for details:
      # - UPDATE_ON_STARTUP=1
      # - USE_PUBLIC_BETA=1
      # - BETA_BRANCH=public
      # - AUTO_UPDATE=0
      # - AUTO_UPDATE_SCHEDULE=0 1 * * *
      # - AUTO_UPDATE_PAUSE_WITH_PLAYERS=0
      # - VALIDATE_ON_INSTALL=1
      # - SCHEDULED_RESTART=0
      # - SCHEDULED_RESTART_SCHEDULE=0 2 * * *
      # Optional Discord notifications, see README - never commit a real webhook URL:
      # - DISCORD_WEBHOOK_URL=
    volumes:
      # Bind mount, to access the files directly on the host
      - ./valheim/server/:/root/valheim-server
      - ./valheim/persistentdata/:/root/.config/unity3d/IronGate/Valheim
    #This is required for ntsync to work inside Docker.
    #If ntsync support is not enabled in your Linux kernel, comment out this section, otherwise Docker Compose won't start.
#    devices:
#      - /dev/ntsync:/dev/ntsync
```

## Links
You can find the Docker builds here:
https://hub.docker.com/r/tsxcloud/valheim-arm  
You can leave comments here:  
https://www.reddit.com/r/valheim/comments/1m3d6my/valheim_server_mods_on_arm64_yes_its_possible  

## Acknowledgments
https://github.com/husjon/valheim_server_oci_setup  
https://gitlab.com/tedtramonte/valheim-server  
https://github.com/Kron4ek/Wine-Builds  
https://github.com/mbround18/valheim-docker (scheduled update/restart design)  
https://github.com/JereKuusela (Cron Job, Server Devcommands)  
https://github.com/nwesterhausen/valheim-discordconnector

## 
Enjoying the project? A ⭐ goes a long way!
