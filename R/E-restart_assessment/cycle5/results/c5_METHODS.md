# Cycle 5 methods (C5-M1 to C5-M5)

Definitions used by the cycle 5 scripts. The ideas behind them are in
[SCENARIOS.md](../../SCENARIOS.md) §3 and the [GUIDE](../../GUIDE.md)
§2.6–2.7. Earlier methods are cited as M (cycle 1), C2-M, C3-M and C4-M.

## C5-M1. Runs, points and annual data

**The runs** (`R/C-new_calibration/workflow-variance_scenarios.R`,
2026-09-28):

- all restart from `restart_pool.rds`, the 32 states of cycle 4, at step 2;
- batches of 32 runs on 32 cores, with recycling (`randomize.restart =
  FALSE`): run s of each batch starts from point s. So each point gets
  exactly 4 runs in each scenario (4 batches);
- **short set:** 15 years (steps 2–781), change at step 262, the first step
  of year 6:
  - baseline: a no-op updater, so that it goes through the same code path;
  - S1: HIV testing odds × 2 (`hiv.test.rate`, 3 groups);
  - S2: PrEP initiation odds × 2 (`prep.start.rate`, 3 groups);
  - S3: STI screening odds × 3 (`sti.screen.hivneg.rate`,
    `sti.screen.hivpos.rate`);
- **long set:** S4, `acts.scale` = 0.9 from the restart, 150 years. Its
  baseline is the 256 cycle 4 pool runs (1–15 per point), cut to their
  first 150 years.

**Checks** (`c5_01`):

- the copied state (step 2) of each run equals exactly the pool point
  `sim_number` (all 61 recorded variables);
- 4 runs per point and scenario;
- before step 262, every arm agrees with the baseline;
- after it, each scenario moves the variable it acts on.

**Annual data.** As cycle 4: year k covers steps (k − 1) × 52 + 2 … k × 52 +
1, and derived variables are computed from annual aggregates (C3-M1).

**Outcomes of the short runs** (`short_outcomes()`):

- counts summed over years 6–15, the intervention period: HIV infections
  (total and by group), gonorrhoea, chlamydia and syphilis infections;
- values in year 15: HIV prevalence, HIV incidence rate, diagnosed
  fraction, PrEP coverage.

## C5-M2. Paired effect and effect heterogeneity

**Point level.** For an outcome Y and a scenario a against the reference 0:

- m_aj, m_0j: the means of the runs of point j in each arm;
- d_j = m_aj − m_0j: the within-point difference;
- s²_Wa, s²_W0: the pooled within-point variances of each arm, with
  N_a − k and N_0 − k degrees of freedom.

**Average effect.** Δ̂ = mean of the d_j, with every point weighted
equally, since the points are draws from π.

- SE = SD(d_j) / √k, with a t distribution on k − 1 degrees of freedom.
- This SE includes both chance and effect heterogeneity.
- For counts, the relative effect is PIA = −Δ̂ / mean(m_0j), the share of
  events averted.

**Effect heterogeneity.** The variance of the conditional effect Δ(x)
between points.

- Chance part of var(d_j): noise = mean_j(s²_Wa / n_aj + s²_W0 / n_0j).
- Estimate: σ̂²_Δ = var(d_j) − noise. It is an ANOVA estimate and can be
  negative.
- Test of no heterogeneity: F = var(d_j) / noise, against F(k − 1,
  N_a + N_0 − 2k). It is exact for a balanced design with normal runs.
- 95% CI by inverting F: σ²_Δ ∈ noise × [F / F_0.975 − 1, F / F_0.025 − 1].
- A point bootstrap is computed as a check (`point_boot_paired()`).
- σ_e = √max(σ̂²_Δ, 0) / mean(m_0j): the SD of the effect between points in
  PIA units (reported in percentage points, pp).
- Effect ICC: σ̂²_Δ / (σ̂²_Δ + s²_Wa + s²_W0) (SCENARIOS.md §3.2).

**Proportional-effect check** (cycle 2, C2-M6).

- If the scenario multiplies the level by the same factor (1 + e) from every
  state, then Δ(x) = e μ_0(x). The heterogeneity of the *absolute* effect is
  then e² σ²_B, where σ²_B is the between-point variance of the baseline
  level.
- `prop_in_ci` reports whether e² σ̂²_B lies inside the CI of σ²_Δ.

**Validation** (`c5_02`). Synthetic runs with the two actual designs,
1,000 replications per case:

- designs: 32 × 4 against 32 × 4, and 32 × 4 against cycle 4's 1–15 runs
  per point;
- ICC 0.25; effects e = 0 and 0.1; added heterogeneity 0, 0.02, 0.1 and 0.3
  (in units of the equilibrium variance); normal or skewed noise;
- criteria: |z| < 3 for biases; coverage in [0.93, 0.97]; rejection rate
  in [0.03, 0.07] under no heterogeneity.

## C5-M3. Consequences for the design

`design_rmse()` evaluates the formulas of SCENARIOS.md §3.2 and §4.2 with
the measured variances.

- Inputs: the between-point variance σ²_B of the baseline level, the
  within-point variance (the mean of the two arms), and σ̂²_Δ or its upper
  95% limit.
- Output: the RMSE of the estimated effect for N = 32 runs per scenario,
  under five designs: paired with 1, 8 or 32 points; unpaired with points
  drawn at random from 32; unpaired with independent points.
- **Caveat.** σ²_B comes from the baseline arm alone (32 points × 4 runs),
  which estimates it poorly (c5_03). The design ratios that involve σ²_B
  (random against paired) are therefore also given with cycle 4's ICC in
  the report.

## C5-M4. STI threshold

**Extinction:** a year with a mean infected count of 0 (it is absorbing).

**Distance from extinction:** the lowest and median STI prevalence in year
15, and the number of runs below the 1% quantile of the baseline
equilibrium (cycle 4, years ≥ 300).

**The filter** (cycle 1 rule, GUIDE §2.13): points whose saved STI
prevalence is below that 1% quantile. Its effect on the scenario estimates
is checked by leaving out the lowest decile of points, a stricter filter.

**State dependence of the relative effect:** a regression of the
point-level share averted, −d_j / m_0j, on the point's saved prevalence of
the same STI.

- This tests heterogeneity of the relative effect.
- A regression of the absolute difference would pick up proportionality
  instead (C5-M2).

## C5-M5. Relaxation after a sustained change (S4)

**Effect trajectory.** Δ(h), the paired effect of S4 against the cycle 4
runs at each year h = 1…150 (C5-M2, unbalanced baseline).

**Long-run effect.** Δ_∞ = the mean of Δ(h) over years 101–150, reported
with its drift (OLS slope, per 50 years) over those years.

**Relaxation fit.** The offset o(h) = (Δ(h) − Δ_∞) / SD_π, with SD_π from
the baseline equilibrium, is fitted with the cycle 3 mean-relaxation models
(one exponential, two exponentials, damped cosine; AIC).

- T(0.1), T(0.2): the years after which the fitted |o| stays ≤ 0.1 or
  ≤ 0.2 SD_π.
- Shares of the long-run effect present at 10, 20 and 50 years:
  Δ(h) / Δ_∞ (raw), and from the fit at 10 years.

**Uncertainty.** 200 bootstraps over points, each keeping all runs of a
point in both arms, with the whole estimation redone.

**Caveat.** Δ_∞ is taken from years 101–150 of the same runs, so T is
relative to that level. A relaxation still under way after 100 years would
be understated. The drift check addresses this.

**Heterogeneity by horizon.** σ_Δ(h) and the effect ICC at each year, in
SD_π units, summarised by period (1–5, 6–10, 11–20, 21–50, 51–100, 101–150
years).
