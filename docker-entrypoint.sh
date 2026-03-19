#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/var/lib/minetest"
GAMES_DIR="${DATA_DIR}/games"
WORLDS_DIR="${DATA_DIR}/worlds"

SEED_GAME_DIR="/opt/luanti-games/minetest"
TARGET_GAME_DIR="${GAMES_DIR}/minetest"

mkdir -p "${GAMES_DIR}" "${WORLDS_DIR}"

# If /var/lib/minetest is a volume, the baked-in game is hidden.
# Seed it into the volume on first start.
if [ ! -d "${TARGET_GAME_DIR}" ] || [ -z "$(ls -A "${TARGET_GAME_DIR}" 2>/dev/null || true)" ]; then
  rm -rf "${TARGET_GAME_DIR}"
  mkdir -p "${TARGET_GAME_DIR}"
  cp -a "${SEED_GAME_DIR}/." "${TARGET_GAME_DIR}/"
fi

exec "$@"

