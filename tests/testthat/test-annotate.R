test_that("vm_centroids returns one row per cell", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  ctr <- vm_centroids(vm)
  expect_equal(nrow(ctr), 3)
  expect_true(all(c("cell", "label", "cx", "cy") %in% names(ctr)))
  # centroids lie inside the clip
  for (i in 1:3) {
    expect_true(ggvmap:::point_in_polygon(c(ctr$cx[i], ctr$cy[i]), vm$clip))
  }
})

test_that("vm_add_ring adds layers and preserves the vm attribute", {
  vm <- voronoi_map(c(5, 3, 8, 4, 6, 2),
                    group = c("A", "A", "B", "B", "C", "C"),
                    clip = clip_circle(), seed = 1)
  p  <- autoplot(vm)
  n0 <- length(p$layers)
  p2 <- vm_add_ring(p)
  expect_s3_class(p2, "ggplot")
  expect_gt(length(p2$layers), n0)
  expect_identical(attr(p2, "vm"), vm)
})

test_that("ring segments cover the full circle for a partitioned disk", {
  vm  <- voronoi_map(c(5, 3, 8, 4, 6, 2),
                     group = c("A", "A", "B", "B", "C", "C"),
                     clip = clip_circle(), seed = 1)
  seg <- ggvmap:::.ring_segments(vm)
  spans <- sum(seg$end - seg$start)
  expect_equal(spans, 2 * pi, tolerance = 0.15)
})

test_that(".angular_span handles wrap-around", {
  # angles clustered around 0 (i.e. -10deg .. +10deg)
  ang <- c(0.1, 6.2, 6.28, 0.0, 0.2)
  sp  <- ggvmap:::.angular_span(ang)
  expect_true(sp[2] > sp[1])
  expect_lt(sp[2] - sp[1], pi)   # a small contiguous arc, not the big complement
})

test_that(".align_to_cells maps named, positional and scalar inputs", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  expect_equal(ggvmap:::.align_to_cells(vm, c(a = 10, b = 20, c = 30)),
               c(10, 20, 30))
  expect_equal(ggvmap:::.align_to_cells(vm, c(1, 2, 3)), c(1, 2, 3))
  expect_equal(ggvmap:::.align_to_cells(vm, 7), c(7, 7, 7))
  expect_error(ggvmap:::.align_to_cells(vm, c(1, 2)), "one per cell")
})

test_that("vm_add_labels adds a text layer", {
  vm <- voronoi_map(c(3, 2, 5), labels = c("a", "b", "c"), seed = 1)
  p  <- autoplot(vm)
  p2 <- vm_add_labels(p, value = c(100, 200, 300))
  expect_gt(length(p2$layers), length(p$layers))
})

test_that("arc ring: overflowing label messages, empty string omits", {
  set.seed(1)
  vm <- voronoi_map(c(60, 30, 5, 1), labels = c("a", "b", "c", "d"),
                    group = c("Giant", "Big", "Small", "A very tiny group"),
                    clip = clip_circle(), seed = 1)
  p <- ggvmap(vm)
  # the tiny group's label cannot fit its segment -> informative message
  expect_message(vm_add_ring(p, style = "arc", values = TRUE),
                 "wider than their arc segment")
  # omitting that label silences the message and still builds
  expect_no_message(
    p2 <- vm_add_ring(p, style = "arc", values = TRUE,
                      labels = c("A very tiny group" = ""))
  )
  expect_s3_class(p2, "ggplot")
  # all labels omitted also builds
  expect_s3_class(
    vm_add_ring(p, style = "arc",
                labels = setNames(rep("", 4),
                                  c("Giant", "Big", "Small",
                                    "A very tiny group"))),
    "ggplot")
})
