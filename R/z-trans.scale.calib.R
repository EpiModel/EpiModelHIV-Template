library(dplyr)
library(ggplot2)
theme_set(theme_light())

res <- readRDS("./data/calib/waves/3/results.rds")

glimpse(res)

res %>%
  group_by(.iteration) %>%
  summarise(
    across(starts_with("hiv.trans."),
      list(min, median, max))
  ) %>%
  print(n = 100)

res1 <- res %>%
  mutate(
    e.B = i.prev.dx.B - 0.333,
    e.H = i.prev.dx.H - 0.127,
    e.W = i.prev.dx.W - 0.084,
    e.tot = i.prev.dx - 0.17,
    # score = e.B^2 + e.H^2 + e.W^2
    score = abs(e.B) + abs(e.H) + abs(e.W)
  ) %>%
  arrange(score) %>%
  select(score, starts_with("e."), starts_with("hiv.trans"), everything())

head(res1)

res1$e.B %>% summary()

summary(res)

n <- 100
nbest <- res1 %>%
  head(n)

nbest <- res1 %>%
  filter(
    between(e.B, -0.01, 0.01),
    between(e.H, -0.01, 0.01),
    between(e.W, -0.01, 0.01)
  )

nrow(nbest)
select(nbest, starts_with("hiv.trans"))

range(nbest$hiv.trans.scale_1)
range(nbest$hiv.trans.scale_2)
range(nbest$hiv.trans.scale_3)

mean(nbest$hiv.trans.scale_1)
mean(nbest$hiv.trans.scale_2)
mean(nbest$hiv.trans.scale_3)

mod <- lm(
  i.prev.dx.B ~
    poly(hiv.trans.scale_1, 2) +
    poly(hiv.trans.scale_2, 1) +
    poly(hiv.trans.scale_3, 1),
  data = res1
)

summary(mod)
plot(mod)

ggplot(res1, aes(x = hiv.trans.scale_1, y = i.prev.dx.B)) +
  geom_point()

ggplot(res1, aes(x = hiv.trans.scale_2, y = i.prev.dx.H)) +
  geom_point()

ggplot(res1, aes(x = hiv.trans.scale_3, y = i.prev.dx.W)) +
  geom_point()

res1 %>%
  arrange(abs(e.W)) %>%
  head(60) %>%
  select(starts_with("hiv.trans")) %>%
  summarize(across(everything(), .fns = list(
    min = ~min(.x),
    max = ~max(.x)
))) %>%
  as.list()

res1 %>%
  filter(between(e.B, -0.05, 0.05)) %>%
  select(starts_with("hiv.trans")) %>%
  summarize(across(everything(), .fns = list(
    min = ~min(.x),
    max = ~max(.x)
))) %>%
  as.list()

res1 %>%
  filter(between(e.H, -0.05, 0.05)) %>%
  select(starts_with("hiv.trans")) %>%
  summarize(across(everything(), .fns = list(
    min = ~min(.x),
    max = ~max(.x)
))) %>%
  as.list()

res1 %>%
  filter(between(e.W, -0.05, 0.05)) %>%
  select(starts_with("hiv.trans")) %>%
  summarize(across(everything(), .fns = list(
    min = ~min(.x),
    max = ~max(.x)
))) %>%
  as.list()

# work on the function
#determ_trans_end <- function(retain_prop = 0.2, thresholds, n_enough) {

results = res

job = list()
thresholds = c(0.02, 0.02, 0.02)
n_enough = 100
retain_prop = 0.2

job$targets = paste0("i.prev.dx.", c("B", "H", "W"))
job$params = paste0("hiv.trans.scale_", 1:3)
job$targets_val = c(0.333, 0.127, 0.084)

values <- results[, job$targets]
targets <- job$targets_val
params <- results[, job$params]
scores <- values
for (j in seq_along(targets)) {
  scores[[j]] <- abs(score[[j]] - targets[[j]])
}

d <- bind_cols(params, scores)
for (j in seq_along(targets)) {
  d <- d[d[ job$targets[[j]] ] < thresholds[[j]], ]
}

p_ok <- results[, c(job$params, job$targets)]
for (j in seq_along(targets)) {
  vals <- p_ok[[ job$targets[j] ]]
  t_val <- job$targets_val[j]
  ok <- abs(vals - t_val) < thresholds[j]
  p_ok <- p_ok[ok, ]
}
p_ok

if (nrow(p_ok) > n_enough) {
  return(p_ok[, job$params])
} else {
  return(NULL)
}




# TODO:
# if nrow(d) > n_enough
# -> return mean of all


d %>% filter()

head(values)
head(scores)


