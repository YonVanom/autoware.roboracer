# On-Vehicle Operation

This guide covers running Autoware on the **physical RoboRacer Off-Road** hardware (not in simulation).

**Prerequisites:**
- Autoware built on the Jetson AGX Orin ([Installation, Jetson AGX Orin](installation/jetson-agx-orin.md))
- A Lanelet2 map and point cloud map for your environment ([Map Creation & Calibration](map-creation.md))
- Network and DDS settings configured ([Autoware DDS documentation](https://autowarefoundation.github.io/autoware-documentation/main/installation/additional-settings-for-developers/network-configuration/dds-settings/))

---

## 1. Physical Setup

Before powering on:

1. **Power**, ensure the Jetson and vehicle electronics are properly powered.
2. **Sensor connections**, verify the ZED camera is connected and recognized by the OS.
3. **Vehicle interface**, confirm the USB connection to the vehicle's motor/servo controller is present. The `roboracer_interface_node` uses the f1tenth stack to communicate with the hardware.
4. **Network**, if using a separate visualization machine, ensure both are on the same network and DDS is configured for multi-machine communication (see [Hardware-in-the-Loop Simulation, step 3](simulation/hardware-in-loop.md#3-configure-the-network) for the network setup procedure).

---

## 2. Source the Workspace

On the **Jetson**:

```bash
source /opt/ros/humble/setup.bash
source ~/autoware/install/setup.bash
```

---

## 3. Manual Control

To drive the vehicle manually without launching Autoware, use the f1tenth stack's `no_lidar_bringup`:

```bash
ros2 launch f1tenth_stack no_lidar_bringup.launch.py
```

This brings up the vehicle interface and joystick teleop without any perception, planning, or localization. Use this for map recording (see [Map Creation](map-creation.md)) or hardware verification.

**Dead-man switch**

Manual control requires holding the dead-man button on the controller. The button mapping is configured in `joy_teleop.yaml`:

| Button | Function |
|--------|----------|
| Button 7 (RB) | Enable manual driving; releasing stops the vehicle |
| Button 6 (LB) | Enable autonomous control mode |

Speed and steering are mapped to the left and right sticks respectively.

---

## 4. Launch Autoware

Choose a launch mode based on your use case. See [Launch Modes](launch-modes.md) for a full comparison.

**Full stack (real-world operation with obstacle avoidance):**
```bash
ros2 launch offroad_launch autoware.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_sensor_kit \
  map_path:=/path/to/your/map/ \
  launch_vehicle_interface:=true
```

**Lite stack (cleared circuit, no obstacle detection):**
```bash
ros2 launch offroad_launch autoware_lite.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_sensor_kit \
  map_path:=/path/to/your/map/ \
  launch_vehicle_interface:=true
```

**Minimal racing stack (closed circuit, circuit planner, lowest overhead):**
```bash
ros2 launch offroad_launch_minimal autoware_minimal.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_sensor_kit \
  map_path:=/path/to/your/map/ \
  launch_vehicle_interface:=true
```

---

## 5. Initialize Localization

Autoware must know the vehicle's initial position before it can plan or drive.

**ZED pose-based initialization (recommended)**

The `pose_initializer` node uses the ZED's onboard pose estimate (`pose_with_covariance`) to initialize localization automatically. The RoboRacer Off-Road configuration sets `stop_check_enabled: false`, which allows initialization while the vehicle is on a slope or moving slightly.

**Manual initialization (RViz)**

Use the **2D Pose Estimate** tool in RViz to click the vehicle's approximate position and heading on the map.

---

## 6. Set a Goal and Engage

**Standard and Lite launch**

1. In RViz, use the **2D Goal Pose** tool to set a destination on the map.
2. Autoware will plan a route and display it in RViz.
3. Once the route is shown and localization is stable, press the **Auto** button in RViz (or use the AD API).

**Minimal launch with circuit planner**

The circuit route planner does not require a goal, it drives laps continuously around the map. Once localization initializes, press **Auto**.

---

## 7. Monitoring

Key topics to monitor during operation:

| Topic | Meaning |
|-------|---------|
| `/localization/kinematic_state` | Current estimated pose and velocity |
| `/planning/trajectory` | Planned trajectory being executed |
| `/control/command/control_cmd` | Steering and velocity commands sent to vehicle |
| `/vehicle/status/velocity_status` | Reported vehicle speed |
| `/vehicle/status/steering_status` | Reported steering angle |
| `/diagnostics_agg` | System health diagnostics |

RViz is launched automatically. Use it to monitor localization quality, the planned trajectory, and (in the full stack) perceived obstacles.

---

## 8. Emergency Stop

- **Software E-stop:** press the **Emergency Stop** button in RViz, or publish to `/system/emergency/control_cmd`.

---

## Troubleshooting

**Localization fails to initialize**
- Check that the ZED camera is publishing pose data (`ros2 topic echo /sensing/camera/...`).
- Verify the point cloud map is loaded and covers the vehicle's starting area.
- Try using the **2D Pose Estimate** tool in RViz to give an initial hint.

**Vehicle does not move after engage**
- Confirm the vehicle interface node is running (`ros2 node list | grep roboracer`).
- Check for active emergency stop conditions in `/diagnostics_agg`.
- Verify a trajectory is being published (`ros2 topic echo /planning/trajectory --once`).

**Localization drifts on hills**
- The off-road configuration relaxes localization thresholds for uneven terrain. See [RoboRacer Off-Road Configuration](configuration/roboracer-offroad.md) for which parameters to adjust.

**NDT scan matching fails or diverges**
- The ZED depth point clouds are dense and short-range. Ensure the NDT voxel resolution (`resolution` in `ndt_scan_matcher.param.yaml`) is tuned appropriately, see [RoboRacer Off-Road Configuration](configuration/roboracer-offroad.md).
