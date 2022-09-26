##
## 03. Network Model Diagnostics: Interactive Analysis
##

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
source("R/00-project_settings.R")

# Interactive Dx Analysis ------------------------------------------------------

# Main
dx <- readRDS("data/intermediate/diagnostics/netdx-main.rds")
print(dx$dx_main, digits = 2)
plot(dx$dx_main)

print(dx$dx_main_static, digits = 2)
plot(dx$dx_main_static)

# Casual
dx <- readRDS("data/intermediate/diagnostics/netdx-casl.rds")
print(dx$dx_casl, digits = 2)
plot(dx$dx_casl)

print(dx$dx_casl_static, digits = 2)
plot(dx$dx_casl_static)

# Inst
dx <- readRDS("data/intermediate/diagnostics/netdx-inst.rds")
print(dx$dx_inst, digits = 2)
plot(dx$dx_inst)
