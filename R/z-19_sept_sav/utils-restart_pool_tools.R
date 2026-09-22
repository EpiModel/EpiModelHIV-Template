merge_restart_points <- function(x, y) {
  required_names <- c(
    "control",
    "param",
    "nwparam",
    "epi",
    "run",
    "coef.form",
    "num.nw"
  )
  # TODO: ensure both have all elts necessary - or of right class
  # TODO: verify run
  #   - same names
  #   - same attrs

  out <- x
  out$control$nsims <- x$control$nsims + y$control$nsims
  new_names <- paste0("sim", seq_len(out$control$nsims))

  # Merge epi data
  for (i in seq_along(x$epi)) {
    out$epi[[i]] <- cbind(x$epi[[i]], y$epi[[i]])
    names(out$epi[[i]]) <- new_names
  }

  ## Formation coefficients
  out$coef.form <- c(x$coef.form, y$coef.form)
  names(out$coef.form) <- new_names

  out$run <- c(x$run, y$run)
  names(out$run) <- new_names

  return(out)
}

# NOTE: always keep a single step
# NOTE: only save what is necessary
make_restart_point <- function(
  sim_obj,
  time_attrs,
  sims_num = NULL
) {
  if (!inherits(sim_obj, c("netsim"))) {
    stop("`sim_obj` must be  an object of class `netsim`")
  }
  required_names <- c(
    "control",
    "param",
    "nwparam",
    "epi",
    "run",
    "coef.form",
    "num.nw"
  )
  missing_names <- setdiff(required_names, names(sim_obj))
  if (length(missing_names) > 0) {
    stop(
      "`sim_obj` is missing the following elements required for",
      " re-initialization: ",
      paste.and(missing_names)
    )
  }

  # Keep only the required_names
  rm_names <- setdiff(names(sim_obj), required_names)
  sim_obj[rm_names] <- NULL

  nsims <- sim_obj$control$nsims
  if (is.null(sims_num)) {
    sims_num <- seq_len(nsims)
    message("Making a restart object with all simulations (", nsims, ")")
  } else if (!all(sims_num %in% seq_len(sim_obj$control$nsims))) {
    stop("All `sims_num` must be >= 1 and <= `control$nsims` (", nsims, ")")
  }

  if (!sim_obj$control$tergmLite) {
    stop("Only `netsim` object with `tergmLite == TRUE` are supported")
  }

  # Select  the simulation of interest
  x <- get_sims(sim_obj, sims = sims_num)
  n_steps <- x$control$nsteps

  # Keep only the last row of each epi
  x$epi <- lapply(x$epi, function(r) r[n_steps, , drop = FALSE])

  # Time correction
  time_offset <- n_steps - 1
  x$control$start <- 1
  x$control$nsteps <- 1
  time_attrs <- union(c("entrTime", "exitTime"), time_attrs)

  # Per sim --------------------------------------------------------------------
  for (i_run in seq_along(x$run)) {
    run_ls <- x$run[[i_run]]

    # Time attributes - offset so last step is now `keep_steps`
    missing_attrs <- setdiff(time_attrs, names(run_ls$attr))
    if (length(missing_attrs) > 0) {
      stop(
        "Some time attributes are not present in the attributes list:",
        paste.and(missing_names)
      )
    }
    run_ls$attr[time_attrs] <- lapply(
      run_ls$attr[time_attrs],
      function(v) v - time_offset
    )

    # Fix UIDs
    uid_offset <- min(run_ls$attr$unique_id) - 1
    run_ls$attr$unique_id <- run_ls$attr$unique_id - uid_offset
    run_ls$last_unique_id <- run_ls$last_unique_id - uid_offset

    # Cumulative Edgelist - fix time and UIDs
    run_ls$el_cuml_cur <- lapply(
      run_ls$el_cuml_cur,
      function(el) {
        el$head <- el$head - uid_offset
        el$tail <- el$tail - uid_offset
        el$start <- el$start - time_offset
        el
      }
    )
    # For Historical one - truncate to 1 (only edges in the kept history)
    run_ls$el_cuml_hist <- lapply(
      run_ls$el_cuml_hist,
      function(el) {
        el$head <- el$head - uid_offset
        el$tail <- el$tail - uid_offset
        el$start <- el$start - time_offset
        el$stop <- el$stop - time_offset
        el[el$stop >= 1, , drop = FALSE]
      }
    )

    # the edgelist stores the name of the vertices. We don't use it with
    # `tergmLite` and it takes a lot of space
    run_ls$el <- lapply(run_ls$el, function(x) {
      attr(x, "vnames") <- NULL
      x
    })

    x$run[[i_run]] <- run_ls
  }

  return(x)
}
