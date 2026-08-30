# Built-in palettes and the .vm_palette resolver ------------------------------

test_that("every built-in palette resolves by name", {
  for (nm in names(vm_palettes())) {
    cols <- ggvmap:::.vm_palette(3, nm)
    expect_length(cols, 3)
    expect_true(all(grepl("^#", cols)), info = nm)
  }
})

test_that("palette names are matched case- and separator-insensitively", {
  base <- ggvmap:::.vm_palette(4, "casa_natal")
  expect_identical(ggvmap:::.vm_palette(4, "Casa Natal"), base)
  expect_identical(ggvmap:::.vm_palette(4, "casanatal"), base)
  expect_identical(ggvmap:::.vm_palette(4, "CASA-NATAL"), base)
})

test_that("qualitative built-ins return true palette colours up to their length", {
  pal <- vm_palettes()$casa_natal
  expect_identical(ggvmap:::.vm_palette(length(pal), "casa_natal"), unname(pal))
  # beyond the palette length, colours are interpolated
  more <- ggvmap:::.vm_palette(length(pal) + 3, "casa_natal")
  expect_length(more, length(pal) + 3)
})

test_that("heatmap palettes are always interpolated end-to-end", {
  pal <- vm_palettes()$heatmap2                     # 5-colour diverging ramp
  three <- ggvmap:::.vm_palette(3, "heatmap2")
  # ends of the ramp, not its first three colours
  expect_identical(toupper(three[1]), toupper(pal[1]))
  expect_identical(toupper(three[3]), toupper(pal[5]))
})

test_that("alger keeps its historical curated form", {
  expect_identical(vm_palettes()$alger,
                   c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F"))
})

test_that("no built-in palette contains pure black or near-white fills", {
  for (nm in setdiff(names(vm_palettes()), ggvmap:::.vm_ramp_palettes)) {
    lum <- apply(grDevices::col2rgb(vm_palettes()[[nm]]), 2, mean)
    expect_true(all(lum > 20 & lum < 240), info = nm)
  }
})

test_that("an unknown palette name gives an informative error", {
  expect_error(ggvmap:::.vm_palette(3, "no_such_palette"), "vm_palettes")
})
