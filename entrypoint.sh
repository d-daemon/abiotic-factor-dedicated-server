#!/usr/bin/env bash
set -e

# Workaround for SteamCMD hardware checks
export CPU_MHZ=2000

# Configuration variables with environment defaults
APP_ID=${APP_ID:-2857200}
GAME_PORT=${GAME_PORT:-7777}
QUERY_PORT=${QUERY_PORT:-27015}
SERVER_NAME=${SERVER_NAME:-"My Abiotic Factor Server"}
SERVER_PASSWORD=${SERVER_PASSWORD:-""}
WORLD_SAVE_NAME=${WORLD_SAVE_NAME:-"Cascade"}
MAX_PLAYERS=${MAX_PLAYERS:-6}
ADDITIONAL_ARGS=${ADDITIONAL_ARGS:-""}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL:-""}
SERVER_STARTED=0
DISCORD_SHUTDOWN_SENT=0
JOIN_CODE_CAPTURED=""

log_server_event() {
  local level=$1
  local message=$2
  echo "[$level] $message"
}

echo "=================================================="
echo " Starting Abiotic Factor Dedicated Server (Wine)"
echo "=================================================="

# Download/Update server files
echo "[1/2] Checking for game server updates via SteamCMD..."
/steamcmd/steamcmd.sh \
  +force_install_dir /game \
  +login anonymous \
  +@sSteamCmdForcePlatformType windows \
  +app_update "${APP_ID}" validate \
  +quit

echo "[2/2] Launching Abiotic Factor Dedicated Server..."
cd /game

EXE_PATH="./AbioticFactor/Binaries/Win64/AbioticFactorServer-Win64-Shipping.exe"

if [ ! -f "$EXE_PATH" ]; then
    echo "ERROR: Server executable not found at $EXE_PATH"
    exit 1
fi

send_discord_notification() {
  local title=${1:-"$SERVER_NAME"}
  local status=${2:-"Offline"}
  local join_code_value=${3:-""}

  json_escape() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    printf '%s' "$value"
  }

  local join_code world_save password_status status_value payload
  join_code=$(json_escape "${join_code_value:-Not available}")
  world_save=$(json_escape "$WORLD_SAVE_NAME")
  password_status="$( [ -n "$SERVER_PASSWORD" ] && printf 'Required' || printf 'None' )"

  case "$status" in
    "Online")
      status_value="🟢 Online"
      ;;
    "Offline")
      status_value="🔴 Offline"
      ;;
    *)
      status_value="⚪ ${status}"
      ;;
  esac

  payload=$(printf '{"username":"Abiotic Factor Server","embeds":[{"title":"%s","color":5814783,"fields":[{"name":"Join code","value":"%s","inline":true},{"name":"Status","value":"%s","inline":true},{"name":"World","value":"%s","inline":false},{"name":"Players","value":"%s","inline":false},{"name":"Password","value":"%s","inline":false},{"name":"Ports","value":"Game: %s\\nQuery: %s","inline":false}]}]}' \
    "$title" "$(json_escape "$status_value")" "$join_code" "$world_save" "$MAX_PLAYERS" "$password_status" "$GAME_PORT" "$QUERY_PORT")

  if ! curl --fail --silent --show-error --max-time 10 \
    -H "Content-Type: application/json" \
    --data "$payload" \
    "$DISCORD_WEBHOOK_URL"; then
    echo "WARNING: Discord webhook notification failed; continuing with server lifecycle update."
  fi
}

cleanup_on_exit() {
  local exit_code=$?

  if [ "${SERVER_STARTED:-0}" -eq 1 ] && [ "${DISCORD_SHUTDOWN_SENT:-0}" -eq 0 ]; then
    DISCORD_SHUTDOWN_SENT=1
    log_server_event "status" "Server is shutting down (exit code: ${exit_code})."

    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
      send_discord_notification "$SERVER_NAME" "Offline" "$JOIN_CODE_CAPTURED"
    fi
  fi
}

trap cleanup_on_exit EXIT

# Build arguments array
ARGS=(
  "-log"
  "-PORT=${GAME_PORT}"
  "-QueryPort=${QUERY_PORT}"
  "-ServerName=${SERVER_NAME}"
  "-WorldSaveName=${WORLD_SAVE_NAME}"
  "-MaxPlayers=${MAX_PLAYERS}"
)

# Append password flag only if set
if [ -n "$SERVER_PASSWORD" ]; then
    ARGS+=("-ServerPassword=${SERVER_PASSWORD}")
fi

# Choose whichever wine binary is present
WINE_CMD=$(command -v wine64 || command -v wine)

if [ -z "$WINE_CMD" ]; then
    echo "ERROR: Neither wine64 nor wine binary was found in PATH."
    exit 1
fi

echo "Launching game server using: $WINE_CMD"

# Preserve the configured space-separated flags as separate arguments.
read -r -a ADDITIONAL_ARGS_ARRAY <<< "$ADDITIONAL_ARGS"

run_server() {
  SERVER_STARTED=1

  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    log_server_event "status" "Server starting without Discord webhook notifications."
    exec "$WINE_CMD" "$EXE_PATH" "${ARGS[@]}" "${ADDITIONAL_ARGS_ARRAY[@]}"
  fi

  log_server_event "status" "Discord webhook enabled; monitoring logs for the join code and shutdown state..."

  set +e
  "$WINE_CMD" "$EXE_PATH" "${ARGS[@]}" "${ADDITIONAL_ARGS_ARRAY[@]}" 2>&1 |
    while IFS= read -r line; do
      printf '%s\n' "$line"

      if [ -z "${JOIN_CODE_SENT:-}" ]; then
        join_code=$(printf '%s\n' "$line" | sed -n \
          's/.*Session short code:[[:space:]]*\([A-Za-z0-9][A-Za-z0-9]*\).*/\1/p')
        if [ -n "$join_code" ]; then
          JOIN_CODE_SENT=1
          JOIN_CODE_CAPTURED="$join_code"
          log_server_event "status" "Server join code detected: ${join_code}"
          send_discord_notification "$SERVER_NAME" "Online" "$JOIN_CODE_CAPTURED"
        fi
      fi
    done
  server_exit_code=${PIPESTATUS[0]}
  set -e

  return "$server_exit_code"
}

run_server
