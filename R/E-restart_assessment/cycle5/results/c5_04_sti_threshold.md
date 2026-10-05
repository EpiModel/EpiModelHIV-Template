# C5-04. STI scenarios near the extinction threshold

## Question

[SCENARIOS.md](../../SCENARIOS.md) §7 predicted that scenarios lowering STI
transmission would be the most state-dependent:

- an extinct STI never returns;
- states with little STI would go extinct first;
- the "processes ongoing" filter removes exactly those states.

With S3 (STI screening × 3) and S2 (whose PrEP visits also screen for
STIs):

- do runs go extinct, or come close?
- does the relative effect depend on how much STI a restart state carries?
- does the filter matter?

## Method

[c5_METHODS.md](c5_METHODS.md) C5-M4. Script: `c5_04_sti_threshold.R`.

## Results

### How close runs come to extinction

Source: `tables/c5_04_extinction.csv`, `figures/c5_04_sti_runs.png`. STI
prevalence in year 15, 128 runs per arm:

| arm | gonorrhoea: median (lowest run) | chlamydia | syphilis | extinctions |
|---|---|---|---|---|
| baseline | 2.5% (1.9%) | 4.8% (4.2%) | 2.2% (1.3%) | 0 |
| S2, PrEP × 2 | 1.6% (0.8%) | 3.0% (2.2%) | 1.6% (0.7%) | 0 |
| S3, STI screening × 3 | **0.39% (0.17%)** | **0.74% (0.35%)** | 2.2% (1.2%) | 0 |

- **S3 pushes gonorrhoea and chlamydia far below the equilibrium range.**
  Every S3 run ends below the 1% quantile of the baseline equilibrium (1.8%
  for gonorrhoea, 4.1% for chlamydia).
- **None goes extinct within 10 years.** At 0.2–0.4% prevalence, a
  population of 100,000 still has many infected men: at least 166 with
  gonorrhoea (median 396) and at least 346 with chlamydia in year 15.

### Does the relative effect depend on the starting state?

Source: `tables/c5_04_state_dependence.csv`,
`figures/c5_04_state_dependence.png`. The share of STI infections averted at
each point, against the point's saved prevalence of the same STI:

| scenario, STI | slope (pp of PIA per SD of initial prevalence) | p | R² |
|---|---|---|---|
| S3, gonorrhoea | 0.02 (SE 0.47) | 0.96 | 0.00 |
| S3, chlamydia | −0.50 (0.27) | 0.07 | 0.11 |
| S2, gonorrhoea | −1.2 (0.8) | 0.16 | 0.07 |
| S2, chlamydia | −0.09 (0.59) | 0.88 | 0.00 |
| S2, syphilis | −1.9 (1.7) | 0.28 | 0.04 |

- **No clear dependence.** S3 averts about 58% of gonorrhoea infections
  whether the state starts with more or with less gonorrhoea.
- **This settles c5_03's S3 gonorrhoea result.** The *absolute* number
  averted grows with the initial level, which is proportionality. The
  *share* averted does not.

### Does the filter matter?

Source: `tables/c5_04_filter_points.csv`.

- **Points below the filter threshold** (the 1% quantile of the equilibrium
  STI prevalence): 1 of 32 for gonorrhoea (1.72% against 1.84%), none for
  chlamydia or syphilis.
- **A stricter filter changes nothing.** Leaving out the lowest 10% of
  points for each STI changes the shares averted by −0.6 to +1.6 pp. That
  is less than one SE in every case (0.5–2.1 pp).

## Interpretation

1. **The predicted threshold effects did not appear within 10 years.**
   - Screening × 3 cuts gonorrhoea and chlamydia by nearly 60%, far below
     anything the baseline equilibrium visits.
   - But at this population size the STIs stay well above extinction, and
     the relative effect is the same from every restart state.
2. **The filter is harmless for STI scenarios too,** at least at this
   strength and horizon. It removes 1 point in 32, and a stricter version
   changes no effect beyond chance.
3. **Where the risk remains:**
   - stronger or longer interventions, or smaller populations, where runs
     do reach extinction;
   - syphilis, which S3 did not act on (c5_01), and which is the STI
     closest to its threshold at baseline (lowest run at 1.3%).

## Decision / input for next steps

- **No special pool is needed** for STI scenarios of this size over 10
  years. The general rules of c5_03 apply.
- **A syphilis scenario would need `syph.screen.*`.** The extinction
  question stays open for syphilis and for long horizons.

## Caveats and deviations

- **Extinction is judged on annual means.** A count of 0 for a whole year
  is required. Brief weekly zeros would not count, but extinction is
  absorbing, so a real one would show.
- **The HPC population is about 100,000.** Local 10,000-node runs are 10
  times closer to extinction.
