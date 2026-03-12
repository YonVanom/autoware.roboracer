# Jetson Docker Image

A pre-built Autoware image for the NVIDIA Jetson Orin (and compatible L4T devices).

The image is based on `nvcr.io/nvidia/l4t-jetpack`, which provides CUDA, cuDNN, and
TensorRT for Tegra. Autoware's dependencies (ROS 2, spconv/cumm built from source,
OpenCV pinned to the Autoware-compatible version) are installed on top via
`setup-dev-env.sh --jetson`, then all packages are compiled with `colcon`.

---

## Prerequisites

Everything below runs on the Jetson itself.

1. **Import source repositories** (if not already done):
   ```bash
   mkdir -p src
   vcs import src < repositories/autoware.repos
   ```

2. **Authenticate with GHCR** (needed to push; skip if only building locally):
   ```bash
   echo <YOUR_PAT> | docker login ghcr.io -u <your-github-username> --password-stdin
   ```
   Your PAT needs the `write:packages` scope.

3. **Enable BuildKit** (required for `--mount=type=cache` and `--mount=type=bind`):
   ```bash
   export DOCKER_BUILDKIT=1
   ```
   On Docker 23+ this is the default.

---

## Building

Build time is approximately 3–5 hours on a Jetson Orin Nano.
The ccache mount (`/root/.ccache`) persists across builds, so rebuilds after
source-only changes are significantly faster.

### Option A – docker buildx bake (recommended)

```bash
IMAGE=ghcr.io/<your-org>/autoware:universe-jetson-devel

docker buildx bake \
  -f docker/docker-bake-jetson.hcl \
  --set "*.context=." \
  --set "*.args.ROS_DISTRO=humble" \
  --set "*.args.L4T_VERSION=r36.4.0" \
  --set "jetson-devel.tags=${IMAGE}" \
  --load \
  --progress=plain
```

### Option B – docker build

```bash
IMAGE=ghcr.io/<your-org>/autoware:universe-jetson-devel

docker build \
  -f docker/Dockerfile.jetson \
  --build-arg ROS_DISTRO=humble \
  --build-arg L4T_VERSION=r36.4.0 \
  -t "${IMAGE}" \
  .
```

### Choosing the L4T version

| JetPack | L4T      | Ubuntu  | CUDA |
|---------|----------|---------|------|
| 6.1     | r36.4.0  | 22.04   | 12.2 |
| 6.0     | r36.3.0  | 22.04   | 12.2 |

Check your Jetson's JetPack version with `cat /etc/nv_tegra_release`.
Use the matching `L4T_VERSION` build arg.

---

## Pushing

```bash
IMAGE=ghcr.io/<your-org>/autoware:universe-jetson-devel
docker push "${IMAGE}"
```

To make the package publicly accessible, go to your GitHub package settings and
set the visibility to **Public**.

---

## Running

### Quick shell

```bash
docker run --rm -it --runtime nvidia --ipc host --network host \
  ghcr.io/<your-org>/autoware:universe-jetson-devel
```

### docker compose

```bash
export AUTOWARE_JETSON_IMAGE=ghcr.io/<your-org>/autoware:universe-jetson-devel
export DATA_PATH=$HOME/autoware_data

docker compose -f docker/docker-compose.jetson.yaml run --rm autoware
```

Override the default command to launch a specific component, e.g.:

```bash
docker compose -f docker/docker-compose.jetson.yaml run --rm autoware \
  ros2 launch autoware_launch autoware.launch.xml \
    map_path:=/autoware_data/map \
    vehicle_model:=<your_vehicle> \
    sensor_model:=<your_sensor_kit>
```

### GPU access note

The compose file uses `runtime: nvidia`. This requires the NVIDIA Container Runtime
to be registered with Docker. Verify with:

```bash
docker info | grep -i runtime
```

If `nvidia` is not listed, install the container runtime:

```bash
sudo apt install -y nvidia-container
sudo systemctl restart docker
```

---

## Image details

| Item | Value |
|------|-------|
| Base | `nvcr.io/nvidia/l4t-jetpack:<L4T_VERSION>` |
| ROS 2 | Humble |
| Autoware install | `/opt/autoware` |
| Entrypoint | `/ros_entrypoint.sh` (sources ROS 2 and `/opt/autoware/setup.bash`) |
