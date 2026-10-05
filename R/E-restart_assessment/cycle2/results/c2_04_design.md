# C2-04. What it means for the project's designs

## Question

What does restart memory imply for the designs the project uses?

- **Intervention runs:** 32 per scenario, in batches of 8, over 15 years.
  NIA and PIA are computed against the baseline median, with the default
  `randomize.restart = FALSE`.
- **Calibration runs:** 70 years from a restart.

## Method

[c2_METHODS.md](c2_METHODS.md) C2-M6. Script: `c2_04_design.R`.

Two ICC values are used:

- **lb:** the same-parameter lower bound;
- **direct:** measured on the runs from x0.

## Results

### Pool usage in the current code

This comes from reading the code: `EpiModel/R/net.mod.init.R` and
`EpiModelHPC/R/netsim_scenarios.R`.

- With `randomize.restart = FALSE` (the default, used by
  `workflow-intervention.R`), simulation s of a `netsim` call restarts
  from point (s − 1) mod k + 1. EpiModelHPC runs each batch of `n_cores`
  = 8 runs as one `netsim` call.
- So **only points 1–8 of any pool are used**, 4 runs each out of 32, in
  every batch and every scenario.
- As a side effect, scenario arms are **paired** by point (same s → same
  point).
- With `randomize.restart = TRUE` (used by the calibration), each run draws
  a point uniformly **with replacement**, and arms are unpaired.

### Intervention outcomes, 32 runs

Source: `tables/c2_04_intervention_design.csv`.

| outcome | current: all runs from x0, SD ratio | x0 level offset | same-param. single point, SD ratio (lb / direct) | pool, 8 points × 4 runs: variance deficit | MCSE inflation of the mean (lb / direct) | points for MCSE ≤ +10%, N = 32 / 256 |
|---|---|---|---|---|---|---|
| cml incidence, total | 0.87 | +2.1% | 0.92 / 0.87 | 1.4–2.4% | 1.20 / 1.32 | 18 / 139 |
| cml incidence, B | 0.83 | +2.1% | 0.93 / 0.83 | 1.3–3.0% | 1.19 / 1.38 | 19 / 152 |
| cml incidence, H | 0.98 | −0.1% | 0.96 / 0.98 | 0.5–0.9% | 1.12 / 1.07 | 6 / 48 |
| cml incidence, W | 0.95 | +2.4% | 0.92 / 0.95 | 0.9–1.5% | 1.21 / 1.13 | 10 / 79 |
| incidence rate, year 15, total | 0.98 | +2.0% | 0.98 / 0.98 | < 0.4% | 1.05 / 1.06 | 6 / 42 |

A randomised draw from 8 points gives an MCSE inflation of 1.40 for total
cumulative incidence (direct ICC), slightly worse than recycling.

### Intervention effects (PIA)

Source: `tables/c2_04_effects_pia.csv`. Per-run PIA values, PIA_i, have:

- an SD of 1.72 percentage points (pp) with a stationary pool, vs 1.49 pp
  from one point (total, e = 0.1);
- an SD of ~5 pp for the Hispanic group.

Monte Carlo SE of the median PIA, and the effect heterogeneity σ_e across
restart states at which a single point would double the RMSE:

| outcome | N = 32 | N = 128 | N = 256 |
|---|---|---|---|
| total, e = 0.1: MCSE / σ_e threshold (pp) | 0.47 / 0.81 | 0.23 / 0.40 | 0.17 / 0.29 |
| Black MSM, e = 0.1 | 0.44 / 0.77 | 0.22 / 0.38 | 0.16 / 0.27 |
| Hispanic MSM, e = 0.1 | 1.65 / 2.86 | 0.83 / 1.43 | 0.59 / 1.01 |

### Calibration run length

Source: `tables/c2_04_calibration_run_length.csv`,
`figures/c2_04_calibration_run_length.png`.

**Share of variance fixed by the restart point**, lower bound (same
parameters):

- **i.prev.dx:** 0.51–0.77 at 10 years, 0.21–0.47 at 20, 0.09–0.25 at 30,
  ≤ 0.06 at 50, ≤ 0.01 at 70.
- **STI ir100:** 0.09–0.18 at 10 years, ≤ 0.07 at 20.

**Imprint of x0's other parameters on the targets:**

| target | 10 years | 20 years | 30 years | 50 years | 70 years |
|---|---|---|---|---|---|
| ir100.gono | +23% | +6% | +4% | +2% | −1% |
| ir100.syph | +18% | +10% | +9% | +4% | ≈ 0 |
| i.prev.dx.B (SD units) | +0.1 | +0.7 | +1.0 | +0.6 | +0.2 |
| i.prev.dx.W (SD units) | +0.9 | +0.8 | +0.9 | +0.7 | +0.2 |

The +1.0 SD for i.prev.dx.B at 30 years corresponds to +1.4%.

## Interpretation

1. **A pool is not what the current code uses.** Whatever the pool size,
   with the default settings only its first 8 points enter the intervention
   runs. To use k points, either:
   - set `randomize.restart = TRUE` (draws with replacement, unpaired arms);
     or
   - make `n_cores` ≥ k per batch, or pre-assign points to batches (not
     possible with the current EpiModelHPC template, which restarts the
     index at 1 in every batch).
2. **For levels of the intervention outcomes, 8 points × 4 runs is already
   close to "full variance".** The deficit is ≤ 3% and the MCSE of the
   level is inflated by 1.2–1.4×. The single point used so far loses
   13–17% of the SD for total and Black cumulative incidence, and adds a
   +2% level offset because x0 has other parameters.
3. **For effects, the pool matters even less — if effects are roughly
   proportional.** A single point then gives an unbiased PIA, and the pool
   only widens the per-run spread (1.5 → 1.7 pp). A single point is only a
   problem if the intervention's relative effect varies between restart
   states by more than ~0.8 pp (N = 32) or ~0.3 pp (N = 256). That can be
   checked directly (see Decision).
4. **The per-run PIA intervals in `outcomes.R` measure level
   stochasticity, not effect uncertainty.** Each run is compared with the
   baseline *median*, so the ±1.5–1.7 pp spread (±5 pp for Hispanic MSM) is
   mostly run-to-run noise in incidence. Pairing runs by restart point, or
   reporting the MCSE of the median PIA, would describe the effect more
   precisely.
5. **Calibration: 70-year runs are long enough to forget the restart
   point, including one made with other parameters.** Shortening them
   ("iterative restart") would bias the targets:
   - by 3–23% for STI incidence at 10–20 years;
   - by 0.6–1.0 SD for diagnosed prevalence at 20–50 years, whenever the
     restart point comes from other parameters, which is always the case
     within a calibration wave.

## Decision / input for next steps

- **Build the pool under the final parameters,** then use it through
  `randomize.restart = TRUE` or batches sized to the pool.
- **Check effect heterogeneity directly.** Run 8 pool points × 8
  replicates × 2 scenarios (baseline and one intervention). The
  between-point SD of the point-level PIA, compared with the thresholds
  above, decides how many points are needed for effects.
- **Keep calibration runs at ~70 years after a restart made with other
  parameters.** Short runs are only safe for fast targets (PrEP coverage,
  suppression) and only once the slow targets are fixed.

## Caveats and deviations

- **The design ICC is bracketed, not known.** The lower bound holds for a
  same-parameter point; the direct value is for x0.
- **The effect analysis is model-based** (proportional effect plus
  heterogeneity). Nothing in this dataset measures effects.
- **The MCSE formula for medians** assumes near-normal outcomes.
