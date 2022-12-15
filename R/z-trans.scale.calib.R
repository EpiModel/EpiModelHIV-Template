library(dplyr)
library(ggplot2)
theme_set(theme_light())

calib_dir <- "./data/calib_sph"
calib_dir <- "./data/calib_mox"

calib_object <- readRDS(fs::path(calib_dir, "/calib_object.rds"))
res <- readRDS(fs::path(calib_dir, "/waves/3/results.rds")) |> as_tibble() %>%
  select(starts_with(c("i.prev.dx", "hiv.trans.scale")))

res1 <- res %>%
  mutate(
    e.B = (i.prev.dx.B - 0.333)^2,
    e.H = (i.prev.dx.H - 0.127)^2,
    e.W = (i.prev.dx.W - 0.084)^2,
    score = e.B + e.H + e.W
  ) %>%
  arrange(score) %>%
  select(score, starts_with("e."), starts_with("hiv."), everything())

head(res1)

res1$e.B %>% summary()

summary(res)
