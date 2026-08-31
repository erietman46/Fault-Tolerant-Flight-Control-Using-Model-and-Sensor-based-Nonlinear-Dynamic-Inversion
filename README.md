# Fault-Tolerant Flight Control for the Cessna Citation 500

Fault-tolerant flight control system for a nonlinear Cessna Citation 500 simulation, developed in MATLAB/Simulink. The project investigates whether an Adaptive Nonlinear Dynamic Inversion (ANDI) controller can maintain satisfactory aircraft behaviour following an aileron hard-over failure, and compares its response with a conventional PI controller.

<img width="2283" height="1301" alt="Fig03b_trajectory_3D" src="https://github.com/user-attachments/assets/b3698c01-34d8-48c5-bfa1-5a7509c36b7f" />
<img width="4335" height="3119" alt="Fig06_rate_sideslip_tracking_failed_runs" src="https://github.com/user-attachments/assets/744253b8-a22d-47c2-ac52-6b5ce01d70a0" />

The first figure compares the ground trajectories of the four validation cases. Following the aileron hard-over failure, the aircraft controlled by the classical PI controller departs significantly from its nominal trajectory, while the ANDI-controlled aircraft remains close to the healthy case. The bottom figure compares roll, pitch, and yaw-rate tracking together with sideslip angle for the two failed cases. At \(t=60\) s, the failure causes a strong disturbance in both controllers. The classical controller develops sustained tracking errors and increased sideslip, whereas ANDI recovers rapidly and continues to track the commanded rates with only a short transient. These results demonstrate the improved fault-accommodation capability of the ANDI-based controller.

The complete simulation contains the aircraft dynamics, actuator models, reference commands, flight-control system, failure injection, feedback signals, and fault-related logic. Both nominal and failed configurations can be simulated to evaluate the effect of actuator degradation on the closed-loop aircraft response.

## Project Overview

Modern flight-control systems must remain stable and controllable even when an actuator no longer behaves as commanded. This project considers an aileron hard-over failure, in which one of the ailerons becomes stuck at a fixed deflection.

The main objective is to compare two control architectures:

- Classical PI control
- Adaptive Nonlinear Dynamic Inversion (ANDI)

The ANDI controller uses aircraft feedback and control-effectiveness information to determine the required incremental control action. When the actuator configuration changes because of a failure, the controller can modify the commanded actuator inputs based on the remaining control authority.

The simulations are used to compare:

| Controller | Healthy Aircraft | Aileron Failure |
|---|---:|---:|
| Classical PI | ✓ | ✓ |
| ANDI | ✓ | ✓ |

This allows the nominal controller performance and the fault-tolerant behaviour of ANDI to be evaluated under identical flight conditions.

---

## Control Architecture

The Simulink model represents the complete closed-loop flight-control system:

```text
Reference Commands
        |
        v
Flight Controller
   PI / ANDI
        |
        v
Actuator Dynamics
        |
        v
Cessna Citation 500
Nonlinear Aircraft Model
        |
        v
Measured / Estimated States
        |
        +-----------------------> Feedback
