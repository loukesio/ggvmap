# Correctness: is the Voronoi construction right?

This article documents *why* the tessellation `ggvmap` produces is a
correct **power diagram** (additively weighted Voronoi diagram), and the
numerical study that backs it up. The invariants below are enforced on
every build by `tests/testthat/test-correctness.R`.

## The mathematics

Each site $`i`$ has a position $`s_i = (x_i, y_i)`$ and a weight
$`w_i`$. Its **power distance** to a point $`p`$ is

``` math
\operatorname{pow}_i(p) = \lVert p - s_i \rVert^2 - w_i .
```

The **power cell** of site $`i`$ is every point closer to $`i`$ than to
any other site *in power distance*:

``` math
C_i = \{\, p : \operatorname{pow}_i(p) \le \operatorname{pow}_j(p)\ \ \forall j \,\}.
```

The boundary between cells $`i`$ and $`j`$ is where the two power
distances are equal. Expanding
$`\operatorname{pow}_i(p) = \operatorname{pow}_j(p)`$:

``` math
\lVert p - s_i\rVert^2 - w_i = \lVert p - s_j\rVert^2 - w_j
\;\Longrightarrow\;
2(s_j - s_i)\cdot p = \lVert s_j\rVert^2 - \lVert s_i\rVert^2 - w_j + w_i .
```

The quadratic $`\lVert p\rVert^2`$ terms cancel, so the bisector is a
**straight line** and each cell is an intersection of half-planes —
hence **convex**. `ggvmap` builds $`C_i`$ by clipping the boundary
polygon against one half-plane per other site (Sutherland–Hodgman). The
coefficients used in the code,

    a  = 2 (x_j - x_i)
    b  = 2 (y_j - y_i)
    cc = (x_j^2 - x_i^2) + (y_j^2 - y_i^2) - (w_j - w_i)   # keep a*x + b*y <= cc

are exactly the inequality above, so the construction is the power
diagram by definition.

For a **treemap**, the weights $`w_i`$ are not the data values — they
are latent parameters adapted iteratively (Nocaj & Brandes 2012) so that
each cell’s *area* becomes proportional to its data value, while site
positions drift to their cell centroids.

## What “correct” means, and how it is tested

| \# | Property | Test |
|----|----|----|
| 1 | **Defining property** — the cell containing a point is the site of minimum power distance | Monte-Carlo: sample interior points, compare containing cell to `which.min(pow)` |
| 2 | **Tiling** — cells cover the domain with no gaps or overlaps | every sampled point lies in exactly one cell; $`\sum \text{area}(C_i) = \text{area(clip)}`$ |
| 3 | **Convexity** — every cell is convex | sign of the cross-product is constant around each polygon |
| 4 | **Finiteness** — centroids are well defined | no `NaN`/`Inf` centroids |
| 5 | **Hierarchy** — grouped layout is a valid *nested* power diagram | groups form a power diagram of the disk; members form a power diagram of their group cell; member areas sum to the group-cell area |

## Results

A sweep over shapes (square, circle, hexagon, diamond, pentagon), cell
counts ($`n = 3 \ldots 80`$), random seeds, extreme weight ratios
(1000:1) and hierarchical layouts — tens of thousands of sampled points
— gives:

| Quantity | Result | Ideal |
|----|----|----|
| argmin agreement (flat) | 36000 / 36000 | all |
| points in exactly one cell | 100% | 100% |
| gaps / overlaps | 0 / 0 | 0 |
| non-convex cells | 0 | 0 |
| non-finite centroids | 0 | 0 |
| total-area deviation | $`\le 9\times10^{-16}`$ | 0 |
| nested-tiling deviation (hierarchical) | $`\approx 1.6\times10^{-15}`$ | 0 |
| top-level & per-group argmin mismatches | 0 | 0 |

The tessellation is therefore an *exact* power diagram (to
floating-point precision) in both the flat and hierarchical cases.

## Convergence quality

Correctness (a valid power diagram) is separate from **fit quality**
(how closely cell areas match their targets), which depends on the
iteration converging. Two initialisation improvements make convergence
far more robust:

- power weights start proportional to each cell’s target area
  ($`w_i \approx
  A_i / \pi`$) rather than uniform;
- initial site positions use farthest-point (“best candidate”) sampling
  rather than a purely random placement.

Across a 75-config sweep these changes eliminated every transient
degenerate-cell fallback and cut the worst-case per-cell area error from
~16× to ~5× (the residual occurs only in hard, non-converged cases with
many near-equal cells — raise `max_iter` or lower `convergence_ratio`
there).

## Reproduce it

The full harness lives in the package’s development history; a compact
version:

``` r

library(ggvmap)
vm <- voronoi_map(runif(20, 1, 50), clip = clip_circle(), seed = 1)

# tiling: total cell area equals the clip area
stopifnot(abs(sum(sapply(vm$cells, \(c) abs(ggvmap:::polygon_area(c)))) /
              abs(ggvmap:::polygon_area(vm$clip)) - 1) < 1e-9)

# defining property at a random interior point
p <- c(0.5, 0.5)
inside <- which(sapply(vm$cells, \(c) ggvmap:::point_in_polygon(p, c)))
amin   <- which.min((p[1]-vm$sites$x)^2 + (p[2]-vm$sites$y)^2 - vm$sites$weight)
stopifnot(inside == amin)
```
