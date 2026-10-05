# Summary of cycle 2, and comparison with cycle 1

Cycle 1 ([`../../results/SUMMARY.md`](../../results/SUMMARY.md)) answered
the four questions from the variance runs. Cycle 2 re-checked:

- the assumptions ([`../REVIEW.md`](../REVIEW.md));
- where x0 comes from ([c2_01](c2_01_provenance.md));
- the project's own outcomes and designs ([c2_02](c2_02_project_outcomes.md),
  [c2_04](c2_04_design.md));
- the robustness of the methods ([c2_03](c2_03_robustness.md));
- selection ([c2_05](c2_05_selection.md)).

## The finding that changes the reading

**The restart point x0 was not produced by the model that the variance runs
simulate.** It is `restart-hpc.rds` from 2026-05-20, and 20 parameters
differ, including STI natural history, HIV testing and Hispanic
transmission; the STI screening parameters are absent.

The variance runs therefore measure **two things at once**:

1. the recovery of the between-run variance;
2. the relaxation of the mean after a **parameter change**.

Cycle 1 treated both as "time to full variance from a restart point" and
explained the second by x0 being "atypical".

## Question by question

### 1. How long from a restart point to full variance?

**Cycle 1:**

- ≈ 70 years for annual HIV prevalence (variance within 10%);
- ≈ 66 years for 20-year windows;
- 80–100 years for the mean.

**Cycle 2**, separating the two cases:

- **Restart point made with other parameters** (this experiment, and every
  calibration wave):
  - prevalence-type outputs, variance: ≈ 70–90 years
    - i.prev.dx.B 69 [56, 92]
    - i.prev.dx.W 89 [63, 428]
  - their mean: ≈ 80–100 years.
  - project outcome, 10-year cumulative incidence, variance ≥ 90%: B ≈ 31
    [18, 56] years; the level offset is ≈ 0 at B ≈ 50.
- **Restart point from the same model** (rigorous lower bounds):
  - prevalence-type variance: **≥ 50 years**;
  - 10-year cumulative incidence: **≥ 10 years**;
  - STI incidence: ≥ 10–20 years;
  - cascade and PrEP: ≥ 5–15 years.

  There is no extra mean bias beyond the between-point variance.

**What changed and why.** The cycle 1 numbers are right for the case they
actually measured, a point made with other parameters. For a same-parameter
point only lower bounds are available, and they are shorter. The truth lies
at or above them; cycle 1's value is a plausible upper range for
prevalence. **The estimators themselves are robust:** three methods agree,
the π period changes little, and memory plateaus at τ_int ≈ 60–65 years.

**Which to trust:**

- **for pool generation from x0:** cycle 1's 100–150-year burn-in (still
  right, and necessary because of the parameter change);
- **for how much a same-parameter single point costs:** the cycle 2 bounds.

### 2. Can restart points shorten that?

**Cycle 1:** yes, to zero. The deficit is ICC/k ≤ 1/k if the points are
drawn from π.

**Cycle 2:** same, with three conditions:

- (a) the points must be drawn **under the parameters of the research
  runs**;
- (b) the code must actually **use** them. With the defaults, only the first
  8 points of a pool are used, because points are recycled within each
  batch of 8 ([c2_04](c2_04_design.md));
- (c) a pool does not help **calibration** runs, which change parameters
  anyway. There, only long runs help: 70 years is enough, and 10–50 years
  leaves biases of 3–23% on STI targets and 0.6–1.0 SD on diagnosed
  prevalence.

**What changed and why.** The principle is unchanged. The implementation
and the calibration use case were not examined in cycle 1.

### 3. How many points?

**Cycle 1:** for levels of slow outputs over 20-year windows, k ≈ 0.7–0.8 N
points for an MCSE inflation ≤ 10% (e.g. 206 for N = 256); ≈ 9 for a
variance deficit ≤ 10%.

**Cycle 2**, for the project's outcomes:

- **Stochastic variability is small.** Cumulative incidence over years 6–15
  has a CV of 1.9% (total and Black), 3.4% (White) and 6.0% (Hispanic).
- **Current practice (all runs from x0):** the SD across runs is 0.87 of
  the stationary value, and the level is +2.1% off because of x0's
  parameters.
- **Points actually used by the current code** (8 points × 4 runs):
  - variance deficit 1.4–3%;
  - MCSE of the level ×1.2–1.4.
- **Levels:** MCSE ≤ +10% needs 18 points at N = 32 and 139 at N = 256.
- **Effects (PIA):** under a proportional effect, even one point is
  unbiased. More points are needed only if the effect varies across restart
  states by more than ~0.8 pp (N = 32) or ~0.3 pp (N = 256) for total
  incidence. This is untested and cheap to test.

**What changed and why.** Cycle 1 sized the pool for the precision of mean
*levels* of *slow* outputs. The project's outcomes are faster (cumulative
incidence) and are relative *effects*. For them, 8–20 well-drawn points are
very likely enough, subject to the effect-heterogeneity check.

**Which to trust:**

- **for intervention analyses:** cycle 2;
- **for studies reporting absolute prevalence levels with tight precision:**
  cycle 1.

### 4. Select beyond "processes ongoing"?

**Cycle 1:** no. "Typical" and target-like selection cut the variance of
20-year HIV prevalence to 62% and 40%; stratified random sampling helps.

**Cycle 2:** no, and more precisely:

- **The STI-ongoing filter is harmless:** it rejects 3.2% of states and
  changes variances by ≤ 2%.
- **Closeness to the actual targets hurts slow outputs.** For year-15
  prevalence the variance is 0.65–0.86, depending on intensity. It hardly
  touches 10-year cumulative incidence (≥ 0.94).
- **Proper conditioning on the targets as data changes nothing** unless the
  targets are known to within ~2× the model's own spread. That spread is
  0.3–3% of the value for HIV targets, and 8–28% for STI incidence.
- **Selected states regress to the mean within 10–20 years.**

**What changed and why.** Same direction, now quantified for the project's
outcomes and targets. It adds the interpretation "selection = conditioning
with exact data", and the only legitimate use: STI targets, with a
data-error model.

## What to do next

1. **Rebuild the pool under the current parameters.** Run k independent
   chains from x0 for 100–150 years and save their final states. The 256 ×
   600-year runs could have provided 254 such points if they had saved
   states. A 150-year rerun costs a quarter of that experiment.
2. **Make the code use the pool.** Set `randomize.restart = TRUE`, or size
   the batches to the pool.
3. **Measure effect heterogeneity.** Run 8 pool points × 8 replicates × 2
   scenarios. This decides whether ~8–20 points suffice for PIA.
4. **Same-parameter restart check.** Run 8 runs × 2 years from a state
   saved by these runs, to confirm the restart is seamless (first weeks
   continuous).
5. **Calibration.** Keep ≥ 70 years after a restart made with other
   parameters. Shorten runs only for fast targets, once the slow ones are
   fixed.
6. **Reporting.** Per-run PIA intervals against the baseline median mostly
   reflect run-to-run noise in incidence: ±1.5–1.7 pp in total, ±5 pp for
   Hispanic MSM. Report the MCSE of the median PIA, or pair runs by restart
   point.

## Open issues

- **x0-specific values.** The direct ICC values belong to one state made
  with other parameters. A nested same-parameter experiment (step 3 above,
  baseline arm) would give the average ICC directly.
- **Real target uncertainties** are not in the project files. The
  conditioning analysis uses a common multiple of SD_π.
- **Bootstrap CIs of fitted times** are somewhat optimistic (coverage
  ~0.83–0.90).
