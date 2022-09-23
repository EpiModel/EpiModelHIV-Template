source("renv/activate.R")

# Make sure the folder structure exists
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
