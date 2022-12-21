library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("./data/calib/waves/1/results.rds")

glimpse(res)

res1 <- res %>%
  mutate(
    gc = abs(ir100.gc - 12.81),
    ct = abs(ir100.ct - 14.59)
  )

res1$gc %>% summary()
res1$ct %>% summary()

n <- 100
nbest <- res1 %>%
  head(n)

nbest <- res1 %>%
  filter(gc < 1)

nrow(nbest)

ggplot(res1, aes(y = ir100.gc, x = ugc.prob)) +
  geom_point() +
  geom_hline(yintercept = 12.81)

res %>%
  group_by(.iteration) %>%
  summarise(across(ugc.prob, list(min, median, max)))


res1 <- res %>%
  mutate(
    gc = abs(ir100.gc - 12.81),
    ct = abs(ir100.ct - 14.59)
  ) %>%
  filter(gc < 0.5)

nrow(res1)
res1$ugc.prob %>% summary()

ggplot(res1, aes(x = ir100.gc)) +
  geom_density() +
  geom_vline(xintercept = 12.81)

plogis(qlogis(0.17) + log(1.25))
plogis(qlogis(0.19) + log(1.25))
