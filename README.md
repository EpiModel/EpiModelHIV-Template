# EpiModeHIV-Template

## Introduction

This template is a scaffold for an EpiModeHIV applied project. Before reading on
make sure you have read the [getting
started](https://github.com/EpiModel/EpiModeling/wiki/Getting-Started-with-EpiModelHIV) wiki page and done all the
relevant steps.

From now on, we refer to the **applied project** as `applied_proj` and to your
custom `EpiModeHIV-p` branch as `EpiModeHIV-p@applied_proj`.

At this point, we assume that you have your applied project cloned on your local
computer and your `EpiModeHIV-p` branch checked out as well.

This template is divided into several **steps**. They are separated as
sub-directories under the `R/` folder. They each contain a `README.md` file. We
will describe each of them below.

## Getting started: fitting your project

First of, some scripts will need a few modification to fit your project.

### shared_variables.R

This files contains the generic configuration for the project. It will be
sourced by every top level scripts.

Open it now and edit the following variables:

```r
EMHIVp_branch <- "applied_proj"          # the name of your project
EMHIVp_dir <- "Desktop\git\EpiModeHIV-p" # the path to EpiModeHIV-p  directory

time_unit <- 7     # number of days in a time step (7 for weekly)
```

### hpc_configs.R

This scripts contains configuration for running things on the HPC.

Open it now and edit the `mail_user` variable to reflect your own e-mail address.
It will be used to notify you of the progress of your jobs on the HPC.

The `current_git_branch` variable should be left to `main` most of the time.
Modify it only if you created an new branch and want to run code from it on the HPC.

If you are working with the RSPH HPC, leave the rest unchanged. Otherwise modify
the code accordingly.

### netsim_settings.R

This script defines the default settings for `netsim`. The default values are
probably correct. Edit the `init` variable to be `init <- init_msm()` if you
need to disable the STIs in your model.

### z-test.R

This file is for you to test code interactively before saving it into a more
appropriate place once it's tested.

## Getting started: setting up the environment

Go to the `00-setup.R` file.

Run the `renv::init(bare = TRUE)` line **and restart the R session before
carrying on**.

Run the rest of the script. It will install all the necessary packages.

At this point you can go the `README.md` file for step **A-networks**

## Table of content

Below is a list of all the steps with a quick description.

- **A-networks**: Estimate and diagnosed the network models.
- **B-netsim_explore**: Get familiar with running network models with `netsim`
- **C-netsim_scenarios**: Run network models with the scenario API
- **D-restart_point**: Mandatory non interactive step
- **E-intervention_explore**: Get familiar with restarting network models with `netsim`
- **F-intervention_scenarios**: Run intervention scenarios and process results for publication
- **Z-calibration**: *advanced step addressing calibration*


## Common mistakes

- rm the workflow dir locally and on the HPC before sending a new one.

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
- only the numbered and workflow scripts should call `library`. The other one
should be just the code itself
- source files in `setup ----` if they only provide functions and in `process ---`
if they are the code itself

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


