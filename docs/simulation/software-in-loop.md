# Software-in-the-Loop Simulation

This guide runs a closed-loop simulation where both **Autoware** and the **off-road simulator** run on the same **x86 host machine**.

**Prerequisites:**
- Autoware built and sourced on the x86 host ([Installation, x86 Host](../installation/x86-host.md))
- Network and DDS settings configured per the [Autoware DDS documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/)

---

## 1. Set Up the Off-Road Simulator

Follow the [Autoware-RoboRacer Off-Road Simulator](https://github.com/autowarefoundation/autoware_off-road_sim) repository instructions for **Docker Setup** and **Running the Simulation**.

---

## 2. Download the Pumptrack Map

This Autoware map matches the default map in the off-road simulator.

```bash
cd ~/autoware_map
gdown --folder https://drive.google.com/drive/folders/1KIsmlb0mSIftXOjA30qQLbdIt7t2ISJv?usp=sharing
```

---

## 3. Run the Simulator

In one terminal window, run the simulator via Docker:

```bash
cd autoware_off-road_sim
./docker/run.sh
```

Inside the Docker container, launch using the Autoware-specific config:

```bash
/root/isaacsim/_build/linux-x86_64/release/python.sh scripts/launch_sim.py \
  --config scripts/configs/pumptrack_autoware_config.yaml
```

This config uses the loopback network device `lo` (as per Autoware DDS documentation) and disables frame ID remapping.

---

## 4. Run Autoware

In a second terminal window:

```bash
cd ~/autoware
source /opt/ros/humble/setup.bash
source install/setup.bash
```

Choose a launch mode based on your use case (see [Launch Modes](../launch-modes.md)):

**Standard launch:**
```bash
ros2 launch offroad_launch e2e_simulator.launch.xml \
  vehicle_model:=roboracer_offroad_isaac \
  sensor_model:=roboracer_offroad_isaac_sensor_kit \
  map_path:=$HOME/autoware_map/pumptrack/ \
  launch_vehicle_interface:=true
```

**Minimal racing launch (circuit planner, lowest overhead):**
```bash
ros2 launch offroad_launch_minimal e2e_simulator_minimal.launch.xml \
  vehicle_model:=roboracer_offroad_isaac \
  sensor_model:=roboracer_offroad_isaac_sensor_kit \
  map_path:=$HOME/autoware_map/pumptrack/ \
  launch_vehicle_interface:=true
```

> Update `map_path` if `autoware_map` is not in your home directory.

---

## Next Steps

- [Hardware-in-the-Loop Simulation](hardware-in-loop.md), run the simulator on x86, Autoware on Jetson
- [On-Vehicle Operation](../on-vehicle-operation.md), run on real hardware without a simulator
