# Run from the repository root after installing ggvmap from GitHub.
# Invented budget for teaching; not research findings.
library(ggvmap)
library(ggplot2)
library(sf)
budget <- read.csv("examples/linkedin/teaching_budget.csv")
cities <- st_read(system.file("extdata", "region-cities.geojson", package = "ggvmap"), quiet = TRUE)
berlin <- cities[cities$city == "Berlin", ]

# Start with values
vm <- voronoi_map(
  budget$share, labels = budget$item,
  group = budget$group, clip = clip_circle(),
  seed = 5, max_iter = 1000)
ggvmap(vm, palette = "reading", show_labels = FALSE)

# Make labels readable
ggvmap(vm, palette = "reading", label_col = "grey15",
       autoscale = TRUE, min_area = 0.009,
       wrap = 10, label_size = 6.75)

# Highlight one item
ggvmap(vm, palette = "reading",
       autoscale = TRUE, min_area = 0.009, wrap = 10,
       label_col = c(`Field sampling` = "grey10"),
       label_size = c(`Field sampling` = 8),
       group_border_col = c(Research = "#333333"))

# Colour each item
ggvmap(vm, fill_by = "label", palette = "reading",
       label_col = "grey15", autoscale = TRUE,
       min_area = 0.009, wrap = 10, label_size = 6.75)

# Add the arc ring
p <- ggvmap(vm, palette = "reading", label_col = "grey15",
            autoscale = TRUE, min_area = 0.009,
            wrap = 10, label_size = 6.75) |>
  vm_add_ring(style = "arc", colors = "#333333",
              values = TRUE, label_size = 6)
p

# Change the ring
ggvmap(vm, palette = "reading", label_col = "grey15",
       autoscale = TRUE, min_area = 0.009,
       wrap = 10, label_size = 6.75) |>
  vm_add_ring(style = "band", palette = "reading",
              width = 0.11, label_size = 5.5)

# Put the values inside
p |> vm_add_labels(
  value = budget$share, suffix = "%",
  col = "grey15", size = 4.8, min_area = 0.10,
  nudge_y = -0.09
)

# Choose another outline
hex <- voronoi_map(
  budget$share, labels = budget$item, group = budget$group,
  clip = clip_hexagon(), seed = 5, max_iter = 1000)
ggvmap(hex, palette = "reading", label_col = "grey15",
       autoscale = TRUE, min_area = 0.009,
       wrap = 10, label_size = 6.75)

# NEW: fit a real outline
totals <- tapply(budget$share, budget$group, sum)
region <- vmap_region(totals, berlin, labels = names(totals),
                      crs = 25833, seed = 11)
stopifnot(region$converged)
ggvmap(region, palette = "reading", label_col = "grey15", label_size = 6.75) |>
  vm_add_labels(value = totals, suffix = "%", col = "grey15", size = 6)
