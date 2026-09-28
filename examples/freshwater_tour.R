# The canonical ggvmap demo: countries with the most freshwater.
# Reproduces the classic infographic style from data(freshwater) —
# share of global renewable internal freshwater resources, 2022
# (FAO Aquastat via World Bank).
#
# Run from the package root:  Rscript examples/freshwater_tour.R
suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
library(ggplot2)

data(freshwater)

# --- The hero plot ----------------------------------------------------------
# Hierarchical layout (one sector per region), alger palette, autoscaled
# labels, values under names, and the thin labelled arc ring with shares.
vm <- voronoi_map(
  weights = freshwater$share,
  labels  = freshwater$country,
  group   = freshwater$region,
  clip    = clip_circle(),
  seed    = 5,
  max_iter = 80
)

# Light text on the dark LATAM cells, dark text everywhere else
name_col  <- setNames(ifelse(freshwater$region == "LATAM", "grey95", "grey15"),
                      freshwater$country)
value_col <- setNames(ifelse(freshwater$region == "LATAM", "grey85", "grey35"),
                      freshwater$country)

hero <- ggvmap(vm,
               palette    = "alger",
               label_size = 2.5,
               label_col  = name_col,
               autoscale  = TRUE,
               min_area   = 0.004,
               fontface   = c(Brazil = "bold")) |>
  vm_add_labels(fmt = function(v) paste0(v, "%"),
                col = value_col,
                size = 2.1, autoscale = TRUE, min_area = 0.006) |>
  vm_add_ring(style = "arc", palette = "alger", values = TRUE,
              label_size = 3)

ggsave("examples/freshwater_hero.png", hero,
       width = 7.5, height = 7.5, dpi = 150, bg = "white")
message("wrote examples/freshwater_hero.png")

# --- Variations -------------------------------------------------------------

# Top 10 countries only, flat map on a hexagon
top10 <- freshwater[!grepl("^Rest of|Middle East", freshwater$country), ][1:10, ]
p <- ggvmap(top10$share, labels = top10$country,
            clip = clip_hexagon(), palette = "alger", seed = 42)
ggsave("examples/freshwater_top10_hex.png", p,
       width = 6, height = 6, dpi = 150, bg = "white")
message("wrote examples/freshwater_top10_hex.png")

# Band-style ring (the filled segments), emphasising one region's border
p <- ggvmap(vm, palette = "alger", label_size = 2.4, label_col = "grey15",
            autoscale = TRUE, min_area = 0.004,
            group_border_col = c(LATAM = "#333333")) |>
  vm_add_ring(style = "band", palette = "alger", width = 0.11)
ggsave("examples/freshwater_band_ring.png", p,
       width = 7, height = 7, dpi = 150, bg = "white")
message("wrote examples/freshwater_band_ring.png")

# Flags on the top-10 map (needs ggimage + internet)
if (requireNamespace("ggimage", quietly = TRUE)) {
  p <- ggvmap(top10$share, labels = top10$country, clip = clip_circle(),
              palette = "alger", label_size = 2.6, label_col = "grey15",
              seed = 42) |>
    vm_add_labels(fmt = function(v) paste0(v, "%"), size = 2.2) |>
    vm_add_flags(size = 0.05, nudge_y = 0.055)
  ggsave("examples/freshwater_flags.png", p,
         width = 6.5, height = 6.5, dpi = 150, bg = "white")
  message("wrote examples/freshwater_flags.png")
}
