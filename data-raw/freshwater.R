# Build data(freshwater): share of global renewable internal freshwater
# resources by country, 2022.  Source: FAO Aquastat via World Bank; figures as
# popularised by the Visual Capitalist "Countries with the Most Freshwater"
# graphic (rounded shares; "Rest of <region>" aggregates the remainder).
freshwater <- data.frame(
  country = c(
    "Brazil", "Russia", "Canada", "United States", "China",
    "Colombia", "Indonesia", "Rest of Africa", "Rest of Europe", "Peru",
    "Rest of LATAM", "Rest of Asia-Pac", "India", "Myanmar", "Chile",
    "DR Congo", "Venezuela", "Papua New Guinea", "Malaysia", "Philippines",
    "Australia", "Mexico", "Ecuador", "Japan", "Middle East",
    "Norway", "New Zealand", "Madagascar", "Vietnam", "Bolivia"
  ),
  share = c(
    13.2, 10.1, 6.7, 6.6, 6.6,
    5.0, 4.7, 6.3, 4.6, 3.8,
    3.7, 3.6, 3.4, 2.3, 2.1,
    2.1, 1.9, 1.9, 1.4, 1.1,
    1.1, 1.0, 1.0, 1.0, 1.0,
    0.9, 0.8, 0.8, 0.8, 0.7
  ),
  region = c(
    "LATAM", "Europe", "North America", "North America", "Asia-Pacific",
    "LATAM", "Asia-Pacific", "Africa", "Europe", "LATAM",
    "LATAM", "Asia-Pacific", "Asia-Pacific", "Asia-Pacific", "LATAM",
    "Africa", "LATAM", "Asia-Pacific", "Asia-Pacific", "Asia-Pacific",
    "Asia-Pacific", "North America", "LATAM", "Asia-Pacific", "Middle East",
    "Europe", "Asia-Pacific", "Africa", "Asia-Pacific", "LATAM"
  ),
  stringsAsFactors = FALSE
)
stopifnot(nrow(freshwater) == 30, abs(sum(freshwater$share) - 100) < 0.5)
usethis::use_data(freshwater, overwrite = TRUE)
