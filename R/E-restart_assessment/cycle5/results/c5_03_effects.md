# C5-03. Effects of three forward scenarios, and how much they depend on the restart point

## Question

For S1 (HIV testing odds × 2), S2 (PrEP initiation odds × 2) and S3 (STI
screening odds × 3), each applied from year 6:

- how large is the effect?
- how much does it vary between restart points? This is the effect
  heterogeneity σ_e, and the effect ICC;
- is that variation what a proportional effect predicts?
- which pool design does it imply?

This is the open issue of cycles 2–4 ([SCENARIOS.md](../../SCENARIOS.md)
§3.4).

## Method

[c5_METHODS.md](c5_METHODS.md) C5-M2 and C5-M3. Script: `c5_03_effects.R`.

- **Design.** Every scenario and the baseline start from the same 32
  points, with 4 runs per point and arm.
- **Effects** are measured within points and averaged over points.
- **Heterogeneity.** The spread of the 32 point-level effects, beyond what
  chance after the restart explains.

Note on sizes: with 128 runs per arm, the SEs here are half those of a
32-run project design.

## Results

### 1. The average effects

Source: `tables/c5_03_effects.csv`, `figures/c5_03_effects.png`. Share of
events averted over years 6–15 (PIA), paired SE:

| outcome | S1, testing × 2 | S2, PrEP × 2 | S3, STI screening × 3 |
|---|---|---|---|
| HIV infections, total | **1.1%** (SE 0.25) | **22.5%** (0.21) | **5.9%** (0.24) |
| Black MSM | 1.1% (0.23) | 20.4% (0.21) | 4.7% (0.23) |
| Hispanic MSM | 1.5% (0.86) | 25.8% (0.74) | 8.6% (0.71) |
| White MSM | 1.1% (0.40) | 29.7% (0.32) | 9.6% (0.43) |
| gonorrhoea infections | −1.1% (0.95) | 20.4% (0.91) | **57.7%** (0.96) |
| chlamydia infections | −1.6% (0.61) | 20.3% (0.64) | **58.1%** (0.52) |
| syphilis infections | −3.7% (1.67) | 7.0% (1.68) | −0.4% (2.09) |

- **The effects are what the mechanisms predict.** S3 reduces HIV by 5.9%
  only through gonorrhoea and chlamydia, which raise HIV transmission in
  the model. S3 does not reach syphilis (c5_01).
- **Year-15 values** (same table, "absolute" rows). HIV prevalence falls by
  0.08 pp (S1), 2.1 pp (S2) and 0.55 pp (S3). The diagnosed fraction rises
  by 1.8 pp (S1) and 7.1 pp (S2).

### 2. How much the effect varies between restart points

Source: `tables/c5_03_effects.csv`, `figures/c5_03_heterogeneity.png` and
`figures/c5_03_point_effects.png`.

σ_e is the SD of the PIA between restart points, in percentage points (pp),
with its 95% CI and the test of no heterogeneity:

| outcome | S1 | S2 | S3 |
|---|---|---|---|
| **HIV infections, total** | 0.58 [0, 1.39], p = 0.22 | 0.20 [0, 1.10], p = 0.43 | 0.63 [0, 1.40], p = 0.17 |
| Black MSM | 0 [0, 1.15] | 0 [0, 1.02] | 0.16 [0, 1.18] |
| Hispanic MSM | 2.5 [0, 5.1] | 1.8 [0, 4.2] | 1.4 [0, 3.9] |
| White MSM | 1.0 [0, 2.3] | 0.6 [0, 1.7] | 1.5 [0, 2.7], **p = 0.036** |
| gonorrhoea | 1.5 [0, 5.1] | 0 [0, 4.6] | 3.2 [0, 5.9], **p = 0.047** |
| chlamydia | 1.5 [0, 3.5] | 1.7 [0, 3.7] | 1.3 [0, 2.9] |

- **No clear heterogeneity.** Of the 21 tests (these outcomes plus syphilis, in the csv), 2 have p < 0.05, about the 1 in
  20 expected by chance.
- **For total HIV infections, heterogeneity is at most ≈ 1.1–1.4 pp** (upper
  95% limits). The point bootstrap gives slightly lower limits,
  0.76–1.17 pp.
- **The effect ICC is small:** 0.005–0.06 for total HIV infections, and at
  most 0.12 for any outcome. The restart point decides at most a few percent
  of the variance of a paired difference.
- **The two p < 0.05 results are explained by proportionality:**
  - **S3 gonorrhoea.** A proportional effect of 58% predicts σ_e = 3.4 pp
    from the baseline's between-point spread alone. The estimate is 3.2 pp.
    Points with more gonorrhoea avert more cases, in proportion, and the
    *relative* effect does not depend on the point's gonorrhoea level
    (p = 0.96, [c5_04](c5_04_sti_threshold.md)).
  - **S3 White MSM** (p = 0.036). This is plausible, since S3 acts on HIV
    through the STIs, whose levels differ between points. But it is
    isolated.
  - Across all 33 outcome × scenario pairs, the proportional prediction lies
    inside the CI (`prop_in_ci`).
- **Effects on annual values** (`tables/c5_03_by_year.csv`): for S1 and S2
  the yearly heterogeneity test is at its nominal rate (0–10% of years with
  p < 0.05). For S3 it is 20–30% of years (HIV prevalence and incidence,
  gonorrhoea), from correlated yearly tests. This is weak support for a
  small S3 heterogeneity.

### 3. Does the effect depend on the point's initial state?

Source: `tables/c5_03_state_dependence.csv`. The absolute point-level effect
(relative to the overall mean) regressed on one predictor chosen in advance:

| scenario | predictor | slope (pp per SD) | p | R² |
|---|---|---|---|---|
| S1 | undiagnosed share of the state | 0.15 (SE 0.25) | 0.57 | 0.01 |
| S2 | HIV prevalence of the state | 0.10 (0.22) | 0.65 | 0.01 |
| S3, gonorrhoea | gonorrhoea prevalence of the state | −2.2 (0.9) | 0.02 | 0.16 |

The S3 slope is the proportionality above, not a change in the relative
effect ([c5_04](c5_04_sti_threshold.md)).

### 4. Level ICC of the baseline arm

Source: `tables/c5_03_baseline_level_icc.csv`.

- **The ANOVA ICC** of 10-year cumulative incidence is 0.08. Cycle 4 found
  0.25 [0.07, 0.40].
- **`icc_w` is −0.14.** In this arm, the within-point variance exceeds
  cycle 4's equilibrium variance by 14%.
- **This is sampling noise, not a model difference.** In cycle 4's own 256
  runs, the variance of a 10-year sum is 35,800 over years 6–15 and 45,200
  over years 1–10. A 128-run arm is within that range.
- **The level ICC stays cycle 4's value.** The effect results do not depend
  on it.

### 5. Consequences for the design

Source: `tables/c5_03_design_rmse.csv`. Error of the PIA for N = 32 runs per
scenario, in pp, from the measured variances, under the designs of
SCENARIOS.md §4.2:

| outcome, scenario | paired, 8 points (current) | paired, 32 points | random, 32 points | 8 / 32 at the upper limit of σ_e |
|---|---|---|---|---|
| HIV infections, S1 | 0.49 | 0.46 | 0.52 | 1.30 |
| HIV infections, S2 | 0.42 | 0.42 | 0.47 | 1.24 |
| HIV infections, S3 | 0.49 | 0.45 | 0.51 | 1.32 |
| gonorrhoea, S3 | 1.93 | 1.66 | 2.72 | 1.39 |

- **At the estimated heterogeneity,** the current design (8 recycled points,
  paired) is within 1–9% of pairing on all 32 points for HIV infections.
  S3's gonorrhoea is within 16%.
- **At the upper 95% limit of σ_e,** the current design could be up to
  24–39% worse than 32 paired points.
- **Randomising the points** (`randomize.restart = TRUE`) is worse than the
  current design for almost every outcome:
  - 4–11% for total HIV infections;
  - 3–51% for STI infections;
  - a factor 2.0–2.3 for year-15 prevalence.
  - **The exception is Hispanic MSM** (2–6% better). Their effects are the
    most heterogeneous point estimates (σ_e 1.4–2.5 pp), so more points pay
    off there.

  These ratios use the between-point variance of this arm, which
  understates cycle 4's ICC (section 4). With ICC 0.25 the advantage of
  pairing is larger.

## Interpretation

1. **The restart point hardly changes intervention effects.** For three
   different mechanisms, the effect on 10-year HIV infections varies between
   restart states by at most ≈ 1–1.4 pp (95% upper limits). The point
   estimates are 0.2–0.6 pp. The variation is compatible with effects that
   are proportional to the level.
   - **In epidemiological terms:** an intervention that averts 22.5% of
     infections from one restart state averts about 22.5% from the others.
   - This supports cycle 2's proportional-effect model (C2-M6).
2. **For effects, pairing matters more than the number of points.**
   - Pairing arms on the same points removes the between-point part of the
     level. That part is small for cumulative incidence, larger for the
     STIs, and dominant for prevalence.
   - Using more points only protects against a heterogeneity that has not
     been found.
3. **The current intervention design is adequate for effects:** 8 recycled
   points, paired, 4 runs each. Pairing on all 32 points (batches of 32)
   is a cheap insurance against the heterogeneity that cannot be excluded
   (+24–39% worst case).
4. **Do not switch to `randomize.restart = TRUE` for scenario runs.** It
   loses the pairing, and costs more than it gains for all outcomes but
   Hispanic MSM, where it gains at most 6%. Pairing on all 32 points gets
   both benefits.
5. **Groups with few infections are the exception.** For Hispanic MSM the
   CIs of σ_e reach 4–5 pp. Their effects rest on about 350 infections per
   run, so both chance and a possible heterogeneity are larger.

## Decision / input for next steps

- **Design rule for intervention effects:** pair all scenarios on the same
  points, used equally often. Use all pool points when batches allow.
- **Report the PIA with its paired SE** (point-level differences), not the
  spread of per-run PIAs.
- **The level ICC stays cycle 4's value** (0.25 for 10-year cumulative
  incidence).

## Caveats and deviations

- **Three scenarios, one horizon (10 years), one dose each.** Larger
  interventions or longer horizons may behave differently (see
  [c5_05](c5_05_relaxation.md) for the horizon).
- **Power.** With 32 points the heterogeneity test detects σ_e ≈ 1 pp only
  about 7 times in 10 ([c5_02](c5_02_validate.md)). The conclusions rest
  on the CIs.
- **Heterogeneity is assessed on 21 relative and 12 absolute
  outcome × scenario pairs,** without a multiplicity correction. The two p < 0.05 results are read in
  that light.
