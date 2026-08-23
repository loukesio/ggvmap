# Figure 2: gallery — everything drawn from data(freshwater).
# Nine boundary shapes, grouped layout, band + arc rings, continuous fill,
# and flags.  Run from the package root: Rscript paper/figures/fig2_gallery.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
})

data(freshwater)
top10 <- freshwater[!grepl("^Rest of|Middle East", freshwater$country), ][1:10, ]

lab <- function(p, title) {
  p + ggtitle(title) +
    theme(plot.title = element_text(size = 8, hjust = 0.5,
                                    family = "mono", colour = "grey30"))
}

# --- row 1-3: the nine shapes ----------------------------------------------
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
shape_panels <- lapply(names(shapes), function(nm) {
  vmx <- voronoi_map(top10$share, labels = top10$country,
                     clip = shapes[[nm]], seed = 42)
  lab(ggvmap(vmx, palette = "alger", label_size = 1.6, autoscale = TRUE),
      paste0("clip_", nm, "()"))
})

# --- bottom row: features ---------------------------------------------------
vm <- voronoi_map(freshwater$share, labels = freshwater$country,
                  group = freshwater$region, clip = clip_circle(),
                  seed = 5, max_iter = 80)

grouped <- lab(
  ggvmap(vm, palette = "alger", label_size = 1.7, label_col = "grey15",
         autoscale = TRUE, min_area = 0.02,
         group_border_col = c(LATAM = "#333333")),
  "grouped + emphasis")

band <- lab(
  ggvmap(vm, palette = "alger", show_labels = FALSE) |>
    vm_add_ring(style = "band", palette = "alger", width = 0.12,
                label_size = 2.0),
  "vm_add_ring(\"band\")")

arc <- lab(
  ggvmap(vm, palette = "alger", show_labels = FALSE) |>
    vm_add_ring(style = "arc", palette = "alger", values = TRUE,
                label_size = 2.0),
  "vm_add_ring(\"arc\")")

continuous <- lab(
  ggvmap(vm, fill_by = "data_weight", palette = "alger",
         show_labels = FALSE),
  "fill_by = \"data_weight\"")

flags <- if (requireNamespace("ggimage", quietly = TRUE)) {
  lab(
    ggvmap(top10$share, labels = top10$country, clip = clip_circle(),
           palette = "alger", show_labels = FALSE, seed = 42) |>
      vm_add_flags(size = 0.09),
    "vm_add_flags()")
} else {
  lab(ggplot() + theme_void(), "vm_add_flags() [ggimage missing]")
}

fig2 <- wrap_plots(c(shape_panels,
                     list(grouped, band, arc, continuous, flags)),
                   ncol = 5, nrow = 3)
ggsave("paper/figures/fig2_gallery.png", fig2, width = 13, height = 8,
       dpi = 300, bg = "white")
message("wrote paper/figures/fig2_gallery.png")
