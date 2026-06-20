# Autoware on RoboRacer

This branch contains a version of Autoware with interfaces and configurations specifically for RoboRacer. It is bases on release tag 1.6.0 of Autoware.

This readme contains information on installing and running Autoware on the Roboracer. The original Autoware readme can be found [here](./README_AUTOWARE.md) for reference.

---

# Supported Platforms

While this guide focuses on setting up Autoware on the RoboRacer platform, this setup supports both:

- **Jetson AGX Orin (RoboRacer target platform)**  
- **x86_64 host machine (Ubuntu 22.04)** — recommended for development and faster builds  

The setup process is almost identical on both platforms, **differences are indicated in the applicable steps**.

---

# Autoware Installation on Jetson AGX Orin

This tutorial provides step-by-step instructions for installing and setting up the Autoware development environment on the RoboRacer car. The Autoware installation process in this branch is modified from the main one to adapt to the Jetson AGX Orin hardware and software systems. 

For instructions on manually setting up a development environment for a standard Autoware release on NVIDIA Jetson, see [manual_setup.md](./manual_setup.md).

This guide assumes you are using `JetPack 6.2.1` on `Ubuntu 22.04` and will run this `RoboRacer` version of `Autoware 1.6.0` on `ROS2 humble`.

The original [Autoware installation documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/autoware/source-installation/) from main branch is here for your reference.

The approximate time investments listed are based on running Jetson AGX Orin on the `MAXN SUPER` power mode.

## Jetson AGX Orin Only: Flash JetPack 6.2.1 to Jetson AGX Orin
(Approximate time investment: 1 hour)

*Skip this section if you are using an x86 host machine.*

There are multiple ways to install JetPack on a Jetson as described in [Jetpack 6.2.1 Documentation](https://developer.nvidia.com/embedded/jetpack-sdk-621). The recommended ways to install are via the `NVIDIA SDK Manager Method`. This guide was tested using JetPack 6.2.1. Other JetPack versions may also work but have not yet been tested.

### NVIDIA SDK Manager Method:
This method requires a Linux host computer running Ubuntu Linux x64 version `22.04` with `~40GB` of disk space

For this method, you will first install `NVIDIA SDK Manager` on your host machine, connect the host machine to the Jetson AGX Orin via a `USB-C` cable, download all of the necessary JetPack components using the SDK Manager, and then flash the JetPack to the target Jetson AGX Orin. This method allows you to directly flash the JetPack to the `NVME SSD drive` on the RoboRacer car's Jetson. You may need to create an NVIDIA account to download the NVIDIA SDK manager.

1. Download and install [SDK Manager](https://developer.nvidia.com/sdk-manager) on your host machine.

2. Follow the steps at [Install Jetson Software with SDK Manager](https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html). Select JetPack version 6.2.1. The target hardware will be the Jetson Orin Nano.
    Make sure to also select `Jetson SDK Components` for installation. This is not selected by default.

3. If you have trouble flashing the JetPack, you can put the Jetson into [`Force Recovery Mode`](https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/howto.html#force-recovery-mode).


## Set up Autoware development environment 
(Approximate time investment: 2-3 hours)

Some of the dependencies required for Autoware can't be or aren't installed automatically on Jetson platforms. These need to be set up manually.
1. Start by updating the system en ensuring the Jetpack packages are installed on your Jetson. This will install, among others, CUDA, CUDNN and TensorRT, which are required by Autoware. 

    **On Jetson AGX Orin:**
    ```bash
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y nvidia-jetpack
    sudo reboot
    ```
    **On x86 host machine:**
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

2. Clone the `roboracer_humble` branch of Autoware (this branch is currently based on version `1.6.0` of `autowarefoundation/autoware`) and move to the directory.
    ```bash
    cd ~
    git clone -b roboracer_humble https://github.com/YonVanom/autoware.av4ev_gokart.git autoware
    cd autoware
    ```

3. Install the Autoware dependencies by running the provided setup script.

   **On Jetson AGX Orin:**
   ```bash
   ./setup-dev-env.sh --jetson
   ```

   **On x86 host machine:**
   ```bash
   ./setup-dev-env.sh
   ```
   
   The --jetson flag implies --no-cuda and --no-nvidia as these are already installed with the JetPack It also installs a compatible version of opencv (instead of the nvidia one), builds spconv and cumm from scratch to ensure they are compatible with the version of cuda on the jetson, and disables the agnocast installation as described in [manual_setup.md](./manual_setup.md).

4. Lastly, make sure the CUDNN and TensorRT CMAKE modules are installed:
    ```bash
    sudo apt update 
    sudo apt install -y ros-humble-cudnn-cmake-module ros-humble-tensorrt-cmake-module
    ```


## Set up Autoware workspace 
(Approximate time investment: 3-4 hours)

1. Make sure you are in the previously created autoware directory
    ```bash
    cd autoware
    ```

2. Create the `src` directory and clone repositories into it.

   Autoware uses [vcstool](https://github.com/dirk-thomas/vcstool) to construct workspaces.

   ```bash
   mkdir -p src
   vcs import src < repositories/autoware.repos
   ```

3. Install dependent ROS packages.

    ```bash
    source /opt/ros/humble/setup.bash
    sudo apt update && sudo apt upgrade
    rosdep update
    rosdep install -y --from-paths src --ignore-src --rosdistro $ROS_DISTRO
    ```

3. Create swapfile. (Originally from Autoware [troubleshooting section](https://autowarefoundation.github.io/autoware-documentation/main/support/troubleshooting/#build-issues))

   Building Autoware requires a lot of memory. On systems with limited RAM, the system can crash during a build because of insufficient memory. If ecountering this problem, 16-32GB of swap can be configured to resolve it.

   Optional: Check the current swapfile
   ```bash
   free -h
   ```
   
   Create a new swapfile
   ```bash
   sudo fallocate -l 32G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

   Optional: Check if the change is reflected
   ```bash
   free -h
   ```

   Optional: To make this change permanent
   ```bash
   sudo bash -c 'echo "/swapfile swap swap defaults 0 0" >> /etc/fstab'
   ```

4. Build the workspace.

   Autoware uses [colcon](https://github.com/colcon) to build workspaces.
   For more advanced options, refer to the [documentation](https://colcon.readthedocs.io/).

   ```bash
   colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
   ```

   Ignore the `stderr` warnings during the build.
   
## Network and DDS settings for ROS 2 and Autoware
Follow the official [Autoware documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/) to correctly configure the network and DDS settings.
 
---
   
# Autoware RoboRacer and the Autoware-RoboRacer Off-Road Simulator
This section provides instructions on setting up a closed-loop simulation with this **RoboRacer version of Autoware** and the **Autoware-RoboRacer off-road simulator**. It provides both instructions on running a `software-in-the-loop` simulation, i.e., both Autoware and the off-road simulator running on the same **x86 host machine**, and a `hardware-in-the-loop` simulation, i.e., Autoware running on the **target Jetson AGX Orin** connected to the off-road simulator on a **x86 host machine**. 

---

## Software-in-the-Loop Simulation
This section show how to run a `software-in-the-loop` simulation, where both **Autoware** and the **off-road simulator** are running on the same **x86 host machine**. It assumes you have configured the network and DDS settings according to the Autoware documentation. (See section `Network and DDS settings for ROS 2 and Autoware` above).

### Prerequisites

1. Set up up the Off-Road Simulator

   Follow the instructions provided in the [Autoware-RoboRacer Off-Road Simulator](https://github.com/autowarefoundation/autoware_off-road_sim) repository to set up the simulator on your **x86 host**. Specifically, **Docker Setup** and **Running the Simulation**.

2. Download the `pumptrack` example map for Autoware

   This Autoware map matches the default map in the off-road simulator.
   ```bash
   cd ~/autoware_map
   gdown --folder https://drive.google.com/drive/folders/1KIsmlb0mSIftXOjA30qQLbdIt7t2ISJv?usp=sharing
   ```

### Run the simulator

   In one terminal window on your **x86 host**, run the simulator using the Docker container:
   ```bash
   cd autoware_off-road_sim
   ./docker/run.sh
   ```
   
   Make sure to launch the simulator using the provided autoware-specific configuration file. Inside the docker container:
   ```bash
   /root/isaacsim/_build/linux-x86_64/release/python.sh scripts/launch_sim.py --config scripts/configs/pumptrack_autoware_config.yaml
   ```   
   
   (This configuration assumes you are using the loopback network device `lo` as according to the Autoware documentation. It also disables remapping of frame ids.)
   
### Run Autoware RoboRacer

   In a second terminal window on your **x86 host**:
   ```bash
   cd autoware
   ```
   
   Make sure to source both your base ROS 2 install, and Autoware:
   ```bash
   source /opt/ros/humble/setup.bash
   source install/setup.bash
   ```
   
   Launch Autoware using the RoboRacer-specific launch files:
   ```bash
   ros2 launch offroad_launch e2e_simulator.launch.xml vehicle_model:=roboracer_offroad_isaac sensor_model:=roboracer_offroad_isaac_sensor_kit map_path:=$HOME/autoware_map/pumptrack/ launch_vehicle_interface:=true 
   ``` 
   Note: this assumes `autoware_map` is located in your home directoy. If this is not the case, update the `map_path` in the above command.
   
---
   
## Hardware-in-the-Loop Simulation
This section show how to run a `hardware-in-the-loop` simulation, where **Autoware** is running on one machine, e.g., the **target Jetson AGX Orin**, and the **off-road simulator** is running on a separate **x86 host machine**. It assumes you have configured the network and DDS settings according to the Autoware documentation on both machines. (See section `Network and DDS settings for ROS 2 and Autoware` above).
   
   
### Prerequisites

1. Set up up the Off-Road Simulator on the **x86 host**

   Follow the instructions provided in the [Autoware-RoboRacer Off-Road Simulator](https://github.com/autowarefoundation/autoware_off-road_sim) repository to set up the simulator on your **x86 host**. Specifically, **Docker Setup** and **Running the Simulation**.

2. Download the `pumptrack` example map for Autoware on the **target, e.g., the Jetson AGX Orin**

   This Autoware map matches the default map in the off-road simulator.
   ```bash
   cd ~/autoware_map
   gdown --folder https://drive.google.com/drive/folders/1KIsmlb0mSIftXOjA30qQLbdIt7t2ISJv?usp=sharing
   
3. Update network configuration

   Make sure both the target and host are connected using an ethernet connection, either directly or through a local network.
   Follow the steps outlined in the Autoware documentation for [communication across multiple computers](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/multiple-computers/). Make sure to **manually set the network interface** on both the host and target device, and to follow the steps regarding **time synchronization**.
   
4. Update the simulation configuration on the **host**

   Modify the `scripts/configs/pumptrack_autoware_config.yaml` configuration on the host. For example:
   ```bash
   cd autoware_off-road_sim
   nano scripts/configs/pumptrack_autoware_config.yaml
   ```
   In the `network_setup` section of the config file, update the `network_interface` to the interface via which the target can be reached. This should be the same as the `NetworkInterface` defined in your `cyclonedds.xml`. For example:
   ```yaml
   network_setup:
     ros2_domain_id: 0
     network_interface: "enp2s0"
   ```
   
### Run the simulator on the host

   In one terminal window on your **x86 host**, run the simulator using the Docker container:
   ```bash
   cd autoware_off-road_sim
   ./docker/run.sh
   ```
   
   Make sure to launch the simulator using the provided autoware-specific configuration file. Inside the docker container:
   ```bash
   /root/isaacsim/_build/linux-x86_64/release/python.sh scripts/launch_sim.py --config scripts/configs/pumptrack_autoware_config.yaml
   ```   
   
   (This configuration assumes you are using the loopback network device `lo` as according to the Autoware documentation. It also disables remapping of frame ids.)
   
### Run Autoware RoboRacer on the target

   In a terminal window on your **target**:
   ```bash
   cd autoware
   ```
   
   Make sure to source both your base ROS 2 install, and Autoware:
   ```bash
   source /opt/ros/humble/setup.bash
   source install/setup.bash
   ```
   
   Launch Autoware using the RoboRacer-specific launch files:
   ```bash
   ros2 launch offroad_launch e2e_simulator.launch.xml vehicle_model:=roboracer_offroad_isaac sensor_model:=roboracer_offroad_isaac_sensor_kit map_path:=$HOME/autoware_map/pumptrack/ launch_vehicle_interface:=true 
   ``` 
   Note: this assumes `autoware_map` is located in your home directoy. If this is not the case, update the `map_path` in the above command.
