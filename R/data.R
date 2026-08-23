# ---- Bundled example datasets ----

#' World goods exports 2021
#'
#' Approximate merchandise exports for 40 economies in 2021, tagged with their
#' World Bank income group.  Compiled for illustration; values are rounded.
#'
#' @format A data frame with 40 rows and 3 columns:
#' \describe{
#'   \item{country}{Country / economy name.}
#'   \item{exports}{Goods exports in billions of US dollars.}
#'   \item{income_group}{Factor: World Bank income group
#'     (`"High income"`, `"Upper middle"`, `"Lower middle"`, `"Low income"`).}
#' }
#' @source Illustrative figures based on WTO / World Bank 2021 data.
#' @examples
#' vm <- voronoi_map(world_exports$exports,
#'                   labels = world_exports$country,
#'                   group  = as.character(world_exports$income_group),
#'                   clip   = clip_circle(), seed = 1)
#' ggvmap(vm, show_labels = FALSE, palette = "alger") |> vm_add_ring(palette = "alger")
"world_exports"

#' Global renewable freshwater resources 2022
#'
#' Share of the world's renewable internal freshwater resources for 25
#' countries plus five "Rest of <region>" aggregates (30 rows, summing to
#' ~100%).  This is the package's canonical demo dataset; see
#' `examples/freshwater_tour.R` for a full tour.
#'
#' @format A data frame with 30 rows and 3 columns:
#' \describe{
#'   \item{country}{Country name or regional remainder (e.g. `"Rest of LATAM"`).}
#'   \item{share}{Share of global renewable internal freshwater resources, in
#'     percent (2022, rounded).}
#'   \item{region}{Region: `"LATAM"`, `"Asia-Pacific"`, `"North America"`,
#'     `"Europe"`, `"Africa"`, or `"Middle East"`.}
#' }
#' @source FAO Aquastat via World Bank, 2022 figures.
#' @examples
#' vm <- voronoi_map(freshwater$share,
#'                   labels = freshwater$country,
#'                   group  = freshwater$region,
#'                   clip   = clip_circle(), seed = 5)
#' ggvmap(vm, palette = "alger", autoscale = TRUE)
"freshwater"

#' Top merchant fleets 2021
#'
#' Merchant fleet sizes for 15 countries in 2021: ships on the national
#' register and total owned.  Compiled for illustration.
#'
#' @format A data frame with 15 rows and 3 columns:
#' \describe{
#'   \item{country}{Country name.}
#'   \item{registered}{Number of ships on the national register.}
#'   \item{owned}{Total number of ships owned by that country's interests.}
#' }
#' @source Illustrative figures based on UNCTAD / ITF 2021 data.
#' @examples
#' vm <- voronoi_map(merchant_fleet$owned,
#'                   labels = merchant_fleet$country,
#'                   seed = 3)
#' \dontrun{
#' ggvmap(vm, palette = "alger") |>
#'   vm_add_flags() |>
#'   vm_add_labels(value = stats::setNames(merchant_fleet$owned,
#'                                         merchant_fleet$country))
#' }
"merchant_fleet"
