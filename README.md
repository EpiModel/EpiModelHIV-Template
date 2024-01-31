# EpiModeHIV-Template

Info req for the cloning and managing of EMHIVp should be on the wiki *above*:
- why 2 repos
- HPC vs local setting
- 2 stage calibration / restart point

## Pre-requisite

- EpiModeHIV-p branch created (e.g. `@applied_proj`)
- This repo used to create a new project (e.g. `applied_proj`)

## Conventions

- one folder per section (e.g. `A-networks/`)
- README contains the goal and steps of the section as well as what to edit
- numbered scripts (e.g. 1-network.R) are to be run in order, in new R session
  each time
- workflow scripts (e.g. workflow-network.R) create the workflows for the HPC
  [[link to wiki]]
- the `shared_variables.R` and `z-context.R` scripts are sourced by all numbered
and workflow script.
- An `hpc_context` flag is set for the code that has to be run on the HPC. In
conjunction with `z-context.R`, it sets up HPC specific elements.
- z-context.R sets the specifics settings for HPC or local context
- the other scripts are sourced and exist either to compartimentalize and reuse
  code

## What to edit

Before going into the project's first section, some setup is required.

### R/shared_variables

Set the `EMHIVp_branch` and `EMHIVp_dir` variable with the name of your project
and the path to your local EpiModelHIV-p repository.

In this example:

```r
EMHIVp_branch <- "applied_proj"
EMHIVp_dir <- "~/GitHub/EpiModelHIV-p"
```

If your model is not running weekly time steps, change `time_unit` to the
relevant value (1 for daily, 7 for weekly, etc).

### R/hpc_configs.R

This script sets up the configuration for running code on the HPC. You can skip
this section at first and go back to it when you start working with the HPC.

Set the `mail_user` variable with the mail address where you would like to
receive the notification from the HPC.

The `current_git_branch` is a fail safe preventing the HPC from running the
wrong code. It's set to `main` by default. If you create a new branch on your
project, edit this variable accordingly before running things on the HPC.

*hpc_node_setup* and *default_sbatch_opt* -> TODO

## Initialize the project

Open the script `00-setup.R`.

Make sure that R is restarted after `renv::init(bare = TRUE)`

Run the rest of the script.

## Go to first section: A-networks/README.md

## TODO

- at the end: remake a `run all` workflow
- per step README
  - goal
  - desc of each script
  - what to modify

use `rs()` on top of files that needs restart and make the function  work even
without rstudio


