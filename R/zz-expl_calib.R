library(dplyr)
library(ggplot2)
theme_set(theme_light())

calib_object <- readRDS("./data/calib/calib_object.rds")
as.list(calib_object$state$default_proposal)

res <- readRDS("./data/calib/full_results.rds") |> as_tibble()

glimpse(res)

res <- res %>%
  select(
    starts_with("hiv.trans"),
    starts_with("."),
    starts_with("i.prev")
  ) %>%
  filter(.wave == 3)

glimpse(res)

ggplot(res, aes(x = hiv.trans.scale_1, y = i.prev.dx.B)) +
  geom_line() +
  geom_hline(yintercept = 0.33)
