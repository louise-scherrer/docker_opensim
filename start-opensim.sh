#!/bin/sh
# Wrapper to run docker compose with current user's UID, GID, and USERNAME

PUID=$(id -u)
PGID=$(id -g)
NUM_JOBS=$(nproc)

if [ "$#" -eq 0 ]; then
  set -- run opensim
fi

export PUID PGID NUM_JOBS
exec docker compose "$@"
