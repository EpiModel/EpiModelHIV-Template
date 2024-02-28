## 3. Network Model Diagnostics: Interactive Assessment
##
## Assess the diagnosed network models using the diagnostics computed on the
## previous script.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

hpc_context <- FALSE # set to TRUE to evaluate HPC estimates
source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R")

# Process ----------------------------------------------------------------------

# 1. Main model
dx <- readRDS(fs::path(diag_dir, paste0("netdx-main-", context, ".rds")))
print(dx$dynamic, digits = 2)
plot(dx$dynamic)

print(dx$static, digits = 2)
plot(dx$static)

# 2. Casual model
dx <- readRDS(fs::path(diag_dir, paste0("netdx-casl-", context, ".rds")))
print(dx$dynamic, digits = 2)
plot(dx$dynamic)

print(dx$static, digits = 2)
plot(dx$static)

# 3. One-Off model
dx <- readRDS(fs::path(diag_dir, paste0("netdx-ooff-", context, ".rds")))
print(dx$static, digits = 2)
plot(dx$static)
