##
## 03. Network Model Diagnostics: Interactive Analysis
##

# Settings ---------------------------------------------------------------------
#
# Choose the right context: "local" if you are checking the smaller networks
#   estimated locally or "hpc" for the full size networks. For "hpc", this
#   assumes that you downloaded the "netdx-<nwtype>-hpc.rds" files from the HPC.
context <- c("local", "hpc")[1]
source("R/utils-0_project_settings.R")

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")

# Interactive Diagnostics Analysis ---------------------------------------------

# Main
dx <- readRDS(paste0(diag_dir, "netdx-main-", context, ".rds"))
print(dx$dx_main, digits = 2)
plot(dx$dx_main)

print(dx$dx_main_static, digits = 2)
plot(dx$dx_main_static)

# Casual
dx <- readRDS(paste0(diag_dir, "netdx-casl-", context, ".rds"))
print(dx$dx_casl, digits = 2)
plot(dx$dx_casl)

print(dx$dx_casl_static, digits = 2)
plot(dx$dx_casl_static)

# Inst
dx <- readRDS(paste0(diag_dir, "netdx-inst-", context, ".rds"))
print(dx$dx_inst, digits = 2)
plot(dx$dx_inst)
