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

.folder.struct <- c(
  "data/input",
  "data/intermediate/estimates",
  "data/intermediate/diagnostics",
  "data/intermediate/calibration",
  "data/output"
)

for (.folder in .folder.struct) {
  if (!dir.exists(.folder)) dir.create(.folder, recursive = TRUE)
}

rm(.folder.struct, .folder)

