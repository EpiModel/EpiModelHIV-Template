mscale <- function(x, rnge) (x - rnge[1]) / diff(rnge)
munscale <- function(x, rnge) x * diff(rnge) + rnge[1]
