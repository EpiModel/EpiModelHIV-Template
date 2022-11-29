n <- 1000
x1 <- runif(n)
x2 <- runif(n)
x3 <- runif(n)
coefs <- replicate(9, runif(1) * 10)
y1 <- plogis(x1 * coefs[1] + x2 * coefs[2] + x3 * coefs[3] + rnorm(n, sd = 3))
y2 <- plogis(x1 * coefs[4] + x2 * coefs[5] + x3 * coefs[6] + rnorm(n, sd = 3))
y3 <- plogis(x1 * coefs[7] + x2 * coefs[3] + x3 * coefs[9] + rnorm(n, sd = 3))
d <- data.frame(y1, y2, y3, x1, x2, x3)

mod <- glm(
  cbind(y1, y2, y3) ~ x1 + x2 + x3,
  weights = rep(100, n),
  family = "binomial"
)

mod
matrix(coefs, ncol = 3)
