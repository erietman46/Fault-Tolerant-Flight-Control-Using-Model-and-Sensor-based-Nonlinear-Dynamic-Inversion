# Fault-Tolerant Flight Control for the Cessna Citation 500

Fault-tolerant flight control system for a nonlinear Cessna Citation 500 simulation, developed in MATLAB/Simulink. The project investigates whether an Adaptive Nonlinear Dynamic Inversion (ANDI) controller can maintain satisfactory aircraft behaviour following an aileron hard-over failure, and compares its response with a conventional PI controller.

The complete simulation contains the aircraft dynamics, actuator models, reference commands, flight-control system, failure injection, feedback signals, and fault-related logic. Both nominal and failed configurations can be simulated to evaluate the effect of actuator degradation on the closed-loop aircraft response.

## Project Overview

Modern flight-control systems must remain stable and controllable even when an actuator no longer behaves as commanded. This project considers an **aileron hard-over failure**, in which one of the ailerons becomes stuck at a fixed deflection.

The main objective is to compare two control architectures:

- **Classical PI control**
- **Adaptive Nonlinear Dynamic Inversion (ANDI)**

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
