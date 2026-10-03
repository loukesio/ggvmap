# Reproduce every figure and render the white paper to PDF.
# Run from the package root:  Rscript paper/render.R
# The paper also reads vignettes/fit_study.csv, written by
# data-raw/fit_study.R (~25 minutes on 6 cores).
# (The benchmark takes ~12 minutes; set REUSE_RUNS=1 to redraw it from the
#  archived benchmark_runs.csv instead.)
for (f in c("paper/figures/fig0_howitworks.R",
            "paper/figures/fig1_design.R",
            "paper/figures/fig2_gallery.R",
            "paper/figures/fig3_usecases.R",
            "paper/figures/fig4_benchmark.R")) {
  message("== running ", f)
  system2("Rscript", f)
}
message("== rendering paper/paper.qmd")
system2("quarto", c("render", "paper/paper.qmd"))
