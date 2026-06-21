# Track Tuning Guide

This guide answers the question: *"the car is doing X, which parameter do I change?"*

Parameters are grouped by the symptom you observe, not by the file they live in. All files are under `config/` relative to the launch package (e.g., `offroad_launch_minimal/config/`). Config files are symlinked, so changes take effect at the next planning cycle without a rebuild or restart, unless noted otherwise.

For detailed tables of parameter values and derivations across all launch modes, see the `TUNING_NOTES.md` files:
- `src/launcher/autoware_launch/offroad_launch_minimal/TUNING_NOTES.md`, minimal stack
- `src/launcher/autoware_launch/offroad_launch/TUNING_NOTES.md`, regular/lite stack

---

## Quick Reference

| Symptom | Primary parameter | File |
|---------|------------------|------|
| Too slow on straights | `max_vel` | `planning/…/common/common.param.yaml` |
| Too fast / too slow in corners | `lateral_acceleration_limits` | `planning/…/autoware_velocity_smoother/velocity_smoother.param.yaml` |
| Brakes too early before corners | `decel_distance_before_curve` | same |
| Brakes too late before corners | `decel_distance_before_curve` | same |
| Accelerates too slowly out of corners | `normal.max_acc`, `decel_distance_after_curve` | `common.param.yaml`, velocity_smoother |
| Drifts wide on corner exit | `mpc_weight_lat_error` | `control/trajectory_follower/lateral/mpc.param.yaml` |
| Oscillates / weaves on straights | `mpc_prediction_horizon`, `mpc_weight_steering_input` | `mpc.param.yaml` |
| Velocity lags, car runs slower than planned | `kp` | `control/trajectory_follower/longitudinal/pid.param.yaml` |
| Overshoots stop points | `smooth_stop_strong_stop_acc` | `pid.param.yaml` |
| Cuts corners (inside of lane) | `mpt.clearance.soft_clearance_from_road` | `planning/…/autoware_path_optimizer/path_optimizer.param.yaml` |
| Path is choppy through corners | `lateral_acceleration_limits` (too high) OR `delta_arc_length` (too coarse) | velocity_smoother OR path_optimizer |

---

## 1. Speed on Straights

The velocity smoother caps all planned speeds at `max_vel`. The car will never plan faster than this regardless of map speed limits.

**File:** `config/planning/scenario_planning/common/common.param.yaml`

```yaml
max_vel: 8.0    # raise to go faster on straights, lower to slow everything down
```

**Also check:** the lanelet2 map speed limits. If the map's `speed_limit` tag is below your `max_vel`, the map wins. Set the map limit to a ceiling value (e.g., 50 km/h) and let config be the real constraint, see [Map Creation & Calibration](../map-creation.md#speed-limits).

**Acceleration on straights:**
```yaml
normal.max_acc: 3.0    # m/s², raise for faster acceleration out of corners
normal.max_jerk: 5.0   # m/s³, raise to allow sharper throttle onset
```

---

## 2. Corner Speed

Corner speed is determined by: `v_corner = sqrt(lateral_acceleration_limit × R)`, where R is the corner radius in metres. This is the single most important parameter for circuit pace.

**File:** `config/planning/scenario_planning/common/autoware_velocity_smoother/velocity_smoother.param.yaml`

```yaml
lateral_acceleration_limits: [1.5, 1.5, 1.5, 1.5]
```

### Targeting a specific corner speed

| Target speed | Radius 1 m | Radius 1.5 m | Radius 2 m | Radius 3 m |
|-------------|-----------|-------------|-----------|-----------|
| 5 km/h (1.4 m/s) | 1.9 m/s² | 1.3 m/s² | 1.0 m/s² | 0.6 m/s² |
| 6 km/h (1.7 m/s) | 2.8 m/s² | 1.9 m/s² | 1.4 m/s² | 0.9 m/s² |
| 8 km/h (2.2 m/s) | 4.9 m/s² | 3.3 m/s² | 2.4 m/s² | 1.6 m/s² |
| 10 km/h (2.8 m/s) | 7.6 m/s² | 5.1 m/s² | 3.8 m/s² | 2.6 m/s² |
| 15 km/h (4.2 m/s) |, |, | 8.6 m/s² | 5.7 m/s² |

*Estimate your tightest corner radius from the map, pick your target speed, read off the required limit.*

**If the car slides in corners:** reduce `lateral_acceleration_limits` in 0.5 m/s² steps until the car holds its line.

**Minimum corner speed floor** (prevents the planner going below this even in hairpins):
```yaml
min_curve_velocity: 1.0    # m/s
```

---

## 3. Braking Point (Corner Entry)

**File:** `config/planning/scenario_planning/common/autoware_velocity_smoother/velocity_smoother.param.yaml`

```yaml
decel_distance_before_curve: 0.8   # metres before corner entry; shorter = later braking
decel_distance_after_curve:  0.4   # metres past the apex before acceleration is allowed
```

**Maximum braking deceleration** when slowing for a corner:
```yaml
min_decel_for_lateral_acc_lim_filter: -4.0   # m/s², more negative = harder braking
```

**If the car brakes too early:** reduce `decel_distance_before_curve` in 0.2 m steps.

**If the car is still going too fast at corner entry** despite early braking: the lateral acceleration limit is too high, reduce it rather than adjusting braking distance.

**If the car brakes harshly (jerky deceleration):** make `min_decel_for_lateral_acc_lim_filter` less negative (e.g., -2.5) for a gentler transition.

---

## 4. Acceleration Out of Corners

**File:** `config/planning/scenario_planning/common/common.param.yaml`
```yaml
normal.max_acc: 3.0    # m/s², acceleration budget the velocity smoother plans with
normal.max_jerk: 5.0   # m/s³, how sharply acceleration can ramp up
```

**File:** `config/planning/scenario_planning/common/autoware_velocity_smoother/velocity_smoother.param.yaml`
```yaml
decel_distance_after_curve: 0.4   # shorter = acceleration begins sooner after apex
```

**File:** `config/control/trajectory_follower/longitudinal/pid.param.yaml`
```yaml
kp: 1.5      # raise if the car is slow to reach planned velocity
max_acc: 5.0 # controller ceiling; keep at or above normal.max_acc
```

---

## 5. Path Tracking, Lateral (Steering)

The MPC trades off lateral tracking accuracy against steering smoothness.

**File:** `config/control/trajectory_follower/lateral/mpc.param.yaml`

### Drifting wide on corner exit or entry
```yaml
mpc_weight_lat_error: 10.0          # raise to snap the car back to the line faster
mpc_weight_terminal_lat_error: 10.0 # same effect at the far end of the horizon
```

### Oscillating / weaving on straights
```yaml
mpc_prediction_horizon: 30        # reduce to 20 on tight circuits
mpc_weight_steering_input: 0.1    # raise to penalise large steering commands
mpc_weight_lat_jerk: 0.005        # raise to smooth rapid steering reversals
```

### Car understeers (turns too little, goes wide)
```yaml
mpc_weight_heading_error: 0.5     # raise to penalise heading deviation
```

### Steering feels sluggish
```yaml
mpc_weight_steering_input: 0.1    # reduce to allow larger steering commands
mpc_weight_steering_input_squared_vel: 0.02
```

### Look-ahead distance

The MPC look-ahead window is `horizon × dt` seconds:

| Horizon | Look-ahead at 5 m/s | Look-ahead at 8 m/s |
|---------|--------------------|--------------------|
| 20 steps (2 s) | 10 m | 16 m |
| 30 steps (3 s) | 15 m | 24 m |
| 50 steps (5 s) | 25 m | 40 m |

For a compact indoor circuit, 20–30 steps is usually right. Longer horizons improve anticipatory braking on wide circuits but can cause oscillation on tight ones.

---

## 6. Path Tracking, Longitudinal (Speed)

**File:** `config/control/trajectory_follower/longitudinal/pid.param.yaml`

### Car consistently runs slower than planned
```yaml
kp: 1.5    # raise (try 2.0); too high causes velocity hunting, back off 0.25 if this occurs
ki: 0.2    # raise slightly for a persistent steady-state offset
```

### Car overshoots stop points
```yaml
smooth_stop_strong_stop_acc: -5.0   # more negative = harder emergency hold; try -3.4 for gentler stop
```

### Braking is too abrupt when decelerating to a waypoint
```yaml
max_jerk: 8.0    # reduce to 3.0–5.0 for softer deceleration onset
min_jerk: -8.0   # reduce magnitude for a smoother brake ramp
```

---

## 7. Path Shape, Corner Geometry

**File:** `config/planning/scenario_planning/lane_driving/motion_planning/autoware_path_optimizer/path_optimizer.param.yaml`

### Car cuts corners (clips inside of curve)
```yaml
mpt.clearance.soft_clearance_from_road: 0.2   # raise (e.g. 0.3) to push path away from edges
```

### Trajectory looks jagged or choppy
```yaml
mpt.common.delta_arc_length: 0.2          # reduce (try 0.1); note: slower solve time
common.output_delta_arc_length: 0.1       # output resolution; keep at 0.1 m
```

**File:** `config/planning/scenario_planning/lane_driving/behavior_planning/behavior_path_planner/behavior_path_planner.param.yaml`

```yaml
input_path_interval: 0.5     # do not go below 0.5 m (triggers null-pointer crash in goal planner)
output_path_interval: 0.5    # same
```

---

## 8. Track-Type Presets

### Tight technical circuit (hairpins, narrow corridors)
```yaml
# velocity_smoother.param.yaml
lateral_acceleration_limits: [1.0, 1.0, 1.0, 1.0]
decel_distance_before_curve: 0.5
min_curve_velocity: 1.0

# common.param.yaml
max_vel: 5.0
normal.max_acc: 2.0

# mpc.param.yaml
mpc_prediction_horizon: 20
mpc_weight_lat_error: 12.0
```

### Wide fast circuit (sweeping corners, long straights)
```yaml
# velocity_smoother.param.yaml
lateral_acceleration_limits: [4.0, 4.0, 4.0, 4.0]
decel_distance_before_curve: 1.5
min_curve_velocity: 1.5

# common.param.yaml
max_vel: 8.0
normal.max_acc: 3.0

# mpc.param.yaml
mpc_prediction_horizon: 40
mpc_weight_lat_error: 8.0
```

### Mixed (tight infield, fast back straight)
Start from the tight preset and increase only `max_vel` and `normal.max_acc`. The lateral acceleration limit naturally allows faster speeds on straighter sections because the curvature filter is inactive where curvature is below `curvature_threshold: 0.02 /m`.

---

## 9. Stability Budget

The controller-side hard limits must always be **at or above** the planning-side limits.

**File:** `config/control/trajectory_follower/longitudinal/pid.param.yaml`

| Controller limit | Should match or exceed |
|-----------------|----------------------|
| `max_acc: 5.0` | `common.param.yaml → limit.max_acc` |
| `min_acc: -6.0` | `common.param.yaml → limit.min_acc` |
| `max_jerk: 8.0` | `common.param.yaml → limit.max_jerk` |
| `min_jerk: -8.0` | `common.param.yaml → limit.min_jerk` |

**File:** `config/control/trajectory_follower/lateral/mpc.param.yaml`

| Controller limit | Should match |
|-----------------|-------------|
| `mpc_acceleration_limit: 4.0` | `common.param.yaml → normal.max_acc` |

---

## 10. Tuning Workflow

1. **Set the map speed limit** above your target max speed (use 50 km/h). Let config be the constraint.
2. **Set `lateral_acceleration_limits`** using the table in section 2 to target your desired corner speed.
3. **Set `max_vel`** to your target straight-line speed.
4. **Run a lap.** Identify the primary problem.
5. **Use sections 3–7** to address each symptom one parameter at a time.
6. **Iterate.** The lateral acceleration limit is the dominant variable, get that right before tuning MPC weights.

> MPC and velocity smoother parameters reload at runtime (symlinked config). `common.param.yaml` requires restarting the stack.
