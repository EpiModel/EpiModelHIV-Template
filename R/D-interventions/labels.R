## Tables Labels and Format
##
## Maps outcome variable names (e.g., lst_ir100_b) to publication labels and
## defines number formatting.
##
## - var_labels: variable name -> display label
## - format_patterns: regex patterns -> number formatters
##   (first match wins; "default" catches the rest)
##
## This script should not be run directly. But `sourced` from other scripts in
## `R/D-interventions/`.

# Conversion between variable name and final label
var_labels <- c(
  # Epi
  "lst_ir100_B"  = "HIV IR100 Black (ly)",
  "lst_ir100_H"  = "HIV IR100 Hispanic (ly)",
  "lst_ir100_W"  = "HIV IR100 White (ly)",

  "cml_incid_B"  = "HIV Cumulative Incidence Black (10y)",
  "cml_incid_H"  = "HIV Cumulative Incidence Hispanic (10y)",
  "cml_incid_W"  = "HIV Cumulative Incidence White (10y)",

  "cml_nia_B"    = "HIV NIA Black (10y)",
  "cml_nia_H"    = "HIV NIA Hispanic (10y)",
  "cml_nia_W"    = "HIV NIA White (10y)",

  "cml_pia_B"    = "HIV PIA Black (10y)",
  "cml_pia_H"    = "HIV PIA Hispanic (10y)",
  "cml_pia_W"    = "HIV PIA White (10y)"

)

unused_labels <- c(
  "cml_nnt_B"    = "HIV NNT Black (10y)",
  "cml_nnt_H"    = "HIV NNT Hispanic (10y)",
  "cml_nnt_W"    = "HIV NNT White (10y)"
)

# Formatters for the variables
fmts <- replicate(length(var_labels), scales::label_number(1))
names(fmts) <- names(var_labels)

format_patterns <- list(
  small_num = list(
    patterns = c("lst_ir100", "cml_nnt"),
    fun = scales::label_number(0.01)
  ),
  perc = list(
    patterns = c("cml_pia"),
    fun = scales::label_percent(0.1)
  ),
  default = list(
    patterns = ".*",
    fun = scales::label_number(1)
  )
)

for (nms in names(fmts)) {
  for (fp in format_patterns) {
    if (any(stringr::str_detect(nms, fp$patterns))) {
      fmts[[nms]] <- fp$fun
      break()
    }
  }
}

make_ordered_labels <- function(nms, named_labels) {
  ordered_labels <- named_labels[nms]
  ordered_labels <- paste0(seq_along(ordered_labels), "-", ordered_labels)
  names(ordered_labels) <- nms

  ordered_labels
}

### utils-format.R
library(dplyr)
library(tidyr)

format_table <- function(d, var_labels, format_patterns) {
  formatters <- make_formatters(var_labels, format_patterns)

  d_out <- d |>
    sum_quants(0.025, 0.5, 0.975) |>
    pivot_longer(-scenario_name) |>
    separate(name, into = c("name", "quantile"), sep = "_/_") |>
    pivot_wider(names_from = quantile, values_from = value) |>
    filter(name %in% names(var_labels)) |>
    mutate(
      clean_val = purrr::pmap_chr(
        list(name, l, m, h),
        ~ common_format(formatters, ..1, ..2, ..3, ..4))
    ) |>
    select(-c(l, m, h)) |>
    mutate(
      name = var_labels[name]
    ) |>
    pivot_wider(names_from = name, values_from = clean_val) |>
    arrange(scenario_name)

  reorder_cols(d_out, var_labels)
}

make_formatters <- function(var_labels, format_patterns) {
  fmts <- vector(mode = "list", length = length(var_labels))
  for (nms in names(var_labels)) {
    for (fp in format_patterns) {
      if (any(stringr::str_detect(nms, fp$patterns))) {
        fmts[[nms]] <- fp$fun
        break()
      }
    }
  }
  fmts
}

sum_quants <- function(d, ql = 0.025, qm = 0.5, qh = 0.975) {
  d |>
    select(-c(sim)) |>
    summarise(across(
        everything(),
        list(
          l = \(x) quantile(x, ql, na.rm = TRUE),
          m = \(x) quantile(x, qm, na.rm = TRUE),
          h = \(x) quantile(x, qh, na.rm = TRUE)
          ),
        .names = "{.col}_/_{.fn}"
        ),
      .by = "scenario_name"
    )
}

reorder_cols <- function(d, var_labels) {
  missing_cols <- setdiff(names(d), var_labels)
  cols_order <- c(missing_cols, intersect(var_labels, names(d)))
  d[, cols_order]
}

common_format <- function(formatters, name, ql, qm, qh) {
  if (is.na(qm)) {
    "-"
  } else {
    paste0(
        formatters[[name]](qm), " (", formatters[[name]](ql),
        ", ", formatters[[name]](qh), ")"
    )
  }
}
