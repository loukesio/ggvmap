# Build the clean country-first promo GIF. No code panels are drawn.
suppressPackageStartupMessages({
  devtools::load_all('.', quiet = TRUE)
  library(ggplot2)
  library(grid)
  library(sf)
})

out <- 'examples/linkedin'
dir.create(file.path(out, 'country_frames'), recursive = TRUE, showWarnings = FALSE)
data(freshwater)
top10 <- freshwater[!grepl('^Rest of|Middle East', freshwater$country), ][1:10, ]

vm <- voronoi_map(
  top10$share,
  labels = top10$country,
  group = top10$region,
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
         autoscale = TRUE, min_area = 0.004, wrap = 12, label_size = 5)
}
with_values <- function() {
  base() |>
    vm_add_labels(value = top10$share, suffix = '%', size = 3.2,
                  min_area = 0.006)
}
with_arc <- function() {
  with_values() |>
    vm_add_ring(style = 'arc', colors = '#333333', values = TRUE,
                label_size = 4)
}

plots <- list(
  base(),
  with_values(),
  with_arc(),
  ggvmap(vm, palette = 'reading', label_col = 'grey15',
         label_size = c(Brazil = 7), fontface = c(Brazil = 'bold'),
         autoscale = TRUE, min_area = 0.004, wrap = 12) |>
    vm_add_labels(value = top10$share, suffix = '%', size = 3.2,
                  min_area = 0.006),
  with_arc() |>
    vm_add_flags(country = 'Brazil', cells = 'Brazil', method = 'url',
                 cache = TRUE, size = 0.07, nudge_y = 0.05),
  with_values() |>
    vm_add_ring(style = 'band', palette = 'reading', width = 0.11,
                label_size = 4.5),
  NULL
)

cities <- sf::st_read(system.file('extdata', 'region-cities.geojson',
                                   package = 'ggvmap'), quiet = TRUE)
berlin <- cities[cities$city == 'Berlin', ]
city_vm <- vmap_region(c(40, 30, 20, 10), berlin,
                       labels = c('A', 'B', 'C', 'D'),
                       crs = 25833, seed = 11)
stopifnot(city_vm$converged)
plots[[7]] <- ggvmap(city_vm, palette = 'reading', label_col = 'grey15',
                     label_size = 5) |>
  vm_add_labels(value = c(40, 30, 20, 10), suffix = '%', size = 3.5)

titles <- c('All countries', 'Add values', 'Add the arc ring',
            'Highlight Brazil', 'Flag Brazil only', 'Change the ring',
            'Then fit a real city outline')
subtitles <- c(
  'Ten countries, grouped by region.',
  'Cell area and labels carry the country shares.',
  'Regional totals sit outside the map.',
  'One country can be made the visual focus.',
  'The flag belongs to Brazil; every country remains visible.',
  'A filled band changes the style, not the data.',
  'The same grammar extends to a real Berlin boundary.'
)

ink <- '#262626'; muted <- '#575D5D'
txt <- function(label, x, y, size, color = ink, face = 'plain', just = 'left') {
  grid.text(label, x = x, y = y, just = just,
            gp = gpar(fontsize = size * 280 / 100, col = color,
                      fontface = face, fontfamily = 'sans'))
}

for (i in seq_along(plots)) {
  ragg::agg_png(file.path(out, 'country_frames', sprintf('%02d.png', i)),
                width = 1440, height = 1100, res = 100, background = 'white')
  grid.newpage()
  txt('ggvmap', .055, .95, 10.5, face = 'bold')
  txt(sprintf('%02d / %02d', i, length(plots)), .945, .95, 8, muted, just = 'right')
  txt(titles[i], .055, .90, 16, face = 'bold')
  txt(subtitles[i], .055, .825, 8.5, muted)
  print(plots[[i]] + theme(plot.margin = margin(14, 18, 14, 18)),
        newpage = FALSE, vp = viewport(x = .5, y = .49, width = .88, height = .65))
  txt(if (i < 7) 'Freshwater share by country · 2022'
      else 'Invented teaching values fitted inside the real Berlin outline',
      .5, .075, 7.2, muted, just = 'center')
  txt(if (i < 7) 'Source: bundled freshwater dataset · FAO Aquastat via World Bank'
      else 'Boundary: Berlin ALKIS snapshot · positions are arranged by the solver',
      .5, .035, 5.8, muted, just = 'center')
  dev.off()
}

message('Rendered ', length(plots), ' clean country promo frames.')
