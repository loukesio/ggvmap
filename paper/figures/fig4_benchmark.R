# Figure 4: benchmarking ggvmap against voronoiTreemap (D3/htmlwidget) and
# WeightedTreemaps (C++/CGAL).
#  (i)   install complexity: recursive dependency count + compiled code
#  (ii)  code length for the same grouped treemap
#  (iii) runtime for flat maps of n = 10/50/100/500 lognormal weights
#        ({bench}; median of 10 iterations, 3 at n = 500)
#  (iv)  layout accuracy: mean |actual - target| / target cell-area error
# voronoiTreemap computes its layout in the browser (D3), so R-side runtime
# and accuracy are not measurable for it; it appears in (i) and (ii) only.
# Results are written to paper/figures/benchmark_results.csv.
# Run from the package root:  Rscript paper/figures/fig4_benchmark.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
  library(bench)
  library(WeightedTreemaps)
})

alger  <- c("#1A5B5B", "#ACC8BE", "#F4AB5C", "#D1422F")
pk_col <- c(ggvmap = alger[1], WeightedTreemaps = alger[3],
            voronoiTreemap = alger[4])

# --- (i) install complexity -------------------------------------------------
db <- available.packages(repos = "https://cloud.r-project.org")
base_pkgs <- rownames(installed.packages(priority = "base"))
rec_deps <- function(pkg) {
  d <- unlist(tools::package_dependencies(
    pkg, db = db, which = c("Depends", "Imports", "LinkingTo"),
    recursive = TRUE))
  setdiff(unique(d), c(base_pkgs, "R"))
}
# ggvmap is not on CRAN: its only non-base Import is ggplot2
deps <- data.frame(
  package  = c("ggvmap", "voronoiTreemap", "WeightedTreemaps"),
  n_deps   = c(length(rec_deps("ggplot2")) + 1L,
               length(rec_deps("voronoiTreemap")),
               length(rec_deps("WeightedTreemaps"))),
  compiled = c("no", "no*", "yes (CGAL)")
)
print(deps)

p1 <- ggplot(deps, aes(x = reorder(package, n_deps), y = n_deps,
                       fill = package)) +
  geom_col(width = 0.62, show.legend = FALSE) +
  geom_text(aes(label = paste0(n_deps, " deps\ncompiled: ", compiled)),
            hjust = -0.06, size = 2.9, colour = "grey20", lineheight = 1.05) +
  scale_fill_manual(values = pk_col) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.45))) +
  coord_flip() +
  labs(title = "A  Install complexity",
       subtitle = "recursive Depends/Imports/LinkingTo (CRAN, non-base)",
       x = NULL, y = "packages") +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"))

# --- (ii) code length for the same grouped treemap --------------------------
snippets <- list(
  ggvmap = 'vm <- voronoi_map(freshwater$share, labels = freshwater$country,
                  group = freshwater$region, clip = clip_circle(), seed = 1)
ggvmap(vm, palette = "alger")',
  WeightedTreemaps = 'tm <- voronoiTreemap(data = freshwater, levels = c("region", "country"),
                     cell_size = "share", shape = "circle", seed = 1)
drawTreemap(tm, label_level = 2, title = NULL)',
  voronoiTreemap = 'fw <- data.frame(h1 = "World", h2 = freshwater$region,
                 h3 = freshwater$country, color = "#1A5B5B",
                 weight = freshwater$share, codes = freshwater$country)
vt <- vt_input_from_df(fw, scaleToPerc = TRUE)
vt_d3(vt_export_json(vt), color_border = "#ffffff")'
)
code_stats <- do.call(rbind, lapply(names(snippets), function(p) {
  s <- snippets[[p]]
  data.frame(
    package = p,
    lines   = length(strsplit(s, "\n")[[1]]),
    words   = length(strsplit(gsub("\\s+", " ", s), " ")[[1]]),
    chars   = nchar(gsub("\\s+", " ", s)),
    calls   = lengths(regmatches(s, gregexpr("[A-Za-z_.][A-Za-z0-9_.]*\\(", s)))
  )
}))
print(code_stats)

cl <- reshape(code_stats, direction = "long",
              varying = c("lines", "words", "chars", "calls"),
              v.names = "value", timevar = "metric",
              times = c("lines", "words", "chars", "calls"))
p2 <- ggplot(cl, aes(x = metric, y = value, fill = package)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.68) +
  scale_fill_manual(values = pk_col) +
  scale_y_log10() +
  labs(title = "B  Code length (same grouped treemap)",
       x = NULL, y = "count (log scale)", fill = NULL) +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

# --- (iii) runtime + (iv) accuracy ------------------------------------------
sizes <- c(10, 50, 100, 500)
rows <- list()
for (n in sizes) {
  set.seed(n)
  w  <- rlnorm(n, meanlog = 3, sdlog = 1)
  df <- data.frame(id = paste0("c", seq_len(n)), w = w)
  iters <- if (n >= 500) 3L else 10L

  bm_gg <- bench::mark(
    ggvmap = voronoi_map(w, seed = 1),
    iterations = iters, check = FALSE, memory = FALSE, filter_gc = FALSE)
  bm_wt <- bench::mark(
    WeightedTreemaps = voronoiTreemap(
      data = df, levels = "id", cell_size = "w", shape = "circle",
      seed = 1, verbose = FALSE),
    iterations = iters, check = FALSE, memory = FALSE, filter_gc = FALSE)

  # accuracy: mean relative area error per cell
  vm <- voronoi_map(w, seed = 1)
  err_gg <- mean(abs(vm$sites$actual_area - vm$sites$target_area) /
                   vm$sites$target_area)
  tm <- voronoiTreemap(data = df, levels = "id", cell_size = "w",
                       shape = "circle", seed = 1, verbose = FALSE)
  ar  <- vapply(tm@cells, function(cc) cc$area,   numeric(1))
  tg  <- vapply(tm@cells, function(cc) cc$target, numeric(1))
  shr <- ar / sum(ar)
  tgn <- tg / sum(tg)
  err_wt <- mean(abs(shr - tgn) / tgn)

  rows[[length(rows) + 1]] <- data.frame(
    n = n, package = c("ggvmap", "WeightedTreemaps"),
    median_s = as.numeric(c(bm_gg$median, bm_wt$median)),
    iterations = iters,
    mean_rel_area_error = c(err_gg, err_wt))
  message("n = ", n, " done")
}
res <- do.call(rbind, rows)
res_out <- merge(res,
                 data.frame(package = deps$package, n_deps = deps$n_deps,
                            compiled = deps$compiled),
                 by = "package", all.x = TRUE)
write.csv(res_out, "paper/figures/benchmark_results.csv", row.names = FALSE)
print(res)

p3 <- ggplot(res, aes(x = n, y = median_s, colour = package)) +
  geom_line(linewidth = 0.7) + geom_point(size = 2) +
  scale_colour_manual(values = pk_col) +
  scale_x_log10(breaks = sizes) + scale_y_log10() +
  labs(title = "C  Runtime",
       subtitle = "flat map, lognormal weights; median of 10 runs (3 at n = 500)",
       x = "number of cells", y = "seconds (log)", colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

p4 <- ggplot(res, aes(x = n, y = 100 * mean_rel_area_error,
                      colour = package)) +
  geom_line(linewidth = 0.7) + geom_point(size = 2) +
  scale_colour_manual(values = pk_col) +
  scale_x_log10(breaks = sizes) +
  labs(title = "D  Layout accuracy",
       subtitle = "mean |actual - target| / target cell area",
       x = "number of cells", y = "mean relative error (%)", colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

fig4 <- (p1 | p2) / (p3 | p4)
ggsave("paper/figures/fig4_benchmark.png", fig4, width = 10, height = 7.6,
       dpi = 300, bg = "white")
message("wrote paper/figures/fig4_benchmark.png")
