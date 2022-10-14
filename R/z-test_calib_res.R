library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("data/calib/full_results.rds") |> as_tibble()

res1 <- filter(
  res,
  # .iteration <= 4,
  .wave == 1
)

range(res1$hiv.test.rate_1)

# # LOESS
# mod <- loess(hiv.test.rate_1 ~ cc.dx.B, data = res1)
# preds <- cbind(res1, predict(mod, se = TRUE)) %>%
#   mutate(upr = fit + 2 * se.fit, lwr = fit - 2 * se.fit)
#
# # GLM
# mod <- glm(hiv.test.rate_1 ~ cc.dx.B, data = res1, family = Gamma("log"))
# summary(mod)

# LM POLY
# mod <- lm(hiv.test.rate_1 ~ poly(cc.dx.B, 3), data = res1)
# summary(mod)
#
# # plot the points (actual observations), regression line, and confidence interval
# preds <- cbind(res1, predict(mod, type = "response", se.fit = TRUE)) %>%
#   mutate(upr = fit + 2 * se.fit, lwr = fit - 2 * se.fit)
#
# ggplot(preds, aes(y = hiv.test.rate_1, x = cc.dx.B)) +
#   geom_point() +
#   geom_line(aes(y = fit), col = "red") +
#   geom_ribbon(aes(ymin=lwr,ymax=upr), alpha=0.3, col = "blue")
#
# pp <- predict(mod, data.frame(cc.dx.B = 0.847), se = TRUE, type = "response")
# pp

values <- res1$cc.dx.B
params <- res1$hiv.test.rate_1
target <- 0.847

s_v <- (values - mean(values)) / sd(values)
s_p <- (params - mean(params)) / sd(params)
s_t <- (target - mean(values)) / sd(values)


mod2 <- lm(s_v ~ poly(s_p, 4))

preds2 <- as_tibble(predict(mod2, type = "response", se.fit = TRUE)) %>%
  mutate(upr = fit + 2 * se.fit, lwr = fit - 2 * se.fit)

ggplot(data.frame(s_v, s_p, preds2), aes(x = s_p, y = s_v)) +
  geom_point() +
  geom_line(aes(y = fit), col = "red") +
  geom_ribbon(aes(ymin=lwr,ymax=upr), alpha=0.3, col = "blue")

ofu <- function(par, target) {
  abs(predict(mod2, data.frame(s_p = par)) - target)
}

oo <- optimize(
  c(-2, 2),
  f = ofu,
  target = s_t
)
pp <- predict(mod2, data.frame(s_p = oo$minimum))
pp <- predict(mod2, data.frame(s_p = oo$minimum + c(0.01, 0.02, 0.03)))

oo$minimum * sd(params) + mean(params)
pp * sd(values) + mean(values)


