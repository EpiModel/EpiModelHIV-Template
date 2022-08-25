# This code install the main/master branch version of EpiModelHIV and the
# CRAN version of all the dependencies
renv::install(c(
  paste0("statnet/", c(
    "statnet.common",
    "ergm",
    "tergm",
    "network",
    "networkDynamic"
  )),
  paste0("EpiModel/", c(
    "ARTnetData",
    "ARTnet",
    "EpiModel",
    "EpiModelHIV-p"
  ))
))

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate()

# Specific other packages

