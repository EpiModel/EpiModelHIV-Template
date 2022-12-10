##
## 03. Network Model Diagnostics: Interactive Analysis
##

# Setup ------------------------------------------------------------------------
library("EpiModelHIV")

# Interactive Dx Analysis ------------------------------------------------------

# Main
dx <- readRDS("data/intermediate/diagnostics/netdx-main.rds")
print(dx$dx_main, digits = 2)
plot(dx$dx_main)
plot(dx$dx_main, type = "duration")

print(dx$dx_main_static, digits = 2)
plot(dx$dx_main_static, sim.lines = TRUE, sim.lwd = 0.1)

# Casual
dx <- readRDS("data/intermediate/diagnostics/netdx-casl.rds")
print(dx$dx_casl, digits = 2)
plot(dx$dx_casl)
plot(dx$dx_casl, type = "duration")

print(dx$dx_casl_static, digits = 2)
plot(dx$dx_casl_static, sim.lines = TRUE, sim.lwd = 0.1)

# Inst
dx <- readRDS("data/intermediate/diagnostics/netdx-inst.rds")
print(dx$dx_inst, digits = 2)
plot(dx$dx_inst, sim.lines = TRUE, sim.lwd = 0.1)
