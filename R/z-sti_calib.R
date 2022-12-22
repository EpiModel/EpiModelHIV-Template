library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("./data/calib/waves/1/results.rds")
res <- readRDS("./results.rds")

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

job <- list()
job$params <- c("ugc.prob", "rgc.prob")

nbest <- res1 %>%
  filter(.iteration < 8) %>%
  filter(gc < 1) %>%
  select(all_of(job$params))
nrow(nbest)

best <- nbest %>%
  summarise(across(everything(), ~ abs(.x - median(.x)))) %>%
  rowSums() %>% which.min()

nbest[best, ]

res <- nbest
# get the n_tuple where all values are the closest to the median
best <- dplyr::summarise(res, dplyr::across(
    dplyr::everything(),
    ~ abs(.x - median(.x)))
)
best <- which.min(rowSums(best))

glimpse(nbest)

summary(nbest$ugc.prob)




res1 %>%
  filter(between(ugc.prob, 0.188, 0.191)) %>%
  pull(ir100.gc) %>%
  summary()


ggplot(res1, aes(y = ir100.gc, x = ugc.prob)) +
  geom_point() +
  geom_hline(yintercept = 12.81)

res %>%
  group_by(.iteration) %>%
  summarise(across(c(ugc.prob, uct.prob), list(min, median, max)))

res %>%
  group_by(.iteration) %>%
  summarise(across(hiv.test.rate_2, list(min, median, max)))


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
