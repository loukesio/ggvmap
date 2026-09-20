# Refresh the four city-boundary snapshots from source services.
# Run from the repository root. Cached downloads are reused; no network access
# is needed by the package tests or examples once the snapshot is present.
stopifnot(requireNamespace("sf", quietly = TRUE))
cache <- "examples/region-data"
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
urls <- c(
  Berlin = "https://tsb-opendata.s3.eu-central-1.amazonaws.com/bezirksgrenzen/bezirksgrenzen.geojson",
  Amsterdam = "https://nominatim.openstreetmap.org/search?q=Amsterdam%2C%20Netherlands&format=geojson&polygon_geojson=1&limit=1",
  London = "https://gis.london.gov.uk/arcgis/rest/services/apps/planning_data_map_02/FeatureServer/303/query?where=1%3D1&outFields=*&outSR=4326&f=geojson",
  Thessaloniki = "https://nominatim.openstreetmap.org/search?q=Municipality%20of%20Thessaloniki%2C%20Greece&format=geojson&polygon_geojson=1&limit=1"
)
projections <- c(Berlin = 25833, Amsterdam = 28992, London = 27700, Thessaloniki = 2100)
definitions <- c(Berlin = "State/city boundary (union of 12 districts)",
                 Amsterdam = "Municipality (OSM relation 271110)",
                 London = "Greater London (GLA boundary)",
                 Thessaloniki = "Municipality (OSM relation 1770680)")
old <- options(HTTPUserAgent = "ggvmap-region-example/0.3 (https://github.com/loukesio/ggvmap)")
features <- list(); manifest <- list()
for (city in names(urls)) {
  file <- file.path(cache, paste0(tolower(city), "-source.geojson"))
  if (!file.exists(file)) {
    if (grepl("nominatim", urls[[city]])) Sys.sleep(1.1)
    download.file(urls[[city]], file, mode = "wb", quiet = TRUE)
  }
  x <- sf::st_read(file, quiet = TRUE)
  stopifnot(nrow(x) == if (city == "Berlin") 12L else 1L)
  if (city == "Amsterdam") stopifnot(x$osm_id == 271110)
  if (city == "Thessaloniki") stopifnot(x$osm_id == 1770680)
  x <- sf::st_transform(x, projections[[city]])
  repaired <- !all(sf::st_is_valid(x))
  if (repaired) x <- sf::st_make_valid(x)
  region <- sf::st_union(sf::st_geometry(x))
  simplified <- sf::st_simplify(region, dTolerance = 50, preserveTopology = TRUE)
  stopifnot(all(sf::st_is_valid(simplified)), !any(sf::st_is_empty(simplified)))
  features[[city]] <- sf::st_sf(city = city, boundary = definitions[[city]],
                               epsg = projections[[city]], simplified_m = 50,
                               geometry = sf::st_cast(sf::st_transform(simplified, 4326), "MULTIPOLYGON"))
  manifest[[city]] <- data.frame(city = city, boundary = definitions[[city]],
    downloaded_source = urls[[city]], reviewed_date = as.character(Sys.Date()),
    source_md5 = unname(tools::md5sum(file)), repaired = repaired,
    source_area_km2 = as.numeric(sf::st_area(region)) / 1e6,
    snapshot_area_km2 = as.numeric(sf::st_area(simplified)) / 1e6,
    vertices = nrow(sf::st_coordinates(simplified)))
}
options(old)
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
sf::st_write(do.call(rbind, features), "inst/extdata/region-cities.geojson", delete_dsn = TRUE, quiet = TRUE)
write.csv(do.call(rbind, manifest), "examples/region_cities_sources.csv", row.names = FALSE)
print(do.call(rbind, manifest)[c("city", "source_area_km2", "snapshot_area_km2", "vertices", "repaired")], row.names = FALSE)
