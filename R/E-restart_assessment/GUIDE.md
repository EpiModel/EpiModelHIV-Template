# A reader's guide to the restart assessment (cycles 1–5)

This guide explains **what** was analysed in the five cycles of
`R/E-restart_assessment/`, **why** each analysis was needed, and **how** it
works. Every method is introduced by its idea first, then by its technical
definition. Every abbreviation is defined where it first appears and again
in the [glossary](#7-glossary) at the end.

The step reports (`results/…md`, `cycle*/results/…md`) hold the numbers
and cite the tables they come from. The few numbers quoted here link to
those reports.

**The notes in [`results/SUMMARY.md`](results/SUMMARY.md)** are answered
here:

- "explain more ICC and MCSE": sections
  [2.6](#26-the-icc-how-much-the-starting-state-fixes) and
  [2.7](#27-mcse-design-effect-and-effective-number-of-runs);
- the "processes ongoing" filter: section
  [2.13](#213-pools-variance-deficit-imprint-assignment-selection);
- "what is PC1": section
  [2.11](#211-comparing-whole-distributions-pca-pc1-energy-distance).

## Contents

0. [The short version](#0-the-short-version)
1. [The problem in epidemiological terms](#1-the-problem-in-epidemiological-terms)
2. [The ideas behind the analyses](#2-the-ideas-behind-the-analyses)
3. [The five cycles: what was done and why](#3-the-five-cycles-what-was-done-and-why)
4. [How the conclusions evolved](#4-how-the-conclusions-evolved)
5. [Current answers and recommendations](#5-current-answers-and-recommendations)
6. [Where to find things](#6-where-to-find-things)
7. [Glossary](#7-glossary)

---

## 0. The short version

**The question.** Research runs of the model are short (15–20 years) and
start from saved model states, called restart points, instead of from
scratch. Do such runs reproduce the variation the model shows in the long
run, both over time within a run and between runs? If not:

- is one restart point enough, or is a pool of points needed?
- how many points?
- how long must runs be simulated before the research period starts?

**The answers so far** (details in [section 5](#5-current-answers-and-recommendations)):

- **One restart point is not enough.** The starting state decides most of
  the level of slow outputs over a research run. For HIV prevalence, about
  84% of the between-run variation of a 20-year mean is fixed by where the
  run starts ([c4_04](cycle4/results/c4_04_icc_direct.md)).
- **A pool of points drawn from the equilibrium removes the need for a
  post-restart burn-in.** The number of points you need depends on how
  precise the estimates must be, not on burn-in
  ([c4_05](cycle4/results/c4_05_pool_design.md)).
- **Restarting is seamless** when the saved state was produced by the same
  model: no jump, no drift ([c4_03](cycle4/results/c4_03_restart_law.md)).
- **A restart file can carry a hidden model difference.** The first
  restart point (x0) carried network coefficients that made every run from
  it simulate a slightly different model, with about 1% fewer
  partnerships ([c4_01](cycle4/results/c4_01_prepare.md),
  [SUMMARY_cycle4](cycle4/results/SUMMARY_cycle4.md)).
- **From a cold start** (the model's synthetic initial population), HIV
  prevalence needs about 100–130 years to reach equilibrium, so 70 years of
  burn-in is not enough for prevalence-type outputs
  ([c3_04](cycle3/results/c3_04_cold_start.md)).

---

## 1. The problem in epidemiological terms

### 1.1 Why restart points exist

The production workflow is:

1. **Cold start.** Build a synthetic population and network from the
   network estimation, with initial HIV and STI prevalences.
2. **Burn-in.** Simulate decades until the epidemic has "settled".
3. **Save.** Save the state of the population at the end: every person's
   attributes, the network, the internal clocks. This saved state is a
   **restart point**.
4. **Research runs.** Many short runs start from that saved state, e.g.
   5 years + a 10-year intervention period.

This saves computing: the long burn-in is done once, not in every research
run.

### 1.2 What can go wrong

The model is **stochastic**: every run is a different random trajectory.
Even with fixed parameters, prevalence in one run wanders around its
long-run level. Two things can go wrong when all runs share a starting
state.

- **Bias.** If the saved state is atypical (e.g. prevalence unusually
  high), every run inherits that, until the model "forgets" its starting
  point.
- **Missing variance.** Runs from the same state start identical, so at
  first they vary less between each other than runs from different states
  would. Estimates look more precise than they are, and their uncertainty
  intervals are too narrow.

**A useful analogy is the cluster-randomised trial.** Runs from the same
restart point are like people in the same cluster: they share something
(the starting state), so they are correlated. Ten runs from one point
carry less information than ten runs from ten independent points, just as
ten people from one village carry less information than ten people from
ten villages. The intraclass correlation (ICC) and the design effect you
know from cluster trials are exactly the quantities used here
([section 2.6](#26-the-icc-how-much-the-starting-state-fixes),
[2.7](#27-mcse-design-effect-and-effective-number-of-runs)).

### 1.3 The questions

The original brief (`restart_assessment_phaseA_brief.md`) asked five
questions, called Q1–Q5:

| brief | question | answered in |
|---|---|---|
| Q1 | Does the model have an equilibrium at all, i.e. no endless drift? | cycle 1 `03`, cycle 3 `c3_03`, cycle 4 `c4_03` |
| Q2 | How long from a cold start to equilibrium? Is 70 years enough? | cycle 3 `c3_04`, `c3_05` |
| Q3 | How long is the model's memory? How is variation split between "over time" and "between runs" in a 20-year run? | cycle 1 `05`, cycle 3 `c3_06` |
| Q4 | How much of the variation does the restart state fix? Is a single point ruled out? | cycle 1 `06` (lower bounds), cycle 4 `c4_04` (direct) |
| Q5 | Reference distributions and design inputs for later work | all cycles; cycle 4 `c4_05` |

The overall aim: **single point or pool, pool size, and how the number of
research runs depends on the pool size.**

---

## 2. The ideas behind the analyses

### 2.1 Runs, "chains", and the annual dataset

**Idea.** Each experiment has 256 simulations of 600 years, each with its
own random numbers. The reports often call a simulation a **chain**, a term borrowed from
Markov chain Monte Carlo (MCMC), where it means one simulated trajectory.
"Chain" and "run" mean the same thing here.

**Technique.**

- **Weekly to annual.** Weekly outputs are converted to annual values.
  Counts of events (**flows**: new infections, diagnoses, deaths) are
  **summed** over the year. Counts of people (**stocks**: infected, on ART,
  on PrEP) are **averaged** over the year.
- **Ratios of annual totals.** Proportions and rates are computed from
  those annual numbers, e.g. prevalence = infected / population, and never
  as means of weekly ratios.
- **Storage.** Every variable is stored as a matrix of years × runs.

**Blocks of variables.**

- **key:** the outputs research reports, e.g. `prev`, `incid_rate`,
  `dx_frac`, `supp_frac`, `prep_cov`, STI prevalence and incidence, `num`.
- **state:** slow structural counts, by race.
- **project:** the calibration targets, e.g. `i.prev.dx.B`, `cc.vsupp.B`,
  `ir100.gono`.

Script `01_prepare_annual.R` (cycle 1) defined these; `c3_01` and `c4_01`
reuse them.

### 2.2 The equilibrium (stationary law π) and why it must exist

**Idea.** After enough time, a run no longer "remembers" how it started.
Its state keeps fluctuating, but around a stable long-run pattern: an
endemic equilibrium with stochastic fluctuations. The distribution of the
state over that long run is called the **stationary distribution**, or
**stationary law**, written **π**.

- π is a distribution, not a single value. At equilibrium, prevalence is
  not fixed at 0.25; it has a mean and a spread.
- "Full variance" in the reports means the spread of π.

**Technique.**

- **Estimating π.** π is estimated by pooling all runs over the late years
  (≥ 300).
  - **μ_π** is the mean.
  - **v_π** is the variance.
  - **SD_π** = √v_π is the standard deviation (SD).
- **"In SD_π units".** Many results are expressed in SD_π units. An offset
  of +1 SD_π means one stationary standard deviation above the
  equilibrium mean, like a z-score relative to the equilibrium spread.

**Why check that π exists** (brief Q1). If some quantity drifted forever,
there would be no "full variance" to reproduce. An example is a random-walk
population composition, where the race mix wanders without a pull back.
So the late years were tested for trends:

- **Drift tests** (cycle 1 `03`, `c3_03`): the cross-run mean and variance
  are regressed on time over years 300–600 and 150–600.
- **Units:** the slopes are expressed per century, in SD_π for the mean
  and as a relative change for the variance.
- **Flag:** a variable is flagged if the confidence interval (CI) excludes
  0 **and** the drift exceeds a tolerance: 0.05 SD_π, or 5% of the
  variance, per century.

**Quasi-stationary.** Syphilis went extinct in 2 of the x0 runs, and
extinction is absorbing: without reintroduction it never comes back. So π
is formally the equilibrium *given that all infections persist*. Such runs
are dropped from the analyses.

### 2.3 How far a set of runs is from equilibrium

**Idea.** Consider all runs at year t after their start. Their values form
a distribution. Compare it with π on two things:

- **Is its centre in the right place?** That is the bias.
- **Is its spread the full spread?** That is the variance.

**Technique.** m(t) is the mean across runs at year t, and v(t) the
variance across runs.

- **Mean offset:** o(t) = (m(t) − μ_π) / SD_π, in SD_π units. 0 means
  unbiased.
- **Variance ratio:** r(t) = v(t) / v_π. 1 means full variance.
  - Runs from a single common state start at r ≈ 0 and rise towards 1.
  - Runs from independent random starts can even start above 1.

These curves are the raw material of cycle 1 `04` (from x0), cycle 3
`c3_04` (from a cold start) and cycle 4 `c4_05` (from a pool).

### 2.4 Memory: autocorrelation (ACF) and τ_int

**Idea.** How long does the model remember? If prevalence is high this
year, is it still likely to be high in 10, 20 or 50 years? Slow memory is
what makes the starting state matter for a long time.

**Technique.**

- **ACF.** The autocorrelation function ρ(k) is the correlation between an
  output now and the same output k years later, at equilibrium.
  - ρ(0) = 1, and ρ(k) decays towards 0.
  - It is computed by pooling all runs with the global mean. Removing each
    run's own mean would hide slow variation.
- **τ_int.** The integrated autocorrelation time is
  **τ_int = 1 + 2 Σ_{k≥1} ρ(k)**, in years.
  - **Meaning:** how many consecutive years of one run carry as much
    information as one independent observation.
  - **Example:** HIV prevalence has τ_int ≈ 50–70 years, depending on the
    experiment and the years used, so a 600-year run contains only about 10
    independent "looks" at prevalence.
  - **ESS:** the effective sample size, the number of years divided by
    τ_int.
- **Geyer's estimator** sums the ACF only while it is still clearly
  positive. When memory is very long, this truncation makes τ_int a lower
  value. Cycle 1 flagged this for prevalence.
- **Variance–time curve.** L × Var(M_L) / v_π, where M_L is the mean over
  a window of L years, approaches τ_int for long windows. It is an
  independent check of τ_int, and a curve still rising at the largest L
  signals memory longer than the data can show.

Where: cycle 1 `05`, cycle 2 `c2_03(d)`, cycle 3 `c3_06`.

### 2.5 What a 20-year run can show: over time vs between runs

**Idea.** Take one research run of 20 years. Prevalence varies a little
within those 20 years. But different runs sit at quite different average
levels. The long-run variance of prevalence splits into:

- the part you see **over time within one run**;
- the part you see **only by comparing runs**.

A slow output (prevalence) is mostly "between runs": a 20-year run looks
nearly flat, and the starting state sets its level. A fast output
(incidence per year) is mostly "within run": it fluctuates a lot from year
to year, so a single run already shows most of its variability.

**Technique.** For windows of L = 20 years, with M = the window mean and
S² = the variance of the 20 values inside the window:

$$v_\pi = \underbrace{\text{average of } S^2}_{\text{over time}} + \underbrace{\text{variance of } M}_{\text{between runs}}$$

This identity is exact, and the code checks it numerically.

**Result.** About 90% of the stationary variance of prevalence is between
20-year runs ([cycle 1 `05`](results/05_equilibrium_structure.md),
[c3_06](cycle3/results/c3_06_replication.md)). The between-run share is the
most a restart state *could* control. How much it actually controls is the
ICC.

### 2.6 The ICC: how much the starting state fixes

**Idea.** Start many runs from the same saved state, and look at an output
h years later. Their values differ because of chance events after the
restart, but they also share something: the starting state pushes them all
in the same direction. The **intraclass correlation (ICC)** is the share of
the output's total variance that is due to *which state* the runs started
from.

- **ICC ≈ 1:** runs from the same point are nearly identical at horizon h.
  The starting state decides the outcome, and runs from one point tell you
  about that point, not about the model in general.
- **ICC ≈ 0:** runs from the same point are as different as runs from
  different points. The starting state no longer matters.

As in a cluster trial, the ICC is the correlation between two runs of the
same cluster (restart point). It decreases with the horizon h, because the
model forgets.

**What "between points" and "within a point" mean.** Both terms come from
grouping runs by the restart point they started from, as people are grouped
by cluster in a cluster trial.

- **A point** is one saved state. **Its runs** are all the runs started
  from it, each with its own random numbers.
- **Within a point.** Runs from the same point still differ from each
  other, because of chance events after the restart: who meets whom, who
  gets infected, who tests.
  - Their spread around their own average is the *within-point variance*.
  - Averaged over the points, it is written σ²_W.
- **Between points.** The averages of different points differ too, because
  the points are different states. For example, one point may have started
  with more infected men than another.
  - The variance of these point averages is the *between-point variance*,
    σ²_B.
- **The two parts add up to the total variance** of the output over all
  runs, when the points are drawn from the equilibrium: v_π = σ²_B + σ²_W,
  as in an analysis of variance (ANOVA). Then ICC = σ²_B / v_π.

**An example with made-up numbers.** Take HIV prevalence (%) 10 years after
the restart, with 3 points × 3 runs:

| point | its 3 runs | point average |
|---|---|---|
| A | 24.8, 25.0, 25.2 | 25.0 |
| B | 25.8, 26.0, 26.2 | 26.0 |
| C | 23.8, 24.0, 24.2 | 24.0 |

- **Within a point:** each point's runs lie within ±0.2 of their average.
  The within-point variance is 0.027.
- **Between points:** the averages are 24, 25 and 26. Their variance is
  0.667.
- **Total:** the variance of all 9 values is 0.693, the sum of the two
  parts (0.6667 + 0.0267).
- **ICC** = 0.667 / 0.693 ≈ 0.96. The point a run started from decides
  almost everything.
- The variances here divide by the number of values, so that the two parts
  add up exactly.

**The pattern differs between outputs.**

- For a fast output such as annual HIV incidence, the picture is reversed.
  Runs from the same point scatter widely and the point averages are close,
  so most of the variance is within points and the ICC is small.
- The real values follow this pattern
  ([c4_04](cycle4/results/c4_04_icc_direct.md)). Ten years after the
  restart, the ICC is 0.80 [0.76, 0.83] for prevalence. For annual HIV
  incidence it is below 0.1 from year 2 on.

**Not the same split as §2.5.** Both sections split a variance into a
"within" and a "between" part, but they group values differently.

- In §2.5 the group is **one run**. Its 20 yearly values vary over time
  (within), and the averages of different runs differ (between).
- Here the group is **one restart point**. Its runs differ from each other
  (within), and the averages of different points differ (between).

**Technique.** For an output Y observed h years after a restart from state
X₀ drawn from π, the variance splits into:

$$\operatorname{Var}(Y)=\underbrace{\operatorname{Var}\big(\mathbb E[Y\mid X_0]\big)}_{\text{between points}}+\underbrace{\mathbb E\big[\operatorname{Var}(Y\mid X_0)\big]}_{\text{within a point}},\qquad \mathrm{ICC}(h)=\frac{\text{between points}}{v_\pi}.$$

The terms of the formula, in the words of the example:

- **E[Y | X₀]** is the average of Y over many runs from the same state X₀:
  the "point average".
- **Var(Y | X₀)** is the spread of those runs around that average.
- **Between points**, Var(E[Y | X₀]), is how much the point averages vary
  when the points are drawn from the equilibrium π. It is σ²_B.
- **Within a point**, E[Var(Y | X₀)], is the within-point spread averaged
  over the points. It is σ²_W.
- METHODS.md M2.2 gives the full definitions.

**How the split changes with the horizon h.**

- For points drawn from π, the total is v_π at every horizon.
- Just after the restart, the runs from one point are identical. All the
  variance is between points, and ICC = 1.
- As h grows, chance accumulates. The within part grows, the between part
  shrinks by the same amount, and the ICC falls toward 0.
- **Why the between part vanishes.** The point averages all converge to
  the same value, the equilibrium mean μ_π: the model forgets where it
  started.
  - It gets there only in the limit. In practice, "enough time" means the
    between part is below a tolerance. From one point, it takes ≈ 50 years
    for prevalence and ≈ 25 years for 10-year cumulative incidence to fall
    to ≤ 10% of v_π ([c4_04](cycle4/results/c4_04_icc_direct.md)).
  - All runs must simulate the same model. Runs from x0 kept x0's network
    coefficients, so they converged to x0's own equilibrium, not to that of
    the cold-start runs (cycle 4).
  - A point where an STI is extinct never rejoins the others for that STI
    ([2.13](#213-pools-variance-deficit-imprint-assignment-selection)).

**Research windows.**

- The same definition applies to research-window summaries, e.g. the mean
  prevalence over years B+1…B+20 after a burn-in of B years, or the
  cumulative incidence over years 6–15.
- **B, the burn-in,** is the number of years simulated after the restart
  before the research window starts.

### 2.7 MCSE, design effect and effective number of runs

**Idea.** A research result is usually a mean over simulation runs, e.g.
mean prevalence in year 15 across 256 runs. The **Monte Carlo standard
error (MCSE)** is the standard error of that mean due to simulation noise.
It tells you how much the answer would change if you re-ran the whole
experiment with other random numbers. It is called "Monte Carlo" because
the uncertainty comes from random simulation, not from data.

**Independent runs.** MCSE = SD/√N for N independent runs, e.g. from N
independent restart points.

**Runs sharing restart points.** When runs share points they are
correlated, and the MCSE is larger, exactly as in a cluster-randomised
trial:

- the **design effect** is DEFF = 1 + ICC × (n − 1), with n the number of
  runs per point;
- the **effective number of runs** is N_eff = N / DEFF;
- the **MCSE inflation** in the reports is √DEFF: how many times larger
  the MCSE is than with N independent points.

**Worked example** ([c4_05](cycle4/results/c4_05_pool_design.md)). Take
the 20-year prevalence mean, with ICC ≈ 0.84:

- 256 runs on 32 points, 8 runs each, give DEFF = 1 + 0.84 × 7 ≈ 6.9;
- so N_eff ≈ 37 and the MCSE inflation is ≈ 2.6. The 256 runs are worth
  about 37 independent ones.

**Consequences.**

- **With a single restart point,** N_eff never exceeds about 1/ICC, however
  many runs you add. You learn the future of that one point, not the
  model's equilibrium.
- **In general, k points cap N_eff at k/ICC.**

**The MCSE is also the yardstick for bias.** The brief's criterion is that
a residual bias b should satisfy |b| ≤ 0.2 × MCSE. Then the mean squared
error, MSE = MCSE² + b², is at most 4% larger than without bias. Since the
MCSE shrinks as N grows, the more runs you plan, the smaller the bias you
can tolerate, and the longer the burn-in must be (cycle 3 `c3_04`).

### 2.8 Measuring the ICC

The ICC is hard to measure because it needs several runs from the *same*
state. The cycles used three approaches, in increasing order of
directness.

**(a) Lower bounds by prediction** (cycle 1 `06`, cycle 2 `c2_02`, cycle 3
`c3_06`).

- **Idea.** If the state at the restart lets you *predict* part of a run's
  future, that part is fixed by the state. The ICC is at least that large.
  Any long run gives many "pseudo-restarts": pretend the run restarted at
  year t₀, and ask how well the observed state at t₀ predicts year t₀ + h.
- **Technique.**
  - **Pseudo-restarts:** every 5 years in the stationary period of every
    run (about 16,000–20,000 rows).
  - **Features:** 212 of them, the key and state variables at t₀ and 1, 2
    and 5 years before. Nothing after t₀ is used.
  - **Model:** ridge regression, a linear regression with a penalty that
    shrinks the coefficients. The penalty prevents overfitting with many
    correlated predictors.
  - **Validation:** 8-fold cross-validation, blocked by run, so that no run
    is in both the fitting and the testing data.
  - **The bound:** the out-of-sample R², the share of variance explained in
    runs not used for fitting.
- **Why it is only a bound.** Predictions cannot use what is not recorded:
  the network structure, individual infection histories, the age structure.
  The true ICC can be larger.

**(b) Direct value for one point** (cycle 1 `04`).

- **Idea.** The first experiment had all 256 runs from one state x0. Their
  missing variance at year h, 1 − r(h), *is* that point's ICC.
- **Limit.** It is one point only, and x0 turned out to be atypical (cycle
  2).

**(c) Direct value averaged over the equilibrium** (cycle 4 `c4_04`).

- **Idea.** 32 restart points drawn from π, with 1–15 runs each: the
  "nested design" cycles 1–2 had asked for. The spread of runs *around
  their own point* measures what the point does not fix.
- **Technique.** icc_w = 1 − (within-point variance) / v_π.
  - **Within-point variance:** the pooled variance of runs around their
    point's mean, on 224 degrees of freedom.
  - **Check:** the classical ANOVA intraclass correlation is reported
    alongside. It is biased low with only 32 points.
- **Result.** The direct values are at or above the lower bounds, as they
  must be. The gap measures memory held in unrecorded state: small for HIV
  prevalence, large for population size and the STIs.

### 2.9 Time to equilibrium: why fitted curves, not "first crossings"

**Idea.** "How many years until the runs have full variance?" sounds
simple: find the first year the curve r(t) enters the band [0.9, 1.1].
But the yearly curves are noisy, and the noise is correlated over time,
because the same runs are followed year after year. A noisy curve can
enter the band early by chance, or leave it again late by chance.
Validation on synthetic data showed that such "first crossing" rules
return essentially random times, even for a series that is at equilibrium
from year 0 (cycle 1 `02`, cycle 2 `c2_03`).

**Technique.**

- **Fit.** A smooth relaxation curve is fitted to r(t) or o(t), then read
  off. The curves are sums of one or two decaying exponentials, e.g.
  $1 − c e^{−t/τ}$ for the variance, or a damped oscillation when the mean
  overshoots.
- **Model choice:** the Akaike information criterion (AIC), a
  goodness-of-fit score that penalises extra parameters.
- **Tolerance times:**
  - **T_var(ε):** the year after which the fitted |r(t) − 1| stays ≤ ε,
    e.g. ε = 0.1 means "within 10% of full variance".
  - **T_mean(δ):** the year after which the fitted |o(t)| stays ≤ δ SD_π.
- **Uncertainty:** the CIs come from refitting on bootstrap resamples
  ([2.10](#210-uncertainty-bootstraps-and-permutation-tests)).
- **Tail window (cycle 3).** After a cold start, the first decades are a
  large non-exponential transient: an HIV epidemic overshoot. The mean fit
  therefore starts only once the offset stays within 3 SD_π (C3-M3). The
  tolerance times depend only on the tail.

**How to read these times.** The 10–20% tolerances are reliable. A 5%
tolerance is at the resolution of 256 runs: the variance of 256 values has
a relative standard error (SE) of about 9% per year.

### 2.10 Uncertainty: bootstraps and permutation tests

**Chain bootstrap** (all cycles).

- **Idea.** To get a CI, re-create many "alternative experiments" by
  resampling. Years within a run are strongly correlated, so resampling
  single years would be wrong. Whole runs are resampled, with replacement.
- **Technique.** Resample the 256 runs, recompute everything (including π),
  repeat 200–500 times, and take the 2.5% and 97.5% percentiles as the 95%
  CI. In the reports, [a, b] after a value is its 95% CI.

**Point bootstrap** (cycle 4). With runs nested in restart points, the
independent units are the points. So points are resampled, each keeping
all its runs.

**Coverage checks.** On synthetic data, the reports check how often these
CIs contain the true value: nominally 95%, observed about 83–100%
depending on the estimator. The reports call them "~85–90% intervals" where
relevant.

**Permutation tests** (cycles 3–4).

- **Idea.** If two experiments simulate the same model, their runs are
  interchangeable. Shuffle the labels "experiment A" and "experiment B"
  many times. The shuffled data show how large a difference arises by
  chance.
- **Technique.** 2000 shuffles of whole runs. The p-value is the share of
  shuffles with a difference at least as large as the observed one.
- **Many variables at once (max-T).** With 63 variables, a few will look
  significant by chance, and the variables are correlated. The **max-T**
  global test compares the *largest* standardised difference with the
  largest ones seen in the shuffles, which handles both problems.

### 2.11 Comparing whole distributions: PCA, PC1, energy distance

**Idea.** Some questions are about the whole state at once, e.g. "are
these two sets of runs from the same equilibrium?" or "is the state
distribution at year 70 already the equilibrium one?". Many variables are
redundant: prevalence, number infected, number diagnosed and number on ART
move together. Comparing them one by one over-counts the same signal.

**PCA.** Principal component analysis rotates the standardised variables
into new, uncorrelated combinations called **principal components (PCs)**,
ordered by how much of the total variation they carry.

- **PC1** (first principal component) is the combination along which the
  equilibrium states differ the most. Its **loadings** (correlations with
  the original variables) show what it represents.
- **Here PC1 is "HIV prevalence"**: it correlates at about −0.9 with
  prevalence and the HIV stocks. The sign is arbitrary.
- **Stratifying on PC1** means sorting candidate restart states by their
  PC1 score, cutting them into k equal groups, and picking one state at
  random in each. The pool then covers the slowest direction of the state
  evenly (cycle 1 `07`).

**Whitening.** The components are rescaled to unit variance, and those
covering 95% of the variation (about 18) are kept. Each independent
direction then counts equally.

**Energy distance.** A single number measuring how different two
multivariate distributions are. It is 0 only if they are identical, and it
does not assume any particular shape.

$$\mathcal E = 2\,\overline{\|x-y\|} - \overline{\|x-x'\|} - \overline{\|y-y'\|}$$

**What x, x', y and y' are.**

- **A state vector.** Take one run at one year. Its state is summarised by
  the ~18 whitened coordinates above: standardised combinations of
  prevalence, incidence, population size, the STIs and so on. That list of
  numbers is the run's **state vector**.
  - It is one point in an 18-dimensional space, just as a person with a
    height and a weight is one point on a scatter plot.
- **x and x'** are the state vectors of two different runs from the first
  group, e.g. two cold-start runs at year 70.
- **y and y'** are the state vectors of two different runs from the second
  group, e.g. two runs at equilibrium (years ≥ 300).
- **‖·‖** is the ordinary (Euclidean) distance between two points: the
  square root of the sum of the squared differences, coordinate by
  coordinate. So:
  - ‖x − y‖ is the distance between a run of the first group and a run of
    the second;
  - ‖x − x'‖ is the distance between two runs of the first group;
  - ‖y − y'‖ is the distance between two runs of the second group.
- **The bars** average each distance over all pairs.

**Why it measures a difference.** Picture the two groups as two clouds of
points.

- **Same distribution.** If both clouds come from the same distribution, a
  point of one cloud is on average as far from a point of the other cloud
  as from another point of its own cloud. The cross-group average then
  equals the within-group averages, and ℰ = 0.
- **Different distributions.** If one cloud is shifted, more spread out or
  differently shaped, points of different clouds are further apart on
  average than points of the same cloud, and ℰ > 0.
- **Why the cross-group average counts twice.** It is set against two
  within-group averages, one per group. With that weighting, ℰ is 0 only
  when the two distributions are identical.

**Its size is judged against a null:** the value obtained between two
halves of the same equilibrium sample, or from permutations that shuffle
whole runs between the two groups (§2.10).

### 2.12 Checking the tools first: synthetic data

**Idea.** Before trusting an estimator on the model output, give it data
where the right answer is known, and see whether it recovers it.

**Technique.** Each cycle's step 02 (`02_validate_methods.R`, `c3_02`,
`c4_02`) simulates data of the same shape: 254–256 runs × 600 years, the
same start design. It uses **AR(1)** processes, autoregressive processes
of order 1, the simplest random process with memory:

- the next value is a × the current value + random noise;
- the correlation k years apart is a^k;
- τ_int = $(1 + a)/(1 − a)$;
- the relaxation times are known exactly.

Sums of a fast and a slow AR(1) mimic outputs with short- and long-term
memory. Special cases:

- a random walk (no equilibrium);
- an HIV-like overshoot;
- over-dispersed starts;
- a nested design with the actual 32 points and 1–15 runs per point.

**Criterion.** An estimate passes if |z| < 3, where
$z = (estimate − truth) / bootstrap SE$,
or if it falls in a stated range. The criterion is looser
than "truth inside the 95% CI" because about 30–40 checks are made on each
synthetic dataset.

**What the checks found:**

- first-crossing rules fail (cycle 1);
- Geyer's τ_int is biased low for slow, weak components (cycle 1);
- the ANOVA ICC is biased low with 32 points (cycle 4).

The reports use the estimators that passed, and document the failures.

### 2.13 Pools: variance deficit, imprint, assignment, selection

**Variance deficit.** Runs spread over k points drawn from π show
almost the full variance: the missing share is about ICC/k, and at most 1/k.

**Imprint.** A pool of 32 points is itself a sample. Its mean state
differs a little from μ_π, and all its runs share that difference.

- Its size is the MCSE of the pool mean,
  $√[(1 + ICC (Σn_j²/N − 1)) / N] SD_π$, where n_j is the number of runs
  from point j.
- It fades as the ICC decays.

**Assignment of runs to points.**

- **Balanced:** each point is used the same number of times. This is the
  most precise use of k points.
- **Random with replacement** (`randomize.restart = TRUE` in EpiModel):
  each run draws its point at random. Some points get many runs and some
  none, which adds a design effect even when there are as many points as
  runs.
- **Recycling** (EpiModel's default): run s uses point (s − 1) mod k + 1.
  Because EpiModelHPC runs batches of 8, only the first 8 points of any
  pool are used (cycle 2 `c2_04`).

**Selection.**

- **Why not pick "the best" states.** Choosing restart states close to the
  equilibrium mean or to calibration targets shrinks the spread of the
  research runs. The pool then looks more precise than it is (cycle 1 `07`,
  cycle 2 `c2_05`).
- **Selection is conditioning.** Statistically, selecting on closeness to
  targets is the same as treating the targets as exact data. A legitimate
  version weights states by how well they match the targets *given the
  targets' uncertainty* (likelihood weights, cycle 2). With realistic data
  uncertainty, this changes almost nothing.
- **Regression to the mean.** Selected states drift back to typical
  behaviour within 10–20 years.
- **The "processes ongoing" filter.** This is the one selection the
  project does use: discard candidate states in which an STI epidemic is
  (nearly) extinct.
  - In the model, extinction is absorbing, so such a state would give
    research runs with no epidemic of that STI.
  - Cycle 1 approximated the filter by "every STI prevalence above its 1%
    equilibrium quantile". Cycle 2 used the project's actual rule in
    `3-choose_restart.R`: every STI incidence ≥ 50% of its target.
  - It is **harmless**: it rejects about 3% of equilibrium states, and a
    pool built with it keeps ≥ 95% of the variance with a bias ≤ 0.04
    SD_π ([07](results/07_pool_design.md),
    [c2_05](cycle2/results/c2_05_selection.md)).
- **The one helpful selection is stratified random sampling** on PC1
  ([2.11](#211-comparing-whole-distributions-pca-pc1-energy-distance)). It
  keeps the variance exact and reduces the imprint.

---

## 3. The five cycles: what was done and why

Each cycle lives in its own folder, with a README, a METHODS file, one
report per step and a SUMMARY. Earlier cycles are never edited. Errata are
recorded in the later cycle.

### 3.1 Cycle 1: one restart point x0 (`R/E-restart_assessment/`)

**Why.** The first variance experiment,
`data/run/variance/df__variance_long.rds`, was thought to be cold-start
runs. Its first recorded week was identical in all 256 runs. They were in
fact all **restarted from one saved state, x0**. The analysis was
re-scoped to "from a restart point to full variance", and the cold-start
questions (Q2) were set aside.

**Steps** (reports in `results/`):

| step | what (idea) | how (technique) |
|---|---|---|
| `01` prepare | turn weekly output into annual values; confirm the single start; find extinctions | sums and means per year; identical first rows; 2 runs with syphilis extinction dropped (254 left) |
| `02` validate | make sure every estimator works before using it | synthetic AR(1) series (S0–S4); found that first-crossing rules fail, so all times come from fitted curves |
| `03` stationarity | check that an equilibrium exists | drift tests of the cross-run mean and variance, years 300–600 and 150–600; 1 borderline flag of 106 |
| `04` relaxation from x0 | how long until runs from x0 have the equilibrium mean and variance, for annual values and for 20-year research windows after a burn-in B | curves o(t), r(t); relaxation fits; window shares vs B; energy distance and PCs for the whole state |
| `05` equilibrium structure | how long is the memory, and what can a 20-year run show? | pooled ACF, τ_int (Geyer), variance–time curve, window decomposition at L = 20 |
| `06` restart memory | how much does a state from π fix? | ICC lower bounds from pseudo-restarts with ridge regression, compared with x0's direct values |
| `07` pool design | burn-in vs pool size; points needed; one chain vs many; selection | design-effect formulas; effective pool size of points spaced along one chain (from the ACF); selection experiment with 2000 simulated pools of 32 states |

**What came out** ([SUMMARY](results/SUMMARY.md)):

- runs from x0 need about 70 years for the variance of prevalence and
  80–100 years for its mean;
- a single point is ruled out: lower bound 0.81 for the 20-year prevalence
  mean;
- pools of k ≈ 0.7–0.8 N points for precise level estimates;
- no selection on closeness; stratification on PC1 helps.

### 3.2 Cycle 2: review of the assumptions (`cycle2/`)

**Why.** A second pass was needed for three reasons:

- to audit the assumptions of the experiment, of the brief and of cycle 1;
- to answer for the project's *own* outcomes and code;
- to test whether cycle 1's conclusions were robust to the method choices.

**Steps** (reports in `cycle2/results/`; the audit is in
`cycle2/REVIEW.md`):

| step | what (idea) | how (technique) |
|---|---|---|
| `c2_01` provenance | where does x0 come from, and was it made by the same model? | matched x0 to `restart-hpc.rds` (2026-05-20); compared its stored parameters with the current ones (20 of 122 differ); tested for first-week jumps after the restart; compared π with the calibration targets |
| `c2_02` project outcomes | the quantities the project reports: calibration targets after 70 years; cumulative HIV incidence over years 6–15; year-15 incidence | direct values from x0; same-parameter lower bounds up to 80 years |
| `c2_03` robustness | do cycle 1's times depend on the estimator or the π period? is there memory beyond 150 years? do fit CIs cover? | stretched-exponential and isotonic (monotone, model-free) fits; π from years ≥ 150/300/450; nonlinear features; windows up to 450 years; 30 replicated synthetic datasets |
| `c2_04` design | what the project's code actually does with a pool; levels vs effects | code reading: point recycling, batches of 8, `randomize.restart`; MCSE of per-run percent infections averted (PIA); calibration run length |
| `c2_05` selection | the project's STI filter; selecting on real targets; conditioning; regression to the mean | 2000 simulated pools per rule; likelihood weights; the distance of selected states to the targets over the following 40 years |

**What came out** ([SUMMARY_cycle2](cycle2/results/SUMMARY_cycle2.md)):

- **x0 was made with other parameters,** e.g. STI natural history and HIV
  testing. Cycle 1 had measured two things mixed together: the recovery of
  variance, and the model forgetting its old parameters.
- **The project's intervention outcome varies little** (coefficient of
  variation 1.9%) and forgets faster than prevalence.
- **Effects vs levels.** For relative effects (PIA), a level shift largely
  cancels. Effect heterogeneity across points was left untested.
- **The code used only 8 points of any pool.**
- **Calibration runs of 70 years forget the restart point.**
- **Selection = conditioning.**

### 3.3 Cycle 3: the cold start (`cycle3/`)

**Why.** New data, `df__variance_long_x0.rds`: 256 runs from a **cold
start**, i.e. the synthetic initial population of the network estimation.
This is the production start and answers the brief's Q2. It also gave an
independent equilibrium sample to compare with the x0 runs.

**Steps** (reports in `cycle3/results/`):

| step | what (idea) | how (technique) |
|---|---|---|
| `c3_01` prepare | provenance of the runs; what the cold-start state looks like; annual data | exact netsim inputs from the workflow folder; parameters (82/82 identical to a rebuild from the parameter file the x0 runs also used); package commits; network coefficients stored in restart files; initial state vs π |
| `c3_02` validate | check the estimators in the cold-start regime | synthetic cold starts: plain, over-dispersed, HIV-like overshoot; permutation and energy tests under "same law" and "different law" |
| `c3_03` same law? | do cold-start runs and x0 runs have the same equilibrium? which one matches the targets? | drift tests; per-variable permutation tests with max-T; energy test on the whitened state; placebo split |
| `c3_04` cold start → equilibrium | T_cold; bias at year 70 against the MCSE; comparison with x0 | curves; fits over the tail window; energy distance; PCs; the MCSE criterion 0.2/√N |
| `c3_05` workflow | the ballpark calibration (targets after 70 years from a cold start); pools of states taken at year B | target bias by run length; research outcomes (cumulative incidence, year-15 values, 20-year windows) of runs from states of age B, cold start vs x0 |
| `c3_06` replication | do cycle 1's memory results hold in this model? | τ_int, window split and ridge lower bounds for both experiments on the same years |

**What came out** ([SUMMARY_cycle3](cycle3/results/SUMMARY_cycle3.md)):

- **The cold start is far from equilibrium.** Everyone infected is
  diagnosed and untreated, and STIs are at 10% per site. HIV prevalence
  overshoots, then settles after ≈ 100–130 years, so 70 years leaves
  prevalence-type outputs about 1–3% too high.
- **The two experiments have different equilibria:** prevalence +3.6% in
  the cold-start runs.
- **Memory structure replicates:** the same lower bounds and the same
  window split.

**Correction.** Cycle 3 attributed the equilibrium difference to a
different network estimate on the HPC. **Cycle 4 showed this was wrong**
([3.4](#34-cycle-4-a-pool-of-32-stationary-points-cycle4)).

### 3.4 Cycle 4: a pool of 32 stationary points (`cycle4/`)

**Why.** New data, `df__variance_long_pool.rds`: 256 runs restarted from
32 states. The states are the final (year-600) states of cold-start runs
1–32, so they are true equilibrium states made by the same model.
`randomize.restart = TRUE` gave 1–15 runs per point.

This is the nested experiment that cycles 1–2 recommended. It measures the
ICC directly, tests whether restarting itself changes anything, and checks
cycle 3's explanation.

**Steps** (reports in `cycle4/results/`):

| step | what (idea) | how (technique) |
|---|---|---|
| `c4_01` prepare | which point each run used; what the points carry | matched each run's first row to the pool, and the pool to the cold-start runs' last rows; runs per point; network coefficients of the pool |
| `c4_02` validate | check the nested-design estimators | synthetic nested data with the actual design; icc_w vs ANOVA ICC; continuity test under H0/H1 |
| `c4_03` restart and law | is a same-parameter restart seamless? same equilibrium as the cold start? | weekly jumps across the restart vs ordinary weeks; one-year changes vs a null from uninterrupted chains; permutation and energy tests |
| `c4_04` direct ICC | how much does a state fix, measured directly? how long does one point need to reach full variance? | icc_w with a point bootstrap; comparison with the lower bounds; fits of the within-point variance |
| `c4_05` pool design | does the actual pool give full spread? points needed; balanced vs random assignment; burn-in with k points | design-effect formulas with the direct ICC; the realised pool's variance and imprint |

**What came out** ([SUMMARY_cycle4](cycle4/results/SUMMARY_cycle4.md)):

- **Restarting is seamless** and keeps the cold-start equilibrium.
- **The cold-start runs used the local network estimate.** The equilibrium
  difference comes from **x0**, whose network coefficients are shifted:
  about 1.1% fewer partnerships in every network.
- **Direct ICCs:** 0.84 for the 20-year prevalence mean, 0.25 for
  cumulative incidence over years 6–15. The lower bounds miss much of the
  memory of population size and the STIs.
- **One same-parameter point** needs ≈ 50 years for prevalence to reach 90%
  of its variance.
- **Randomised assignment wastes precision** for level estimates.

**The network-coefficient mechanism, in plain words** (cycles 3–4).

- **The edges coefficient.** In the network model (a statistical model
  called an exponential random graph model, ERGM), one coefficient, the
  **edges coefficient**, sets how many partnerships exist.
- **The population correction.** As the population size changes, EpiModel
  adjusts it every week so that mean degree stays constant. It only
  *adds* the effect of the size change to the current value.
- **Where the offset lives.** A restart file stores that current value, so
  any offset in it is carried forever. `restart-hpc.rds` (x0) is offset by
  −0.011 (about 1.1% fewer ties); the new pool has no offset.
- **The check.** Section C3-M0 of `cycle3/results/c3_METHODS.md` describes
  how to compute the offset of any restart file.

### 3.5 Cycle 5: scenarios run from the pool (`cycle5/`)

**Why.** The project runs scenarios, and its main results are **effects**:
differences between scenarios. [SCENARIOS.md](SCENARIOS.md) argued that
restart memory matters differently for effects:

- runs of two scenarios from the same point share the point's influence, so
  it cancels in their difference;
- what is left is how much the effect itself depends on the state, the
  **effect heterogeneity**.

That had never been measured.

**The runs.** Four scenarios, run on the HPC, all from the 32 pool points
with 4 runs per point and scenario (batches of 32, so every point is used
once per batch):

- **forward**, changing from year 6: HIV testing × 2, PrEP initiation × 2,
  STI screening × 3;
- **alternative world**: 10% fewer sexual acts from the restart, run for
  150 years.

**Steps** (reports in `cycle5/results/`):

| step | what (idea) | how (technique) |
|---|---|---|
| `c5_01` prepare | were the runs what we intended? did each change act? | each run's first row matched to its pool point; the target variable of each scenario before and after year 6 |
| `c5_02` validate | check the paired estimators | synthetic runs with the two actual designs; bias, CI coverage, test size |
| `c5_03` effects | how large is each effect, how much does it vary between points, and what design follows? | within-point differences averaged over points; the heterogeneity as the spread of point-level effects beyond chance (an F ratio); design errors from the measured variances |
| `c5_04` STI threshold | do STI scenarios reach extinction, or depend on the state? | extinctions; share averted against the state's initial STI level; effects with a stricter filter |
| `c5_05` relaxation | how long does a sustained change take to show? | the effect over 150 years against the cycle 4 runs; fitted relaxation; heterogeneity by horizon |

**What came out** ([SUMMARY_cycle5](cycle5/results/SUMMARY_cycle5.md)):

- **Effects hardly depend on the restart point.** For 10-year HIV
  infections, the share averted varies between points by 0.2–0.6
  percentage points (upper 95% limits 1.1–1.4). An intervention averting
  22.5% from one state averts about 22.5% from the others.
- **So pairing matters more than pool size for effects.** The current
  design, 8 recycled points paired across scenarios, is adequate.
  Randomising the points (`randomize.restart = TRUE`) makes effects *less*
  precise.
- **No STI threshold effects within 10 years,** even with gonorrhoea
  reduced by 58%.
- **A sustained change needs about 100 years to show fully.** 10% fewer
  acts lower prevalence by 4.3 pp in the end, but only 21% of that is
  visible after 10 years. After 70 years, prevalence is still 0.7 SD_π
  from its new level.

---

## 4. How the conclusions evolved

| claim | first made | status now |
|---|---|---|
| A single restart point is not enough | cycle 1 (lower bounds) | **confirmed** directly (cycle 4) |
| x0 is "atypical" | cycle 1 | explained: x0 carries other parameters (cycle 2) and a network offset (cycle 4) |
| From one point, ≈ 70 years to full variance of prevalence | cycle 1 (x0) | true for x0; a same-parameter point needs ≈ 50 years (cycle 4) |
| Pools of k ≈ 0.7–0.8 N points for level estimates | cycle 1 | **confirmed** with direct ICCs, for balanced assignment (cycle 4) |
| Do not select on closeness; stratify | cycle 1 | **confirmed** and quantified (cycle 2); a chance under-dispersion of one real pool illustrates it (cycle 4) |
| The restart itself may cause jumps | cycle 2 (open) | **no**, for a same-parameter restart (cycle 4) |
| The cold-start and x0 equilibria differ | cycle 3 | **confirmed** (cycle 4) |
| … because the HPC network estimate differs | cycle 3 | **wrong**; it is x0's network offset (cycle 4) |
| Lower bounds are close to the true ICC | cycles 1–3 | true for HIV prevalence; **not** for population size and STIs (cycle 4) |
| 70 years of cold-start burn-in is enough | production practice | not for prevalence-type outputs; ≈ 110–130 years (cycle 3) |

---

## 5. Current answers and recommendations

**Consolidated from [SUMMARY_cycle5](cycle5/results/SUMMARY_cycle5.md),
[SUMMARY_cycle4](cycle4/results/SUMMARY_cycle4.md),
[SUMMARY_cycle3](cycle3/results/SUMMARY_cycle3.md) and
[SUMMARY_cycle2](cycle2/results/SUMMARY_cycle2.md).**

1. **Make restart points from the right model.**
   - Build them from independent cold-start runs, saved ≥ 120 years after
     the cold start, with the same parameters and network as the research
     runs.
   - Before using any restart file, compute its network-coefficient offset.
     It should be 0 in all networks.
2. **Use a pool, not a single point.**
   - For the intervention outcome (cumulative incidence, 32 runs per
     scenario), the current 32-point randomised pool gives ≈ 26 effective
     runs.
   - For precise level estimates of slow outputs, use ≈ 0.8 N points with
     balanced assignment.
3. **No burn-in is needed after restarting from such a pool:** no level
   shift, and ≥ 90% of the variance with ≥ 16 points.
4. **Select points at random,** optionally stratified on PC1, after the
   "STI ongoing" filter. Never select on closeness to targets.
5. **Recalibrate.** The current parameters were fitted under x0's shifted
   network.
6. **For intervention effects, pair the scenarios on the same restart
   points** (cycle 5).
   - The effect hardly varies between points, so 8 paired points are enough
     for 10-year HIV outcomes.
   - Pairing on all 32 points is cheap insurance.
   - Do not randomise the points for scenario runs.
7. **Scenarios that change the past need their own equilibrium:** their own
   pool, or about 100 years of burn-in (cycle 5).

---

## 6. Where to find things

| folder | contents |
|---|---|
| `R/E-restart_assessment/` | cycle 1 scripts `01…07`, `README.md`, `METHODS.md` (M1–M3), `results/` |
| `cycle2/` | `c2_*` scripts, `REVIEW.md` (assumption audit and cycle 1 errata), `results/c2_METHODS.md` |
| `cycle3/` | `c3_*` scripts, `results/c3_METHODS.md` (C3-M0–M4) |
| `cycle4/` | `c4_*` scripts, `results/c4_METHODS.md` (C4-M0–M4), cycle 3 errata in `results/SUMMARY_cycle4.md` |
| `cycle5/` | `c5_*` scripts, `results/c5_METHODS.md` (C5-M1–M5); scenario runs in `data/run/variance_scenarios/` |
| `SCENARIOS.md` | what changes when the model is used to compare scenarios |
| `WHY_A_POOL.md` | what a restart pool still adds for scenarios, and a design for parameter uncertainty |
| `data/run/restart_assessment/` | annual datasets and large intermediates (git-ignored) |

**Naming.**

- Every step has a report `…/results/<step>.md`, tables
  `…/results/tables/<step>_*.csv`, figures `…/results/figures/<step>_*.png`
  and logs `…/results/logs/<step>.log`.
- Each `run_all*.R` re-runs its cycle from scratch.

**Section references in the reports.**

- M2.3, C2-M4, C3-M3, C4-M2 point to the METHODS files of cycles 1, 2, 3
  and 4.
- A1–A12, B1–B9 point to the assumption tables of `cycle2/REVIEW.md`.

---

## 7. Glossary

**Symbols and short names used in the reports:**

| term | meaning |
|---|---|
| π | stationary law: the model's long-run (equilibrium) distribution, estimated from years ≥ 300 |
| μ_π, v_π, SD_π | mean, variance and standard deviation of an output under π |
| SD_π units | a difference divided by SD_π, like a z-score against the equilibrium spread |
| x0 | the single restart state of the first experiment (`restart-hpc.rds`, May 2026) |
| cold start | a run started from the synthetic initial population (`initialize_msm`) |
| restart point / pool | a saved model state, and a set of k such states |
| chain | one simulated run (from Markov chain Monte Carlo terminology) |
| t, h, t₀ | years since the start; horizon after a restart; pseudo-restart year |
| B | burn-in: years simulated after the restart before a research window |
| L | length of a research window in years (20, or 10 for cumulative incidence) |
| M, S² | mean of a window; variance of the values inside a window |
| m(t), v(t) | mean and variance across runs at year t |
| o(t) | mean offset (m(t) − μ_π)/SD_π: bias in SD_π units |
| r(t) | variance ratio v(t)/v_π: share of the full variance present |
| T_var(ε), T_mean(δ) | years until the fitted variance is within ε (e.g. 10%) or the fitted mean within δ SD_π, for good |
| T_cold | time from a cold start to equilibrium |
| k, N, n, n_j | number of restart points; number of runs; runs per point; runs from point j |
| σ²_B, σ²_W | between-point and within-point variance: how much the averages of different restart points differ; how much runs from the same point differ (§2.6) |
| key / state / project | blocks of variables: reported outputs / structural counts / calibration targets |
| `prev`, `incid_rate`, `dx_frac`, `supp_frac`, `prep_cov`, `num` | HIV prevalence; HIV incidence per 100 person-years; diagnosed fraction; suppressed fraction; PrEP coverage; population size (`.B`/`.H`/`.W` = Black, Hispanic, White MSM) |
| `i.prev.dx.X`, `cc.vsupp.X`, `ir100.sti` | calibration targets: diagnosed prevalence; suppression among diagnosed; STI incidence per 100 person-years |
| cml incidence, `cml10` | HIV infections summed over a 10-year window (years 6–15 = the intervention period) |

**Abbreviations:**

| abbreviation | meaning |
|---|---|
| ACF | autocorrelation function ρ(k): correlation between an output now and k years later |
| AIC | Akaike information criterion: fit score penalising extra parameters, used to choose between curve models |
| ANOVA | analysis of variance; here the classical between/within decomposition behind the ICC |
| AR(1) | autoregressive process of order 1: next value = a × current + noise; the reference process for validation |
| CI | confidence interval; [a, b] after a value is its 95% CI |
| CV | coefficient of variation: SD / mean |
| DEFF | design effect: 1 + ICC(n − 1); variance multiplier for correlated runs |
| ERGM | exponential random graph model: the statistical model of the partnership networks |
| ESS | effective sample size: number of values ÷ τ_int (or N ÷ DEFF for runs) |
| ICC | intraclass correlation: share of an output's variance fixed by the restart point |
| icc_w, icc_a | cycle 4's direct ICC estimators: 1 − within-point variance / v_π (main); ANOVA ICC (check) |
| LB | lower bound, here on the ICC, from prediction (ridge R²) |
| MAD | median absolute deviation: a robust measure of spread, used for the jump tests |
| max-T | a global test over many variables using the largest standardised difference |
| MCMC | Markov chain Monte Carlo (origin of the word "chain") |
| MCSE | Monte Carlo standard error: SE of a mean over simulation runs |
| MSE | mean squared error = MCSE² + bias² |
| NIA, PIA | number / percent of infections averted by an intervention |
| OLS | ordinary least squares (plain linear regression) |
| PC, PC1, PCA | principal component(s); the first one; principal component analysis |
| R² | share of variance explained by a prediction, measured on runs not used to fit it |
| RMS | root mean square: typical size of a quantity that can be positive or negative |
| SD, SE | standard deviation; standard error |
| τ_int | integrated autocorrelation time, in years: τ_int = 1 + 2 Σ ρ(k) |
| W1 | Wasserstein-1 distance: the average shift needed to turn one distribution into another |
