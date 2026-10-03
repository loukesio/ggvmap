# Figure 4: benchmarking ggvmap against voronoiTreemap (D3/htmlwidget) and
# WeightedTreemaps (C++/CGAL).
#  (i)   install complexity: recursive dependency count + compiled code
#  (ii)  code length for the same grouped treemap
#  (iii) runtime for flat circular maps of n = 10..500 lognormal weights,
#        5 random datasets per size (1 at n = 500), each timed once
#  (iv)  layout accuracy: total area error (and median per-cell error in the CSV)
# voronoiTreemap computes its layout in the browser (D3), so R-side runtime
# and accuracy are not measurable for it; it appears in (i) and (ii) only.
# Per-run results: paper/figures/benchmark_runs.csv; medians per size:
# paper/figures/benchmark_results.csv. Takes about 30-40 minutes.
# Run from the package root:  Rscript paper/figures/fig4_benchmark.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
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
# Both packages lay out the SAME weights in the SAME shape (a circle), each at
# its default settings. Five random datasets per size (one at n = 500, which
# takes ~10 minutes in ggvmap); each layout is timed once.
# Two error measures, both computed from each package's own reported areas:
#   total_error      sum over cells of |drawn share - intended share|
#                    (ggvmap's stopping rule; 0.01 = 1%)
#   median_rel_error median over cells of |drawn - intended| / intended
sizes <- c(10, 25, 50, 100, 200, 500)
fit_errors <- function(actual, target) {
  a <- actual / sum(actual); t <- target / sum(target)
  c(total_error = sum(abs(a - t)), median_rel_error = median(abs(a - t) / t))
}
# Set REUSE_RUNS=1 to redraw the figure from benchmark_runs.csv without
# re-timing anything.
reuse <- Sys.getenv("REUSE_RUNS") == "1" && file.exists("paper/figures/benchmark_runs.csv")
rows <- list()
for (n in if (reuse) integer(0) else sizes) {
  for (rep in if (n >= 500) 1L else 1:5) {
    set.seed(1000 * n + rep)
    w  <- rlnorm(n, meanlog = 3, sdlog = 1)
    df <- data.frame(id = paste0("c", seq_len(n)), w = w)

    t_gg <- system.time(vm <- voronoi_map(w, clip = clip_circle(), seed = rep))[["elapsed"]]
    t_wt <- system.time(tm <- voronoiTreemap(
      data = df, levels = "id", cell_size = "w", shape = "circle",
      seed = rep, verbose = FALSE))[["elapsed"]]

    e_gg <- fit_errors(vm$sites$actual_area, vm$sites$target_area)
    e_wt <- fit_errors(vapply(tm@cells, function(cc) cc$area,   numeric(1)),
                       vapply(tm@cells, function(cc) cc$target, numeric(1)))
    rows[[length(rows) + 1]] <- data.frame(
      n = n, rep = rep, package = c("ggvmap", "WeightedTreemaps"),
      seconds = c(t_gg, t_wt),
      ggvmap_converged = c(vm$converged, NA),
      total_error = c(e_gg[["total_error"]], e_wt[["total_error"]]),
      median_rel_error = c(e_gg[["median_rel_error"]], e_wt[["median_rel_error"]]))
    message("n = ", n, " rep ", rep, " done")
  }
}
if (reuse) {
  runs <- read.csv("paper/figures/benchmark_runs.csv")
} else {
  runs <- do.call(rbind, rows)
  write.csv(runs, "paper/figures/benchmark_runs.csv", row.names = FALSE)
}
res <- aggregate(cbind(seconds, total_error, median_rel_error) ~ package + n,
                 data = runs, FUN = median)
res_out <- merge(res,
                 data.frame(package = deps$package, n_deps = deps$n_deps,
                            compiled = deps$compiled),
                 by = "package", all.x = TRUE)
write.csv(res_out, "paper/figures/benchmark_results.csv", row.names = FALSE)
print(res)

p3 <- ggplot(res, aes(x = n, y = seconds, colour = package)) +
  geom_point(data = runs, alpha = 0.35, size = 1.2) +
  geom_line(linewidth = 0.7) + geom_point(size = 2) +
  scale_colour_manual(values = pk_col) +
  scale_x_log10(breaks = sizes) + scale_y_log10() +
  labs(title = "C  Runtime",
       subtitle = "same weights, same circle; line = median of 5 datasets (1 at n = 500)",
       x = "number of cells", y = "seconds (log)", colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

p4 <- ggplot(res, aes(x = n, y = 100 * total_error, colour = package)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey55") +
  geom_point(data = runs, alpha = 0.35, size = 1.2) +
  geom_line(linewidth = 0.7) + geom_point(size = 2) +
  scale_colour_manual(values = pk_col) +
  scale_x_log10(breaks = sizes) + scale_y_log10() +
  labs(title = "D  Layout accuracy",
       subtitle = "area mistakes of all cells added up, % of map (dashed = 1%)",
       x = "number of cells", y = "total area error (%)", colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

fig4 <- (p1 | p2) / (p3 | p4)
ggsave("paper/figures/fig4_benchmark.png", fig4, width = 10, height = 7.6,
       dpi = 300, bg = "white")
message("wrote paper/figures/fig4_benchmark.png")
