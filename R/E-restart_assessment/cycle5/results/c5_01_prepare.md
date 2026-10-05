# C5-01. The scenario runs: design and checks

## Question

- Do the scenario runs have the intended design, with 32 pool points × 4
  runs per scenario and each run's point known?
- Did each scenario's parameter change take effect, at the intended time?

## Method

[c5_METHODS.md](c5_METHODS.md) C5-M1. Script: `c5_01_prepare.R`.

## Results

### Design

Source: `tables/c5_01_design.csv`.

| set | scenario | runs | points | runs per point | years |
|---|---|---|---|---|---|
| short | baseline, S1, S2, S3 | 128 each | 32 | 4 | 15 |
| long | S4 | 128 | 32 | 4 | 150 |
| long | baseline = cycle 4 pool runs | 256 | 32 | 1–15 | 150 (of 600) |

- **Points.** The copied state (step 2) of every run equals exactly the pool
  point given by its `sim_number`, in all 61 recorded variables (128/128 in
  each set).
  - So recycling with batches of 32 used each point once per batch, as
    planned.
  - This also confirms that a merged tibble keeps the copied state as its
    first row (step 2) when `steps_to_keep = Inf`.
- **The S4 baseline is legitimate.** The cycle 4 runs started from the
  same `restart_pool.rds` (same file, same point order) with the same
  parameters.

### Did the changes take effect?

Source: `tables/c5_01_mechanism_check.csv`. The mean of the variable each
scenario acts on, as a change against the baseline over years 6–15. z
compares years 1–5, i.e. before the change, with the baseline.

| scenario | variable acted on | before (z) | after (change) |
|---|---|---|---|
| S1, testing × 2 | new diagnoses per year | 0.6 | **+5.0%** |
| | undiagnosed infections | 0.9 | **−8.7%** |
| S2, PrEP × 2 | PrEP coverage | −0.1 | **+57.6%** |
| | undiagnosed infections | 0.4 | −39.1% |
| | gonorrhoea, chlamydia incidence | −0.3, −0.7 | −20.4%, −20.3% |
| S3, STI screening × 3 | gonorrhoea, chlamydia incidence | 0.5, 0.1 | **−57.7%, −58.1%** |
| | syphilis incidence | 0.3 | +0.4% |

- **Before the change,** every arm agrees with the baseline (|z| ≤ 1.3).
- **After it,** each scenario moves its target.
- **S2 does more than add PrEP.** PrEP users are tested for HIV and STIs
  every 3 months, so S2 also finds undiagnosed HIV (−39%) and treats STIs
  (−20%).
- **S3 does not touch syphilis.** In this model version, syphilis screening
  has its own parameters, `syph.screen.hivneg.rate` and
  `syph.screen.hivpos.rate` (`EpiModelHIV-p/R/syphilis.R`). They are not in
  `model_parameters.csv`, so they stay at their package defaults. S3 is a
  gonorrhoea and chlamydia scenario.

### S4 at a glance

Figure: `figures/c5_01_long_prevalence.png`. Mean HIV prevalence falls from
0.254 at the restart to 0.245 at 10 years, 0.218 at 50 and 0.212 at 150
years.

## Interpretation

1. **The design is exactly the planned one:** paired and balanced over the
   whole pool, 4 runs per point and scenario.
2. **All four changes act as intended,** with one qualification: S3 covers
   gonorrhoea and chlamydia only.
3. **Effects spread through the model.** The S2 PrEP scenario is also a
   testing and STI-treatment scenario, because of the PrEP visits.

## Decision / input for next steps

- c5_03 and c5_04 use the short set, and c5_05 uses S4 with the cycle 4
  runs as its baseline.
- The STI conclusions of c5_04 are about gonorrhoea and chlamydia. A
  syphilis scenario would need `syph.screen.*`.

## Caveats and deviations

- **The syphilis gap was not planned.** It was found here, from the data,
  then confirmed in the code.
- **Scenario definitions** are in `tables/c5_01_scenario_definitions.csv`,
  copied from the workflow script.
