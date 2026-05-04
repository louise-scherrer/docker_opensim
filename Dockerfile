FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---- Create non-root user ----
ARG USERNAME=myuser
ARG UID=1000
ARG GID=1000

# ---- Base + runtime deps (keep minimal but functional) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo ca-certificates curl git bash \
    lsb-release wget \
    locales \
    # JxBrowser/Chromium runtime deps (fixes gray view + NPEs in containers)
    libnss3 libnspr4 \
    libxss1 libxcomposite1 libxdamage1 libxrandr2 libxfixes3 libxtst6 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libdrm2 libgbm1 \
    libgtk-3-0 libgtk2.0-0 \
    libasound2 \
    libxkbcommon0 libxkbcommon-x11-0 \
    libpangocairo-1.0-0 libpango-1.0-0 libcairo2 \
    libdbus-1-3 \
    fonts-liberation \
    # for clean privilege drop in entrypoint
    gosu \
 && rm -rf /var/lib/apt/lists/*

# ---- Locale (UTF-8) ----
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


# ---- Create non-root user ----
RUN groupadd -g ${GID} ${USERNAME} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} \
 && usermod -aG sudo ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}
 
 # These are *environment variables* many scripts expect (your build script does).
ENV USER=${USERNAME}
ENV HOME=/home/${USERNAME}

# ---- Build OpenSim GUI from upstream build script ----
USER ${USERNAME}
WORKDIR /home/${USERNAME}/src

# Fetch + run build script; answer "yes" to the two ln overwrite prompts. 
 RUN set -eux; \
    curl -L -o opensim-gui-linux-build-script.sh \
      https://raw.githubusercontent.com/opensim-org/opensim-gui/refs/heads/main/scripts/build/opensim-gui-linux-build-script.sh; \
    chmod +x opensim-gui-linux-build-script.sh; \
    yes | ./opensim-gui-linux-build-script.sh

# Optionally clone models (useful for demos)
RUN git clone --depth 1 https://github.com/opensim-org/opensim-models.git /home/${USERNAME}/opensim-models || true

# Switch back to root to install entrypoint
USER root

# Try to expose OpenSim on PATH in a robust way.
# (If the script already installs /usr/local/bin/opensim, this is harmless.)
RUN ln -sf /opt/opensim-gui/bin/opensim /usr/local/bin/opensim 2>/dev/null || true \
 && ln -sf /opt/opensim-gui/bin/opensim /usr/local/bin/OpenSim 2>/dev/null || true

# ---- Entrypoint: fix TMPDIR + GPU group + drop to user ----
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default runtime env for the visualizer temp dir
ENV TMPDIR=/home/${USERNAME}/.cache/opensim-tmp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opensim"]

