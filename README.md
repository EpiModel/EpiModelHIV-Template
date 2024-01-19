# EpiModeHIV-Template

This template repository contains a working [EpiModelHIV-p](https://github.com/EpiModel/EpiModelHIV-p) project to be used as a starting point for new applied research.

Follow the instructions on this README to setup your own project.


*Assume the user knows how to create repo etc or send to a wiki page*

## Setup

before going to a step

1. edit `R/shared_variables.R`
  *sep what is to be edited from the rest*
2. go through `R/00-setup.R`
3. go to step `A-networks_local/README.md`

## Pre-requisite

This document assumes that you are working with [RStudio](https://posit.co/products/open-source/rstudio/) and the [GitHub deskto app](https://desktop.github.com/).

*These are not mandatory. If you are not using them you probably know your way around `R` and `git` and will have no trouble following along*.

## Setting up the project on GitHub

You will need a name for your project. I will use `applied_proj` for this example. (I suggest sticking to [snake_case](https://en.wikipedia.org/wiki/Snake_case) for your own project name).

To get started create the `applied_proj` repository on GitHub by clicking on the green *Use this template* button and select the *Create a new repository* option in the drop down menu.

Next, create a new `applied_proj` branch on [EpiModelHIV-p](https://github.com/EpiModel/EpiModelHIV-p).

## Setting up the project on your computer

On your computer, clone your `applied_proj` repository as well as [EpiModelHIV-p](https://github.com/EpiModel/EpiModelHIV-p) and checkout your `applied_proj` branch.


### for this: just link to a wiki pages outside

*File -> Clone repository...* : make the GitHub folder outside of one drive?

- make sure the GITHUB_PAT is already setup (usethis::edit_r_environ())

On RStudio: create a new project -> existing directory (so 2 new projects)

### Start on the `applied_proj` rstudio project

Open "R/00-setup.R"

edit the `EpiModelHIV-p@<branch>`

run:

```r
renv::init(bare = TRUE)
```

then restart R (ctrl+shift+F10)

then the rest

Edit the `R/shared_variables.R` file:
  - `mail_user`
  - `EMHIVp_dir`

An applied EpiModelHIV project is composed of multiple sequential steps located within the `R/` directory.

Each step contains several `R` scripts, and a `README.md` file explaining how to adapt the code to fit the needs of the project.

## General rules

- Only run the numbered scripts
- Always restart R before running them
- the `source`d scripts are utilities
- Follow the guidance in each step README


## ARTnet/ARTnetData Dependency

EpiModelHIV-p requires installation of the `ARTnet` package, which itself depends on the `ARTnetData` package that contains the restricted dataset for the ARTnet study. Before getting started with the package workflow below, make sure you have requested access to the `ARTnetData` package and can successfully install and load the `ARTnet` package following the instructions on the [ARTnet package repository](https://github.com/EpiModel/ARTnet#readme).

## Setup
This template project works with the [renv](https://rstudio.github.io/renv/index.html) package manager system. First, clone this repository locally, then load the project in Rstudio by opening the `.Rproj` file in the root directory. Finally, initialize the R package library by running the `renv::init()` command, and choose "Restore the project from the lockfile." This will install the packages dependencies in their correct versions. After that, you are ready to run the scripts in `R/`.
