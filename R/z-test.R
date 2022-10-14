n <- 1000
x1 <- runif(n)
x2 <- runif(n)
x3 <- runif(n)
y <- x1 + x2 + x3 - x1*x2*x3 + rnorm(n)

m <- lm(y ~ poly(x1, 2) * poly(x2, 2) * poly(x2, 2))
summary(m)

loss <- function(par) {
  abs(predict(m, newdata = data.frame(x1 = par[1], x2 = par[2], x3 = par[3])))
}

optim(
  par = c(0.1, 0.1),
  fn = loss
)
