# Autoware on RoboRacer, Wiki

This wiki covers installing, running, and tuning Autoware on the RoboRacer Off-Road platform (based on Autoware release 1.6.0).

---

## Getting Started

| Topic | Description |
|-------|-------------|
| [Installation, Jetson AGX Orin](installation/jetson-agx-orin.md) | Set up Autoware on the target platform |
| [Installation, x86 Host](installation/x86-host.md) | Set up Autoware on a development machine |
| [Manual Jetson Setup](installation/manual-setup.md) | Step-by-step without the automated script |

---

## Simulation

| Topic | Description |
|-------|-------------|
| [Software-in-the-Loop](simulation/software-in-loop.md) | Autoware + off-road simulator on one x86 machine |
| [Hardware-in-the-Loop](simulation/hardware-in-loop.md) | Autoware on Jetson, simulator on x86 over a network |

---

## Architecture & Operation

| Topic | Description |
|-------|-------------|
| [Architecture Overview](architecture.md) | How RoboRacer packages fit into Autoware |
| [Launch Modes](launch-modes.md) | Regular vs Lite (offroad_launch) vs Minimal (offroad_launch_minimal) |
| [Circuit Route Planner](circuit-planner.md) | Continuous lap driving without goal setting, parameters and tuning |
| [On-Vehicle Operation](on-vehicle-operation.md) | Running on real hardware (not simulation) |
| [Map Creation & Calibration](map-creation.md) | Creating point cloud and Lanelet2 maps |

---

## Configuration & Tuning

| Topic | Description |
|-------|-------------|
| [RoboRacer Off-Road Configuration](configuration/roboracer-offroad.md) | RC-specific parameter overrides and their reasoning |
| [Track Tuning Guide](configuration/tuning-guide.md) | Symptom-based guide: "the car does X, change Y" |
