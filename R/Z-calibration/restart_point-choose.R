##
# Files in calib_dir ? (or specific one)

# calc the distance

# get best sim

# make and save the restart point
for (nme in names(targets)) {
  if (nme %in% names(d)) {
    d[[nme]] <- d[[nme]] - targets[[nme]]
  }
}

# Calculate RMSE
mat_d <- as.matrix(select(d, - c(batch_number, sim, scenario_name)))

d$scores <- apply(mat_d, 1, function(x) {
  sum(x^2, na.rm = TRUE)
})

# pick best sim
best_sim <- d %>%
  arrange(scores) %>%
  select(batch_number, sim) %>%
  head(1)

# Check the values manually
d %>%
  arrange(scores) %>%
  head(1) %>%
  as.list()

# Get best sim
best <- readRDS(fs::path(
  "data/intermediate/calibration",
  paste0("sim__empty_scenario__", best_sim$batch_number, ".rds"))
)

best <- EpiModel::get_sims(best, best_sim$sim)
epi_num <- best$epi$num

# Remove all epi except `num`
best$epi <- list(num = epi_num)

saveRDS(best, path_to_restart)
