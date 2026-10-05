---
title: "Restart pools and scenarios: findings and next steps"
date: 2026-09
---

# Restart pools and scenarios

Findings of the restart assessment (cycles 1–5), and where to go next.

EpiModelHIV · Atlanta model, 100k nodes

---

## The question

- **The practice.** Research runs start from saved model states (restart
  points) instead of a 70+ year burn-in each time.
- **The worry.** Runs that share a starting state are correlated. Estimates
  can be biased and their intervals too narrow.
- **What we ran:**
  - 256 × 600-year runs from one point (x0);
  - 256 cold starts;
  - 256 runs from a 32-point equilibrium pool;
  - 4 scenarios × 128 runs from that pool (cycle 5).
- **Main question:** what does a pool of restart points add when we compare
  scenarios?

---

## Finding 1: levels depend on the starting state

- **The restart state fixes a large share of the between-run variance
  (the ICC):**

  | output | share fixed by the restart state |
  |---|---|
  | 20-year prevalence mean | 84% |
  | 10-year cumulative incidence | 25% |

- **One point cannot represent the model.** For 20-year prevalence, 256 runs
  from one point are worth at most about 1.2 independent runs (1 / ICC).
  From 32 points, 8 runs each, they are worth about 37.
- **A pool of equilibrium states gives the full spread from year 1,** with
  no burn-in and no jump at the restart (when made by the same model).
- **Restart files can hide model differences.** x0 carried shifted network
  coefficients: 1.1% fewer ties in every run.
- **From a cold start,** prevalence needs about 126 years to reach
  equilibrium.

<small>c4_03, c4_04, c4_05, c3_04, c4_01</small>

---

## Finding 2: effects barely depend on it

Baseline and three interventions from the same 32 points, 4 runs each:

| scenario (from year 6) | HIV infections averted, years 6–15 | SD of the effect between states |
|---|---|---|
| HIV testing odds × 2 | 1.1% | 0.6 pp [0, 1.4] |
| PrEP initiation odds × 2 | 22.5% | 0.2 pp [0, 1.1] |
| STI screening × 3 | 5.9% | 0.6 pp [0, 1.4] |

- **The effect is proportional to the level.** An intervention that averts
  22.5% of infections from one state averts about 22.5% from any other.
- **Pairing matters, the number of points barely does.** Error of the PIA
  with 32 runs per scenario:
  - paired, 8 points: 0.42–0.49 pp;
  - paired, 32 points: 0.42–0.46 pp;
  - random points: 0.47–0.52 pp, and × 2 for prevalence.
- **Exceptions:** small groups (Hispanic MSM, CI up to 5 pp) and syphilis.

<small>c5_03, c5_04</small>

---

## Finding 3: changes to the past take a century

10% fewer sexual acts from the restart, 150 years:

- **Prevalence** falls by 4.3 points (0.254 → 0.212).
  - Share of that visible at 10 years: 21%; at 20: 43%; at 50: 85%.
  - Within 0.1 SD of its new level only after **≈ 109 years**.
- **Incidence** reacts faster: two-thirds of the change within 10 years.
- **Calibration targets** follow the same split:

  | target | years to settle |
  |---|---|
  | `ir100.hiv.dx` (a flow) | 60–77 |
  | `i.prev.dx` (a stock) | 92–110 |

- **So:**
  - 10-year effects are early effects;
  - sensitivity or counterfactual scenarios need their own equilibrium.

<small>c5_05</small>

---

## What we now do

1. **Pools:** built under the final parameters, ~150 years, checked for
   equilibrium, network offsets and parameters.
   - The pool for the pool2 values is running.
2. **Scenario runs:** all scenarios paired on the same points, used equally
   often (batches of 32). Never `randomize.restart` for scenarios.
3. **Reporting:** effects with paired SEs, and the horizon always stated.
4. **Calibration:** runs of 70–80 years are enough when fitting
   `ir100.hiv.dx`. Diagnosed prevalence needs longer.
5. **HPC:** one tested procedure, a separate output directory per workflow,
   no broad `rm` or `scancel`.

---

## For discussion

1. **Parameter uncertainty is probably the larger uncertainty.**
   - Design: one equilibrium state per calibrated parameter set, all
     scenarios branched from it and paired.
   - How many sets, and from which calibration output?
2. **Which HIV targets?** `ir100.hiv.dx` and `i.prev.dx` probably cannot
   both be met by `trans.scale` alone (Hispanic MSM: −52% vs +6%). Add a
   testing parameter, or choose one?
3. **What the pool means for Atlanta.** At 100k nodes the model is the city.
   The pool is our uncertainty about its *current* state.
   - Should we report per-run spreads as prediction intervals?
   - Should we use common random numbers for "realised" effects?
4. **Equilibrium assumption.** The real epidemic is not stationary (PrEP
   scale-up). Do we need a calendar-time lead-in?
5. **Tooling.** Build restart-file checks and a pool helper into
   EpiModel / EpiModelHPC? The batch-offset or seed options are needed for
   pairing on large pools.
6. **Other cities** (NYC, Boston). The same rules, with a pool per city?

<small>Details: GUIDE.md, SCENARIOS.md, WHY_A_POOL.md, cycle5/results/SUMMARY_cycle5.md</small>
