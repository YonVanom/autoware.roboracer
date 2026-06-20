# Manual Jetson Setup

This guide manually installs Autoware on an NVIDIA Jetson **without** using the automated `setup-dev-env.sh` script. Use this when the script is unavailable or when installing standard Autoware 1.6.0 (not the RoboRacer fork).

This guide assumes JetPack 6.2.1 on Ubuntu 22.04, targeting Autoware 1.6.0 on ROS 2 Humble.

The original [Autoware installation documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/autoware/source-installation/) is available for reference.

Approximate time investments are based on running the Jetson Orin Nano (Super) in `MAXN SUPER` power mode.

---

## 1. Set Up Autoware Dependencies
*(Approximate time: 2–3 hours)*

1. Update the system and install JetPack packages (CUDA, cuDNN, TensorRT).

   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y nvidia-jetpack
   sudo reboot
   ```

2. Install an Autoware-compatible version of OpenCV. The NVIDIA-provided OpenCV is missing functions required by Autoware.

   ```bash
   sudo apt remove --purge libopencv* opencv* python3-opencv
   sudo apt autoremove -y
   sudo apt autoclean
   sudo apt update
   sudo apt install -y libopencv-dev=4.5.4+dfsg-9ubuntu4 python3-opencv=4.5.4+dfsg-9ubuntu4
   ```

3. Build and install `spconv` and `cumm`. Autoware requires C++ versions of these libraries, which must be compiled from source on Jetson.

   ```bash
   git clone -b spconv_v2.3.8+cumm_v0.5.3 https://github.com/autowarefoundation/spconv_cpp
   cd spconv_cpp

   mkdir -p cumm/build && cd cumm/build && cmake .. && make && cpack -G DEB
   cd ../../ && sudo apt install ./cumm/_packages/cumm_0.5.3_arm64.deb

   mkdir -p spconv/build && cd spconv/build && cmake .. && make -j $(nproc) && cpack -G DEB
   cd ../../ && sudo apt install ./spconv/_packages/spconv_2.3.8_arm64.deb
   ```

---

## 2. Set Up Autoware Development Environment
*(Approximate time: 0.5 hours)*

1. Clone Autoware 1.6.0 and move into the directory.

   ```bash
   cd ~
   git clone -b 1.6.0 https://github.com/autowarefoundation/autoware.git
   cd autoware
   ```

2. **CRITICAL: Disable the `agnocast` task before running the setup script.**

   Agnocast is incompatible with the default Linux kernel version on Jetson and causes a **kernel panic** on the next boot. You will need to reflash the Jetson and start over if this happens.

   Open the Ansible playbook:
   ```bash
   sudo apt install nano
   nano ansible/playbooks/universe.yaml
   ```

   Find and remove these lines:
   ```yaml
   - role: autoware.dev_env.agnocast
     when: rosdistro == 'humble'
   ```

   Save with `Ctrl+X`, `Y`, `Enter`.

3. Run the setup script with the flags to skip NVIDIA/CUDA installation (already present from JetPack).

   ```bash
   ./setup-dev-env.sh --no-nvidia --no-cuda-drivers -y
   ```

   Forcing CUDA driver installation here can corrupt the kernel. You would need to reflash JetPack to recover.

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

2. Create the `src` directory and clone all repositories.

   ```bash
   mkdir src
   vcs import src < autoware.repos
   ```

3. Install ROS package dependencies.

   ```bash
   source /opt/ros/humble/setup.bash
   sudo apt update && sudo apt upgrade
   rosdep update
   rosdep install -y --from-paths src --ignore-src --rosdistro $ROS_DISTRO
   ```

4. Create a swap file (especially important on Jetson Orin Nano with limited RAM; less critical on Jetson AGX Orin).

   ```bash
   sudo fallocate -l 32G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile

   # Make permanent
   sudo bash -c 'echo "/swapfile swap swap defaults 0 0" >> /etc/fstab'
   ```

5. Build the workspace.

   ```bash
   colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
   ```

   Ignore `stderr` warnings during the build.
