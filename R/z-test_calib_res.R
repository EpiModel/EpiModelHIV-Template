library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("./data/results.rds") |> as_tibble()
# res <- readRDS("./data/calib/full_results.rds") |> as_tibble()
calib_object <- readRDS("./data/calib/calib_object.rds")
calib_object$state$default_proposal

res1 <- filter(
  res,
  # between(.iteration, 3, 5),
  .wave == 1
)

values <- c(
  res1$cc.dx.B,
  res1$cc.dx.H,
  res1$cc.dx.W
)
params <- c(
  res1$hiv.test.rate_1,
  res1$hiv.test.rate_2,
  res1$hiv.test.rate_3
)

target <- c(0.847, 0.818, 873)[2]

s_v <- (values - mean(values)) / sd(values)
s_p <- (params - mean(params)) / sd(params)
s_t <- (target - mean(values)) / sd(values)

mod2 <- lm(s_v ~ poly(s_p, 4))
preds2 <- as_tibble(predict(mod2, type = "response", se.fit = TRUE))
mod3 <- lm(s_v ~ poly(s_p, 5))
preds3 <- as_tibble(predict(mod3, type = "response", se.fit = TRUE))
mod4 <- mgcv::gam(s_v ~ s(s_p, bs = "cs"))
preds4 <- as_tibble(predict(mod4, type = "response", se.fit = TRUE))

ggplot(data.frame(s_v, s_p), aes(x = s_p, y = s_v)) +
  geom_point() +
  geom_line(data = preds2, aes(y = fit), col = "red") +
  geom_line(data = preds3, aes(y = fit), col = "blue") +
  geom_line(data = preds4, aes(y = fit), col = "green") +
  geom_hline(yintercept = s_t)

# close_vals <- abs(values - target) < 0.01
# close_pars <- params[close_vals]
# sum(close_vals)
# hist(close_pars)
# mean(close_pars)
# median(close_pars)

opti_f <- function(mod) {
  function(par, target) {
    abs(predict(mod, data.frame(s_p = par)) - target)
  }
}

oo <- optimize(c(-2, 2), f = opti_f(mod2), target = s_t)

pp <- predict(mod2, data.frame(s_p = oo$minimum))

old_pp =  predict(mod2, data.frame(s_p = (old_oo - mean(params)) / sd(params)))
old_oo = oo$minimum * sd(params) + mean(params)
old_oo

pp4 * sd(values) + mean(values)
old_pp * sd(values) + mean(values)
