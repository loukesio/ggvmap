# Generate a regular polygon with n sides inscribed in a circle

Generate a regular polygon with n sides inscribed in a circle

## Usage

``` r
regular_polygon(n = 6, cx = 0.5, cy = 0.5, r = 0.5)
```

## Arguments

- n:

  Number of sides.

- cx, cy:

  Centre coordinates.

- r:

  Radius.

## Value

2-column matrix (x, y), counterclockwise, open. The matrix carries
attributes `"center"`, `"radius"` and `"shape"` describing the boundary,
which downstream helpers (radial seeding, the annotation ring) read.
