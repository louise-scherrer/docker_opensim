FROM ubuntu:22.04

LABEL maintainer="Arnaud TANGUY <arn.tanguy@gmail.com>"
LABEL org.opencontainers.image.title="docker_opensim"
LABEL org.opencontainers.image.description="OpenSim Docker image with GUI support"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.authors="Arnaud TANGUY <arn.tanguy@gmail.com>; Louise Scherrer <louise.scherrer@lirmm.fr>"

ENV DEBIAN_FRONTEND=noninteractive

# ---- Create non-root user ----
ARG USERNAME=myuser
ENV USERNAME=${USERNAME}
ARG UID=1000
ARG GID=1000
# --- opensim build
ARG GUI_BRANCH=094fa00fdff624d6f7a97e4fc356f69d43220559
ARG CORE_BRANCH=8c51609d1039f5d536f53678edbfef4d7840774f
ARG NUM_JOBS=4

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
RUN getent group ${GID} || groupadd -g ${GID} ${USERNAME} \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} \
 && usermod -aG sudo ${USERNAME} \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}
 
 # These are *environment variables* many scripts expect (your build script does).
ENV USER=${USERNAME}
ENV HOME=/home/${USERNAME}

# ---- Build OpenSim GUI from upstream build script ----
USER ${USERNAME}
WORKDIR /home/${USERNAME}/opensim-workspace

# Fetch + run build script; answer "yes" to the two ln overwrite prompts. 
RUN set -eux \
   && curl -L -o opensim-gui-linux-build-script.sh \
     https://raw.githubusercontent.com/opensim-org/opensim-gui/refs/heads/main/scripts/build/opensim-gui-linux-build-script.sh \
   && sed -i "s/^GUI_BRANCH=.*/GUI_BRANCH=\"${GUI_BRANCH}\"/" opensim-gui-linux-build-script.sh \
   && sed -i "s/^CORE_BRANCH=.*/CORE_BRANCH=\"${CORE_BRANCH}\"/" opensim-gui-linux-build-script.sh \
   && chmod +x opensim-gui-linux-build-script.sh; \
   yes | ./opensim-gui-linux-build-script.sh \
   && rm -rf ~/opensim-workspace \
   && rm -rf ~/opensim-core ~opensim-workspace ~/netbeans-12.3 ~/swig;

RUN rm -rf ~/opensim-workspace
WORKDIR /home/${USERNAME}

# Clone models (useful for demos)
RUN git clone --depth 1 https://github.com/opensim-org/opensim-models.git /home/${USERNAME}/opensim-models

# ---- Entrypoint: fix TMPDIR + GPU group + drop to user ----
USER root
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Default runtime env for the visualizer temp dir
# TODO: remove
# ENV TMPDIR=/home/${USERNAME}/.cache/opensim-tmp

# Configures the container's runtime with a user "myuser" with UID and GID
# Matching the user's. UID/GID args are passed by start-opensim.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Run opensim by default
# The entrypoint accepts any command (bash, etc)
CMD ["opensim"]

