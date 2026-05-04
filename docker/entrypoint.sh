#!/usr/bin/env bash
set -euo pipefail

USERNAME="${USERNAME:-myuser}"
TMPDIR="${TMPDIR:-/home/${USERNAME}/.cache/opensim-tmp}"

# Ensure TMPDIR exists and is writable by the user (JxBrowser extraction relies on this).
mkdir -p "${TMPDIR}"
chown -R "${USERNAME}:${USERNAME}" "${TMPDIR}"
chmod 700 "${TMPDIR}" || true

# If the host GPU is passed through, automatically add user to the render group GID.
# This avoids hardcoding "--group-add 992" on the host.
if ls /dev/dri/renderD* >/dev/null 2>&1; then
  RENDER_NODE="$(ls /dev/dri/renderD* | head -n 1)"
  RENDER_GID="$(stat -c '%g' "${RENDER_NODE}")"

  # Create a named group for that GID (if not already present)
  if ! getent group "${RENDER_GID}" >/dev/null 2>&1; then
    groupadd -g "${RENDER_GID}" renderhost 2>/dev/null || true
  fi

  # Add user to the numeric render group
  usermod -aG "${RENDER_GID}" "${USERNAME}" 2>/dev/null || true
fi

# Also add to video if it exists (often needed for card* nodes)
if getent group video >/dev/null 2>&1; then
  usermod -aG video "${USERNAME}" 2>/dev/null || true
fi

# If "opensim" isn't found but ./opensim exists in common install location, run it.
# Otherwise, run the requested command.
if [[ "${1:-}" == "opensim" ]]; then
  if command -v opensim >/dev/null 2>&1; then
    exec gosu "${USERNAME}" opensim
  elif [[ -x /opt/opensim-gui/bin/opensim ]]; then
    exec gosu "${USERNAME}" /opt/opensim-gui/bin/opensim
  elif [[ -x /opt/opensim-gui/opensim ]]; then
    exec gosu "${USERNAME}" /opt/opensim-gui/opensim
  else
    echo "ERROR: cannot find OpenSim executable (opensim)." >&2
    echo "Tried: opensim in PATH, /opt/opensim-gui/bin/opensim" >&2
    exit 127
  fi
else
  exec gosu "${USERNAME}" "$@"
fi

# Below hack to give privileges to write on the mounted volume at image run
sudo chown -R 1000:0 work/  # to add to grant writing privileges in ~/work
