# Contributing to ggvmap

Thanks for your interest! A few ground rules keep the package easy to
maintain:

- **Pure R only.** No compiled code and no new hard dependencies —
  `ggplot2` is the only Import. Optional niceties go in `Suggests`
  behind [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html)
  guards.
- **`README.md` is generated.** Edit `README.Rmd` only, then run
  `devtools::build_readme()`. The pre-rendered figures (hero, shapes
  grid, interactive GIF) come from `data-raw/readme_figures.R` and
  `data-raw/readme_interactive_gif.R`.
- **Keep sources ASCII.** Non-ASCII characters in R code are written as
  `\uXXXX` escapes.
- Every new argument gets roxygen docs, a `NEWS.md` entry, and a test.
- `devtools::check()` must be clean (no errors, warnings, or notes) and
  `devtools::test()` fully passing before a PR.
- The geometric invariants in `tests/testthat/test-correctness.R` are
  the package’s contract — never weaken them.
