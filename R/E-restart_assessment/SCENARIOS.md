# Scenarios and the restart pool

The model exists to run **scenarios**: the same model with some parameters
changed, to see what would happen in other situations. Cycles 1–4 studied
one situation only, the baseline, run many times. This document works out
what changes in the restart point and pool question when the aim is to
compare scenarios.

It follows the conventions of the [reader's guide](GUIDE.md):

- each idea comes first, then its technical form;
- every abbreviation is defined where it first appears and in the
  [glossary](#10-glossary);
- the intraclass correlation (ICC), the Monte Carlo standard error (MCSE),
  the design effect, the equilibrium π and SD_π units are explained in
  GUIDE §2.2–2.7.

**When this document was written, no scenario had been simulated.** All
variance runs of cycles 1–4 used the baseline parameters. What follows about
effects was derived: from the code, from the ICCs and variances measured in
cycles 1–4, and from the formulas given here.

> **Cycle 5 has since tested these predictions**
> ([SUMMARY_cycle5](cycle5/results/SUMMARY_cycle5.md)). Four scenarios were
> run from the pool, 4 runs per point and scenario.
>
> - **Effect heterogeneity (§3.4, §4.5):** small, and compatible with
>   proportional effects. For 10-year HIV infections, σ_e is 0.2–0.6 pp,
>   with upper 95% limits of 1.1–1.4 pp.
> - **Designs (§4.2):** the current paired 8-point design is within 1–9% of
>   32 paired points. `randomize.restart = TRUE` is worse for effects, as
>   predicted.
> - **STIs near threshold (§7):** no extinction, and no dependence on the
>   state, within 10 years of screening × 3.
> - **Sustained changes (§5–6):** 10% fewer acts need ≈ 109 years for
>   prevalence to settle, against the 80–100 predicted. 10 years show 21%
>   of the long-run prevalence effect, against the rough guide's 28%.

## Contents

0. [The short version](#0-the-short-version)
1. [Scenarios in this project](#1-scenarios-in-this-project)
2. [Three kinds of scenario, three kinds of starting state](#2-three-kinds-of-scenario-three-kinds-of-starting-state)
3. [Comparing forward scenarios from one pool: pairing](#3-comparing-forward-scenarios-from-one-pool-pairing)
4. [Designs for the project's intervention runs](#4-designs-for-the-projects-intervention-runs)
5. [Sustained changes move the equilibrium](#5-sustained-changes-move-the-equilibrium)
6. [Scenarios that change the past](#6-scenarios-that-change-the-past)
7. [Scenarios near a threshold: STIs](#7-scenarios-near-a-threshold-stis)
8. [Problems found in the current scenario files](#8-problems-found-in-the-current-scenario-files)
9. [Recommendations](#9-recommendations)
10. [Glossary](#10-glossary)

---

## 0. The short version

- **The pool remains the right starting point for intervention scenarios.**
  - An intervention scenario changes parameters from a given time on
    (`.at`). It asks "starting from the world as it is, what would change
    if we did X?".
  - The pool is a sample of the world as it is under the model (the
    baseline equilibrium). All scenarios can share it.
- **Effects are compared within restart points, and that changes the pool
  question.**
  - For a **level** (an outcome under one scenario), the share of variance
    fixed by the restart point, the ICC, is a cost. It is why a pool is
    needed.
  - For an **effect** (the difference between two scenarios), runs of both
    scenarios from the same point share that part, so it cancels.
    - This is like a multi-centre trial in which every centre receives
      every treatment: the centre effect cancels in the comparison.
    - For effects, the ICC is a gain.
  - What does not cancel:
    - chance after the restart, which only more runs reduce;
    - **effect heterogeneity**, i.e. how much the effect itself depends on
      the starting state.
- **Gain from pairing for the project outcomes.** If effects are
  homogeneous, the standard error (SE) of a paired effect is √(1 − ICC)
  times that of an effect from unpaired independent runs:
  - 0.87 for 10-year cumulative incidence (ICC 0.25);
  - 0.56 for year-15 prevalence (ICC 0.69).
- **Effect heterogeneity is the one unknown.**
  - If the intervention removes the same fraction of infections whatever
    the state, heterogeneity is negligible. For a 10% effect, the percent
    of infections averted (PIA) would vary between states by ≈ 0.1
    percentage points (pp).
  - Cycle 5 measured it: for 10-year HIV infections, σ_e is 0.2–0.6 pp
    (upper 95% limits 1.1–1.4 pp), compatible with proportional effects
    ([c5_03](cycle5/results/c5_03_effects.md)).
- **Consequences for the current workflow** (`randomize.restart = FALSE`,
  batches of 8):
  - the scenarios are already paired, on points 1–8 of the pool, 4 runs
    each;
  - for effects, this is within 10% of pairing on all 32 points, unless
    the PIA varies between states by more than ≈ 0.6 pp;
  - `randomize.restart = TRUE` would use all 32 points but break the
    pairing. It is worse for effects unless that variation exceeds
    ≈ 1.3 pp;
  - pairing over all 32 points is the robust choice, and it is possible
    with the current tools ([4.3](#43-how-to-pair-over-the-whole-pool-with-the-current-tools)).
- **Measuring the heterogeneity is cheap.** 32 points × 4 runs × 2
  scenarios × 15 years cost 2.5% of one variance wave. If there is no
  heterogeneity, that run bounds it at ≈ 0.9 pp.
- **Scenarios that change the past need their own equilibrium.**
  - These are sensitivity analyses on calibrated parameters, counterfactual
    histories, other parameter sets, and network changes.
  - Started from the baseline pool, they repeat the x0 problem: about 80
    years before prevalence settles.
- **Sustained changes keep acting for decades.** 10-year effects are early
  effects.
- **The current scenario file would run nine copies of the baseline.**
  - `scenarios.csv` has `.at = 3901`, but the runs end at step 782, so no
    change is ever applied.
  - Its testing rates come from an older parameter set.
  - `make_scenarios.R` copies group 2's testing rate into group 3.
  - See [section 8](#8-problems-found-in-the-current-scenario-files).

---

## 1. Scenarios in this project

### 1.1 The idea

A scenario is a "what if": the same model and the same starting world, with
some parameters set to other values from a given time on. Comparing each
scenario with a reference scenario answers "what difference would this
make?".

### 1.2 How the code does it

**Definition.** `R/D-interventions/make_scenarios.R` writes
`data/input/scenarios.csv`, one row per scenario:

- `.scenario.id`: the scenario's name;
- `.at`: the time step from which the new values apply;
- one column per changed parameter, holding its new value. It is an
  absolute value, not a multiplier.

The current grid multiplies the odds of HIV testing and the odds of
treatment initiation by 1/4, 1 or 4 (`apply_or()`), giving 3 × 3 = 9
scenarios.

**Mechanics** (EpiModel, `R/net.fn.scenarios.R` and `R/net.mod.updater.R`):

- `create_scenario_list()` turns each row into a parameter **updater**:
  "at step `.at`, set these parameters to these values".
- `use_scenario()` adds the updater to `param$.param.updater.list` and sets
  `param$.scenario.id`.
  - An updater with `.at` < 2 is applied to `param` at once, i.e. from the
    start of the run.
- During the run, an updater fires at the step whose time equals its `.at`
  exactly, then it is removed.

**Runs** (`workflow-intervention.R`, `R/netsim_settings.R`):

- every scenario restarts from `data/run/estimates/restart_pool.rds`
  (32 points) at `restart_time` = 2;
- runs end at `intervention_end` = 782:
  - 5 years of **lead-in** up to `intervention_start` = 262;
  - then 10 years of intervention;
- 32 runs per scenario, in 4 batches of 8. Each batch is one `netsim` call
  on 8 cores, run as a separate job by SLURM (the job scheduler of the
  high-performance computing cluster, HPC).

**Outcomes** (`outcomes.R`, `labels.R`):

- `cml_incid_X`: HIV infections over the intervention period, by group X
  (B, H, W = Black, Hispanic, White MSM, men who have sex with men);
- `lst_ir100_X`: HIV incidence per 100 person-years over the last year;
- NIA (number of infections averted) = baseline median − the run's value;
- PIA (percent of infections averted) = NIA / baseline median;
- NIA and PIA are computed **for each run**, against the median of the
  reference scenario `test_1_treat_1`;
- the tables report, for each scenario, the median and the 2.5% and 97.5%
  quantiles of these per-run values.

### 1.3 Levels and contrasts

Scenario runs produce two kinds of quantity.

- A **level** is the value of an outcome under one scenario, e.g. the
  number of infections over 10 years with testing odds × 4.
  - Cycles 1–4 were about levels, under the baseline.
- A **contrast**, or effect, compares two scenarios, e.g. NIA and PIA.
  - It is the main product of the project.

Levels and contrasts respond differently to restart points
([section 3](#3-comparing-forward-scenarios-from-one-pool-pairing)).

---

## 2. Three kinds of scenario, three kinds of starting state

The pool is a sample of the **baseline equilibrium** π₀: the states the
model visits in the long run under the calibrated parameters (GUIDE §2.2).
Whether a scenario can start from it depends on the question the scenario
asks.

| kind | example | what differs from the baseline | where its runs should start |
|---|---|---|---|
| **forward** (intervention) | testing odds × 4 from year 5 | parameters from `.at` on | the baseline pool, shared by all scenarios |
| **alternative world** (sensitivity analysis, counterfactual, other parameter sets) | "if condom use had always been lower"; a per-act risk at its upper bound; another calibrated parameter set | parameters over the whole history | that world's own equilibrium: its own pool, or a long burn-in ([section 6](#6-scenarios-that-change-the-past)) |
| **network** | more casual partnerships | the network formation coefficients | first the new coefficients must be set explicitly ([6.3](#63-network-scenarios)); then as one of the two above |

- **Why the pool fits forward scenarios.**
  - The question is "starting from the world as it is, what would change?".
  - Under the model, the pool *is* the world as it is.
  - After `.at`, the scenario pulls the runs away from π₀. That movement is
    the answer, not a nuisance.
- **Why it does not fit alternative worlds.**
  - The question is "what would the world look like if X had been
    different?". That world has its own equilibrium.
  - Runs restarted from π₀ under its parameters spend decades moving from
    our world to that one.
  - This is exactly what happened with x0 in cycles 1–2: a state made under
    other parameters, restarted under the current ones
    ([section 6](#6-scenarios-that-change-the-past)).

---

## 3. Comparing forward scenarios from one pool: pairing

### 3.1 The idea: restart points as centres of a multi-centre trial

When all scenarios start from the same restart points, each point is like a
centre in a multi-centre trial in which every centre receives every
treatment. Statisticians call this a **randomised block design**, with the
points as blocks.

- **What cancels.** Anything a centre does to all its patients cancels
  when treatments are compared within that centre. Here, that is the level
  a restart state imposes on all its runs.
- **What does not cancel:**
  - **chance after the restart:** runs from the same point still differ;
  - **effect heterogeneity:** the effect itself may differ between points,
    as a treatment effect may differ between centres (a treatment × centre
    interaction).

### 3.2 The technique

**Notation**, for a scenario a compared with the reference scenario 0:

- x_j: restart point j, for j = 1…k;
- μ_a(x): the expected outcome of runs from x under scenario a;
- Δ(x) = μ_a(x) − μ_0(x): the **conditional effect** of the scenario for
  runs from x;
- Δ̄: the **average effect**, i.e. Δ(x) averaged over the baseline
  equilibrium π₀. This is the target;
- σ²_B: the variance of μ_0(x) between points. As in GUIDE §2.6, the ICC is
  σ²_B / v_π, where v_π is the variance at equilibrium;
- σ²_W: the variance between runs from the same point (chance after the
  restart);
- σ²_Δ: the variance of Δ(x) between points, i.e. the **effect
  heterogeneity**. Its SD in PIA units is written σ_e, in percentage
  points.

**Precision of the estimated effect Δ̂**, with N runs per scenario over k
points (n = N/k runs per point and scenario):

- **Paired** (the same points, each used the same number of times, in every
  scenario):
  - Var(Δ̂) = σ²_Δ / k + 2 σ²_W / N;
  - σ²_B does not appear: it cancels.
- **Unpaired** (each scenario draws its own points):
  - Var(Δ̂) = Var(Ȳ_a) + Var(Ȳ_0), and each term carries σ²_B with its
    design effect (GUIDE §2.7);
  - with an independent point for every run:
    Var(Δ̂) = 2 (σ²_B + σ²_W) / N, plus σ²_Δ / N.

**Pairing gain.** With homogeneous effects (σ²_Δ = 0):

- the paired variance divided by the unpaired variance is
  σ²_W / (σ²_B + σ²_W) = 1 − ICC;
- so the SE is multiplied by √(1 − ICC).

**The effect ICC.** ICC_Δ = σ²_Δ / (σ²_Δ + 2 σ²_W).

- It is the share of the variance of a paired difference that is fixed by
  the point. A paired difference is one run per scenario from the same
  point.
- With ICC_Δ in place of the ICC, all the pool formulas of cycles 1–4 hold
  for paired effects:
  - design effect 1 + ICC_Δ (n − 1);
  - effective number of runs N / design effect;
  - a cap of k / ICC_Δ effective runs, whatever N.

### 3.3 The ICC changes role

- **For levels, restart memory is a cost.** With a high ICC, runs from one
  point are close copies, so many points are needed (GUIDE §2.7).
- **For paired effects, it is a gain.** The part of the variance fixed by
  the point is the part that cancels. The more the point decides, the more
  pairing removes.

| outcome | ICC ([c4_04](cycle4/results/c4_04_icc_direct.md), [c4_05](cycle4/results/c4_05_pool_design.md)) | SE of a paired effect / SE with unpaired independent runs, √(1 − ICC) |
|---|---|---|
| cumulative incidence, years 6–15 | 0.25 [0.07, 0.40] | 0.87 |
| HIV prevalence, year 15 | 0.69 [0.61, 0.75] | 0.56 |
| HIV prevalence, 20-year mean | 0.84 [0.81, 0.87] | 0.40 |

- **For the project outcome the gain is modest.** Three-quarters of the
  variance of 10-year cumulative incidence is chance after the restart, and
  only more runs reduce it.
- **For slow outcomes the gain is large.** Effects on prevalence are much
  more precise when paired.
- **These ICCs were measured under the baseline.** For the levels of other
  forward scenarios over 10 years they are assumed similar, because the
  memory sits in the starting state, which all scenarios share.

### 3.4 What is known about effect heterogeneity

- **Cycles 1–4 measured nothing about it,** since every variance run used
  the baseline. Cycle 5 did ([c5_03](cycle5/results/c5_03_effects.md)): it
  is small for the three scenarios tested, and what there is, the
  proportional model below predicts.
- **If the effect is proportional**, the intervention removes the same
  fraction e of infections from every state. Then Δ(x) = −e μ_0(x) and
  σ_Δ = e σ_B. Cycle 2 used this model ([c2_04](cycle2/results/c2_04_design.md),
  C2-M6).
  - For 10-year cumulative incidence, the coefficient of variation (CV =
    SD / mean) between runs at equilibrium is 1.9%
    ([c2_02](cycle2/results/c2_02_project_outcomes.md)).
  - With ICC 0.25, σ_B ≈ √0.25 × 1.9% ≈ 0.95% of the mean.
  - With e = 10%, the PIA varies between states with SD σ_e ≈ 0.1 pp, and
    ICC_Δ ≈ 0.002. The restart point is then irrelevant for effects.
- **Why effects could depend on the state beyond that:**
  - testing and treatment act on the undiagnosed and untreated infected
    men, whose number varies between states. The diagnosed fraction
    `dx_frac` keeps memory of the start (ICC 0.36 for a 20-year mean,
    [c4_04](cycle4/results/c4_04_icc_direct.md));
  - responses can be nonlinear, e.g. when a rate is already high, or near
    an epidemic threshold ([section 7](#7-scenarios-near-a-threshold-stis)).
- **Heterogeneity fades with the horizon.**
  - Δ(x) can depend on x only through what the runs remember of x.
  - That memory decays on the same time scales as for levels (GUIDE §2.4).
  - So heterogeneity is a short-horizon matter, and the project's window
    (years 6–15) is short.

---

## 4. Designs for the project's intervention runs

### 4.1 How the current workflow uses the pool

This comes from reading the code (`EpiModel/R/net.mod.init.R`,
`EpiModelHPC/R/netsim_scenarios.R`). Cycle 2 first noted it
([c2_04](cycle2/results/c2_04_design.md)).

- **`randomize.restart = FALSE`** (the default, and what
  `workflow-intervention.R` uses):
  - run s of a `netsim` call restarts from point (s − 1) mod k + 1;
  - each batch is one call with 8 runs, so only points 1–8 are used, 4
    runs each per scenario;
  - **every scenario uses the same points, so the design is paired.**
- **`randomize.restart = TRUE`:**
  - each run draws a point at random, with replacement;
  - no seed is set anywhere. EpiModelHPC sets none, and EpiModel derives
    each run's random numbers from the job's random initial state
    (`future.seed = TRUE`);
  - so each scenario draws different points: **the design is unpaired.**
- **Knowing the point of each run.**
  - With recycling, the merged tibbles keep `sim_number`, the run's index
    within its batch (`merge_netsim_scenarios_tibble()`). The point is
    `sim_number`.
  - With `randomize.restart = TRUE`, EpiModel records the point in
    `dat$run[["_restart_simnum"]]`, which is not saved by default. It can
    be recovered from the first epi row of the raw output, which is the
    point's own last row (as in cycle 4). The merge drops that row
    (`steps_to_keep`), so the point must be kept explicitly.

### 4.2 The designs compared

**What the table shows.** The error of the PIA of 10-year cumulative
incidence, against the average effect Δ̄, in percentage points of PIA, with
N = 32 runs per scenario.

- It is the RMSE (root mean square error), so it includes the chance of
  which points were used.
- Example: 0.41 pp means that a PIA estimated at 10.0% is typically off by
  about ±0.4 pp.
- **Assumptions.** Scenario means are compared. Medians, as in the tables
  of `labels.R`, are about 25% noisier for near-normal outcomes.
- **Inputs.** ICC 0.25 ([c4_04](cycle4/results/c4_04_icc_direct.md)), CV
  1.9% ([c2_02](cycle2/results/c2_02_project_outcomes.md)), the formulas of
  [3.2](#32-the-technique).
- **Reading σ_e.** σ_e = 1 pp means that a 10% PIA would be about 9% from
  some states and 11% from others (± 1 SD).

| design | how it arises | σ_e = 0 | 0.5 pp | 1 pp | 2 pp |
|---|---|---|---|---|---|
| paired, 1 point | one restart point for every scenario | 0.41 | 0.65 | 1.08 | 2.04 |
| paired, 8 points × 4 runs | **current default** | 0.41 | 0.45 | 0.54 | 0.82 |
| paired, 32 points × 1 run | [4.3](#43-how-to-pair-over-the-whole-pool-with-the-current-tools) | 0.41 | 0.42 | 0.45 | 0.54 |
| unpaired, 32 points at random | `randomize.restart = TRUE` | 0.53 | 0.54 | 0.58 | 0.73 |
| reference: unpaired, independent points | the ideal of cycles 1–4 | 0.48 | 0.48 | 0.51 | 0.59 |

**Reading the table:**

- **With homogeneous effects, the number of points does not matter for
  effects; only pairing does.**
  - One point, 8 or 32 all give 0.41 pp.
  - With one point, the estimate is the effect for that point's state. It
    equals the average effect only if effects are homogeneous.
- **The current default is within +10% of 32 paired points** while
  σ_e ≤ 0.6 pp.
- **`randomize.restart = TRUE` is worse for effects** unless σ_e > 1.3 pp.
  It gains points but loses the pairing.
- **Pairing over all 32 points is never worse,** so it is the robust
  choice.

**For slow outcomes the ranking is sharper.** For year-15 prevalence (ICC
0.69) with homogeneous effects, randomisation gives 2.3 times the SE of
pairing: 1.29 against 0.56, relative to independent runs.

**For levels, the ranking is reversed.** The MCSE inflation of the level of
cumulative incidence under each scenario
([c4_05](cycle4/results/c4_05_pool_design.md)) is:

- 1.32 with the current 8 recycled points;
- 1.11 with 32 random points;
- 1.00 with 32 points used once each.

**Pairing over all 32 points, each used equally often, is best for both
levels and effects.**

### 4.3 How to pair over the whole pool with the current tools

1. **Batches of 32.**
   - Set `max_cores <- 32` in `workflow-intervention.R`.
   - Recycling then uses points 1–32 once per batch, identically in every
     scenario.
   - This needs nodes with 32 cores and the memory for 32 runs.
2. **Split the pool into four 8-point files.**
   - `EpiModel::get_sims(x, sims = 9:16)` subsets a restart object. It was
     checked on the current pool: runs, network coefficients and epi rows
     match the source points.
   - Add one `step_tmpl_netsim_scenarios()` step per file, each writing to
     its own `output_dir`. Otherwise the file names
     `sim__<scenario>__<batch>.rds` collide.
   - Merge with the file index as the batch number. The point is then
     8 × (file − 1) + `sim_number`.
   - This needs no package change.
3. **A batch offset for the restart index** in EpiModel or EpiModelHPC:
   batch b uses points (b − 1) × 8 + s.
   - It is the cleanest fix. It was already suggested in
     [SUMMARY_cycle4](cycle4/results/SUMMARY_cycle4.md) (recommendation 3).
4. **The same seed for batch b in every scenario,** with
   `randomize.restart = TRUE`.
   - The point draws would then be the same in every scenario, and so
     would every random number up to `.at` ("common random numbers").
   - It needs a seed option in EpiModelHPC.
   - The draws are still with replacement, so the points are not used
     equally often.

### 4.4 Analyse with the pairing

- **Point estimates.** In a paired design where every point is used
  equally often, the difference of the scenario means *is* the mean of the
  within-point differences. The current point estimates already benefit
  from the pairing.
- **Uncertainty.**
  - `outcomes.R` compares each run with the baseline median. The 2.5–97.5%
    quantiles of those per-run values show the run-to-run spread of
    incidence, not the uncertainty of the effect
    ([c2_04](cycle2/results/c2_04_design.md), interpretation 4).
  - The paired uncertainty comes from point-level differences:
    - for each point j, d_j = mean of scenario a's runs from j − mean of
      the reference scenario's runs from j;
    - Δ̂ = mean of the d_j;
    - its SE is SD(d_j) / √k, with a t distribution on k − 1 degrees of
      freedom (7 with the current 8 points).
  - This SE covers both chance and effect heterogeneity.
- **The same data measure heterogeneity.** It is the scenario × point
  interaction of a two-way analysis of variance (ANOVA),
  [4.5](#45-measuring-effect-heterogeneity).

### 4.5 Measuring effect heterogeneity

*Done in cycle 5,* with 32 points × 4 runs × (baseline + 3 scenarios)
([c5_03](cycle5/results/c5_03_effects.md)). The planning numbers below are
kept for later scenarios.

**From the first valid intervention run** (8 points × 4 runs × 9 scenarios,
once [section 8](#8-problems-found-in-the-current-scenario-files) is fixed):

- if the true heterogeneity is zero, one contrast bounds σ_e at ≈ 1.7 pp
  (upper 95% limit). That is loose;
- a two-way ANOVA over the 9 scenarios has 56 degrees of freedom for the
  interaction, but it only measures an average heterogeneity.

**A dedicated run: 32 points × 4 runs × 2 scenarios** (baseline and one
intervention), paired as in [4.3](#43-how-to-pair-over-the-whole-pool-with-the-current-tools):

- if the truth is zero, it bounds σ_e at ≈ 0.9 pp;
- it detects σ_e = 1.3 pp with power 0.94. That is the value above which
  randomisation beats the current design;
- 32 × 8 × 2 would bound σ_e at ≈ 0.6 pp;
- the cost: 256 runs × 15 years = 3,840 run-years, 2.5% of one
  256 × 600-year variance wave.

**Notes:**

- at least 2 runs per point and scenario are needed to separate
  heterogeneity from chance, so the 32 × 1 design of 4.2 cannot measure it;
- the bounds assume near-normal outcomes, and use the chi-squared
  distribution of a variance with k − 1 degrees of freedom;
- cycle 4's tools cover most of the analysis: `nested_anova()` for the
  within-point variance of each scenario, and `point_boot_index()` for
  confidence intervals that resample points (`cycle4/c4_utils.R`).

---

## 5. Sustained changes move the equilibrium

### 5.1 The idea

- A permanent change from `.at` on defines a new model, with its own
  equilibrium π_a.
- The runs start at π₀ and head for π_a. The 10-year intervention period
  shows the beginning of that move.
- How fast the model moves is set by its slow modes, the same ones that
  make restart memory long (GUIDE §2.4). For HIV prevalence, fluctuations
  relax with τ ≈ 30 years ([04](results/04_relaxation_from_x0.md)).

### 5.2 An empirical example: x0

x0 was made under other parameters. Restarting it under the current
parameters is, in effect, a sustained parameter change at the restart.
Cycles 1–2 measured how the runs then moved to their new equilibrium
([04](results/04_relaxation_from_x0.md),
[c2_02](cycle2/results/c2_02_project_outcomes.md)):

- **Prevalence** started only 0.36 SD from its new mean, yet needed
  83 [74, 119] years to settle within 0.1 SD.
  - The rest of the state was further off: +1.7 SD for HIV incidence,
    −1.5 SD for population size, −4.4 SD for chlamydia.
  - Prevalence moved with the rest of the state before settling.
- **The path overshoots.** The best-fitting curves for prevalence and
  diagnosed prevalence are damped oscillations with τ ≈ 25–32 years.
- **HIV incidence** needed 55 years for its mean, and STI incidence 35–58
  years.

### 5.3 Consequences

- **10-year effects are early effects.**
  - The direct effect of a testing or treatment change on incidence is
    fast. The feedback through prevalence takes decades.
  - A rough guide only, not measured for any scenario: with a single
    exponential of τ = 30 years, a change reaches about
    1 − e^(−10/30) ≈ 28% of its eventual effect on prevalence within 10
    years.
- **State the horizon with every effect.**
  - A 10-year PIA says nothing directly about 20 or 50 years.
  - The last-year outcomes (`lst_`) are snapshots of a moving target, not
    new equilibria.
- **The pool does not change.** Every forward scenario starts from π₀, the
  status quo it is compared with.
- **Longer questions need longer runs,** from the same pool. By the x0
  example, a sustained change needs about 80–100 years to show its
  equilibrium effect on prevalence.
- **The lead-in is not needed to reach equilibrium.**
  - With a same-parameter pool, there is no level shift at the restart
    ([c4_03](cycle4/results/c4_03_restart_law.md)).
  - With ≥ 16 points the variance deficit is ≤ 10% from the start
    ([c4_05](cycle4/results/c4_05_pool_design.md)). With the 8 points
    currently used, prevalence-type levels need ≈ 12 years for that.
  - No parameter changes during the lead-in (the only updaters are the
    scenarios', at `.at`). So it only moves the intervention to year 5, and
    it costs a third of the compute.
  - **Keep it** if it stands for calendar time with planned changes, e.g. a
    PrEP scale-up before the intervention.
  - **Otherwise, restarting at `.at`** would buy 1.5 times more runs for
    the same compute. It would also raise the ICC of cumulative incidence
    slightly (0.27 at B = 0 against 0.25 at B = 5; the ANOVA check gives
    0.40 against 0.21; `cycle4/results/tables/c4_04_icc_summary.csv`).
    Pairing turns that into a small gain for effects.

---

## 6. Scenarios that change the past

### 6.1 The problem

- A scenario meant to hold over the whole history has its own equilibrium
  π_a.
- Restarting the baseline pool under its parameters reproduces the x0
  situation: the runs spend decades moving from π₀ to π_a. Outcomes read
  during that move measure the transition between the two worlds, not π_a.
- Cycle 4 showed the other side: a restart is seamless only when the state
  was made by the same model ([c4_03](cycle4/results/c4_03_restart_law.md)).

### 6.2 What to do

- **Build the scenario's own pool:** independent cold starts under its
  parameters, with states saved ≥ 120 years later, as for the baseline
  pool. The prevalence mean needs 126 years after a cold start
  ([c3_04](cycle3/results/c3_04_cold_start.md)).
- **Or restart the baseline pool under its parameters and burn in** before
  the analysis window.
  - The change built into x0 needed about 80 years for prevalence. How
    long depends on how far apart the two equilibria are.
  - Check it on the scenario's own runs with the cycle 1 tools: the mean
    offset against the scenario's own long-run level (GUIDE §2.3, §2.9).
- **Compare within the alternative world.** To ask "what would the
  intervention do if X were different?", run both that world's baseline
  and its intervention from its own pool, paired as in
  [section 3](#3-comparing-forward-scenarios-from-one-pool-pairing).

### 6.3 Network scenarios

- **Partnership formation is not in `param`.**
  - Restarted runs take their network coefficients from the restart file
    (`dat$nwparam[[network]]$coef.form <- x$coef.form[[s]][[network]]`,
    `EpiModel/R/net.mod.init.R`).
  - The only automatic change is the population-size correction of the
    edges term (`edges_correct()`).
  - So `scenarios.csv` cannot change who forms partnerships. A new network
    estimate affects only runs that start from it (cold starts), not
    restarts.
  - This is how x0 carried a hidden 1.1% reduction in ties
    ([c4_01](cycle4/results/c4_01_prepare.md)).
- **What a network scenario needs:**
  - code that modifies `dat$nwparam[[i]]$coef.form` at `.at`, e.g. a small
    module;
  - a check that the target network statistics are reached.
- **After the change,** the network relaxes on the time scale of
  partnership durations (years for main partnerships). Then the epidemic
  relaxes on its own slow time scale.
- **Behaviour within partnerships is in `param`.** Condom use and act
  rates (`cond.*`, `acts.*` in `model_parameters.csv`) can be changed with
  `.at` as usual.

### 6.4 Many parameter sets, and calibration

- **Several calibrated parameter sets** (for an uncertainty analysis) are
  several alternative worlds. A pool made with one set is foreign to the
  others.
  - A workable design is one chain per parameter set: restart it from the
    baseline pool with that set's parameters, run it until it settles
    (≈ 70–100 years), then branch all scenarios from its final state,
    paired.
  - The variance between sets is then part of the reported uncertainty, as
    intended.
- **Calibration waves are alternative-world runs too.** Each proposal is
  read 70 years after restarting from states made under other parameters.
  The cycles found:
  - the restart point is forgotten by year 70 (ICC ≈ 0,
    [c4_05](cycle4/results/c4_05_pool_design.md));
  - the imprint of the other parameters is ≈ 0.2 SD for diagnosed
    prevalence at 70 years ([c2_04](cycle2/results/c2_04_design.md));
  - after a cold start, 70 years is too early for prevalence-type targets:
    +0.7 to +1.3 SD_π ([SUMMARY_cycle3](cycle3/results/SUMMARY_cycle3.md),
    from [c3_04](cycle3/results/c3_04_cold_start.md)).

---

## 7. Scenarios near a threshold: STIs

- **Extinction is absorbing in the model:** an extinct sexually
  transmitted infection (STI) never returns (GUIDE §2.13). At baseline,
  syphilis goes extinct at ~1.3 × 10⁻⁵ per run-year, which is negligible
  ([SUMMARY](results/SUMMARY.md)).
- **A scenario that reduces STI transmission can push runs to
  extinction.** Then:
  - **outcomes become two-part** (extinct or persisting runs). The mean
    effect mixes the probability of extinction with the effect in the
    persisting runs, so report both;
  - **effects depend strongly on the starting state,** since states with
    low STI prevalence go extinct first. Effect heterogeneity is then
    large, so pairing and many points matter. Stratifying the pool on STI
    prevalence helps;
  - **the "processes ongoing" filter may bias such effects.** It is
    harmless for levels: it rejects about 3% of equilibrium states
    ([c2_05](cycle2/results/c2_05_selection.md)). But it removes exactly
    the states closest to extinction, so STI-reduction scenarios may look
    slightly less able to eliminate an STI. For such scenarios, compare the
    results with and without the filter.

---

## 8. Problems found in the current scenario files

These came up while checking how scenarios run. None of them concerns
restart points, but each would invalidate an intervention run.

1. **No scenario would ever apply.**
   - `data/input/scenarios.csv` has `.at = 3901` in all 9 rows.
   - The runs end at `intervention_end` = 782 (`nsteps` in
     `workflow-intervention.R`), and an updater fires only at the step
     whose time equals its `.at` exactly.
   - So all 9 scenarios would silently simulate the baseline.
   - The file was last written in April 2025 (commit `4ba3dc7`). It does
     not match the current `shared_variables.R`, where
     `intervention_start` = 262.
2. **The testing rates come from an older parameter set.**
   - The scenarios store absolute values. The odds-ratio-1 rows set
     `hiv.test.rate_1` to 0.00278, against 0.000542 in
     `model_parameters.csv` (5.1 times).
   - The treatment rates match the current parameters.
   - So `test_1_treat_1`, the reference for NIA and PIA, would not be the
     calibrated baseline once its updater fires.
3. **Group 3 (White MSM) gets group 2's testing rate.**
   - `make_scenarios.R` computes `hiv.test.rate_3` from
     `param$hiv.test.rate[[2]]`. The csv shows it: the columns for groups
     2 and 3 are equal in every row.
   - Even after regenerating the file, the reference scenario would raise
     group 3's testing rate from 0.00109 to 0.00125 (+14%).
   - It is probably meant to be `[[3]]`.

**Fixes:**

- correct the index;
- re-run `make_scenarios.R` after every calibration;
- after a run, check that the updaters fired. Each one prints "At timestep
  = 262 the following parameters were modified" in the job log.

**Checked and fine:**

- **The pool passes nothing on through missing parameters.**
  - EpiModel fills parameters missing from `param` with the restart file's
    values (`net.mod.init.R`).
  - For the current pool, this fills only `.param.updater.list` (empty),
    `.scenario.id`, `groups` (1) and `time.unit` (7).
  - Every other parameter in the pool equals the current `param`.
  - Scenario runs set their own `.param.updater.list` and `.scenario.id`
    through `use_scenario()`, so those are not inherited either.
- **The pool's network coefficients pass** the network-coefficient check
  of cycle 3 (C3-M0: offset 0, [c4_01](cycle4/results/c4_01_prepare.md)).

---

## 9. Recommendations

1. **Fix the scenario file** ([section 8](#8-problems-found-in-the-current-scenario-files))
   before the next intervention run.
2. **Start every forward scenario from the same pool, paired, with every
   point used equally often** ([4.3](#43-how-to-pair-over-the-whole-pool-with-the-current-tools)).
   - The 32-point pool is enough for the levels of cumulative incidence:
     18 points used equally often give ≤ +10% MCSE
     ([c4_05](cycle4/results/c4_05_pool_design.md)).
   - For effects, pairing removes the point's share of the variance.
3. **Keep `randomize.restart = FALSE` for scenario runs,** unless its draws
   can be made common to all scenarios.
4. **Report effects with paired uncertainty,** from point-level differences
   ([4.4](#44-analyse-with-the-pairing)), and state the horizon.
5. **Measure effect heterogeneity once** ([4.5](#45-measuring-effect-heterogeneity)).
   It decides how many points effects need. *Done in cycle 5:* small for
   testing, PrEP and STI screening.
6. **Give alternative-world scenarios their own equilibrium:** their own
   pool, or a checked burn-in ([section 6](#6-scenarios-that-change-the-past)).
   This covers sensitivity analyses, counterfactuals, other parameter sets
   and network changes. Check their restart files with C3-M0, as for the
   baseline.
7. **For STI-reduction scenarios:** report extinction probabilities,
   stratify the pool on STI prevalence, and check the effect of the filter
   ([section 7](#7-scenarios-near-a-threshold-stis)).

---

## 10. Glossary

Terms introduced here. For the others, see the
[GUIDE glossary](GUIDE.md#7-glossary).

| term | meaning |
|---|---|
| scenario | the model with some parameters changed from `.at` on |
| `.at` | the time step from which a scenario's new values apply |
| updater | EpiModel's instruction "at step `.at`, set these parameters", kept in `param$.param.updater.list` |
| lead-in | the 5 years between the restart and `intervention_start` |
| reference scenario | the scenario the others are compared with (`test_1_treat_1`) |
| level | the value of an outcome under one scenario |
| contrast, effect | a comparison of two scenarios (a difference or a ratio) |
| NIA, PIA | number / percent of infections averted, against the reference scenario |
| forward scenario | a change from `.at` on, starting from today's world |
| alternative-world scenario | parameters that differ over the whole history; such a scenario has its own equilibrium |
| π₀, π_a | the equilibrium under the baseline, and under scenario a |
| paired design | every scenario uses the same restart points, each equally often; a randomised block design with points as blocks |
| Δ(x), Δ̄ | the conditional effect for runs from state x; its average over π₀, which is the target |
| σ²_B, σ²_W | the variance between points and within points (GUIDE §2.6) |
| σ²_Δ, σ_e | effect heterogeneity: the variance of Δ(x) between points; its SD in percentage points of PIA |
| ICC_Δ | effect ICC, σ²_Δ / (σ²_Δ + 2 σ²_W): the share of a paired difference's variance fixed by the point |
| common random numbers | the same random numbers for runs of different scenarios, so that they differ only through the scenario |
| ANOVA | analysis of variance |
| CV | coefficient of variation, SD / mean |
| HPC, SLURM | high-performance computing cluster; its job scheduler |
| MSM | men who have sex with men |
| pp | percentage points |
| RMSE | root mean square error: the typical total error, chance and bias together |
| SE, SD | standard error; standard deviation |
| STI | sexually transmitted infection |
