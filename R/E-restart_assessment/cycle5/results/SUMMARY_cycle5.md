# Summary of cycle 5: scenarios run from the pool

Cycles 1–4 measured restart memory for **levels**, with one scenario: the
baseline. [SCENARIOS.md](../../SCENARIOS.md) then argued that intervention
**effects** behave differently. It made predictions it could not test:

- pairing scenarios on the same restart points cancels most of the point's
  influence;
- what remains is effect heterogeneity, likely small;
- sustained changes take decades to show their full effect.

Cycle 5 tests those predictions with four scenarios, all started from the
32-point pool with 4 runs per point and scenario, on the HPC on 2026-09-28:

| scenario | change | runs |
|---|---|---|
| baseline | none | 128 × 15 years |
| S1 | HIV testing odds × 2 from year 6 | 128 × 15 years |
| S2 | PrEP initiation odds × 2 from year 6 | 128 × 15 years |
| S3 | STI screening odds × 3 from year 6 | 128 × 15 years |
| S4 | 10% fewer sexual acts from the restart | 128 × 150 years, against the 256 cycle 4 runs |

Every number below comes from a table in `tables/`, cited in the linked
step reports.

## Question by question

### 1. Did the scenarios work as intended?

**Yes, with one qualification** ([c5_01](c5_01_prepare.md)).

- Every run started from the intended point, 4 runs per point and scenario.
- Before year 6, all arms match the baseline. After it, each moves its
  target:
  - S1: diagnoses +5%;
  - S2: PrEP coverage +58%;
  - S3: gonorrhoea and chlamydia −58%.
- **S3 did not change syphilis.** In this model version, syphilis screening
  has its own parameters (`syph.screen.*`), which S3 left at their defaults.

### 2. How large are the effects?

Share of HIV infections averted over years 6–15, with paired SEs
([c5_03](c5_03_effects.md)):

| scenario | PIA |
|---|---|
| S1, testing × 2 | 1.1% (SE 0.25) |
| S2, PrEP × 2 | 22.5% (0.21) |
| S3, STI screening × 3 | 5.9% (0.24), through gonorrhoea and chlamydia |

S2 also finds undiagnosed HIV and treats STIs, through the quarterly PrEP
visits.

### 3. Does the effect depend on the restart point? (the open question of cycles 2–4)

**Hardly** ([c5_03](c5_03_effects.md), [c5_04](c5_04_sti_threshold.md)).

- **The SD of the PIA between restart points** (effect heterogeneity σ_e),
  for total HIV infections:

  | scenario | σ_e | 95% CI |
  |---|---|---|
  | S1 | 0.58 pp | [0, 1.39] |
  | S2 | 0.20 pp | [0, 1.10] |
  | S3 | 0.63 pp | [0, 1.40] |

  None is significant.
  - The effect ICC is 0.005–0.06: the restart point decides only a few
    percent of the variance of a paired difference.
- **What variation there is, a proportional effect predicts.**
  - An intervention that averts 22.5% of infections from one restart state
    averts about 22.5% from the others.
  - For all 33 outcome × scenario pairs, the proportional prediction lies
    inside the CI.
- **No threshold effect for the STIs within 10 years.**
  - S3 pushes gonorrhoea and chlamydia to 0.2–0.4% prevalence, far below the
    equilibrium range.
  - No run goes extinct, and the share averted does not depend on the
    state's initial STI level (p = 0.96 for gonorrhoea).
  - The "processes ongoing" filter would remove 1 point of 32, and a
    stricter filter changes no effect beyond chance.
- **The exceptions are small groups and syphilis.** For Hispanic MSM the CIs
  of σ_e reach 4–5 pp: few infections per run, so everything is noisier.
  Syphilis keeps some state-dependence for a long time (c5_05).

### 4. What does it mean for the design of intervention runs?

([c5_03](c5_03_effects.md) §5). Error of the PIA of HIV infections for 32
runs per scenario:

| design | error (pp) |
|---|---|
| paired, 8 recycled points (current default) | 0.42–0.49 |
| paired, all 32 points | 0.42–0.46 |
| random points (`randomize.restart = TRUE`) | 0.47–0.52 |

- **The current design is adequate for effects:** within 1–9% of the best
  one, at the estimated heterogeneity.
- **Pairing on all 32 points is cheap insurance:** at the upper CI limit of
  σ_e, the current design would be 24–39% worse.
- **Randomising the points is the wrong move for scenarios.** It loses the
  pairing:
  - +4–11% error for HIV infections;
  - up to +51% for STI infections;
  - × 2.0–2.3 for year-15 prevalence.

### 5. How long does a sustained change take to show?

([c5_05](c5_05_relaxation.md)). S4, 10% fewer acts from the restart:

- **Prevalence falls by 4.3 pp** (0.254 → 0.212). It is within 0.1 SD_π of
  its new level only after **109 [91, 124] years**, which is a lower bound.
  - SCENARIOS.md predicted 80–100 years from the x0 example.
- **The share of the long-run effect that is visible:**

  | output | at 10 years | at 20 years | at 50 years |
  |---|---|---|---|
  | prevalence | 21% | 43% | 85% |
  | incidence and STIs | about two-thirds | about 80% | 93–97% |

- **After a 70-year burn-in, prevalence is still 0.7–0.8 SD_π off** its new
  equilibrium, and 1.8 SD_π after 50 years.
- **The diagnosed fraction reverses sign.** It rises for about 10 years,
  stays above the baseline for about 40, then ends below it.
- **Heterogeneity fades with the horizon.**
  - For HIV prevalence, the SD of the effect between points is at most about
    1% of the effect, and never significant.
  - Where heterogeneity exists (population size, White MSM prevalence), it
    is early and gone by 20–50 years. Syphilis is the exception.

## What changes in the recommendations

1. **For intervention effects, pair all scenarios on the same restart points,
   each used equally often.**
   - The current default (`randomize.restart = FALSE`, batches of 8) already
     does this on 8 points and is adequate.
   - Batches of 32, as used here, extend it to the whole pool at no extra
     cost in runs.
   - **Do not use `randomize.restart = TRUE` for scenario runs.**
2. **Report effects with paired uncertainty** (point-level differences).
   The spread of per-run PIAs against the baseline median describes chance,
   not the precision of the effect.
3. **The pool-size rules of cycle 4 are for levels.**
   - For effects, even 8 paired points are enough for 10-year HIV outcomes
     at this scale.
   - Scenarios whose effects could depend on the state (small groups,
     syphilis, near-threshold STIs) should use the whole pool.
4. **Scenarios that change the past need about 100 years of burn-in, or
   their own pool.** 70 years leaves prevalence 0.7 SD_π short.
   - **This concerns calibration too.** A proposal that moves the
     parameters as much as S4 would be read 0.7 SD_π from its own
     equilibrium after 70 years. Proposals close to the pool's parameters
     are less affected: after x0's change, cycle 2 found +0.2 SD at 70
     years.
5. **Read 10-year effects as early effects.** Prevalence shows about a fifth
   of its long-run effect after 10 years. Cascade outcomes can even have
   the opposite sign in the short and the long run.
6. **Syphilis scenarios need the `syph.screen.*` parameters.**

## Inputs for the next phase

| input | value | source |
|---|---|---|
| effect heterogeneity σ_e, total HIV infections, 10 years | ≤ 1.1–1.4 pp (95% upper), estimates 0.2–0.6 pp | c5_03 |
| effect ICC, total HIV infections | 0.005–0.06 | c5_03 |
| error of the PIA, 32 runs per scenario, paired | ≈ 0.42–0.49 pp | c5_03 |
| burn-in for an alternative-world scenario, prevalence | ≈ 100–110 years (T 0.1 SD); ≈ 95 years (T 0.2 SD) | c5_05 |
| share of the long-run prevalence effect at 10 / 20 / 50 years | 21% / 43% / 85% | c5_05 |
| reference data | `data/run/restart_assessment/cycle5/c5_01_annual_{short,long}.rds`; merged runs in `data/run/variance_scenarios/` | c5_01 |

## Open issues

1. **Larger interventions, longer horizons and smaller populations** were not
   tested. Effects near extinction are still unmeasured, and for syphilis
   not tried at all.
2. **Power is limited with 32 points.** A heterogeneity of 1 pp is detected
   about 7 times in 10 ([c5_02](c5_02_validate.md)). The conclusions rest on
   CIs, which exclude large heterogeneity but not small.
3. **The level ICC of cumulative incidence** was poorly determined by one
   128-run arm (0.08 by ANOVA, against 0.25 in cycle 4). Cycle 4's value is
   kept.
4. **S4's T values are lower bounds.** Prevalence still drifts slightly
   after 100 years.
