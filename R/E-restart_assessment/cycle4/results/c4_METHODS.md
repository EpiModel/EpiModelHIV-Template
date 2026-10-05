# Cycle 4 methods

Cycle 4 re-uses the definitions of cycles 1–3:

- [../../METHODS.md](../../METHODS.md) M1–M3;
- [../../cycle2/results/c2_METHODS.md](../../cycle2/results/c2_METHODS.md)
  C2-M0 to C2-M7;
- [../../cycle3/results/c3_METHODS.md](../../cycle3/results/c3_METHODS.md)
  C3-M0 to C3-M4.

It adds the following. Sections are cited in the cycle 4 scripts as C4-Mx.

## C4-M0. Provenance

**Run inputs.** They come from the slurmworkflow map of the pool runs
(`workflows/variance_assess_pool/SWF/steps/2/map.rds`):

- the restart file;
- `start`, `nsteps`, `randomize.restart`, `initialize.FUN`;
- the parameter list, compared element by element with that of the
  cold-start runs.

**Network coefficients.** The offset of each point's edges coefficients is
computed against the local `netest-hpc.rds` as in C3-M0:
coef − c₀ − log(N_init/N). A point saved from a run that started from this
estimate, with a consistent population correction, has offset 0.

## C4-M1. Design and annual data

**Design.**

- 256 runs of 600 years, restarted at step 2 from a pool of k = 32 states.
- `randomize.restart = TRUE`: each run draws its point uniformly with
  replacement.

**Identifying the point of each run.** The first recorded row of a
restarted run is the copied state, so each run's point is identified by
matching that row with the pool's saved rows. The pool's rows are matched
in turn with the last rows of the cold-start runs (cycle 3).

**Counts.** $n_j$ runs per point, $N=\sum_j n_j$ = 256. The design constant
$\sum_j n_j^2/N$ appears in every pool formula below.

**Time.** As for the x0 runs of cycles 1–2: year $k$ after the restart
covers steps $(k-1)\cdot52+2\ldots k\cdot52+1$, and year 0 is the saved
state. The derived variables are those of C3-M1.

## C4-M2. Direct ICC, averaged over π

The 32 points are stationary states: year 600 of independent cold-start
runs, 460 years after the cold-start transient ended (c3_04). For an output
$Y$ at horizon $h$ (a value $h$ years after the restart, or a window
functional after a burn-in $B$):

- **Within-point variance.** $\hat\sigma^2_W(h)$ is the pooled variance of
  runs around their point mean, divisor $N-k$ = 224.
- **Main estimator:**
  $$\widehat{\mathrm{ICC}}_w(h)=1-\hat\sigma^2_W(h)/\hat v_\pi,$$
  with $\hat v_\pi$ from years ≥ 300 of the same runs (π_pool = π_cold,
  c4_03). This is the share of the stationary variance that runs from the
  same point do not show, i.e. the share fixed by the point.
  - It is precise: 224 df.
  - It uses no model of the restart state.
  - It assumes that the points are draws from π, so that the total variance
    is $v_\pi$.
- **Check estimator:** the ANOVA intraclass correlation
  $\hat\sigma^2_B/(\hat\sigma^2_B+\hat\sigma^2_W)$, with
  $\hat\sigma^2_B=(MS_B-\hat\sigma^2_W)/n_0$ and
  $n_0=(N-\sum n_j^2/N)/(k-1)$. It needs no π reference but rests on 32
  points. It is biased low and its CIs undercover (c4_02).
- **CIs:** a bootstrap over points: points are drawn with replacement and
  keep all their runs, and π is recomputed in each replicate.
- **Window functionals:**
  - `M20`: the mean over years $B+1\ldots B+20$;
  - `cml10`: HIV infections over years $B+1\ldots B+10$, where $B=5$ is the
    project's years 6–15;
  - $B$ = 0–150, with the π reference over every window starting at a year
    ≥ 300.

**Unobserved memory.** The lower bounds of cycles 1–3 (M2.3) use observed
summaries at $t_0$ and lags. Hence
$\mathrm{ICC}_w-\mathrm{LB}$ is the memory held in state the summaries do
not carry: the network, individual histories, the age structure. The lower
bounds of the same model come from c3_06 (cold start, years 240–600).

**A single same-parameter point.**

- The runs of one point have variance $w(h)=\hat\sigma^2_W(h)/\hat v_\pi$,
  averaged over points drawn from π.
- $w(h)$ is fitted with the cycle 3 variance model over $h$ = 1–150 (or $B$
  = 0–150).
- $T(\varepsilon)$ is the time after which the fitted $1-w$ stays
  ≤ ε, i.e. the time to full variance from one restart point.
- **CIs:** 200 bootstrap refits.

## C4-M3. Is the restart seamless?

**Weekly seam.** Cross-run means of the restarted runs at weeks 0–104, and
of their source chains at weeks −104…0. Each source chain is weighted by
its number of runs, so both sides average over the same states.

- The first step after the restart is compared with every other week:
  increments for stocks, levels for flows. The score is
  z = (first − median)/MAD (C2-M0).
- **Global:** the maximum |z| over variables in the restart week, against
  the same maximum in each of the 206 ordinary weeks.

**One-year change.** $D_i$ = (first simulated year of run $i$, steps 3–54)
− (year 600 of its source chain).

- Under a seamless restart, $D$ has the distribution of a stationary
  one-year change of the cold-start chains, $Y_{t+1}-Y_t$ for $t$ =
  300–599.
- **Per variable:** mean($D$) in SD_π units with a point-bootstrap CI, and
  var($D$) against the stationary value.
- **Global test:** max over 66 variables of |mean($D$)| / null SD.
  - The null is the same statistic computed on 32 random cold-start chains
    at a random year, with no restart, weighted by the run counts.
  - It is conservative: it has one continuation per chain, while the pool
    statistic averages several runs per point.
- **Validation** (c4_02): the rejection rate is 0.045 under H0, and the
  power is 1.00 for a 0.1 SD jump.

**Same stationary law.** The tests of C3-M2 (per-chain sums, chain
permutations, max-T, energy with chain blocks) on years ≥ 300, pool runs
against the cold-start runs and against the x0 runs. Runs from the same
point are exchangeable with independent chains by then (ICC(300) ≈ 0,
c4_04).

## C4-M4. Pool design with the direct ICC

For N runs spread over k points drawn iid from π, with counts $n_j$ and
ICC $c$:

- **Across-run variance:**
  $\mathbb E[s^2]/v_\pi=1-c\,(\sum n_j^2/N-1)/(N-1)$.
- **MCSE of the mean:**
  $\sqrt{(1+c(\sum n_j^2/N-1))/N}\,\mathrm{SD}_\pi$.
- **Inflation** against N independent points:
  $\sqrt{1+c(\sum n_j^2/N-1)}$.

The two assignments differ in $\sum n_j^2/N$:

- **Balanced** ($n=N/k$ runs per point): $\sum n_j^2/N=n$.
  - Inflation $\sqrt{1+c(n-1)}$.
  - Points for inflation ≤ 1+g: $k\ge Nc/((1+g)^2-1+c)$ (cycle 1).
- **`randomize.restart`** (with replacement):
  $\mathbb E[\sum n_j^2/N]=N/k+1-1/k$.
  - Inflation $\sqrt{1+c(N-1)/k}$.
  - Points: $k\ge c(N-1)/((1+g)^2-1)$. Even $k=N$ leaves
    $\sqrt{1+c(N-1)/N}$.

The CIs for k come from the CI of $c$: the formulas are monotone in $c$.

**Burn-in with k points.** With many runs per point, the variance deficit
at horizon $h$ is $\mathrm{ICC}(h)/k$. $T(k,\varepsilon)$ is read from the
fitted curve.

**The realised pool.** Its across-run variance and mean offset, compared
with the formulas for its own counts.
