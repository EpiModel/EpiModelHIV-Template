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
| **`3-assess.R`** | Load and inspect the diagnostics interactively (print tables, plot). |
| **`workflow-networks.R`** | Generate the HPC workflow to run estimation + diagnostics at full scale. |

Utility scripts (sourced, never run directly):

| Script | Role |
|---|---|
| `initialize.R` | Load ARTnet data, build network objects with node attributes |
| `model_main.R`, `model_casl.R`, `model_ooff.R` | Define ERGM formulas, target statistics, and fit each model |
| `diag_main.R`, `diag_casl.R`, `diag_ooff.R` | Run dynamic and static diagnostics for each model |
| `z-context.R` | Set network size and estimation parameters for local vs. HPC |

## Workflow

### 1. Run estimation locally

Run **`1-estimation.R`** in a fresh R session. This fits the three models using
the local context (10k nodes, fast approximation). It takes a few minutes.

### 2. Run diagnostics locally

Run **`2-diagnostics.R`** in a fresh R session. This simulates from the fitted
models and computes statistics to check against the targets.

### 3. Assess the diagnostics

Run **`3-assess.R`** interactively. For each network, you get two types of
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

### 4. Run on the HPC

Once you are satisfied with the local diagnostics:

1. Push your code to GitHub.
2. Run **`workflow-networks.R`** locally — this generates SLURM job files in
   `workflows/networks/`.
3. Submit the workflow on the HPC (see [wiki](https://github.com/EpiModel/EpiModeling/wiki#slurmworkflow)).
4. Once complete, download `data/run/estimates/` and `data/run/diagnostics/`
   from the HPC.
5. Re-run `3-assess.R` with `hpc_context <- TRUE` to inspect the full-scale
   diagnostics.

## What to edit

For most projects, the default network models and ARTnet configuration in
`initialize.R` will work without changes.

If your project requires different network parameterizations (e.g., different
city, different age groups, different partnership structure), modify:

- `initialize.R` — geographic settings, initial HIV prevalence
- `model_*.R` — ERGM formula terms and target statistics
- `diag_*.R` — diagnostic formulas (should mirror estimation formulas, but can
  include extra terms for inspection)
- `z-context.R` — network sizes (keep local ≤ 10k to avoid very long estimation times)
