# Alternative views of the verified 12 February 2023 Berlin party-list votes.
# Run from the repository root: Rscript examples/berlin_vote_alternatives.R
# If the input CSV is absent, first run examples/berlin_map_voronoi.R.
# Requires only ggplot2. No geographic solver is involved in these charts.
suppressPackageStartupMessages(library(ggplot2))

input <- "examples/berlin_vote_shares.csv"
if (!file.exists(input)) stop("First run Rscript examples/berlin_map_voronoi.R")
d <- read.csv(input, stringsAsFactors = FALSE)
palette <- c(CDU = "#16171A", SPD = "#E3000F", "Grüne" = "#1FA02C",
             Linke = "#BE3075", AfD = "#009EE0", FDP = "#FFCC00",
             Sonstige = "#B9BDC4")
parties <- names(palette)
districts <- sort(unique(d$bezirk))
stopifnot(nrow(d) == 84L, length(districts) == 12L,
          setequal(d$party, parties), !anyNA(d), all(d$votes > 0),
          !anyDuplicated(d[c("bezirk", "party")]))
district_votes <- tapply(d$votes, d$bezirk, sum)[districts]
party_votes <- tapply(d$votes, d$party, sum)[parties]
total <- sum(d$votes)
stopifnot(total == 1516860,
          all(party_votes == c(428228, 279017, 278964, 185119, 137871, 70416, 137245)),
          max(abs(d$share - d$votes / district_votes[d$bezirk])) < 1e-12)
d$party <- factor(d$party, levels = parties)
d$district_pct <- 100 * d$share
d$berlin_pct <- 100 * as.numeric(party_votes[as.character(d$party)]) / total
d$difference_pp <- d$district_pct - d$berlin_pct
fmt_votes <- function(x) format(x, big.mark = ",", scientific = FALSE, trim = TRUE)

source_note <- "Source: Berlin election authority, AGH_W2 · Valid party-list votes · Sonstige = all other parties"

# ---- Sankey: district totals on the left, party totals on the right --------
# All ribbon and node heights share one scale: fraction of Berlin's valid votes.
# Both sides use the same total gap space, split between their respective nodes.
nodes <- function(weights, labels) {
  height <- as.numeric(weights) / total
  gap <- 0.14 / (length(height) - 1)
  top <- c(0, head(cumsum(height + gap), -1))
  data.frame(label = labels, top = top, bottom = top + height,
             mid = top + height / 2, votes = as.numeric(weights))
}
left <- nodes(district_votes, districts)
right <- nodes(party_votes, parties)
flows <- d[order(match(d$bezirk, districts), d$party), ]
flows$height <- flows$votes / total
flows$left_top <- flows$right_top <- NA_real_
for (district in districts) {
  ids <- which(flows$bezirk == district)
  flows$left_top[ids] <- left$top[match(district, left$label)] +
    c(0, head(cumsum(flows$height[ids]), -1))
}
for (party in parties) {
  ids <- which(flows$party == party)
  flows$right_top[ids] <- right$top[match(party, right$label)] +
    c(0, head(cumsum(flows$height[ids]), -1))
}
# Verify ribbons exactly fill each node, without overlaps or gaps at the nodes.
for (district in districts) {
  f <- flows[flows$bezirk == district, ]
  node <- left[left$label == district, ]
  stopifnot(abs(min(f$left_top) - node$top) < 1e-12,
            abs(max(f$left_top + f$height) - node$bottom) < 1e-12)
}
for (party in parties) {
  f <- flows[flows$party == party, ]
  node <- right[right$label == party, ]
  stopifnot(abs(min(f$right_top) - node$top) < 1e-12,
            abs(max(f$right_top + f$height) - node$bottom) < 1e-12)
}
t <- seq(0, 1, length.out = 100)
ease <- 3 * t^2 - 2 * t^3
ribbons <- do.call(rbind, lapply(seq_len(nrow(flows)), function(i) {
  f <- flows[i, ]
  upper <- f$left_top + ease * (f$right_top - f$left_top)
  data.frame(id = i, party = f$party,
             x = c(t, rev(t)), y = -c(upper, rev(upper + f$height)))
}))
left$text <- paste0(left$label, "\n", fmt_votes(left$votes), " votes")
right$text <- paste0(right$label, "\n", fmt_votes(right$votes), " · ",
                     sprintf("%.1f%%", 100 * right$votes / total))
sankey <- ggplot() +
  geom_polygon(data = ribbons, aes(x, y, group = id, fill = party),
               alpha = 0.48, colour = NA) +
  geom_rect(data = left, aes(xmin = -0.018, xmax = 0, ymin = -bottom, ymax = -top),
            fill = "#45494E", colour = NA) +
  geom_rect(data = right, aes(xmin = 1, xmax = 1.025, ymin = -bottom, ymax = -top, fill = label),
            colour = NA) +
  geom_text(data = left, aes(x = -0.04, y = -mid, label = text),
            hjust = 1, size = 3.3, lineheight = 1.15, colour = "#292D32") +
  geom_text(data = right, aes(x = 1.05, y = -mid, label = text),
            hjust = 0, size = 3.8, lineheight = 1.2, colour = "#292D32") +
  annotate("text", x = -0.04, y = 0.045, label = "DISTRICT · VOTES", hjust = 1,
           size = 3.3, fontface = "bold", colour = "#545A61") +
  annotate("text", x = 1.05, y = 0.045, label = "PARTY · BERLIN TOTAL", hjust = 0,
           size = 3.3, fontface = "bold", colour = "#545A61") +
  scale_fill_manual(values = palette, guide = "none") +
  scale_x_continuous(limits = c(-0.60, 1.46), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-1.16, 0.08), expand = c(0, 0)) +
  labs(title = "Berlin 2023 — where each party’s votes came from",
       subtitle = "Ribbon width shows the number of votes, not district vote share.\nOne election, 12 February 2023: these connections do not show voters changing parties.",
       caption = paste0(source_note, "\n1,516,860 valid votes · Both sides use the same count scale")) +
  theme_void(base_size = 12) +
  theme(plot.title = element_text(size = 23, face = "bold", margin = margin(b = 10)),
        plot.subtitle = element_text(size = 12, lineheight = 1.3, colour = "#545A61", margin = margin(b = 18)),
        plot.caption = element_text(size = 10, colour = "#545A61", hjust = 0, lineheight = 1.3, margin = margin(t = 14)),
        plot.margin = margin(20, 20, 16, 20), plot.background = element_rect(fill = "white", colour = NA))

# ---- Dumbbells: district share compared with the Berlin-wide benchmark ----
# The Berlin rate is computed from summed votes, never a mean of district rates.
# The hollow circle is a descriptive benchmark, not an earlier election.
d$district <- factor(d$bezirk, levels = rev(districts))
panel_labels <- setNames(paste0(parties, "\nBerlin: ", sprintf("%.1f%%", 100 * party_votes / total)), parties)
dumbbell <- ggplot(d, aes(y = district)) +
  geom_vline(xintercept = seq(0, 40, 10), colour = "#E9ECEF", linewidth = 0.35) +
  geom_segment(aes(x = berlin_pct, xend = district_pct, yend = district),
               colour = "#8A919A", linewidth = 0.7) +
  geom_point(aes(x = berlin_pct, shape = "Berlin overall"),
             size = 2.5, stroke = 0.7, fill = "white", colour = "#45494E") +
  geom_point(aes(x = district_pct, fill = party, shape = "District"),
             size = 2.8, stroke = 0.4, colour = "#45494E") +
  geom_text(aes(x = district_pct, label = sprintf("%.1f", district_pct)),
            nudge_y = 0.29, size = 2.55, colour = "#33383D") +
  facet_wrap(~party, ncol = 4, labeller = labeller(party = panel_labels)) +
  scale_fill_manual(values = palette, guide = "none") +
  scale_shape_manual(NULL, values = c("Berlin overall" = 21, District = 21)) +
  guides(shape = guide_legend(override.aes = list(fill = c("white", "#45494E"), size = 3))) +
  scale_x_continuous(limits = c(0, 45), breaks = seq(0, 40, 10),
                     labels = function(x) paste0(x, "%"), expand = c(0.025, 0)) +
  scale_y_discrete(expand = expansion(add = 0.65)) +
  labs(title = "Berlin 2023 — each district against the city",
       subtitle = "Filled dot: district share. Hollow dot: Berlin-wide share. Labels give district percentages.\nA line to the right means a higher local share; a line to the left means a lower local share. This is not change over time.",
       x = "Share of valid party-list votes", y = NULL,
       caption = paste0(source_note, "\n12 February 2023 · Berlin benchmark = party votes / all valid votes citywide; it includes the district")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(), strip.text = element_text(face = "bold", size = 12, lineheight = 1.15),
        axis.text.y = element_text(size = 9), axis.text.x = element_text(size = 9),
        axis.line.x = element_line(colour = "#BDC3C9", linewidth = 0.35),
        panel.spacing.x = unit(18, "pt"), panel.spacing.y = unit(24, "pt"),
        legend.position = "top", legend.justification = "left",
        plot.title = element_text(size = 23, face = "bold", margin = margin(b = 10)),
        plot.subtitle = element_text(size = 12, colour = "#545A61", lineheight = 1.3, margin = margin(b = 8)),
        plot.caption = element_text(size = 10, colour = "#545A61", hjust = 0, lineheight = 1.3, margin = margin(t = 12)),
        plot.margin = margin(20, 20, 16, 20))

for (ext in c("png", "pdf")) {
  device <- if (ext == "pdf") grDevices::cairo_pdf else "png"
  ggsave(paste0("examples/berlin_votes_sankey.", ext), sankey,
         width = 14, height = 10.5, dpi = 220, bg = "white", device = device)
  ggsave(paste0("examples/berlin_votes_dumbbell.", ext), dumbbell,
         width = 16, height = 11, dpi = 220, bg = "white", device = device)
}
write.csv(d[c("bezirk", "party", "votes", "district_pct", "berlin_pct", "difference_pp")],
          "examples/berlin_district_comparisons.csv", row.names = FALSE)
cat("Verified 84 district/party counts and ribbon widths; exported both charts as PNG and PDF.\n")
