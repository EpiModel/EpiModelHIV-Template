# Cycle 5: scenarios run from the restart pool

This cycle tests the predictions of [`SCENARIOS.md`](../SCENARIOS.md) with
four scenarios, all restarted from the 32-point pool
(`restart_pool.rds`), with 4 runs per point and scenario, run on the HPC on
2026-09-28:

| set | scenarios |
|---|---|
| short, 15 years | baseline; S1 HIV testing odds × 2; S2 PrEP initiation odds × 2; S3 STI screening odds × 3 (changes from year 6) |
| long, 150 years | S4: 10% fewer sexual acts from the restart, against the cycle 4 pool runs |

**Workflow:** `R/C-new_calibration/workflow-variance_scenarios.R`, which
runs batches of 32, so that each pool point is used once per batch in every
scenario.

**Data:** `data/run/variance_scenarios/{short,long}/merged_tibbles/`.

Cycles 1–4 are read-only. Cycle 5 writes only here and to
`data/run/restart_assessment/cycle5/`.

**Start with:** [`results/SUMMARY_cycle5.md`](results/SUMMARY_cycle5.md).

## Questions

1. Did each scenario change what it should, at the right time, from the
   intended points?
2. Do the paired estimators work with these designs?
3. How large are the effects, how much do they vary between restart points,
   and which design follows?
4. Do STI scenarios behave differently near the extinction threshold, and
   does the filter matter?
5. How long does a sustained change take to show, and does effect
   heterogeneity fade with the horizon?

## Steps

| Script | Question | Report |
|---|---|---|
| `c5_01_prepare.R` | Design, point identification, did the changes take effect; annual data | [c5_01](results/c5_01_prepare.md) |
| `c5_02_validate.R` | Paired effect and heterogeneity estimators on synthetic data with the two designs | [c5_02](results/c5_02_validate.md) |
| `c5_03_effects.R` | Effects, heterogeneity, proportionality, design consequences (S1–S3) | [c5_03](results/c5_03_effects.md) |
| `c5_04_sti_threshold.R` | Extinction, state dependence of STI effects, the filter | [c5_04](results/c5_04_sti_threshold.md) |
| `c5_05_relaxation.R` | S4: relaxation times, share of the long-run effect, heterogeneity by horizon | [c5_05](results/c5_05_relaxation.md) |

**Supporting files:**

- `c5_config.R`: sources the cycle 1–4 configurations;
- `c5_utils.R`: annual data of scenario runs, the paired effect and
  heterogeneity, design errors, point bootstrap;
- [`results/c5_METHODS.md`](results/c5_METHODS.md): definitions C5-M1 to
  C5-M5.

## How to run

From the project root, after cycle 4, whose annual data it reads:

```bash
Rscript R/E-restart_assessment/cycle5/run_all_c5.R   # ~35 min on 12 cores, most of it c5_05's bootstrap
```

## Project conventions observed

The same as cycles 1–4. No package was installed.

## Decision log

| Date | Decision | Reason | Confirmed by user |
|---|---|---|---|
| 2026-09-28 | Four scenarios: testing, PrEP, STI screening (forward), acts × 0.9 (from the restart) | each tests one prediction of SCENARIOS.md | yes (design proposed, "32 cores, run all scenarios at once, hpc directly") |
| 2026-09-28 | Batches of 32 cores, recycling, 4 runs per point and scenario | paired and balanced over the whole pool | yes |
| 2026-09-28 | S4 baseline = cycle 4 pool runs, first 150 years | same points, same parameters; saves 19,200 run-years | yes (in the proposal) |
| 2026-09-28 | Heterogeneity CI by inverting the F ratio, point bootstrap as check | validated in c5_02 (the bootstrap is not) | no |
| 2026-09-28 | Level ICC of the baseline arm not used for decisions; cycle 4's value kept | one 128-run arm estimates it poorly (c5_03) | no |
