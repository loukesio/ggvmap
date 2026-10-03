# Accuracy study behind vignettes/validation.Rmd.
# Run from the package root:  Rscript data-raw/fit_study.R
# Writes vignettes/fit_study.csv (one row per layout).
devtools::load_all(".", quiet = TRUE)

spreads <- list(
  even   = function(n) runif(n, 1, 2),          # values within a factor of 2
  typical = function(n) rlnorm(n, 3, 1),        # a few big, many small
  extreme = function(n) rlnorm(n, 3, 2)         # spans several orders of magnitude
)
shapes <- list(square = clip_square(), circle = clip_circle(),
               hexagon = clip_hexagon(), triangle = clip_triangle())

grid <- rbind(
  expand.grid(type = "flat", n = c(5, 10, 20, 40), shape = names(shapes),
              spread = names(spreads), seed = 1:10, stringsAsFactors = FALSE),
  expand.grid(type = "grouped", n = 30, shape = "circle",
              spread = names(spreads), seed = 1:10, stringsAsFactors = FALSE),
  expand.grid(type = "flat", n = 100, shape = "circle",
              spread = names(spreads), seed = 1:3, stringsAsFactors = FALSE)
)

run_one <- function(k) {
  g <- grid[k, ]
  set.seed(1000 + g$seed)
  w <- spreads[[g$spread]](g$n)
  grp <- if (g$type == "grouped") rep(LETTERS[1:5], length.out = g$n) else NULL
  t0 <- Sys.time()
  vm <- voronoi_map(w, group = grp, clip = shapes[[g$shape]], seed = g$seed)
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  # The same layout without the Newton phase, to measure what it adds.
  op <- options(ggvmap.newton = FALSE)
  vm0 <- voronoi_map(w, group = grp, clip = shapes[[g$shape]], seed = g$seed)
  options(op)
  fit <- vm_fit(vm)
  clip_area <- abs(polygon_area(vm$clip))
  cell_area <- sum(abs(vapply(vm$cells, polygon_area, numeric(1))))
  data.frame(
    g, iterations = vm$iterations, seconds = secs,
    converged = vm$converged, total_error = vm$convergence,
    converged_without_newton = vm0$converged,
    total_error_without_newton = vm0$convergence,
    median_rel_error = median(abs(fit$rel_error)),
    max_rel_error = max(abs(fit$rel_error)),
    within_5pct = mean(abs(fit$rel_error) <= 0.05),
    within_10pct = mean(abs(fit$rel_error) <= 0.10),
    worst_cell_value_share = fit$value_share[which.max(abs(fit$rel_error))],
    floored_cells = sum(fit$target_share > fit$value_share + 1e-12),
    tiling_error = abs(cell_area / clip_area - 1),
    stringsAsFactors = FALSE
  )
}

res <- do.call(rbind, parallel::mclapply(seq_len(nrow(grid)), run_one,
                                          mc.cores = max(1, parallel::detectCores() - 2)))
write.csv(res, "vignettes/fit_study.csv", row.names = FALSE)
