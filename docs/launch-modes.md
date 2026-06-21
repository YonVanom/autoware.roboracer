# Launch Modes

The RoboRacer Off-Road stack has three launch modes, each suited to a different use case. Understanding the differences helps you choose the right one and interpret its behavior.

---

## Overview

| | Regular | Lite | Minimal |
|---|---------|------|---------|
| **Package** | `offroad_launch` | `offroad_launch` | `offroad_launch_minimal` |
| **Launch file** | `autoware.launch.xml` | `autoware_lite.launch.xml` | `autoware_minimal.launch.xml` |
| **Planning preset** | `default` | `lite` | `minimal` |
| **Circuit planner** | Optional (`use_circuit_planner:=true`) | Optional (`use_circuit_planner:=true`) | Always on |
| **Dynamic object detection** | Full (ML-based) | None, empty publisher | None, empty publisher |
| **Perception** | Full pipeline | Ground segmentation only | Ground segmentation only |
| **System footprint** | High | Medium | Low |
| **Use case** | Real-world operation with obstacles | Cleared circuit, safety modules active | Racing on a closed circuit |

---

## Regular Launch

**Package:** `offroad_launch`  
**File:** `offroad_launch/launch/autoware.launch.xml`

The full Autoware stack with all modules enabled. Includes ML-based object detection, all planning safety behaviors (obstacle stop, obstacle cruise, out-of-lane, etc.), full system monitoring, and diagnostics.

Use this when:
- Running on real roads or environments where unexpected obstacles are possible
- Validating the full safety-critical stack

The [circuit route planner](circuit-planner.md) can be enabled in this mode to drive continuous laps without setting a goal:

```bash
ros2 launch offroad_launch autoware.launch.xml \
  map_path:=/path/to/map \
  vehicle_model:=roboracer_offroad \
  sensor_model:=<sensor_kit> \
  use_circuit_planner:=true
```

---

## Lite Launch

**Package:** `offroad_launch`  
**File:** `offroad_launch/launch/autoware_lite.launch.xml`

A wrapper around the regular launch that applies lite planning and control presets and disables real-time object detection. The structural difference from regular:

- `planning_module_preset: lite`, simplified planning module set (fewer behavior modules)
- `control_module_preset: lite`
- `use_empty_dynamic_object_publisher: true`, no ML detection; publishes an empty object list instead
- Obstacle segmentation time series filter disabled
- Perception analytics disabled

This gives a significantly lower CPU/GPU load while keeping the rest of the Autoware safety architecture intact.

Use this when:
- Running on a **cleared circuit** where no dynamic obstacles are expected
- CPU/GPU resources are limited and full ML perception is not needed
- You want to use Autoware's safety behaviors (lane keeping, speed limits) without dynamic obstacle avoidance

The [circuit route planner](circuit-planner.md) can be enabled here too:

```bash
ros2 launch offroad_launch autoware_lite.launch.xml \
  map_path:=/path/to/map \
  vehicle_model:=roboracer_offroad \
  sensor_model:=<sensor_kit> \
  use_circuit_planner:=true
```

---

## Minimal Launch

**Package:** `offroad_launch_minimal`  
**File:** `offroad_launch_minimal/launch/autoware_minimal.launch.xml`

A purpose-built racing stack from the `offroad_launch_minimal` package. This is **not** a wrapper around the regular launch, it is constructed directly from individual components, launching only what is required for circuit racing.

Key differences from Lite:

- **[Circuit route planner](circuit-planner.md)** (`roboracer_circuit_route_planner`) replaces the standard mission planner, no goal setting required; the planner drives laps continuously
- **Minimal planning preset** (`module_preset: minimal`), only the modules essential for trajectory following on a closed circuit
- **Dummy occupancy grid**, the time-series obstacle segmentation filter that normally produces `/perception/occupancy_grid_map/map` is not running; a static empty grid is published to unblock the behavior planner
- **No system monitor**, replaced by a minimal diagnostic graph that marks all modes as always available
- **Racing-optimized parameters**, aggressive velocity, acceleration, MPC weights, and curvature limits; see [Track Tuning Guide](configuration/tuning-guide.md)

Use this when:
- Racing on a **closed circuit** (no dynamic obstacles, no route goal needed)
- Minimizing system overhead for maximum control loop performance
- Using the circuit planner for continuous lap racing

```bash
ros2 launch offroad_launch_minimal autoware_minimal.launch.xml \
  map_path:=/path/to/map \
  vehicle_model:=roboracer_offroad \
  sensor_model:=<sensor_kit>
```

---

## Which Should I Use?

```
Is this a closed circuit with no obstacles?
├── No  → Regular launch (full stack)
└── Yes → Do you need dynamic obstacle avoidance?
          ├── Yes → Regular launch
          └── No  → Are you racing (continuous laps, no goal setting)?
                    ├── No  → Lite launch (cleared track, all planning behaviors)
                    └── Yes → Minimal launch (circuit planner, lowest overhead)
```

---

## Simulator Equivalents

Each mode has an end-to-end simulator variant for use with the off-road simulator:

| Mode | Simulator launch file |
|------|-----------------------|
| Regular | `offroad_launch/launch/e2e_simulator.launch.xml` |
| Lite | `offroad_launch/launch/e2e_simulator_lite.launch.xml` |
| Minimal | `offroad_launch_minimal/launch/e2e_simulator_minimal.launch.xml` |

See [Software-in-the-Loop Simulation](simulation/software-in-loop.md) and [Hardware-in-the-Loop Simulation](simulation/hardware-in-loop.md) for setup instructions.
