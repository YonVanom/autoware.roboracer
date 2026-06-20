# Architecture Overview

The RoboRacer Off-Road runs a full Autoware 1.6.0 autonomous driving stack on a 1/10-scale RC vehicle. This page describes how the RoboRacer-specific packages fit into the Autoware framework.

---

## Platform

| Item | Details |
|------|---------|
| Vehicle | RoboRacer Off-Road (1/10 scale RC, wheelbase 0.324 m) |
| Target compute | Jetson AGX Orin (JetPack 6.2.1, Ubuntu 22.04) |
| Development compute | x86_64 host (Ubuntu 22.04) |
| ROS 2 distribution | Humble Hawksbill |
| Autoware version | 1.6.0 |

---

## Custom Packages

The repository adds RoboRacer-specific packages on top of Autoware 1.6.0. All live under `src/launcher/autoware_launch/` unless noted.

### `offroad_launch`
The primary launch package for general operation. Based on `autoware_launch` with parameter overrides tuned for the vehicle's 1/10 scale, terrain, and sensor characteristics.

**Launch files:**

| File | Use case |
|------|----------|
| `autoware.launch.xml` | Full stack for real-world operation |
| `autoware_lite.launch.xml` | Full stack with lite planning preset, no ML object detection |
| `e2e_simulator.launch.xml` | End-to-end simulation with the off-road simulator |
| `e2e_simulator_lite.launch.xml` | Simulation with lite preset |
| `planning_simulator.launch.xml` | Planning-only simulation with logged sensor data |
| `logging_simulator.launch.xml` | Replay recorded bags |

See [Launch Modes](launch-modes.md) for details on Regular vs Lite. See [RoboRacer Off-Road Configuration](configuration/roboracer-offroad.md) for the parameter overrides.

### `offroad_launch_minimal`
A purpose-built racing stack with the minimum set of components needed for closed-circuit autonomous racing. Uses a custom circuit route planner and racing-optimized parameters.

**Launch files:**

| File | Use case |
|------|----------|
| `autoware_minimal.launch.xml` | Minimal racing stack for real hardware |
| `e2e_simulator_minimal.launch.xml` | Minimal racing stack with the off-road simulator |

See [Launch Modes](launch-modes.md) for details on the Minimal stack.

### `roboracer_offroad_launch` (vehicle)
Located at `vehicle/roboracer_offroad_launch/`. Vehicle launch for real hardware. Contains:
- Vehicle URDF description
- `vehicle_interface.launch.xml`, launches `roboracer_interface_node` via the f1tenth stack, bridging Autoware control commands to the physical servo and motor

### `roboracer_offroad_isaac_launch` (vehicle, simulation)
Located at `vehicle/roboracer_offroad_isaac_launch/`. Vehicle launch for Isaac Sim. The `roboracer_isaac_interface_node` bridges Autoware commands to the simulator's `/ego/*` topics.

### `roboracer_offroad_isaac_sensor_kit_launch` (sensor kit, simulation)
Located at `sensor_kit/roboracer_offroad_isaac_sensor_kit_launch/`. Sensor kit for use with the Isaac Sim off-road simulator.

### `roboracer_offroad_sensor_kit_launch` (sensor kit, real hardware)
Located at `sensor_kit/roboracer_offroad_sensor_kit_launch/`. Sensor kit for the physical vehicle.

### `roboracer_circuit_route_planner`
Located at `src/universe/autoware_universe/planning/roboracer_circuit_route_planner/`. Custom route planner for closed-circuit racing. Replaces the standard goal-based mission planner, the vehicle drives laps continuously without requiring a goal to be set.

### `roboracer_sim`
Located at `src/universe/autoware_universe/sensing/roboracer_sim/`. Sensor bridge connecting the Autoware sensing pipeline to the Isaac Sim off-road simulator.

---

## Sensing and Actuation Suite

The RoboRacer Off-Road uses a **ZED stereo camera** as its primary sensor. The ZED provides:
- **RGB images**, used for visual reference and camera-based perception
- **Depth images**, converted to point clouds for NDT-based localization
- **Point cloud**, derived from the depth images
- **IMU**, used for EKF pose estimation
- **Pose and pose with covariance**, used for initial pose estimation in place of GNSS

The vehicle also has a **VESC** (motor controller), which serves two roles:
- **Actuation**, receives throttle and steering commands from the vehicle interface
- **Feedback**, reports vehicle speed and steering angle, which are published as `/vehicle/status/velocity_status` and `/vehicle/status/steering_status`

There is no separate LiDAR and no GNSS. The point clouds fed into NDT scan matching come from the ZED's depth sensor. The ZED's onboard pose estimate is used to initialize localization. This is also why the NDT voxel resolution is tuned finer than Autoware defaults, the depth point clouds are densely clustered at close range.

**Sensor calibration** is defined in the sensor kit description packages:
- Simulation: `roboracer_offroad_isaac_sensor_kit_description/config/sensor_kit_calibration.yaml`
- Real hardware: `roboracer_offroad_sensor_kit_description/config/sensor_kit_calibration.yaml`

---

## Stack Data Flow

```
┌─────────────────────────────────────────────┐
│         Sensors / Simulator                 │
│  ZED camera (depth + IMU), GNSS             │
│  (or Isaac Sim ROS 2 bridge)                │
└───────────────────┬─────────────────────────┘
                    │ raw sensor data
                    ▼
┌─────────────────────────────────────────────┐
│              Sensing                        │
│  ZED drivers, depth→pointcloud,             │
│  pointcloud preprocessing, GNSS, IMU        │
└──────────┬────────────────────────┬─────────┘
           │ /sensing/...           │ /sensing/...
           ▼                        ▼
┌──────────────────────┐  ┌──────────────────────┐
│    Localization      │  │      Perception       │
│  NDT scan matching   │  │  Ground segmentation  │
│  (depth PC ↔ PCD map)│  │  (or empty publisher) │
│  EKF pose estimator  │  └──────────┬───────────┘
│  GNSS initializer    │             │ /perception/...
└──────────┬───────────┘             │
           │ /localization/          │
           │ kinematic_state         │
           └──────────┬─────────────┘
                      ▼
          ┌───────────────────────┐
          │       Planning        │
          │ Route/Circuit planner │
          │ → Behavior →          │
          │   Motion planning     │
          └───────────┬───────────┘
                      │ /planning/trajectory
                      ▼
          ┌───────────────────────┐
          │       Control         │
          │ MPC (lateral)         │
          │ PID (longitudinal)    │
          └───────────┬───────────┘
                      │ /control/command/control_cmd
                      ▼
          ┌───────────────────────┐
          │   Vehicle Interface   │
          │ roboracer_interface / │
          │ roboracer_isaac_iface │
          └───────────┬───────────┘
                      │ servo + motor commands
                      ▼
          ┌───────────────────────┐
          │ RoboRacer Hardware /  │
          │ Isaac Sim             │
          └───────────────────────┘
```

---

## Maps

| File | Format | Required | Purpose |
|------|--------|----------|---------|
| `lanelet2_map.osm` | Lanelet2 (OSM XML) | Always | Road network, lane geometry, speed limits |
| `pointcloud_map.pcd` | Point Cloud (PCD) | Always | 3D environment for NDT scan matching |
| `area_map.area` | ZED area memory | When using ZED for initial pose | Spatial reference used by the ZED SDK for relocalization and initial pose estimation |

See [Map Creation & Calibration](map-creation.md) for how to create these.

---

## Related Pages

- [Launch Modes](launch-modes.md), which launch file to use and when
- [RoboRacer Off-Road Configuration](configuration/roboracer-offroad.md), parameter overrides and rationale
- [Track Tuning Guide](configuration/tuning-guide.md), how to tune speed, path tracking, and braking
