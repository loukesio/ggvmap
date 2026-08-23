test_that("ggvmap accepts a voronoi_map or raw weights", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  p1 <- ggvmap(vm)
  expect_s3_class(p1, "ggplot")
  expect_identical(attr(p1, "vm"), vm)

  p2 <- ggvmap(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  expect_s3_class(p2, "ggplot")
  expect_s3_class(attr(p2, "vm"), "voronoi_map")
})

test_that("autoplot delegates to ggvmap", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  pa <- autoplot(vm, palette = "alger", label_size = 4)
  pg <- ggvmap(vm, palette = "alger", label_size = 4)
  expect_equal(length(pa$layers), length(pg$layers))
})

test_that(".resolve_fontface handles single values and named vectors", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  expect_equal(ggvmap:::.resolve_fontface(vm, "bold"),
               c("bold", "bold", "bold"))
  expect_equal(ggvmap:::.resolve_fontface(vm, c(b = "bold.italic")),
               c("plain", "bold.italic", "plain"))
  # names not matching any cell are ignored
  expect_equal(ggvmap:::.resolve_fontface(vm, c(zzz = "bold")),
               c("plain", "plain", "plain"))
})

test_that("ggvmap fontface: named vector styles only the named cells", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  p <- ggvmap(vm, fontface = c(a = "bold", c = "bold.italic"))
  txt <- p$layers[[length(p$layers)]]
  faces <- txt$aes_params$fontface %||% txt$geom_params$fontface
  expect_equal(unname(faces), c("bold", "plain", "bold.italic"))
})

test_that("min_area drops name labels of tiny cells", {
  vm <- voronoi_map(c(100, 100, 1), labels = c("a", "b", "tiny"), seed = 1)
  p_all  <- ggvmap(vm)
  p_some <- ggvmap(vm, min_area = 0.05)
  txt_all  <- p_all$layers[[length(p_all$layers)]]$data
  txt_some <- p_some$layers[[length(p_some$layers)]]$data
  expect_equal(nrow(txt_all), 3)
  expect_equal(nrow(txt_some), 2)
  expect_false("tiny" %in% txt_some$label)
})

test_that("autoscale returns one size per cell, floored at 60%", {
  vm <- voronoi_map(c(100, 100, 1), labels = c("a", "b", "tiny"), seed = 1)
  sizes <- ggvmap:::.label_sizes(vm, 3, autoscale = TRUE)
  expect_length(sizes, 3)
  expect_true(all(sizes >= 0.6 * 3))
  expect_true(all(sizes <= 3))
  # the tiny cell gets smaller text than the large ones
  expect_lt(sizes[3], sizes[1])
  # off by default: constant size
  expect_equal(ggvmap:::.label_sizes(vm, 3, autoscale = FALSE), rep(3, 3))
})

test_that("vm_add_labels supports fontface named vector, min_area, autoscale", {
  vm <- voronoi_map(c(100, 100, 1), labels = c("a", "b", "tiny"), seed = 1)
  p  <- ggvmap(vm, show_labels = FALSE)

  p2 <- vm_add_labels(p, fontface = c(a = "bold"), autoscale = TRUE)
  lay <- p2$layers[[length(p2$layers)]]
  expect_equal(nrow(lay$data), 3)
  expect_equal(unname(lay$data$fontface), c("bold", "plain", "plain"))
  expect_lt(lay$data$size[3], lay$data$size[1])

  p3 <- vm_add_labels(p, min_area = 0.05)
  lay3 <- p3$layers[[length(p3$layers)]]
  expect_equal(nrow(lay3$data), 2)
  expect_false("tiny" %in% lay3$data$cell_label)

  # filtering everything returns the plot unchanged
  p4 <- vm_add_labels(p, min_area = 1)
  expect_equal(length(p4$layers), length(p$layers))
})

test_that("palette = 'alger' resolves and contains no black", {
  for (n in c(2, 4, 9)) {
    cols <- ggvmap:::.vm_palette(n, "alger")
    expect_length(cols, n)
    expect_false("#000000" %in% toupper(cols))
  }
  expect_equal(ggvmap:::.vm_palette(4, "alger"),
               c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F"))
  # continuous ramp also black-free
  cont <- ggvmap:::.vm_palette(64, "alger", continuous = TRUE)
  expect_false("#000000" %in% toupper(cont))
  # plotting with it works
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  expect_s3_class(ggvmap(vm, palette = "alger"), "ggplot")
})

test_that("data(freshwater) loads with the documented shape", {
  data(freshwater, envir = environment())
  expect_equal(nrow(freshwater), 30)
  expect_named(freshwater, c("country", "share", "region"))
  expect_lt(abs(sum(freshwater$share) - 100), 0.5)
  expect_setequal(unique(freshwater$region),
                  c("LATAM", "Asia-Pacific", "North America",
                    "Europe", "Africa", "Middle East"))
})

test_that("family reaches the text layers", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  p <- ggvmap(vm, family = "mono")
  txt <- p$layers[[length(p$layers)]]
  expect_equal(txt$aes_params$family, "mono")

  p2 <- vm_add_labels(ggvmap(vm, show_labels = FALSE), family = "mono")
  txt2 <- p2$layers[[length(p2$layers)]]
  expect_equal(txt2$aes_params$family, "mono")

  # NULL (default) leaves the ggplot2 default untouched
  p3 <- ggvmap(vm)
  expect_null(p3$layers[[length(p3$layers)]]$aes_params$family)
})

test_that("vm_add_ring style = 'arc' draws paths, not ring polygons", {
  vm <- voronoi_map(c(5, 3, 8, 4, 6, 2),
                    group = c("A", "A", "B", "B", "C", "C"),
                    clip = clip_circle(), seed = 1)
  p <- ggvmap(vm, show_labels = FALSE)
  n0 <- length(p$layers)

  arc <- vm_add_ring(p, style = "arc", curved = FALSE)
  new_layers <- arc$layers[(n0 + 1):length(arc$layers)]
  geoms <- vapply(new_layers, function(l) class(l$geom)[1], character(1))
  expect_true(any(geoms == "GeomPath"))
  expect_false(any(geoms == "GeomPolygon"))

  band <- vm_add_ring(p, style = "band")
  bgeoms <- vapply(band$layers[(n0 + 1):length(band$layers)],
                   function(l) class(l$geom)[1], character(1))
  expect_true(any(bgeoms == "GeomPolygon"))
})

test_that("arc values = TRUE appends percentage shares", {
  vm <- voronoi_map(c(5, 3, 8, 4, 6, 2),
                    group = c("A", "A", "B", "B", "C", "C"),
                    clip = clip_circle(), seed = 1)
  p <- vm_add_ring(ggvmap(vm, show_labels = FALSE),
                   style = "arc", values = TRUE, curved = FALSE)
  lab_layers <- Filter(function(l) "label" %in% names(l$data), p$layers)
  labs <- unlist(lapply(lab_layers, function(l) l$data$label))
  expect_true(all(grepl("%$", labs)))
})

test_that("per-cell label colours via named vectors", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  p <- ggvmap(vm, label_col = c(b = "red"))
  txt <- p$layers[[length(p$layers)]]
  expect_equal(unname(txt$aes_params$colour), c("white", "red", "white"))

  p2 <- vm_add_labels(ggvmap(vm, show_labels = FALSE), col = c(a = "blue"))
  txt2 <- p2$layers[[length(p2$layers)]]
  expect_equal(unname(txt2$aes_params$colour), c("blue", "grey20", "grey20"))
})
