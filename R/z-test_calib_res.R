library(dplyr)
library(ggplot2)
theme_set(theme_light())

# res <- readRDS("./data/results.rds") |> as_tibble()
res <- readRDS("./data/calib/full_results.rds") |> as_tibble()
calib_object <- readRDS("./data/calib-old/calib_object.rds")
calib_object <- readRDS("./data/calib/calib_object.rds")

calib_object$state$default_proposal %>% as.list()

res %>%
  group_by(.wave) %>%
  summarise(it = max(.iteration))

res1 <- filter(
  res,
  between(.iteration, 1, 5),
  .wave == 1
)
grp <- as.factor(rep(1:3, each = nrow(res1)))

values <- unlist(res1[paste0("cc.dx.", c("B", "H", "W"))])
params <- unlist(res1[paste0("hiv.test.rate_", 1:3)])
target <- c(0.847, 0.818, 0.873)[1]

nrg <- 1
values <- unlist(res1[paste0("cc.dx.", c("B", "H", "W")[nrg])])
params <- unlist(res1[paste0("hiv.test.rate_", nrg)])
target <- c(0.847, 0.818, 0.873)[nrg]

values <- unlist(res1[paste0("cc.linked1m.", c("B", "H", "W"))])
params <- unlist(res1[paste0("tx.init.rate_", 1:3)])
target <- c(0.829, 0.898, 89)[1]

values <- unlist(res1[paste0("cc.vsupp.", c("B", "H", "W"))])
params <- unlist(res1[paste0("tx.halt.partial.rate_", 1:3)])
target <- c(0.605, 0.62, 0.71)[1]

values <- res1[["i.prev.dx.B"]]
params <- res1[["hiv.trans.scale_1"]]
target <- c(0.605, 0.62, 0.71)[1]

s_v <- (values - mean(values)) / sd(values)
s_p <- (params - mean(params)) / sd(params)
s_t <- (target - mean(values)) / sd(values)

mod2 <- lm(s_v ~ poly(s_p, 3))
preds2 <- as_tibble(predict(mod2, type = "response", se.fit = TRUE))
mod3 <- lm(s_v ~ poly(s_p, 5))
preds3 <- as_tibble(predict(mod3, type = "response", se.fit = TRUE))
mod4 <- mgcv::gam(s_v ~ s(s_p, bs = "cs"))
preds4 <- as_tibble(predict(mod4, type = "response", se.fit = TRUE))

ggplot(data.frame(s_v, s_p, grp), aes(x = s_p, y = s_v, col = grp)) +
  geom_point(alpha = 0.6) +
  geom_line(data = preds2, aes(y = fit), col = "red") +
  geom_line(data = preds3, aes(y = fit), col = "blue") +
  geom_line(data = preds4, aes(y = fit), col = "green") +
  # scale_x_continuous(limits = c(-0.2, 0.2)) +
  geom_hline(yintercept = s_t)

ggplot(data.frame(values, params), aes(x = params, y = values)) +
  geom_point(alpha = 0.6) +
  # scale_x_continuous(limits = c(-0.2, 0.2)) +
  geom_hline(yintercept = 0.847) +
  geom_hline(yintercept = 0.818) +
  geom_hline(yintercept = 0.873) +
  geom_vline(xintercept = 0.004767) +
  geom_vline(xintercept = 0.003639) +
  geom_vline(xintercept = 0.005979)


opti_f <- function(mod) {
  function(par, target) {
    abs(predict(mod, data.frame(s_p = par)) - target)
  }
}

(oo <- optimize(range(s_p), f = opti_f(mod2), target = s_t)$minimum)
oo * sd(params) + mean(params)

(oo <- optimize(range(s_p), f = opti_f(mod3), target = s_t)$minimum)
oo * sd(params) + mean(params)

(oo <- optimize(c(-2, 2), f = opti_f(mod4), target = s_t)$minimum)
oo * sd(params) + mean(params)

pp <- predict(mod2, data.frame(s_p = oo))

old_pp =  predict(mod2, data.frame(s_p = (old_oo - mean(params)) / sd(params)))
old_oo = oo * sd(params) + mean(params)
old_oo

pp4 * sd(values) + mean(values)
old_pp * sd(values) + mean(values)

# trans_scale ------------------------------------------------------------------
res1 <- filter(
  res,
  between(.iteration, 1, 5),
  .wave == 1
)
v1 <- res1[["i.prev.dx.B"]]
v2 <- res1[["i.prev.dx.H"]]
v3 <- res1[["i.prev.dx.W"]]
p1 <- res1[["hiv.trans.scale_1"]]
p2 <- res1[["hiv.trans.scale_2"]]
p3 <- res1[["hiv.trans.scale_3"]]
target <- c(0.605, 0.62, 0.71)[1]

s_v1 <- (v1 - mean(v1)) / sd(v1)
s_v2 <- (v2 - mean(v2)) / sd(v2)
s_v3 <- (v3 - mean(v3)) / sd(v3)
s_p1 <- (p1 - mean(p1)) / sd(p1)
s_p2 <- (p2 - mean(p2)) / sd(p2)
s_p3 <- (p3 - mean(p3)) / sd(p3)
s_t1 <- (target - mean(v1)) / sd(v1)
s_t2 <- (target - mean(v2)) / sd(v2)
s_t3 <- (target - mean(v3)) / sd(v3)

mod2 <- lm(s_v1 ~ poly(s_p1, 2) + poly(s_p2, 2) + poly(s_p3, 2))
preds2 <- as_tibble(predict(mod2, type = "response", se.fit = TRUE))
mod3 <- lm(s_v ~ poly(s_p, 5))
preds3 <- as_tibble(predict(mod3, type = "response", se.fit = TRUE))
mod4 <- mgcv::gam(s_v ~ s(s_p, bs = "cs"))
preds4 <- as_tibble(predict(mod4, type = "response", se.fit = TRUE))

ggplot(data.frame(s_v, s_p), aes(x = s_p, y = s_v)) +
  geom_point(alpha = 0.6) +
  geom_line(data = preds2, aes(y = fit), col = "red") +
  # geom_line(data = preds3, aes(y = fit), col = "blue") +
  # geom_line(data = preds4, aes(y = fit), col = "green") +
  scale_x_continuous(limits = c(-0.2, 0.2)) +
  geom_hline(yintercept = s_t1)

res2 <- filter(
  res,
  .wave == 2,
  between(hiv.test.rate_1, 0.0038, 0.0039)
)

summary(res2$cc.dx.B)
res2 <- filter(
  res,
  between(.iteration, 1, 1),
  .wave == 1
) %>%
  mutate(yes = floor(cc.dx.B * 1e5), no = floor((1 - cc.dx.B) * 1e5))

mod3 <- glm(
  cc.dx.B ~ poly(hiv.test.rate_1, 2),
  data = res2,
  family = "binomial",
  weights = rep(1e5, nrow(res2))
)
plot(mod3)
