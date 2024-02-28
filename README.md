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

## Conventions

Each script in this project is structured in the same way to simplify reading.
As these applied project are pretty complex, you are advised to read the code
and make sure you understand what it does before running it. Comments are often
present to guide you along the way.

### Top level scripts

By *top level scripts* we mean the scripts that will be executed directly by the
user.

They are all the scripts starting with as number (e.g. `1-estimation.R`) or the
scripts starting with `workflow` (e.g. `workflow-networks.R`).

These scripts are meant to be run in clean R session. It is advised to restart
R before running these scripts. This can be done by pressing `Ctrl+Shift+F10`
on RStudio. (Note, `.rs.restartR()` is **NOT** the same at all).

All other scripts are utilities. They provide variables or functions to the top
level ones and should not be run on their own.

### The `z-context.R` scripts

Each step contains a `z-context.R`. It defines specific parameters differently
depending on the context of executions.

The two possible contexts are `local` or `hpc`. Local means *your own computer*
and *hpc* is the High Performance Computing cluster where you will run your
large scale simulations.

You will probably not need to edit these files.

Simply know that the context switching is done by setting the following variable
before these scripts are sourced:

```r
hpc_context <- TRUE
```

### General advise on making new scripts

When creating a new top level script you should adhere to the global structure
used all over this repo. These project of ours are very complex with many moving
pieces. Trying to keep them as clean as possible helps a lot in not getting lost.

## Getting started: fitting your project

First of, some scripts will need a few modification to fit your project.

### shared_variables.R

This files contains the generic configuration for the project. It will be
sourced by every top level scripts.

Open it now and modify the following variables to fit your project:

```r
EMHIVp_branch <- "applied_proj"             # the name of your project
EMHIVp_dir <- "Desktop\\git\\EpiModelHIV-p" #  path to EpiModeHIV-p  directory

time_unit <- 7     # number of days in a time step (7 for weekly)
```

### hpc_configs.R

This scripts contains configuration for running things on the HPC.

Open it now and modify the `mail_user` variable to reflect your own e-mail
address. It will be used to notify you of the progress of your jobs on the HPC.

The `current_git_branch` variable should be left to `main` most of the time.
Modify it only if you created an new branch and want to run code from it on the
HPC.

If you are working with the RSPH HPC, leave the rest unchanged. Otherwise modify
the code accordingly.

### netsim_settings.R

This script defines the default settings for `netsim`. The default values are
probably correct. Modify the `init` variable to be `init <- init_msm()` if you
need to disable the STIs in your model.

### z-test.R

This file is for you to test code without making another script *dirty*. As a
reminder, you should **always** write code in a file and not in the R console.
Even if it's just for a *quick* test.

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

Here is a list of commonly made mistakes to help you avoid them as you go:

### Workflow directories

As you start working with the HPC, you will create workflow directories. Do not
forget to delete them locally AND on the HPC before making a new one with the
same name.

On the HPC this can be done with:

```sh
rm -rf workflows/<the name of your workflow>
```

