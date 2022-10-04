library("EpiModel")

# Utilities --------------------------------------------------------------------

#' Takes a list of epi_trackers factory and return a list of epi_trackers
#'
#' This function accept epi_tracers factories as input. These are function
#' with one argument `races_set` that return an epi_tracker specific to a set of
#' races.
#' This function is used when the same trackers are used for different races
#'
#' @param trackers_list a list of epi_trackers factories
#' @param races the races of interest using the internal identifiers (here
#'   integers)
#' @param races_names character names to identify the races (here B, H W)
#' @param individual_trackers should a tracker be created for each of the
#'   `races`? (default = TRUE)
#' @param global_trackers should a tracker be created for the population as a
#'   whole, i.e. not stratified by race? (default = TRUE)
epi_trackers_by_races <- function(trackers_list,
                                  races = c(1, 2, 3),
                                  races_names = c("B", "H", "W"),
                                  individual_trackers = TRUE,
                                  global_trackers = TRUE) {
  races_list <- if (individual_trackers) as.list(races) else list()
  races_names <- if (individual_trackers) races_names else c()

  if (global_trackers) {
    races_list <- c(races_list, list(races))
    races_names <- c(races_names, "ALL")
  }

  epi_trackers <- lapply(
    races_list,
    function(races) {
      lapply(trackers_list, do.call, args = list(races_set = races))
    }
  )

  epi_trackers <- unlist(epi_trackers)
  names(epi_trackers) <- paste0(
    names(epi_trackers), "___",
    unlist(lapply(races_names, rep, times = length(trackers_list)))
  )

  return(epi_trackers)
}

# Trackers ---------------------------------------------------------------------
epi_n <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "active")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & active == 1, na.rm = TRUE)
    })
  }
}

# HIV Trackers
epi_s <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 0, na.rm = TRUE)
    })
  }
}

# eligible to prep
epi_s_prep_elig <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "prepElig")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 0 & prepElig == 1, na.rm = TRUE)
    })
  }
}

# on prep
epi_s_prep <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "prepStat")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 0 & prepStat == 1, na.rm = TRUE)
    })
  }
}

epi_i <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1, na.rm = TRUE)
    })
  }
}

epi_i_dx <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "diag.status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1 & diag.status == 1, na.rm = TRUE)
    })
  }
}

epi_i_tx <- function(races_set) {
  function(dat) {
    needed_attributes <- c("race", "status", "tx.status")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1 & tx.status == 1, na.rm = TRUE)
    })
  }
}

epi_i_sup <- function(races_set) {
  function(dat) {
    at <- get_current_timestep(dat)
    needed_attributes <- c("race", "status", "vl.last.supp")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set & status == 1 & vl.last.supp == at, na.rm = TRUE)
    })
  }
}

epi_i_sup_dur <- function(races_set) {
  function(dat) {
    at <- get_current_timestep(dat)
    needed_attributes <- c("race", "status", "vl.last.usupp")
    with(get_attr_list(dat, needed_attributes), {
      sum(race %in% races_set &
        status == 1 &
        at - vl.last.usupp >= 52,
      na.rm = TRUE
      )
    })
  }
}

# linked in less than `weeks` step
epi_linked_time <- function(weeks) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "tx.init.time", "diag.time")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            tx.init.time - diag.time <= weeks,
          na.rm = TRUE
        )
      })
    }
  }
}

# STI trackers
epi_gc_i <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rGC", "uGC", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rGC == 1 | uGC == 1),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_ct_i <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rCT", "uCT", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rCT == 1 | uCT == 1),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_gc_s <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rGC", "uGC", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rGC == 0 & uGC == 0),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_ct_s <- function(hiv_status) {
  function(races_set) {
    function(dat) {
      needed_attributes <- c("race", "rCT", "uCT", "status")
      with(get_attr_list(dat, needed_attributes), {
        sum(
          race %in% races_set &
            status %in% hiv_status &
            (rCT == 0 & uCT == 0),
          na.rm = TRUE
        )
      })
    }
  }
}

epi_prep_ret <- function(ret_steps) {
  function(races_set) {
    function(dat) {
      at <- get_current_timestep(dat)
      needed_attributes <- c("race", "prepStartTime")
      with(get_attr_list(dat, needed_attributes), {
        retained <- sum(
          race %in% races_set &
          prepStartTime == at - ret_steps,
          na.rm = TRUE
        )
      })
    }
  }
}
