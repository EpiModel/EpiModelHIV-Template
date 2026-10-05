# Summary of cycle 4 (restart from a 32-point pool), and what it changes

Cycles 1–3 analysed:

- runs restarted from one state x0 made with other parameters (cycles 1–2);
- runs from a cold start (cycle 3).

Cycle 4 analyses 256 × 600-year runs restarted from **32 stationary states
of the cold-start runs**: their final states at year 600, with
`randomize.restart`, 1–15 runs per point ([c4_01](c4_01_prepare.md)).
This is the nested, same-parameter experiment that cycles 1–2 asked for.
Every number below comes from a table in `tables/`, cited in the linked
step reports.

## First: an erratum for cycle 3

Cycle 3 inferred that the HPC's `netest-hpc.rds` differs from the local
copy, giving the cold-start runs about 8% fewer casual and 11% more one-off
ties. **That is wrong.**

- **The evidence.** The new pool is made of the cold-start runs' own final
  states, and every point carries exactly the local `netest` edges
  coefficients, adjusted for its population size (offset < 5 × 10⁻¹³ in
  all networks, [c4_01](c4_01_prepare.md)).
- **Where the September pool's offsets came from.** Its network-specific
  offsets came from the ballpark calibration runs it was built from, not
  from the variance runs.

**What does hold is the mechanism.** A restart file carries its own network
coefficients, and new parameters never reset them. The coefficient that
differs is **x0's**: `restart-hpc.rds` has a uniform −0.011 offset, i.e.
1.1% fewer ties in every network. It explains π_x0 ≠ π_cold:

- restarting from consistent states reproduces π_cold exactly (next
  section);
- a 1.1% drop in transmission predicts about −3.3% prevalence for an
  endemic infection at p ≈ 0.25, against −3.5% observed. This is a rough
  plausibility check.

**Corrections to cycle 3:**

| where (cycle 3) | statement | correction |
|---|---|---|
| c3_01 Interpretation 3; c3_03 Interpretation 2; SUMMARY_cycle3 "most likely cause" | the cold starts load a different network estimate on the HPC | They use the local estimate. The difference comes from x0's −0.011 offset. |
| SUMMARY_cycle3 recommendation 1 | settle the network estimate first: compare the HPC `netest` with the local copy | Not needed for the variance runs. Check restart files instead: `restart-hpc.rds` fails (−0.011), and the new pool passes (0). |
| c3_01 network table | the September pool row | It cannot be reproduced: `restart_pool.rds` was overwritten on 2026-09-27. Re-running c3_01 would compute the new pool under the September label. |
| c3_06, SUMMARY_cycle3 Q3 | the restart-memory results of cycles 1–2 carry over (on lower bounds) | They carry over, but the lower bounds understate memory for population size and the STIs (Q3 below). |

Everything else in cycle 3 stands. That includes the cold-start times, the
bias at year 70, and "the calibrated parameters fit the x0 model", since
the calibration restarted from `restart-hpc.rds` and its −1.1% network.

## Question by question

### 1. Is a same-parameter restart seamless?

**Yes, at the resolution of 256 runs** ([c4_03](c4_03_restart_law.md)).

- **Weekly.** The restart week is an ordinary week. Its largest |z| (2.74)
  is reached or exceeded in 52% of the 206 other weeks; after the x0
  restart, z reached 23.5.
- **One-year changes.** No systematic change across the restart (global
  p = 0.63 over 66 variables).
- **Stationary law.** It is the cold-start law: p = 0.40 for means and
  0.43 for variances, energy p = 0.67; largest difference 0.08 SD_π. It is
  not the x0 law (p = 0.0005, prevalence +2.4 SD_π).

So restart points saved by consistent runs need **no burn-in for level
shifts**. The first-week jumps of cycle 2 were caused by x0's parameters.

### 2. How much variance does the restart state fix? (direct ICC)

Direct values, averaged over π ([c4_04](c4_04_icc_direct.md)), with the
lower bound of the same model in brackets:

| output | ICC |
|---|---|
| 20-year prevalence mean | **0.84** [0.81, 0.87] (LB 0.80) |
| 20-year diagnosed prevalence (B) | 0.86 (LB 0.81) |
| 20-year population size | 0.81 (LB 0.71) |
| population size, 30 years ahead | 0.49 (LB 0.17) |
| 20-year STI means | 0.43–0.57 (LB 0.29–0.37) |
| 20-year HIV incidence | 0.37 (LB 0.31) |
| 10-year cumulative incidence, years 6–15 | **0.25** [0.07, 0.40] (LB 0.15) |
| cascade and PrEP, 20-year means | 0.19–0.36 |

- **The lower bounds are close for HIV prevalence,** but they miss much of
  the memory of population size and the STIs. That memory likely sits in
  the age structure and the network.
- **Cycle 1's design rule,** the larger of the lower bound and the x0
  value, happened to give about the right values.

### 3. How long from one same-parameter point to full variance?

Direct, averaged over π. These replace cycle 2's lower bounds
([c4_04](c4_04_icc_direct.md)). Years until the runs of one point show
≥ 90% of the stationary variance:

| output | years |
|---|---|
| prevalence (annual) | **51** [44, 200] |
| 20-year prevalence windows (burn-in) | 40 [34, 232] |
| population size | 76 [55, 557] |
| STIs | 24–34 |
| diagnosed fraction | 14 |
| suppression | 5 |
| PrEP coverage | 2 |
| 10-year cumulative incidence (burn-in) | **24** [16, 124] |

For comparison:

- cycle 2's rigorous lower bounds were ≥ 50 and ≥ 10 years;
- the x0 point with other parameters needed 73 and 31 years (cycles 1–2).

### 4. How many points, and how should runs be assigned?

[c4_05](c4_05_pool_design.md).

- **The actual 32-point pool gives the stationary spread from year 1,** and
  its mean errors are those of a random pool. By chance it is
  under-dispersed in the diagnosed fraction (59% of the variance in year 1).
  That is the case for stratified sampling of points.
- **A pool caps the effective number of runs at k / ICC,** whatever N.
  With 32 points the cap is about 38 effective runs for 20-year
  prevalence, and about 129 for 10-year cumulative incidence.
- **Randomised assignment wastes precision for levels.** With 256 runs
  drawn with replacement from 256 points, the MCSE of 20-year prevalence is
  still 1.36× that of independent points. Balanced assignment of ≈ 205
  points (0.8 N) is needed for ≤ +10%.
- **For the intervention outcome** (cumulative incidence, N = 32 per
  scenario):
  - 18 balanced points give ≤ +10%;
  - the actual design (32 points, randomised) gives 1.11, i.e. 26
    effective runs of 32;
  - a single point would give 2.95, i.e. 4 effective runs.
- **Burn-in with k points.** With ≥ 16 stationary points no burn-in is
  needed for ≥ 90% of the variance of any output. With 8, about 12 years
  for prevalence.

## The overall aim of the brief, answered across cycles 1–4

| question | answer | source |
|---|---|---|
| Single restart point or pool? | **Pool.** One point fixes 84% of the between-run variance of 20-year prevalence and 25% of 10-year cumulative incidence, and needs ≈ 50 (prevalence) / ≈ 25 (incidence) years of burn-in to recover the variance | c4_04 |
| How to make the points | Independent cold-start chains, states saved ≥ 120 years after the cold start (the current pool: year 600). Same parameters and network as the research runs. Random, optionally stratified on the slow state | c3_04, c3_05, c4_03, cycle 1 `07` |
| How large | Levels of slow outputs: ≈ 0.8 N balanced points. Intervention outcome at N = 32: ≥ 18 balanced, or the current 32 randomised (26 effective runs) | c4_05 |
| How the number of runs depends on the pool | Effective runs = N / (1 + ICC (n − 1)) with n = N / k runs per point. They can never exceed k / ICC, whatever N: 38 (20-year prevalence) and 129 (cumulative incidence) for 32 points | c4_05 |
| Burn-in after restarting from the pool | None for levels. None for the variance with ≥ 16 points | c4_03, c4_05 |
| Calibration runs from a restart | 70 years forgets the point (ICC of year-70 targets ≈ 0) | c4_05; cycle 2 |

## What changes in the recommendations

1. **Check every restart file before using it:** compute the C3-M0
   offsets. They should be 0 in all networks.
   - `restart-hpc.rds` fails, at −0.011: runs from it simulate a model with
     1.1% fewer ties.
   - The current `restart_pool.rds` passes.
2. **Recalibrate under the model the runs actually simulate** (local
   netest, pool restarts). The current parameters were fitted under x0's
   network (cycle 3, c3_03).
3. **Keep the current pool design for intervention runs,** or make it
   balanced: exactly one or two runs per point, which needs a batch offset
   for the restart index in EpiModelHPC. For level estimates with many
   runs, build ≈ 0.8 N points.
4. **Stratify the points** on prevalence and population size when building
   a pool, so that a single pool is not under-dispersed by chance.
5. **The effect heterogeneity check remains** (cycle 2): the same pool with
   two scenarios, e.g. 32 points × 4 runs × baseline and one intervention.

## Inputs for the next phase

| input | value | source |
|---|---|---|
| design ICC, 20-year prevalence mean | 0.84 [0.81, 0.87] | c4_04 |
| design ICC, 10-year cumulative incidence | 0.25 [0.07, 0.40] | c4_04 |
| one-point burn-in for 90% variance | prevalence 51 y, 20-year windows 40 y, cumulative incidence 24 y, population 76 y | c4_04 |
| points for MCSE ≤ +10% | cumulative incidence: 18 (N = 32), 139 (N = 256) balanced | c4_05 |
| reference data | `data/run/restart_assessment/cycle4/c4_01_annual_pool.rds` (runs, points, seam data); `c4_04_icc.rds` | c4_01, c4_04 |

## Open issues

1. **Effect heterogeneity across restart points** is still unmeasured. It
   decides the pool size for intervention *effects*.
2. **The ICCs are for the local-netest model.** For x0's model they are
   similar (c3_06) but not measured directly.
3. **Precision.** 32 points give ICC CIs of ±0.02 (ICC ≈ 0.9) to ±0.15
   (ICC ≈ 0.3), about 88% coverage. Beyond ≈ 60 years `icc_w` is only
   resolved to ±0.2.
4. **A small first-year dampening of demographic noise** after a restart
   cannot be excluded (variance ratios 0.70–0.80 for population size and
   prevalence, CIs from 32 clusters). It is second order.
