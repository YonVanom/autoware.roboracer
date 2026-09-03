# Installation, x86 Host

This guide installs Autoware (based on Autoware 1.6.0, ROS 2 Humble) on an x86_64 machine running Ubuntu 22.04. An x86 host is recommended for development and faster builds.

For installation on the Jetson AGX Orin target platform, see [Installation, Jetson AGX Orin](jetson-agx-orin.md).

---

## 1. Set Up Autoware Dependencies
*(Approximate time: 1–2 hours)*

1. Update the system.

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Clone this repository and move into the directory.

   ```bash
   cd ~
   git clone -b kar_gokart_humble https://github.com/YonVanom/autoware.roboracer.git autoware
   cd autoware
   ```

3. Run the setup script.

   ```bash
   ./setup-dev-env.sh
   ```

4. Install the cuDNN and TensorRT CMake modules.

   ```bash
   sudo apt update
   sudo apt install -y ros-humble-cudnn-cmake-module ros-humble-tensorrt-cmake-module
   ```

---

## 2. Set Up the Autoware Workspace
*(Approximate time: 1–2 hours on a modern x86 machine)*

1. Ensure you are in the autoware directory.

   ```bash
   cd ~/autoware
   ```

2. Create the `src` directory and clone all repositories.

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

4. Build the workspace.

   The ZED packages (`zed_components`, `zed_debug`) require the ZED SDK to be installed. Either install it from the [ZED SDK Downloads](https://www.stereolabs.com/developers/release) page, or skip those packages during the build:

   ```bash
   # With ZED SDK installed
   colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

   # Without ZED SDK
   colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release \
     --packages-skip zed_components zed_debug
   ```

   Ignore `stderr` warnings during the build.

---

## 3. Network and DDS Settings

Follow the official [Autoware DDS documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/) to configure network and DDS settings correctly before running.

---

## Next Steps

- [Software-in-the-Loop Simulation](../simulation/software-in-loop.md), run the full stack on your x86 machine
- [Hardware-in-the-Loop Simulation](../simulation/hardware-in-loop.md), run the simulator on x86, Autoware on Jetson
