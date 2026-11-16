# T-truing_calib: an automated `truing` calibration on the HPC

10k nodes, 70-year runs from restart points, ergmkit modules. The engine is
the `truing` package (`calibration_work/truing`), synced next to the project
root (`truing/`, untracked); this chapter is its EpiModelHIV + Slurm side.

- `z-context.R`: calibration name, directories, runs per array task, Slurm
  settings; `TRUING_LOCAL_TEST=1` = a tiny calibration of 1-year runs.
- `config.R`: the `truing_config`: 15 parameters (guess, allowed range, pass-1
  search range = guess x [0.5, 2]), their targets and tolerances, the 4 waves
  (wave 4 = the `hiv.trans.scale` -> `i.prev.dx` joint block + 2 one-parameter
  jobs), restart pools of 32 (every `ir100` at least half its target),
  max 3 passes.
- `controller.R`: one controller step: gather the pending batch, decide the
  next one, build the restart pool it needs, submit the batch as one array (all
  its runs at once) and the next controller with `--dependency=afterany`.
- `run_task.R`: one array task: `truing_runs_per_task` runs in parallel, each
  with its own parameters, seed and restart point; last-year means; the
  restart point of runs marked `.keep`.
- `workflow-calib.R`: the starting workflow (renv restore + first controller).

State (`data/run/truing_calib/<name>/`): `config.rds`, `state.rds`,
`results.rds` (every run: parameters, bookkeeping, outputs), `batches/`,
`pools/` (EpiModelHPC layout, `pool_index.csv`), `jobs/`, `logs/`, `log.txt`,
`status.txt`.

Start:

1. Push this branch; `rsync -a calibration_work/truing/ <hpc>/truing/`.
2. Locally: `HPC_WF_PREFIX=claude_ pixi run Rscript R/T-truing_calib/workflow-calib.R`,
   rsync `workflows/<name>` to the HPC clone.
3. On the HPC, from the project root: `./workflows/<name>/start_workflow.sh`.

A crashed or cancelled controller resumes with
`sbatch data/run/truing_calib/<name>/jobs/<last batch>_controller.sh` (it
gathers what finished and reruns the missing runs once).
