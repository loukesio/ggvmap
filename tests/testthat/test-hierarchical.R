test_that("hierarchical layout partitions by group weight", {
  w <- c(5, 3, 2, 8, 4, 6, 1, 2, 3)
  g <- c("A", "A", "A", "B", "B", "B", "C", "C", "C")
  vm <- voronoi_map(w, group = g, clip = clip_circle(), seed = 1)

  expect_s3_class(vm, "voronoi_map")
  expect_true(vm$hierarchical)
  expect_length(vm$cells, length(w))
  expect_equal(nrow(vm$groups$sites), 3)

  # Total cell area equals the clip area
  total_clip <- abs(ggvmap:::polygon_area(vm$clip))
  total_cell <- sum(abs(vapply(vm$cells, ggvmap:::polygon_area, numeric(1))))
  expect_equal(total_cell, total_clip, tolerance = 0.01)

  # Group areas roughly proportional to group weights
  ga <- tapply(vm$sites$actual_area, vm$sites$group, sum)
  gw <- tapply(w, g, sum)
  ga <- ga[names(gw)]
  expect_true(all(abs(ga / sum(ga) - gw / sum(gw)) < 0.05))
})

test_that("sites carry group labels in cell order", {
  w <- c(4, 2, 6, 1)
  g <- c("X", "Y", "X", "Y")
  vm <- voronoi_map(w, labels = c("a", "b", "c", "d"), group = g, seed = 2)
  expect_equal(vm$sites$group, g)
  expect_equal(vm$sites$label, c("a", "b", "c", "d"))
})

test_that("single-member groups fill their whole sub-region", {
  w <- c(5, 3, 2)
  g <- c("A", "B", "C")           # every group has one member
  vm <- voronoi_map(w, group = g, clip = clip_circle(), seed = 1)
  expect_length(vm$cells, 3)
  # member cell area == group cell area for single-member groups
  for (k in 1:3) {
    expect_equal(
      abs(ggvmap:::polygon_area(vm$cells[[k]])),
      abs(ggvmap:::polygon_area(vm$groups$cells[[k]])),
      tolerance = 1e-6
    )
  }
})

test_that("vm_as_df includes a group column when hierarchical", {
  vm <- voronoi_map(c(3, 2, 5), group = c("A", "A", "B"), seed = 1)
  df <- vm_as_df(vm)
  expect_true("group" %in% names(df))
  expect_setequal(unique(df$group), c("A", "B"))
})
