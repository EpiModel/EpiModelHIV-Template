# Summary: from a restart point to full variance

**Data.** 256 runs of 600 years, all started from one restart state x0.
Two runs where syphilis went extinct are dropped, leaving 254. Every number
below comes from a table in `tables/`, cited in the linked step reports.

## Preliminaries

- **A stationary law exists.** No drift in mean or variance over years
  150–600. One borderline flag (`prev.W`, 300–600) is in line with
  multiplicity. See [03](03_stationarity.md).
- **Validation.** The estimators recover known answers on synthetic data.
  Yearly "first crossing of a null band" rules do not: they return random
  times on stationary series. All times are therefore read from fitted
  relaxation curves. See [02](02_validate_methods.md).

## 1. How long from a single restart point to full variance?

**About 70 years for annual HIV prevalence, and 65 years or more for
20-year research windows. The mean needs 80–100 years.** Source:
[04](04_relaxation_from_x0.md).

**Annual values.**

- HIV prevalence relaxes with τ ≈ 30 years.
  - 90% of the stationary variance is reached at 73 [59, 131] years; 80% at
    52 [43, 71].
  - The mean is within 0.1 SD at 83 [74, 119] years.
  - The slowest direction of the whole state (PC1, the prevalence mode)
    gives 75 [57, 248] and 99 [72, 126] years.
- Population size is similar. STIs need ≈ 35–60 years, mainly for the mean.
- Incidence, suppression and PrEP coverage need < 10 years for the
  variance, but 25–55 years for the mean.

**20-year research windows.**

- Started directly at x0, the prevalence window means show only 14%
  [11, 16] of their stationary between-run variance, and they are shifted by
  +0.6 SD.
- 90% of the variance needs a post-restart burn-in of 66 [49, 141] years.
- At B = 70 the mean offset is +0.12 [0.00, 0.26] SD.

**Why it takes so long.**

- x0 is atypical: −4.4 SD for chlamydia, +1.7 SD for HIV incidence and
  −1.5 SD for population size in year 1.
- The model has a slow HIV mode: τ_int ≥ 66 years at stationarity. Over a
  20-year run, 90% of the stationary variance of prevalence is between runs
  and only 10% is visible over time (see [05](05_equilibrium_structure.md)).

## 2. Can restart points lower that?

**Yes, to zero, provided the points are drawn from the stationary law.**

- A pool of k points leaves a variance deficit of ICC/k ≤ 1/k. With ≥ 16
  independent stationary points, every output has ≥ 90% of the stationary
  variance from year 0 (see [07](07_pool_design.md)).
- A single point is ruled out. The restart state fixes at least 81% [80]
  of the variance of the 20-year HIV-prevalence window mean. It fixes at
  least 32–39% for total incidence, the STIs and dx_frac, and 8–14% for
  suppression and total PrEP coverage. Only race-specific PrEP coverage
  (H 0.02, W 0.03) falls below the 0.05 threshold. These are lower bounds
  (see [06](06_restart_memory.md)); the direct single-x0 value is 86% for
  prevalence.

## 3. How many points?

**It depends on precision, not on burn-in. For level estimates of slow
outputs, about one point per research run.**

- **Variance only.** A ≤ 10% deficit for all outputs needs ≈ 9 points
  (18 for ≤ 5%).
- **Precision of the mean.** With N research runs on k points, the MCSE
  inflation is $\sqrt{1+\mathrm{ICC}(N/k-1)}$. For N = 256:
  - 32 points inflate the MCSE of mean HIV prevalence by 2.65×, the
    equivalent of ~36 independent runs;
  - staying within +10% needs 206 points for prevalence, 178 for incidence,
    188 for chlamydia and 98 for suppression.

  **What ICC and MCSE mean here** (METHODS.md M2.2 and M3.1;
  [../GUIDE.md](../GUIDE.md) §2.6–2.7):

  - **ICC** (intraclass correlation) is the share of an output's
    between-run variance that is fixed by the restart point.
    - ICC = 0: runs from the same point are as different as runs from
      different points.
    - ICC = 1: runs from the same point are identical.
    - It is the ICC of cluster-randomised trials, with restart points as
      clusters and runs as members.
  - **MCSE** (Monte Carlo standard error) is the standard error of a mean
    computed over simulation runs: how much the mean would move if the
    whole experiment were re-run with other random numbers.
    - With N runs from N independent points, it is SD/√N.
  - **Why sharing points costs precision.** Runs that share a point are
    correlated, so they carry less information.
    - As in a cluster trial, the variance of the mean is multiplied by the
      design effect 1 + ICC × (n − 1), with n = N/k runs per point.
    - The MCSE is multiplied by the square root of the design effect. That
      square root is the "MCSE inflation" above.
    - The **effective number of runs** is N divided by the design effect.
  - **Example: the 20-year prevalence mean** (design ICC ≈ 0.86,
    [07](07_pool_design.md)), with 256 runs on 32 points (8 each):
    - design effect ≈ 1 + 0.86 × 7 ≈ 7.0;
    - MCSE inflation ≈ √7.0 ≈ 2.65;
    - effective runs ≈ 256 / 7.0 ≈ 36.

  The general rule is k ≈ 0.7–0.8 N for the slow and intermediate outputs.
- **How to produce them.** Run k independent chains from x0 for 100–150
  years (in parallel) and save the final states.
  - Spacing points along one chain is not cheaper: points 50 years apart
    are worth only ~0.67 of an independent point.
  - The pool is reusable across all scenarios and projects.

## 4. Should the points be selected beyond "all processes ongoing"?

**No selection on closeness to anything. Random sampling, optionally
stratified.** Source: [07](07_pool_design.md), selection experiment.

- **Closeness selection causes under-dispersion.** Choosing the 32 most
  typical or most target-like states out of 254 cuts the between-run
  variance of 20-year HIV prevalence to 62% and 40% of the truth. The
  within-run variance drops too (0.90). The pool mean looks more precise
  only because the variance is too small.
- **The "processes ongoing" filter is essentially harmless.**
  - **What it is.** Before drawing the pool, discard candidate states in
    which an STI is close to extinction, i.e. whose STI prevalence is below
    the 1% quantile of its stationary distribution. Then draw at random
    among the rest. This mimics the project's rule in
    `3-choose_restart.R`, which drops states whose STI incidence is below
    half its target.
  - **Why it is needed.** In the model an extinct STI never comes back, so
    such a state would give research runs without that epidemic.
  - **Why it is harmless.** It removes only a few rare states.
    - The futures of the filtered pool keep ≥ 95% of the stationary
      between-run variance (variance ratio ≥ 0.95).
    - Their mean is off by at most 0.04 SD.
    - Cycle 2 found the same for the project's own rule, which rejects
      3.2% of stationary states
      ([../cycle2/results/c2_05_selection.md](../cycle2/results/c2_05_selection.md)).
- **Stratified random sampling on the slow state mode keeps the variance
  exact and makes the pool more precise.**
  - **PC1, the first principal component,** is the weighted combination of
    all the standardised key and state variables along which equilibrium
    states differ most.
    - Its loadings, i.e. its correlations with each variable, are −0.91 for
      prev and −0.85 for prev.B ([04](04_relaxation_from_x0.md),
      `tables/04_pc_loadings.csv`).
    - In practice PC1 is "HIV prevalence and the HIV counts". Its sign is
      arbitrary.
  - **What stratifying means.** Sort the candidate states by their PC1
    score, cut them into 32 equal groups, and draw one state at random in
    each. The pool then covers the slowest direction of the state evenly,
    rather than by chance.
  - **The gain.** It cuts the pool-mean error for prevalence from 0.175 to
    0.105 SD, the equivalent of a ~2.8× larger random pool. This is the
    only selection that helps.

## Inputs for the next phase

| input | value | source |
|---|---|---|
| single-point burn-in | ≥ 70 y (variance), 80–100 y (mean); use 100–150 y to build a pool | 04 |
| slowest variables, τ_int | prev ≥ 66 y (lower value), prev.W 62, prev.B 58, num 50, prev.H 40, STIs 18–23 | 05 |
| between-run share of variance at L = 20 | prev 0.90, num 0.86, prev.H 0.77, STIs 0.56–0.58, dx_frac 0.40, supp_frac 0.29, incid_rate 0.19, prep_cov 0.12 | 05 |
| ICC lower bound, value at h = 20 | prev 0.49, num 0.36, STIs 0.03–0.07, incid_rate 0.03 | 06 |
| ICC lower bound, 20-year window mean at B = 0 | prev 0.81, num 0.72, STIs 0.34–0.39, incid_rate 0.32, dx_frac 0.34, prep_cov 0.14, supp_frac 0.12 | 06 |
| nested experiment n ≈ 1 + 1/ICC_lb | ≈ 2 (slow outputs) to ≈ 9 (supp_frac) runs per point | 06 |
| single-chain spacing heuristic | d ≥ 2 τ_int ≈ 130 y; points 50 / 75 y apart are worth ~0.67 / ~0.8 of an independent point | 05, 07 |
| reference data | `data/run/restart_assessment/01_annual.rds` (annual, 254 chains); `04_curves_x0.rds`, `04_window_burnin.rds` (single-x0 curves) | 01, 04 |

## Open issues

1. **Only one x0.** The direct ICC values are for one state that is far
   from equilibrium for the STIs.
   - A nested experiment would measure ICC averaged over π, including
     network and individual-level memory that the lower bounds cannot see.
     Suggested size: ~8 stationary points × ~16 runs × 40 years.
   - It should also measure the ICC of **intervention effects**. Contrasts
     between scenarios run from the same point may need far fewer points
     than the level estimates above.
2. **τ_int for HIV prevalence is a lower value.** The Geyer estimator
   truncates, and the variance–time curve is still rising at 150 years.
3. **Syphilis goes extinct** at ~1.3 × 10⁻⁵ per chain-year. This is
   negligible for 20-year runs, but π is formally quasi-stationary.
4. **Tolerance.** A 5% variance tolerance is at the resolution of 254
   chains. The 10–20% tolerances are the reliable ones.
