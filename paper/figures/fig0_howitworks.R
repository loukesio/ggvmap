# Figure: how the map is built, round by round.
# The same ten values and the same random start, stopped after 1, 3 and 6
# rounds and at the end. Bottom panel: each country's intended share versus
# the share it is drawn with, after round 1 and at the end.
# Run from the package root: Rscript paper/figures/fig0_howitworks.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
})

data(freshwater)
top10 <- freshwater[!grepl("^Rest of|Middle East", freshwater$country), ][1:10, ]

fit_after <- function(rounds) {
  voronoi_map(top10$share, labels = top10$country, clip = clip_circle(),
              seed = 4, max_iter = rounds)
}
final <- fit_after(200)
stages <- list(fit_after(1), fit_after(3), fit_after(6), final)
titles <- c("after 1 round", "after 3 rounds", "after 6 rounds",
            sprintf("finished (%d rounds)", final$iterations))

panels <- Map(function(vm, ttl, tag) {
  ggvmap(vm, palette = "reading", label_size = 2.1, label_col = "grey10",
         autoscale = TRUE) +
    labs(title = paste0(tag, "  ", ttl),
         subtitle = sprintf("area mistakes add up to %.1f%% of the map",
                            100 * vm$convergence)) +
    theme(plot.title = element_text(size = 9.5, face = "bold"),
          plot.subtitle = element_text(size = 8.5, colour = "grey30"))
}, stages, titles, LETTERS[1:4])

first <- vm_fit(stages[[1]]); last <- vm_fit(final)
d <- data.frame(country = factor(first$label, rev(first$label)),
                intended = 100 * first$target_share,
                round1 = 100 * first$actual_share,
                end = 100 * last$actual_share)
pE <- ggplot(d, aes(y = country)) +
  geom_segment(aes(x = intended, xend = round1, yend = country),
               colour = "grey75", linewidth = 0.6) +
  geom_point(aes(x = round1, colour = "drawn, after 1 round"), size = 2.2) +
  geom_point(aes(x = intended, colour = "intended share"), size = 3.6,
             shape = 21, stroke = 1, fill = NA) +
  geom_point(aes(x = end, colour = "drawn, finished"), size = 1.7) +
  scale_colour_manual(values = c("intended share" = "grey15",
                                 "drawn, after 1 round" = "#C9A227",
                                 "drawn, finished" = "#2E6E8E"),
                      breaks = c("intended share", "drawn, after 1 round",
                                 "drawn, finished")) +
  labs(title = "E  Each country's share of the circle",
       subtitle = "the finished dots sit inside the rings: drawn area matches intended area",
       x = "share of the circle (%)", y = NULL, colour = NULL) +
  theme_minimal(base_size = 9.5) +
  theme(plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(colour = "grey30"),
        legend.position = "bottom", panel.grid.minor = element_blank())

fig <- (panels[[1]] | panels[[2]] | panels[[3]] | panels[[4]]) / pE +
  plot_layout(heights = c(1, 0.9))
ggsave("paper/figures/fig0_howitworks.png", fig, width = 12, height = 7.6,
       dpi = 300, bg = "white")
message("wrote paper/figures/fig0_howitworks.png")
