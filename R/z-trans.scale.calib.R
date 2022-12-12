library(dplyr)
library(ggplot2)
theme_set(theme_light())

calib_object <- readRDS("./data/calib/calib_object.rds")
res <- readRDS("./data/calib/waves/3/results.rds") |> as_tibble() %>%
  select(starts_with(c("i.prev.dx", "hiv.trans.scale")))

res1 <- res %>%
  mutate(
    e.B = abs(i.prev.dx.B - 0.333),
    e.H = abs(i.prev.dx.H - 0.127),
    e.W = abs(i.prev.dx.W - 0.084),
    score = e.B + e.H + e.W
  ) %>%
  arrange(score) %>%
  select(score, starts_with("e."), starts_with("hiv."), everything())

head(res1)

res1$e.B %>% summary()

summary(res)
