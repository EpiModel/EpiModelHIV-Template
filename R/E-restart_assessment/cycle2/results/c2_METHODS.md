# Cycle 2 methods

Cycle 2 re-uses the cycle 1 definitions ([../../METHODS.md](../../METHODS.md)
M1–M3) and adds the following. Sections are cited in the cycle 2 scripts as
C2-Mx.

## C2-M0. Provenance and continuity

**x0 source.** The first recorded row of the variance runs is matched
against the last epi row of every restart file in `data/run/estimates/`, on
13 stocks. An exact match identifies the file.

**Parameters.** The file's `param` list is compared with
`data/input/model_parameters.csv`, which the variance runs used through
`netsim_settings.R`:

- a vector parameter `name` maps to the csv rows `name_1`, `name_2`, …;
- a parameter "differs" if the relative difference exceeds 1% or it is
  absent from x0.

**Restart continuity.** On weekly cross-chain means:

- for stocks, the first weekly increment is compared with the increments
  of weeks 2–26;
- for flows, the first-week level is compared with the levels of weeks
  2–26;
- the statistic is z = (first − median) / MAD.

A restart artifact would appear as a first-week jump. A parameter change
also acts from the first week, so the two cannot be separated with this
data alone.

## C2-M1. Project variables

These follow `EpiModelHIV::mutate_calibration_targets()` and
`D-interventions/outcomes.R`, as ratios of annual aggregates:

| variable | definition |
|---|---|
| `i.prev.dx.X` | hiv.dx.X / num.X |
| `cc.vsupp.X` | hiv.supp.X / hiv.dx.X |
| `cc.dx.X` | `dx_frac.X` |
| `cc.prep.X` | `prep_cov.X` |
| `ir100.sti` | 100 · annual infections / mean (num − infected) |
| `disease.mr100` | 100 · AIDS departures / hiv.inf |
| `cml_incid.X` | HIV infections summed over the 10-year intervention window (years 6–15 after restart) |

The weekly-ratio definitions in the package average weekly ratios over the
last year. The annual ratio of aggregates differs from them only by
second-order terms.

## C2-M2. Windows from the restart

For a window of L years starting after a burn-in B, the functional covers
years B+1 … B+L after the restart. It is a sum for cumulative incidence and
a mean otherwise.

- **Stationary reference.** All windows starting every year from
  `EQ_START`, all chains, with the global mean.
- **Between-run share from x0.** $\operatorname{Var}_{x_0}(W_B)/\operatorname{Var}_\pi(W)$.

## C2-M3. Relaxation estimators

Three estimators of $T_{\text{var}}(\varepsilon)$ are compared:

- **cycle 1 fits:** 1 or 2 exponentials;
- **stretched exponential:** $r(t)=1-c\,e^{-(t/\tau)^\beta}$;
- **isotonic (nonparametric):** a monotone non-decreasing least-squares fit
  of $r(t)$ (`isoreg`); the first year the fit reaches 1 − ε.

CIs come from 200 chain bootstraps.

**Mean relaxation.** The cycle 1 models are 1-exp, 2-exp and damped
cosine. The selected model and its time constants are reported
(`c2_02_t_direct_x0.csv`).

## C2-M4. Same-parameter lower bound on the burn-in

For a restart point drawn from π under the parameters of the research runs,
$\mathrm{ICC}(h)\ge \mathrm{LB}(h)$. LB is the out-of-sample $R^2$ of the
cycle 1 ridge predictor (M2.3), extended to horizons up to 80 years. Hence:

$$T_{\text{same}}(\varepsilon)\ \ge\ T_{\text{LB}}(\varepsilon)=\min\{h:\ \mathrm{LB}(h')\le\varepsilon\ \ \forall h'\ge h\}.$$

- **Grid.** 5, 10, 15, 20, 30, …, 80 years.
- **The direct x0 value** $1-v(h)/v_\pi$ is **not** an upper bound. It is
  one realisation for one state made with other parameters, and it falls
  below LB in some cases (`c2_03_claim_lb_vs_direct.csv`).

## C2-M5. Robustness checks

- **π reference.** Years ≥ 150, ≥ 300 or ≥ 450.
- **Nonlinear lower bound.** Adds the squares and pairwise products of the
  first 10 PCs of the standardised lag-0 features. The gain in $R^2$ has a
  paired chain-bootstrap CI.
- **Long memory.** $L\operatorname{Var}(M_L)/v_\pi$ at L = 75, 150, 225,
  450 on years 151–600. Chain means over 450 years are checked for
  normality (heavy tails would indicate chain-level persistent components).
- **Replication study.** 30 synthetic datasets for each of S0, S1 and S2
  (cycle 1 definitions). Each one gets both detection rules and the
  fit-based $T_{\text{var}}(0.1)$ and $T_{\text{mean}}(0.1)$, with CIs from
  100 bootstrap refits. The study reports the distribution of the rules and
  the coverage of the fit CIs.

## C2-M6. Designs

**Recycling.** EpiModel restarts simulation s of a `netsim` call from source
run $(s-1) \bmod k + 1$. EpiModelHPC runs each batch of `n_cores` runs as
one `netsim` call, so only points 1…`n_cores` are used. With N runs on those
8 points (n = N/8 per point) and ICC c:

- expected across-run variance deficit: $c\,(n-1)/(N-1)$;
- MCSE inflation of the mean: $\sqrt{1+c\,(n-1)}$.

**`randomize.restart = TRUE`.** Each run draws a point independently with
replacement. The MCSE inflation is $\sqrt{1+c\,(N-1)/k}$.

**Effects (PIA/NIA as in `outcomes.R`).**

- **Model.** $Y=g(X)(1+\epsilon)$ with within-state CV $\mathrm{CV}_w$, and
  an intervention that multiplies $g$ by $1-e(X)$.
- **Proportional effect** ($e(X)=e$). The pool mean of $g$ cancels in PIA
  to first order, so a single restart point gives an unbiased PIA.
- **Effect heterogeneity.** With SD $\sigma_e$ across states, a single
  point adds a bias with SD $\sigma_e$.
- **MCSE of the median-based PIA.** $(1-e)\,\mathrm{CV}_w\sqrt{\pi/N}$ (two
  medians of N runs).
- **Threshold.** A single point doubles the RMSE when
  $\sigma_e=\sqrt3\,\mathrm{MCSE}$.

## C2-M7. Selection and conditioning

**Candidates.** Each replicate takes one state per chain at a random
stationary year (254 iid π draws). The distance is
$d^2=\sum_j\big((T_j-\text{target}_j)/\mathrm{SD}_\pi(T_j)\big)^2$ over 16
calibration targets (`cc.prep` total is excluded because of a definition
mismatch).

**Strategies:**

- **keep_q:** keep the fraction q closest to the targets, then draw 32 at
  random. This isolates selection intensity at a fixed pool size.
- **weight_f:** sample 32 with replacement with weights
  $\propto\exp(-d^2/2f^2)$. This is Bayesian conditioning on the targets
  treated as data with independent Gaussian errors of SD $f\cdot\mathrm{SD}_\pi$.
  The effective sample size of the weights is reported.
- **sti_filter:** the project rule from `3-choose_restart.R` (every STI
  ir100 ≥ 50% of its target), then random.

**Futures.** Cumulative HIV incidence over years 6–15 after the state, and
diagnosed prevalence and prevalence at year 15. The metrics are bias (SD
units and %) and Var(futures)/stationary variance, over 2000 replicates.

**Regression to the mean.** Take the 12.5% of 5000 random states closest to
the targets and follow their distance to the targets, and the mean and SD
of i.prev.dx.B, over the next 40 years, against all states.
