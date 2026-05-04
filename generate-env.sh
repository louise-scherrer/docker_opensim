#!/bin/sh
# Generates a .env file with the current user's UID, GID, and USERNAME

echo "UID=$(id -u)" > .env
echo "GID=$(id -g)" >> .env
echo "USERNAME=myuser" >> .env

echo ".env file generated:"
cat .env
