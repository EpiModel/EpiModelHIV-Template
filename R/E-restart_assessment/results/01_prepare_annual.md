# 01. Data and annual dataset

## Question

What is in the dataset, does it really start from one restart state, and what
annual dataset do the later steps use?

## Method

See [METHODS.md](../METHODS.md) M1. Script: `01_prepare_annual.R`.

## Results

**Shape.** The weekly data is a tibble of 7,987,200 rows × 61 columns:

- 256 sims × 31,200 steps (600 years × 52 weeks);
- 1.8 GB in memory, 4.5 GB peak RSS while loading;
- no NA values.

Source: `logs/01.log`, `tables/01_raw_inventory.csv`.

**Single restart state.** The first recorded step (`time == 2`) is identical
in all 256 chains (`logs/01.log`: "First step identical across chains:
TRUE"). Its values are the `x0` column of `tables/01_raw_inventory.csv`.

**Redundancies** (`tables/01_raw_inventory.csv`):

- `nNew` is identical to `arrivals`;
- `num`, `hiv.inf`, `hiv.incid`, `arrivals`, … are exact sums of their
  B/H/W parts.

**Absorbing event.** Syphilis goes extinct in 2 chains: sim 88 at year 88.9
and sim 75 at year 374.4 (`tables/01_extinctions_year.csv`). No other
infection ever reaches 0. These two chains are dropped everywhere, leaving
254 chains.

**Annual dataset.** It has 27 `key`, 26 `state` and 30 `other` variables
(`tables/01_variable_dictionary.csv`, which also lists the aggregation rule
of every variable). It takes 96.6 MB in memory (`logs/01.log`), about 20
times smaller than the weekly data.

**Sanity figures.**

- `figures/01_key_600y.png`: 10 chains, cross-chain mean and 5–95% band of
  every key variable over 600 years.
- `figures/01_key_first100y.png`: the same over the first 100 years.

## Interpretation

The data matches a single-restart design. The first 100 years show two
different things:

- **Fast outputs** (PrEP coverage, suppression, HIV incidence) spread within
  a few years.
- **HIV prevalence and population size** spread slowly. Their 5–95% band is
  still widening after 50 years.
- **x0 is visibly atypical.** Its chlamydia prevalence (0.026) is far below
  the stationary level (~0.043). Gonorrhoea overshoots to ~0.03 before
  settling at ~0.020. HIV prevalence first rises for ~15 years, then
  declines for ~100 years.

## Decision / input for next steps

- Work on the annual dataset `data/run/restart_assessment/01_annual.rds`.
- Use 254 chains.
- Use the raw scale for all variables.

## Caveats and deviations

- **Syphilis extinction.** The user had checked that processes stay active,
  but syphilis extinctions occur late in two chains. Over 600 × 256
  chain-years this is ~1.3 × 10⁻⁵ per chain-year, negligible for 20-year
  research runs. Formally, π is therefore the quasi-stationary law
  conditional on syphilis persistence.
- **Weekly `x0` values.** They are single-week snapshots. Annual means of
  year 1 already differ from them (e.g. chlamydia), so the offsets reported
  in step 04 use the annual values.
