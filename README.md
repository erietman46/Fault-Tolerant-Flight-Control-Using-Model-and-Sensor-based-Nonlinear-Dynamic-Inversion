# Fault-Tolerant Flight Control for the Cessna Citation 500

Fault-tolerant flight control system for a nonlinear Cessna Citation 500 simulation, developed in MATLAB/Simulink. The project investigates whether an Adaptive Nonlinear Dynamic Inversion (ANDI) controller can maintain satisfactory aircraft behaviour following an aileron hard-over failure, and compares its response with a conventional PI controller.

<img width="2283" height="1301" alt="Fig03b_trajectory_3D" src="https://github.com/user-attachments/assets/b3698c01-34d8-48c5-bfa1-5a7509c36b7f" />
<img width="4335" height="3119" alt="Fig06_rate_sideslip_tracking_failed_runs" src="https://github.com/user-attachments/assets/744253b8-a22d-47c2-ac52-6b5ce01d70a0" />

The first figure compares the ground trajectories of the four validation cases. Following the aileron hard-over failure, the aircraft controlled by the classical PI controller departs significantly from its nominal trajectory, while the ANDI-controlled aircraft remains close to the healthy case. The bottom figure compares roll, pitch, and yaw-rate tracking together with sideslip angle for the two failed cases. At t=60 s, the failure causes a strong disturbance in both controllers. The classical controller develops sustained tracking errors and increased sideslip, whereas ANDI recovers rapidly and continues to track the commanded rates with only a short transient. These results demonstrate the improved fault-accommodation capability of the ANDI-based controller.

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
```

## Key Results

The aileron hard-over failure is introduced at approximately `t = 60 s`.  
The failure reduces the available aileron control effectiveness by about 50% in roll, which strongly degrades the response of the classical controller. The ANDI controller is able to accommodate the change in control effectiveness and keeps the aircraft much closer to the nominal trajectory.

### Tracking Performance After Failure

| Metric | Classical PI | ANDI | Improvement with ANDI |
|---|---:|---:|---:|
| RMS roll-rate error, `p` | 3.77 deg/s | 1.75 deg/s | 53.6% lower |
| RMS pitch-rate error, `q` | 0.62 deg/s | 0.10 deg/s | 84.4% lower |
| RMS yaw-rate error, `r` | 0.33 deg/s | 0.17 deg/s | 48.5% lower |
| RMS sideslip error, `β` | 0.81 deg | 0.18 deg | 77.9% lower |

The largest improvement is seen in pitch-rate and sideslip tracking. Although ANDI still experiences a transient when the failure occurs, the post-failure tracking errors remain substantially smaller than with the classical controller.

### Aircraft Response and Trajectory

| Metric after failure | Classical PI | ANDI |
|---|---:|---:|
| Maximum roll angle | 70.85 deg | 14.43 deg |
| Maximum pitch angle | 42.42 deg | 2.61 deg |
| Altitude loss from failure point | 7385 m | 321 m |
| Maximum horizontal trajectory deviation | 8576 m | 327 m |
| Maximum 3D trajectory deviation | 11290 m | 329 m |

The difference is also clear in the aircraft trajectory. Under classical control, the actuator failure produces a large departure from the corresponding healthy trajectory, with a maximum horizontal deviation of approximately 8.6 km. With ANDI, this deviation is reduced to approximately 0.33 km, corresponding to a reduction of about 96%.

The maximum 3D trajectory deviation is reduced from approximately 11.3 km with the classical controller to 0.33 km with ANDI. The ANDI controller also limits the maximum roll and pitch excursions and prevents the large altitude loss observed with the classical controller.

Overall, the validation results show that the ANDI-based controller provides substantially better fault accommodation following the aileron hard-over failure. The controller cannot remove the transient caused by the sudden actuator failure, but it is able to recover the aircraft response and maintain considerably better tracking and trajectory control than the classical PI controller.


