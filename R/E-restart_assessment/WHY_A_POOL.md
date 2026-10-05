# Is a restart pool needed for scenarios?

Cycle 5 found that intervention effects hardly depend on the restart state.
This note asks what a pool of restart points still adds when the model is
used to compare scenarios, with a research publication in mind. It ends with
the design question that matters next: parameter uncertainty.

Conventions as in the [GUIDE](GUIDE.md). Terms such as ICC, pairing, PIA,
NIA and σ_e are defined in the GUIDE and [SCENARIOS.md](SCENARIOS.md)
glossaries. Numbers come from the cycle reports, which are linked.

## Contents

1. [What cycle 5 says about precision](#1-what-cycle-5-says-about-precision)
2. [What the pool buys scientifically](#2-what-the-pool-buys-scientifically)
3. [What it costs](#3-what-it-costs)
4. [The larger uncertainty: parameters](#4-the-larger-uncertainty-parameters)
5. [A design for parameter uncertainty](#5-a-design-for-parameter-uncertainty)
6. [Answer](#6-answer)

---

## 1. What cycle 5 says about precision

**The idea.** When every scenario starts from the same restart states
(pairing), the level a state imposes on all its runs cancels in the
difference between scenarios. What remains is:

- chance after the restart;
- the part of the effect that depends on the state (effect heterogeneity).

Cycle 5 measured the second: it is small.

**The numbers** ([c5_03](cycle5/results/c5_03_effects.md)). Share of HIV
infections averted over years 6–15 (PIA):

| scenario | PIA | σ_e: SD of the PIA between restart states |
|---|---|---|
| S1, testing × 2 | 1.1% | 0.58 pp [0, 1.39] |
| S2, PrEP × 2 | 22.5% | 0.20 pp [0, 1.10] |
| S3, STI screening × 3 | 5.9% | 0.63 pp [0, 1.40] |

**The error of the PIA** for 32 runs per scenario, paired, under three
designs:

| scenario | 1 point | 8 points (current) | 32 points |
|---|---|---|---|
| S2, PrEP × 2 | 0.46 pp | 0.42 pp | 0.42 pp |
| S1, testing × 2 | 0.73 pp | 0.49 pp | 0.46 pp |
| S3, STI screening × 3 | 0.77 pp | 0.49 pp | 0.45 pp |

**Reading it:**

- **The number of points barely matters for precision** once there are a
  few.
- **A single point costs up to about 60% more error.**
  - That extra error is not noise that more runs would average away. It is
    a fixed offset: the result is the effect *from that one state*.
  - Its size is σ_e, which is unknown unless several points were run.

---

## 2. What the pool buys scientifically

### 2.1 The estimand: the model's effect, not one state's

- **From one restart state,** the result is conditional: "the effect,
  starting from this particular realisation of the epidemic".
- **From a pool drawn from the equilibrium,** the result is the model's
  effect, averaged over the states the calibrated model actually visits.
  That is what a paper claims when it writes "the intervention would avert
  X% of infections".
- **The pool is what lets you check** that the two agree. Cycle 5 could
  write "the effect varies by less than 1.4 percentage points across
  equilibrium states" because it had 32 of them. With one state, the
  sentence would have been an assumption.

**In epidemiological terms:** a result from one restart state is a
single-site study. A pool is a multi-site study that can report the
between-site variation of the effect, even when that variation turns out to
be small.

### 2.2 Levels, and everything built on them

- **Many reported quantities are levels:**
  - the NIA (number of infections averted), which is PIA × the baseline
    level;
  - incidence per year under each scenario;
  - prevalence trajectories;
  - "infections in year X".
- **The restart state fixes a large share of their variance:** 25% for
  10-year cumulative incidence and 84% for a 20-year prevalence mean
  ([c4_04](cycle4/results/c4_04_icc_direct.md)).
- **From one point, level intervals are too narrow** and centred on that
  point's own future. For year-15 prevalence, a single point inflates the
  MCSE 4.7 times at N = 32, against 1.29 for 32 random points
  ([c4_05](cycle4/results/c4_05_pool_design.md)).
- Papers usually show NIA next to PIA, and absolute trajectories in
  figures. So the pool is needed there, whatever cycle 5 found for PIA.

### 2.3 Insurance where effects are not proportional

Cycle 5 found the exceptions where theory predicts them:

- **Small groups:** for Hispanic MSM, σ_e is 1.4–2.5 pp, with upper limits
  of 4–5 pp. There are few infections per run.
- **Syphilis:** its effect heterogeneity persists for up to 150 years
  ([c5_05](cycle5/results/c5_05_relaxation.md)).
- **Non-monotone outcomes:** after a sustained change, the diagnosed
  fraction first rises, then ends below the baseline
  ([c5_05](cycle5/results/c5_05_relaxation.md)).

The scientifically interesting scenarios are often exactly the ones where
proportionality is least safe:

- large interventions and near-elimination scenarios;
- subgroup analyses;
- STI outcomes near their threshold.

For those, one cannot know beforehand that the starting state doesn't
matter.

### 2.4 Honest uncertainty

- **What a reported interval should cover** is every source of variation
  the model contains. The starting state is one of them.
- **With one point, that source is silently missing.** It is small for PIA
  but dominant for prevalence levels.
- **With a pool used in a paired design,** it is included for levels and
  cancels, correctly, for effects.

### 2.5 How many runs to report levels

**The idea.** The project reports each level as the median and the 2.5–97.5%
range of the runs (`sum_quants(0.025, 0.5, 0.975)` in
`R/D-interventions/labels.R`). "Not missing any value" means two things:

- the runs reach the tails of the distribution;
- the reported range ends are close to the true ones.

Both depend on the number of runs only. They are the same, in SD units, for
every near-normal outcome, which covers everything tracked so far except
syphilis: equilibrium kurtosis is within ±0.1, against 0.24–0.53 for
syphilis.

**The technique.** For N independent runs:

| runs | median, 95% error | each range end (2.5%, 97.5%), 95% error | chance the runs reach both ends of the true 95% range | share of outcomes beyond the lowest–highest run |
|---|---|---|---|---|
| 32 | ± 0.42 SD | ± 0.71 SD | 31% | 6% |
| 64 | ± 0.30 SD | ± 0.56 SD | 64% | 3% |
| 128 | ± 0.22 SD | ± 0.43 SD | 92% | 1.6% |
| 200 | ± 0.17 SD | ± 0.36 SD | 99% | 1% |
| 400 | ± 0.12 SD | ± 0.26 SD | ~100% | 0.5% |
| 800 | ± 0.09 SD | ± 0.18 SD | ~100% | 0.25% |

- These values come from simulated normal outcomes, 20,000 replications per
  N. SD is the run-to-run standard deviation of the outcome.
- **Each range end** (the 2.5% and 97.5% quantiles of the runs) is
  estimated, so it is uncertain. "± 0.71 SD" means that, in 95% of repeated
  experiments, the reported end is within 0.71 SD of the true quantile.
  - That is about a third of the distance from the middle of the range to
    its end (1.96 SD).
  - The range ends are always about twice as uncertain as the median.
- **The last column** is the expected share of possible outcomes lying
  outside the range of the runs, 2 / (N + 1).

**An example: 10-year HIV infections** (SD ≈ 194 infections, mean ≈ 10,500;
[c2_02](cycle2/results/c2_02_project_outcomes.md)):

- **32 runs:**
  - the median is known to about ±80 infections;
  - the 97.5% end only to about ±140;
  - 69% of the time, the runs do not reach both ends of the true 95% range.
- **200 runs:** the median is known to about ±33, and the range ends to
  about ±70.

**Consequences:**

- **Medians and means are cheap.** 32 runs give them to a fraction of an SD.
- **Ranges are expensive.** The ends of a 95% range need about **200 runs**
  to be reliable: ±0.36 SD, and reached 99% of the time. About 800 are needed
  to know them within ±0.18 SD. Syphilis needs about 25% more.
- **The runs must start from independent equilibrium states,** ideally
  about one pool point per run, the same point for replication *i* of every
  scenario.
  - With a few points and many runs each, the between-state part is
    under-represented. The tails of prevalence-type outcomes then come out
    too short, however many runs are added (ICC 0.84 for a 20-year
    prevalence mean, [c4_04](cycle4/results/c4_04_icc_direct.md)).
- **For the current design,** 32 runs per scenario are enough for medians,
  but their range ends are uncertain by about ±0.7 SD.

### 2.6 Replications per restart point

**The idea.** Replications from the same point share that point's
influence, so each extra one only adds the chance that happens after the
restart. How much that is worth depends on the outcome's ICC over the
research window.

**The technique.** With n replications from each point, each point is worth
n / (1 + ICC × (n − 1)) independent runs, and never more than 1 / ICC.

The ICCs are those of 10-year windows starting at the restart, with no
burn-in. They were measured on the cycle 4 nested runs with `icc_direct()`
(C4-M2). A range gives the main estimate and the ANOVA check, where they
differ:

| outcome (10-year window from the restart) | ICC | 2 replications worth | 4 worth | 8 worth | cap (1/ICC) |
|---|---|---|---|---|---|
| HIV prevalence, 10-y mean | 0.93 | 1.04 | 1.06 | 1.07 | 1.08 |
| `i.prev.dx.B` | 0.94 | 1.03 | 1.05 | 1.06 | 1.06 |
| population size | 0.91 | 1.05 | 1.08 | 1.09 | 1.10 |
| gonorrhoea infections | 0.66 | 1.20 | 1.34 | 1.42 | 1.52 |
| `ir100.hiv.dx.B` | 0.51 | 1.32 | 1.58 | 1.75 | 1.96 |
| HIV infections, total | 0.27–0.40 | 1.4–1.6 | 1.8–2.2 | 2.1–2.8 | 2.5–3.7 |
| Hispanic HIV infections, PrEP coverage | 0.16 | 1.72 | 2.70 | 3.77 | 6.3 |
| a paired intervention effect (PIA) | ≤ 0.06 ([c5_03](cycle5/results/c5_03_effects.md)) | 1.9 | 3.4 | 5.6 | ≥ 17 |

"Worth" is in independent-run equivalents per point.

**What the cap means.** Take the first row: 93% of the run-to-run variance of
the 10-year prevalence mean is decided by the starting state, and 7% is
chance after the restart.

- Replications from one point differ only by that 7%. Averaging many of them
  pins down **that point's** expected future.
- But that expected future is one draw among all points' futures, and it
  carries the point's own offset: 93% of the variance. No number of
  replications removes it.
- A run from a *new* point carries the full variance. So one point with
  infinitely many replications is worth 100% / 93% ≈ 1.08 runs from
  different points.

In numbers (equilibrium SD of the 10-year prevalence mean ≈ 0.0036):

| design | SE of the estimated equilibrium mean |
|---|---|
| 1 point × 10,000 replications | ≈ 0.0035: the point's offset, √0.93 × 0.0036, never shrinks |
| 10,000 points × 1 replication | 0.0036 / √10,000 = 0.000036 |
| 32 points × 1 replication | ≈ 0.0006 |

**When the cap applies depends on the question:**

- **"What is the model's average over the equilibrium?"** The cap applies,
  and only more points help.
- **"What happens from *this* state?"** This is a conditional estimand: one
  specific starting epidemic, e.g. a chosen typical state. There is no cap.
  Replications are fully useful, because they estimate that state's future.
- **Effects.** The point's offset cancels between paired scenarios, so the
  cap is 1 / ICC_Δ ≥ 17 (last row of the first table). Replications stay
  valuable for PIA.

**Consequences for design:**

- **Levels:** spend runs on points (k ≈ N, one replication each).
- **Effects:** spend them on runs. A modest pool, 32 points paired across
  scenarios, with as many replications as the precision needs (§2.5 and §1).
- **Both:** many points with 1–2 replications each.
- **At least 2 replications per point** are needed to *measure* the ICC or
  the effect heterogeneity. With one run per point, chance and the point's
  influence cannot be told apart.
- **A burn-in between the restart and the window** would lower the ICC and
  make replications worth more. That is why cycle 4's 5-year lead-in gave
  0.25 for cumulative incidence. But with a same-parameter pool no burn-in is
  needed for bias, so adding points is the cheaper route.

---

## 3. What it costs

- **Building the pool:** 32 cold starts × ≥ 120 years, run in parallel once.
  Every scenario of that parameter set then reuses it.
- **Running scenarios from it:** nothing extra. With pairing, the same
  number of runs is spread over more points.
- **The real cost is procedural.**
  - The pool must be rebuilt after every recalibration, with the same
    parameters and network as the scenario runs.
  - It must be checked before use: the network-coefficient offset (C3-M0)
    and the parameters it would fill in.
  - The x0 episode shows what a stale restart file does silently: every
    run from it simulated a model with 1.1% fewer partnerships
    ([c4_01](cycle4/results/c4_01_prepare.md)).

---

## 4. The larger uncertainty: parameters

**Chance after the restart is now small and well understood.** With 32
paired runs, the PIA of HIV infections has an error of about 0.4–0.5 pp.

**Parameter uncertainty is probably much larger.** This is the spread of
calibrated parameter sets that reproduce the targets about equally well.

- It has not been measured in this project, so this is a strong expectation,
  not a result.
- The reason to expect it: calibration targets (diagnosed prevalence, STI
  incidence, cascade indicators) typically leave parameters such as per-act
  transmission, testing rates and behavioural scalars only partly
  identified. Different combinations can then fit about equally well and
  imply different intervention effects. How much this applies here is
  untested.

**Why this matters for the restart question.** Each parameter set has its
own equilibrium.

- A state made under one set needs about 100 years to settle under another.
  With 10% fewer acts, prevalence settles after 109 years and is still
  0.7 SD_π off after 70 years ([c5_05](cycle5/results/c5_05_relaxation.md)).
- **So a single pool does not carry over to an uncertainty analysis.** A
  pool built with the best-fitting parameters is foreign to every other
  parameter set, which is the x0 situation again.

---

## 5. A design for parameter uncertainty

**The idea.** Generalise the pool from "several states of one model" to
"one equilibrium state per plausible model".

1. **Draw J parameter sets** from the calibration: posterior draws, or the
   accepted sets of the final swfcalib wave.
2. **Bring each set to its own equilibrium.**
   - Either a cold start, ≥ 120 years (c3_04: 126 years for the prevalence
     mean);
   - or a restart from a state of a nearby set, with ≥ 100 years of burn-in
     (c5_05).
   - Save the final state: one restart point per parameter set.
3. **Branch every scenario from each set's state, paired:** the same state
   and the same number of runs for the baseline and every intervention.
4. **Analyse with two levels of variation:**
   - between parameter sets: the parameter uncertainty of the effect;
   - within a set, between runs: chance, which is known to be small for
     effects (cycle 5).

**Why this is efficient:**

- **The between-point variation is folded into the between-set variation,**
  which has to be reported anyway. A separate pool per set is not needed:
  one state per set is enough, because cycle 5 showed that effects hardly
  depend on the state within one model.
- **Pairing still removes the level each state imposes,** so effect
  uncertainty reflects parameters, not the starting states.
- **Runs per set can be few.** Chance adds about 0.4–0.5 pp at 32 runs per
  scenario, and fewer runs per set are acceptable if parameter uncertainty
  dominates. The split of J × n is a design choice.

**Cost, roughly:** J sets × (≥ 100 years to equilibrium + scenario runs).
For example, J = 100 sets needs 100 × 100 = 10,000 run-years to reach the
equilibria. That is less than one 256 × 600-year variance wave
(153,600 run-years).

**What would need checking first:**

- how many sets J are needed for a stable interval (a pilot with J ≈ 30);
- whether one state per set is enough for levels, or a few states per set
  are needed for prevalence-type outputs (ICC 0.84 within a set);
- whether the burn-in can be shortened by restarting from the state of the
  *nearest* set rather than from a generic one.

---

## 6. Answer

- **For one-off PIA estimates from forward scenarios, a pool is not
  strictly necessary.** A single same-parameter equilibrium state, paired
  across scenarios, gives a nearly unbiased PIA: the error rises from
  0.42–0.46 to 0.46–0.77 pp. But you could not *show* that it is unbiased.
- **For a research result you will defend, keep the pool.** It is cheap
  insurance, and it is what lets you claim the effect is the model's, not
  one starting state's. It is also required for levels and NIA, and for
  subgroups, STIs and large interventions, where effects are least
  proportional.
- **The next design question is parameter uncertainty.** The pool idea
  should become one equilibrium state per parameter set, with all scenarios
  branched from each, paired. That is where the uncertainty that matters for
  the conclusions lives.
