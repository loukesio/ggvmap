# Build the clean country-first promo GIF. No code panels are drawn.
suppressPackageStartupMessages({
  devtools::load_all('.', quiet = TRUE)
  library(ggplot2)
  library(grid)
})

out <- 'examples/linkedin'
dir.create(file.path(out, 'country_frames'), recursive = TRUE, showWarnings = FALSE)
data(freshwater)
countries <- freshwater

vm <- voronoi_map(
  countries$share,
  labels = countries$country,
  group = countries$region,
  clip = clip_circle(),
  seed = 42,
  max_iter = 1000
)
stopifnot(vm$converged)

# Make the Brazil-only flag reproducible offline after the bundled asset exists.
flag_cache_dir <- file.path(tempdir(), 'ggvmap-flags')
dir.create(flag_cache_dir, recursive = TRUE, showWarnings = FALSE)
file.copy(file.path(out, 'flags', 'br.png'), flag_cache_dir,
          overwrite = TRUE)

base <- function() {
  ggvmap(vm, palette = 'reading', label_col = 'grey15',
         autoscale = TRUE, min_area = 0.009, wrap = 10, label_size = 6)
}
with_values <- function() {
  base() |>
    vm_add_labels(value = countries$share, suffix = '%', size = 3.6,
                  min_area = 0.009)
}
with_arc <- function() {
  with_values() |>
    vm_add_ring(style = 'arc', colors = '#333333', values = TRUE,
                label_size = 5.5)
}

plots <- list(
  base(),
  with_values(),
  with_arc(),
  ggvmap(vm, palette = 'reading', label_col = 'grey15',
         label_size = c(Brazil = 8), fontface = c(Brazil = 'bold'),
         autoscale = TRUE, min_area = 0.009, wrap = 10) |>
    vm_add_labels(value = countries$share, suffix = '%', size = 3.6,
                  min_area = 0.009),
  with_arc() |>
    vm_add_flags(country = 'Brazil', cells = 'Brazil', method = 'url',
                 cache = TRUE, size = 0.07, nudge_y = 0.05),
  with_values() |>
    vm_add_ring(style = 'band', palette = 'reading', width = 0.11,
                label_size = 5.5)
)

ink <- '#262626'; muted <- '#575D5D'
txt <- function(label, x, y, size, color = ink, face = 'plain', just = 'left') {
  grid.text(label, x = x, y = y, just = just,
            gp = gpar(fontsize = size * 280 / 100, col = color,
                      fontface = face, fontfamily = 'sans'))
}

for (i in seq_along(plots)) {
  ragg::agg_png(file.path(out, 'country_frames', sprintf('%02d.png', i)),
                width = 2400, height = 1800, res = 150, background = 'white')
  grid.newpage()
  print(plots[[i]] + theme(plot.margin = margin(14, 18, 14, 18)),
        newpage = FALSE, vp = viewport(x = .5, y = .53, width = .97, height = .92))
  txt('Freshwater shares · 2022 · FAO Aquastat / World Bank',
      .5, .025, 8.2, muted, just = 'center')
  dev.off()
}

message('Rendered ', length(plots), ' clean country promo frames.')
