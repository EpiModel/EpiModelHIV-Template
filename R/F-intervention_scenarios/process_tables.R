process_one_scenario_tibble <- function(sc_info) {
    # loading the file
    d_sc <- readRDS(sc_info$file_path)
    d_sc <- mutate(d_sc, scenario_name = sc_info$scenario_name) |>
    select(scenario_name, batch_number, sim, time, everything())

    # global mutate
    d_sc <- d_sc |>
    mutate(
        prev = i.num / (i.num + s.num),
        incid.sti = incid.gc + incid.ct
    )

    # last year summaries
    d_sc_ly <- d_sc |>
    filter(time > max(time) - 52) |>
    group_by(scenario_name, batch_number, sim) |>
    summarise(
        across(
        c(prev, disease.mr100),
        ~ mean(.x, na.rm = TRUE),
        .names = "{.col}_ly"
        ),
        .groups = "drop" # ungroup the tibble after the summary
    )

    # cummulative summaries
    d_sc_cml <- d_sc |>
    filter(time > max(time) - 10 * 52) |>
    group_by(scenario_name, batch_number, sim) |>
    summarise(
        across(
        starts_with("incid."),
        ~ sum(.x, na.rm = TRUE),
        .names = "{.col}_cml"
        ),
        .groups = "drop" # ungroup the tibble after the summary
    )

    # joining
    d_cmb <- left_join(
        d_sc_ly, d_sc_cml,
        by = c("scenario_name", "batch_number", "sim")
    )

    return(d_cmb)
}

library("dplyr")
future::plan("multisession", workers = 4)

sc_dir <- fs::path(scenario_dir, "merged_tibbles")
sc_infos_tbl <- EpiModelHPC::get_scenarios_tibble_infos(sc_dir)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(sc_infos_tbl)),
  \(i) process_one_scenario_tibble(sc_infos_tbl[i, ])
)

d_sc_raw <- bind_rows(d_ls)
readr::write_csv(d_sc_raw, "sc_raw.csv")
