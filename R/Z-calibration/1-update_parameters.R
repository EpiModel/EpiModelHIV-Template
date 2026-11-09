calibrated_params <- read.csv("calibrated.csv")
current_params <- read.csv("data/input/model_parameters.csv")
for (i in seq_len(nrow(calibrated_params))) {
  p <- calibrated_params$param[[i]]
  v <- calibrated_params$value[[i]]
  loc <- which(current_params$param == p)
  current_params$value[[loc]] <- v
}
write.csv(current_params, "data/input/model_parameters.csv", row.names = FALSE)
