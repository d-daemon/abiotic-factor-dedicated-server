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

# Hand off execution to Wine
exec "$WINE_CMD" "$EXE_PATH" "${ARGS[@]}" "${ADDITIONAL_ARGS_ARRAY[@]}"

