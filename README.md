# EpiModelHIV-Template

This template is a scaffold for an EpiModelHIV applied project. It walks you
through every step from cloning the repo to publication-ready tables and plots.

This project relies on several tools:

- [EpiModel](https://epimodel.github.io/EpiModel/) — network-based epidemic simulation framework
- [EpiModelHIV](https://github.com/EpiModel/EpiModelHIV-p) — HIV/STI modules built on EpiModel
- [ARTnet](https://github.com/EpiModel/ARTnet) — sexual partnership survey data used for network estimation
- [slurmworkflow](https://epimodel.github.io/slurmworkflow/) — HPC job pipeline generation
- [renv](https://rstudio.github.io/renv/) — R package version management

See the [EpiModeling wiki](https://github.com/EpiModel/EpiModeling/wiki) for
how we use these tools in practice.

## Setup

Before running any scripts, complete these steps in order.

### 1. Prerequisites

This project has two components that work together:

- **Your applied project** (this repo) — scripts, parameters, and analysis for your research question.
- **`EpiModelHIV-p@<your_branch>`** — your custom branch of the EpiModelHIV-p package containing the simulation modules.

From now on, we refer to your applied project as `<applied_project>` and to
your package branch as `EpiModelHIV-p@<applied_project>`.

- [ ] Create a new repository `<applied_project>` from the [`EpiModelHIV-Template`](https://github.com/EpiModel/EpiModelHIV-Template) ("Use this template" green button above) and clone it to your local machine
- [ ] Create a new branch on [`EpiModelHIV-p`](https://github.com/EpiModel/EpiModelHIV-p) for your project and clone it to your local machine
- [ ] Have access to [ARTnetData](https://github.com/EpiModel/EpiModeling/wiki#artnetdata)
- [ ] Have an RSPH HPC account ([instructions](https://github.com/EpiModel/EpiModeling/wiki#hpc-setup)) for the HPC parts

### 2. Personalize

A few configuration files need to be edited before you can run any scripts.
These files are documented with inline comments — look for `# <- USER` markers
to find the values you need to change.

Open the following two files and edit every variable marked with `# <- USER`.
**The project will not work until this is done.**

- **`R/shared_variables.R`**
- **`R/hpc_configs.R`**

### 3. Initialize the R environment

Open **`R/00-setup.R`** and run it step by step (read the comments — there is
a required R restart in the middle).

This installs all R packages and copies the default parameter file into
`data/input/`.

### 4. Start Chapter A

You are now ready to begin. Head to [`R/A-networks/README.md`](R/A-networks/README.md).

---

## Project overview

The project is organized into four sequential chapters under `R/`:

| Chapter | What it does | Output |
|---|---|---|
| [**A — Networks**](R/A-networks/README.md) | Estimate partnership network models from ARTnet data | `data/run/estimates/` |
| [**B — Model Dev**](R/B-model_dev/README.md) | Run simulations, develop and debug custom modules | — |
| [**C — Calibration**](R/C-calibration/README.md) | Fit parameters to epidemiological targets | `data/run/calibration/` |
| [**D — Interventions**](R/D-interventions/README.md) | Run intervention scenarios, produce tables and plots | `data/run/scenarios/` & `data/output/` |

In practice the workflow is iterative — you will cycle between B, C, and D as
the project evolves.

## Conventions

**Script types** — Each chapter contains:

- **Numbered scripts** (`1-*.R`, `2-*.R`): top-level scripts, run in a fresh R session (`Ctrl+Shift+F10`), in order.
- **`workflow-*.R`**: generate HPC job files via [slurmworkflow](https://github.com/EpiModel/EpiModeling/wiki#slurmworkflow). Run locally.
- **`z-context.R`**: switches between local (small, fast) and HPC (full-scale) settings. Sourced, never run directly.
- **Other scripts**: utilities sourced by numbered scripts. Never run directly.

**Shared variables** — `R/shared_variables.R` is sourced by every top-level
script and is the single source of truth for paths, time steps, and milestones.
Never redefine its variables in other scripts.

**Data directories:**

- `data/input/` — parameters, scenario definitions (**git-tracked**)
- `data/run/` — estimates, calibration, raw simulations (not tracked)
- `data/output/` — publication tables and plots (not tracked)
