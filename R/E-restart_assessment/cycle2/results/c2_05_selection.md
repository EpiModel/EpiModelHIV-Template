# C2-05. Selecting restart points, revisited

## Question

Cycle 1 compared extreme selections (the 32 closest of 254) using the π
means as "targets". Here the selection uses:

- the **project's own rule** (every STI ir100 ≥ 50% of its target,
  `3-choose_restart.R`);
- the **actual calibration targets**, at several **selection intensities**;
- **proper conditioning** on the targets as noisy data.

In each case: what happens to the variance and the level of the project
outcomes, and do selected states stay close to the targets?

## Method

[c2_METHODS.md](c2_METHODS.md) C2-M7. Script: `c2_05_selection.R`.
2000 replicates, 32 points per pool.

## Results

**Project filter** (`tables/c2_05_project_filter.csv`). 96.8% of the
109,474 stationary states pass. Rejected states have low syphilis (ir100
down to 0.02 of the target). As a pool rule, it changes the variance of the
outcomes by ≤ 2% and their level by ≤ 0.02 SD.

**Selection intensity and conditioning**
(`tables/c2_05_selection_summary.csv`, `figures/c2_05_selection.png`).
Var(futures)/stationary value:

| strategy | cml incidence, years 6–15 | i.prev.dx.B, year 15 | prevalence, year 15 | effective sample size of the weights |
|---|---|---|---|---|
| random (q = 1) | 0.995 | 0.996 | 0.997 | |
| keep the closest 75% | 0.987 | 0.855 | 0.837 | |
| keep 50% | 0.971 | 0.775 | 0.757 | |
| keep 25% | 0.949 | 0.706 | 0.679 | |
| keep 12.5% | 0.943 | 0.674 | 0.649 | |
| weights, data SD = 0.5 SD_π | 0.403 | 0.248 | 0.245 | 2.2 |
| weights, data SD = 1 SD_π | 0.885 | 0.610 | 0.591 | 19.5 |
| weights, data SD = 2 SD_π | 0.967 | 0.801 | 0.786 | 158 |
| weights, data SD = 5 SD_π | 0.979 | 0.942 | 0.938 | 249 |
| weights, data SD = 10 SD_π | 0.996 | 0.982 | 0.979 | 254 |
| STI filter | 0.984 | 0.981 | 0.979 | |

- **Level bias** stays ≤ 0.05 SD for all "keep" rules. The π means are
  already close to the targets ([c2_01](c2_01_provenance.md)).

**How precisely the model pins down the targets.** The model's own
stochastic spread (SD_π) as a share of the target value
(`tables/c2_01_targets_vs_pi.csv`):

| target | SD_π / target |
|---|---|
| cc.dx.B | 0.3% |
| i.prev.dx.B | 1.4% |
| i.prev.dx.W | 2.8% |
| ir100.chla | 8% |
| ir100.gono | 13% |
| ir100.syph | 28% |

**Regression to the mean** (`tables/c2_05_regression_to_mean.csv`,
`figures/c2_05_regression_to_mean.png`). States selected as the closest
12.5% start at a distance of 3.09 from the targets, against 4.38 for random
states. Their distance then grows:

| years after selection | distance to the targets |
|---|---|
| 1 | 3.57 |
| 5 | 4.08 |
| 10 | 4.20 |
| 20 | 4.29 |

The SD of their i.prev.dx.B grows from 0.66 to 0.83 at 20 years and 0.98 at
40 years (random states: 1.0).

## Interpretation

1. **Selection hurts slow outputs, not fast ones.** Selecting close to the
   targets barely affects the 10-year cumulative incidence (≥ 0.94 of the
   variance even at 12.5%), because incidence forgets the state within a
   few years. Prevalence-type outputs lose 15–35% of their variance.
2. **"Selecting the best" is conditioning with exact targets.** Proper
   conditioning weights states by how well they explain the targets given
   the targets' uncertainty. It only shrinks the distribution noticeably
   when the data error is ≲ 2 SD_π, i.e. when the targets are known almost
   as precisely as the model's own stochastic spread.
   - For the HIV targets that spread is 0.3–3% of the target value. Real
     surveillance estimates are much less certain, so correct conditioning
     is ≈ no selection. **Selecting on the HIV targets removes genuine
     model variability rather than adding information.**
   - For STI incidence the model's own spread is 8–28% of the target.
     Conditioning on reliable STI data could legitimately narrow the pool
     a little, but that requires an explicit data-error model, not a
     closest-k rule.
3. **Selected states do not stay selected.** Within 10–20 years they are as
   far from the targets as random states. Their narrowed distribution
   widens back over 40 years, so selection distorts the first decades of
   the research runs and then fades. This is the same slow relaxation as
   in [c2_02](c2_02_project_outcomes.md).
4. **Your current filter ("STIs ongoing") is harmless** and justified,
   since extinctions are absorbing.

## Decision / input for next steps

- **Keep the STI-ongoing filter.** Do not select on closeness to the HIV
  targets.
- **If STI targets are to condition the pool,** use likelihood weights
  with the data uncertainty of those targets.
- **Stratified random sampling** on the slow state mode remains the only
  selection that reduces pool error without distorting the variance
  (cycle 1, `07`).

## Caveats and deviations

- The data-error model is independent Gaussian errors on 16 targets, all
  with the same multiple f of SD_π. Real target uncertainties differ by
  target and are not in the project files.
- Futures are single realisations per state (one run per point).
