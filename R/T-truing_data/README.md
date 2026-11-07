# T-truing_data: black-box calibration data for `truing`

Large designs of cold 70-year runs (10k nodes, ergmkit modules), gathered in the
swfcalib `full_results` layout: the calibrated parameters, `.proposal_index`,
`.wave`, `.iteration`, `sim`, then `num` and every calibration target (means
over the last year, as `R/Z-calibration/swfcalib_model.R`), then `.campaign`,
`.design`, `.point`, `.scenario`, `.seed`.

- `z-context.R`: campaign name, directories, base seed, cores.
- `design.R`: the waves (parameters, targets, ranges) and the crossed designs
  (`grid`: evenly spaced, `lhs`: one random draw per stratum), shuffled per
  parameter.
- `workflow-wave.R`: one wave iteration = renv restore, one
  `step_tmpl_netsim_scenarios()` per design, the tibble merge, then `gather.R`.
- `gather.R`: last-year means, swfcalib layout,
  `<truing_dir>/results/w<k>_i<j>.rds` and `<truing_dir>/full_results.rds`;
  deletes the intermediates in `data/run/calibration/truing_*` once every
  simulation is there.

Carry variants (wave >= 2, first iteration): the previous wave's parameters
are run at their carried root (full designs) and scaled jointly by x0.1, 0.25,
0.5, 0.8, 1.25, 2, 4, 10 (smaller designs: grid 64x4 + LHS 256), the earlier
waves at their roots. Columns `.carry` / `.carry_factor`; scenario ids
`w<k>_i<j>[_x<f>]_<design>_p<NNNN>`.

Arrays are split into chunks of at most 512 tasks (RSPH `MaxArraySize` = 1001)
and throttled to 32 cores; a wait step follows each chunk (slurmworkflow chains
an array through its last task only).

`TRUING_WAVE`, `TRUING_ITER` select the wave; `TRUING_LOCAL_TEST=1` runs a tiny
version locally (1 year) into `data/run/truing/TEST` instead of building a
workflow.

Loop:

1. Set `wave`/`iteration` in `workflow-wave.R` and run it locally
   (`pixi run Rscript R/T-truing_data/workflow-wave.R`).
2. On the HPC clone: same branch, `data/run/estimates/*-local.rds` uploaded once,
   then `./workflows/<name>/start_workflow.sh` from the project root.
3. Download `data/run/truing/<campaign>/` (results only), explore solvers.
4. Write the values to carry forward in `<truing_dir>/carry.csv`
   (`param,value`), next wave.

Seeds: each design step exports `TRUING_SEED`; the `.Rprofile` sets
`set.seed(TRUING_SEED + k)` in array element `k`, and `gather.R` records it in
`.seed` (the replicates of a batch derive from it via `future.seed`).
