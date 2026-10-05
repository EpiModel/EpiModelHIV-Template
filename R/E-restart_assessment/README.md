# E. Restart assessment: from a restart point to full variance

This analyses the 256 × 600-year runs started from **one** restart state x0
(`data/run/variance/df__variance_long.rds`, produced by
`R/C-new_calibration/workflow-variance.R`). The questions:

1. How long after a restart point does the cross-run distribution reach full
   (stationary) variance?
2. Can a pool of restart points shorten that?
3. How many points does the pool need?
4. Should the points be selected beyond "all processes ongoing"?

**Answers:** [`results/SUMMARY.md`](results/SUMMARY.md).
**Notation and estimators:** [`METHODS.md`](METHODS.md).

## Logic chain

1. **`01` Prepare.** Converts the weekly data to annual values (flows summed,
   stocks averaged, ratios of annual aggregates). It checks that the first
   step is identical in all chains, confirming a single x0. It also finds
   syphilis extinctions, and those chains are dropped. Every later step reads
   only the annual file.
2. **`02` Validate.** Every estimator must recover known answers on
   synthetic series of the same shape before its output on real data is
   trusted. This is where the brief's detection rule for "time to
   stationarity" was found to fail and was replaced by tolerance on fitted
   relaxation curves.
3. **`03` Stationarity.** "Full variance" only has a meaning if a stationary
   law exists. This step checks that nothing drifts over years 150–600
   (population size, composition, prevalence…).
4. **`04` Relaxation from x0 (Q1).** Uses the 254 replicate futures of the
   single x0 to measure directly:
   - the share of the stationary variance present t years after restart;
   - the mean offset (how atypical x0 is);
   - the same for 20-year research windows after a post-restart burn-in B;
   - a multivariate view (energy distance, principal components).
5. **`05` Equilibrium structure.** Measures the memory at stationarity (ACF,
   τ_int) and how a 20-year run splits the stationary variance into
   variation over time and variation between runs. This tells which outputs
   depend most on the starting state.
6. **`06` Restart memory (Q2).** Lower bounds on ICC(h), the share of the
   variance fixed by the restart state, averaged over states from π. They
   come from pseudo-restarts inside the stationary chains (ridge regression,
   chain-blocked CV). They are compared with the direct single-x0 values
   from `04`.
7. **`07` Pool design (Q2–Q4).** Turns the ICCs into:
   - the burn-in needed as a function of pool size;
   - the MCSE inflation and points needed for planned run counts;
   - the cost of drawing points from one chain vs independent chains.

   It then runs a selection experiment on real stationary states (random vs
   "ongoing" vs "typical" vs target-like vs stratified pools).

## How to run

From the project root, in a fresh session:

```bash
Rscript R/E-restart_assessment/run_all.R   # ~45 min on 12 cores, < 6 GB RAM
```

Or run each numbered script on its own, in order (Ctrl+Shift+F10). Every
script reads only `00_config.R` and the outputs of earlier steps.

## File index

| File | Role |
|---|---|
| `00_config.R` | every path and tunable, seed, parallel RNG |
| `utils.R` | shared estimators (documented, with METHODS.md sections) |
| `01_prepare_annual.R` … `07_pool_design.R` | steps |
| `run_all.R` | runs the steps in order, stops on the first error |
| `METHODS.md` | concepts, formulas, notation |
| `results/NN_*.md` | one report per step |
| `results/SUMMARY.md` | answers to the questions |
| `results/tables/NN_*.csv` | every number quoted in the md files |
| `results/figures/NN_*.png` | figures |
| `results/logs/` | `NN.log`, `NN_sessionInfo.txt` |
| `data/run/restart_assessment/` | large intermediates (git-ignored via `data/run`) |

## Project conventions observed

- **Script style.** Top-level numbered scripts meant for a fresh session.
  They start from `R/shared_variables.R` (through `00_config.R`) and use
  relative paths from the project root.
- **Code style.** `library()` + `dplyr` + `ggplot2` (`theme_light`). Section
  headers are `# Title ----`. Lines are ≤ 80 columns and indentation is
  2 spaces (`air.toml`).
- **Data locations.** Intermediate data goes under `data/run/` (already
  git-ignored). Nothing under `data/input/` or existing scripts was touched.
- **Packages.** `data.table`, `posterior`, `glmnet`, `ranger` and `energy`
  are not installed, so everything is base R + `dplyr`/`tidyr`/`ggplot2` +
  `minpack.lm`. Nothing was installed. As a result:
  - ridge regression is hand-written (SVD path);
  - ESS from `posterior` is replaced by Geyer's τ_int;
  - there is no random forest.

## Decision log

| Date | Decision | Reason | Confirmed by user |
|---|---|---|---|
| 2026-09-25 | Scope: from a restart point to full variance; the cold-start → equilibrium questions of the brief are dropped | user instruction | yes |
| 2026-09-25 | Analysis in `R/E-restart_assessment/`, intermediates in `data/run/restart_assessment/` | user asked for a subfolder of `R/`; `data/run` is git-ignored | yes (folder) |
| 2026-09-25 | Chains 75 and 88 dropped (syphilis extinct, absorbing) | the stationary law is conditional on persistence; same chains for all variables | no |
| 2026-09-25 | All variables on the raw scale | no proportion near 0/1 after dropping the extinct chains | no |
| 2026-09-25 | Brief's T_cold rule replaced by tolerance on fitted relaxation curves | the rule fails validation (autocorrelated statistic), see `02` | no |
| 2026-09-25 | Validation criterion \|z\| < 3 instead of "truth in 95% CI", plus a coverage study | ~30 checks on one realisation | no |
| 2026-09-25 | `EQ_START` = 150 | variance and mean within tolerance by ~100 years for every variable (`04`), +50-year margin | no |
| 2026-09-25 | No reversibility (cross-correlation) check; no random forest | not needed for the user's questions; `ranger` not installed | no |
