# Reproduce every figure and render the white paper to PDF.
# Run from the package root:  Rscript paper/render.R
# (The benchmark takes ~20-30 minutes; comment it out to re-render the
#  paper from the archived benchmark_results.csv.)
for (f in c("paper/figures/fig1_design.R",
            "paper/figures/fig2_gallery.R",
            "paper/figures/fig3_usecases.R",
            "paper/figures/fig4_benchmark.R")) {
  message("== running ", f)
  system2("Rscript", f)
}
message("== rendering paper/paper.qmd")
system2("quarto", c("render", "paper/paper.qmd"))
