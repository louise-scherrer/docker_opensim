#!/bin/bash
# Exit on error
set -e

# 1. Capture IDs from environment (or use defaults)
USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}

echo "Configuring myuser with UID $USER_ID and GID $GROUP_ID..."

# 2. Update Group and User IDs
# We use '|| true' in case the IDs are already set to avoid exit errors
groupmod -g "$GROUP_ID" myuser || true
usermod -u "$USER_ID" -g "$GROUP_ID" myuser || true

# 3. Ensure the home directory is owned by the new ID
chown -R myuser:myuser /home/myuser

# 4. Refresh the passwd database for sudo (fixes the 'does not exist' error)
# This clears any SSSD or nscd caches if they exist
[ -x /usr/sbin/nscd ] && /usr/sbin/nscd -i passwd || true

# 5. Hand off to the application as 'myuser'
# 'exec' ensures myuser becomes PID 1, handling signals (SIGTERM) properly
echo "Switching to myuser..."
exec gosu myuser "$@"
#
# #!/usr/bin/env bash
# set -euo pipefail
#
# USERNAME="${USERNAME:-myuser}"
# TMPDIR="${TMPDIR:-/home/${USERNAME}/.cache/opensim-tmp}"
#
# # Ensure TMPDIR exists and is writable by the user (JxBrowser extraction relies on this).
# mkdir -p "${TMPDIR}"
# sudo chown -R "${USERNAME}:${USERNAME}" "${TMPDIR}"
# sudo chmod 700 "${TMPDIR}" || true
#
# # If the host GPU is passed through, automatically add user to the render group GID.
# # This avoids hardcoding "--group-add 992" on the host.
# if ls /dev/dri/renderD* >/dev/null 2>&1; then
#   RENDER_NODE="$(ls /dev/dri/renderD* | head -n 1)"
#   RENDER_GID="$(stat -c '%g' "${RENDER_NODE}")"
#
#   # Create a named group for that GID (if not already present)
#   if ! getent group "${RENDER_GID}" >/dev/null 2>&1; then
#     sudo groupadd -g "${RENDER_GID}" renderhost 2>/dev/null || true
#   fi
#
#   # Add user to the numeric render group
#   sudo usermod -aG "${RENDER_GID}" "${USERNAME}" 2>/dev/null || true
# fi
#
# # Also add to video if it exists (often needed for card* nodes)
# if getent group video >/dev/null 2>&1; then
#   sudo usermod -aG video "${USERNAME}" 2>/dev/null || true
# fi
#
# # If "opensim" isn't found but ./opensim exists in common install location, run it.
# # Otherwise, run the requested command.
# if [[ "${1:-}" == "opensim" ]]; then
#   if command -v opensim >/dev/null 2>&1; then
#     exec opensim
#   elif [[ -x /opt/opensim-gui/bin/opensim ]]; then
#     exec /opt/opensim-gui/bin/opensim
#   elif [[ -x /opt/opensim-gui/opensim ]]; then
#     exec /opt/opensim-gui/opensim
#   else
#     echo "ERROR: cannot find OpenSim executable (opensim)." >&2
#     echo "Tried: opensim in PATH, /opt/opensim-gui/bin/opensim" >&2
#     exit 127
#   fi
# else
#   exec "$@"
# fi
