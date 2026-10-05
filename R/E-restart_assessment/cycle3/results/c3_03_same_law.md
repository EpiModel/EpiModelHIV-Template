# C3-03. One model or two? The stationary laws of the two experiments

## Question

1. Do the cold-start runs settle into a stationary law?
2. Is it the law of the x0 runs of cycles 1–2, which share the parameter
   file and the model code (c3_01)?
3. Which of the two matches the calibration targets?

## Method

[c3_METHODS.md](c3_METHODS.md) C3-M2; drift tests as cycle 1 M2.2. Script:
`c3_03_same_law.R`.

- **Drift:** the cold-start runs over years 300–600 and 150–600.
- **Per variable:** π_cold vs π_x0, each from years ≥ 300 of its own chains;
  63 key, state and project variables.
- **Whole state:** a two-sample energy test on the whitened state.
- **Permutations:** 2000, of whole chains.

## Results

### Stationarity of the cold-start runs

7 of 106 drift tests are flagged, all over 300–600 and none over 150–600
(`tables/c3_03_drift.csv`):

- **Mean drift, SD_π per century, of one signal:** the Black population and
  its HIV stocks:
  - `num.B` −0.076 [−0.122, −0.028];
  - `hiv.inf.B`, `hiv.dx.B`, `hiv.tx.B`, `hiv.supp.B`: −0.054 to −0.058;
  - the total `num`: −0.053.
- **Variance drift:** `num.H`, +6.3% per century [0.6, 11.3].

### π_cold vs π_x0, variable by variable

`tables/c3_03_law_compare.csv`:

- **Means:** 60 of 63 variables differ at p < 0.05. The global max-T
  test gives max |z| = 33.2, p = 0.0005, the smallest p possible with 2000
  permutations (`tables/c3_03_law_global.csv`).
- **Variances:** 13 of 63 differ at p < 0.05; global max |z| = 7.3,
  p = 0.0005.

| variable | cold − x0 (pooled SD_π) | relative difference | variance ratio |
|---|---|---|---|
| prev | +2.43 [2.34, 2.52] | +3.6% | 0.96 |
| prev.B | +2.27 [2.19, 2.35] | +3.0% | 0.97 |
| prev.W | +2.28 [2.19, 2.37] | +6.1% | 0.96 |
| prev.H | +1.26 [1.20, 1.32] | +5.1% | 0.99 |
| i.prev.dx.B | +2.26 [2.18, 2.35] | +3.1% | 0.98 |
| chla_prev | +1.73 [1.68, 1.78] | +12.5% | 0.98 |
| gono_prev | +1.56 [1.51, 1.61] | +19.7% | 0.99 |
| syph_prev | +1.05 | +26.3% | 0.97 |
| incid_rate | +0.96 | +4.1% | 1.04 |
| prep.indic.B | −1.41 [−1.47, −1.35] | −1.5% | 0.97 |
| dx_frac | +0.46 | +0.14% | 0.98 |
| supp_frac | +0.26 | +0.15% | 0.97 |
| num | −0.08 | −0.03% | 0.99 |
| prep_cov | −0.03 | −0.02% | 1.01 |

The largest variance differences are +5–6% for Hispanic and White HIV
incidence, and −5% for suppression among Hispanic and White MSM.

Figures: `figures/c3_03_law_means.png` (all key and project variables) and
`figures/c3_03_means_both.png` (cross-chain means of both experiments over
600 years).

### Whole state

`tables/c3_03_energy_test.csv`, 18 whitened components, 13 cross-sections:

| comparison | energy | null median | null 95% | p |
|---|---|---|---|---|
| cold start vs x0 runs | 0.428 | 0.0045 | 0.0077 | 0.0005 |
| placebo: two halves of the cold start | 0.0083 | 0.0078 | 0.0109 | 0.40 |

### Calibration targets

`tables/c3_03_targets.csv`, gap of each stationary mean to the target:

| target | π_cold | gap, % (SD_π) | π_x0 gap, % (SD_π) |
|---|---|---|---|
| i.prev.dx.B | 0.3395 | +2.9 (+2.1) | −0.2 (−0.2) |
| i.prev.dx.H | 0.1337 | +5.3 (+1.2) | +0.1 (0.0) |
| i.prev.dx.W | 0.0895 | +6.5 (+2.4) | +0.3 (+0.1) |
| ir100.gono | 14.9 | +16.5 (+1.3) | −3.3 (−0.3) |
| ir100.chla | 17.2 | +18.0 (+2.2) | +4.1 (+0.5) |
| ir100.syph | 2.60 | +29.8 (+1.1) | +2.4 (+0.1) |
| cc.dx.B / H / W | | −0.1 / +0.9 / +0.4 | −0.2 / +0.8 / +0.3 |
| cc.vsupp.B / H / W | | 0.0 / −0.3 / −0.2 | +0.1 / −0.2 / −0.1 |
| cc.prep.B / H / W | | −1.1 / +3.7 / −0.6 | −0.8 / +3.9 / −0.6 |
| disease.mr100 | | −4.7 (−0.4) | −5.0 (−0.4) |
| ir100.hiv.dx.B / H / W (new) | 2.19 / 0.77 / 0.49 | −15.6 / −51.3 / +28.8 | not recorded |

`cc.prep` (total) is +30.9% in both experiments. This is the definition
mismatch noted in cycle 2.

## Interpretation

1. **The cold-start runs have a stationary law.** The only flags are one
   borderline signal in the Black population size (−0.08 SD per century at
   most, just above the 0.05 tolerance) and one variance flag. Neither is
   flagged over 150–600. As with cycle 1's `prev.W`, this is at the
   resolution of 256 chains and is not acted on. Over a 20-year run it is
   ≤ 0.02 SD.
2. **The two experiments do not simulate the same model.**
   - **Size of the difference.** HIV prevalence differs by 2.4 SD of its
     stationary spread (+3.6%). STI incidence is 13–26% higher in the cold
     start. The whole-state distance is 56 times the null 95% quantile.
   - **What is unchanged.** Cascade proportions, PrEP coverage and
     population size are essentially the same.
   - **Mechanism.** The pattern points at contact rates, not at care
     parameters. That is what c3_01 found: the x0 runs carry the network
     coefficients stored in `restart-hpc.rds`, and the cold-start runs load
     another network estimate on the HPC.
   - **What it is not.** It is not slow relaxation: over 600 years the two
     means stay apart (`figures/c3_03_means_both.png`).
3. **The calibrated parameters fit the x0 model, not the cold-start
   model.**
   - Under π_x0 every race-specific target is within ±1.23 SD_π, as cycle 2
     found.
   - Under π_cold, diagnosed prevalence is 3–7% above target, 1.2–2.4 SD_π of
     stochastic spread. STI incidence is 16–30% above.
   - The parameters were calibrated from runs restarted from
     `restart-hpc.rds`, i.e. with the x0 network. The parameter values date
     from commit `5eeff7c` (2026-09-09, "update calibrated values from
     single"). At that commit `path_to_restart` pointed to
     `restart-hpc.rds` (`R/netsim_settings.R`), and the restart
     calibration workflows (`R/C-calibration/workflow-restart_calib*.R`)
     restart from `path_to_restart`. Any run that
     starts from the HPC network, a cold start or a pool built from cold
     starts, simulates a model 1.2–2.4 SD off the prevalence targets.
4. **The new `ir100.hiv.dx` targets** are far from the model (−51% for
   Hispanic MSM). They were not part of the calibration.

## Decision / input for next steps

- **Each experiment is analysed against its own π.** c3_04 and c3_05
  measure the cold start against π_cold. The x0 values of cycles 1–2 remain
  valid for the x0 model.
- **Levels cannot be pooled across the two experiments.** Whether their
  *dynamics* agree is tested in c3_06.

## Caveats and deviations

- **The mechanism is inferred.** The network difference comes from the
  coefficients stored in the restart files (c3_01), not from the HPC netest
  itself. It explains the direction: more one-off partnerships, more
  transmission. The size of the effect of −8% casual / +11% one-off ties on
  prevalence is not tested here; that would need a simulation.
- **Tiny differences are significant.** With 256 chains × 301 years, even a
  −0.02% difference in PrEP coverage has p = 0.0015. The practical scale is
  the SD_π column, not the p-values.
