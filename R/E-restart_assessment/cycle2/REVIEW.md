# Cycle 2 review: assumptions and conceptual soundness

**What this is.** A second pass over:

- the assumptions of the experiment, the brief and the project;
- the assumptions I made in cycle 1;
- whether the conclusions follow from the results.

Cycle 1 is left untouched in `../results/`. Every cycle 2 number comes from
a table in `results/tables/` and is detailed in the step reports
`results/c2_0N_*.md`. The side-by-side answers are in
[`results/SUMMARY_cycle2.md`](results/SUMMARY_cycle2.md).

**Verdicts:**

- ✓ holds;
- ✗ does not hold;
- ◐ holds only partly, or only in some settings;
- ? cannot be tested with this data.

## A. Assumptions about the experiment and the project

| # | Assumption (yours / the brief's) | Verdict | Evidence | Consequence |
|---|---|---|---|---|
| A1 | The 256 runs start from a single restart point | ✓ | First row identical in all chains. It matches `restart-hpc.rds` exactly ([c2_01](results/c2_01_provenance.md)) | – |
| A2 | The restart point comes from the model being run (same parameters, same version) | **✗** | x0 dates from 2026-05-20. 20 of 122 parameters differ, including chlamydia and syphilis natural history, HIV testing (±13–26%), Hispanic transmission (+23%), and STI screening absent ([c2_01](results/c2_01_provenance.md)) | **The experiment measures relaxation after a parameter change**, not "same-parameter point → full variance". Cycle 1's "x0 is atypical" is explained by this, not by chance |
| A3 | The restart is seamless | ? | First-week jumps in STIs (z up to 23), HIV incidence (+13% for one week) and suppression. They are consistent with parameters acting immediately. The attribute set is compatible | Needs a same-parameter restart check: 8 runs × 2 years |
| A4 | Every process remains active | ✗ | Syphilis extinct in 2 of 256 chains (cycle 1). The STI-ongoing filter rejects 3.2% of stationary states ([c2_05](results/c2_05_selection.md)) | Keep the filter. The π used here is quasi-stationary |
| A5 | Fixed parameters give a time-homogeneous Markov process | ✓ | `prep.start` = 0, `riskh.start` = −52, `sti.screen.prep.start` = 1 are all before the restart at step 2. Partner identification is off | – |
| A6 | A stationary law exists and matches the targets | ✓ | No drift (cycle 1). All race-specific targets are within ±1.23 SD_π of π ([c2_01](results/c2_01_provenance.md)) | `cc.prep` total differs (0.266 vs 0.203): a definition mismatch in the total target |
| A7 | Research runs are 20-year windows | ✗ | Intervention runs are 15 years (5 + 10). The outcomes are cumulative incidence over years 6–15 and year-15 incidence. Calibration runs are 70 years ([c2_02](results/c2_02_project_outcomes.md)) | Cycle 2 recomputes everything for these quantities |
| A8 | A pool of k points is used as k points | **✗** (defaults) | EpiModel recycles points 1…nsims within each `netsim` call, and EpiModelHPC calls `netsim` per batch of 8. **Only the first 8 points of any pool are used.** `randomize.restart = TRUE` draws with replacement instead ([c2_04](results/c2_04_design.md)) | Pool size is moot until this is changed |
| A9 | "Full variance" (the stationary spread) is the right target | ◐ | Right for the model's stochastic spread, which is tiny for the key outcomes: CV 1.9% for 10-year incidence, 1.4% for i.prev.dx.B. It does not include parameter uncertainty | The restart question concerns a few % of the outcome levels |
| A10 | "Select the best" restart point, or select close to the targets | ✗ (for HIV targets) | Selection = conditioning with exact targets. With realistic data error, conditioning ≈ random. Selected states regress to the mean within 10–20 years ([c2_05](results/c2_05_selection.md)) | Do not select on HIV targets. STI targets only with a data-error model |
| A11 | The brief's time-to-stationarity rule | ✗ | Over 30 replications it returns a median of 132 years for a series stationary from year 0 ([c2_03](results/c2_03_robustness.md)) | Replaced by fitted relaxation times (cycle 1 already did this) |
| A12 | The brief's random-walk check (S3) must be flagged | ✗ | S3's drift is ~3.4% per century, below the brief's 5% tolerance | Cycle 1 added S3b |

## B. My cycle 1 assumptions

| # | Assumption | Verdict | Evidence | Consequence for cycle 1 conclusions |
|---|---|---|---|---|
| B1 | x0 is a (possibly unlucky) state of this model | ✗ | A2 | The **mean** results (T_mean, level offsets) describe a parameter-change transient. The **variance** results describe variance recovery after that change |
| B2 | The direct ICC from x0 approximates the average ICC of a same-parameter point | ◐ | It sits above the same-parameter lower bound at most horizons (by 0.1–0.2 at 20–70 years), but *below* it in 6 cases ([c2_03](results/c2_03_robustness.md)) | Treat it as one state's value. For same-parameter points only the lower bound is rigorous |
| B3 | "The lower bound is always at or below the direct value" (cycle 1 `06` md) | ✗ | 99 of 297 pairs have LB > direct, 6 of them beyond the CI | Erratum (section D) |
| B4 | The estimand is the MCSE of mean *levels*, so k ≈ 0.7–0.8 N | ◐ | Right for levels of slow outputs over 20-year windows. The project reports per-run NIA/PIA against the baseline median | For the project's outcomes and effects, far fewer points are needed ([c2_04](results/c2_04_design.md)) |
| B5 | The fit-based times and their CIs | ◐ | Robust to the estimator (exponential, stretched exponential, isotonic) and to the π period. Nearly unbiased, but CI coverage is 0.83–0.90 ([c2_03](results/c2_03_robustness.md)) | Keep the times. Read the CIs as ~85–90% |
| B6 | Memory: τ_int ≥ 66 years, possibly much longer | ✓ (refined) | The variance–time curve flattens at 63 [53, 74] for L = 450. Chain means are normal, so there is no chain-level persistent component | τ_int ≈ 60–65 years |
| B7 | The lower bounds miss only unobserved state | ✓ | Nonlinear features add nothing (−0.001 to −0.004) | – |
| B8 | Selection experiment: π means as targets, extreme selection | ◐ | With the real targets and graded intensity, selection matters for prevalence (variance 0.65–0.86), not for 10-year incidence (≥ 0.94) | The cycle 1 conclusion holds for slow outputs. It is weaker for incidence outcomes |
| B9 | Pool recipe: k chains from x0 for 100–150 years | ✓ | Needed because x0 has other parameters: the mean imprint on prevalence lasts 80–100 years ([c2_02](results/c2_02_project_outcomes.md)) | For a same-parameter start, ≥ 50 years is the lower bound for prevalence variance |

## C. Conceptual points that change the reading

1. **Two different questions were mixed in cycle 1.**
   - **Variance recovery:** how long until runs from one point spread like
     π. This is intrinsic to the model's slow HIV mode (τ ≈ 25–30 years,
     τ_int ≈ 60–65 years). For a same-parameter point, it takes ≥ 50 years
     for prevalence and ≥ 10 years for 10-year cumulative incidence (rigorous
     lower bounds).
   - **Forgetting the restart's parameters:** how long until runs from a
     point made with *other* parameters are unbiased. This is what x0
     shows: 80–100 years for prevalence and 35–60 years for the STIs. It
     applies to every calibration wave that starts from a restart point.
   - Cycle 1 reported both under "full variance".
2. **Stochastic variance is small relative to the quantities of interest.**
   - The variability that the restart design controls:
     - 10-year cumulative incidence: CV 1.9% (total), 1.9% (B), 3.4% (W),
       6.0% (H);
     - diagnosed prevalence: 1.4–2.8%.
   - Intervention effects of 5–30% dwarf it. The restart design matters for
     how wide per-run intervals are, not for whether effects are detected.
3. **Levels and effects need different pools.**
   - Under a roughly proportional effect, the pool cancels in PIA. A single
     point is then unbiased for PIA and only narrows the per-run spread
     (1.7 → 1.5 pp).
   - What a single point cannot handle is **effect heterogeneity across
     restart states**. That becomes a problem above ~0.8 pp (N = 32) or
     ~0.3 pp (N = 256). It is untested and testable.
4. **Selecting states is conditioning, and conditioning needs a data-error
   model.** The model's own spread is 0.3–3% of the HIV target values. For
   any realistic surveillance uncertainty, correct conditioning leaves the
   pool unchanged, so closeness selection removes real variability.
5. **Calibration from a restart point needs long runs.** With 70-year runs,
   the calibration is essentially independent of the restart point (lower
   bound ≤ 0.01 and imprint ≤ 0.22 SD at year 70). Shortening the runs
   would evaluate the targets during the transient:
   - STI incidence biased by 3–23% at 10–20 years;
   - diagnosed prevalence by 0.6–1.0 SD at 20–50 years.

   The benefit of a restart for calibration is skipping the network and
   initialisation burn-in, not reducing noise.

## D. Errata for cycle 1

These cycle 1 statements should be read as corrected. The cycle 1 files are
left as they were, for comparison.

| Where (cycle 1) | Statement | Correction |
|---|---|---|
| `04` md, `SUMMARY` "Why it takes so long" | "x0 is atypical" (with no cause) | x0 was produced with other parameters (A2). The level offsets are a parameter-change transient |
| `06` md, Interpretation | "The ridge lower bound is always at or below the direct single-x0 value" | False in 99 of 297 pairs (6 beyond the CI). The direct value is for one state and is not an upper bound |
| `SUMMARY` Q1 | "About 70 years … The mean needs 80–100 years", as the time from *a* restart point | This holds for a point made with other parameters. For a same-parameter point: ≥ 50 years (rigorous) for prevalence variance, no mean bias beyond the ICC, and ≥ 10 years for 10-year cumulative incidence |
| `SUMMARY` Q3, `07` md | "k ≈ 0.7–0.8 N points" | Holds for levels of slow outputs. For the project's outcomes, 8 points already leave a variance deficit ≤ 3%. For PIA, the number depends on effect heterogeneity (C3). Pools of more than 8 points are not used by the current code (A8) |
| `SUMMARY` Q4, `07` md | "Closeness selection cuts the between-run variance to 62% / 40%" | Holds for 20-year prevalence windows under extreme selection. For 10-year cumulative incidence it is 0.94–0.99 |
| `05` md | τ_int for prevalence "≥ 66 (lower value)" | ≈ 60–65 years (the variance–time curve flattens) |
| `02`, `04` md CIs | 95% bootstrap CIs for fitted times | Actual coverage is ~0.83–0.90 |
| `01` md | "Weekly x0 values … annual means of year 1 already differ from them (e.g. chlamydia)" | The difference is the immediate effect of the parameter change (first-week jumps) |

## E. What stays as it was

- The stationary law exists, the drift tests are fine, and the syphilis
  extinction handling is fine.
- The estimators are validated. Time to full variance from x0 is robust to
  the estimator and to the π period.
- A pool of points drawn from π removes the burn-in (deficit ICC/k ≤ 1/k).
- Build pools from independent chains after a long burn-in, under the
  final parameters.
- Stratified random sampling is the only selection that helps.
- The slow HIV prevalence mode sets all the long time scales.
