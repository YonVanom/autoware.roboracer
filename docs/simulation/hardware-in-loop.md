# Hardware-in-the-Loop Simulation

This guide runs a closed-loop simulation where **Autoware** runs on the **target Jetson AGX Orin** and the **off-road simulator** runs on a separate **x86 host machine**, connected over a network.

**Prerequisites:**
- Autoware built on the Jetson AGX Orin ([Installation, Jetson AGX Orin](../installation/jetson-agx-orin.md))
- Network and DDS settings configured on **both machines** per the [Autoware DDS documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/)

---

## 1. Set Up the Off-Road Simulator on the Host

Follow the [Autoware-RoboRacer Off-Road Simulator](https://github.com/autowarefoundation/autoware_off-road_sim) repository instructions for **Docker Setup** and **Running the Simulation**.

---

## 2. Download the Pumptrack Map on the Jetson

```bash
mkdir -p ~/autoware_map
cd ~/autoware_map
gdown --folder https://drive.google.com/drive/folders/1KIsmlb0mSIftXOjA30qQLbdIt7t2ISJv?usp=sharing
```

---

## 3. Configure the Network

Both machines must be connected via Ethernet (directly or through a local network).

Follow the Autoware documentation for [communication across multiple computers](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/multiple-computers/). Specifically:

- **Manually set the network interface** on both the host and the Jetson.
- Follow the steps for **time synchronization** between machines.

---

## 4. Update the Simulation Config on the Host

Edit the simulator network configuration on the host to point to the correct network interface:

```bash
cd autoware_off-road_sim
nano scripts/configs/pumptrack_autoware_config.yaml
```

In the `network_setup` section, update `network_interface` to the interface via which the Jetson is reachable. This should match the `NetworkInterface` in your `cyclonedds.xml`:

```yaml
network_setup:
  ros2_domain_id: 0
  network_interface: "enp2s0"   # replace with your actual interface name
```

---

## 5. Run the Simulator on the Host

In one terminal window on the **x86 host**:

```bash
cd autoware_off-road_sim
./docker/run.sh
```

Inside the Docker container:

```bash
/root/isaacsim/_build/linux-x86_64/release/python.sh scripts/launch_sim.py \
  --config scripts/configs/pumptrack_autoware_config.yaml
```

---

## 6. Run Autoware on the Jetson

In a terminal window on the **Jetson**:

```bash
cd ~/autoware
source /opt/ros/humble/setup.bash
source install/setup.bash
```

Choose a launch mode based on your use case (see [Launch Modes](../launch-modes.md)):

**Standard launch:**
```bash
ros2 launch offroad_launch e2e_simulator.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_isaac_sensor_kit \
  map_path:=$HOME/autoware_map/pumptrack/
```

**Minimal racing launch (circuit planner, lowest overhead):**
```bash
ros2 launch offroad_launch_minimal e2e_simulator_minimal.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_isaac_sensor_kit \
  map_path:=$HOME/autoware_map/pumptrack/
```

> Update `map_path` if `autoware_map` is not in your home directory.

---

## Next Steps

- [On-Vehicle Operation](../on-vehicle-operation.md), run on real hardware without a simulator
