# Figure 1: design principles of ggvmap.
# (A) workflow pipeline, (B) data -> code -> plot, (C) grammar of vm_add_*
# annotation layers, (D) grammar of appearance arguments.
# Run from the package root:  Rscript paper/figures/fig1_design.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
})

alger <- c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F")

# --- helpers for box diagrams ----------------------------------------------
box <- function(x, y, label, w = 0.42, h = 0.09, fill = "grey95",
                col = "grey30", text_col = "grey15", size = 3.1,
                fontface = "plain", family = "mono") {
  list(
    annotate("rect", xmin = x - w/2, xmax = x + w/2,
             ymin = y - h/2, ymax = y + h/2,
             fill = fill, colour = col, linewidth = 0.35),
    annotate("text", x = x, y = y, label = label, size = size,
             colour = text_col, fontface = fontface, family = family)
  )
}
arrow_down <- function(x, y0, y1) {
  annotate("segment", x = x, xend = x, y = y0, yend = y1,
           linewidth = 0.4, colour = "grey40",
           arrow = arrow(length = unit(4, "pt"), type = "closed"))
}
canvas <- function() {
  ggplot() + xlim(0, 1) + ylim(0, 1) + theme_void() +
    theme(plot.title = element_text(face = "bold", size = 11))
}

# --- (A) workflow -----------------------------------------------------------
pA <- canvas() + ggtitle("A  Workflow") +
  box(0.5, 0.95, "weights (+ labels, group)", fill = "white", family = "") +
  arrow_down(0.5, 0.905, 0.845) +
  box(0.5, 0.80, "voronoi_map()", fill = alger[2], size = 3.4) +
  arrow_down(0.5, 0.755, 0.695) +
  box(0.5, 0.65, "ggvmap()", fill = alger[3], size = 3.4) +
  arrow_down(0.5, 0.605, 0.545) +
  box(0.5, 0.50, "vm_add_ring()", fill = "grey95") +
  arrow_down(0.5, 0.455, 0.395) +
  box(0.5, 0.35, "vm_add_labels()", fill = "grey95") +
  arrow_down(0.5, 0.305, 0.245) +
  box(0.5, 0.20, "vm_add_flags()", fill = "grey95") +
  arrow_down(0.5, 0.155, 0.095) +
  box(0.30, 0.05, "ggsave()", w = 0.3, fill = "white") +
  box(0.70, 0.05, "vm_girafe()", w = 0.34, fill = "white") +
  annotate("segment", x = 0.5, xend = 0.3, y = 0.095, yend = 0.095,
           linewidth = 0.4, colour = "grey40") +
  annotate("segment", x = 0.5, xend = 0.7, y = 0.095, yend = 0.095,
           linewidth = 0.4, colour = "grey40") +
  annotate("text", x = 0.955, y = 0.35, label = "pipe  |>",
           angle = 90, size = 3, colour = "grey45", family = "mono")

# --- (B) data -> code -> plot ----------------------------------------------
data(freshwater)
vm <- voronoi_map(freshwater$share, labels = freshwater$country,
                  group = freshwater$region, clip = clip_circle(),
                  seed = 5, max_iter = 80)
name_col  <- setNames(ifelse(freshwater$region == "LATAM", "grey95", "grey15"),
                      freshwater$country)
value_col <- setNames(ifelse(freshwater$region == "LATAM", "grey85", "grey35"),
                      freshwater$country)
hero <- ggvmap(vm, palette = "alger", label_size = 2.0, label_col = name_col,
               autoscale = TRUE, min_area = 0.004,
               fontface = c(Brazil = "bold")) |>
  vm_add_labels(fmt = function(v) paste0(v, "%"), col = value_col,
                size = 1.7, autoscale = TRUE, min_area = 0.006) |>
  vm_add_ring(style = "arc", palette = "alger", values = TRUE,
              label_size = 2.4)
code_txt <- paste(
  "voronoi_map(freshwater$share,",
  "    labels = freshwater$country,",
  "    group  = freshwater$region,",
  "    clip   = clip_circle()) |>",
  "  ggvmap(palette = \"alger\",",
  "         autoscale = TRUE) |>",
  "  vm_add_labels() |>",
  "  vm_add_ring(style = \"arc\",",
  "              values = TRUE)",
  sep = "\n")
pB_code <- canvas() + ggtitle("B  Data to plot") +
  annotate("rect", xmin = 0.02, xmax = 0.98, ymin = 0.16, ymax = 1.0,
           fill = "grey96", colour = "grey80", linewidth = 0.3) +
  annotate("text", x = 0.07, y = 0.58, label = code_txt, size = 2.6,
           family = "mono", colour = "grey15", hjust = 0, lineheight = 1.3) +
  annotate("text", x = 0.5, y = 0.04,
           label = "data(freshwater): country, share, region",
           size = 2.7, colour = "grey40")
pB <- pB_code / hero + plot_layout(heights = c(1, 2.1))

# --- (C) grammar of annotation layers --------------------------------------
pC <- canvas() + ggtitle("C  Annotation layers") +
  box(0.26, 0.86, "vm_add_ring()",   fill = alger[2]) +
  box(0.26, 0.64, "vm_add_labels()", fill = alger[2]) +
  box(0.26, 0.42, "vm_add_flags()",  fill = alger[2]) +
  box(0.26, 0.20, "vm_add_images()", fill = alger[2]) +
  box(0.74, 0.86, "group band or arc,\nshares (values = TRUE)",
      fill = "white", family = "", size = 2.7, h = 0.14) +
  box(0.74, 0.64, "per-cell values,\nformatted, kept inside",
      fill = "white", family = "", size = 2.7, h = 0.14) +
  box(0.74, 0.42, "country flags from\nnames or ISO codes",
      fill = "white", family = "", size = 2.7, h = 0.14) +
  box(0.74, 0.20, "any image or logo\nat cell centroids",
      fill = "white", family = "", size = 2.7, h = 0.14)

# --- (D) grammar of appearance ---------------------------------------------
pD <- canvas() + ggtitle("D  Appearance") +
  box(0.22, 0.86, "map",   fill = alger[3], w = 0.3, family = "") +
  box(0.22, 0.58, "group", fill = alger[3], w = 0.3, family = "") +
  box(0.22, 0.28, "cell",  fill = alger[3], w = 0.3, family = "") +
  box(0.70, 0.86, "palette, fill_by, legend,\nclip shape, family",
      fill = "white", family = "", size = 2.7, h = 0.14, w = 0.52) +
  box(0.70, 0.58, "group_border_col\n(all groups or named)",
      fill = "white", family = "", size = 2.7, h = 0.14, w = 0.52) +
  box(0.70, 0.28, "fontface, label_col, label_cells,\nautoscale, min_area",
      fill = "white", family = "", size = 2.7, h = 0.16, w = 0.52)

fig1 <- (pA | pB | (pC / pD)) + plot_layout(widths = c(1, 1.35, 1.1))
ggsave("paper/figures/fig1_design.png", fig1, width = 12, height = 6.4,
       dpi = 300, bg = "white")
message("wrote paper/figures/fig1_design.png")
