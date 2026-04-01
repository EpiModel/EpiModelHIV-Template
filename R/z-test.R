r2i_mean <- function(r) 1 / r
i2r_mean <- function(i) 1 / i
# quantile - prob (p) that event occurs after interval (i)
i2r_p <- function(i, p) 1 - (1 - p)^(1 / i)
r2i_p <- function(r, p) log(1 - p, base = 1 - r)

r2i_p(default_proposal$prep.start.rate_1, 0.5) / 52
i2r_p(year_steps * c(0.25, 4), 0.5)
i2r_p(year_steps * 4, 0.5)

r2i_mean(r)


