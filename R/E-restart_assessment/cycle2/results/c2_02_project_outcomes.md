# C2-02. The project's own outcomes: calibration targets and intervention outcomes

## Question

Cycle 1 used generic 20-year windows. The project actually uses:

- **calibration targets** averaged over the last year of 70-year runs from
  a restart (`swfcalib_model.R`);
- **intervention outcomes:** cumulative HIV incidence over years 6–15 after
  restart and incidence in year 15 (`outcomes.R`), from 15-year runs.

For each of these: how much of the stationary variance do runs from a
single restart point show, and how long is needed? Two views are reported:

- (a) **direct**, on the runs from x0, which was made with other parameters
  (see [c2_01](c2_01_provenance.md));
- (b) **lower bounds** for a same-parameter restart point.

## Method

[c2_METHODS.md](c2_METHODS.md) C2-M1 to C2-M4. Script:
`c2_02_project_outcomes.R`.

- 18,796 pseudo-restarts and 212 features.
- 296 responses: values up to 80 years, and 10-year cumulative incidence
  with B up to 70.

## Results

### Intervention outcome: cumulative incidence over 10 years

Source: `tables/c2_02_direct_cml_incidence.csv`,
`tables/c2_02_cml_burnin_direct.csv`, `tables/c2_02_time_compare.csv`,
`figures/c2_02_cml_incidence.png`.

**Stationary variability is small.** The CV of 10-year cumulative incidence
is **1.9%** in total (1.9% B, 3.4% W, 6.0% H). The stationary mean is 10,206
infections, 7,784 of them among Black MSM.

**Runs from x0, B = 5 (the project's design).**

| group | between-run variance vs stationary | mean offset |
|---|---|---|
| total | 0.75 [0.62, 0.88] | +2.07% [1.84, 2.28] (+1.09 SD) |
| B | 0.70 [0.59, 0.80] | +2.09% |
| W | 0.91 [0.75, 1.08] | +2.37% |
| H | 0.95 [0.80, 1.12] | −0.1% |

**Burn-in B, total.**

| view | variance ≥ 90% | variance ≥ 80% |
|---|---|---|
| direct x0, fitted | 31 [18, 56] years | 14 [6, 25] |
| same-parameter lower bound | ≥ 10 years | ≥ 5 |

- The mean offset of the total is still +0.8% at B = 20–30 and ≈ 0 at B = 50.

### Intervention outcome: incidence rate in year 15

Runs from x0 have 96% of the stationary variance (SD ratio 0.98), with a
mean offset of +2.0% (`tables/c2_04_intervention_design.csv`).

### Calibration targets

Source: `tables/c2_02_icc_compare.csv`, `tables/c2_02_t_direct_x0.csv`,
`figures/c2_02_icc_targets.png`.

**Share of variance fixed by the restart, lower bound (same parameters) /
direct (x0):**

| target | h = 10 | h = 20 | h = 30 | h = 50 | h = 70 |
|---|---|---|---|---|---|
| i.prev.dx.B | 0.77 / 0.85 | 0.47 / 0.64 | 0.25 / 0.50 | 0.04 / 0.18 | 0.01 / 0.12 |
| i.prev.dx.H | 0.51 / 0.68 | 0.21 / 0.43 | 0.09 / 0.15 | 0.02 / 0.16 | 0.00 / 0.04 |
| i.prev.dx.W | 0.73 / 0.82 | 0.45 / 0.55 | 0.24 / 0.35 | 0.06 / 0.26 | 0.01 / 0.16 |
| ir100.gono | 0.18 / 0.28 | 0.06 / 0.23 | 0.02 / 0.25 | 0.00 / 0.07 | 0.00 / 0.11 |
| ir100.chla | 0.18 / 0.34 | 0.06 / 0.24 | 0.02 / 0.19 | 0.00 / 0.10 | 0.00 / 0.18 |
| cc.dx.B | 0.13 / 0.20 | 0.07 / 0.10 | 0.04 / 0.03 | 0.00 / 0.06 | 0.00 / 0.02 |
| cc.vsupp.B, cc.prep.B | ≤ 0.04 at every h | | | | |

**Time until the variance deficit stays ≤ 10%:**

| variable | same-parameter lower bound | direct x0 (fit) |
|---|---|---|
| prevalence and diagnosed prevalence (B, W) | ≥ 50 years | 69–89 years (i.prev.dx.B 69 [56, 92]; i.prev.dx.W 89 [63, 428]; prev 73 [58, 171]) |
| Hispanic | ≥ 30 years | 43 [34, 65] |
| num | ≥ 40 years | 75 [47, 246] |
| STI incidences | ≥ 10–20 years | 35–45 years |
| cascade and PrEP | ≥ 5–15 years | < 10 years for variance |

**Mean imprint of x0 after the parameter change** (`tables/c2_02_t_direct_x0.csv`).

- Within 0.1 SD at:
  - prevalence: 83 years;
  - STI incidence: 35–58 years;
  - HIV incidence: 55 years.
- The selected mean-relaxation models for prevalence and diagnosed
  prevalence are **damped oscillations** (τ ≈ 25–32 years): the transient
  overshoots.

## Interpretation

1. **For the intervention outcome, the restart question is second order.**
   Ten-year cumulative incidence varies only ±1.9% between runs at
   stationarity, and 75% of that shows up across runs from one point. The
   single-point design used so far therefore makes interval half-widths
   about 13% too narrow (SD ratio 0.87) on an outcome whose total spread is
   ±2%. The larger issue is the **+2.1% level offset** caused by x0's old
   parameters. It is 1.1 SD of the stochastic spread, so it is significant,
   although small in absolute terms (see [c2_04](c2_04_design.md) for what
   it does to effects).
2. **For prevalence-type outcomes, memory is long even with a
   same-parameter point.** The rigorous lower bound puts the time to full
   variance at ≥ 50 years. Cycle 1's ~70 years is the same quantity for a
   foreign-parameter point, and the true same-parameter value lies at or
   above 50.
3. **For calibration, 70-year runs essentially forget the restart point.**
   The lower bounds at h = 70 are ≤ 0.01, and the direct x0 imprint is
   ≤ 0.22 SD. **Shorter calibration runs would not.** At 20–30 years:
   - the restart state still fixes 25–47% of the variance of diagnosed
     prevalence (lower bound);
   - the imprint of x0's other parameters on the targets is large: +6% to
     +23% for STI incidence at 10–20 years, and +1.0 SD for i.prev.dx.B at
     30 years ([c2_04](c2_04_design.md), calibration table).

## Decision / input for next steps

- The design analysis ([c2_04](c2_04_design.md)) uses the project outcomes
  with both ICC values: lower bound = same parameters, direct = x0.
- **Burn-in answer for a same-parameter restart point:**
  - prevalence-type: at least 50 years;
  - cumulative incidence over 10 years: at least 10 years;
  - STIs: at least 10–20 years.

  These are lower bounds. For a point made with other parameters, the
  direct estimates are the better guide: ~70–90 years for prevalence and
  30–40 years for cumulative incidence.

## Caveats and deviations

- Lower bounds cannot see memory held in unobserved state (network
  structure, infection ages, treatment histories). Nonlinear features do
  not raise them ([c2_03](c2_03_robustness.md)).
- The direct values at long horizons (50–70 years) are noisy: their CIs
  include ~0 for most variables, and variables are correlated through the
  shared chains.
- The time grid for the lower bounds is 5–10 years.
