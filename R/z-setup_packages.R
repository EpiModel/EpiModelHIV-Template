# This code install the main/master branch version of EpiModelHIV and the
# CRAN version of all the dependencies
renv::install(c(
  # ARTnet
  "EpiModel/ARTnetData",
  "EpiModel/ARTnet",
  # EpiModel
  "EpiModel/EpiModel",
  "EpiModel/EpiModelHIV-p",
  # HPC related packages
  "EpiModel/EpiModelHPC",
  "EpiModel/slurmworkflow"
  # Others
  # "Rglpk",
  # "rmarkdown",
  # "pkgload",
  # "sessioninfo"
))

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate()

if (FALSE) {
  library("rmarkdown")
  library("pkgload")
  library("Rglpk")
  library("sessioninfo")
}


