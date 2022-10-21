library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("./data/calib/waves/1/results.rds") |> as_tibble()
calib_object <- readRDS("./data/calib/calib_object.rds")
readRDS("./data/calib/sideloads/cc.linked1m.Btx.init.rate_1cc.linked1m.Htx.init.rate_2cc.linked1m.Wtx.init.rate_3.rds")

res1 <- filter(
  res,
  .iteration == max(.iteration) ,
  .wave == 1
)


values <- c(
  res1$cc.linked1m.B,
  res1$cc.linked1m.H,
  res1$cc.linked1m.W
)
params <- c(
  res1$tx.init.rate_1,
  res1$tx.init.rate_2,
  res1$tx.init.rate_3
)

target <- 0.829

s_v <- (values - mean(values)) / sd(values)
s_p <- (params - mean(params)) / sd(params)
s_t <- (target - mean(values)) / sd(values)

mod2 <- lm(s_v ~ poly(s_p, 3))

preds2 <- as_tibble(predict(mod2, type = "response", se.fit = TRUE)) %>%
  mutate(upr = fit + 2 * se.fit, lwr = fit - 2 * se.fit)

ggplot(data.frame(s_v, s_p, preds2), aes(x = s_p, y = s_v)) +
  geom_point() +
  geom_line(aes(y = fit), col = "red") +
  geom_ribbon(aes(ymin = lwr,ymax = upr), alpha=0.3, col = "blue")

ggplot(data.frame(values, params), aes(x = params, y = values)) +
  geom_point()

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


