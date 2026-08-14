#!/bin/bash

SERVER=/root/valheim-server
PERSISTENT="/root/.config/unity3d/IronGate/Valheim"
SETTINGS="${PERSISTENT}/settings"

source /beta_branches.conf

# Odin-style (mbround18/valheim-docker) update & restart scheduling, reimplemented in bash
UPDATE_ON_STARTUP="${UPDATE_ON_STARTUP:-1}"
AUTO_UPDATE="${AUTO_UPDATE:-0}"
AUTO_UPDATE_SCHEDULE="${AUTO_UPDATE_SCHEDULE:-0 1 * * *}"
AUTO_UPDATE_PAUSE_WITH_PLAYERS="${AUTO_UPDATE_PAUSE_WITH_PLAYERS:-0}"
VALIDATE_ON_INSTALL="${VALIDATE_ON_INSTALL:-1}"
USE_PUBLIC_BETA="${USE_PUBLIC_BETA:-0}"
BETA_BRANCH="${BETA_BRANCH:-$BETA_DEFAULT}"
SCHEDULED_RESTART="${SCHEDULED_RESTART:-0}"
SCHEDULED_RESTART_SCHEDULE="${SCHEDULED_RESTART_SCHEDULE:-0 2 * * *}"
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Matches one cron field ("*", "*/n", "a-b", or a comma list of those) against a numeric value
cron_field_match () {
    local field="$1" value="$2" part start end step
    [ "$field" = "*" ] && return 0
    IFS=',' read -ra parts <<< "$field"
    for part in "${parts[@]}"; do
        if [[ "$part" == \*/* ]]; then
            step="${part#*/}"
            (( step > 0 && value % step == 0 )) && return 0
        elif [[ "$part" == *-* ]]; then
            start="${part%-*}"
            end="${part#*-}"
            (( value >= start && value <= end )) && return 0
        elif (( value == part )); then
            return 0
        fi
    done
    return 1
}

# Checks the current time against a 5-field "min hour dom month dow" cron expression.
# Numeric fields only (no month/weekday names, no @daily-style macros).
cron_match () {
    local min hour dom month dow
    read -r min hour dom month dow <<< "$1"
    cron_field_match "$min" "$(date +%-M)" || return 1
    cron_field_match "$hour" "$(date +%-H)" || return 1
    cron_field_match "$dom" "$(date +%-d)" || return 1
    cron_field_match "$month" "$(date +%-m)" || return 1
    cron_field_match "$dow" "$(date +%w)" || return 1
}

update_server () {
    echo "$(timestamp) INFO: Checking for update"
    echo "$(timestamp) INFO: USE_PUBLIC_BETA=${USE_PUBLIC_BETA} BETA_BRANCH=${BETA_BRANCH:-<empty>} VALIDATE_ON_INSTALL=${VALIDATE_ON_INSTALL}"
    export SteamAppId=892970
    local -a beta_args=() validate_args=()
    # "public" isn't a real steamcmd branch name (it's just the live/default branch,
    # which needs no -beta flag at all) — only pass +set_beta for an actual named branch.
    if [ "$USE_PUBLIC_BETA" = "1" ] && [ -n "$BETA_BRANCH" ] && [ "$BETA_BRANCH" != "public" ]; then
        beta_args=(+set_beta "$BETA_BRANCH")
    fi
    [ "$VALIDATE_ON_INSTALL" = "1" ] && validate_args=(validate)
    steamcmd.sh +@sSteamCmdForcePlatformType windows \
                +force_install_dir "${SERVER}" \
                +login anonymous \
                "${beta_args[@]}" \
                +app_update 896660 "${validate_args[@]}" +quit
}

# Best-effort heuristic: compares connect/disconnect log line counts to guess if
# anyone is currently online. Only used when AUTO_UPDATE_PAUSE_WITH_PLAYERS=1.
players_online () {
    local log_file="${PERSISTENT}/logs/valheim_$(date '+%d-%m-%Y').log"
    [ -f "$log_file" ] || return 1
    local connects disconnects
    connects=$(grep -c "Got connection SteamID" "$log_file")
    disconnects=$(grep -c "Closing socket" "$log_file")
    (( connects > disconnects ))
}

# Rewrites an auto-generated block in the valheim-cron plugin's cron.txt with
# in-game "restart in N minutes" broadcasts, timed off SCHEDULED_RESTART_SCHEDULE.
# entrypoint.sh has no channel into the running server itself (no RCON/stdin
# commands) — this only works because valheim-cron reads cron.txt on its own
# in-game schedule, so the warning has to be expressed as its own cron entry
# a few minutes earlier, not triggered live at restart time.
sync_restart_warnings () {
    local cron_file="${SERVER}/BepInEx/config/cron.yaml"
    [ -f "$cron_file" ] || return 0

    local begin_marker="# --- BEGIN AUTO-GENERATED SCHEDULED_RESTART WARNINGS ---"
    local end_marker="# --- END AUTO-GENERATED SCHEDULED_RESTART WARNINGS ---"

    if grep -qF "$begin_marker" "$cron_file"; then
        # Substring match (not $0==b): a prior run may have appended the marker
        # directly onto a file that didn't end in a newline, merging it onto
        # the previous line, so an exact-equality match could miss it.
        awk -v b="$begin_marker" -v e="$end_marker" '
            index($0, b) {skip=1; next}
            index($0, e) {skip=0; next}
            skip!=1 {print}
        ' "$cron_file" > "${cron_file}.tmp" && mv "${cron_file}.tmp" "$cron_file"
    fi

    [ "$SCHEDULED_RESTART" = "1" ] || return 0

    local min hour dom month dow
    read -r min hour dom month dow <<< "$SCHEDULED_RESTART_SCHEDULE"

    if ! [[ "$min" =~ ^[0-9]+$ ]] || ! [[ "$hour" =~ ^[0-9]+$ ]]; then
        echo "$(timestamp) INFO: SCHEDULED_RESTART_SCHEDULE isn't a single specific time (uses *, a range, or a list) - skipping the in-game restart warning"
        return 0
    fi

    # Note: crossing midnight does not adjust dom/month/dow, so avoid scheduling
    # restarts in the first hour of a day if dow/dom matter.
    # Make sure we're not gluing onto an unterminated last line before appending.
    [ -s "$cron_file" ] && [ -n "$(tail -c1 "$cron_file")" ] && echo >> "$cron_file"
    {
        echo "$begin_marker"
        local offset total_min warn_min warn_hour label
        for offset in 60 30 15 5 1; do
            total_min=$(( hour * 60 + min - offset ))
            total_min=$(( ((total_min % 1440) + 1440) % 1440 ))
            warn_hour=$(( total_min / 60 ))
            warn_min=$(( total_min % 60 ))

            case "$offset" in
                60) label="1 HOUR" ;;
                1) label="1 MINUTE" ;;
                *) label="${offset} MINUTES" ;;
            esac

            if [ "$offset" = "1" ]; then
                printf '  - commands:\n    - broadcast center <color=orange>WARNING - SERVER RESTART IN %s</color>\n    - save\n    schedule: "%d %d %s %s %s"\n' \
                    "$label" "$warn_min" "$warn_hour" "$dom" "$month" "$dow"
            else
                printf '  - command: broadcast center <color=orange>WARNING - SERVER RESTART IN %s</color>\n    schedule: "%d %d %s %s %s"\n' \
                    "$label" "$warn_min" "$warn_hour" "$dom" "$month" "$dow"
            fi
        done
        echo "$end_marker"
    } >> "$cron_file"

    echo "$(timestamp) INFO: Updated in-game restart warning schedule in cron.yaml"
}

# Writes DISCORD_WEBHOOK_URL into DiscordConnector's config so it stays out of the repo/image.
# Event routing (serverLifecycle;cronjob) is set in the committed default config, not here.
sync_discord_webhook () {
    [ -n "$DISCORD_WEBHOOK_URL" ] || return 0
    local cfg_file="${SERVER}/BepInEx/config/games.nwest.valheim.discordconnector/discordconnector.cfg"
    [ -f "$cfg_file" ] || return 0
    sed -i "s#^Webhook URL[[:space:]]*=.*#Webhook URL = ${DISCORD_WEBHOOK_URL}#" "$cfg_file"
}

shutdown_requested=0
valheim_pid=""

shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    shutdown_requested=1
    [ -n "$valheim_pid" ] && kill -2 "$valheim_pid"
}
trap 'shutdown' TERM

# Fired by the scheduler background job (via SIGUSR1), so the actual kill happens
# in this process, where $valheim_pid is kept up to date across restarts.
scheduled_action () {
    [ -n "$valheim_pid" ] && kill -2 "$valheim_pid"
}
trap 'scheduled_action' USR1

scheduler () {
    local last_check=""
    while true; do
        sleep 15
        local now
        now="$(date +%Y%m%d%H%M)"
        [ "$now" = "$last_check" ] && continue
        last_check="$now"

        if [ "$AUTO_UPDATE" = "1" ] && cron_match "$AUTO_UPDATE_SCHEDULE"; then
            if [ "$AUTO_UPDATE_PAUSE_WITH_PLAYERS" = "1" ] && players_online; then
                echo "$(timestamp) INFO: Scheduled update skipped, players online"
            else
                echo "$(timestamp) INFO: Scheduled update triggered"
                touch /tmp/.pending_update
                kill -USR1 $$
            fi
        fi

        if [ "$SCHEDULED_RESTART" = "1" ] && cron_match "$SCHEDULED_RESTART_SCHEDULE"; then
            echo "$(timestamp) INFO: Scheduled restart triggered"
            kill -USR1 $$
        fi
    done
}

echo "Load extra Box64 and Fex-emu settings from emulators.rc"
source /load_emulators_env.sh
echo " "

/print_app_versions.sh

echo " "
echo "Checking NTSYNC"
echo "The NTSYNC module has been present in the Linux kernel since version 6.14 and is usually included only in the generic kernel versions."
echo "Kernel version on this machine is -- $(uname -r)"
echo " "
/usr/bin/lsof /dev/ntsync
echo " "
if /sbin/lsmod | grep -q ntsync; then
  if /usr/bin/lsof /dev/ntsync > /dev/null 2>&1; then
    echo "NTSYNC Module is present in kernel, ntsync is running."
  else
    echo "NTSYNC Module is present in kernel, but ntsync is NOT running. No problem — ntsync is not nessesary."
  fi
else
  echo "NTSYNC Module is NOT present in kernel. No problem — ntsync is not nessesary."
fi
echo " "

echo "Wine configuration"
winetricks sound=disabled

echo "Trying to remove /tmp/.X0-lock"
rm -f /tmp/.X0-lock
echo " "

echo "Starting Xvfb"
Xvfb :0 -screen 0 1024x768x16 &
sleep 5

rm -f /tmp/.pending_update
scheduler &
scheduler_pid=$!

first_iteration=1

while true; do
    if [ "$first_iteration" = "1" ]; then
        [ "$UPDATE_ON_STARTUP" = "1" ] && update_server
        first_iteration=0
    elif [ -f /tmp/.pending_update ]; then
        rm -f /tmp/.pending_update
        update_server
    fi

    echo "Checking if BepInEx files need to be copied"
    mkdir -p "${SERVER}"
    if [ ! -d "${SERVER}/BepInEx" ]; then
        echo "Copy BepInEx files"
        cp -r defaults/server/. "${SERVER}/"
    else
        echo "The folder ${SERVER}/BepInEx already exists, copying is not needed."
    fi
    echo " "

    sync_restart_warnings
    sync_discord_webhook

    echo "Starting server PRESS CTRL-C to exit"
    echo " "
    cd "${SERVER}"

    if [[ ! -f ${SERVER}/linux64/libpulse-mainloop-glib.so.0 ]]; then
        echo "Installing libpulse-mainloop-glib.so.0:x86_64"
        mkdir -p "${SERVER}/linux64/"
        pushd "$(mktemp -d)"
        wget http://mirrors.edge.kernel.org/ubuntu/pool/main/p/pulseaudio/libpulse-mainloop-glib0_17.0%2Bdfsg1-2ubuntu3_amd64.deb
        dpkg -x libpulse-mainloop-glib0_17.0+dfsg1-2ubuntu3_amd64.deb ./
        cp usr/lib/x86_64-linux-gnu/libpulse-mainloop-glib.so.0 "${SERVER}/linux64/"
        echo "Installing libpulse-mainloop-glib.so.0:x86_64 - Done"
        popd
    fi

    sed -i "s/^enabled *=.*/enabled = ${ENABLE_PLUGINS}/" "${SERVER}/doorstop_config.ini"
    if [ "$ENABLE_PLUGINS" = "true" ]; then
        echo "Plugins support is ENABLED"
        export WINEDLLOVERRIDES="winhttp=n,b"
    else
        echo "Plugins support is DISABLED"
    fi

    if [ "$ENABLE_CROSSPLAY" = "true" ]; then
        echo "Crossplay is ENABLED"
        CROSSPLAY_FLAG="-crossplay"
    else
        echo "Crossplay is DISABLED"
        CROSSPLAY_FLAG=""
    fi

    mkdir -p "${PERSISTENT}/logs"
    LOG_FILE="${PERSISTENT}/logs/valheim_$(date '+%d-%m-%Y').log"

    wine valheim_server.exe \
        -name "$SERVER_NAME" \
        -port 2456 \
        -world "$SERVER_WORLD" \
        -password "$SERVER_PASSWORD" \
        -public $SERVER_VISIBILITY \
        -saveinterval $SERVER_SAVE_INTERVAL \
        -backups $SERVER_BACKUPS \
        -backupshort $SERVER_BACKUP_SHORT \
        -backuplong $SERVER_BACKUP_LONG \
        -savedir ${PERSISTENT} \
        ${CROSSPLAY_FLAG:+"$CROSSPLAY_FLAG"} \
        -nographics \
        -batchmode \
        2>&1 | tee -a ${LOG_FILE} &

    # Find pid for valheim_server
    valheim_pid=""
    timeout=0
    while [ $timeout -lt 11 ]; do
        if ps -e | grep "valheim_server"; then
            valheim_pid=$(ps -e | grep "valheim_server" | awk '{print $1}')
            break
        elif [ $timeout -eq 10 ]; then
            echo "$(timestamp) ERROR: Timed out waiting for valheim_server.exe to be running"
            exit 1
        fi
        sleep 6
        ((timeout++))
        echo "$(timestamp) INFO: Waiting for valheim_server.exe to be running"
    done

    echo " "
    # Hold us open until we receive SIGTERM or a scheduled action fires
    wait

    # kill -2 above is a graceful request, not instant — make sure it's actually gone
    tail --pid=$valheim_pid -f /dev/null

    if [ "$shutdown_requested" = "1" ]; then
        break
    fi
    echo "$(timestamp) INFO: Restarting server (scheduled update/restart)"
done

kill "$scheduler_pid" 2>/dev/null

# o7
echo "$(timestamp) INFO: Shutdown complete."
exit 0
