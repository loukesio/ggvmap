# From the repository root: Rscript examples/linkedin/create_animation.R
# Render actual ggvmap output; all budget numbers are invented teaching values.
suppressPackageStartupMessages({
  devtools::load_all('.', quiet = TRUE)
  library(ggplot2)
  library(grid)
  library(sf)
})
out <- 'examples/linkedin'
dir.create(file.path(out, 'frames'), recursive = TRUE, showWarnings = FALSE)
budget <- data.frame(
  item = c('Field sampling', 'Sequencing', 'Data analysis', 'Equipment',
           'Travel', 'Training', 'Reporting', 'Other'),
  share = c(30, 25, 18, 12, 8, 6, .6, .4),
  group = c(rep('Research', 3), rep('Support', 5)))
stopifnot(sum(budget$share) == 100)
write.csv(budget, file.path(out, 'teaching_budget.csv'), row.names = FALSE)
cities <- sf::st_read(system.file('extdata', 'region-cities.geojson', package = 'ggvmap'), quiet = TRUE)
berlin <- cities[cities$city == 'Berlin', ]
totals <- tapply(budget$share, budget$group, sum)
steps <- list(
  list(title = 'Start with values', subtitle = 'A part-of-whole plot, built in R.', duration = 6,
       note = 'Invented budget: 100 units. Field sampling = 30 units = 30% of the whole.',
       detail = 'Each cell is one budget item. Gold = Research; sage = Support.',
       code = c('vm <- voronoi_map(', '  budget$share, labels = budget$item,',
                '  group = budget$group, clip = clip_circle(),',
                '  seed = 5, max_iter = 1000)',
                'ggvmap(vm, palette = "reading", show_labels = FALSE)')),
  list(title = 'Make labels readable', subtitle = 'Scale small labels. Wrap long names.', duration = 6,
       note = 'min_area = 0.009 hides labels below 0.9% of the plotted area.',
       detail = 'The 0.6% and 0.4% cells remain; only their labels are hidden.',
       code = c('ggvmap(vm, palette = "reading", label_col = "grey15",',
                '       autoscale = TRUE, min_area = 0.009,',
                '       wrap = 10, label_size = 6.75)')),
  list(title = 'Highlight one item', subtitle = 'Emphasise a cell without changing its area.', duration = 6,
       note = 'The data and geometry stay fixed; only the selected item gets visual emphasis.',
       detail = 'A darker label and group border make Research the focus.',
       code = c('ggvmap(vm, palette = "reading",',
                '       autoscale = TRUE, min_area = 0.009, wrap = 10,',
                '       label_col = c(`Field sampling` = "grey10"),',
                '       label_size = c(`Field sampling` = 8),',
                '       group_border_col = c(Research = "#333333"))')),
  list(title = 'Colour each item', subtitle = 'Switch the fill without changing the layout.', duration = 6,
       note = 'Colors now identify individual items; their areas and positions stay the same.',
       detail = 'Field sampling still has 30%. The next frame returns to group colors.',
       code = c('ggvmap(vm, fill_by = "label", palette = "reading",',
                '       label_col = "grey15", autoscale = TRUE,',
                '       min_area = 0.009, wrap = 10, label_size = 6.75)')),
  list(title = 'Add the arc ring', subtitle = 'Show each group\'s share around the circle.', duration = 7,
       note = 'Research = 73 of 100 budget units. Support = the remaining 27.',
       detail = 'Dark arcs and their labels identify the groups; percentages are group totals.',
       code = c('p <- ggvmap(vm, palette = "reading", label_col = "grey15",',
                '            autoscale = TRUE, min_area = 0.009,',
                '            wrap = 10, label_size = 6.75) |>',
                '  vm_add_ring(style = "arc", colors = "#333333",',
                '              values = TRUE, label_size = 6)',
                'p')),
  list(title = 'Change the ring', subtitle = 'Use a filled band when the arc should be stronger.', duration = 6,
       note = 'The same group totals remain visible, with a more graphic outer treatment.',
       detail = 'Arc and band are presentation choices; neither changes cell areas.',
       code = c('ggvmap(vm, palette = "reading", label_col = "grey15",',
                '       autoscale = TRUE, min_area = 0.009,',
                '       wrap = 10, label_size = 6.75) |>',
                '  vm_add_ring(style = "band", palette = "reading",',
                '              width = 0.11, label_size = 5.5)')),
  list(title = 'Put the values inside', subtitle = 'Keep the same layout; add another layer.', duration = 6,
       note = '30% means 30 of 100 invented budget units go to Field sampling.',
       detail = 'Item values appear in cells above 10%; ring values show group totals.',
       code = c('p |> vm_add_labels(', '  value = budget$share, suffix = "%",',
                '  col = "grey15", size = 4.8, min_area = 0.10,',
                '  nudge_y = -0.09', ')')),
  list(title = 'Choose another outline', subtitle = 'The same values, now inside a hexagon.', duration = 6,
       note = 'Changing the outline changes the arrangement, not the requested shares.',
       detail = 'Gold still means Research (73%); sage still means Support (27%).',
       code = c('hex <- voronoi_map(', '  budget$share, labels = budget$item, group = budget$group,',
                '  clip = clip_hexagon(), seed = 5, max_iter = 1000)',
                'ggvmap(hex, palette = "reading", label_col = "grey15",',
                '       autoscale = TRUE, min_area = 0.009,',
                '       wrap = 10, label_size = 6.75)')),
  list(title = 'NEW: fit a real outline', subtitle = 'vmap_region() handles bends, holes and islands.', duration = 8,
       note = 'The same group totals: Research 73%, Support 27%. This is not Berlin data.',
       detail = 'The boundary is real; cell positions are artificial. No outer ring for regions.',
       code = c('totals <- tapply(budget$share, budget$group, sum)',
                'region <- vmap_region(totals, berlin, labels = names(totals),',
                '                      crs = 25833, seed = 11)',
                'stopifnot(region$converged)',
                'ggvmap(region, palette = "reading", label_col = "grey15", label_size = 6.75) |>',
                '  vm_add_labels(value = totals, suffix = "%", col = "grey15", size = 6)')),
  list(title = 'Make it yours with ggvmap', subtitle = 'Values, labels, colours, layers, outlines.', duration = 6,
       note = 'Get the package and runnable examples: github.com/loukesio/ggvmap',
       detail = 'Palette: reading. This animation uses invented teaching values throughout.',
       code = c('remotes::install_github("loukesio/ggvmap")', '',
                'ggvmap(vm, palette = "reading", label_col = "grey15",',
                '       autoscale = TRUE, min_area = 0.009,',
                '       wrap = 10, label_size = 6.75) |>',
                '  vm_add_ring(style = "arc", colors = "#333333",',
                '              values = TRUE, label_size = 6)'))
)
# The installation line is displayed but not executed during rendering.
env <- environment()
plots <- list()
for (i in seq_along(steps)) {
  code <- steps[[i]]$code
  if (i == length(steps)) code <- code[-c(1, 2)]
  plots[[i]] <- eval(parse(text = paste(code, collapse = '\n')), envir = env)
}
stopifnot(vm$converged, hex$converged, region$converged)
layouts <- list(circle = vm, hexagon = hex, berlin = region)
checks <- do.call(rbind, lapply(names(layouts), function(nm) {
  z <- layouts[[nm]]
  data.frame(layout = nm, converged = z$converged,
             total_area_error_pp = 100 * sum(abs(z$sites$actual_area - z$sites$target_area)) / sum(z$sites$target_area))
}))
write.csv(checks, file.path(out, 'layout_checks.csv'), row.names = FALSE)
ink <- '#262626'; muted <- '#575D5D'; gold <- '#EFBC68'; sage <- '#919F89'
txt <- function(label, x, y, size, color = ink, face = 'plain', just = 'left', family = 'sans') {
  grid.text(label, x = x, y = y, just = just,
            gp = gpar(fontsize = size * 280 / 100, col = color, fontface = face, fontfamily = family))
}
for (i in seq_along(steps)) {
  st <- steps[[i]]
  ragg::agg_png(file.path(out, 'frames', sprintf('%02d.png', i)),
                width = 1440, height = 1680, res = 100, background = 'white')
  grid.newpage()
  txt('ggvmap', .055, .963, 10.5, face = 'bold')
  txt(sprintf('%02d / %02d', i, length(steps)), .945, .963, 8, muted, just = 'right')
  txt(st$title, .055, .918, 16, face = 'bold')
  txt(st$subtitle, .055, .882, 8.5, muted)
  # Labels and arcs come from the package, not from a drawn imitation.
  print(plots[[i]] + theme(plot.margin = margin(14, 18, 14, 18)),
        newpage = FALSE, vp = viewport(x = .5, y = .619, width = .88, height = .50))
  # Explicit keys explain every palette color, including the two hidden labels.
  if (st$title == 'Colour each item') {
    fills <- ggvmap:::.vm_palette(8, 'reading')
    keys <- c('Sampling', 'Sequencing', 'Analysis', 'Equipment',
              'Travel', 'Training', 'Reporting', 'Other')
    for (k in seq_along(keys)) {
      x <- .07 + ((k - 1) %% 4) * .224
      y <- .377 - ((k - 1) %/% 4) * .023
      grid.rect(x = x, y = y, width = .014, height = .010, gp = gpar(fill = fills[k], col = NA))
      txt(keys[k], x + .014, y, 6.1)
    }
  } else {
    grid.rect(x = .32, y = .363, width = .016, height = .012, gp = gpar(fill = gold, col = NA))
    txt('Research', .338, .363, 7.8)
    grid.rect(x = .57, y = .363, width = .016, height = .012, gp = gpar(fill = sage, col = NA))
    txt('Support', .588, .363, 7.8)
  }
  grid.rect(x = .5, y = .240, width = .89, height = .209, gp = gpar(fill = '#F5F5F2', col = NA))
  txt('R', .072, .325, 7, muted, face = 'bold')
  for (j in seq_along(st$code)) txt(st$code[j], .072, .299 - (j - 1) * .0255,
                                  6.35, family = 'Menlo')
  txt(st$note, .055, .108, 6.8, face = 'bold')
  txt(st$detail, .055, .082, 6.45, muted)
  txt('No numeric axes. Read cell areas and labels. Larger share does not mean better.',
      .055, .051, 6.1, muted)
  txt(if (st$title == 'NEW: fit a real outline') 'Invented budget; no uncertainty intervals. Berlin boundary: ALKIS / TSB, simplified 50 m.'
      else 'Invented teaching data; not research findings. No uncertainty intervals.',
      .055, .031, 5.8, muted)
  # Progress rule: one segment per teaching step; no additional data encoding.
  for (k in seq_along(steps)) grid.rect(x = .055 + (k - .5) * .89 / length(steps),
    y = .009, width = .89 / length(steps) - .006, height = .004,
    gp = gpar(fill = if (k <= i) gold else '#E6E8E4', col = NA))
  dev.off()
}
write.csv(data.frame(frame = sprintf('%02d.png', seq_along(steps)),
                     seconds = vapply(steps, `[[`, numeric(1), 'duration'),
                     title = vapply(steps, `[[`, character(1), 'title')),
          file.path(out, 'timing.csv'), row.names = FALSE)
# A complete runnable plotting example, without the animation's layout code.
demo <- c('# Run from the repository root after installing ggvmap from GitHub.',
          '# Invented budget for teaching; not research findings.',
          'library(ggvmap)', 'library(ggplot2)', 'library(sf)',
          'budget <- read.csv("examples/linkedin/teaching_budget.csv")',
          'cities <- st_read(system.file("extdata", "region-cities.geojson", package = "ggvmap"), quiet = TRUE)',
          'berlin <- cities[cities$city == "Berlin", ]')
for (i in seq_len(length(steps) - 1)) demo <- c(demo, '', paste0('# ', steps[[i]]$title), steps[[i]]$code)
writeLines(demo, file.path(out, 'demo.R'))
message('Rendered ', length(steps), ' frames; all three layouts converged.')
