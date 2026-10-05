# C2-01. Where x0 comes from, and what the variance runs really measure

## Question

Where does the restart state x0 come from? Was it produced with the same
model and parameters as the variance runs? Does the restart create a
discontinuity? How does the stationary law π of the variance runs compare
with the calibration targets?

## Method

[c2_METHODS.md](c2_METHODS.md) C2-M0, C2-M1. Script: `c2_01_provenance.R`.

## Results

**Source.** x0 matches `data/run/estimates/restart-hpc.rds` exactly, on all
13 stocks (`tables/c2_01_x0_source.csv`). That file was last modified on
**2026-05-20**. The variance runs are from 2026-09-18.

- `netsim_settings.R` at the time of the run pointed to
  `restart-<context>.rds` (git `76ff0aa`).
- The later pool `restart_pool.rds` (2026-09-21, 62 states) does not
  contain x0. Its STI stocks are very different: chlamydia infections
  ≈ 10,400 vs 2,585 in x0 and 4,270 at π.

**Parameters.** **20 of 122** model parameters differ between x0 and the
variance runs (`tables/c2_01_param_diff.csv`):

| group | change (x0 → variance runs) |
|---|---|
| HIV testing | `hiv.test.rate` −14% (B), +13% (H), +26% (W) |
| HIV transmission | `hiv.trans.scale` +23% (H), +2% (W) |
| ART / PrEP | `tx.halt.rate` ±1–3%, `prep.start.rate` +1% (B), +6% (H) |
| Chlamydia | `chla.uret.prob` −30%, `chla.uret.sympt.prob` 0.95 → 0.50 |
| Syphilis | `syph.prob` +19%, `syph.sympt.tx.prob` 0.017 → 0.215 (×12.6), `syph.prog.int_5` 780 → 520, `syph.tert.min.dwell` new |
| STI screening | `sti.screen.hivneg.rate`, `sti.screen.hivpos.rate`: absent in x0's parameters |

The attribute set of x0 is compatible with the installed EpiModelHIV 3.3.2:
no attribute is missing (`logs/c2_01.log`).

**First week after the restart** (`tables/c2_01_restart_continuity.csv`,
`figures/c2_01_first_year_weekly.png`). Jumps out of line with the
following weeks:

| variable | first week | weeks 2–26 | z |
|---|---|---|---|
| gono.uret.inf (increment) | +41 | +3.9 / week | 23.5 |
| chla.inf (increment) | −40 | +17.9 / week | −15.0 |
| gono.inf (increment) | +44 | +10.0 / week | 13.5 |
| chla.uret.incid | 158 | 121 | 12.2 |
| hiv.supp (increment) | +15 | +0.6 / week | 8.2 |
| hiv.incid.B | 18.4 | 16.0 | 7.1 |
| hiv.incid | 23.7 | 21.0 | 6.3 |

Most HIV, PrEP and demographic stocks are continuous (|z| < 4).

**π vs calibration targets** (`tables/c2_01_targets_vs_pi.csv`).

- All race-specific targets lie within **±1.23 SD_π** of the stationary mean.
- In relative terms, all but five are within ±1%. The exceptions are the
  STI incidences (−3.3% gono, +4.1% chla, +2.4% syph), cc.prep.H (+3.9%)
  and disease.mr100 (−5.0%).
- The exception is `cc.prep` (total): 0.266 at π vs a target of 0.203. The
  race-specific values match, so this looks like a definition difference
  in the total target.
- Runs from x0 are within **0.22 SD** of π for every target at year 70.

## Interpretation

- **The variance experiment does not restart from a state of the model
  being run.** It restarts from a state produced four months earlier with
  a different parameterisation: other STI natural history, other HIV
  testing, other Hispanic transmission, and no STI screening parameters.
  What it measures is therefore **the relaxation after a parameter change,
  plus the recovery of the between-run variance**. That is exactly what
  happens when calibration waves or intervention runs start from a restart
  point made with other parameters. It is **not** the pure "any
  same-parameter point → full variance" question.
- **This explains why x0 looked atypical in cycle 1.** It was at −4.4 SD
  for chlamydia, +1.4 SD for gonorrhoea and +1.7 SD for HIV incidence in
  year 1. The cause is the parameter change, not chance: the old
  parameters had a lower chlamydia equilibrium (95% of urethral chlamydia
  symptomatic, hence treated).
- **The first-week jumps are consistent with parameters acting
  immediately.** For example, the new STI screening and treatment treats
  existing chlamydia infections, so chlamydia drops in week 1 and rises
  afterwards. An artifact of the restart mechanism itself cannot be ruled
  out without a same-parameter restart. It would be small for HIV: about
  +2.7 infections in one week, against ~1,100 per year.
- **The Sept parameters are well calibrated.** π matches the targets
  within ~1 SD of the model's own stochastic spread.

## Decision / input for next steps

- Cycle 2 reports two things separately:
  - the **direct** x0 values, which answer "restart point made with other
    parameters";
  - **lower bounds for a same-parameter restart point**, from stationary
    pseudo-restarts ([c2_02](c2_02_project_outcomes.md)).
- **Recommended cheap check.** Run 8 runs × 2 years restarted from a state
  saved *by these runs*, with the same parameters, and verify that the
  first weeks are continuous.

## Caveats and deviations

- x0's parameters come from the restart object's `param` list. This assumes
  the list reflects what the generating run used (EpiModel stores it at
  `netsim` time).
- The continuity test uses cross-chain means. Individual-level
  inconsistencies (e.g. timers) that average out are not detected.
