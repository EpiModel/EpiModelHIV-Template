# C3-04. From the cold start to equilibrium ($T_{\text{cold}}$)

## Question

After the production cold start:

1. How many years until the cross-run mean and variance are stationary?
2. Is the 70-year burn-in (`calibration_end`) enough?
3. How large is the residual bias at year 70, against the Monte Carlo error
   of the planned run counts?
4. How does this compare with a restart from x0 (cycle 1)?

## Method

[c3_METHODS.md](c3_METHODS.md) C3-M3, C3-M4; M2.4 for the energy distance.
Script: `c3_04_cold_start.R`.

- **Curves:** $o(t)$ and $r(t)$ for 66 variables, against π_cold (years
  ≥ 300 of the same chains), with 500 chain bootstraps.
- **Fits:**
  - variance over years 5–300;
  - mean over the tail window, from the first year the offset stays
    ≤ 3 SD;
  - 200 bootstrap refits.
- **Whole state:** 18 whitened components (95.4% of the variance).

## Results

### Tolerance times

Full table: `tables/c3_04_t_cold_wide.csv` (long format:
`tables/c3_04_t_cold.csv`). Years after the cold start:

| variable | tail window from | T_mean(0.1) | T_mean(0.2) | T_var(0.1) | T_var(0.2) |
|---|---|---|---|---|---|
| prev | 54 | 126 [104, 173] | 106 [95, 124] | 66 [53, 165] | 52 [42, 75] |
| prev.B | 52 | 127 [103, 183] | 104 [93, 123] | 84 [53, 179] | 56 [41, 81] |
| prev.W | 56 | 112 [100, 167] | 101 [94, 114] | 55 [42, 120] | 40 [31, 58] |
| prev.H | 48 | 108 [93, 147] | 93 [85, 108] | 30 [22, 117] | 24 [18, 32] |
| i.prev.dx.B | 53 | 126 [98, 163] | 104 [91, 120] | 89 [58, 198] | 58 [45, 89] |
| dx_frac | 48 | 99 [88, 105] | 88 [82, 92] | 60 [50, 87] | 43 [36, 52] |
| num | 47 | 89 [58, 194] | 65 [56, 84] | 44 [34, 176] | 35 [28, 47] |
| incid_rate | 23 | 78 [65, 98] | 58 [53, 63] | 24 [18, 29] | 14 [10, 17] |
| syph_prev | 8 | 78 [55, 83] | 54 [52, 56] | 20 [10, 76] | 12 [8, 18] |
| supp_frac | 19 | 71 [67, 76] | 64 [62, 68] | 43 [33, 62] | 6 [4, 32] |
| gono_prev | 8 | 58 [40, 62] | 38 [36, 41] | 38 [13, Inf] | 10 [0, Inf] |
| chla_prev | 17 | 38 [38, 59] | 36 [35, 40] | 43 [27, 133] | 18 [4, 33] |
| prep_cov | 5 | 35 [31, 40] | 30 [27, 33] | 4 [0, 28] | 2 [0, 5] |

**The prevalence tail.** It is close to one exponential with a time
constant of 13–17 years (`mean_tau1`). The 2-exponential fits of prev,
prev.B, prev.H and i.prev.dx.B add a small slow component with τ ≈ 48–53
years (`mean_tau2`).

**Slowest variance.** The slowest variance times are for Hispanic stocks:
`prep.indic.H` T_var(0.1) = 190 [33, 455] and `num.H` 175 [37, 321]. Their
variance overshoots by 10–30% between years 45 and 210
(`tables/c3_04_block10.csv`, column `r`).

Figures:

- `figures/c3_04_mean_offset_key.png`: $o(t)$ with bands and fits;
- `figures/c3_04_offset_log_key.png`: the tail on a log scale;
- `figures/c3_04_var_ratio_key.png`: $r(t)$.

### Residual bias at year 70

`tables/c3_04_bias70.csv`. SD_π units; b/MCSE = |o|·√N:

| variable | o(70), empirical | o(70), fitted | relative | v(70)/v_π | b/MCSE, N = 32 | b/MCSE, N = 256 |
|---|---|---|---|---|---|---|
| prev | +1.13 [1.00, 1.25] | +1.13 [0.99, 1.27] | +1.6% | 0.92 [0.77, 1.07] | 6.4 | 18.0 |
| prev.B | +0.94 [0.81, 1.06] | +0.96 | +1.2% | 0.95 | 5.3 | 15.0 |
| prev.W | +1.25 [1.13, 1.36] | +1.24 | +3.1% | 0.93 | 7.1 | 20.0 |
| prev.H | +0.70 [0.57, 0.84] | +0.69 | +2.7% | 1.13 | 4.0 | 11.2 |
| i.prev.dx.B | +1.01 [0.89, 1.14] | +1.04 | +1.3% | 0.93 | 5.7 | 16.1 |
| i.prev.dx.W | +1.33 [1.21, 1.47] | +1.29 | +3.4% | 0.97 | 7.5 | 21.3 |
| dx_frac | +0.63 [0.50, 0.77] | +0.60 | +0.19% | 1.05 | 3.6 | 10.1 |
| num | −0.22 [−0.35, −0.09] | −0.15 | −0.07% | 0.97 | 1.2 | 3.5 |
| cc.vsupp.B | −0.22 [−0.34, −0.11] | −0.21 | −0.13% | 0.92 | 1.3 | 3.6 |
| incid_rate | +0.17 [0.04, 0.28] | +0.13 | +0.7% | 0.92 | 0.9 | 2.7 |
| supp_frac | +0.18 [0.06, 0.31] | +0.11 | +0.11% | 1.04 | 1.0 | 2.9 |
| prep_cov | −0.09 [−0.21, 0.03] | 0.00 | −0.06% | 1.03 | 0.5 | 1.4 |
| gono_prev | +0.04 [−0.08, 0.17] | −0.03 | +0.5% | 0.87 | 0.2 | 0.7 |
| chla_prev | +0.09 [−0.02, 0.19] | 0.00 | +0.6% | 0.90 | 0.5 | 1.4 |
| syph_prev | −0.05 [−0.17, 0.07] | +0.14 | −1.0% | 0.99 | 0.3 | 0.8 |

The brief's criterion is b/MCSE ≤ 0.2.

**Burn-in for that criterion** (`T_mean_mcse_N*` in
`tables/c3_04_t_cold.csv`):

| variable | N = 32 | N = 256 | N = 1024 |
|---|---|---|---|
| prev | 170 [118, 323] | 220 [133, 494] | 254 [140, 638] |
| prev.W | 130 [111, 285] | 147 [127, 487] | 159 [137, 610] |
| dx_frac | 115 [95, 154] | 132 [108, 195] | 143 [118, 219] |
| incid_rate | 117 [88, 174] | 157 [111, 258] | 184 [126, 315] |
| STIs | 57–104 | 62–113 | 64–139 |

### The whole state

**Energy distance** to π (`tables/c3_04_energy_summary.csv`,
`tables/c3_04_energy_rule.csv`, `figures/c3_04_energy_distance.png`):

- year 1: 247;
- year 20: 24.7;
- year 50: 3.69;
- year 70: 0.40;
- year 100: 0.062.

The null has median 0.054, 95% quantile 0.063 and maximum 0.069. The
5-year running mean falls below the null maximum at year 99 and below the
95% quantile at year 100.

**Slowest direction** (`tables/c3_04_pc_t_cold.csv`,
`tables/c3_04_pc_loadings.csv`):

- **PC1**, the HIV-prevalence mode (loading −0.90 on prev):
  T_mean(0.1) = 117 [99, 153], T_var(0.1) = 86 [54, 181].
- **PC2**, diagnosis and STIs: T_mean(0.1) = 102 [94, 122].

### Cold start vs restart from x0

`tables/c3_04_compare_x0.csv`, same estimators. Each experiment is against
its own π:

| variable | T_mean(0.1): cold / x0 | T_var(0.1): cold / x0 |
|---|---|---|
| prev | 126 / 83 | 66 / 73 |
| prev.B | 127 / 82 | 84 / 66 |
| dx_frac | 99 / 94 | 60 / 26 |
| incid_rate | 78 / 55 | 24 / 2 |
| num | 89 / 48 | 44 / 75 |
| gono_prev | 58 / 36 | 38 / 36 |
| chla_prev | 38 / 54 | 43 / 42 |
| syph_prev | 78 / 62 | 20 / 59 |

### Equilibrium start for c3_06

`tables/c3_04_eq_start.csv`:

- the slowest key or state time at 0.1 / 10% is `prep.indic.H` T_var(0.1)
  = 190;
- the rule gives `EQ_START_C3` = **240**.

## Interpretation

1. **$T_{\text{cold}}$ is about 100–130 years, set by HIV prevalence.**
   - **The transient.** The cold start triggers an epidemic overshoot of
     +15 SD_π around year 25, which then decays with τ ≈ 13–17 years.
   - **Mean within 0.2 / 0.1 SD:** ≈ 105 / 125 years for prevalence and
     diagnosed prevalence, ≈ 100 years for the diagnosed fraction.
   - **Whole state:** it cannot be told apart from π after ≈ 100 years (the
     energy distance at the null level; PC1 at 117 years).
   - **Faster outputs:** STIs, PrEP coverage and suppression take 35–80
     years.
2. **70 years is not enough for prevalence-type outputs.**
   - **The bias at year 70.** Prevalence and diagnosed prevalence are
     +0.7 to +1.3 SD_π above π (+1.2% to +3.4%). That is 4–8 MCSE for 32
     runs and 11–21 for 256, against the criterion 0.2.
   - **The cascade and population size** are within 0.2–0.6 SD.
   - **STI and PrEP outputs** are within ±0.13 SD. For them, 70 years is
     adequate.
3. **The variance is less of an issue than the mean.** At year 70 the
   variance ratios are 0.83–1.17 for the key outputs. Independent cold
   starts begin almost identical at the population level (c3_01), so the
   slow variables need 55–90 years to spread fully. That is as long as
   after a single restart point: 66 vs 73 years for prevalence.
4. **A cold start is slower than a restart from x0, for the mean.**
   - It starts much further away (−8.6 SD in year 1, then an overshoot of
     +15 SD, against x0's −0.4 SD in year 1, cycle 1 `04_t_full.csv`). The prevalence mean needs
     ≈ 125 years instead of ≈ 85.
   - For the STIs the two are similar (35–80 years).
5. **The MCSE criterion sets a much longer burn-in** for the slow outputs:
   ≈ 130–220 years for prevalence at N = 32–256. Its upper CIs are
   285–840 years. With 256 chains a residual bias below ~0.05 SD cannot be
   resolved. The fitted slow component (τ ≈ 48–53 years, `mean_tau2`) may
   be real or a noise excursion; see `figures/c3_04_offset_log_key.png` and
   `tables/c3_04_block10.csv`, where the offset of prevalence hovers at
   +0.05 to +0.14 SD between years 115 and 185.

## Decision / input for next steps

- **Burn-in from a cold start:**
  - ≥ 110–130 years for prevalence-type outputs within 0.1 SD;
  - ≈ 170–220 years to meet the brief's MSE criterion for 32–256 runs;
  - 70 years is enough only for STI, PrEP and suppression outputs.
- **`EQ_START_C3` = 240** for c3_06.
- c3_05 translates these times into the calibration targets and the
  research outcomes.

## Caveats and deviations

- **The tail window** (C3-M3) is a change from the brief, which fits from
  year 5. It is validated in c3_02, where both give the same answer on an
  exact 2-exponential overshoot. On real data the tail window avoids
  fitting the nonlinear overshoot.
- **T_var(0.1) CIs are wide** (upper ends 120–200 years for prevalence), as
  in cycles 1–2. ε = 0.2 is the reliable tolerance.
- **The Hispanic variance overshoot** (`num.H`, `prep.indic.H`) drives the
  EQ_START rule. The key outputs alone would give 180. 240 is kept as the
  conservative choice.
- **π comes from years ≥ 300 of the same chains.** With T_cold ≈ 100–130,
  this leaves a margin of ≥ 170 years.
