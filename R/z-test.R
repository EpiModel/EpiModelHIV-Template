n <- 1e4
x1 <- rnorm(n)
x2 <- rnorm(n)
x3 <- rnorm(n)
y1 <- 2*x1 + 0.2*x2 + 0.3 * x3 + rnorm(n, 0, 0.5)
y2 <- 0.2*x1 + 2*x2 + 0.3 * x3 + rnorm(n, 0, 0.5)
y3 <- 0.2*x1 + 0.2*x2 + 3 * x3 + rnorm(n, 0, 0.5)
results <- data.frame(x1, x2, x3, y1, y2, y3)

mscale <- function(x, val) (x - mean(val)) / sd(val)
munscale <- function(x, val) x * sd(val) + mean(val)

poly_n <- 3
job <- list()
job$targets <- c("y1", "y2", "y3")
job$params <- c("x1", "x2", "x3")
targets <- c(0.3, -1, 0.2)

complete_rows <- vctrs::vec_detect_complete(values)
values <- values[complete_rows, ]
params <- params[complete_rows, ]

s_v <- purrr::map_dfc(values, ~ mscale(.x, .x))
s_p <- purrr::map_dfc(params, ~ mscale(.x, .x))
s_t <- purrr::map2_dbl(targets, values, mscale)
s_data <- dplyr::bind_cols(s_p, s_v)

sfmla <- paste0(
  "cbind(",
  paste0(job$targets, collapse = ", "),
  ") ~ ",
  paste0(
    paste0("poly(", job$params, ", ", poly_n, ")"),
    collapse = " + "
  )
)

fmla <- as.formula(sfmla)
mod <- lm(fmla, data = s_data)

loss_fun <- function(par, t) {
  dat <- as.data.frame(as.list(par))
  names(dat) <- job$params
  out <- predict(mod, dat)
  sum((out - t)^2)
}

initial <- rep(0, ncol(params))
s_newp <- optim(initial, loss_fun, t = s_t)$par

dat <- as.data.frame(as.list(s_newp))
names(dat) <- job$params
s_newv <- predict(mod, dat)

newp <- purrr::map2_dbl(s_newp, params, munscale)

oldp <- swfcalib::load_sideload(calib_object, job)
swfcalib::save_sideload(calib_object, job, newp)

if (is.null(oldp)) return(NULL)

s_oldp <- purrr::map2_dbl(oldp, params, mscale)
dat <- as.data.frame(as.list(s_oldp))
names(dat) <- job$params
s_oldv <- predict(mod, dat)

newv <- purrr::map2_dbl(s_newv, values, munscale)
oldv <- purrr::map2_dbl(s_oldv, values, munscale)

if (all(abs(oldv - newv) < thresholds) &&
  all(abs(newv - target) < thresholds)) {
  result <- data.frame(as.list(newp))
  names(result) <- job$params
  return(result)
} else {
  return(NULL)
}
