# EpiModeHIV-Template

This repository contains an example applied project using [EpiModelHIV-p](https://github.com/EpiModel/EpiModelHIV-p). It may be used as a "starter" project repository for future applied projects. 

## ARTnet/ARTnetData Dependency
EpiModelHIV-p requires installation of the `ARTnet` package, which itself depends on the `ARTnetData` package that contains the restricted dataset for the ARTnet study. Before getting started with the package workflow below, make sure you have requested access to the `ARTnetData` package and can successfully install and load the `ARTnet` package following the instructions on the [ARTnet package repository](https://github.com/EpiModel/ARTnet#readme).

## Setup
This template project works with the [`renv`](https://rstudio.github.io/renv/index.html) package manager system. First, clone this repository locally, then load the project in Rstudio by opening the `.Rproj` file in the root directory. Finally, initialize the R package library by running the `renv::init()` command, and choose "Restore the project from the lockfile." This will install the packages dependencies in their correct versions. After that, you are ready to run the scripts in `R/`.
