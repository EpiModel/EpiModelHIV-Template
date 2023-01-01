library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("./data/calib/waves/1/results.rds")
calib_object <- readRDS("./data/calib/calib_object.rds")
calib_object$state$default_proposal |> as.list()

glimpse(res)

res %>%
  group_by(.iteration) %>%
  summarise(across(starts_with("ir100."), list(min, median, max)))

res %>%
  group_by(.iteration) %>%
  summarise(across(c(rgc.prob, rct.prob), list(min, median, max)))

res1 <- res %>%
  mutate(
    gc = abs(ir100.gc - 12.81),
    ct = abs(ir100.ct - 14.59)
  )

res1$gc %>% summary()
res1$ct %>% summary()


ggplot(res, aes(y = ir100.gc, x = ugc.prob)) +
  geom_point() +
  geom_hline(yintercept = 12.81) +
  scale_y_continuous(limits = c(11.8, 13.8))
