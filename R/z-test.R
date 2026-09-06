library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

props <- readRDS("./props.rds")
print(props, n = 200)
sort(props$gono.uret.prob)
sort(props$chla.uret.prob)
sort(props$syph.prob)


results <- readRDS("./gp_res.rds")

ggplot(results, aes(x = gono.uret.prob, y = ir100.gono)) +
  geom_hline(yintercept = 12.81) +
  geom_smooth() +
  geom_point(aes(col = factor(.iteration)))

ggplot(results, aes(x = chla.uret.prob, y = ir100.chla)) +
  geom_hline(yintercept = 14.59) +
  geom_smooth() +
  geom_point(aes(col = factor(.iteration)))

ggplot(results, aes(x = syph.prob, y = ir100.syph)) +
  geom_hline(yintercept = 1) +
  geom_smooth() +
  geom_point(aes(col = factor(.iteration)))


results <- readRDS(fs::path(swfcalib_dir, "prev_results.rds"))
# ---- data ----
d <- tibble(
  p = results$syph.prob,
  y = results$ir100.syph
)

library(GauPro)

kern <- k_Matern52(D = 1)
kern <- k_Gaussian(D = 1)
gp <- gpkm(d$p, d$y, kernel = kern)

gp$plot1D()
gp$cool1Dplot()

summary(gp)
plot(gp)

# With mvtnorm
#
# - assumption about the structure of the kernel
# - does mvtnorm estimate the params? (of the kernel)
# - does mvtnorm estimate the measurement error?

rmvnorm(10, 1:5, diag(1, 5, 5))


# Use `hmer` for 3 GP, one per hiv.scale
