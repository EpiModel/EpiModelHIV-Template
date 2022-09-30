# This code install the main/master branch version of EpiModelHIV and the
# CRAN version of all the dependencies
renv::install(c(
  # statnet packages
  "statnet/statnet.common",
  "statnet/ergm",
  "statnet/tergm",
  "statnet/network",
  "statnet/networkDynamic",
  # ARTnet
  "EpiModel/ARTnetData",
  "EpiModel/ARTnet",
  # EpiModel
  "EpiModel/EpiModel",
  "EpiModel/EpiModelHIV-p",
  # HPC related packages
  "EpiModel/EpiModelHPC",
  "EpiModel/slurmworkflow",
  # CRAN
  "rmarkdown",
  "pkgload",
  "sessioninfo"
))

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate()

# Specific other packages
