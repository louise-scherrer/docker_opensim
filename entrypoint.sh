#!/bin/bash
# Exit on error
set -e

# Capture IDs from environment (or use defaults)
USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}

echo "Configuring myuser with UID $USER_ID and GID $GROUP_ID..."

CURRENT_UID=$(id -u myuser)
CURRENT_GID=$(id -g myuser)

if [ "$USER_ID" != "$CURRENT_UID" ] || [ "$GROUP_ID" != "$CURRENT_GID" ]; then
  echo "Updating user/group IDs: USER_ID=$USER_ID (was $CURRENT_UID), GROUP_ID=$GROUP_ID (was $CURRENT_GID)"
  groupmod -g "$GROUP_ID" myuser || true
  usermod -u "$USER_ID" -g "$GROUP_ID" myuser || true
  # Ensure the home directory is owned by the new ID
  echo "Fixing /home/myuser ownership"
  chown -R myuser:myuser /home/myuser
  echo "Fixing /opt/opensim-gui ownership"
  sudo chown -R myuser:myuser /opt/opensim-gui
fi

# Add opensim to PATH
export PATH="/opt/opensim-gui/bin:$PATH"

# Hand off to the application as 'myuser'
# 'exec' ensures myuser becomes PID 1, handling signals (SIGTERM) properly
echo "Switching to myuser..."
exec gosu myuser "$@"
