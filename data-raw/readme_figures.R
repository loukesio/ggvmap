# Pre-rendered README figures (the quality exceptions: hero, the 3x3 shapes
# grid, the palette gallery, and the interactive screenshot).  Everything else
# in README.Rmd is a live chunk.  Run from the package root:
#   Rscript data-raw/readme_figures.R
# then rebuild the README with devtools::build_readme().
suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
library(ggplot2)

data(freshwater)

# --- Hero: the full freshwater infographic ----------------------------------
vm <- voronoi_map(
  weights = freshwater$share,
  labels  = freshwater$country,
  group   = freshwater$region,
  clip    = clip_circle(),
  seed    = 5,
  max_iter = 80
)
name_col  <- setNames(ifelse(freshwater$region == "LATAM", "grey95", "grey15"),
                      freshwater$country)
value_col <- setNames(ifelse(freshwater$region == "LATAM", "grey85", "grey35"),
                      freshwater$country)
hero <- ggvmap(vm,
               palette    = "casa_natal",
               label_size = 2.5,
               label_col  = name_col,
               autoscale  = TRUE,
               min_area   = 0.009,
               wrap       = 10,
               fontface   = c(Brazil = "bold")) |>
  vm_add_labels(fmt = function(v) paste0(v, "%"),
                col = value_col,
                size = 2.1, autoscale = TRUE, min_area = 0.009) |>
  vm_add_ring(style = "arc", palette = "casa_natal", values = TRUE,
              label_size = 3)
ggsave("man/figures/README-hero.png", hero,
       width = 2600, height = 2600, units = "px", dpi = 350, bg = "white")
message("wrote man/figures/README-hero.png")

# --- 3x3 grid: every boundary shape, each in its own palette ----------------
top10 <- freshwater[!grepl("^Rest of|Middle East", freshwater$country), ][1:10, ]
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
grid_palettes <- c("minou", "dora", "casa_natal", "kiss", "ploen",
                   "maya", "hat", "seafarer", "shuggie")
panels <- lapply(seq_along(shapes), function(i) {
  nm <- names(shapes)[i]
  vmx <- voronoi_map(top10$share, labels = top10$country,
                     clip = shapes[[nm]], seed = 42)
  ggvmap(vmx, palette = grid_palettes[i], label_size = 1.9, autoscale = TRUE) +
    ggplot2::ggtitle(paste0("clip_", nm, "()  ·  \"", grid_palettes[i], "\"")) +
    ggplot2::theme(plot.title = ggplot2::element_text(
      size = 9, hjust = 0.5, family = "mono", colour = "grey30"))
})
grid <- patchwork::wrap_plots(panels, ncol = 3)
ggsave("man/figures/README-shapes-grid.png", grid,
       width = 2600, height = 2600, units = "px", dpi = 290, bg = "white")
message("wrote man/figures/README-shapes-grid.png")

# --- Palette gallery: all built-in palettes as swatch strips ----------------
pals <- vm_palettes()
sw <- do.call(rbind, lapply(seq_along(pals), function(i) {
  cols <- pals[[i]]
  data.frame(pal = names(pals)[i], row = i,
             x = seq_along(cols), fill = cols)
}))
sw$pal <- factor(sw$pal, levels = rev(names(pals)))
gallery <- ggplot(sw, aes(x = x, y = pal, fill = fill)) +
  geom_tile(width = 0.92, height = 0.72) +
  scale_fill_identity() +
  scale_x_continuous(expand = c(0.01, 0.01)) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(),
        axis.text.x = element_blank(),
        axis.text.y = element_text(family = "mono", size = 9, colour = "grey20"))
ggsave("man/figures/README-palettes.png", gallery,
       width = 2000, height = 2600, units = "px", dpi = 320, bg = "white")
message("wrote man/figures/README-palettes.png")

# --- Interactive hover demo -------------------------------------------------
# man/figures/README-interactive.gif is recorded from the live widget in
# headless Chrome by data-raw/readme_interactive_gif.R.
