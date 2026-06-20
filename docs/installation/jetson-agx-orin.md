# Installation, Jetson AGX Orin

This guide installs Autoware (based on Autoware 1.6.0, ROS 2 Humble) on a Jetson AGX Orin running JetPack 6.2.1 on Ubuntu 22.04.

For installation on an x86 host machine, see [Installation, x86 Host](x86-host.md).

The approximate time investments are based on running the Jetson AGX Orin in `MAXN SUPER` power mode.

---

## 1. Flash JetPack 6.2.1
*(Approximate time: 1 hour)*

There are multiple ways to install JetPack as described in the [JetPack 6.2.1 Documentation](https://developer.nvidia.com/embedded/jetpack-sdk-621). The recommended method is the **NVIDIA SDK Manager Method**.

### NVIDIA SDK Manager Method

Requires a Linux host running Ubuntu 22.04 x64 with ~40 GB of free disk space.

1. Download and install [SDK Manager](https://developer.nvidia.com/sdk-manager) on your host machine.

2. Follow [Install Jetson Software with SDK Manager](https://docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html). Select JetPack **6.2.1** and the **Jetson AGX Orin** as the target. Make sure to also select **Jetson SDK Components** (not selected by default).

3. If the Jetson is unresponsive during flashing, put it into [Force Recovery Mode](https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/howto.html#force-recovery-mode).

---

## 2. Set Up Autoware Dependencies
*(Approximate time: 2–3 hours)*

Some Autoware dependencies cannot be installed automatically on Jetson. These must be set up first.

1. Update the system and install JetPack packages. This installs CUDA, cuDNN, and TensorRT, which Autoware requires.

   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y nvidia-jetpack
   sudo reboot
   ```

2. Clone this repository and move into the directory.

   ```bash
   cd ~
   git clone -b roboracer_humble https://github.com/YonVanom/autoware.av4ev_gokart.git autoware
   cd autoware
   ```

3. Run the setup script with the `--jetson` flag.

   ```bash
   ./setup-dev-env.sh --jetson
   ```

   The `--jetson` flag:
   - Implies `--no-cuda` and `--no-nvidia` (already installed with JetPack)
   - Installs a compatible version of OpenCV instead of the NVIDIA-provided one
   - Builds `spconv` and `cumm` from source for compatibility with the Jetson's CUDA version
   - Disables the `agnocast` installation (incompatible with the Jetson kernel, see [Manual Setup](manual-setup.md) for details)

4. Install the cuDNN and TensorRT CMake modules.

   ```bash
   sudo apt update
   sudo apt install -y ros-humble-cudnn-cmake-module ros-humble-tensorrt-cmake-module
   ```

---

## 3. Set Up the Autoware Workspace
*(Approximate time: 3–4 hours)*

1. Ensure you are in the autoware directory.

   ```bash
   cd ~/autoware
   ```

2. Create the `src` directory and clone all repositories. Autoware uses [vcstool](https://github.com/dirk-thomas/vcstool) to manage workspaces.

   ```bash
   mkdir -p src
   vcs import src < repositories/autoware.repos
   ```

3. Install ROS package dependencies.

   ```bash
   source /opt/ros/humble/setup.bash
   sudo apt update && sudo apt upgrade
   rosdep update
   rosdep install -y --from-paths src --ignore-src --rosdistro $ROS_DISTRO
   ```

4. Create a swap file. Building Autoware requires substantial memory. On systems with limited RAM, the build can crash. 16–32 GB of swap resolves this.

   ```bash
   # Check current swap
   free -h

   # Create a 32 GB swap file
   sudo fallocate -l 32G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile

   # Make permanent across reboots
   sudo bash -c 'echo "/swapfile swap swap defaults 0 0" >> /etc/fstab'
   ```

5. Build the workspace. Autoware uses [colcon](https://github.com/colcon).

   ```bash
   colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
   ```

   Ignore `stderr` warnings during the build.

---

## 4. Network and DDS Settings

Follow the official [Autoware DDS documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/) to configure network and DDS settings correctly before running.

---

## Next Steps

- [Software-in-the-Loop Simulation](../simulation/software-in-loop.md)
- [Hardware-in-the-Loop Simulation](../simulation/hardware-in-loop.md)
- [On-Vehicle Operation](../on-vehicle-operation.md)
