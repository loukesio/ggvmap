# Generates the bundled example datasets. Run with:  source("data-raw/datasets.R")
# Values are approximate, compiled for illustration (2021 vintage).

# --- world_exports: goods exports 2021 with World Bank income groups --------
world_exports <- data.frame(
  country = c(
    "China", "United States", "Germany", "Netherlands", "Japan",
    "Hong Kong", "South Korea", "Italy", "France", "Belgium",
    "Canada", "Mexico", "Russia", "Singapore", "Taiwan",
    "United Kingdom", "Spain", "United Arab Emirates", "India", "Switzerland",
    "Poland", "Australia", "Thailand", "Vietnam", "Brazil",
    "Malaysia", "Saudi Arabia", "Ireland", "Sweden", "Austria",
    "Czechia", "Indonesia", "Turkey", "Norway", "Denmark",
    "Philippines", "Ukraine", "Egypt", "Nigeria", "Kenya"
  ),
  exports = c(
    3364, 1754, 1631, 836, 756,
    670, 644, 610, 585, 545,
    507, 495, 494, 457, 447,
    470, 383, 425, 395, 380,
    337, 344, 271, 336, 281,
    299, 276, 190, 190, 202,
    227, 231, 225, 161, 128,
    75, 68, 44, 47, 7
  ),
  income_group = c(
    "Upper middle", "High income", "High income", "High income", "High income",
    "High income", "High income", "High income", "High income", "High income",
    "High income", "Upper middle", "Upper middle", "High income", "High income",
    "High income", "High income", "High income", "Lower middle", "High income",
    "High income", "High income", "Upper middle", "Lower middle", "Upper middle",
    "Upper middle", "High income", "High income", "High income", "High income",
    "High income", "Lower middle", "Upper middle", "High income", "High income",
    "Lower middle", "Lower middle", "Lower middle", "Lower middle", "Lower middle"
  ),
  stringsAsFactors = FALSE
)
world_exports$income_group <- factor(
  world_exports$income_group,
  levels = c("High income", "Upper middle", "Lower middle", "Low income")
)

# --- merchant_fleet: top merchant fleets 2021 -------------------------------
merchant_fleet <- data.frame(
  country    = c("China", "Greece", "Japan", "Singapore", "Indonesia",
                 "Norway", "Germany", "South Korea", "Denmark", "Turkey",
                 "United States", "United Kingdom", "Italy", "Netherlands",
                 "Russia"),
  registered = c(4887, 642, 914, 1459, 2232,
                 387, 198, 760, 45, 1213,
                 780, 320, 590, 520, 1420),
  owned      = c(6884, 4520, 3848, 2497, 2280,
                 1373, 1479, 1623, 900, 1560,
                 1240, 880, 1420, 1210, 1740),
  stringsAsFactors = FALSE
)

usethis::use_data(world_exports, overwrite = TRUE)
usethis::use_data(merchant_fleet, overwrite = TRUE)
