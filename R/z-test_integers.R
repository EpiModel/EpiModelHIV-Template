n <- 1e6L
xf <- runif(n)
xi <- sample(n)

n_sub <- 1e2L
sub_i <- sample(n, n_sub)
sub_f <- as.numeric(sub_i)
sub_si <- sort(sub_i) # necessary so `sub_l` gives same result
sub_sf <- as.numeric(sub_si)
sub_l <- logical(n)
sub_l[sub_si] <- TRUE

# subset -----------------------------------------------------------------------
# --> subsetting with integer is the fastest
microbenchmark::microbenchmark(
  int = xf[sub_i],
  float = xf[sub_f],
  log = xf[sub_l],
  wic = xf[which(sub_l)]
)

bench::mark(
  int = xf[sub_si],
  float = xf[sub_sf],
  log = xf[sub_l]
)

xf[sub_i]
xf[sub_l]

sub_l |> sum()

# compare flags ----------------------------------------------------------------
# --> comparing to 1L is faster than to 1
# --> even faster if already logical (no comparison needed)
x_grp <- sample(0:1, n, TRUE)
x_flo <- as.numeric(x_grp)
x_lgl <- as.logical(x_grp)

which(x_lgl)
which(as.logical(x_grp))

microbenchmark::microbenchmark(
  int = which(x_grp == 1L),
  lint = which(as.logical(x_grp)),
  float = which(x_grp == 1),
  log = which(x_lgl),
  logdumb = which(x_lgl == TRUE),
  fint = which(x_flo == 1L),
  ffloat = which(x_flo == 1)
)

bench::mark(
  int = which(x_grp == 1L),
  float = which(x_grp == 1),
  log = which(x_lgl),
  logdumb = which(x_lgl == TRUE)
)

# compare categ ----------------------------------------------------------------
x_grp <- sample(1:4, n, TRUE)
x_flo <- as.numeric(x_grp)
x_fact <- factor(c("black", "hispanic", "white")[x_grp])

microbenchmark::microbenchmark(times = 500L,
  int = which(x_grp == 2L),
  float = which(x_grp == 2),
  fact = which(x_fact == "hispanic"),
  fint = which(x_flo == 2L),
  ffloat = which(x_flo == 2)
)

bench::mark(iterations = 200L,
  int = which(x_grp == 2L),
  float = which(x_grp == 2),
  fact = which(x_fact == "hispanic")
)

# --> x %in% c(1L, 3L, 4L) slower than  x != 2L
microbenchmark::microbenchmark(times = 500L,
  which(x_grp %in% c(1L, 3L, 4L)),
  which(x_grp != 2L)
)

# --> x %in% c(2L, 3L) slower than  x == 2L | x == 3L
microbenchmark::microbenchmark(times = 500L,
  which(x_grp %in% c(2L, 3L)),
  which(x_grp == 2L | x_grp == 3L),
  which(x_grp != 1L & x_grp != 4L),
  which(x_grp > 1L & x_grp < 4L)
)

# big factors ------------------------------------------------------------------
# --> comparison of factor is faster than on integer
n <- 1e6L
c_levels <- paste0(
  sample(letters, 1000, TRUE),
  sample(letters, 1000, TRUE),
  sample(letters, 1000, TRUE)
) |> unique()
xf <- as.factor(sample(c_levels, n, TRUE))
xi <- as.integer(xf)
lvl_low <- levels(xf)[10]
lvl_high <- levels(xf)[700]

all(which(xi == 10) == which(xf == lvl_low))

microbenchmark::microbenchmark(times = 500L,
  which(xi == 10),
  which(xf == lvl_low),
  which(xf == 10),
  which(xf == "afu"),
  which(xi == 700),
  which(xf == lvl_high),
  which(xf == 700),
  which(xf == "sqr")
)

# more factors -----------------------------------------------------------------
hiv.levels <- c("no", "acute rising", "acute falling", "chronic", "AIDS")
hiv.stage <- ordered(
  sample(hiv.levels, n, TRUE, prob = c(10, 2, 3, 4, 1)),
  levels = hiv.levels
)

head(hiv.stage)
head(hiv.stage > "acute falling")

microbenchmark::microbenchmark(times = 500L,
  which(hiv.stage > "acute falling"),
  which(hiv.stage %in% c("chronic", "AIDS"))
)

microbenchmark::microbenchmark(times = 500L,
  which(hiv.stage > "acute falling"),
  which(hiv.stage > "no" & hiv.stage < "chronic"),
  which(hiv.stage == "acute rising" | hiv.stage == "acute falling"),
  which(hiv.stage %in% c("acute rising", "acute falling"))
)

bench::mark(iterations = 200L,
  which(hiv.stage > "no" & hiv.stage < "chronic"),
  which(hiv.stage == "acute rising" | hiv.stage == "acute falling"),
  which(hiv.stage %in% c("acute rising", "acute falling"))
)

bench::mark(iterations = 200L,
  which(hiv.stage > "acute falling"),
  which(hiv.stage == "chronic" | hiv.stage == "AIDS"),
  which(hiv.stage %in% c("chronic", "AIDS"))
)

a = ordered("no", levels = hiv.levels)
b = ordered(sample(hiv.levels, 10, TRUE), levels = hiv.levels)
c(a, b)


# Bitwise stuff ----------------------------------------------------------------
# hiv.inf, gono.inf, syph.inf
# 0, 0, 0

x <- sample(0:7, 1e5, TRUE)
h <- bitwAnd(x, strtoi("001", base = 2)) == strtoi("001", base = 2)
g <- bitwAnd(x, strtoi("010", base = 2)) == strtoi("010", base = 2)
s <- bitwAnd(x, strtoi("100", base = 2)) == strtoi("100", base = 2)

# coinf hiv - syph
strtoi("101", base = 2)

microbenchmark::microbenchmark(
  bit = bitwAnd(x, strtoi("101", base = 2)) == strtoi("101", base = 2),
  bit_lit = bitwAnd(x, 5L) == 5L,
  lgl = h & s
)

bench::mark(iterations = 200L,
  bit = bitwAnd(x, strtoi("101", base = 2)) == strtoi("101", base = 2),
  bit_lit = bitwAnd(x, 5L) == 5L,
  lgl = h & s
)

bench::mark(iterations = 200L,
  bit = which(bitwAnd(x, strtoi("111", base = 2)) == strtoi("111", base = 2)),
  bit_lit = which(bitwAnd(x, 7L) == 7L),
  lgl = which(h & s & g),
  subs = {
    ids = which(h)
    ids = ids[g[ids]]
    ids = ids[s[ids]]
    ids
  }
)

strtoi("1101", base = 2)
bitwAnd(5, 15) |> as.bi

library(collapse)
n <- 1e6
x <- sample(1:4, n, TRUE)

microbenchmark::microbenchmark(
  base = x[x == 1L | x == 3L],
  fwhich = fsubset(x, x %iin% c(1L, 3L))
)

library(inline)

fast_which_inline <- cfunction(
  sig = c(x = "integer", xv = "integer",
          y = "integer", yv = "integer",
          z = "integer", zv = "integer"
          ),
  body = '
    int *px = INTEGER(x), *py = INTEGER(y), *pz = INTEGER(z);
    int target_x = INTEGER(xv)[0], target_y = INTEGER(yv)[0], target_z = INTEGER(zv)[0];
    int n = LENGTH(x);
    SEXP res = PROTECT(Rf_allocVector(INTSXP, n));
    int count = 0;
    for(int i = 0; i < n; i++) {
        if(px[i] == target_x && py[i] == target_y && pz[i] == target_z) {
            INTEGER(res)[count++] = i + 1;
        }
    }
    SEXP final_res = PROTECT(Rf_allocVector(INTSXP, count));
    memcpy(INTEGER(final_res), INTEGER(res), count * sizeof(int));
    UNPROTECT(2);
    return final_res;
', cxxargs = c("-O3", "-march=native", "-ffast-math")
)


n <- 1e6
x <- sample(1:4, n, TRUE)
y <- sample(1:4, n, TRUE)
z <- sample(1:4, n, TRUE)

microbenchmark::microbenchmark(
  base = which(x == 1L & y == 3L & z == 2L),
  subs = {
    ids <- which(x == 1L)
    ids <- ids[y[ids] == 3L]
    ids <- ids[z[ids] == 2L]
    ids
  },
  inl = fast_which_inline(x, 1L, y, 3L, z, zv = 2L)
)

bench::mark(
  base = which(x == 1L & y == 3L & z == 2L),
  subs = {
    ids <- which(x == 1L)
    ids <- ids[y[ids] == 3L]
    ids <- ids[z[ids] == 2L]
    ids
  },
  inl = fast_which_inline(x, 1L, y, 3L, z, zv = 2L)
)