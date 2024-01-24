##
## 03. Network Model Diagnostics: Interactive Analysis
##

# Settings ---------------------------------------------------------------------
#
source("R/shared_variables.R")
hpc_context <- FALSE # set to TRUE to evaluate HPC estimates
source("R/A-networks/z-context.R")

# Libraries  -------------------------------------------------------------------
library("EpiModel")

# Interactive Diagnostics Analysis ---------------------------------------------

# Main
dx <- readRDS(fs::path(diag_dir, paste0("netdx-main-", context, ".rds")))
print(dx$dynamic, digits = 2)
plot(dx$dynamic)

print(dx$static, digits = 2)
plot(dx$static)

# Casual
dx <- readRDS(fs::path(diag_dir, paste0("netdx-casl-", context, ".rds")))
print(dx$dynamic, digits = 2)
plot(dx$dynamic)

print(dx$static, digits = 2)
plot(dx$static)

# Inst
dx <- readRDS(fs::path(diag_dir, paste0("netdx-ooff-", context, ".rds")))
print(dx$static, digits = 2)
plot(dx$static)
