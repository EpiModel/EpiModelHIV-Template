library("dplyr")
library("EpiModel")

targets_plot_infos <- list(
  cc.dx = list(
    names = paste0("cc.dx.", c("B", "H", "W")),
    window_size = 13
  ),
  cc.linked1m = list(
    names = paste0("cc.linked1m.", c("B", "H", "W")),
    window_size = 13
  ),
  cc.vsupp = list(
    names = paste0("cc.vsupp.", c("B", "H", "W")),
    window_size = 13
  ),
  i.prev.dx = list(
    names = paste0("i.prev.dx.", c("B", "H", "W")),
    window_size = 13
  ),
  ir100.sti = list(
    names = c("ir100.gc", "ir100.ct"),
    window_size = 52
  ),
  cc.prep.ind = list(
    names = paste0("cc.prep.ind.", c("B", "H", "W")),
    window_size = 13
  ),
  cc.prep = list(
    names = paste0("cc.prep.", c("B", "H", "W")),
    window_size = 13
  ),
  disease.mr100 = list(
    names = "disease.mr100",
    window_size = 13
  )
)

process_one_calibration <- function(file_name, nsteps = 52) {
  # keep only the file name without extension and split around `__`
  name_elts <- fs::path_file(file_name) %>%
    fs::path_ext_remove() %>%
    strsplit(split = "__")

  scenario_name <- name_elts[[1]][2]
  batch_num <- as.numeric(name_elts[[1]][3])

  d <- as_tibble(readRDS(file_name))
  d <- d %>%
    filter(time >= max(time) - (nsteps + 52 * 3)) %>% # margin for prep_ret2y
    mutate_calibration_targets() %>%
    filter(time >= max(time) - nsteps) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    )) %>%
    mutate(
      scenario_name = scenario_name,
      batch = batch_num
    )

  return(d)
}
