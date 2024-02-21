# Restart Point

## Introduction

Make the restart point required to run the final intervention. This step allows
you to run the final simulations before / while the model is being calibrated.

Run the script locally and the corresponding workflow on the HPC and move on to
the interventions.

## Scripts descriptions

- **0-restart_point_single.R**: make a dummy restart point
- **workflow-restart_point.R**: Create the workflow to run the above script on
the HPC.

## What to edit

Nothing.

## On the HPC

The workflow runs the same script on the HPC to prep it for the last steps.
