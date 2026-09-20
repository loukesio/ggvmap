# Region invariants use sf/GEOS independently of the polyclip area calculations.
region_sf <- function(parts) {
  area <- vapply(parts, ggvmap:::.region_ring_area, numeric(1))
  if (!length(parts)) return(sf::st_sfc(sf::st_polygon()))
  polys <- sf::st_sfc(lapply(parts, function(p) {
    m <- cbind(p$x, p$y)
    sf::st_polygon(list(rbind(m, m[1, ])))
  }))
  # Add nested islands after subtracting the holes of their containing shell.
  shells <- which(area > 0); holes <- which(area < 0)
  pieces <- lapply(shells, function(i) {
    inside <- holes[lengths(sf::st_within(polys[holes], polys[i])) > 0]
    if (length(inside)) sf::st_difference(polys[i], sf::st_union(polys[inside])) else polys[i]
  })
  sf::st_union(do.call(c, pieces))
}

expect_region_partition <- function(vm, expected) {
  total <- as.numeric(sf::st_area(expected))
  cells <- do.call(c, lapply(vm$cells, region_sf))
  expect_true(all(sf::st_is_valid(cells)))
  expect_equal(as.numeric(sf::st_area(cells)) / total,
               vm$sites$actual_area / total, tolerance = 1e-7)
  whole <- sf::st_union(cells)
  difference <- sum(as.numeric(sf::st_area(sf::st_sym_difference(whole, expected))))
  expect_lt(difference / total, 1e-7)
  overlap <- (sum(as.numeric(sf::st_area(cells))) - as.numeric(sf::st_area(whole))) / total
  expect_lt(abs(overlap), 1e-7)
  expect_equal(vm$convergence,
               sum(abs(vm$sites$actual_area - vm$sites$target_area)) / total,
               tolerance = 1e-7)
  ctr <- vm_centroids(vm, inside = TRUE)
  expect_true(all(vapply(seq_along(vm$cells), function(i) {
    ggvmap:::.region_inside(c(ctr$cx[i], ctr$cy[i]), vm$cells[[i]])
  }, logical(1))))
}

test_that("concave clips are directed to the region solver", {
  u <- cbind(c(0, 3, 3, 2, 2, 1, 1, 0), c(0, 0, 3, 3, 1, 1, 3, 3))
  expect_error(voronoi_map(c(5, 3, 2), clip = u), "vmap_region")
  star <- regular_polygon(5)[c(1, 3, 5, 2, 4), ]
  expect_error(voronoi_map(c(5, 3, 2), clip = star), "convex")
  expect_true(voronoi_map(c(1, 1), clip = clip_square()[4:1, ], seed = 1)$converged)
  skip_if_not_installed("polyclip")
  skip_if_not_installed("sf")
  vm <- vmap_region(c(5, 3, 2), u, seed = 4, convergence_ratio = 0.002)
  expect_s3_class(vm, "voronoi_region")
  expect_true(vm$converged)
  expect_region_partition(vm, sf::st_sfc(sf::st_polygon(list(rbind(u, u[1, ])))))
})

test_that("holes, separate islands and a one-cell region retain their topology", {
  skip_if_not_installed("polyclip")
  skip_if_not_installed("sf")
  outer <- rbind(c(0, 0), c(6, 0), c(6, 6), c(0, 6), c(0, 0))
  hole <- rbind(c(1, 1), c(4, 1), c(4, 4), c(1, 4), c(1, 1))
  island <- rbind(c(2, 2), c(3, 2), c(3, 3), c(2, 3), c(2, 2))
  separate <- outer / 4 + 8
  geometry <- sf::st_sfc(sf::st_multipolygon(list(list(outer, hole), list(island), list(separate))))
  rings <- list(outer, hole, island, separate)
  vm <- vmap_region(1, rings)
  expect_true(vm$converged)
  expect_identical(vm$iterations, 0L)
  expect_equal(vm$total_area, 30.25, tolerance = 1e-8)
  expect_region_partition(vm, geometry)
  for (seed in c(1, 11)) {
    fit <- vmap_region(c(5, 3, 2), rings, seed = seed)
    expect_true(fit$converged)
    expect_region_partition(fit, geometry)
  }
  # A centered hole puts the mathematical centroid outside the filled region.
  centered <- list(clip_square(r = 2), clip_square(r = 1))
  donut <- vmap_region(1, centered)
  expect_false(ggvmap:::.region_inside(unlist(vm_centroids(donut)[c("cx", "cy")]), donut$clip))
  expect_true(ggvmap:::.region_inside(unlist(vm_centroids(donut, inside = TRUE)[c("cx", "cy")]), donut$clip))
})

test_that("region fitting is scale-stable, reproducible, and preserves RNG state", {
  skip_if_not_installed("polyclip")
  shape <- cbind(c(0, 4, 4, 1, 1, 0), c(0, 0, 1, 1, 4, 4))
  set.seed(91); before <- .Random.seed
  a <- vmap_region(c(5, 3, 2), shape, seed = 8)
  expect_identical(.Random.seed, before)
  b <- vmap_region(c(5, 3, 2), sweep(shape * 1000, 2, c(400000, 5500000), "+"), seed = 8)
  expect_equal(a$sites$actual_area, b$sites$actual_area / 1e6, tolerance = 1e-6)
  expect_equal(a$cells, vmap_region(c(5, 3, 2), shape, seed = 8)$cells)
  expect_equal(a$sites$target_area / a$total_area, c(.5, .3, .2))
  one <- vmap_region(c(1, .001), clip_square(), seed = 2, min_weight_ratio = .1)
  expect_equal(one$sites$target_area / one$total_area, c(1, .1) / 1.1)
})

test_that("malformed input and non-convergence are explicit", {
  skip_if_not_installed("polyclip")
  for (weights in list(numeric(), c(1, NA), c(1, Inf), c(1, -1), c(1, 0))) {
    expect_error(vmap_region(weights, clip_square()), "positive")
  }
  expect_error(vmap_region(1:2, clip_square(), labels = c("a", "a")), "unique")
  expect_error(vmap_region(1:2, clip_square(), max_iter = 0), "max_iter")
  expect_error(vmap_region(1:2, clip_square(), convergence_ratio = NA), "convergence_ratio")
  expect_error(vmap_region(1:2, clip_square(), seed = 1.5), "seed")
  expect_error(vmap_region(1:2, clip_square(), min_weight_ratio = -1), "min_weight_ratio")
  expect_error(vmap_region(1, cbind(1:3, 1:3)), "area")
  expect_error(vmap_region(1, list(x = 1:3, y = 1:2)), "equally long")
  expect_error(vmap_region(1, matrix(NA_real_, 3, 2)), "finite")
  expect_warning(vm <- vmap_region(c(50, 3, 1), clip_square(), seed = 2,
                                  max_iter = 1, convergence_ratio = 1e-10), "did not converge")
  expect_false(vm$converged)
  expect_true(is.finite(vm$convergence))
})

test_that("spatial input requires projection and combines features as a union", {
  skip_if_not_installed("polyclip")
  skip_if_not_installed("sf")
  square <- rbind(clip_square(), clip_square()[1, ])
  geo <- sf::st_sfc(sf::st_polygon(list(square + 10)), crs = 4326)
  expect_error(vmap_region(1, geo), "Project longitude")
  projected <- vmap_region(1, geo, crs = 3857)
  expect_equal(projected$crs$epsg, 3857L)
  expect_error(vmap_region(1, sf::st_set_crs(geo, NA)), "known projected")
  expect_error(vmap_region(1, sf::st_sfc(sf::st_point(c(0, 0)), crs = 25833)), "POLYGON")
  bow <- rbind(c(0, 0), c(1, 1), c(0, 1), c(1, 0), c(0, 0))
  expect_error(vmap_region(1, sf::st_sfc(sf::st_polygon(list(bow)), crs = 25833)), "Invalid")
  g <- sf::st_sfc(sf::st_polygon(list(square)), sf::st_polygon(list(square + .5)), crs = 25833)
  vm <- vmap_region(c(3, 2), g, seed = 2)
  expect_equal(vm$total_area, 1.75, tolerance = 1e-7)
  expect_region_partition(vm, sf::st_set_crs(sf::st_union(g), NA))
})

test_that("region plots retain ring groups and interior annotation anchors", {
  skip_if_not_installed("polyclip")
  vm <- vmap_region(1, list(clip_square(r = 2), clip_square(r = 1)))
  df <- vm_as_df(vm)
  expect_equal(length(unique(df$ring)), 2L)
  expect_true(all(df$cell == 1))
  p <- ggvmap(vm, palette = "alger")
  expect_s3_class(autoplot(vm), "ggplot")
  expect_identical(p$layers[[1]]$geom_params$rule, "evenodd")
  built <- ggplot2::ggplot_build(p)
  expect_equal(length(unique(built$data[[1]]$subgroup)), 2L)
  anchor <- p$layers[[2]]$data
  expect_true(ggvmap:::.region_inside(c(anchor$cx, anchor$cy), vm$clip))
  p <- vm_add_labels(p, nudge_x = 100, nudge_y = 100)
  label <- p$layers[[3]]$data
  expect_true(ggvmap:::.region_inside(c(label$x, label$y), vm$clip))
  expect_error(ggvmap(vm, interactive = TRUE), "not yet supported")
  expect_error(vm_add_ring(ggvmap(vm)), "not supported")
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  expect_silent(plot(vm))
  grDevices::dev.off()
  expect_gt(file.info(path)$size, 0)
})

test_that("all four city snapshots fit and tile their supplied boundaries", {
  skip_if_not_installed("polyclip")
  skip_if_not_installed("sf")
  cities <- sf::st_read(system.file("extdata", "region-cities.geojson", package = "ggvmap"), quiet = TRUE)
  expect_setequal(cities$city, c("Berlin", "Amsterdam", "London", "Thessaloniki"))
  for (i in seq_len(nrow(cities))) for (seed in c(1, 11)) {
    city <- sf::st_transform(cities[i, ], cities$epsg[i])
    vm <- vmap_region(c(30, 25, 18, 12, 8, 5, 2), city,
                      seed = seed, convergence_ratio = .002)
    expect_true(vm$converged, info = cities$city[i])
    expect_region_partition(vm, sf::st_set_crs(sf::st_geometry(city), NA))
  }
})
