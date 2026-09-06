# Abiotic Factor Dedicated Server

Run an *Abiotic Factor* dedicated server in Docker. The container uses SteamCMD to download and update the Windows server, then runs it headlessly through Wine.

## Quick start

You need a 64-bit Linux host or NAS with Docker Engine and the Compose plugin. Allow at least 8 GB of free disk space and UDP access to ports `7777` and `27015`.

From the project directory:

```sh
cp .env.example .env
```

Edit `.env` if needed, especially `SERVER_NAME` and `SERVER_PASSWORD`, then start the server:

```sh
docker compose up -d --build
docker compose logs -f abiotic-server
```

The first start downloads the server and may take several minutes. It is ready when the logs show the game process launching. The container restarts automatically unless you stop it.

### Synology

Copy this repository to a shared folder, open **Container Manager > Project > Create**, select that folder, and build/start the project. Allow UDP ports `7777` and `27015` through the NAS firewall and router.

## Configuration

Compose reads `.env` automatically. The most useful settings are:

| Variable | Default | Purpose |
| --- | --- | --- |
| `SERVER_NAME` | `Abiotic Factor Facility` | Server browser name |
| `SERVER_PASSWORD` | empty | Join password; empty means public |
| `WORLD_SAVE_NAME` | `Cascade` | World save name |
| `MAX_PLAYERS` | `6` | Player limit |
| `IMAGE_REPOSITORY` | `hhxcusco/abiotic-server` | Docker image repository |
| `GAME_PORT` | `7777` | Game UDP port |
| `QUERY_PORT` | `27015` | Steam query UDP port |

Do not commit `.env` if it contains a password. After changing `.env`, recreate the container:

```sh
docker compose up -d --force-recreate
```

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

## Published image

The default `docker-compose.yml` builds locally. To use the published image instead:

```sh
cp docker-compose.yml.example docker-compose.yml
cp .env.example .env
docker compose up -d
```

Review the image name before using this option with a fork.

## License and game files

This repository provides container configuration and startup scripts. *Abiotic Factor* and its server files belong to their respective rights holders and are downloaded through SteamCMD at runtime.