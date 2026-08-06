#!/bin/bash
# Project launcher for the EpiModelHPC deploy doctor: a one-CPU companion job
# that sweeps for CPU-starved / degenerate SLURM tasks over the life of a
# campaign, requeues them, and self-terminates when its watched jobs drain. The
# doctor LOGIC lives in the EpiModelHPC package (inst/hpc_doctor/, resolved at
# runtime via EpiModelHPC::hpc_doctor_script()), so this repo carries no copy of
# the scripts and cannot drift from the package. This launcher is the only
# project-specific piece.
#
# BEFORE FIRST USE, replace the three placeholders:
#   <HPC_PROJECT_DIR>   absolute path to this project's checkout on the cluster
#                       (e.g. /projects/epimodel/<user>/<Project>), in BOTH the
#                       cd and the --output line below.
#   <HPC_MAIL_USER>     SLURM notification address (e.g. you@emory.edu).
#   <JOB_NAME_PATTERN>  extended-regex matching THIS project's campaign job names
#                       ONLY (e.g. '(restart_point|myproj_.*|swfcalib)'). It must
#                       not match other projects' jobs running on the account.
#
# Launch it once per deploy, idempotently, from the deploy script (after at least
# one workflow's renv-restore step has installed EpiModelHPC on the node):
#   ssh "$HPC" "squeue -u \$USER -h -o '%j' | grep -qx deploy_doctor || (cd <HPC_PROJECT_DIR> && sbatch R/hpc-doctor/deploy_doctor.sbatch)"
#
# The workflows stop it automatically once the last campaign finishes, via
# EpiModelHPC::add_doctor_teardown_step() (see this directory's README.md), so it
# does not need a manual scancel.
#
#   sbatch R/hpc-doctor/deploy_doctor.sbatch
#   sbatch --export=ALL,ACT= R/hpc-doctor/deploy_doctor.sbatch   # report-only
#
#SBATCH --job-name=deploy_doctor
#SBATCH --partition=week-long-cpu,day-long-cpu,epimodel
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=7-00:00:00
#SBATCH --nice=9000000
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<HPC_MAIL_USER>
#SBATCH --output=<HPC_PROJECT_DIR>/data/run/deploy_doctor_%j.log

set -u
cd <HPC_PROJECT_DIR>
. /projects/epimodel/spack/share/spack/setup-env.sh
spack unload -a
spack load r@4.5.1

# Resolve the doctor from the installed EpiModelHPC package (not a repo copy).
# The path is wrapped in markers because renv's startup messages print to stdout
# during activation; extract only what is between the markers.
DOCTOR=$(Rscript -e 'cat("@@P@@", EpiModelHPC::hpc_doctor_script("deploy_doctor.sh"), "@@E@@", sep="")' 2>/dev/null | sed -n 's/.*@@P@@\(.*\)@@E@@.*/\1/p')
test -n "$DOCTOR" && test -f "$DOCTOR" || { echo "ERROR: could not resolve doctor script (got: '$DOCTOR')" >&2; exit 1; }

# PATTERN must match THIS project's campaign job names only.
PATTERN='<JOB_NAME_PATTERN>' bash "$DOCTOR"
