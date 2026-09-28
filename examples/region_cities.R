# Run from the repository root after installing this checkout:
# Rscript examples/region_cities.R
# A shape test, not election data: every city receives the same illustrative weights.
suppressPackageStartupMessages({ library(ggvmap); library(sf); library(ggplot2) })
snapshot <- system.file("extdata", "region-cities.geojson", package = "ggvmap")
if (!nzchar(snapshot)) stop("Install the feature checkout with remotes::install_local('.') first.")
cities <- st_read(snapshot, quiet = TRUE)
weights <- c(A = 30, B = 25, C = 18, D = 12, E = 8, F = 5, G = 2)
fills <- setNames(c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F", "#80619D", "#518BBA", "#D6C68E"), names(weights))

# Reconstruct GEOS polygons from canonical rings for independent validation.
as_geometry <- function(parts) {
  signed <- function(p) {
    x <- p$x - p$x[1]; y <- p$y - p$y[1]; j <- c(2:length(x), 1L)
    sum(x * y[j] - x[j] * y) / 2
  }
  a <- vapply(parts, signed, numeric(1))
  polygons <- st_sfc(lapply(parts, function(p) {
    m <- cbind(p$x, p$y); st_polygon(list(rbind(m, m[1, ])))
  }))
  holes <- which(a < 0)
  shells <- lapply(which(a > 0), function(i) {
    included <- holes[lengths(st_within(polygons[holes], polygons[i])) > 0L]
    if (length(included)) st_difference(polygons[i], st_union(polygons[included])) else polygons[i]
  })
  st_union(do.call(c, shells))
}

audit <- list(); layouts <- list(); plots <- list()
scenarios <- list(uneven = weights, equal = setNames(rep(1, 7), names(weights)))
for (i in seq_len(nrow(cities))) {
  city <- cities$city[i]
  boundary <- st_transform(cities[i, ], cities$epsg[i])
  expected <- st_set_crs(st_geometry(boundary), NA)
  total <- as.numeric(st_area(expected))
  for (scenario in names(scenarios)) for (seed in c(1, 11, 42)) {
    w <- scenarios[[scenario]]
    vm <- vmap_region(w, boundary, labels = names(w), seed = seed,
                      convergence_ratio = .002, max_iter = 1000)
    geometry <- do.call(c, lapply(vm$cells, as_geometry))
    united <- st_union(geometry)
    measured <- as.numeric(st_area(geometry))
    error <- sum(abs(measured / total - w / sum(w)))
    mismatch <- sum(as.numeric(st_area(st_sym_difference(united, expected)))) / total
    overlap <- abs(sum(measured) - as.numeric(st_area(united))) / total
    stopifnot(vm$converged, all(st_is_valid(geometry)), error < .002,
              mismatch < 1e-7, overlap < 1e-7,
              max(abs(measured - vm$sites$actual_area)) / total < 1e-7)
    audit[[length(audit) + 1L]] <- data.frame(city = city, scenario = scenario, seed = seed,
      converged = vm$converged, iterations = vm$iterations,
      total_absolute_error_pp = 100 * error,
      max_cell_error_pp = 100 * max(abs(measured / total - w / sum(w))),
      coverage_difference_fraction = mismatch, overlap_fraction = overlap)
    cat(sprintf("%-12s %-6s seed=%2d iterations=%3d total error=%.3f pp\n", city, scenario, seed, vm$iterations, 100 * error))
    if (scenario == "uneven" && seed == 11) layouts[[city]] <- vm
  }
  vm <- layouts[[city]]
  # Use the public plotting and annotation functions, with actual map coordinates.
  p <- ggvmap(vm, palette = unname(fills), label_col = c(A = "white", D = "white", E = "white", B = "#142D31", C = "#142D31", F = "#142D31", G = "#142D31"), label_size = 3.4,
              border_size = .45, min_area = .03, legend = TRUE) |>
    vm_add_labels(suffix = "%", col = c(A = "white", D = "white", E = "white", B = "#142D31", C = "#142D31", F = "#142D31", G = "#142D31"),
                  size = 2.8, min_area = .03, nudge_y = -0.035 * max(diff(range(vm_as_df(vm)$x)), diff(range(vm_as_df(vm)$y))))
  p <- p + guides(fill = guide_legend(nrow = 1)) + labs(title = if (city == "London") "Greater London" else city,
                subtitle = sprintf("Same illustrative weights · area fit error %.3f percentage points", 100 * vm$convergence),
                caption = if (city %in% c("Amsterdam", "Thessaloniki"))
                  "Boundary: © OpenStreetMap contributors · ODbL · openstreetmap.org/copyright" else if (city == "London")
                  "Boundary: Greater London Authority / Ordnance Survey · Open Government Licence v3.0" else
                  "Boundary: Geoportal Berlin / ALKIS, via TSB · simplified 50 m") +
    theme(plot.title = element_text(size = 19, face = "bold"),
          plot.subtitle = element_text(size = 10, colour = "grey35"),
          plot.caption = element_text(size = 8, colour = "grey35"),
          legend.position = "bottom", legend.text = element_text(size = 8),
          plot.margin = margin(15, 15, 15, 15))
  plots[[city]] <- p
  ggsave(paste0("examples/region_", tolower(city), ".png"), p, width = 7, height = 6, dpi = 220, bg = "white")
}
write.csv(do.call(rbind, audit), "examples/region_cities_checks.csv", row.names = FALSE)

# A four-panel gallery, using each city's own scale. Shapes are never distorted.
draw_gallery <- function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(3, 2,
    heights = grid::unit(c(.9, 5, 5), "null"))))
  grid::grid.text("One set of weights, four real city outlines", x = .5, y = .68,
    gp = grid::gpar(fontsize = 22, fontface = "bold"),
    vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1:2))
  grid::grid.text("Illustrative A–G shares: 30%, 25%, 18%, 12%, 8%, 5%, 2% · Each city uses its own map scale",
    x = .5, y = .26, gp = grid::gpar(fontsize = 11, col = "#555555"),
    vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1:2))
  for (i in seq_along(plots)) print(plots[[i]], newpage = FALSE,
    vp = grid::viewport(layout.pos.row = 2 + (i - 1L) %/% 2L, layout.pos.col = 1 + (i - 1L) %% 2L))
  grid::popViewport()
}
grDevices::png("examples/region_cities.png", width = 2800, height = 2400, res = 220)
draw_gallery(); grDevices::dev.off()
grDevices::cairo_pdf("examples/region_cities.pdf", width = 2800/220, height = 2400/220)
draw_gallery(); grDevices::dev.off()
cat("PASS: 24 city/weight/seed combinations, with independent coverage and area checks.\n")
