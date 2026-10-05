# C3-01. The cold-start runs: provenance, initial state, annual data

## Question

What is in `df__variance_long_x0.rds`? Were these runs made with the same
parameters and model code as the x0 runs of cycles 1–2? What does the
cold-start state look like? Which annual dataset do the later steps use?

## Method

[c3_METHODS.md](c3_METHODS.md) C3-M0, C3-M1. Script: `c3_01_prepare.R`.

## Results

### How the runs were made

These are the `netsim` inputs that slurmworkflow shipped to the HPC
(`tables/c3_01_run_setup.csv`):

- a cold start from `data/run/estimates/netest-hpc.rds`, with
  `initialize_msm()` and `start` = 1;
- 31,200 steps (600 years);
- 256 runs in 32 batches of 8;
- `init`: every STI site at 10% prevalence.

**Parameters.** All **82 of 82** `param` elements are identical to the list
rebuilt from the current `model_parameters.csv`
(`tables/c3_01_param_compare.csv`). That csv was last modified on
2026-09-15, before both experiments (`tables/c3_01_files.csv`).

**Model code** (`tables/c3_01_code_versions.csv`):

- The x0 runs used EpiModelHIV-p `4ab6641f`, the cold-start runs `6e6bff15`.
- The two differ in `R/mod.prevalence.R` (+2/−1 lines) and
  `R/utils-calibration.R` (+14 lines).
- That is a new output (`hiv.dx.incid.*`) and new targets
  (`ir100.hiv.dx.*`); the dynamics are unchanged.

**Network coefficients** (`tables/c3_01_network_coefs.csv`). The offset
of the edges coefficient against the local `netest-hpc.rds`, and the implied
ratio of tie propensity (C3-M0):

| restart file | main | casual | one-off | same in all networks? |
|---|---|---|---|---|
| `restart-hpc.rds`, x0 of cycles 1–2 (2026-05-20) | −0.0111 (0.989) | −0.0111 (0.989) | −0.0111 (0.989) | yes |
| `restart_pool.rds`, 62 points from HPC cold starts (2026-09-21) | −0.0147 (0.985) | −0.0870 (0.917) | +0.1004 (1.106) | no |

The pool offsets are identical across its 62 points.

### The data

**Shape** (`logs/c3_01.log`):

- 7,987,200 rows × 65 columns, 2 GB;
- 256 runs × 31,200 steps;
- the 61 variables of the x0 file plus `hiv.dx.incid` (total and B/H/W).

**Missing values and identities** (`tables/c3_01_first_steps.csv`,
`tables/c3_01_identities.csv`):

- Step 1 records only `num`, which is 100,000 in every run.
- No other value is missing.
- `nNew` = `arrivals`, and totals are exact sums of B/H/W.
- All 256 trajectories are distinct.

**No extinction.** No infection reaches 0 in any run
(`tables/c3_01_extinctions_year.csv` is empty), so all **256 runs** are
kept. Cycle 1 had dropped 2 of 256 runs for syphilis extinction.

**Annual dataset** (`data/run/restart_assessment/cycle3/c3_01_annual_cold.rds`,
122 MB):

- 27 key, 26 state, 17 project and 34 other variables
  (`tables/c3_01_variable_dictionary.csv`);
- the derived variables reproduce the cycle 1 values exactly from their raw
  variables (maximum difference 0, `logs/c3_01.log`).

### The cold-start state

First simulated week (`tables/c3_01_first_steps.csv`), cross-chain means:

- 21,475 infected, of whom 21,304 are diagnosed;
- 6,580 on ART and 171 suppressed;
- 168 on PrEP;
- 171 new HIV infections in the week;
- 20,377 gonorrhoea, 19,862 chlamydia and 9,995 syphilis infections.

HIV prevalence by race in week 1 is 0.333 (B), 0.138 (H) and 0.084 (W)
(`tables/c3_01_initial_state.csv`). These are the diagnosed-prevalence
targets used as `init.hiv.prev` in `R/A-networks/initialize.R`.

Year 1 against the stationary law of the same runs
(`tables/c3_01_initial_state.csv`), in SD_π units:

| variable | year 1 | π (years ≥ 300) | offset (SD_π) |
|---|---|---|---|
| prev | 0.224 | 0.255 | −8.6 |
| dx_frac | 0.948 | 0.849 | +38 |
| supp_frac | 0.720 | 0.529 | +61 |
| prep_cov | 0.113 | 0.266 | −87 |
| incid_rate | 2.29 | 1.41 | +15 |
| gono_prev | 0.0995 | 0.0245 | +29 |
| chla_prev | 0.132 | 0.048 | +27 |
| syph_prev | 0.139 | 0.0225 | +27 |
| num | 99,880 | 100,050 | −0.5 |

The cross-chain SD in year 1 is 0.10–0.18 of SD_π for prevalence and
population size (`sd_ratio_year1`).

Figures:

- `figures/c3_01_key_600y.png` and `figures/c3_01_key_first150y.png`: 10
  runs, the mean and the 5–95% band, with the x0 runs' stationary mean as a
  dashed line;
- `figures/c3_01_first2y_weekly.png`: the first two years, weekly.

## Interpretation

1. **The cold start is far from equilibrium in every direction.**
   `initialize_msm()` takes HIV status from the network's diagnosed
   attribute (`EpiModelHIV-p/R/mod.initialize.R`), so at t = 1:
   - every infected person is diagnosed, untreated and at set-point viral
     load;
   - nobody is on PrEP;
   - each STI site is at 10%.

   In week 1, HIV incidence is 8.5 times its stationary weekly level
   (`tables/c3_01_week1_vs_pi.csv`), and ART uptake then overshoots
   (`figures/c3_01_first2y_weekly.png`). The result is an HIV epidemic
   overshoot: prevalence peaks around year 25, +15 SD_π above π
   (`tables/c3_04_block10.csv`, `figures/c3_01_key_first150y.png`). The
   population dips during years 5–45 and jumps back when the initial cohort
   has aged out, around year 50.
2. **The runs start almost identical at the population level.** The random
   initialisation leaves cross-chain SDs of 10–18% of the stationary SD for
   prevalence and population size. Independent cold starts therefore behave
   like runs from one common state for the slow variables (c3_04).
3. **Same parameters and same dynamics code, but not the same network
   model.** The x0 runs did not load `netest`:
   - they took their edges coefficients from `restart-hpc.rds`, which carries
     the local (May) estimate shifted by −0.011 in all three networks, a
     population-count offset from its own history;
   - the cold-start runs loaded the HPC copy of `netest-hpc.rds`;
   - the September pool was built on the HPC from cold starts with the same
     code, and its offsets differ **by network** (−0.015, −0.087, +0.100).
     `edges_correct()` shifts all networks by the same amount, so a
     network-specific offset can only come from different starting
     coefficients.

   The HPC's network estimate therefore differs from the local copy. The
   September cold starts have about 8% fewer casual and 11% more one-off
   partnerships than the local estimate implies (tie propensity
   0.917 / 1.106), against 1% fewer in every network for the x0 runs.

## Decision / input for next steps

- Use `c3_01_annual_cold.rds`: 256 chains, raw scale, cycle 1 blocks.
- The x0 runs of cycles 1–2 and the cold-start runs are **not expected to
  share a stationary law**. c3_03 tests this.

## Caveats and deviations

- **The HPC `netest-hpc.rds` is not available locally.** Its coefficients
  are inferred from the pool, assuming the pool's runs started from 100,000
  nodes, as every cold start does. Recommended check, on the HPC:
  `sapply(readRDS("data/run/estimates/netest-hpc.rds"), function(x) x$coef.form[1])`,
  to be compared with −19.1725 (main), −18.5614 (casual) and −14.1951
  (one-off) locally.
- **`restart-hpc.rds` has 8 coefficient sets but 1 run.** EpiModel uses the
  first set, and that is the one reported.
- **`hiv.supp` counts new infections.** In week 1 it equals HIV incidence
  (`tables/c3_01_first_steps.csv`), because new infections start at viral
  load 0, below the suppression threshold. This slightly inflates
  `supp_frac`; weekly infections are a small fraction of the suppressed
  count. It is left as is, as in cycles 1–2.
