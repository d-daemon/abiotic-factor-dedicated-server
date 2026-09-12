# Abiotic Factor Dedicated Server

[![Build and publish server image](https://github.com/d-daemon/abiotic-factor-dedicated-server/actions/workflows/docker-build.yml/badge.svg)](https://github.com/d-daemon/abiotic-factor-dedicated-server/actions/workflows/docker-build.yml)
[![Docker pulls](https://img.shields.io/docker/pulls/hhxcusco/abiotic-server?logo=docker)](https://hub.docker.com/r/hhxcusco/abiotic-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Run an **Abiotic Factor** dedicated server using Docker.

## Prerequisites

- `64-bit Linux host` or `Windows host with Windows Subsystem for Linux (WSL)`
- `Docker` or `Synology Container Manager`
- At least `8 GB` of free disk space
- UDP access to ports `7777` and `27015`

## Quick start

If you are using Synology Container Manager, jump straight to [Synology](#synology).

Create a folder for the server and add these items to it:

- `.env`
- `compose.yml`
- `game_data/`

The folder should look like this:

```text
abiotic-factor/
├── .env
├── compose.yml
└── game_data/
```

Copy the repository's `compose.yml` into your server folder, then create `.env` and edit `SERVER_NAME` and `SERVER_PASSWORD` as needed. The `game_data` folder can be empty; it stores the downloaded game files, saves, configuration, and logs.

The published image workflow uses `hhxcusco/abiotic-server:latest`, so you do not need to clone the repository or download the Dockerfile and startup script.

```sh
docker compose up -d
docker compose logs -f abiotic-server
```

The first start downloads the Docker image and game server files and may take several minutes. It is ready when the logs show the game process launching. The container restarts automatically unless you stop it.

### Synology

For Synology Container Manager, set up the published image workflow as follows:

1. Create a shared-folder subfolder named `abiotic-factor`.
2. Create a `game_data` folder inside `abiotic-factor`. This folder stores the downloaded game files, saves, configuration, and logs.
3. Create an `.env` file inside `abiotic-factor` and set your server settings, especially `SERVER_NAME` and `SERVER_PASSWORD`. You can also add a Discord webhook URL in `DISCORD_WEBHOOK_URL` so the server broadcasts its latest join code.
4. Add the repository's `compose.yml` inside `abiotic-factor`.
5. In **Container Manager > Project > Create**, create a project named `abiotic-factor` and select the `abiotic-factor` folder as the project path.
6. Open UDP ports `7777` and `27015` in the Synology firewall and forward both UDP ports from your router to the Synology NAS.
7. Start the project. Container Manager downloads the published Docker image and the game server files; the first start may take several minutes.

The project folder should contain `compose.yml`, `.env`, and the `game_data` directory at the same level.

## Configuration

Compose reads `.env` automatically. The most useful settings are:

| Variable | Default | Purpose |
| --- | --- | --- |
| `SERVER_NAME` | `Abiotic Factor Facility` | Server browser name |
| `SERVER_PASSWORD` | | Join password; empty means public |
| `WORLD_SAVE_NAME` | `Cascade` | World save name |
| `MAX_PLAYERS` | `6` | Player limit |
| `GAME_PORT` | `7777` | Game UDP port |
| `QUERY_PORT` | `27015` | Steam query UDP port |
| `DISCORD_WEBHOOK_URL` | | Optional Discord webhook for a startup server-info notification |

After changing `.env`, recreate the container:

```sh
docker compose up -d --force-recreate
```

When `DISCORD_WEBHOOK_URL` is configured, the server posts its join code, world,
player limit, password status, and ports to Discord after the server logs its
automatically generated join code. It also logs a shutdown/restart status line
and sends that lifecycle event to Discord when the game process exits or the
container is stopped. Webhook failures do not prevent the game server from
starting.

## Ports and data

Both published ports use UDP. If you change `GAME_PORT` or `QUERY_PORT`, open and forward the new ports on your firewall and router:

- `7777`: game traffic
- `27015`: server query and browser discovery

Game files, saves, configuration, and logs are stored in `./game_data`. Back up `game_data/AbioticFactor/Saved/` before changing hosts or experimenting with configuration. Do not delete `game_data` unless you want to remove the server and its saves.

## Useful commands

```sh
docker compose ps                         # Status
docker compose logs -f abiotic-server     # Live logs
docker compose restart abiotic-server     # Check for game updates
docker compose stop                       # Stop, keep data
docker compose down                       # Remove container and network
```

SteamCMD validates the server files every time the container starts, so restarting also checks for game updates. If startup fails, inspect the logs with `docker compose logs --tail=200 abiotic-server`; common causes are insufficient disk space, a failed download, or blocked UDP ports.

## License and game files

This repository provides container configuration and startup scripts. *Abiotic Factor* and its server files belong to their respective rights holders and are downloaded through SteamCMD at runtime.
