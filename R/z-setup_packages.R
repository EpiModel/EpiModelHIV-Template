# This code install the main/master branch version of EpiModelHIV and the
# CRAN version of all the dependencies
renv::install(c(
  # statnet packages
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
  "statnet.common",
  "ergm",
  "tergm",
  "network",
  "networkDynamic",

  "rmarkdown",
  "pkgload",
  "sessioninfo"
))

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate()

# Specific other packages
