# RoboRacer Off-Road Configuration

The `offroad_launch` and `offroad_launch_minimal` packages override a set of Autoware default parameters to adapt the stack to the RoboRacer Off-Road: a 1/10-scale RC vehicle operating on uneven, hilly terrain.

Due to the vehicle's small size and sensor placement, the ZED depth sensor has a limited vertical field of view and often captures incomplete ground surface when traversing hill crests, dips, or banked turns. This leads to sparse or incomplete point clouds, which negatively impacts NDT scan matching and downstream modules. In practice this caused unstable localization, frequent false-positive instability detections, and unnecessary emergency braking. The changes below relax strict thresholds and disable modules not well-suited to this scale and terrain.

All config files are relative to `src/launcher/autoware_launch/offroad_launch/config/`.

---

## Localization

### `localization/localization_error_monitor.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `error_ellipse_size_lateral_direction` | 0.3 | **1.0** | Increase tolerance to lateral drift from reduced feature visibility on uneven terrain |
| `warn_ellipse_size_lateral_direction` | 0.25 | **0.7** | Raise warning threshold to match |

### `localization/ndt_scan_matcher/ndt_scan_matcher.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `required_distance` | 10.0 | **1.0** | Allow scan matching with short-range depth data |
| `converged_param_nearest_voxel_transformation_likelihood` | 2.3 | **0.5** | Reduce rejection of imperfect but usable matches |
| `resolution` | 2.0 | **1.0** | Finer NDT voxel size improves matching for the dense, close-range point clouds from the ZED depth sensor |

### `localization/ndt_scan_matcher/pointcloud_preprocessor/voxel_grid_filter.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `voxel_size_x/y/z` | 3.0 | **0.3** | At 3.0 m, ZED depth points collapse to too few voxels for reliable NDT matching; 0.3 m retains enough points |

### `localization/pose_initializer.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `stop_check_enabled` | true | **false** | Allow pose-based initialization from the ZED even if the vehicle is moving slightly (e.g., rolling on a hill) |

### `localization/pose_instability_detector.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `pose_estimator_longitudinal_tolerance` | 0.11 | **0.5** | Accounts for pitch changes on hills, reducing false instability triggers |
| `pose_estimator_angular_tolerance` | 0.0175 | **0.1** | Reduced sensitivity to angular pose variation on slopes |

---

## Perception

### `perception/obstacle_segmentation/ground_segmentation/ground_segmentation.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `global_slope_max_angle_deg` | 10.0 | **20.0** | Improves ground classification on steep slopes and banked terrain |
| `local_slope_max_angle_deg` | 13.0 | **25.0** | Same |

---

## Planning

### `planning/mission_planning/mission_planner/mission_planner.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `reroute_time_threshold` | 10.0 | **1.0** | Enables faster rerouting when localization updates |
| `minimum_reroute_length` | 30.0 | **1.0** | Allows rerouting on short segments appropriate for the scale |

### `planning/preset/default_preset.yaml`

The following planning modules are **disabled**:

| Module | Reason |
|--------|--------|
| Obstacle stop | When driving downhill, the ZED depth sensor frequently interprets the ground ahead as an obstacle, triggering false stops |
| Obstacle slow down | Same |
| Obstacle cruise | Same |
| Dynamic obstacle stop | Same |
| Out-of-lane | Not well-suited to 1/10-scale lane widths |
| Obstacle velocity limiter | False positives on terrain |
| Run-out | Not relevant for off-road |
| Road user stop | Not relevant for closed-circuit operation |

---

## MPC and Control (RC-Car Baseline)

These parameters scale the Autoware defaults from full-size vehicles to the RoboRacer's dimensions (wheelbase 0.324 m, max steering angle 0.4 rad).

### `control/trajectory_follower/lateral/mpc.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `input_delay` | 0.24 s | **0.08 s** | Measured servo command-to-response delay |
| `vehicle_model_steer_tau` | 0.27 s | **0.12 s** | Measured servo first-order time constant |
| `steering_lpf_cutoff_hz` | 3.0 Hz | **10.0 Hz** | 3 Hz attenuated legitimate fast steering commands from the RC servo |
| `curvature_smoothing_num_traj` | 15 | **3** | 15 × 0.1 m = 1.5 m window over-smoothed corners; 3 × 0.1 m ≈ 1× wheelbase |
| `curvature_smoothing_num_ref_steer` | 15 | **3** | Same |
| `mpc_weight_lat_error` | 1.0 | **5.0** | Tighter lateral tracking for a small vehicle with limited inertia |
| `mpc_weight_steering_input` | 1.0 | **0.2** | Lower penalty gives the RC servo access to more of its range |
| `mpc_min_prediction_length` | 5.0 m | **1.5 m** | Proportional to the RC wheelbase |
| `mpc_prediction_horizon` | 50 | **20** | At RC speeds, 50 steps looks too far ahead; 20 steps ≈ 2 s provides adequate look-ahead |

---

## Velocity Smoother (RC-Car Baseline)

### `planning/scenario_planning/common/autoware_velocity_smoother/velocity_smoother.param.yaml`

| Parameter | Default | Off-Road | Reason |
|-----------|---------|----------|--------|
| `lateral_acceleration_limits` | [1.0, 1.0, 1.0, 1.0] m/s² | **[3.5, 3.5, 3.5, 3.5]** | RC car at scale can sustain ~3.5 m/s² lateral acceleration; default was too conservative |
| `decel_distance_before_curve` | 3.5 m | **1.5 m** | Proportional to wheelbase (~4.6× vs. ~10× for a full-size vehicle) |
| `decel_distance_after_curve` | 2.0 m | **1.0 m** | Same scaling rationale |
| `velocity_thresholds` | [0.1, 0.3, 20.0, 30.0] m/s | **[0.5, 1.0, 3.0, 5.0]** | Rescaled to the RC car's operating speed range |
| `steering_angle_rate_limits` | [11.5, 11.5, 10.5, 3.5] °/s | **[80.0, 70.0, 55.0, 40.0]** | RC servo is ~6–8× faster than the hydraulic system the defaults model |

---

## Trade-offs

These changes improve robustness and drivability on uneven terrain by increasing tolerance to noisy or incomplete point cloud data. However, they also:

- Disable several obstacle handling behaviors
- Reduce the conservatism of safety checks

This configuration is **not suitable for full-scale or safety-critical deployments** without further validation and re-enabling of the disabled modules.

---

## See Also

- [Track Tuning Guide](tuning-guide.md), symptom-based guide for speed and path tracking tuning
- [Launch Modes](../launch-modes.md), which launch file to use
- [Architecture Overview](../architecture.md), how `offroad_launch` fits into the Autoware stack
