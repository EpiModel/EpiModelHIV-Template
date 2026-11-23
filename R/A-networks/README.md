# A — Network Estimation

## What this chapter does

EpiModelHIV simulates partnerships between individuals on a network. Before
running any epidemic simulation, we need network models that realistically
reproduce partnership patterns observed in the real world.

This chapter fits three separate network models from
[ARTnet](https://github.com/EpiModel/ARTnet) survey data — one for each
partnership type:

| Network | What it represents | Duration |
|---|---|---|
| **Main** | Long-term / primary partnerships | Months to years (age-dependent) |
| **Casual** | Short-term recurring partnerships | Weeks to months (age-dependent) |
| **One-off** | Single encounters | Instantaneous (dissolve each time step) |

These three models are fitted separately but are **not independent**: the casual
model accounts for each person's degree in the main network, and vice versa.
This means **the fitting order matters** — main must be fitted before casual.

For background on TERGMs and the ERGM formula syntax used in the model scripts,
see the [wiki](https://github.com/EpiModel/EpiModeling/wiki#tergm).

## Scripts

| Script | What it does |
|---|---|
| **`1-estimation.R`** | Fit the 3 network models. Saves estimates to `data/run/estimates/`. |
| **`2-diagnostics.R`** | Simulate from the fitted models and compute diagnostic statistics. Saves to `data/run/diagnostics/`. |
| **`3-check.R`** | Check every target statistic and duration of the fits against the diagnostics. Stops if the HPC fits are outside tolerance. No netsim work before it passes. |
| **`4-assess.R`** | Load and inspect the diagnostics interactively (print tables, plot). |
| **`workflow-networks.R`** | Generate the HPC workflow to run estimation, diagnostics and the check at full scale. |

Utility scripts (sourced, never run directly):

| Script | Role |
|---|---|
| `initialize.R` | Load ARTnet data, build network objects with node attributes |
| `model_main.R`, `model_casl.R`, `model_ooff.R` | Define ERGM formulas, target statistics, and fit each model |
| `diag_main.R`, `diag_casl.R`, `diag_ooff.R` | Run dynamic and static diagnostics for each model |
| `network_check.R` | The criteria of the network check, and `assert_network_check()`, which `R/netsim_settings.R` calls |
| `z-context.R` | Set network size and estimation parameters for local vs. HPC |

## Workflow

### 1. Run estimation locally

Run **`1-estimation.R`** in a fresh R session. This fits the three models using
the local context (10k nodes, fast approximation). It takes a few minutes.

### 2. Run diagnostics locally

Run **`2-diagnostics.R`** in a fresh R session. This simulates from the fitted
models and computes statistics to check against the targets.

### 3. Check the fits against their targets

Run **`3-check.R`**. It reads the diagnostics, compares every target statistic
of the three models with what they simulate, and for the HPC fits stops if
anything is outside tolerance (for the local fits it reports the misses and
goes on, since those diagnostics are short and noisy):

- **static**: draws from the cross-sectional model, all three networks. A miss
  here is a problem with the fit.
- **dynamic**: the last half of the dynamic simulation, main and casual, run at
  the tergm sampling every netsim run uses (`control_tergm_sim()` in
  `R/shared_variables.R`). A statistic that passes the static check and misses
  here is under-sampled at that setting: raise `tergm_proposals` and rerun the
  diagnostics.
- **duration**: mean partnership duration by age group.

A statistic passes within 5% of its target, or within one standard deviation
of the statistic for small counts. The check is written to
`network_check-<context>.csv` in `data/run/diagnostics/`.

**This is the gate before any netsim work.** `R/netsim_settings.R` stops every
HPC-context script unless the fits it loads have passed, at the current
`tergm_proposals`. The attributes are static in the diagnostics, so the check
says nothing about what aging does to the networks in the full model; that is
looked at in the netsim work, and if it calls for different network
statistics, come back here.

### 4. Look at the diagnostics in full

Run **`4-assess.R`** interactively. For each network, you get two types of
diagnostics:

- **Dynamic**: simulates the network forward in time. The plot shows target
  values (black line) vs. simulated values (colored lines/CI band). Good fit =
  simulated values track the target closely and remain stable over time.
- **Static**: samples from the ERGM once (no temporal dynamics). Checks that
  the fitted parameters reproduce the target statistics in a single snapshot.

**What to look for:**

- In the **table**: compare the `Target` and `Sim Mean` columns. They should be
  close. Large discrepancies (relative to `Sim SD`) indicate a poor fit.
- In the **plot**: the target line should fall within the simulated confidence
  band. If it drifts outside, the model is not reproducing that statistic well.

**If diagnostics look bad:**

- Check the R console output from `1-estimation.R` for convergence warnings.
- Try increasing `MCMLE.maxit` in `z-context.R`.
- The formula terms in `model_*.R` may need adjustment (consult a lab member
  experienced with ERGM fitting).

### 5. Run on the HPC

Once you are satisfied with the local diagnostics:

1. Push your code to GitHub.
2. Run **`workflow-networks.R`** locally — this generates SLURM job files in
   `workflows/networks/`.
3. Submit the workflow on the HPC (see [wiki](https://github.com/EpiModel/EpiModeling/wiki#slurmworkflow)).
4. The last step is the network check, so the job's END mail means the fits
   passed and a FAIL mail means they did not. Once complete, download
   `data/run/estimates/` and `data/run/diagnostics/` from the HPC: the netsim
   scripts read `network_check-hpc.rds` from there and stop without it.
5. Re-run `4-assess.R` with `hpc_context <- TRUE` to inspect the full-scale
   diagnostics.

## What to edit

For most projects, the default network models and ARTnet configuration in
`initialize.R` will work without changes.

If your project requires different network parameterizations (e.g., different
city, different age groups, different partnership structure), modify:

- `data/input/city.csv`: the city's geography, population size (the HPC network size), race composition and initial HIV prevalence (see "Modeling another city" in the main README)
- `model_*.R`: ERGM formula terms and target statistics
- `diag_*.R`: diagnostic formulas (should mirror estimation formulas, but can include extra terms for inspection)
- `z-context.R`: local network size (keep it ≤ 10k to avoid very long estimation times)
