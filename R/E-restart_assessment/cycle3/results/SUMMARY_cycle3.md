# Summary of cycle 3 (cold start), and comparison with cycles 1–2

Cycles 1 and 2 analysed 256 × 600-year runs restarted from one state x0
([../../results/SUMMARY.md](../../results/SUMMARY.md),
[../../cycle2/results/SUMMARY_cycle2.md](../../cycle2/results/SUMMARY_cycle2.md)).
Cycle 3 analyses 256 × 600-year runs from the production **cold start**
(`df__variance_long_x0.rds`). Every number below comes from a table in
`tables/`, cited in the linked step reports.

## The finding that changes the reading

**The x0 runs and the cold-start runs are not the same model.** They share
the parameter list (82 of 82 elements identical) and the model code (the
only difference is a new output). Even so:

- **Different equilibria** ([c3_03](c3_03_same_law.md)):
  - HIV prevalence +2.4 SD_π (+3.6%);
  - diagnosed prevalence +3–6%;
  - STI incidence +13–26%;
  - cascade proportions and PrEP coverage unchanged.

  The whole-state distance is 56 times its null 95% quantile (p = 0.0005);
  a placebo split gives p = 0.40.
- **Most likely cause: the network coefficients**
  ([c3_01](c3_01_prepare.md)).
  - A restarted run takes its edges coefficients from the restart file and
    keeps them: `edges_correct()` only rescales them for population size.
  - `restart-hpc.rds` (x0) carries the local May network estimate with a
    uniform −0.011 offset.
  - The cold starts load the HPC's `netest-hpc.rds`. The September pool,
    built on the HPC from cold starts, shows network-specific offsets
    against the local estimate: main −0.015, casual −0.087, one-off +0.100.
    These imply tie propensities of 0.985, 0.917 and 1.106.
  - A population-size effect would shift all three networks equally, so the
    HPC estimate is not the local one.
- **The calibrated parameters fit the x0 model, not the cold-start model**
  ([c3_03](c3_03_same_law.md)).
  - Under π_x0 every race-specific target is within ±1.23 SD_π.
  - Under π_cold, diagnosed prevalence is +2.9% (B), +5.3% (H) and +6.5%
    (W) above target, and STI incidence +16% to +30%.
  - The calibration was run from restarts of `restart-hpc.rds`, i.e. with
    the x0 network.

**What this adds to cycle 2.** Cycle 2 found that x0 was made with other
*parameters* and that their imprint decays in 80–100 years. A restart file
also carries *network coefficients*, which new parameters never reset. That
imprint does not decay.

## Question by question

### 1. How long from a cold start to equilibrium? Is 70 years enough?

**Cycles 1–2** could not answer: their runs did not start cold.

**Cycle 3** ([c3_04](c3_04_cold_start.md)):

- **The transient.** The cold start (everyone infected diagnosed and
  untreated, 10% STI prevalence per site) triggers an HIV overshoot of
  +15 SD_π around year 25. It decays with τ ≈ 13–17 years.
- **Mean within 0.1 SD:**
  - prevalence 126 [104, 173] years;
  - diagnosed prevalence (B) 126 [98, 163];
  - dx_frac 99 [88, 105];
  - HIV incidence 78 [65, 98];
  - STIs and PrEP 35–78.
- **Mean within 0.2 SD:** ≈ 105 years for prevalence.
- **Whole state:** at the null level from year 100; the prevalence mode
  (PC1) needs 117 [99, 153] years.
- **Variance within 10%:** 66 [53, 165] years for prevalence. Cold-start
  runs begin almost identical at the population level, so they spread as
  slowly as runs from one restart point (x0: 73).
- **At year 70:**
  - **Too early for prevalence-type outputs.** Prevalence and diagnosed
    prevalence are +0.7 to +1.3 SD_π (+1.2% to +3.4%) above π. That is 4–8
    MCSE for 32 runs, against the brief's criterion of 0.2.
  - **Adequate** for STIs, PrEP and suppression (within ±0.2 SD).
- **The brief's MSE criterion** needs ≈ 130–220 years for prevalence
  (N = 32–256). The upper CIs are long: 256 chains cannot resolve biases
  below ~0.05 SD.
- **Against a restart from x0:** a cold start needs about 1.5 times longer
  for the prevalence mean (126 vs 83 years), and about as long for the
  variance.

### 2. What does it mean for the workflow?

[c3_05](c3_05_workflow.md).

**Ballpark calibration** (cold start, targets read at year 70):

- Diagnosed prevalence is read +1.3% (B), +3.0% (H) and +3.4% (W) above the
  cold-start equilibrium. With π_cold's own gap, that is +4.3%, +8.4% and
  +10.2% above the targets.
- A calibration that matches the targets at year 70 would therefore leave
  the equilibrium 1–3% below them. This is inferred, not simulated.
- Getting within 1% needs 76–90 years.
- STI, PrEP and cascade targets are fine at 70 years.

**Pool of year-70 states from cold starts** (how the September pool was
built):

- **Cumulative incidence over years 6–15** (the intervention outcome): no
  bias (+0.05% [−0.20, 0.28]) and full spread (variance ratio 0.96). This
  is better than the current single x0 (+2.1%, variance ratio 0.75).
- **Prevalence-type outcomes:** still +0.5–0.7 SD high and falling. A
  20-year run inherits a spurious decline of 0.7 SD and 26% extra
  within-run variance.
- **Burn-in for |offset| ≤ 0.1 SD:**
  - ≈ 70 years for cumulative incidence (37 from x0);
  - ≈ 110–120 years for prevalence outcomes (68–74 from x0).

### 3. Do the restart-memory results of cycles 1–2 hold?

**Yes** ([c3_06](c3_06_replication.md)), with both experiments on the same
years.

- **ICC lower bounds agree:**
  - the 20-year prevalence mean fixes 0.80 vs 0.81 of the variance;
  - prevalence 20 years ahead 0.48 vs 0.48;
  - 10-year cumulative incidence 0.15 vs 0.14.
- **The variance split of a 20-year run** agrees within 0.015 for the HIV,
  cascade and PrEP outputs. About 89% of the variance of the prevalence
  mean is between runs.
- **What differs:**
  - HIV memory is shorter in the cold-start model: τ_int 53 vs 68 years for
    prevalence;
  - syphilis is less persistent.

So cycles 1–2's design conclusions carry over to the production model: a
single restart point is ruled out, the pool-size formulas hold, and
selection on closeness shrinks the variance.

## What changes in the recommendations

1. **Settle the network estimate first.** On the HPC, compare
   `data/run/estimates/netest-hpc.rds` with the local copy (the one-liner is
   in [c3_01](c3_01_prepare.md)). Then:
   - decide which estimate is the model, and use it everywhere: cold
     starts, pools and calibration;
   - check every restart file before using it. The offset of its edges
     coefficients against `netest` (C3-M0) should be the same in all
     networks and close to 0. Or reset `coef.form` to
     $c_0+\log(N_{\text{init}}/N)$ at restart;
   - recalibrate under the chosen network. Under the HPC network the model
     is 1.2–2.4 SD_π off the diagnosed-prevalence targets and 16–30% off STI
     incidence.
2. **Cold-start burn-in:**
   - **Ballpark stage:** 70 years is enough for STI, PrEP and cascade
     targets. For diagnosed prevalence use ≈ 90 years, or accept a
     ballpark bias of 1.3–3.4%.
   - **Pool building:** save states at ≥ 120 years for prevalence-type
     outcomes and at ≥ 70–80 years for cumulative incidence. This updates
     cycle 2's "100–150 years from x0", since x0 is not usable (other
     parameters, other network).
3. **A better initialisation would shorten all of this.** This is not
   tested here. The cold start sets total HIV prevalence to the
   *diagnosed*-prevalence targets, diagnoses everyone and treats nobody
   ([c3_01](c3_01_prepare.md)). Initialising total prevalence at ≈ π
   (≈ 0.40 / 0.16 / 0.10) and the cascade at its stationary fractions
   should remove most of the overshoot.
4. **Unchanged from cycles 1–2:**
   - pool size and use: k ≈ N for slow level estimates, 8–20 points for the
     project outcomes, and `randomize.restart` or batches sized to the
     pool;
   - no selection on closeness;
   - the spacing heuristic becomes d ≥ 2 τ_int ≈ 105 years (cold-start
     τ_int).

## Inputs for the next phase

| input | value | source |
|---|---|---|
| cold-start burn-in, mean ≤ 0.1 SD | prevalence ≈ 125 y; incidence ≈ 80 y; STIs/PrEP ≤ 80 y | c3_04 |
| cold-start burn-in, variance ≤ 10% | prevalence ≈ 65–90 y | c3_04 |
| bias at year 70 | prevalence-type +0.7 to +1.3 SD_π (+1.2–3.4%) | c3_04 |
| pool state age for research outcomes | ≥ 70–80 y (cumulative incidence), ≥ 120 y (prevalence) | c3_05 |
| ballpark calibration length for ≤ 1% target bias | 76–90 y (diagnosed prevalence) | c3_05 |
| τ_int, prevalence (cold-start model) | 53 [49, 58] y | c3_06 |
| reference data | `data/run/restart_assessment/cycle3/c3_01_annual_cold.rds` (annual, 256 chains); `c3_04_curves.rds` | c3_01, c3_04 |

## Open issues

1. **The HPC network estimate is inferred, not read.** The mechanism
   (network coefficients) explains the direction of the difference.
   Confirming it needs the HPC file. Measuring its size needs a short
   simulation, e.g. 32 cold starts for 150 years with the local netest.
2. **The new `ir100.hiv.dx` targets are far from the model:** −16% (B),
   −51% (H), +29% (W). They were not in the calibration; the definition and
   the target values should be checked.
3. **Residual bias below ~0.05 SD is not resolvable** with 256 chains. The
   MCSE-criterion burn-ins extrapolate a fitted tail.
4. **Borderline drift** of the Black population size (−0.08 SD_π per
   century over years 300–600, not over 150–600).
5. **The Hispanic stocks' variance** overshoots by 10–30% until ≈ 210
   years. It sets `EQ_START_C3` = 240 but has no practical consequence for
   the key outputs.
