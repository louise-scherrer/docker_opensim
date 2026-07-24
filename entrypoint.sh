#!/bin/bash
# Exit on error
set -e

# Capture IDs from environment (or use defaults)
USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}

echo "Configuring myuser with UID $USER_ID and GID $GROUP_ID..."

# Update Group and User IDs
# We use '|| true' in case the IDs are already set to avoid exit errors
groupmod -g "$GROUP_ID" myuser || true
usermod -u "$USER_ID" -g "$GROUP_ID" myuser || true

# Ensure the home directory is owned by the new ID
chown -R myuser:myuser /home/myuser

# Refresh the passwd database for sudo (fixes the 'does not exist' error)
# This clears any SSSD or nscd caches if they exist
# [ -x /usr/sbin/nscd ] && /usr/sbin/nscd -i passwd || true

# Add opensim to PATH
export PATH="/opt/opensim-gui/bin:$PATH"

# Hand off to the application as 'myuser'
# 'exec' ensures myuser becomes PID 1, handling signals (SIGTERM) properly
echo "Switching to myuser..."
exec gosu myuser "$@"
