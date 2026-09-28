# Regenerate the example-gallery PNGs (README figures live in data-raw/readme_figures.R).
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
# The bundled data(freshwater) has several 0.7-0.9% cells, exercising
# autoscale/min_area.  The full infographic lives in freshwater_tour.R.
data(freshwater)
vm <- voronoi_map(
  weights = freshwater$share,
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
            group_border_col = c(LATAM = "#333333"),
            fontface         = c(Brazil = "bold.italic")) |>
  vm_add_labels(autoscale = TRUE, min_area = 0.005, size = 2.2,
                fmt = function(v) paste0(v, "%"))
save_png(p, "examples/07_freshwater_small_cells.png", size = 6.5)
