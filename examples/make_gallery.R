# Regenerate the example-gallery PNGs and the README showcase figures.
# Run from the package root with:  Rscript examples/make_gallery.R
suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
library(ggplot2)

save_png <- function(p, file, size = 5.5, dpi = 150) {
  ggsave(file, p, width = size, height = size, dpi = dpi, bg = "white")
  message("wrote ", file)
}

w    <- c(30, 20, 50, 10, 40, 15, 25)
labs <- c("Tech", "Health", "Energy", "Finance", "Retail", "Media", "Auto")

# --- 01: the same weights on every boundary shape ---------------------------
shapes <- list(
  square    = clip_square(),
  hexagon   = clip_hexagon(),
  circle    = clip_circle(),
  diamond   = clip_diamond(),
  triangle  = clip_triangle(),
  pentagon  = clip_pentagon(),
  octagon   = clip_octagon(),
  rectangle = clip_rectangle(1, 0.6),
  ellipse   = clip_ellipse(0.5, 0.32)
)
for (nm in names(shapes)) {
  vm <- voronoi_map(w, labels = labs, clip = shapes[[nm]], seed = 42)
  save_png(ggvmap(vm, palette = "alger"),
           file.path("examples", sprintf("01_shape_%s.png", nm)))
}

# --- 02: continuous fill by weight ------------------------------------------
vm <- voronoi_map(w, labels = labs, clip = clip_square(), seed = 42)
save_png(ggvmap(vm, fill_by = "data_weight", palette = "alger", legend = TRUE),
         "examples/02_fill_weight.png")

# --- 03: hierarchical (grouped) layout on a square --------------------------
vm <- voronoi_map(
  c(30, 20, 50, 10, 40, 15, 25, 35, 12),
  labels = c("Tech", "Health", "Energy", "Finance", "Retail",
             "Media", "Auto", "Food", "Travel"),
  group  = c("Growth", "Defensive", "Cyclical", "Cyclical", "Cyclical",
             "Growth", "Cyclical", "Defensive", "Cyclical"),
  clip   = clip_square(), seed = 7
)
save_png(ggvmap(vm, palette = "alger"), "examples/03_grouped_square.png")

# --- 04: outer annotation ring (world exports) ------------------------------
data(world_exports)
vm <- voronoi_map(
  weights = world_exports$exports,
  labels  = world_exports$country,
  group   = as.character(world_exports$income_group),
  clip    = clip_circle(), seed = 1, max_iter = 80
)
p <- ggvmap(vm, label_size = 2.3, label_col = "grey20", palette = "alger") |>
  vm_add_ring(width = 0.11, label_size = 3.4, palette = "alger")
save_png(p, "examples/04_ring_custom.png", size = 6.5)
save_png(p, "man/figures/showcase_ring.png", size = 6.5)

# --- 05: flags + value labels (merchant fleets) -----------------------------
data(merchant_fleet)
fleet <- merchant_fleet[order(-merchant_fleet$owned), ][1:8, ]
vm <- voronoi_map(fleet$owned, labels = fleet$country,
                  clip = clip_circle(), seed = 3)
p <- ggvmap(vm, label_size = 3, label_col = "grey15", palette = "alger") |>
  vm_add_labels(value = stats::setNames(fleet$owned, fleet$country),
                size = 2.6) |>
  vm_add_flags(size = 0.05, nudge_y = 0.05)
save_png(p, "examples/05_flags_circle.png", size = 6)
save_png(p, "man/figures/showcase_flags.png", size = 6)

# --- 06: everything combined ------------------------------------------------
vm <- voronoi_map(
  weights = world_exports$exports,
  labels  = world_exports$country,
  group   = as.character(world_exports$income_group),
  clip    = clip_circle(), seed = 1, max_iter = 80
)
p <- ggvmap(vm, label_size = 2.1, label_col = "grey20", palette = "alger",
            autoscale = TRUE) |>
  vm_add_ring(width = 0.11, label_size = 3.2, palette = "alger") |>
  vm_add_flags(size = 0.028, nudge_y = 0.045)
save_png(p, "examples/06_combined.png", size = 6.5)

# --- 07: world freshwater — small-cell handling -----------------------------
# Renewable internal freshwater resources (km^3/yr, illustrative FAO figures).
# Includes several cells in the 0.7–0.9% range to exercise autoscale/min_area.
freshwater <- data.frame(
  country = c("Brazil", "Colombia", "Peru", "Venezuela",
              "Russia", "India", "China", "Indonesia", "Myanmar", "Malaysia",
              "Canada", "United States", "Mexico", "Nicaragua",
              "DR Congo", "Nigeria", "Madagascar", "Cameroon",
              "Norway", "France", "Italy", "Sweden"),
  region  = c(rep("South America", 4), rep("Asia", 6),
              rep("North America", 4), rep("Africa", 4), rep("Europe", 4)),
  km3     = c(5661, 2145, 1616, 805,
              4312, 1446, 2813, 2019, 1003, 580,
              2850, 2818, 409, 156,
              900, 221, 337, 273,
              378, 200, 183, 171)
)
vm <- voronoi_map(
  weights = freshwater$km3,
  labels  = freshwater$country,
  group   = freshwater$region,
  clip    = clip_circle(), seed = 5, max_iter = 80
)
p <- ggvmap(vm,
            palette          = "alger",
            label_size       = 2.6,
            label_col        = "grey15",
            autoscale        = TRUE,
            min_area         = 0.005,
            group_border_col = c("South America" = "#333333"),
            fontface         = c(Brazil = "bold.italic")) |>
  vm_add_labels(autoscale = TRUE, min_area = 0.005, size = 2.2)
save_png(p, "examples/07_freshwater_small_cells.png", size = 6.5)
