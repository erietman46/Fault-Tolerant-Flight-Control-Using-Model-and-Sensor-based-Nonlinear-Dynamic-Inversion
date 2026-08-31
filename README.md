# Fault-Tolerant Flight Control for the Cessna Citation 500

Project Contributors: Eltjo Rietman (Github: erietman46) and Tycho Rietman (Github: TychoRietman)

Fault-tolerant flight control system for a nonlinear Cessna Citation 500 / Citation I simulation, developed in MATLAB/Simulink. The project investigates whether an Adaptive Nonlinear Dynamic Inversion (ANDI) controller can maintain satisfactory aircraft behaviour following a lateral-control actuator fault and compares its response with a conventional PI rate controller.

![3-D validation trajectories](results%20and%20validation/Fig03b_trajectory_3D.png)

![Rate and sideslip tracking](results%20and%20validation/Fig06_rate_sideslip_tracking_failed_runs.png)

The first figure compares the 3-D trajectories of the four validation cases. Following the aileron fault, the aircraft controlled by the classical PI controller departs significantly from its nominal trajectory, while the ANDI-controlled aircraft remains much closer to the healthy case. The second figure compares roll-, pitch-, and yaw-rate tracking together with sideslip angle for the two failed cases. At `t = 60 s`, the failure causes a strong disturbance in both controllers; the classical controller develops sustained tracking errors, whereas ANDI recovers substantially better.

> **Important detail:** the committed failure block is not a perfectly stuck aileron. After activation at `t = 60 s`, the model switches from the healthy aileron to
>
> `delta_a,failed = -0.28 + 0.5 * delta_a,healthy`  [rad],
>
> a large negative bias combined with approximately 50% remaining command effectiveness. The results therefore demonstrate accommodation of this specific effectiveness-loss case rather than a general proof of robustness to all actuator failures.

## Project overview

Modern flight-control systems must remain stable and controllable when actuator behaviour changes unexpectedly. This project combines online aerodynamic-model identification, fault monitoring, and nonlinear dynamic inversion to study fault accommodation in the TU Delft Citation simulation environment.

The main comparison is between:

- **Classical PI rate control** — a fixed-gain baseline controller.
- **Adaptive Nonlinear Dynamic Inversion (ANDI)** — a model-based nonlinear controller that uses online Recursive Least Squares (RLS) estimates of the aerodynamic model and control derivatives.

Four validation cases are used:

| Controller | Healthy aircraft | Aileron fault |
|---|---:|---:|
| Classical PI | ✓ | ✓ |
| ANDI | ✓ | ✓ |

The simulations use identical trim conditions and pilot-command profiles so that the nominal performance and the post-failure response can be compared directly.

## Control architecture

At a high level, the Simulink model implements

```text
Pilot / reference commands
          |
          v
  Control Mode Selector
     /             \
    v               v
Classical PI       ANDI
                     |
                     +------ online aerodynamic estimates
                     |               ^
                     v               |
                surface commands     |
                     |               |
                     v               |
             actuator dynamics ------+
                     |
              failure injection
                     |
                     v
         Cessna Citation nonlinear plant
                     |
                     v
       states / accelerations / air data
                     |
          +----------+----------+
          |                     |
          v                     v
      controller          coefficient reconstruction
                                |
                                v
                       regressors + RLS + monitor
```

## Key results

The aileron fault is introduced at approximately `t = 60 s`. The identified aileron control effectiveness decreases substantially after the fault, strongly degrading the fixed classical controller. ANDI adapts to the changed model and keeps the aircraft much closer to its nominal trajectory.

### Tracking performance after failure

| Metric | Classical PI | ANDI | Improvement with ANDI |
|---|---:|---:|---:|
| RMS roll-rate error, `p` | 3.77 deg/s | 1.75 deg/s | 53.6% lower |
| RMS pitch-rate error, `q` | 0.62 deg/s | 0.10 deg/s | 84.4% lower |
| RMS yaw-rate error, `r` | 0.33 deg/s | 0.17 deg/s | 48.5% lower |
| RMS sideslip error, `beta` | 0.81 deg | 0.18 deg | 77.9% lower |

### Aircraft response and trajectory

| Metric after failure | Classical PI | ANDI |
|---|---:|---:|
| Maximum roll angle | 70.85 deg | 14.43 deg |
| Maximum pitch angle | 42.42 deg | 2.61 deg |
| Altitude loss from failure point | 7385 m | 321 m |
| Maximum horizontal trajectory deviation | 8576 m | 327 m |
| Maximum 3-D trajectory deviation | 11290 m | 329 m |

The results demonstrate substantially better fault accommodation for ANDI in the tested case. They should not be interpreted as proof that ANDI will remain stable or superior for every failure, flight condition, noise realization, or modeling error.


## Repository contents

### `model/`

The simulation entry point is **`model/Citation_FlightGear_v2.mdl`**. 

The model was last saved with MATLAB/Simulink **R2026a (26.1)**. Its committed simulation configuration uses a **120 s** stop time, **0.01 s fixed step**, and the **`ode5`** solver.

| File | Purpose |
|---|---|
| `Citation_FlightGear_v2.mdl` | Main Simulink model and primary entry point. Contains the nonlinear Citation plant, actuator model and fault injection, classical PI controller, ANDI controller, online aerodynamic identification, monitoring logic, signal logging, pilot interface, and FlightGear visualization. |
| `Citation_FlightGear_v2.mdl.autosave` | Simulink autosave/backup file. It is not required for normal use and can usually be omitted from version control. |
| `initcit.m` | Initializes the inherited Citation/DASMAT aircraft model. Loads `ac_genrl.mat`, `citdata.mat`, `jt15data.mat`, the selected trim file, mass/inertia/CG data, wind settings, and landing-gear parameters. |
| `id_init.m` | Initializes the project-specific identification and control parameters: RLS initial estimates/covariances, detector thresholds, ANDI PI gains, sideslip gain, command filter/limits, anti-windup parameters, and classical-controller gains. |
| `CitTrim_AE4311_2026_V120_A7500_M4500.tri` | Trim-condition data used by `initcit.m` for the validation operating point. |
| `citast.tri` | Additional/legacy Citation trim-state data retained with the inherited aircraft model. |
| `ac_genrl.mat` | General aircraft-model constants/data used by the Citation simulation. |
| `citdata.mat` | Citation aerodynamic/model data used by the current nonlinear plant. |
| `citdata_original.mat` | Reference/original copy of the Citation data retained for comparison or recovery. |
| `jt15data.mat` | JT15 engine/propulsion-model data used by the Citation simulation. |
| `gear_params.m` | Citation landing-gear parameters and geometry. This is inherited support code, not part of the new ANDI contribution. |
| `ac_atmos.c` / `ac_atmos.mexw64` | Atmospheric and air-data S-function source plus the included 64-bit Windows MEX binary. |
| `ac_axes.c` / `ac_axes.mexw64` | Coordinate-axis transformation S-function source plus the included 64-bit Windows MEX binary. |
| `get_Cnb.m` | Builds the body-to-NED direction-cosine matrix from Euler angles. |
| `Calculation of Force/Moments Coefficients` *(Simulink subsystem)* | Reconstructs the six nondimensional aerodynamic force/moment coefficients (`CX`, `CY`, `CZ`, `Cl`, `Cm`, `Cn`) from the simulated motion, aircraft parameters, and atmosphere. |
| `Regressors Symmetr. and Asymmetr. F/M Coefficients` *(Simulink subsystem)* | Constructs the longitudinal and lateral-directional regression vectors used by the online aerodynamic identification. |
| `RLS for CX`, `RLS for CY`, `RLS for CZ`, `RLS for CL`, `RLS for Cm`, `RLS for Cn` *(Simulink subsystems)* | Six Recursive Least Squares estimators that update the aerodynamic-model coefficients and control derivatives online. |
| `CIC lambda_CX` ... `CIC lambda_Cn` *(Simulink subsystems)* | Adaptive forgetting-factor logic associated with the six identification channels. |
| `Monitoring Fault Detection` / `Monitoring Metrics` *(Simulink subsystems)* | Forms innovation/variance-based monitoring metrics, compares them with the thresholds initialized in `id_init.m`, and supplies the fault/reset logic used by the adaptive identification. |
| `ANDI Rate Controller` *(Simulink subsystem)* | Generates rate/sideslip references from pilot inputs, forms PI virtual-control commands, and performs nonlinear dynamic inversion using the current online model. It also outputs a `valid_B` signal indicating whether the control-effectiveness inversion is usable. |
| `Classical Rate Controller` *(Simulink subsystem)* | Fixed-gain PI baseline mapping rate errors to elevator, aileron, and rudder commands. |
| `Control Mode Selector` *(Simulink subsystem)* | Selects ANDI or classical surface commands and merges them with the remaining pilot inputs before sending the vector to the aircraft model. |
| `Cessna Citation 500` *(Simulink subsystem)* | Inherited nonlinear Citation/DASMAT plant wrapper. Contains the controller/actuator interfaces and the nonlinear aircraft model. |
| `Cessna Citation 500/Actuators` *(Simulink subsystem)* | Applies surface actuator dynamics, limits, and the validation aileron failure. The `Failure Activation` step is set to `60 s` in the committed model. |
| `Pilot` / `Virtual Joystick` *(Simulink subsystems)* | Supplies pilot/control inputs and allows the model to operate without a physical joystick. |
| `FlightGear Visualisation` *(Simulink subsystem)* | Packages and sends aircraft states to FlightGear using Aerospace Blockset Flight Simulator Interface blocks. FlightGear is optional for the control/validation results. |
| `plot_controller_comparison.m` | Validation/plotting entry point after the four MAT files exist. Loads the four runs, generates all validation figures and CSV tables, and saves a combined summary MAT file. |
| `Citation.jpg` | Image used by the masked Citation Simulink block. |
| `cessnac550_3d_sfnc.m` | Legacy MATLAB S-function for a simple 3-D aircraft animation. |
| `sfunxyz.m` | Legacy MATLAB X-Y-Z plotting S-function. |
| `sfun_rttime.c` / `sfun_rttime.mexw64` | Real-time pacing S-function source and Windows binary. |
| `sdspdsamp.c`, `sdspdsamp2.c`, `sdspmview2.m` | Legacy MathWorks DSP visualization/downsampling support files retained with the original model. They are not part of the new controller contribution. |
| `cellpipe.m`, `get_pipestr.m`, `get_sysparam.m` | Legacy Simulink/helper utilities retained for compatibility with the inherited model. |
| `runfg2024_c172.bat`, `runfg_c172.bat` | Windows FlightGear launch scripts. Update installation paths/version arguments if FlightGear visualization is used. |

### Major Simulink blocks: what is inherited vs. project-specific

The project intentionally combines an inherited aircraft simulation with new control/identification logic. A useful way to read the main diagram is:

| Block/group | Role in this repository | Origin/status |
|---|---|---|
| `Cessna Citation 500` and its DASMAT aircraft/engine/aerodynamic subsystems | Nonlinear six-degree-of-freedom aircraft plant | Inherited TU Delft/DASMAT Citation simulation infrastructure |
| `Actuators`, trim/data files, atmosphere/axis S-functions | Aircraft interfaces and physical/support models | Primarily inherited with the validation failure inserted into the actuator path |
| `Calculation of Force/Moments Coefficients` | Reconstruct coefficients required for online identification | Project implementation |
| `Regressors ...` + six `RLS` blocks | Online aerodynamic and control-effectiveness identification | Project implementation |
| `CIC lambda_*` + monitoring logic | Adaptive forgetting / fault-monitoring and estimator-reset logic | Project implementation |
| `ANDI Rate Controller` | Adaptive nonlinear inversion and rate/sideslip control | Project implementation |
| `Classical Rate Controller` | Fixed PI comparison baseline | Project implementation |
| `plot_controller_comparison.m` | Reproducible four-case validation and figures/tables | Project implementation |


## Source model and academic attribution

The nonlinear aircraft environment in this repository is not an aircraft model created from scratch for this project. It builds on the long-standing TU Delft Citation/DASMAT simulation infrastructure.

The principal background reference for the simulation framework is:

> C. A. A. M. van der Linden, *DASMAT — Delft University Aircraft Simulation Model and Analysis Tool: A MATLAB/Simulink Environment for Flight Dynamics and Control Analysis*, Delft University of Technology, Faculty of Aerospace Engineering, 1998.  
> https://resolver.tudelft.nl/uuid:25767235-c751-437e-8f57-0433be609cc1

### What is new in this repository

The research contribution of this repository is the **fault-tolerant control/identification study built around the supplied Citation model**, in particular the integration and validation of:

- the actuator-failure test configuration;
- online force/moment coefficient reconstruction;
- online RLS aerodynamic/control-effectiveness identification;
- adaptive forgetting and monitoring/reset logic;
- the ANDI rate/sideslip controller;
- the classical PI comparison controller;
- the four-case validation workflow and result analysis.
