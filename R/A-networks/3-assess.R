##
## 03. Network Model Diagnostics: Interactive Analysis
##

# Settings ---------------------------------------------------------------------
#
source("R/shared_variables.R")
# hpc_context <- TRUE
source("R/A-networks/z-context.R")

# Libraries  -------------------------------------------------------------------
library("EpiModel")

# Interactive Diagnostics Analysis ---------------------------------------------

# Main
dx <- readRDS(paste0(diag_dir, "netdx-main-", context, ".rds"))
print(dx$dynamic, digits = 2)
plot(dx$dynamic)

print(dx$static, digits = 2)
plot(dx$static)

# Casual
dx <- readRDS(paste0(diag_dir, "netdx-casl-", context, ".rds"))
print(dx$dynamic, digits = 2)
plot(dx$dynamic)

print(dx$static, digits = 2)
plot(dx$static)

# Inst
dx <- readRDS(paste0(diag_dir, "netdx-ooff-", context, ".rds"))
print(dx$static, digits = 2)
plot(dx$static)
