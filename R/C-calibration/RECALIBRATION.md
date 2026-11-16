# Running a recalibration campaign

Procedural companion to `README.md`, which describes the three-phase pipeline. This file is about what goes wrong and how to avoid it. Each item below cost a real campaign.

**Where the target numbers come from is documented elsewhere.** The template's targets are the engine defaults, which are Atlanta's: `EpiModelHIV-p/inst/AHEAD/DERIVATION.md` has each target's inputs and formula, and `EpiModelHIV-p/plan/calibration-targets-2026.md` the decisions behind them. A project with its own `data/input/targets.csv` carries a source on each row; for the cities our team models, the file and the script that derives it are in `cities/` of EpiModelHIV-Appendix. Procedure lives here, because this is where the scripts that run it are.

## Before you launch anything

**Override targets in one place.** `R/calibration_targets.R` defines `project_calibration_targets()`, and every consumer reads through it: `swfcalib_config.R`, `3-choose_restart.R`, `process_calibs.R`, `utils-calib_plots.R`. Do not override at a call site. A campaign has previously been run with settled targets that lived only in a GitHub issue while every script still read the engine defaults.

**Bracket-check every target whose parameter you are about to sweep.** A root outside the prior is expensive even with the Gaussian process (GP) rules. A job whose design does not reach its target widens the design toward it, one full design of simulations per iteration, up to the extended range in `swfcalib_config.R`, and a wave still open after `max_iteration` (4) stops the campaign. Under the earlier shrink and SE-range proposers it was worse: the job pinned at a boundary, burned its full 100-iteration budget, and reported the boundary as converged. Run a short sweep of the parameter across its prior, fit the mean response curve, invert it for the root, and confirm the root sits inside the prior with headroom. Any change to a target moves its root; a natural-history change once moved the chlamydia root from 0.204 to 0.142 against a prior floor of 0.19, which would have deadlocked the STI wave for its whole budget.

**Check the extinction cliff for the STI parameters.** Below some transmission probability a fraction of replicates go extinct, and the mean incidence curve becomes meaningless. Report the root's headroom over the cliff, and filter to replicates with an extinction fraction under 0.5 before fitting. The STI jobs build in a version of the filter: they fit their GP on the design points at which every run kept the epidemic alive (`positive_only` in `het_gp_process.R`), and `calib_sti_checks.csv` reports each STI's fade-out share after the confirmation run.

**Archive, do not reuse, prior swfcalib state.** `swfcalib::calibration_step1()` starts with `load_calib_object()`, which reads `data/run/swfcalib/calib_object.rds` if it exists and discards the object `swfcalib_config.R` just built. A stale state whose late waves are marked `done = TRUE` makes `is_calibration_complete()` return `TRUE`: the workflow skips ahead, `update_param.R` writes the previous campaign's values back out, and the run mails END looking like a successful recalibration. Move it to a timestamped path rather than deleting it, so the prior assessments survive.

## Things that fail silently

**`TIMEOUT` is not `FAILED`.** A SLURM task killed at its wall exits `TIMEOUT`, so `mail-type = "FAIL"` sends nothing and the campaign looks healthy while some array tasks produced no output. Every long step in this repo now requests `"FAIL,TIME_LIMIT"`. Keep it that way when you add steps.

**Restart points and absolute-time attributes.** `make_restart_point_hiv()` in `utils-restart.R` time-shifts only the attributes matching `time_prefixes`, currently `.last$`, `.time$`, `.due$`. Any new attribute holding an absolute timestep must match one of those suffixes or be added. `prep.inj.due` was missed once: restarts carried a step-3640 value into a run whose clock restarts at 2, so injections never came due again and the LAI arm quietly stopped re-dosing. No error, just wrong results.

**Blanket type coercion in `swfcalib_config.R`.** The parameter table now carries character and logical parameters alongside the numeric ones. `swfcalib_config.R` filters to numeric before the wide pivot; if you widen `default_proposal`, make sure you are not pulling a coerced `NA` into the simulations.

**Sweep grids defined twice.** `step_tmpl_merge_netsim_scenarios_tibble` writes one tibble per scenario and the scenario identity survives only in the filename. The tibbles carry no record of the swept values. Define any sweep grid in one sourced file, used by both the workflow and the analysis, and `stopifnot` that every scenario found is in the grid. Two copies will drift and silently mislabel every root.

## Judging the result

**Fit is not the same as rest.** Report, per target, the slope over the end of the burn-in alongside the mean that is scored. A target met in passing on a monotone trajectory is not the same as one at equilibrium, and the fitted parameter absorbs whatever truncation the horizon imposes. Diagnosed HIV prevalence has historically been the only target in this model that fails this check, drifting 1.4 to 3.3 percent of target per decade at year 70 against acceptance bands of order 12 percent. See EpiModelHIV-p#374. `process_calibs.R` makes the check after every run, in `calib_drift.csv` (`drift_table()`): each target's slope over the final 20 years, per decade, with an interval clustered on the restart-pool member. A target is at rest when it drifts within 0.25 tolerances per decade, and diagnosed prevalence by race, the sentinel for the slowest HIV mode, when it moves less than 1 percent of its own level per decade.

**Use plausible intervals, not just the point target.** `project_calibration_intervals` in `R/calibration_targets.R` is where they go; with a `data/input/targets.csv` they are read from its `lower` and `upper` columns. The optimizer does not read them; they are how you decide whether a calibrated model is acceptable rather than merely closest, and they are what sets prior width for a bracket check.

## The wave structure

Waves run in order because later parameters depend on earlier ones being right. Jobs within a wave run in parallel. The current table is in `README.md`. Notes on it:

- Wave ordering encodes the causal chain: the care cascade (PrEP, testing, suppression) must be right before transmission outcomes are tuned.
- Skipping early waves after a late-wave target moves is a measurement, not an assumption. Regress each early-wave outcome on the quantity that changed, over the range the previous campaign swept, and show the implied drift is below the tolerance those waves converged to.
- HIV transmission is fitted before the STIs, and the coupling between them runs both ways at similar strength. In the first-pass runs of a four-city calibration (November 2026), an HIV diagnosis rate moved 0.01 to 0.9 of its tolerance per tolerance of an STI rate, and an STI rate 0 to 0.45 of its tolerance per tolerance of an HIV rate, so neither order is free. HIV goes first because its parameters move more between calibration passes, and the STI fits, which sit just above their extinction thresholds, are fitted last, against an HIV epidemic near its final level. The HIV miss this leaves is corrected by a later pass that refits the HIV wave.

## Known gaps in this scaffold

Recorded so they are not rediscovered. Both are ports from LA-PrEP-2026 rather than new work.

**The restart-point workflow.** `workflow-restart_point.R` (added 10/12/26, adapted from LA-PrEP-2026, now LA-PrEP-CABARET-EPI) runs a pool of replications with the current parameters (`n_rep`: 64 for a first pool before swfcalib, 500 after calibration), merges them, saves the best as the restart point through `3-choose_restart.R`, and writes `calib_assess.csv`. Clear the previous `sim__empty_scenario__*.rds` pool from `calib_dir` on the HPC before each run, or the merge mixes old and new simulations. `workflow-restart_pool.R` turns the same simulations into the restart pool the swfcalib runs start from.

**The bracket check is not here.** LA-PrEP-2026 carries it as two near-duplicate scripts, one for the STI probabilities and one for `prep.start.rate`. They should collapse into a single script taking a caller-supplied list of (target, parameter) pairs, since the analysis core is already generic: summarize the mean response curve, filter to replicates below the extinction threshold, invert for the root, and report the root's position within the swept range. This matters more than it looks. Every target move relocates its root, and a job whose root has left its prior spends whole iterations widening toward it.
