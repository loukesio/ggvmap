# Run from the repository root. Rebuilds the example, then uses sf/GEOS to
# check areas and coverage independently of the solver's shoelace calculations.
source("examples/berlin_map_voronoi.R")

# A square with an off-centre hole: subtract its area AND first moments.
outer <- list(x = c(0, 4, 4, 0), y = c(0, 0, 4, 4))
hole <- list(x = c(1, 2, 2, 1), y = c(1, 1, 2, 2))
donut <- polyclip::polyclip(list(outer, hole), list(outer), "intersection")
stopifnot(abs(parts_area(donut) - 15) < 1e-6,
          max(abs(parts_centroid(donut, c(NA, NA)) - rep(30.5 / 15, 2))) < 1e-6,
          !in_region(c(1.5, 1.5), donut), in_region(c(3, 3), donut))

# A clipped U has two pieces. Bridging edges cancel in signed integrals:
# this disproves the original blanket claim that bridges corrupt shoelace area.
u <- cbind(c(0, 3, 3, 2, 2, 1, 1, 0), c(0, 0, 3, 3, 1, 1, 3, 3))
clipped <- ggvmap:::clip_polygon_halfplane(u, 0, -1, -2)
stopifnot(abs(ggvmap:::polygon_area(clipped) - 2) < 1e-12,
          max(abs(ggvmap:::polygon_centroid(clipped) - c(1.5, 2.5))) < 1e-12,
          !ggvmap:::point_in_polygon(c(0.5, 2.5), u),
          in_region(c(0.5, 2.5), as_parts(u)))
two_parts <- polyclip::polyclip(as_parts(u),
                              list(list(x = c(0, 3, 3, 0), y = c(2, 2, 3, 3))),
                              "intersection")
stopifnot(length(two_parts) == 2L, abs(parts_area(two_parts) - 2) < 1e-6)

checks <- lapply(names(solutions), function(nm) {
  r <- solutions[[nm]]
  district <- b[b$Gemeinde_name == nm, ]
  # Compare to the original sf boundary directly, not to the same ring converter.
  region <- (st_geometry(district) - c(bb["xmin"], bb["ymin"])) / as.numeric(sc)
  region <- st_set_crs(region, NA)
  cells <- do.call(c, lapply(r$cells, parts_sf))
  stopifnot(all(st_is_valid(cells)))
  merged <- st_union(cells)
  total <- as.numeric(st_area(region))
  measured <- as.numeric(st_area(cells))
  target <- long$share[match(paste(nm, r$sites$label), paste(long$bezirk, long$party))]
  union_area <- as.numeric(st_area(merged))
  mismatch <- sum(as.numeric(st_area(st_sym_difference(region, merged)))) / total
  overlap <- abs(sum(measured) - union_area) / total
  error <- sum(abs(measured / total - target))
  stopifnot(abs(total - r$total_area) / total < 1e-7,
            max(abs(measured - r$sites$actual_area)) / total < 1e-7,
            mismatch < 1e-7, overlap < 1e-7, error < 0.002)
  raw_area <- as.numeric(st_area(b_raw[b_raw$Gemeinde_name == nm, ]))
  simple_area <- as.numeric(st_area(district))
  data.frame(bezirk = nm, total_absolute_error_pp = 100 * error,
             max_party_error_pp = 100 * max(abs(measured / total - target)),
             coverage_difference_fraction = mismatch, overlap_fraction = overlap,
             simplification_area_change_pct = 100 * (simple_area / raw_area - 1))
})
checks <- do.call(rbind, checks)
write.csv(checks, "examples/berlin_geometry_checks.csv", row.names = FALSE)
print(checks, row.names = FALSE)
cat("PASS: official totals, hole/multipart fixtures, signed-integral counterexample,",
    "and independent sf coverage/area checks for all 12 districts.\n")
