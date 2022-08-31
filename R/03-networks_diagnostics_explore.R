##
## 03. Network Model Diagnostics: Interactive Analysis
##

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
source("R/000-project_settings.R")

# Interactive Dx Analysis ------------------------------------------------------

# Main
dx <- readRDS(fs::path(diagnostics_directory, "netdx-main.rds"))
print(dx$dx_main, digits = 2)
plot(dx$dx_main)

print(dx$dx_main_static, digits = 2)
plot(dx$dx_main_static)

# Casual
dx <- readRDS(fs::path(diagnostics_directory, "netdx-casl.rds"))
print(dx$dx_casl, digits = 2)
plot(dx$dx_casl)

print(dx$dx_casl_static, digits = 2)
plot(dx$dx_casl_static)

# Inst
dx <- readRDS(fs::path(diagnostics_directory, "netdx-inst.rds"))
print(dx$dx_inst, digits = 2)
plot(dx$dx_inst)
