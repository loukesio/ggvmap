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
#' autoplot(vm, show_labels = FALSE) |> vm_add_ring()
"world_exports"

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
#' autoplot(vm) |>
#'   vm_add_flags() |>
#'   vm_add_labels(value = stats::setNames(merchant_fleet$owned,
#'                                         merchant_fleet$country))
#' }
"merchant_fleet"
