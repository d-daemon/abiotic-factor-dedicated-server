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
  local join_code_value=$1
  json_escape() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    printf '%s' "$value"
  }

  local server_name join_code world_save password_status payload
  server_name=$(json_escape "$SERVER_NAME")
  join_code=$(json_escape "$join_code_value")
  world_save=$(json_escape "$WORLD_SAVE_NAME")
  password_status="$( [ -n "$SERVER_PASSWORD" ] && printf 'Required' || printf 'None' )"
  payload=$(printf '{"username":"Abiotic Factor Server","embeds":[{"title":"%s","color":5814783,"fields":[{"name":"Join code","value":"%s","inline":false},{"name":"World","value":"%s","inline":true},{"name":"Players","value":"%s","inline":true},{"name":"Password","value":"%s","inline":true},{"name":"Ports","value":"Game: %s\\nQuery: %s","inline":true}]}]}' \
    "$server_name" "$join_code" "$world_save" "$MAX_PLAYERS" "$password_status" "$GAME_PORT" "$QUERY_PORT")

  if ! curl --fail --silent --show-error --max-time 10 \
    -H "Content-Type: application/json" \
    --data "$payload" \
    "$DISCORD_WEBHOOK_URL"; then
    echo "WARNING: Discord webhook notification failed; continuing with server startup."
  fi
}

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
  if [ -z "$DISCORD_WEBHOOK_URL" ]; then
    exec "$WINE_CMD" "$EXE_PATH" "${ARGS[@]}" "${ADDITIONAL_ARGS_ARRAY[@]}"
  fi

  echo "Discord webhook enabled; monitoring logs for the join code..."

  set +e
  "$WINE_CMD" "$EXE_PATH" "${ARGS[@]}" "${ADDITIONAL_ARGS_ARRAY[@]}" 2>&1 |
    while IFS= read -r line; do
      printf '%s\n' "$line"

      if [ -z "${JOIN_CODE_SENT:-}" ]; then
        join_code=$(printf '%s\n' "$line" | sed -n \
          's/.*Session short code:[[:space:]]*\([A-Za-z0-9][A-Za-z0-9]*\).*/\1/p')
        if [ -n "$join_code" ]; then
          JOIN_CODE_SENT=1
          send_discord_notification "$join_code"
        fi
      fi
    done
  server_exit_code=${PIPESTATUS[0]}
  set -e

  return "$server_exit_code"
}

run_server

