# Circuit Route Planner

The `roboracer_circuit_route_planner` replaces Autoware's standard goal-based mission planner with a sliding-window route that continuously follows a closed circuit. No goal needs to be set: once localization initializes and Autoware is engaged, the planner drives laps indefinitely.

---

## How It Works

The planner runs on a 200 ms timer. On each tick it:

1. Finds the lanelet closest to the current vehicle pose.
2. If the vehicle has entered a new lanelet since the last tick, rebuilds and publishes a route.
3. The route is a sliding window consisting of:
   - `backward_lanelets_num` lanelets behind the vehicle, for overlap continuity
   - all lanelets ahead up to `lookahead_distance_m` meters

The goal pose is set to the end of the last forward lanelet. When the window advances past the end of the map it wraps around the circuit loop automatically.

The route UUID is kept constant for the lifetime of the node. This prevents the behavior path planner from treating each window update as a new route and triggering a full reset.

**Topics:**

| Topic | Direction | Description |
|-------|-----------|-------------|
| `/map/vector_map` | input | Lanelet2 map (transient local) |
| `/localization/kinematic_state` | input | Current pose and velocity from EKF |
| `/planning/mission_planning/route` | output | Sliding window route (transient local) |
| `/planning/route_state` | output | Route state, always SET while running |

---

## Enabling the Circuit Planner

The circuit planner is available in all three launch modes. It is **off by default** in the regular and lite stacks, and **on by default** in the minimal stack.

### Regular launch

```bash
ros2 launch offroad_launch autoware.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_sensor_kit \
  map_path:=/path/to/map/ \
  use_circuit_planner:=true
```

### Lite launch

```bash
ros2 launch offroad_launch autoware_lite.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_sensor_kit \
  map_path:=/path/to/map/ \
  use_circuit_planner:=true
```

### Minimal launch

The minimal stack always uses the circuit planner. The `use_circuit_planner` argument is not exposed there.

### Simulator variants

The same flag applies to the end-to-end simulator launch files:

```bash
ros2 launch offroad_launch e2e_simulator.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_isaac_sensor_kit \
  map_path:=/path/to/map/ \
  use_circuit_planner:=true
```

```bash
ros2 launch offroad_launch e2e_simulator_lite.launch.xml \
  vehicle_model:=roboracer_offroad \
  sensor_model:=roboracer_offroad_isaac_sensor_kit \
  map_path:=/path/to/map/ \
  use_circuit_planner:=true
```

---

## Parameters

Config file: `src/universe/autoware_universe/planning/roboracer_circuit_route_planner/config/circuit_route_planner.param.yaml`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lookahead_distance_m` | double | `30.0` | How far ahead (in metres) to extend the route window. Must be shorter than the circuit length to prevent the window from wrapping all the way around, which would cause a premature stop. |
| `backward_lanelets_num` | int | `2` | Number of lanelets behind the vehicle to include in the route. These provide a backward overlap so the behavior path planner always has the current lanelet within the published route. Without this, the planner loses its reference lanelet each time the window shifts forward. |

---

## Tuning

**`lookahead_distance_m`**

This is the most important parameter. Set it to roughly half the circuit length as a starting point.

- Too short: the behavior planner may not have enough path to generate smooth trajectories, especially before corners.
- Too long (longer than the circuit): the window wraps all the way around the loop, placing the goal behind the vehicle, which causes the planner to stop or behave erratically.

**`backward_lanelets_num`**

The default of 2 works for most maps. Increase it if you see `lanelet_sequence is empty` warnings in the behavior path planner log, which indicates the window has shifted forward past the planner's current reference lanelet.

---

## Map Requirements

The circuit planner relies entirely on the Lanelet2 map's connectivity graph. For it to work correctly:

- All lanelets must be connected in a closed loop, i.e., following `next` references from any lanelet should eventually return to the starting lanelet.
- There must be no dead-end lanelets on the circuit path.
- The planner always takes the first `next` lanelet at each junction. For circuits with branching paths, ensure the preferred path is the first successor in the map.

---

## Differences from the Standard Mission Planner

| | Standard mission planner | Circuit route planner |
|---|---|---|
| Goal required | Yes, set via RViz or AD API | No |
| Route | Full path from start to goal | Sliding window, replanned each lanelet |
| Multi-lap | Requires new goal each lap | Continuous |
| Junction behavior | Uses full route graph search | Always takes first successor |
| Use case | Point-to-point navigation | Closed-circuit racing |
