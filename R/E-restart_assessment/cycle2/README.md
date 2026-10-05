# Cycle 2: review of assumptions and conceptual soundness

Cycle 2 re-checks cycle 1 (`../`). Cycle 1 files are left untouched so the
two can be compared. Cycle 2 reads the cycle 1 annual dataset and tables
**read-only**, and writes only here and to `data/run/restart_assessment/cycle2/`.

**Start with:**

1. [`REVIEW.md`](REVIEW.md): assumption audit (yours, the brief's, mine),
   conceptual points, and cycle 1 errata;
2. [`results/SUMMARY_cycle2.md`](results/SUMMARY_cycle2.md): the four
   questions answered side by side with cycle 1.

## Steps

| Script | Question | Report |
|---|---|---|
| `c2_01_provenance.R` | Where x0 comes from; parameter differences; continuity at the restart; π vs calibration targets | [c2_01](results/c2_01_provenance.md) |
| `c2_02_project_outcomes.R` | Calibration targets (year 70) and intervention outcomes (years 6–15, year 15), measured directly on the x0 runs, plus same-parameter lower bounds to 80 years | [c2_02](results/c2_02_project_outcomes.md) |
| `c2_03_robustness.R` | Alternative estimators, π period, nonlinear bounds, long memory, replication study, cycle 1 claims | [c2_03](results/c2_03_robustness.md) |
| `c2_04_design.R` | Current designs: single point, recycled pool, randomised pool; levels vs effects; calibration run length | [c2_04](results/c2_04_design.md) |
| `c2_05_selection.R` | The project's filter, selection intensity on the real targets, likelihood conditioning, regression to the mean | [c2_05](results/c2_05_selection.md) |

**Supporting files:**

- `c2_config.R`: cycle 2 settings, including the project design constants
  read from the code;
- `c2_utils.R`: new functions;
- [`results/c2_METHODS.md`](results/c2_METHODS.md): definitions C2-M0 to
  C2-M7.

## How to run

From the project root, after cycle 1 (it needs `01_annual.rds` and the
cycle 1 tables):

```bash
Rscript R/E-restart_assessment/cycle2/run_all_c2.R   # ~15 min on 12 cores
```

`c2_01` also reads the weekly variance data (1.8 GB in memory) and the
restart files in `data/run/estimates/`.

## Code sources read for the review

These are read only, not modified:

- `R/netsim_settings.R` (current and at git `76ff0aa`);
- `R/C-new_calibration/3-choose_restart.R`, `swfcalib_model.R`,
  `swfcalib_config_pool2.R`;
- `R/D-interventions/workflow-intervention.R`, `outcomes.R`;
- `../EpiModel/R/net.mod.init.R`, `netsim.R`: restart source assignment;
- `../EpiModelHPC/R/netsim_scenarios.R`: batches;
- `../EpiModelHIV-p/R/`: time-dependent parameters and calibration target
  definitions.
