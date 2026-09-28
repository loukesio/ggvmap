# ---------------------------------------------------------------------------
# Berlin repeat election, 12 February 2023 -- district vote-share treemaps
#
# Each of the 12 Bezirke keeps a simplified geographic outline and is subdivided
# into one Voronoi cell per party, cell area proportional to that party's
# Zweitstimmen in that district (official result, 12 Feb 2023).
#
# Uses the public ggvmap::vmap_region() function for concave district outlines,
# holes and disconnected pieces. Requires the feature checkout to be installed.
# The local geometry helpers below independently check and draw its output.
#
# Data
#   Votes:      https://wahlen-berlin.de/wahlen/Be2023/AFSPRAES/agh/DL/DL_BE_AGHBVV2023.xlsx
#               (precinct level; aggregating reproduces the published Berlin
#                totals exactly: 2,431,776 eligible / 1,529,558 voters / 62.9%)
#   Boundaries: https://tsb-opendata.s3.eu-central-1.amazonaws.com/bezirksgrenzen/bezirksgrenzen.geojson
#               (Geoportal Berlin, Bezirksgrenzen / ALKIS)
# ---------------------------------------------------------------------------

suppressMessages({
  library(sf); library(ggvmap); library(ggplot2)
  library(readxl); library(polyclip)
})

# Run from the repository root: Rscript examples/berlin_map_voronoi.R
stopifnot(dir.exists("examples"), file.exists("DESCRIPTION"))
out_dir <- "examples"
cache_dir <- file.path(out_dir, "berlin-data")
dir.create(cache_dir, showWarnings = FALSE)

## ---- 1. independent geometry helpers ------------------------------------
as_parts <- function(m) list(list(x = m[, 1], y = m[, 2]))

signed_part_area <- function(p) {
  x <- p$x; y <- p$y; n <- length(x); j <- c(n, seq_len(n - 1L))
  sum(x[j] * y - x * y[j]) / 2
}
part_area <- function(p) abs(signed_part_area(p))
part_centroid <- function(p) {
  x <- p$x; y <- p$y; n <- length(x); j <- c(n, seq_len(n - 1L))
  cr <- x[j] * y - x * y[j]
  a  <- sum(cr) / 2
  if (abs(a) < 1e-15) return(c(mean(x), mean(y)))
  c(sum((x[j] + x) * cr) / (6 * a), sum((y[j] + y) * cr) / (6 * a))
}
# polyclip returns positive outer rings and negative hole rings. Input regions
# are canonicalized through polyclip too, so the same convention applies.
parts_area <- function(ps) if (!length(ps)) 0 else sum(vapply(ps, signed_part_area, numeric(1)))
parts_centroid <- function(ps, fallback) {
  if (!length(ps)) return(fallback)
  a <- vapply(ps, signed_part_area, numeric(1))
  if (sum(a) < 1e-15) return(fallback)
  cs <- vapply(ps, part_centroid, numeric(2))
  c(sum(cs[1, ] * a) / sum(a), sum(cs[2, ] * a) / sum(a))
}

# Convert canonical rings to sf geometry for independent area checks and labels.
parts_sf <- function(ps) {
  a <- vapply(ps, signed_part_area, numeric(1))
  polygons <- st_sfc(lapply(ps, function(p) {
    m <- cbind(p$x, p$y)
    st_polygon(list(rbind(m, m[1, ])))
  }))
  outer <- st_union(polygons[a > 0])
  if (any(a < 0)) outer <- st_difference(outer, st_union(polygons[a < 0]))
  outer
}

# even-odd point-in-region across all rings (handles holes and exclaves)
in_region <- function(pt, region) {
  inside <- FALSE
  for (p in region) {
    x <- p$x; y <- p$y; n <- length(x); j <- c(n, seq_len(n - 1L))
    cross <- ((y > pt[2]) != (y[j] > pt[2])) &
      (pt[1] < (x[j] - x) * (pt[2] - y) / (y[j] - y + 1e-300) + x)
    if (sum(cross) %% 2 == 1) inside <- !inside
  }
  inside
}

## ---- 2. votes -------------------------------------------------------------
xlsx <- file.path(cache_dir, "DL_BE_AGHBVV2023.xlsx")
if (!file.exists(xlsx)) download.file(
  "https://wahlen-berlin.de/wahlen/Be2023/AFSPRAES/agh/DL/DL_BE_AGHBVV2023.xlsx",
  xlsx, mode = "wb", quiet = TRUE)

x <- as.data.frame(read_excel(xlsx, sheet = "AGH_W2"))
parties <- c("CDU", "SPD", "GRÜNE", "DIE LINKE", "AfD", "FDP")
cols    <- c("Wahlberechtigte insgesamt", "Wählende", "Gültige Stimmen", parties)
for (n in cols) x[[n]] <- suppressWarnings(as.numeric(x[[n]]))
stopifnot(!anyNA(x[cols]), !anyDuplicated(x$Adresse),
          all(x$Stimmart == "Zweitstimme"),
          all(x$Wahlbezirksart %in% c("W", "B")))

agg <- aggregate(x[cols], by = list(Bezirk = x$Bezirksname), FUN = sum)
names(agg)[2:4] <- c("wahlberechtigte", "waehlende", "gueltige")
agg$sonstige <- agg$gueltige - rowSums(agg[parties])
agg$turnout  <- 100 * agg$waehlende / agg$wahlberechtigte
stopifnot(nrow(agg) == 12L, all(agg$sonstige >= 0),
          sum(agg$wahlberechtigte) == 2431776,
          sum(agg$waehlende) == 1529558, sum(agg$gueltige) == 1516860,
          all(colSums(agg[parties]) == c(428228, 279017, 278964, 185119, 137871, 70416)))

long <- do.call(rbind, lapply(c(parties, "Sonstige"), function(p) {
  v <- if (p == "Sonstige") agg$sonstige else agg[[p]]
  data.frame(bezirk = agg$Bezirk, party = p, votes = v, stringsAsFactors = FALSE)
}))
long$party[long$party == "DIE LINKE"] <- "Linke"
long$party[long$party == "GRÜNE"]     <- "Grüne"

party_col <- c(CDU = "#16171A", SPD = "#E3000F", "Grüne" = "#1FA02C",
               Linke = "#BE3075", AfD = "#009EE0", FDP = "#FFCC00",
               Sonstige = "#B9BDC4")
long$party <- factor(long$party, levels = names(party_col))

## ---- 3. boundaries --------------------------------------------------------
gj <- file.path(cache_dir, "bezirksgrenzen.geojson")
if (!file.exists(gj)) download.file(
  "https://tsb-opendata.s3.eu-central-1.amazonaws.com/bezirksgrenzen/bezirksgrenzen.geojson",
  gj, mode = "wb", quiet = TRUE)

b_raw <- st_read(gj, quiet = TRUE) |> st_transform(25833)
b <- b_raw |>
  st_simplify(dTolerance = 100, preserveTopology = TRUE)
stopifnot(nrow(b) == 12L, !anyDuplicated(b$Gemeinde_name), all(st_is_valid(b)),
          setequal(b$Gemeinde_name, agg$Bezirk))
bb <- st_bbox(b); sc <- max(bb["xmax"] - bb["xmin"], bb["ymax"] - bb["ymin"])
nx <- function(v) (v - bb["xmin"]) / sc
ny <- function(v) (v - bb["ymin"]) / sc

to_region <- function(g) {
  ps <- st_cast(st_geometry(g), "POLYGON", warn = FALSE)
  rings <- unlist(lapply(ps, function(p) lapply(p, function(m) {
    m <- m[-nrow(m), 1:2, drop = FALSE] # remove closing vertex only
    list(x = nx(m[, 1]), y = ny(m[, 2]))
  })), recursive = FALSE)
  # Canonical ring orientation; preserve separate holes and outer rings.
  polyclip::polyclip(rings, rings, op = "union")
}

## ---- 4. one treemap per district -----------------------------------------
cell_df <- list(); lab_df <- list(); solutions <- list(); diagnostics <- list()
for (nm in sort(unique(long$bezirk))) {
  reg <- to_region(b[b$Gemeinde_name == nm, ])
  dd  <- long[long$bezirk == nm, ]; dd <- dd[order(dd$party), ]
  r <- ggvmap::vmap_region(dd$votes, reg, labels = as.character(dd$party),
                   seed = 11, max_iter = 600, convergence_ratio = 0.002)
  cat(sprintf("%-27s parts=%d conv=%-5s it=%3d err=%.3f%%\n",
              nm, length(reg), r$converged, r$iterations, 100 * r$convergence))
  if (!r$converged) stop("Area tolerance was not met for ", nm)
  solutions[[nm]] <- r
  diagnostics[[nm]] <- data.frame(
    bezirk = nm, converged = r$converged, iterations = r$iterations,
    total_absolute_error_pp = 100 * r$convergence,
    max_party_error_pp = 100 * max(abs(r$sites$actual_area / r$total_area - dd$votes / sum(dd$votes))))
  for (i in seq_along(r$cells)) for (k in seq_along(r$cells[[i]])) {
    p <- r$cells[[i]][[k]]
    cell_df[[length(cell_df) + 1]] <- data.frame(
      gid = paste(nm, i, sep = "_"), ring = k, bezirk = nm, party = r$sites$label[i],
      x = p$x, y = p$y)
  }
  for (i in seq_along(r$cells)) {
    if (!length(r$cells[[i]])) next
    pieces <- st_cast(parts_sf(r$cells[[i]]), "POLYGON", warn = FALSE)
    big <- pieces[which.max(st_area(pieces))]
    ct <- st_coordinates(st_point_on_surface(big))[1, ]
    lab_df[[length(lab_df) + 1]] <- data.frame(
      bezirk = nm, party = r$sites$label[i], x = ct[1], y = ct[2],
      frac = r$sites$actual_area[i] / r$total_area)
  }
}
cell_df <- do.call(rbind, cell_df); lab_df <- do.call(rbind, lab_df)
cell_df$party <- factor(cell_df$party, levels = names(party_col))

bez <- st_geometry(b); bpts <- st_point_on_surface(bez)
bout <- do.call(rbind, lapply(seq_along(bez), function(i) {
  rings <- to_region(b[i, ])
  do.call(rbind, lapply(seq_along(rings), function(k) {
    data.frame(gid = i, ring = k, x = rings[[k]]$x, y = rings[[k]]$y)
  }))
}))
bn <- data.frame(bezirk = b$Gemeinde_name,
                 x = nx(st_coordinates(bpts)[, 1]),
                 y = ny(st_coordinates(bpts)[, 2]))
bn <- merge(bn, agg[c("Bezirk", "turnout")], by.x = "bezirk", by.y = "Bezirk")

## ---- 5. plot --------------------------------------------------------------
lab <- lab_df[lab_df$frac >= 0.10, ]
# Approximate text footprints at this export size; omit names that would cross
# their cell boundary. The legend and companion table retain every category.
fits_cell <- vapply(seq_len(nrow(lab)), function(i) {
  r <- solutions[[lab$bezirk[i]]]
  cell <- r$cells[[match(lab$party[i], r$sites$label)]]
  dx <- 0.0045 * nchar(lab$party[i])
  points <- expand.grid(x = lab$x[i] + c(-dx, 0, dx),
                        y = lab$y[i] + c(-0.010, 0, 0.010))
  all(vapply(seq_len(nrow(points)), function(j) {
    in_region(unlist(points[j, ]), cell)
  }, logical(1)))
}, logical(1))
lab <- lab[fits_cell, ]
lab$col <- ifelse(lab$party %in% c("FDP", "Sonstige"), "#26292E", "white")
# A numbered key keeps long district names from covering vote-share cells.
bn$id <- as.integer(b$Gemeinde_schluessel[match(bn$bezirk, b$Gemeinde_name)])
bn <- bn[order(bn$id), ]
bn$key_y <- seq(0.76, 0.12, length.out = nrow(bn))
bn$txt <- sprintf("%02d  %s\n      %.0f%% turnout", bn$id, bn$bezirk, bn$turnout)
# Leave clear space around the numbered district markers.
clear_of_markers <- vapply(seq_len(nrow(lab)), function(i) {
  all((bn$x - lab$x[i])^2 + (bn$y - lab$y[i])^2 > 0.027^2)
}, logical(1))
lab <- lab[clear_of_markers, ]

p <- ggplot() +
  geom_polygon(data = cell_df, aes(x, y, group = gid, subgroup = ring, fill = party),
               rule = "evenodd", colour = "white", linewidth = 0.30) +
  geom_polygon(data = bout, aes(x, y, group = gid, subgroup = ring), rule = "evenodd",
               fill = NA, colour = "white", linewidth = 1.9) +
  geom_polygon(data = bout, aes(x, y, group = gid, subgroup = ring), rule = "evenodd",
               fill = NA, colour = "grey12", linewidth = 0.55) +
  geom_text(data = lab, aes(x, y, label = party), colour = lab$col,
            size = 2.45, fontface = "bold", check_overlap = TRUE) +
  geom_point(data = bn, aes(x, y), shape = 21, fill = "white",
             colour = "grey15", stroke = 0.4, size = 5.8) +
  geom_text(data = bn, aes(x, y, label = sprintf("%02d", id)),
            size = 2.6, fontface = "bold") +
  geom_text(data = bn, aes(x = 1.07, y = key_y, label = txt),
            hjust = 0, size = 3.1, lineheight = 1.15, colour = "grey15") +
  annotate("text", x = 1.07, y = 0.815, label = "District / turnout",
           hjust = 0, size = 3.6, fontface = "bold") +
  scale_fill_manual(values = party_col, breaks = names(party_col)) +
  expand_limits(x = c(-0.015, 1.65), y = c(-0.015, 0.84)) +
  coord_equal(clip = "off") +
  theme_void() +
  labs(title = "Berlin 2023 — district vote shares",
       subtitle = "Area within each district shows its share of valid party-list votes (12 February 2023).\nParty positions are artificial, not voter locations. District sizes show geography, not numbers of voters.",
       caption = "Votes: Berlin election authority · 2,431,776 eligible · 62.9% turnout · Sonstige = other parties\nBoundaries: ALKIS / TSB GeoJSON mirror, simplified by 100 m; boundary date unverified\nggvmap::vmap_region() with polyclip · See the companion chart for exact comparisons") +
  theme(
    plot.title    = element_text(face = "bold", size = 22, hjust = .5, margin = margin(b = 6)),
    plot.subtitle = element_text(size = 11, colour = "grey30", hjust = .5, lineheight = 1.35,
                                 margin = margin(b = 4)),
    plot.caption  = element_text(size = 9, colour = "grey45", hjust = .5, lineheight = 1.45,
                                 margin = margin(t = 6)),
    legend.position = "bottom", legend.title = element_blank(),
    legend.text = element_text(size = 12.5), legend.key.size = unit(15, "pt"),
    legend.margin = margin(t = 0, b = 0),
    plot.margin = margin(16, 14, 12, 14),
    plot.background = element_rect(fill = "white", colour = NA))

ggsave(file.path(out_dir, "berlin_map_voronoi_reviewed.png"), p,
       width = 13, height = 8.5, dpi = 300, bg = "white")

# Equal-width district bars give readers a common scale for comparisons.
long$share <- long$votes / agg$gueltige[match(long$bezirk, agg$Bezirk)]
bars <- ggplot(long, aes(share, factor(bezirk, levels = rev(sort(unique(bezirk)))), fill = party)) +
  geom_col(position = position_stack(reverse = TRUE), width = 0.75) +
  geom_text(aes(label = sprintf("%.1f", 100 * share)),
            position = position_stack(vjust = 0.5, reverse = TRUE), size = 3,
            colour = ifelse(long$party %in% c("FDP", "Sonstige"), "#26292E", "white")) +
  scale_fill_manual(values = party_col, breaks = names(party_col)) +
  guides(fill = guide_legend(nrow = 1)) +
  scale_x_continuous(labels = function(x) paste0(100 * x, "%"), expand = c(0, 0)) +
  labs(title = "Berlin 2023 — compare district vote shares",
       subtitle = "Valid party-list votes, 12 February 2023; labels are percentages. Each row totals 100% before rounding.",
       x = NULL, y = NULL, fill = NULL,
       caption = "Source: Berlin election authority, AGH_W2 · Sonstige = all other parties · Same data as the map") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        legend.position = "bottom", plot.title = element_text(face = "bold"),
        plot.margin = margin(10, 22, 10, 10))
ggsave(file.path(out_dir, "berlin_vote_shares.png"), bars, width = 12, height = 6.5, dpi = 200, bg = "white")
write.csv(long, file.path(out_dir, "berlin_vote_shares.csv"), row.names = FALSE)
write.csv(do.call(rbind, diagnostics), file.path(out_dir, "berlin_map_diagnostics.csv"), row.names = FALSE)
write.csv(data.frame(file = basename(c(xlsx, gj)), md5 = unname(tools::md5sum(c(xlsx, gj)))),
          file.path(out_dir, "berlin_source_checksums.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "berlin_session_info.txt"))
cat("Written reviewed map, companion chart, vote shares and diagnostics to examples/\n")
