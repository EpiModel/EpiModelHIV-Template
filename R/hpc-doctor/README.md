# Deploy doctor (project launcher)

The deploy-doctor logic lives in the **EpiModelHPC** package (`inst/hpc_doctor/`), not in this repo. Projects invoke it through `EpiModelHPC::hpc_doctor_script()`, so there is no private copy here to drift from the package.

This directory holds one project-specific file:

- `deploy_doctor.sbatch`: the SLURM launcher. Replace the three placeholders (`<HPC_PROJECT_DIR>`, `<HPC_MAIL_USER>`, `<JOB_NAME_PATTERN>`) before first use.

## Launch

Launch the doctor from the deploy script, idempotently, alongside a campaign (once at least one workflow's renv-restore step has installed EpiModelHPC on the node):

```bash
ssh "$HPC" "squeue -u \$USER -h -o '%j' | grep -qx deploy_doctor || (cd <HPC_PROJECT_DIR> && sbatch R/hpc-doctor/deploy_doctor.sbatch)"
```

Report-only (no requeues): `sbatch --export=ALL,ACT= R/hpc-doctor/deploy_doctor.sbatch`.

## Teardown (automatic, from the workflow)

The doctor is one job shared across every concurrent campaign whose name matches its `PATTERN`, so it must be stopped only when the **last** campaign finishes, not when any single workflow does. Each workflow does this with the two EpiModelHPC watch-list steps, added in the generator:

```r
wf <- make_em_workflow("my_campaign", override = TRUE)
wf <- add_doctor_register_step(wf, "my_campaign")   # near the start
# ... netsim / merge / process steps ...
wf <- add_doctor_teardown_step(wf, "my_campaign")   # last step
```

The register step marks the campaign live in a watch-list directory (`data/run/.doctor_watch`, gitignored); the teardown step removes that marker and stops the doctor only once the directory is empty. It is race-free across simultaneous finishes and runs even if an earlier step fails (`afterany` chaining). See `?add_doctor_teardown_step`. Register and teardown are a matched pair: a workflow that registers but never tears down leaves a stale marker that blocks teardown for other campaigns.
