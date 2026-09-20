# City-boundary snapshots

`region-cities.geojson` contains four boundary snapshots for reproducible tests
and examples. These are third-party geographic data, not original MIT-licensed
package code. All were reviewed on 20 September 2026. The files are simplified
in local projected coordinates at 50 meters and stored in longitude/latitude
(EPSG:4326). The `epsg` field identifies each example's working projection.
They are test outlines, not a guarantee of current administrative accuracy.

- **Berlin**: union of twelve ALKIS district outlines, Geoportal Berlin,
  via [Technologiestiftung's GeoJSON mirror](https://tsb-opendata.s3.eu-central-1.amazonaws.com/bezirksgrenzen/bezirksgrenzen.geojson).
  [Official source catalog](https://daten.berlin.de/datensaetze/alkis-berlin-bezirke-wms-ecb4fc8b),
  Data licence Germany – Zero – Version 2.0. Mirror boundary date unverified.
- **Amsterdam**: municipality, OpenStreetMap relation 271110.
- **Thessaloniki**: municipality, OpenStreetMap relation 1770680; this is not
  the larger urban/metropolitan area.
- **London**: Greater London, from the
  [Greater London Authority boundary layer](https://gis.london.gov.uk/arcgis/rest/services/apps/planning_data_map_02/FeatureServer/303).
  Contains public sector information licensed under the
  [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
  Attribution: Ordnance Survey Open Data and Greater London Authority.

The Amsterdam and Thessaloniki features are © OpenStreetMap contributors,
obtained via Nominatim, and are provided under the
[Open Data Commons Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/1-0/).
See [OpenStreetMap copyright and attribution](https://www.openstreetmap.org/copyright).
These derived OSM features retain that licence; the package's MIT licence does
not replace it. Feature provenance is identified by the `city` and `boundary`
properties. Original services may be updated after the recorded review date.

The repository's `examples/prepare_region_cities.R` rebuilds this snapshot.
`examples/region_cities_sources.csv` records exact download URLs, source file
checksums, whether geometry repairs were needed, and areas before/after
simplification. No source geometry required repair in the reviewed run.
