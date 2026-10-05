# Cycle 3 methods

Cycle 3 re-uses the cycle 1 definitions ([../../METHODS.md](../../METHODS.md)
M1–M3) and the cycle 2 ones ([../../cycle2/results/c2_METHODS.md](../../cycle2/results/c2_METHODS.md)
C2-M0 to C2-M7). It adds the following. Sections are cited in the cycle 3
scripts as C3-Mx.

## C3-M0. Provenance

**Run inputs.** slurmworkflow stores the exact `netsim` inputs it ships to
the HPC in `workflows/variance_assess_raw/SWF/steps/2/map.rds`. That file
gives the path of the network estimate, `control`, `init` and the full
`param` list of the cold-start runs.

**Parameters.** Each element of that `param` list is compared with
`identical()` to a list rebuilt from `data/input/model_parameters.csv`
exactly as `R/netsim_settings.R` does. The x0 runs of cycles 1–2 used the
same csv (C2-M0).

**Model code.** The EpiModelHIV-p commit of each run is read from
`renv.lock.hpc` just before and at commit `1ff17d2`. The files of `R/` that
differ between the two commits are listed from the sibling clone.

**Network coefficients.** A restarted run does not take its formation
coefficients from `netest`. It takes them from the restart file
(`x$coef.form[[s]]`, `EpiModel/R/net.mod.init.R`). After that,
`edges_correct()` only adds $\log N_{t-1}-\log N_t$ to every network's edges
coefficient at each step. Hence, for any run,

$$\text{coef}_t = c_0 + \text{offset} + \log(N_{\text{init}}/N_t),$$

- $c_0$ is the edges coefficient of `netest`;
- $N_{\text{init}}$ = 100,000 nodes;
- the offset is a constant that no later step removes.

The offset of a restart file is computed against the local
`netest-hpc.rds`. Its use:

- **The same offset in the three networks** means the file comes from this
  netest, shifted by a population-count mismatch somewhere in its history.
  The correction adds the same amount to every network.
- **Different offsets per network** mean the file comes from another
  network estimate.
- $e^{\text{offset}}$ is the implied ratio of tie propensity, which is close
  to the ratio of mean degree.

## C3-M1. Cold-start annual data

- **Time.** Step 1 is `initialize_msm()`; only `num` is recorded there. Year
  $k$ covers steps $(k-1)\cdot52+1\ldots k\cdot52$.
- **Aggregation.** Stocks are averaged and flows summed (M1.2). Year 1 has
  51 simulated weeks: its flow sums are rescaled by 52/51, and its stocks are
  averaged over those weeks (`annualise()`).
- **Derived variables.** They use the cycle 1 definitions and names (M1.3).
  `derive_vars()` reproduces the cycle 1 values exactly from their raw
  variables; this is checked in c3_01. Project variables follow C2-M1.
- **New target.** The annual analogue of `ir100.hiv.dx.X`, new in
  EpiModelHIV-p 6e6bff15:
  $$100\cdot\frac{\text{new diagnoses}}{\overline{\text{num}.X-\text{hiv.dx}.X-\text{dx.incid}.X}}.$$
- **Blocks.** Cycle 1's `key` and `state` blocks are unchanged. The project
  variables form the `project` block.
- **Chains.** A chain is dropped if HIV or an STI goes extinct. None did.

## C3-M2. Is the stationary law the same?

$\pi_{\text{cold}}$ and $\pi_{x_0}$ are each estimated from years ≥ 300 of
their own chains (global mean, M2.1).

**Per variable.**

- **Statistics:**
  - the mean difference in pooled SD units,
    $d=(\mu_c-\mu_x)/\sqrt{(v_c+v_x)/2}$;
  - the relative difference (%);
  - the variance ratio $v_c/v_x$.
- **CIs:** from independent chain bootstraps of the two experiments.

**Permutation tests.**

- Under $H_0$ the chains of the two experiments are exchangeable, so
  relabelling whole chains gives an exact null.
- Each variable gets a two-sided p-value.
- The global test is single-step max-T: the maximum over variables of
  |statistic| / permutation SD. It accounts for multiplicity and for the
  correlation between variables.
- The statistics are computed from per-chain sums, so 2000 permutations are
  cheap.

**Whole state.**

- **Coordinates:** key and state variables, standardised by the pooled π
  moments and whitened (PCA on the pooled π covariance, 95% of the
  variance).
- **Points:** every chain at the cross-sections 300, 325, …, 600.
- **Test:** the energy V-statistic between the two experiments, with a null
  from chain permutations (`energy_chain_test()`).
- **Placebo:** the same test between two random halves of the cold-start
  chains.

**Validation** (c3_02, 256 vs 254 synthetic chains, six correlated
variables):

- Under $H_0$, the rejection rate at 5% is 0.05 (means) and 0.07
  (variances) over 200 replications. For the energy test it is 0.06 over
  100.
- The power for a 0.1 SD mean shift of one variable is 1.00.

## C3-M3. Relaxation after a cold start

**Curves.** $o(t)$ and $r(t)=v(t)/v_\pi$ are defined as in M2.2. π comes
from years ≥ 300 of the same chains and is recomputed in every bootstrap
replicate.

**Reading $r(t)$ after a cold start.**

- Cold-start chains are independent, so $1-r(t)$ is **not** an ICC as it
  was for $x_0$.
- $r(t)$ measures how dispersed the cold-start law $\mathcal L_t$ is in that
  direction, relative to π.
- It can exceed 1 (over-dispersion).
- For HIV prevalence it starts near 0: the random initialisation fixes the
  population-level state almost exactly.

**Fits.**

- **Variance:** the cycle 1 models, $1-c_1e^{-t/\tau_1}(-c_2e^{-t/\tau_2})$,
  with coefficients of either sign, over years 5–300 (`FIT_START`).
- **Mean:** the cycle 1 models (1-exp, 2-exp, damped cosine, AIC), but
  over a **tail window**. The window starts at the first year after which
  the 5-year running mean of $|o|$ stays ≤ 3 SD (`TAIL_LEVEL`).
- **Why a tail window.** The first decades after a cold start are a
  nonlinear transient: an HIV epidemic overshoot of +15 SD and the
  replacement of the initial cohort. A sum of two exponentials does not
  describe it, and least squares would spend the fit there. Tolerance times
  depend only on the tail, which is close to linear (a straight line on a log
  scale, `figures/c3_04_offset_log_key.png`).

**Tolerance times.**

- $T_{\text{var}}(\varepsilon)$: the year after which the fitted
  $|r(t)-1|$ stays ≤ ε.
- $T_{\text{mean}}(\delta)$: the year after which $|o(t)|$ stays ≤ δ.
  - After the start of the tail window, this is read from the fitted curve.
  - Before it, the offset is several SD, far above the noise, so
    exceedances of large tolerances are read from the running mean of the
    data (`t_tol()`).
- δ = 0.1 and 0.2 SD. δ also takes the brief's MCSE criterion
  $0.2/\sqrt N$ (brief §2.6), the residual bias that inflates the MSE of an
  $N$-run mean by ≤ 4%, for $N$ = 32, 128, 256 and 1024.
- **CIs:** 200 bootstrap refits.

**`EQ_START_C3`** is the rule of cycle 1:

- take the slowest fitted time at 0.1 SD / 10% over the key and state
  variables;
- round it up to 10 years;
- add 50 years.

**Validation** (c3_02). All checks pass with |z| < 3:

- C1, the brief's S1: AR(1), every chain started at 5;
- C2, an over-dispersed random start, where $r>1$;
- C3, an HIV-like overshoot (start at −31 SD, peak near +12.6 SD, tail
  τ = 17.5 y).

Over 30 replications of C3, the CI of the empirical $o(70)$ covers the truth
0.90 of the time, and the CI of $T_{\text{mean}}(0.1)$ 1.00 of the time.

## C3-M4. Residual bias and outcomes of the production workflow

**Residual bias.** $b(T)=o(T)$, read empirically (chain-bootstrap CI) and
from the fit. $b/\text{MCSE}=|o|\sqrt N$ in SD units. The brief's criterion
is $b/\text{MCSE}\le0.2$.

**Ballpark calibration.**

- The target of a $T$-year cold-start run is its value in year $T$, as in
  `swfcalib_model.R`, which averages the last 52 weeks.
- The bias is taken against $\pi_{\text{cold}}$ (SD and %).
- The gap to the target value adds this bias to the gap of
  $\pi_{\text{cold}}$ itself (c3_03).
- The run length for $|b|\le p\%$ uses $\delta=(p/100)\,\mu_\pi/\mathrm{SD}_\pi$
  in `cold_times()`.

**Research runs from a state of age $B$.** A run restarted from the state at
the end of year $B$ covers years $B+1,\ldots$ The outcomes:

- **Cumulative incidence** `cml_*`: HIV infections over years
  $B+6\ldots B+15$ (`outcomes.R`, C2-M1).
- **Year-15 values** `*_y15`: the value in year $B+15$.
- **20-year means** `M20_*`: the mean over years $B+1\ldots B+20$ (cycle 1),
  with two extras:
  - the within-window variance ratio;
  - the mean change over the window (OLS slope × 20) in $\mathrm{SD}_\pi$
    units. This is the spurious trend a research run inherits from an
    unfinished relaxation (brief §2.6).
- **Reference:** the same functional over every window starting at a year
  ≥ 300, all chains, global mean.

**Burn-in needed.**

- $B(\delta)$ comes from the fitted offset curve $o_W(B)$, $B$ = 0–250 (tail
  window, `t_tol()`), with δ = 0.1 and 0.2 SD, the MCSE criterion for
  $N$ = 32 and 256, and 1% of the outcome level.
- The same is computed for the x0 runs, where $B$ = years since $x_0$, each
  against its own π.
- $B=0$ for the x0 runs is the current design: every run starts at $x_0$.
