# Docker container for Opensim in Ubuntu 22.04
## Docker container based on Ubuntu 22.04 base container, with installation of Opensim core and GUI (https://simtk.org/projects/opensim), compiled from source following Opensim's build instructions (https://github.com/opensim-org : opensim-core, opensim-gui and opensim-models packages)

## Current Dockerfile use
* Based on the Dockerfile + the entrypoint.sh script
* During the build, 
    * the settings of a typical user on a Ubuntu system called __myuser__ are replicated, notably the Opensim installation is meant to be run by a user __myuser__ which has sudo privileges,
    * basic graphical interface libraries are installed, that are undeclared dependencies of Opensim (as far as I know): without them the GUI might launch but the central window remains grey and non interactive, and does not display the simulation world and models,
    * then the install scripts provided on Opensim's Guithub are run: they use apt to install most dependencies then compile opensim-core and opensim-gui from Github sources).
    
## Build instructions
* Assumption: the user group `docker` exists and was configured following Docker's recommandations to allow Docker run commands as non-root user (https://docs.docker.com/engine/install/linux-postinstall/) Commands: `sudo groupadd docker` then `sudo usermod -aG docker $USER`
* The following was added to the file `/etc/docker/daemon.json`, 
`{
  "dns": ["1.1.1.1", "8.8.8.8"]
}`. 
It is supposed to allow the Opensim install script to access for example `archive.ubuntu.com` when running `apt install...`.
* (Fast and rather unsafe method) Expose your xhost so that the container can display the GUI by reading and writing though the X11 unix socket: `xhost +local:docker`. (Maybe consider safer options, some examples are proposed here: https://wiki.ros.org/docker/Tutorials/GUI)
* Build the docker using `docker build -t ubuntu_22_opensim_gui .`

## Run instructions
* Run the container for the first time, it is named **opensim_dev** here
`docker run -it \ --name opensim_dev \ --shm-size=1g \ -e DISPLAY=$DISPLAY \ -v /tmp/.X11-unix:/tmp/.X11-unix \ --device /dev/dri:/dev/dri \ -v ~/opensim_docker_mounted_volume:/home/myuser/work \ ubuntu_22_opensim_gui \ bash`
* Launch OpenSim GUI by entering the command `opensim`, which is set in the Dockerfile
* Restart the same container: `docker start -ai opensim_dev`
* (UNTESTED) To open another terminal in the same running container, the command should be `docker exec -it opensim_dev bash`
* As for typical Docker containers, exit the container by typing the command `exit`
* Optionnal, run `xhost -local:root` to restore the access control to the X server that were disabled before running the container

## Opensim and GUI
* The container opens a bash terminal as user __myuser__ when running. The command `opensim` opens the GUI. It should allow to do all that is planned in the doc (https://opensimconfluence.atlassian.net/wiki/spaces/OpenSim/overview).

## Notes on options
* `--shm-size=1g` gives the Docker more shared memory space (a bit of the RAM) to run into that the default, which is very small (64MB) and not sufficient for large GUI
* For the DNS fix, there must be other/better ways, maybe the option `--network=host` when running docker build (TODO (Louise) test it)? See https://docs.docker.com/engine/daemon/troubleshoot/#specify-dns-servers-for-docker
* If the `~/opensim_docker_mounted_volume` folder does not exist, it is created when running the Docker for the first time

## TODOs
* Explore options (`--network=host` and all those concerning graphical display that were added when debugging the GUI, some might be useless, check that `--shm-size=1g` is still useful)
* Explore how to reduce the size of the Docker
* Test the GUI for more than just loading a model and running the simulation under gravity: model scaling, importing a custom model, exporting simulation files.
