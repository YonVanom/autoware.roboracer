# Autoware on RoboRacer

This branch contains Autoware with interfaces and configurations for the RoboRacer Off-Road platform, based on Autoware release 1.6.0. The original Autoware README is [here](./README_AUTOWARE.md).

[Demo video](https://drive.google.com/file/d/15U8plRqHoRn4PuRkvt0tRaTNCsWwtDhl/view?usp=sharing)

## Documentation

Full instructions are in the **[docs/](./docs/Home.md)** folder:

| Topic | |
|-------|-|
| [Installation, Jetson AGX Orin](docs/installation/jetson-agx-orin.md) | Set up on the target platform |
| [Installation, x86 Host](docs/installation/x86-host.md) | Set up on a development machine |
| [Manual Jetson Setup](docs/installation/manual-setup.md) | Step-by-step without the automated script |
| [Software-in-the-Loop Simulation](docs/simulation/software-in-loop.md) | Autoware + simulator on one x86 machine |
| [Hardware-in-the-Loop Simulation](docs/simulation/hardware-in-loop.md) | Autoware on Jetson, simulator on x86 |
| [Architecture Overview](docs/architecture.md) | How RoboRacer packages fit into Autoware |
| [Launch Modes](docs/launch-modes.md) | Regular vs Lite vs Minimal, when to use each |
| [On-Vehicle Operation](docs/on-vehicle-operation.md) | Running on real hardware |
| [Map Creation & Calibration](docs/map-creation.md) | Creating point cloud and Lanelet2 maps |
| [RoboRacer Off-Road Configuration](docs/configuration/roboracer-offroad.md) | RC-specific parameter overrides |
| [Track Tuning Guide](docs/configuration/tuning-guide.md) | Symptom-based tuning reference |

## Supported Platforms

- **Jetson AGX Orin**, target platform
- **x86_64 host (Ubuntu 22.04)**, recommended for development and faster builds

## Quick Start

```bash
# Clone
git clone -b roboracer_humble https://github.com/YonVanom/autoware.av4ev_gokart.git autoware
cd autoware

# Install dependencies
./setup-dev-env.sh            # x86
./setup-dev-env.sh --jetson   # Jetson AGX Orin

# Build workspace
mkdir -p src && vcs import src < repositories/autoware.repos
source /opt/ros/humble/setup.bash
rosdep install -y --from-paths src --ignore-src --rosdistro $ROS_DISTRO
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
```

See [Installation, Jetson AGX Orin](docs/installation/jetson-agx-orin.md) or [Installation, x86 Host](docs/installation/x86-host.md) for full instructions including swap file setup and dependency details.
