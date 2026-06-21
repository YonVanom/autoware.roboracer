# Map Creation & Calibration

Autoware requires the following map files for each environment:

| File | Format | Required | Purpose |
|------|--------|----------|---------|
| `pointcloud_map.pcd` | PCD (Point Cloud Data) | Always | 3D reference for NDT scan matching (localization) |
| `lanelet2_map.osm` | Lanelet2 (OSM XML) | Always | Road network, lane geometry, speed limits, stop lines, and other semantic annotations |
| `*.area` | ZED area memory | When using ZED for initial pose | Spatial reference used by the ZED SDK to recognize the environment and estimate the initial pose |

All files must be placed in the same directory and that directory passed as `map_path:=` when launching Autoware.

---

## Example Map (Pumptrack)

A ready-to-use example map for the pumptrack environment is available:

```bash
mkdir -p ~/autoware_map
cd ~/autoware_map
gdown --folder https://drive.google.com/drive/folders/1KIsmlb0mSIftXOjA30qQLbdIt7t2ISJv?usp=sharing
```

This map matches the default environment in the [off-road simulator](https://github.com/autowarefoundation/autoware_off-road_sim). Use it to test the system before creating your own maps.

---

## Creating a Point Cloud Map and Area File

The point cloud map (`.pcd`) and ZED area memory file (`.area`) are created simultaneously on the vehicle using `zed_slam.py`. The ZED SDK runs SLAM internally, building a fused point cloud while saving a spatial memory file that it uses for relocalization on subsequent runs.

### Prerequisites

Before launching `zed_slam`, set the output path in `localize.yaml`:

```yaml
area_file: "/path/to/your/map/your_map.area"
```

The `.ply` point cloud is saved to the same base path (e.g., `your_map.ply`).

Start the vehicle in **manual operation mode** using the f1tenth stack's `no_lidar_bringup`. This lets you drive the map recording pass without launching Autoware.

```bash
ros2 launch f1tenth_stack no_lidar_bringup.launch.py
```

### Recording process

1. Launch `zed_slam` in mapping mode with point cloud saving enabled:
   ```bash
   ros2 launch zed_slam zed_slam.launch.py mode:=mapping save_pointcloud:=true
   ```

   Key parameters:
   | Parameter | Value | Description |
   |-----------|-------|-------------|
   | `mode` | `mapping` | Builds a new map from scratch |
   | `save_pointcloud` | `true` | Saves the fused point cloud as a `.ply` alongside the `.area` file |
   | `area_file` | set in `localize.yaml` | Output path for the `.area` file |

2. Drive around the full circuit at a slow, steady speed until the `LOOP_CLOSED` message appears in the terminal. This confirms the ZED SDK has detected a loop closure and the map is spatially consistent.

3. Save the map via the service call:
   ```bash
   ros2 service call /zed/save_map std_srvs/srv/Trigger
   ```
   This saves both the `.area` file and the `.ply` point cloud to the paths configured by `area_file`.

### Converting the point cloud

The ZED SDK saves a `.ply` file. Convert it to `.pcd` for Autoware:

```bash
pcl_convert -f ascii your_map.ply pointcloud_map.pcd
```

Place `pointcloud_map.pcd` in your map directory. The area file must be named `area_map.area` in that same directory:

```bash
cp your_map.area /path/to/map/area_map.area
```

### NDT parameters for the RoboRacer Off-Road

The RoboRacer Off-Road runs with a finer NDT voxel resolution than Autoware defaults because the ZED depth sensor produces dense, short-range point clouds. At the default 3.0 m voxel size, most points collapse into too few voxels for reliable scan matching. See [RoboRacer Off-Road Configuration](configuration/roboracer-offroad.md) for the specific parameter values.

---

## Creating a Lanelet2 Map

A Lanelet2 map defines the road network as a directed graph of lanelets. Each lanelet has a left boundary, right boundary, and optionally speed limits, turn directions, and regulatory elements (stop lines, traffic lights).

### Tools

- **[VectorMapBuilder](https://tools.tier4.jp/feature/vector_map_builder_ll2/)** (web-based, by Tier IV), recommended for creating Lanelet2 maps from point cloud maps
- **[JOSM](https://josm.openstreetmap.de/)** with the Lanelet2 plugin, for manual editing

### General process

1. Load your `pointcloud_map.pcd` into VectorMapBuilder as the reference.
2. Trace the lane boundaries over the point cloud.
3. Add regulatory elements as needed (stop lines, speed limits).
4. Export as `lanelet2_map.osm`.

### Circuit maps: use multiple lanelets

For closed circuits, split the track into multiple lanelets rather than drawing one large lanelet for the entire loop. A good split follows natural track features: one lanelet per straight, one per turn, etc.

This is necessary for the circuit route planner to work correctly. The planner tracks progress by detecting when the vehicle enters a new lanelet and uses this to advance the route window. With a single lanelet covering the whole circuit, the planner only triggers once per lap and the route window cannot advance, causing the behavior planner to run out of path.

Finer splits also give the behavior planner more reference points for trajectory generation, which improves path smoothness through corners.

### Speed limits

Speed limits in the Lanelet2 map are set via the `speed_limit` tag on each lanelet (in km/h). Autoware will not exceed the map's speed limit even if the configured `max_vel` is higher.

**Recommended practice:** set all lanelets in the map to a ceiling value (e.g., 50 km/h) and let the Autoware configuration be the real constraint. This avoids needing to update the map when tuning speed parameters.

To edit speed limits after the fact, open the `.osm` file in a text editor and modify the `speed_limit` attribute:
```xml
<tag k="speed_limit" v="50"/>
```

---

## Verifying a Map

Before running autonomously, verify the map works correctly:

1. Launch the `planning_simulator.launch.xml` or `e2e_simulator` with the new map.
2. Set an initial pose using the RViz **2D Pose Estimate** tool.
3. Confirm the point cloud map loads and the vehicle's position aligns with the surrounding map.
4. Set a goal and confirm Autoware plans a route through the lanelet graph.
5. Check that speed limits and stop lines in the map behave as expected.
