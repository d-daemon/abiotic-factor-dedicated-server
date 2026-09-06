FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture and install Wine + dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        sqlite3 \
        locales \
        procps \
        wine \
        wine64 \
        wine32 \
        xvfb && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    WINEDEBUG=-all

# Install SteamCMD
WORKDIR /steamcmd
RUN curl -sSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -zxvf -

WORKDIR /game
VOLUME ["/game"]

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7777/udp 27015/udp

ENTRYPOINT ["/entrypoint.sh"]