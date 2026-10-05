# C5-05. A sustained change from the restart: relaxation and horizon

## Question

S4 lowers the number of sexual acts by 10% from the restart
(`acts.scale` = 0.9). It stands for an "alternative world" scenario
([SCENARIOS.md](../../SCENARIOS.md) §5–6), which the baseline pool does not
fit.

- How long until the runs reach their new equilibrium?
  - SCENARIOS.md predicted about 80–100 years for prevalence, from the x0
    example.
- What share of the long-run effect is present after 10, 20 and 50 years?
  - The rough guide was about 28% at 10 years for prevalence.
- Does the effect heterogeneity between restart points fade with the
  horizon, as SCENARIOS.md §3.4 argued?

## Method

[c5_METHODS.md](c5_METHODS.md) C5-M5. Script: `c5_05_relaxation.R`.

- **Baseline.** The 256 cycle 4 pool runs, from the same 32 points, cut to
  150 years.
- **Effect.** Δ(h) is paired by point, at every year h.
- **Long-run effect Δ_∞:** the mean of Δ(h) over years 101–150.
- **Relaxation times:** fitted, then bootstrapped over points (200 draws).

## Results

### The effect over time

Source: `tables/c5_05_relaxation.csv`, `figures/c5_05_effect_trajectory.png`.

| variable | long-run effect | share at 10 y | at 20 y | at 50 y | T(0.2 SD) | T(0.1 SD) |
|---|---|---|---|---|---|---|
| HIV prevalence | **−4.3 pp** (0.254 → 0.212) | **21%** [20, 22] | 43% | 85% | 95 [82, 107] y | **109** [91, 124] y |
| prevalence, Black MSM | −5.6 pp | 21% | 43% | 85% | 91 y | 104 y |
| prevalence, Hispanic MSM | −3.9 pp | 21% | 44% | 84% | 81 y | 93 y |
| prevalence, White MSM | −2.8 pp | 21% | 43% | 85% | 96 y | 110 y |
| HIV incidence rate | −0.27 per 100 PY | 66% | 76% | 93% | 57 y | 73 y |
| gonorrhoea prevalence | −1.8 pp | 66% | 82% | 95% | 65 y | 81 y |
| chlamydia prevalence | −2.3 pp | 72% | 87% | 97% | 52 y | 65 y |
| syphilis prevalence | −1.5 pp | 65% | 80% | 94% | 60 y | 80 y |
| diagnosed fraction | −0.3 pp | **opposite sign** | opposite sign | 23% | 82 y | 96 y |
| population size | +120 (not significant at most years) | — | — | — | — | — |

T(δ) is the number of years until the effect stays within δ SD_π of its
long-run value. PY = person-years.

- **Prevalence moves slowly and steadily.**
  - The best-fitting curves are two exponentials or a damped cosine.
  - There is **no overshoot**, unlike the x0 transient.
  - The effect is still drifting slightly over years 101–150 (−0.14 pp per
    50 years), so T is a little understated.
- **Incidence and the STIs react fast, then follow prevalence.** Two-thirds
  of the effect on HIV incidence appears within 10 years, and the rest
  follows the slow decline of prevalence.
- **The diagnosed fraction reverses.** With fewer new infections, the
  infected population ages into diagnosis, so the diagnosed fraction first
  *rises* (+2.8 SD_π at about 10 years). It then falls below the baseline
  (−1.2 SD_π) as prevalence settles.
- **Population size** changes little and noisily: +120 on about 100,000,
  and 0.4 SD_π at most.

### Heterogeneity by horizon

Source: `tables/c5_05_heterogeneity_summary.csv`,
`figures/c5_05_heterogeneity_by_year.png`. The SD of the effect between
restart points, in SD_π units, averaged by period, with the share of years
where the heterogeneity test gives p < 0.05:

| variable | 1–5 y | 6–10 y | 11–20 y | 21–50 y | 51–100 y | 101–150 y |
|---|---|---|---|---|---|---|
| HIV prevalence | 0.03 (0%) | 0.08 (0%) | 0.16 (0%) | 0.07 (0%) | 0.00 (0%) | 0.08 (0%) |
| prevalence, White MSM | 0.06 (0%) | 0.20 (**100%**) | 0.25 (**50%**) | 0.06 (0%) | 0.00 (0%) | 0.08 (0%) |
| HIV incidence rate | 0.03 (0%) | 0.24 (20%) | 0.11 (0%) | 0.13 (0%) | 0.11 (4%) | 0.12 (8%) |
| population size | 0.10 (**40%**) | 0.21 (**60%**) | 0.20 (0%) | 0.41 (**67%**) | 0.04 (0%) | 0.00 (0%) |
| syphilis prevalence | 0.19 (**60%**) | 0.28 (20%) | 0.15 (0%) | 0.16 (0%) | 0.39 (**40%**) | 0.32 (**28%**) |

- **For HIV prevalence, the effect hardly depends on the restart point at
  any horizon.**
  - The SD between points is ≤ 0.16 SD_π, against an effect of −12 SD_π at
    the end. That is at most about 1% of the effect.
  - No year has p < 0.05.
- **Where heterogeneity appears, it is early, and it fades:**
  - White MSM prevalence, years 6–20;
  - population size, years 1–50. Population memory sits in the age
    structure (c4_04), and vanishes after 50 years here.
- **Syphilis is the exception.** Its heterogeneity persists up to 150 years.
  - Syphilis has the slowest STI mode (a 64-year component in cycle 1).
  - The S4 test is also slightly liberal ([c5_02](c5_02_validate.md)).

## Interpretation

1. **An alternative world needs about 100 years before prevalence
   settles.**
   - T(0.1 SD) is 109 [91, 124] years for prevalence, and 104–110 years for
     Black and White MSM. That is close to, and a little above, the 80–100
     years predicted from x0.
   - So the rule in SCENARIOS.md §6 holds: a scenario that changes the past
     needs its own pool or ≈ 100 years of burn-in.
   - **Shorter burn-ins leave prevalence visibly off** its new equilibrium
     (`tables/c5_05_heterogeneity_by_year.csv`): by 1.8 SD_π after 50
     years, 0.7–0.8 SD_π after 70 years (the calibration run length), and
     0.2 SD_π after 100 years.
2. **A 10-year window shows 21% of the long-run effect on prevalence,**
   slightly less than the rough guide of 28%. For incidence and the STIs it
   shows two-thirds.
   - A 10-year PIA is an early effect, as SCENARIOS.md §5.3 said. Its
     long-run counterpart is larger.
3. **Short-run effects can have the opposite sign to long-run effects:** see
   the diagnosed fraction above. Cascade outcomes read at 10 years can
   mislead about the long run.
4. **Effect heterogeneity is a short-horizon matter, and small.** This
   confirms SCENARIOS.md §3.4 for HIV. Syphilis keeps some state-dependence
   for longer.

## Decision / input for next steps

- **Burn-in for alternative-world scenarios:** ≈ 100 years for
  prevalence-type outputs, ≈ 70–80 years for incidence and the STIs. Or use
  a pool built under the scenario's parameters.
- **Horizon:** report 10-year effects as early effects. For long-run
  questions, run ≥ 100 years.

## Caveats and deviations

- **One change, of one size (−10% acts).** Relaxation times depend mostly
  on the model's slow modes, so they should carry over to other moderate
  changes. Larger ones may differ.
- **Δ_∞ comes from years 101–150 of the same runs.** Prevalence still
  drifts slightly there, so the T values are lower bounds.
- **The baseline is unbalanced** (1–15 runs per point), so heterogeneity
  CIs are about 92% rather than 95% ([c5_02](c5_02_validate.md)).
