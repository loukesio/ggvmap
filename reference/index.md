# Package index

## Compute

Build a Voronoi map (optionally hierarchical).

- [`voronoi_map()`](https://loukesio.github.io/ggvmap/reference/voronoi_map.md)
  : Compute a Voronoi map
- [`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md) :
  Quick ggplot2 Voronoi map

## Plot

Base-R and ggplot2 visualisation.

- [`autoplot(`*`<voronoi_map>`*`)`](https://loukesio.github.io/ggvmap/reference/autoplot.voronoi_map.md)
  : Autoplot method for voronoi_map objects
- [`plot(`*`<voronoi_map>`*`)`](https://loukesio.github.io/ggvmap/reference/plot.voronoi_map.md)
  : Plot a Voronoi map
- [`vm_girafe()`](https://loukesio.github.io/ggvmap/reference/vm_girafe.md)
  : Render an interactive Voronoi map
- [`vm_as_df()`](https://loukesio.github.io/ggvmap/reference/vm_as_df.md)
  : Convert a voronoi_map to a tidy data frame
- [`vm_centroids()`](https://loukesio.github.io/ggvmap/reference/vm_centroids.md)
  : Centroids of every cell in a voronoi_map

## Annotations

Outer ring, flags, images and value labels.

- [`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md)
  : Add a colored outer annotation ring
- [`vm_add_flags()`](https://loukesio.github.io/ggvmap/reference/vm_add_flags.md)
  : Add country flags at cell centroids
- [`vm_add_images()`](https://loukesio.github.io/ggvmap/reference/vm_add_images.md)
  : Add images at cell centroids
- [`vm_add_labels()`](https://loukesio.github.io/ggvmap/reference/vm_add_labels.md)
  : Add value labels at (or near) cell centroids
- [`country_to_iso()`](https://loukesio.github.io/ggvmap/reference/country_to_iso.md)
  : Look up ISO 3166-1 alpha-2 codes for country names
- [`flag_url()`](https://loukesio.github.io/ggvmap/reference/flag_url.md)
  : URL of a flag PNG on flagcdn.com
- [`flag_cache()`](https://loukesio.github.io/ggvmap/reference/flag_cache.md)
  : Pre-download flags for offline use

## Colours

- [`okabe_ito()`](https://loukesio.github.io/ggvmap/reference/okabe_ito.md)
  : The Okabe-Ito colourblind-safe qualitative palette

## Boundary shapes

- [`clip_square()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  [`clip_hexagon()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  [`clip_circle()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  [`clip_diamond()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  [`clip_triangle()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  [`clip_pentagon()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  [`clip_octagon()`](https://loukesio.github.io/ggvmap/reference/clip_shapes.md)
  : Generate common clipping shapes
- [`clip_rectangle()`](https://loukesio.github.io/ggvmap/reference/clip_rectangle.md)
  : Rectangular clipping boundary
- [`clip_ellipse()`](https://loukesio.github.io/ggvmap/reference/clip_ellipse.md)
  : Elliptical clipping boundary
- [`regular_polygon()`](https://loukesio.github.io/ggvmap/reference/regular_polygon.md)
  : Generate a regular polygon with n sides inscribed in a circle

## Data

- [`world_exports`](https://loukesio.github.io/ggvmap/reference/world_exports.md)
  : World goods exports 2021
- [`merchant_fleet`](https://loukesio.github.io/ggvmap/reference/merchant_fleet.md)
  : Top merchant fleets 2021
