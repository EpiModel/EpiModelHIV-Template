# C3-05. What the cold-start transient means for the workflow

## Question

**(a) Ballpark calibration** (`swfcalib_config_ballpark.R`,
`swfcalib_model.R`). Runs start cold and their targets are read in the
last year of a 70-year run. How biased is each target, and how long must
the runs be?

**(b) Restart points taken at year B of cold-start runs.** The September
pool of `3-choose_restart.R` was taken at B = 70. For runs started from
such points:

- how biased and how spread are the research outcomes (10-year cumulative
  incidence, year-15 values, 20-year windows)?
- which B is needed?
- how does this compare with restarting from x0?

## Method

[c3_METHODS.md](c3_METHODS.md) C3-M3, C3-M4. Script: `c3_05_workflow.R`.

- **Reference.** Each experiment is taken against its own π (c3_03).
- **Grid.** B = 0–250, with 500 chain bootstraps.
- **Burn-in needed.** B(δ) comes from the fitted offset curve (tail
  window), with 200 bootstrap refits.

## Results

### (a) Calibration targets after T years from a cold start

`tables/c3_05_calib_bias.csv`. Bias of the target against π_cold, % [95%
CI]:

| target | T = 30 | T = 50 | T = 70 | T = 100 | T = 150 |
|---|---|---|---|---|---|
| i.prev.dx.B | +19.2 | +4.8 [4.6, 4.9] | +1.34 [1.18, 1.50] | +0.26 [0.09, 0.43] | +0.11 [−0.07, 0.27] |
| i.prev.dx.H | +38.3 | +10.0 | +2.97 [2.44, 3.48] | +0.65 [0.10, 1.18] | −0.07 |
| i.prev.dx.W | +38.9 | +11.4 | +3.43 [3.16, 3.77] | +0.45 [0.14, 0.76] | +0.08 |
| cc.dx.B / H / W | +2.9 / +3.9 / +2.5 | +0.6 / +1.1 / +0.8 | +0.15 / +0.27 / +0.31 | ≤ 0.09 | |
| cc.vsupp.B / H / W | −1.9 / −2.4 / −1.5 | −0.6 / −0.8 / −0.6 | −0.13 / −0.18 / −0.15 | ≤ 0.07 | |
| ir100.gono / chla / syph | +9.5 / +6.6 / −0.4 | +2.0 / +1.8 / −4.3 | +0.4 / +0.5 / −0.7 (CIs include 0) | | |
| cc.prep.B / H / W | −1.5 / −1.3 / −0.7 | −0.5 / −0.3 / −0.2 | −0.10 / −0.04 / −0.10 | | |
| disease.mr100 | +19.8 | +8.4 | +1.9 [0.2, 3.4] | +1.1 | |
| ir100.hiv.dx.B / H / W | +6.7 / +12.2 / +15.9 | +1.7 / +4.9 / +4.3 | +0.3 / 0.0 / +1.1 | | |

**Gap to the target value at T = 70.** This adds the transient to
π_cold's own gap (c3_03): i.prev.dx.B +4.3%, H +8.4%, W +10.2%;
ir100.gono +16.9%, chla +18.6%, syph +28.8%.

**Run length for a transient bias ≤ 1%** (`tables/c3_05_calib_run_length.csv`):

- i.prev.dx: 76 [73, 78] (B), 89 [83, 100] (H), 90 [85, 95] (W) years;
- ir100.syph: 85 [81, 109] years;
- cc.dx and cc.vsupp: 43–60 years;
- ir100.gono / chla: 59 / 50 years.

Figure: `figures/c3_05_calib_bias.png`.

### (b) Research outcomes of runs started from a state of age B

`tables/c3_05_research_summary.csv` (every B:
`tables/c3_05_research_windows.csv`):

| outcome | cold start, B = 70: offset | cold start, B = 70: variance ratio | x0, B = 0 (current): offset | x0, B = 0: variance ratio |
|---|---|---|---|---|
| cumulative incidence, years 6–15 | +0.05% [−0.20, 0.28] | 0.96 [0.82, 1.10] | +2.09% [1.86, 2.31] | 0.75 [0.61, 0.87] |
| same, Black MSM | −0.02% [−0.24, 0.19] | 0.90 | +2.10% | 0.70 |
| same, White MSM | +0.32% [−0.07, 0.73] | 1.06 | +2.38% | 0.89 |
| HIV incidence rate, year 15 | +0.38% [−0.15, 0.97] | 0.97 | +2.04% | 0.96 |
| prevalence, year 15 | +0.51 SD (+0.72%) | 1.02 | +0.85 SD (+1.27%) | 0.30 |
| i.prev.dx.B, year 15 | +0.49 SD (+0.65%) | 0.97 | +0.41 SD (+0.57%) | 0.27 |
| i.prev.dx.W, year 15 | +0.51 SD (+1.32%) | 1.09 | +0.86 SD (+2.39%) | 0.33 |
| 20-year prevalence mean | +0.71 SD (+0.94%) | 1.01 | +0.59 SD (+0.84%) | 0.14 |
| 20-year dx_frac mean | +0.51 SD (+0.10%) | 0.86 | −0.58 SD (−0.11%) | 0.59 |
| 20-year chlamydia mean | +0.20 SD (+0.96%) | 0.88 | +0.17 SD (+0.97%) | 0.43 |

**Spurious trend inside the 20-year window at B = 70, cold start.** The
mean change over the window is −0.71 SD_π [−0.83, −0.59] for prevalence
and −0.43 for dx_frac. The within-window variance of prevalence is 1.26
[1.08, 1.46] times the stationary one.

**Burn-in needed** (`tables/c3_05_burnin_needed.csv`), in years since the
start:

| outcome | cold, 0.1 SD | cold, 0.2 MCSE (N = 32) | cold, 1% of level | x0, 0.1 SD | x0, 1% of level |
|---|---|---|---|---|---|
| cumulative incidence, total | 70 [66, 72] | 78 [75, 82] | 42 [40, 43] | 37 [31, 89] | 14 [10, 18] |
| cumulative incidence, B | 72 [55, 79] | 89 [66, 90] | 47 [45, 49] | 30 [27, 77] | 14 [10, 17] |
| cumulative incidence, H | 37 [33, 39] | 42 [39, 53] | 33 [20, 36] | 17 [0, 73] | 14 [0, 20] |
| cumulative incidence, W | 81 [68, 99] | 110 [90, 138] | 50 [43, 57] | 49 [39, 143] | 30 [20, 38] |
| incidence, year 15 | 63 [49, 84] | 102 [76, 162] | 39 [35, 44] | 36 [31, 47] | 23 [18, 27] |
| prevalence, year 15 | 112 [88, 168] | 159 [101, 766] | 64 [61, 67] | 68 [58, 148] | 34 [30, 40] |
| i.prev.dx.B, year 15 | 111 [87, 191] | 158 [100, 507] | 61 [58, 64] | 68 [57, 112] | 33 [29, 38] |
| 20-year prevalence mean | 120 [94, 208] | 167 [106, 917] | 69 [66, 72] | 74 [63, 133] | 39 [34, 44] |

Figures:

- `figures/c3_05_research_offset.png` and
  `figures/c3_05_research_var_ratio.png`: both starts, every B.

## Interpretation

1. **The ballpark calibration reads diagnosed prevalence during the
   transient.**
   - **At year 70.** The targets are 1.3% (B) to 3.4% (W) above the
     cold-start equilibrium, 0.7–1.3 SD_π
     (`tables/c3_04_bias70.csv`). Fitting them there pushes
     transmission down, so the fitted model settles 1–3% below its targets
     once the transient is over.
   - **Run lengths.** It takes 76–90 years to get within 1%. STI, PrEP and
     suppression targets are fine at 70 years (≤ 0.7%, CIs include 0).
   - **Scale.** This is a bias of the *ballpark* stage. Later waves restart
     from pools, and for them cycle 2 found 70 years enough.
2. **A pool of year-70 states from cold starts is adequate for the
   intervention outcome, not for prevalence.**
   - **Cumulative incidence.** Runs from such states give the 10-year
     cumulative incidence without bias (+0.05%) and with the stationary
     spread (0.96). That is better than the current single x0 (+2.1%, SD
     ratio 0.87).
   - **Prevalence-type outcomes.** They are still +0.5–0.7 SD high and
     falling. A 20-year run from such a state shows a spurious decline of
     0.7 SD, and 26% more within-run variance than a stationary run.
   - **Why.** Incidence forgets the cold start in ≈ 40–70 years;
     prevalence needs ≈ 110–120.
3. **Why the cold start is slower than x0.** It starts from a much more
   distant state (c3_04). With x0, 1% accuracy on cumulative incidence
   comes after 14 years and 0.1 SD after ≈ 37; from a cold start it takes
   42 and 70.
   - **The spread differs.** At B = 0, the x0 runs, which share one state,
     have a variance deficit (SD ratio 0.87 for cumulative incidence). The
     cold-start runs at B = 70 do not (0.96).
   - **The catch.** x0 is not an option for the current model: it has
     other parameters (cycle 2) and another network (c3_01, c3_03).
4. **The MCSE criterion** (bias ≤ 0.2 MCSE) is stricter still:
   - for 32 runs per scenario it needs ≈ 80–110 years for cumulative
     incidence and ≈ 160 for prevalence outcomes;
   - the upper CIs are long.

## Decision / input for next steps

- **Ballpark calibration:**
  - either run 90 years instead of 70 when diagnosed prevalence is a
    target;
  - or treat the ballpark as approximate and rely on the pool waves.
- **Pool built from cold starts:**
  - save states at B ≥ 120 years for prevalence-type research outcomes;
  - B ≥ 70–80 years is enough for cumulative incidence and incidence rates;
  - independent chains give the full spread, so no single-point variance
    deficit remains.
- **These times** are for this cold-start initialisation. A start closer to
  π would shorten them (SUMMARY).

## Caveats and deviations

- **The target value of a run** is its annual ratio of aggregates in year
  T. `swfcalib_model.R` averages weekly ratios over the last 52 weeks; the
  difference is second order (cycle 2).
- **Research runs from a saved state** are assumed to continue exactly like
  the chain they come from. With the September pool this holds only if the
  pool was built with the same network estimate as the runs (c3_01).
- **Effects (PIA/NIA)** are not in this data. For relative effects the
  level offsets largely cancel (cycle 2, C2-M6). The spurious prevalence
  trend does not cancel if the effect depends on prevalence.
