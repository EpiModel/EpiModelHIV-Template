## Gather the results of one wave iteration into the swfcalib `full_results`
## format, then delete the intermediates.
##
## Run by the last step of `workflow-wave.R` (`step_tmpl_do_call_script`) with:
## - `design`: the design table of the wave iteration (all designs bound)
## - `step_info`: one row per (carry variant, design), with `carry`, `design`,
##   `n_cores`, `seed_base` (no `carry`: a single "root" variant)
## - `df_dir`, `sim_dir`: the intermediates
## - `truing_dir`: the campaign directory
## - `year_steps`
## It can also be sourced locally with these objects defined.

library(dplyr)
library(EpiModelHIV)

targets <- EpiModelHIV::get_calibration_targets()
out_cols <- c("num", "num.active.sex", names(targets))

df_files <- fs::dir_ls(df_dir, regexp = "/df__.*\\.rds$")
if (length(df_files) == 0) stop("No merged results in `", df_dir, "`")

# The mean over the last year of every simulation, as `swfcalib_model.R`
res <- lapply(df_files, function(f) {
  sc <- sub("^df__(.*)\\.rds$", "\\1", fs::path_file(f))
  readRDS(f) |>
    mutate_calibration_targets(year_steps = year_steps) |>
    filter(time >= max(time) - year_steps) |>
    group_by(batch_number, sim_number, sim) |>
    summarise(
      across(any_of(out_cols), \(x) mean(x, na.rm = TRUE)),
      .groups = "drop"
    ) |>
    mutate(.scenario = sc)
}) |>
  bind_rows()

# Workflows built before the carry variants
if (!".carry" %in% names(design)) {
  design <- mutate(design, .carry = "root", .carry_factor = 1)
}
if (!"carry" %in% names(step_info)) step_info$carry <- "root"

# The seed each batch ran with (array element `k` of its design)
seeds <- design |>
  select(".scenario.id", ".carry", ".design", ".point", ".n_rep") |>
  left_join(step_info, by = c(.carry = "carry", .design = "design")) |>
  mutate(n_batch = ceiling(.data$.n_rep / .data$n_cores))

res <- res |>
  inner_join(seeds, by = c(.scenario = ".scenario.id")) |>
  mutate(.seed = .data$seed_base + (.data$.point - 1) * .data$n_batch +
           .data$batch_number) |>
  select(-c("n_batch", "n_cores", "seed_base", ".n_rep", "sim_number",
            "batch_number", ".carry"))

# swfcalib `full_results` layout: parameters, bookkeeping, outputs
full <- design |>
  select(-c(".at", ".n_rep")) |>
  inner_join(res, by = c(.scenario.id = ".scenario", ".design", ".point")) |>
  rename(.scenario = ".scenario.id") |>
  arrange(.data$.carry_factor != 1, .data$.carry_factor, .data$.design,
          .data$.point, .data$sim) |>
  mutate(
    .campaign = fs::path_file(truing_dir),
    .proposal_index = row_number()
  ) |>
  select(
    all_of(truing_params),
    ".proposal_index", ".wave", ".iteration", "sim",
    any_of(out_cols),
    ".campaign", ".carry", ".carry_factor", ".design", ".point", ".scenario",
    ".seed"
  )

# Every simulation present?
expected <- sum(design$.n_rep)
complete <- nrow(full) == expected
if (!complete) {
  warning(
    "Wave ", unique(design$.wave), " iteration ", unique(design$.iteration),
    ": ", nrow(full), " simulations gathered for ", expected, " expected. ",
    "The intermediates are kept."
  )
}

# Write: this iteration, then the campaign's `full_results.rds`
res_dir <- fs::path(truing_dir, "results")
fs::dir_create(res_dir)
iter_file <- fs::path(
  res_dir,
  sprintf("w%d_i%d.rds", unique(design$.wave), unique(design$.iteration))
)
saveRDS(full, iter_file)

full_results <- fs::dir_ls(res_dir, regexp = "/w[0-9]+_i[0-9]+\\.rds$") |>
  lapply(readRDS) |>
  bind_rows() # by name: the column order may differ
saveRDS(full_results, fs::path(truing_dir, "full_results.rds"))
saveRDS(design, fs::path(res_dir, sub("\\.rds$", "_design.rds",
                                      fs::path_file(iter_file))))

message(
  "Gathered ", nrow(full), " simulations into \"", iter_file, "\"; ",
  "`full_results.rds` now holds ", nrow(full_results), " rows."
)

# Clean up the intermediates, only when everything was gathered
if (complete) {
  fs::dir_delete(df_dir)
  fs::dir_delete(sim_dir)
  message("Deleted the intermediates in \"", df_dir, "\" and \"", sim_dir, "\"")
}
