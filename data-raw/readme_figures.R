# Pre-rendered README figures (the quality exceptions: hero, the 3x3 shapes
# grid, and the interactive screenshot).  Everything else in README.Rmd is a
# live chunk.  Run from the package root:
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
ggsave("man/figures/README-hero.png", hero,
       width = 7.5, height = 7.5, dpi = 150, bg = "white")
message("wrote man/figures/README-hero.png")

# --- 3x3 grid: every boundary shape -----------------------------------------
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
panels <- lapply(names(shapes), function(nm) {
  vmx <- voronoi_map(top10$share, labels = top10$country,
                     clip = shapes[[nm]], seed = 42)
  ggvmap(vmx, palette = "alger", label_size = 1.9, autoscale = TRUE) +
    ggplot2::ggtitle(paste0("clip_", nm, "()")) +
    ggplot2::theme(plot.title = ggplot2::element_text(
      size = 9, hjust = 0.5, family = "mono", colour = "grey30"))
})
grid <- patchwork::wrap_plots(panels, ncol = 3)
ggsave("man/figures/README-shapes-grid.png", grid,
       width = 9, height = 9, dpi = 150, bg = "white")
message("wrote man/figures/README-shapes-grid.png")

# --- Interactive hover demo -------------------------------------------------
# man/figures/README-interactive.gif is recorded from the live widget in
# headless Chrome by data-raw/readme_interactive_gif.R.
