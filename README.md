# Docker container for Opensim in Ubuntu 22.04

## Usage

1. Clone this repository `gh repo clone louise-scherrer/docker_opensim`
1. Enter the repository `cd docker_opensim`
1. Run `xhost +local:` to give permission to use the X11 socket for GUI display
1. To use it:
   1. Use `./start-opensim.sh run opensim` to run opensim from the published image ghcr.io/louise-scherrer/opensim:main
   1. Or use:
      1. `./start-opensim.sh build opensim-dev` to build a local container and run opensim
      1. `./start-opensim.sh run opensim-dev` to run the opensim from the local container
      1. `./start-opensim.sh run opensim bash` to enter a shell script in the local container

Note:
1. the `docker-compose.yml` file mounts the `./work` folder into the image by default
1. `start-opensim.sh` is a wrapper script to run the container with the right user's UID/GID within the container so that shared files in ./work volume keep the correct permissions
