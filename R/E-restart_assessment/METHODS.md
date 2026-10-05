# Methods

Notation used in the code and results. Section numbers (M1 …) are cited in the
script comments.

## M1. Data and annual aggregation

- **Design.** 256 chains, all started from **one common restart state** $x_0$,
  run for 600 years (31,200 weekly steps) with a single fixed parameter set.
  The first recorded step is identical in all chains, which confirms the
  common start (`01_raw_inventory.csv`, `x0`).
- **Dropped chains.** Syphilis went extinct (absorbing) in chains 75 and 88
  (`01_extinctions_year.csv`). They are removed from all analyses, leaving
  $C = 254$ chains, so π means the *quasi-stationary* law conditional on
  syphilis persistence.
- **Time.** Year $k$ after the restart covers steps
   $(k-1)\cdot52+2 \ldots k\cdot52+1$. Year 0 is $x_0$.
- **Aggregation (M1.2).** Flows (`*.incid`, arrivals, departures) are summed
  over the year. Stocks are averaged over the year.
- **Derived variables (M1.3).** These are always ratios of annual aggregates:
  - prevalence = infected / population;
  - HIV incidence per 100 person-years = 100 × annual infections / mean
    susceptibles;
  - diagnosed fraction and suppressed fraction, both among people living
    with HIV;
  - PrEP coverage = on PrEP / PrEP-indicated;
  - STI prevalence;
  - STI incidence per 100 person-years = 100 × annual infections / population.

  All are given in total and by race (B/H/W).
- **Blocks.**
  - `key` = the reported outputs above.
  - `state` = race-specific stocks (population, infected, diagnosed, on ART,
    suppressed, on PrEP, PrEP-indicated) and STI site stocks. Totals are exact
    sums of these, so they are left out.
- **Storage.** Each variable is a matrix $Y$[year, chain].

## M2. Concepts and estimators

### M2.1 Laws

- $\mathcal L_t$ is the law of the state $t$ years after the restart. Its 254
  chains are an iid sample.
- π is the stationary law, estimated by pooling all chains over years ≥
  `LATE_START` = 300: $\hat\mu_\pi$ and $\hat v_\pi$ use the global mean.
- Moments at year $t$: $m(t)$ is the cross-chain mean and $v(t)$ the
  cross-chain variance.

### M2.2 Restart memory and the single-point experiment

**What the ICC is.** Start many runs from the same restart state and look
at an output $h$ years later.

- The runs differ because of chance events after the restart, but they also
  share the push of their common starting state.
- The **intraclass correlation**, $\mathrm{ICC}(h)$, is the share of the
  output's stationary variance that is due to *which* state the runs
  started from.
- Equivalently, it is the correlation between two runs started from the
  same state. This is the ICC of cluster-randomised trials, with restart
  states as clusters and runs as their members.
- It is 1 when the starting state fully determines the output, and 0 when
  the starting state no longer matters.
- It decreases with $h$ as the model forgets its start.

**The decomposition.** Restart from a state $X_0$ drawn from π and observe
an output $Y_h$ $h$ years later. The law of total variance splits its
variance in two:
$$\operatorname{Var}(Y_h)=\underbrace{\operatorname{Var}(\mathbb E[Y_h\mid X_0])}_{\sigma_B^2(h)}+\underbrace{\mathbb E[\operatorname{Var}(Y_h\mid X_0)]}_{\sigma_W^2(h)},\qquad \mathrm{ICC}(h)=\sigma_B^2(h)/v_\pi .$$

The elements:

- $X_0$ is the full saved state: every person's attributes, the network,
  and the internal clocks.
- $Y_h$ is the output, e.g. HIV prevalence, $h$ years after the restart.
- $\mathbb E[Y_h\mid X_0]$ is the mean of $Y_h$ over (infinitely) many runs
  from that same $X_0$: the "expected future" of this restart state.
- $\operatorname{Var}(Y_h\mid X_0)$ is the variance of $Y_h$ across runs
  from that same $X_0$: the spread created by chance after the restart.
- $\sigma_B^2(h)$ (B for **between** restart states) is the variance of the
  expected future across restart states drawn from π: how much the
  starting state moves the output.
- $\sigma_W^2(h)$ (W for **within** a restart state) is the chance spread,
  averaged over restart states.
- $v_\pi=\operatorname{Var}(Y_h)$ is the stationary variance. When $X_0$ is
  drawn from π, $Y_h$ is also distributed as π, so the two parts add up to
  $v_\pi$ at every $h$.

Hence $\mathrm{ICC}(h)=\sigma_B^2(h)/v_\pi=1-\sigma_W^2(h)/v_\pi$. Runs that
share a restart state are correlated, so they carry less information than
independent runs. M3.1 turns the ICC into the design effect and the loss of
precision.

**The single-x0 estimate.** The dataset contains 254 replicate futures of
**one** state $x_0$. Because all runs share $x_0$, their variance across
runs at year $h$, $v(h)$, is the within-state variance
$\operatorname{Var}(Y_h\mid x_0)$ of that one state. This gives a direct
estimate of *its* ICC:
$$\widehat{\mathrm{ICC}}_{x_0}(h)=1-v(h)/\hat v_\pi .$$

- This is the variance that is *missing* at horizon $h$ when every run
  starts from $x_0$. That is exactly the question "how long until full
  variance".
- It measures one $x_0$ only. $\mathrm{ICC}(h)$ is its average over
  $x_0\sim\pi$.
- The mean offset $o(t)=(m(t)-\hat\mu_\pi)/\hat\sigma_\pi$ measures how
  atypical $x_0$ still is after $t$ years. It is a bias shared by every run
  from $x_0$ and is invisible in any single-point experiment.

**Drift tests.** Regress $m(t)$ and $v(t)$ on $t$ over a late period. Express
the slopes per century, in SD units (mean) or relative units (variance), with
chain-bootstrap CIs. Flag a variable when the CI excludes 0 **and** the drift
exceeds 0.05.

### M2.3 Lower bounds on ICC from pseudo-restarts

- **Pseudo-restarts.** Take every (chain, $t_0$) with $t_0$ in the stationary
  period, every 5 years. $F$ = all key and state variables at $t_0$ and at
  $t_0-1, t_0-2, t_0-5$. Nothing after $t_0$ is used.
- **The bound.** By the Markov property,
  $$R^2_F(h)=\operatorname{Var}(\mathbb E[Y_{t_0+h}\mid F])/\operatorname{Var}(Y)\le\mathrm{ICC}(h).$$
  Any out-of-sample $R^2$ is below $R^2_F$, so it is also a lower bound.
- **Models.**
  - Ridge on all features. λ is chosen per response by an inner 4-fold CV.
    Features are standardised on training rows only.
  - An "own-value" model that uses only the response variable at $t_0$. For
    values it gives ≈ $\rho(h)^2$.
- **Validation.** 8 folds **blocked by chain**. $R^2_{oos}$ is taken against
  the π mean. CIs come from resampling chains of out-of-sample residuals.
- **Reported bound.** $\max(0, R^2_{\text{ridge}}, R^2_{\text{own}})$.
- **Reference curves.** $\rho(h)^2 \le \mathrm{ICC}(h)$ is a bound.
  $\rho(2h)$ equals ICC only for reversible processes. This model is not
  reversible, so $\rho(2h)$ is a heuristic only.
- **What the bounds miss.** Memory held in unobserved state (network
  structure, individual clocks) is invisible here. The direct single-$x_0$
  estimate includes it.

### M2.4 Distances between distributions

- **Energy distance, V-statistic.**
  $\mathcal E=2\overline{\|x-y\|}-\overline{\|x-x'\|}-\overline{\|y-y'\|}$,
  diagonals included.
- **Coordinates.** Key and state variables are standardised by π moments,
  then whitened with a PCA on the π covariance. Components are kept up to
  95% of the variance.
- **Null.** For each of 20 random half-splits, half A at year $t$ is compared
  with half B pooled at years 300, 350, …, 550. Values for $t\ge300$ are a
  null sample.

### M2.5 Time to full variance

**Detection rules fail here.** This includes the brief's rule (first year
after which $D(t)$ exceeds its null 95% quantile in ≤5% of years, with runs
≤3) and a null-maximum variant.

- $D(t)$ is autocorrelated in $t$ because the same chains are followed over
  time. A stationary stretch of 250 years therefore exceeds any fixed null
  threshold by chance with probability near ½.
- On synthetic data both rules return ≈200–300 years for series whose truth
  is 15–30 years, including one that is stationary from year 0
  (`02_validation.csv`).

**Rule used instead: tolerance on fitted relaxation curves.**

- **Variance.** Fit $r(t)=v(t)/v_\pi$ with $1-c_1e^{-t/\tau_1}$ or
  $1-c_1e^{-t/\tau_1}-c_2e^{-t/\tau_2}$ (AIC, needing an improvement ≥ 2).
  $T_{\text{var}}(\varepsilon)$ is the first time after which the fitted
  deficit stays ≤ ε.
- **Mean.** Fit $o(t)$ with 1-exp, 2-exp or damped-cosine models.
  $T_{\text{mean}}(\delta)$ is the first time after which the fitted |offset|
  stays ≤ δ SD.
- **Fitting.** Fits use years 1–300. CIs come from refitting on 200 chain
  bootstraps.
- **Resolution.** Yearly $v(t)$ has a relative SE of ≈ $\sqrt{2/253}$ ≈ 9%.
  $T_{\text{var}}(0.05)$ is therefore close to the resolution of the data and
  its upper CIs are long. ε = 0.1 and 0.2 are the reliable tolerances.

### M2.6 Autocorrelation

- **Pooled ACF.** Uses the global mean and variance on years ≥ `EQ_START`
  (150), with no per-chain demeaning.
- **Fast computation.** An exact per-chain decomposition (FFT for lagged
  products) lets the chain bootstrap recompute it cheaply.
- **Integrated autocorrelation time.**
  $\tau_{\text{int}}=1+2\sum_{k\ge1}\rho(k)$ with Geyer's initial monotone
  sequence.

### M2.7 Windows

For a research window of $L=20$ years, with window mean $M_L$ and
within-window variance $S^2_L$ (divisor $L$):
$$v_\pi=\underbrace{\mathbb E[S_L^2]}_{\text{over time}}+\underbrace{\operatorname{Var}(M_L)}_{\text{over runs}}$$

- The identity is exact on pooled windows with the global mean. It is checked
  numerically.
- **Variance–time curve.** $L\operatorname{Var}(M_L)/v_\pi\to\tau_{\text{int}}$.
- **Burn-in.** A window after a post-restart burn-in $B$ covers years
  $B+1\ldots B+L$.
- **From $x_0$.** The between-run share is
  $\operatorname{Var}(M_L(B))/\operatorname{Var}_\pi(M_L)$ and the
  within-run share is $\overline{S^2_L(B)}/\mathbb E_\pi[S^2_L]$.

### M2.8 Uncertainty

- **Chain bootstrap.** Resample the 254 chains with replacement and
  recompute everything, including the π reference. CIs are 95% percentile
  intervals.
- **Known under-coverage.** The ACF CIs cover ≈ 0.9 instead of 0.95 in the
  validation.

## M3. Pool design

### M3.1 Variance and precision with k points

Take k points iid from π, with N runs spread evenly over them (n = N/k). For
an output with ICC c and stationary variance V:

- **Variance across runs.**
  $\mathbb E[\text{variance across runs}]=\sigma_W^2+\sigma_B^2\,n(k-1)/(N-1)=V\,[1-c\,(1-n(k-1)/(N-1))]\approx V(1-c/k)$
  for large n. The deficit is $c/k$.
- **Precision of the grand mean.**
  $\operatorname{Var}(\bar Y)=V\,[c/k+(1-c)/N]$. The MCSE inflation relative
  to one point per run is $\sqrt{1+c(N/k-1)}$.
- **Points needed.** For an MCSE inflation ≤ 1+g:
  $k\ge Nc/((1+g)^2-1+c)$.
- **Time to full variance with k points.** For an annual value at horizon
  $h$, the deficit is $\mathrm{ICC}(h)/k$. $T(k,\varepsilon)$ is the first
  horizon after which it stays ≤ ε.
- **Design ICC.** The larger of the lower bound (M2.3) and the direct
  single-$x_0$ value (M2.2), clipped to [0, 1].

### M3.2 Generating the pool

- **Independent chains.** k chains started from $x_0$ and run for
  $T_{\text{full}}$ years give k (nearly) iid draws from π. Their residual
  shared component is $\mathrm{ICC}_{x_0}(T_{\text{full}})$.
- **One chain.** Points spaced d years apart along one chain are correlated.
  With the pooled ACF as a proxy, the effective size is
  $k_{\text{eff}}=k^2/\sum_{ij}\rho(|i-j|d)$.

### M3.3 Selection experiment

- **Replicates.** Each replicate draws one state per chain at a random
  stationary year, giving 254 iid π draws. Each state has one realised
  20-year future.
- **Strategies.** Each picks 32 of the 254:
  - random;
  - "ongoing" (STI prevalence above the π 1% quantile, then random);
  - "typical" (closest to the π mean in the whitened state);
  - "target-like" (closest to the π means of five headline outputs);
  - stratified (32 strata on state PC1, one random point each).
- **Metrics.** Over 2000 replicates:
  - bias of the pool mean;
  - its RMSE;
  - Var(futures)/Var_π, which should be 1 for a faithful pool;
  - within-window variance ratio.
