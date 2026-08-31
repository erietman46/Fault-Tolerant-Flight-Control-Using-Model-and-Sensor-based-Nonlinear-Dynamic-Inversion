# Fault-Tolerant Flight Control for the Cessna Citation 500

Fault-tolerant flight control system for a nonlinear Cessna Citation 500 / Citation I simulation, developed in MATLAB/Simulink. The project investigates whether an Adaptive Nonlinear Dynamic Inversion (ANDI) controller can maintain satisfactory aircraft behaviour following a lateral-control actuator fault and compares its response with a conventional PI rate controller.

![3-D validation trajectories](results%20and%20validation/Fig03b_trajectory_3D.png)

![Rate and sideslip tracking](results%20and%20validation/Fig06_rate_sideslip_tracking_failed_runs.png)

The first figure compares the 3-D trajectories of the four validation cases. Following the aileron fault, the aircraft controlled by the classical PI controller departs significantly from its nominal trajectory, while the ANDI-controlled aircraft remains much closer to the healthy case. The second figure compares roll-, pitch-, and yaw-rate tracking together with sideslip angle for the two failed cases. At `t = 60 s`, the failure causes a strong disturbance in both controllers; the classical controller develops sustained tracking errors, whereas ANDI recovers substantially better.

> **Important implementation detail:** the committed failure block is not a perfectly stuck aileron. After activation at `t = 60 s`, the model switches from the healthy aileron to
>
> `delta_a,failed = -0.28 + 0.5 * delta_a,healthy`  [rad],
>
> i.e. a large negative bias combined with approximately 50% remaining command effectiveness. The repository therefore demonstrates accommodation of this specific bias/effectiveness-loss case rather than a general proof of robustness to all actuator failures.

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

## Repository contents

### `model/`

The simulation entry point is **`model/Citation_FlightGear_v2.mdl`**. You normally do **not** run `initcit.m` or `id_init.m` manually: the model's initialization callback runs both scripts automatically when the model initializes.

The model was last saved with MATLAB/Simulink **R2026a (26.1)**. Its committed simulation configuration uses a **120 s** stop time, **0.01 s fixed step**, and the **`ode5`** solver.

| File | Purpose |
|---|---|
| `Citation_FlightGear_v2.mdl` | **Main Simulink model and primary entry point.** Contains the nonlinear Citation plant, actuator model and fault injection, classical PI controller, ANDI controller, online aerodynamic identification, monitoring logic, signal logging, pilot interface, and FlightGear visualization. |
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
| `plot_controller_comparison.m` | **Validation/plotting entry point after the four MAT files exist.** Loads the four runs, generates all validation figures and CSV tables, and saves a combined summary MAT file. |
| `Citation.jpg` | Image used by the masked Citation Simulink block. |
| `cessnac550_3d_sfnc.m` | Legacy MATLAB S-function for a simple 3-D aircraft animation. |
| `sfunxyz.m` | Legacy MATLAB X-Y-Z plotting S-function. |
| `sfun_rttime.c` / `sfun_rttime.mexw64` | Real-time pacing S-function source and Windows binary. |
| `sdspdsamp.c`, `sdspdsamp2.c`, `sdspmview2.m` | Legacy MathWorks DSP visualization/downsampling support files retained with the original model. They are not part of the new controller contribution. |
| `cellpipe.m`, `get_pipestr.m`, `get_sysparam.m` | Legacy Simulink/helper utilities retained for compatibility with the inherited model. |
| `runfg2024_c172.bat`, `runfg_c172.bat` | Windows FlightGear launch scripts. Update installation paths/version arguments if FlightGear visualization is used. |

### Major Simulink blocks: what is inherited vs. project-specific

The repository intentionally combines an inherited aircraft simulation with new control/identification logic. A useful way to read the main diagram is:

| Block/group | Role in this repository | Origin/status |
|---|---|---|
| `Cessna Citation 500` and its DASMAT aircraft/engine/aerodynamic subsystems | Nonlinear six-degree-of-freedom aircraft plant | Inherited TU Delft/DASMAT Citation simulation infrastructure |
| `Actuators`, trim/data files, atmosphere/axis S-functions | Aircraft interfaces and physical/support models | Primarily inherited/support code, with the validation failure inserted into the actuator path |
| `Calculation of Force/Moments Coefficients` | Reconstruct coefficients required for online identification | Project implementation |
| `Regressors ...` + six `RLS` blocks | Online aerodynamic and control-effectiveness identification | Project implementation |
| `CIC lambda_*` + monitoring logic | Adaptive forgetting / fault-monitoring and estimator-reset logic | Project implementation |
| `ANDI Rate Controller` | Adaptive nonlinear inversion and rate/sideslip control | Project implementation |
| `Classical Rate Controller` | Fixed PI comparison baseline | Project implementation |
| `plot_controller_comparison.m` | Reproducible four-case validation and figures/tables | Project implementation |

## Requirements

### Software used for the committed model

- **MATLAB R2026a (26.1)** — the model was last saved in this release. Earlier releases have not been verified.
- **Simulink** — required.
- **Aerospace Blockset** — required by the committed `FlightGear Visualisation` subsystem, which uses Aerospace Blockset Flight Simulator Interface and angle-conversion blocks.
- **FlightGear** — optional. It is only needed if you want external 3-D visualization; it is not needed to reproduce the numerical plots from the saved MAT files.

### Not required by the inspected reproduction workflow

- **Control System Toolbox:** no direct dependency was found in the initialization or validation scripts. The PI/ANDI implementation is contained in Simulink/MATLAB logic.
- **Aerospace Toolbox:** the FlightGear blocks in this model come from **Aerospace Blockset**, not Aerospace Toolbox.

### Platform note

The repository contains precompiled `*.mexw64` S-functions, so the supplied binaries target **64-bit Windows**. The corresponding C sources are included for the main custom S-functions. On Linux/macOS, or if a MEX binary is incompatible with your MATLAB release, you may need to rebuild the required S-functions with a supported C compiler.

## How to run

### A. Reproduce the two headline figures from the checked-in result files

This is the fastest reproducibility path and does not require rerunning the nonlinear simulation.

1. Clone/download the repository and start MATLAB.
2. Set the MATLAB current folder to the repository root.
3. Run:

```matlab
cd('results and validation')
run(fullfile('..','model','plot_controller_comparison.m'))
```

4. The script loads the newest matching copies of:

```text
classical_no_failure*.mat
classical_failure*.mat
ANDI_no_failure*.mat
ANDI_failure*.mat
```

5. Generated figures/tables are written to:

```text
results and validation/Step6_validation_output/
```

The two README headline plots correspond to:

```text
Fig03b_trajectories_3D.png
Fig06_rate_sideslip_tracking_failed_runs.png
```

The checked-in 3-D figure is currently named `Fig03b_trajectory_3D.png`; this is the same analysis with a slightly different historical filename.

### B. Run the nonlinear Simulink model

1. Change to the model directory:

```matlab
cd('model')
open_system('Citation_FlightGear_v2.mdl')
```

2. The model initialization automatically executes:

```matlab
run('initcit.m')
run('id_init.m')
```

so you do not normally need to run these manually.

3. Confirm that the trim initialization prints the intended mass, CG, altitude, speed, flight-path angle, and power-lever condition in the MATLAB Command Window.

4. Select the controller with the top-level **`ANDI enable`** block:

- constant output `0` -> classical PI controller;
- constant output `1` -> ANDI controller.

The committed model is configured with ANDI enabled.

5. Configure the fault inside:

```text
Cessna Citation 500
  -> Actuators
      -> Failure Activation
```

For a failed run, use the committed `0 -> 1` step at `t = 60 s`. For a healthy run, keep the failure signal at `0` for the full simulation.

6. Run the model for `120 s`. The committed solver settings are:

```text
Solver:     ode5
Type:       fixed-step
Step size:  0.01 s
Stop time:  120 s
```

7. Save each completed workspace with the corresponding name in `results and validation/`:

```matlab
% Example after running Classical + Healthy
save(fullfile('..','results and validation','classical_no_failure.mat'))
```

Repeat for the four combinations:

| Run | ANDI enable | Failure activation | Save as |
|---|---:|---|---|
| Classical healthy | `0` | disabled / held at `0` | `classical_no_failure.mat` |
| Classical failure | `0` | step to `1` at `60 s` | `classical_failure.mat` |
| ANDI healthy | `1` | disabled / held at `0` | `ANDI_no_failure.mat` |
| ANDI failure | `1` | step to `1` at `60 s` | `ANDI_failure.mat` |

8. After all four files exist, reproduce the full validation suite:

```matlab
cd(fullfile('..','results and validation'))
run(fullfile('..','model','plot_controller_comparison.m'))
```

The validation script generates the monitoring plots, RLS histories, aileron-effectiveness comparison, 2-D/3-D trajectories, surface histories, rate/sideslip tracking, handling-state plots, trajectory-deviation plots, five CSV summary tables, and a combined MAT summary.

## Controller tuning

The main controller parameters are collected in `model/id_init.m`, which makes the tuning easy to inspect and modify. The committed ANDI values are:

| Parameter | Value | Role |
|---|---:|---|
| `Kp_p`, `Kp_q`, `Kp_r` | `4.5` | Proportional gains for roll-, pitch-, and yaw-rate inner loops. |
| `Ki_p`, `Ki_q`, `Ki_r` | `5.0` | Integral gains for the three angular-rate loops. |
| `K_beta` | `2` | Outer sideslip controller gain. |
| `tau_cmd` | `0.5 s` | Pilot-command/reference filtering time constant. |
| `p_ref_max` | `20 deg/s` | Maximum commanded roll rate. |
| `q_ref_max`, `r_ref_max` | `10 deg/s` | Maximum commanded pitch/yaw rate. |
| `beta_ref_max` | `5 deg` | Maximum commanded sideslip. |
| `Taw_p`, `Taw_q`, `Taw_r` | `0.5 s` | Anti-windup tracking time constants. |
| `Kaw_p`, `Kaw_q`, `Kaw_r` | `2 s^-1` | Corresponding back-calculation anti-windup gains. |

These gains should be interpreted as a tuning that works for the demonstrated trim condition and maneuver, not as a globally validated gain set for the complete Citation envelope.

Qualitatively:

- Increasing the PI gains generally makes the rate response faster, but also increases actuator activity and the likelihood of saturation, excitation of unmodelled dynamics, and amplification of noisy estimates.
- Reducing the gains generally improves smoothness and robustness margins but slows disturbance/failure recovery.
- `tau_cmd` trades command responsiveness against high-frequency control activity. A smaller value makes the demanded rates change more abruptly; a larger value produces smoother but slower commands.
- Anti-windup becomes important after the fault because the changed actuator authority can drive the inversion/controller toward surface limits.
- ANDI performance also depends on the quality of the identified control derivatives. Aggressive controller gains cannot compensate for poor excitation, biased estimates, or an ill-conditioned control-effectiveness matrix.

No systematic gain sweep, structured singular-value analysis, Monte Carlo campaign, or full-envelope gain-scheduling study is included in the repository, so stronger robustness claims would require additional validation.

## Robustness and limitations

### Sensor noise

The current validation does **not** establish robustness to realistic sensor noise. The project uses measured/simulated motion variables to reconstruct aerodynamic coefficients and then updates the model online with RLS. Noise can therefore affect both the coefficient reconstruction and the innovations used by the monitoring logic.

Particularly sensitive quantities include angular accelerations/rapidly changing signals and the RLS innovation. In a noisy implementation, practical extensions would normally include appropriate sensor filtering, synchronized measurements, careful differentiation/acceleration estimation, covariance/forgetting-factor tuning, and detector thresholds calibrated against the expected noise statistics.

The present thresholds in `id_init.m` are therefore specific to the current simulation/validation setup and should not be treated as universal fault-detection limits.

### Sensitivity to model identification

ANDI is model based. Its ability to redistribute control after a failure depends on the online estimates converging quickly enough and on sufficient excitation of the relevant aerodynamic/control derivatives. If the estimated control-effectiveness matrix becomes inaccurate or poorly conditioned, inversion quality degrades. The implementation exposes a `valid_B` signal to identify whether the ANDI control-effectiveness inversion is usable, but the repository does not constitute a formal proof of closed-loop stability for arbitrary estimation errors.

### Other failure types

Only the committed aileron bias/effectiveness-loss scenario has been quantitatively validated in the checked-in results. The architecture is conceptually applicable to other actuator-effectiveness changes if those changes are observable in the identified aerodynamic derivatives and sufficient remaining control authority exists, but that generalization has **not** been demonstrated here.

Not yet validated are, for example:

- complete aileron loss or a truly stuck surface;
- different aileron bias magnitudes or effectiveness levels;
- elevator or rudder failures;
- multiple simultaneous actuator failures;
- rate limits, runaway actuators, or increased actuator lag;
- sensor bias, dropout, or failure;
- structural/aerodynamic damage;
- strong turbulence or realistic measurement-noise cases;
- operation over a broad speed/altitude/CG envelope.

These cases are natural next steps for assessing how far the ANDI/RLS architecture generalizes beyond the single demonstration case.

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

## Source model and academic attribution

The nonlinear aircraft environment in this repository is **not an aircraft model created from scratch for this project**. It builds on the long-standing TU Delft Citation/DASMAT simulation infrastructure.

The included `initcit.m` identifies **Clark Borst (TU Delft Control and Simulation, 2004)** and its startup banner also credits **Coen de Visser (2022)**. Other inherited support files identify additional authors, including **C.A.A.M. van der Linden**, **O. Stroosma**, and **A.R. Veldhuijzen**. Those original attributions should be retained in the source files.

The principal background reference for the simulation framework is:

> C. A. A. M. van der Linden, *DASMAT — Delft University Aircraft Simulation Model and Analysis Tool: A MATLAB/Simulink Environment for Flight Dynamics and Control Analysis*, Delft University of Technology, Faculty of Aerospace Engineering, 1998.  
> https://resolver.tudelft.nl/uuid:25767235-c751-437e-8f57-0433be609cc1

A later TU Delft reference describing the Citation simulation lineage and the development of an upgraded Citation II model is:

> M. A. van den Hoek, C. C. de Visser, and D. M. Pool, “Identification of a Cessna Citation II Model Based on Flight Test Data,” *4th CEAS Specialist Conference on Guidance, Navigation and Control*, Warsaw, 2017.  
> https://resolver.tudelft.nl/uuid:c0a57513-38b7-4d3a-898c-fa57c3e7ac2e

That work explicitly describes the pre-existing TU Delft baseline as a DASMAT/Citation I model and provides useful context for the aircraft-model lineage.

### What is new in this repository

The research contribution of this repository is the **fault-tolerant control/identification study built around the supplied Citation model**, in particular the integration and validation of:

- the actuator-failure test configuration;
- online force/moment coefficient reconstruction;
- online RLS aerodynamic/control-effectiveness identification;
- adaptive forgetting and monitoring/reset logic;
- the ANDI rate/sideslip controller;
- the classical PI comparison controller;
- the four-case validation workflow and result analysis.

This distinction is important both academically and for software licensing.

## License and third-party material

Original project code and project-specific modifications authored for this repository are released under the **MIT License**; see [`LICENSE`](LICENSE).

**The MIT license does not relicense third-party or inherited material.** The repository contains TU Delft/DASMAT Citation-model files and legacy MathWorks/support code with their own authorship/copyright notices. See [`THIRD_PARTY_NOTICE.md`](THIRD_PARTY_NOTICE.md) before redistributing or reusing those files.

In particular, do not assume that the following are MIT-licensed merely because they are stored in this repository:

- the inherited Citation/DASMAT plant and data files;
- TU Delft/NLR support scripts and S-functions;
- MathWorks-copyrighted legacy helper/S-function source;
- Aerospace Blockset library content referenced by the Simulink model.

If you intend to redistribute the complete model outside the context in which it was supplied, verify the applicable rights for those third-party components separately.
