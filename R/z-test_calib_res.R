library(dplyr)
library(ggplot2)
theme_set(theme_light())

it <- 1
res1 <- readRDS("data/calib/waves/1/results.rds") %>%
   filter(between(.iteration, it - 1, it + 1))

# # LOESS
# mod <- loess(hiv.test.rate_1 ~ cc.dx.B, data = res1)
# preds <- cbind(res1, predict(mod, se = TRUE)) %>%
#   mutate(upr = fit + 2 * se.fit, lwr = fit - 2 * se.fit)
#
# # GLM
# mod <- glm(hiv.test.rate_1 ~ cc.dx.B, data = res1, family = Gamma("log"))
# summary(mod)

# LM POLY
mod <- lm(hiv.test.rate_1 ~ poly(cc.dx.B, 3), data = res1)
summary(mod)

# plot the points (actual observations), regression line, and confidence interval
preds <- cbind(res1, predict(mod, type = "response", se.fit = TRUE)) %>%
  mutate(upr = fit + 2 * se.fit, lwr = fit - 2 * se.fit)

ggplot(preds, aes(y = hiv.test.rate_1, x = cc.dx.B)) +
  geom_point() +
  geom_line(aes(y = fit), col = "red") +
  geom_ribbon(aes(ymin=lwr,ymax=upr), alpha=0.3, col = "blue")

pp <- predict(mod, data.frame(cc.dx.B = 0.804), se = TRUE, type = "response")
pp$fit - 2 * pp$se.fit
pp$fit + 2 * pp$se.fit

pp <- predict(
  mod,
  data.frame(cc.dx.B = 0.804),
  se = TRUE,
  type = "response",
  dispersion = TRUE
)

oom <- function(x) {
  10^floor(log10(x))
}

# test
simulator <- function(x)  x - 2 * x^2

target <- -0.3
x0 <- seq(0.1, 1, length.out = 1000)
y0 <- simulator(x0)

plot(y0 ~ x0)

mod <- lm(x0 ~ poly(y0, 3))
preds <- predict(mod, type = "response")
plot(y0, preds)

pp <- predict(mod, data.frame(y0 = target), se = TRUE, type = "response")
x1 <- seq(pp$fit - oom(pp$fit), pp$fit + oom(pp$fit), length.out = 1000)
x = c(x0, x1)

y = simulator(x)
plot(y ~ x)
mod <- lm(x ~ poly(y, 3))

preds <- predict(mod, type = "response")
plot(y, preds)

pp <- predict(mod, data.frame(y = target), se = TRUE, type = "response")

make_poly_proposer <- function(n_new, poly_n = 4) {
  force(n_new)
  force(poly_n)
  function(job, results) {
    values <- results[[job$targets]]
    target <- job$targets_val
    param <- results[[job$params]]

    tar_range <- range(
      results[[job$params]][
        results[[".iteration"]] == max(results[[".iteration"]])])

    spread <- (tar_range[2] - tar_range[1]) / 4

    mod <- lm(param ~ poly(values, poly_n))
    pp <- predict(mod, data.frame(values = target), target = "response", se = T)
    proposals <- seq(pp$fit - spread, pp$fit + spread, length.out = n_new)
    out <- list(proposals)
    names(out) <- job$params
    dplyr::as_tibble(out)
  }
}
