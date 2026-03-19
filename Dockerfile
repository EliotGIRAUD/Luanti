## Multi-stage build: compile Luanti with Prometheus enabled (build-time)
FROM debian:bookworm AS builder

ARG LUANTI_REF=master
ARG GAME_REPO=https://github.com/minetest/minetest_game.git
ARG GAME_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git \
    build-essential cmake ninja-build pkg-config \
    libcurl4-openssl-dev libfreetype6-dev \
    libsqlite3-dev libpq-dev \
    zlib1g-dev libbz2-dev libzstd-dev \
    libluajit-5.1-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Build prometheus-cpp from source (needed for ENABLE_PROMETHEUS=1)
RUN git clone --depth 1 --recurse-submodules https://github.com/jupp0r/prometheus-cpp.git /src/prometheus-cpp \
    && cmake -S /src/prometheus-cpp -B /src/prometheus-cpp/build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_TESTING=OFF \
    && cmake --build /src/prometheus-cpp/build \
    && cmake --install /src/prometheus-cpp/build

# Luanti engine
RUN git clone --depth 1 --branch "${LUANTI_REF}" https://github.com/luanti-org/luanti.git

# Game (minetest_game -> gameid "minetest")
RUN git clone --depth 1 --branch "${GAME_REF}" "${GAME_REPO}" /src/game-src

WORKDIR /src/luanti

RUN cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SERVER=1 \
    -DBUILD_CLIENT=0 \
    -DENABLE_PROMETHEUS=1 \
    -DENABLE_CURSES=0 \
    -DENABLE_SOUND=0

RUN cmake --build build

# Install into /usr/local so runtime can copy share data too
RUN cmake --install build --prefix /usr/local && \
    mkdir -p /usr/local/share/luanti/games && \
    cp -a /src/game-src /usr/local/share/luanti/games/minetest


## Runtime image
FROM debian:bookworm-slim

RUN groupadd -r minetest && useradd -r -g minetest minetest

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    bash \
    libcurl4 \
    libfreetype6 \
    libsqlite3-0 \
    libpq5 \
    libluajit-5.1-2 \
    zlib1g libbz2-1.0 libzstd1 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/minetest /var/lib/minetest /var/lib/minetest/games /var/lib/minetest/worlds
RUN chown -R minetest:minetest /var/lib/minetest

COPY --from=builder /usr/local/bin/luantiserver /usr/local/bin/luantiserver
COPY --from=builder /usr/local/share/luanti /usr/local/share/luanti
COPY --from=builder /usr/local/lib/ /usr/local/lib/
RUN ldconfig

# Seed game (will be copied into /var/lib/minetest volume at runtime)
RUN mkdir -p /opt/luanti-games
COPY --from=builder /src/game-src /opt/luanti-games/minetest

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh && chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 30000/udp

ENV HOME=/var/lib/minetest

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
USER minetest
WORKDIR /var/lib/minetest

CMD ["luantiserver", "--config", "/etc/minetest/minetest.conf", "--gameid", "minetest", "--worldname", "world"]
