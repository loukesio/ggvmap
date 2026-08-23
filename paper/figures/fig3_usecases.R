# Figure 3: use cases across disciplines (simulated but realistic data;
# every panel is fully scripted here).
# Run from the package root:  Rscript paper/figures/fig3_usecases.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
})

titled <- function(p, tag, title) {
  p + ggtitle(paste0(tag, "  ", title)) +
    theme(plot.title = element_text(size = 10, face = "bold", hjust = 0))
}

# --- (A) gene families by genome share (genomics) ---------------------------
# Sizes loosely modelled on large Drosophila/vertebrate gene families.
gene_fam <- data.frame(
  family = c("Zinc finger", "Olfactory receptor", "Protein kinase", "GPCR",
             "Immunoglobulin", "Homeobox", "ABC transporter", "Cytochrome P450",
             "Helicase", "HSP", "Histone", "tRNA"),
  class  = c("Regulation", "Signalling", "Signalling", "Signalling",
             "Defence", "Regulation", "Other", "Other",
             "Regulation", "Defence", "Regulation", "Other"),
  genes  = c(720, 400, 518, 340, 210, 235, 130, 102, 95, 60, 86, 45)
)
vmA <- voronoi_map(gene_fam$genes, labels = gene_fam$family,
                   group = gene_fam$class, clip = clip_circle(), seed = 2,
                   max_iter = 80)
colA <- setNames(ifelse(gene_fam$class == "Regulation", "grey95", "grey15"),
                 gene_fam$family)
valA <- setNames(ifelse(gene_fam$class == "Regulation", "grey85", "grey35"),
                 gene_fam$family)
pA <- ggvmap(vmA, palette = "alger", label_size = 2.1, label_col = colA,
             autoscale = TRUE) |>
  vm_add_labels(size = 1.8, autoscale = TRUE, col = valA) |>
  vm_add_ring(style = "arc", palette = "alger", values = TRUE,
              label_size = 2.2)
pA <- titled(pA, "A", "Gene families by genome share")

# --- (B) GWAS hits per chromosome (genetics) --------------------------------
set.seed(7)
chr_len <- c(248, 242, 198, 190, 182, 171, 159, 145, 138, 134, 135, 133,
             114, 107, 102, 90, 83, 80, 59, 64, 47, 51)  # Mb, chr1-22
hits <- rpois(22, lambda = chr_len / 8) + 1
vmB <- voronoi_map(hits, labels = paste0("chr", 1:22),
                   clip = clip_rectangle(1, 0.62), seed = 3, max_iter = 80)
pB <- ggvmap(vmB, fill_by = "data_weight", palette = "alger",
             label_size = 2.0, autoscale = TRUE) |>
  vm_add_labels(size = 1.7, autoscale = TRUE)
pB <- titled(pB, "B", "GWAS hits per chromosome")

# --- (C) RNA-seq library composition (transcriptomics) ----------------------
rnaseq <- data.frame(
  fraction = c("mRNA exonic", "mRNA intronic", "lncRNA", "pre-mRNA",
               "rRNA residual", "tRNA", "snoRNA", "Mitochondrial",
               "Intergenic", "Adapter/low-quality", "Duplicates"),
  class    = c("Signal", "Signal", "Signal", "Signal",
               "Contaminant", "Contaminant", "Signal", "Contaminant",
               "Noise", "Noise", "Noise"),
  percent  = c(46.0, 14.5, 4.0, 3.5, 6.5, 1.2, 0.8, 8.5, 7.0, 3.0, 5.0)
)
vmC <- voronoi_map(rnaseq$percent, labels = rnaseq$fraction,
                   group = rnaseq$class, clip = clip_hexagon(), seed = 4,
                   max_iter = 80)
colC <- setNames(ifelse(rnaseq$class == "Signal", "grey95", "grey15"),
                 rnaseq$fraction)
valC <- setNames(ifelse(rnaseq$class == "Signal", "grey80", "grey35"),
                 rnaseq$fraction)
pC <- ggvmap(vmC, palette = "alger", label_size = 1.9, label_col = colC,
             autoscale = TRUE, min_area = 0.012,
             group_border_col = c(Contaminant = "#333333")) |>
  vm_add_labels(fmt = function(v) paste0(v, "%"), size = 1.7,
                autoscale = TRUE, min_area = 0.02, col = valC)
pC <- titled(pC, "C", "RNA-seq library composition")

# --- (D) household expenditure (social science) -----------------------------
# Shares approximating a European household budget survey.
budget <- data.frame(
  item  = c("Rent & utilities", "Maintenance", "Groceries", "Restaurants",
            "Transport", "Vehicle", "Health", "Insurance",
            "Recreation", "Culture", "Clothing", "Education", "Other"),
  need  = c("Housing", "Housing", "Food", "Food",
            "Mobility", "Mobility", "Security", "Security",
            "Leisure", "Leisure", "Leisure", "Other", "Other"),
  share = c(24.1, 8.2, 12.5, 6.3, 8.1, 5.2, 5.5, 4.8, 8.4, 3.1, 4.5, 1.3, 8.0)
)
vmD <- voronoi_map(budget$share, labels = budget$item, group = budget$need,
                   clip = clip_circle(), seed = 6, max_iter = 80)
colD <- setNames(ifelse(budget$need == "Housing", "grey95", "grey15"),
                 budget$item)
valD <- setNames(ifelse(budget$need == "Housing", "grey85", "grey35"),
                 budget$item)
pD <- ggvmap(vmD, palette = "alger", label_size = 1.9, label_col = colD,
             autoscale = TRUE) |>
  vm_add_labels(fmt = function(v) paste0(v, "%"), size = 1.7,
                autoscale = TRUE, col = valD) |>
  vm_add_ring(style = "arc", palette = "alger", values = TRUE,
              label_size = 2.2)
pD <- titled(pD, "D", "Household expenditure")

fig3 <- (pA | pB) / (pC | pD)
ggsave("paper/figures/fig3_usecases.png", fig3, width = 11, height = 11,
       dpi = 300, bg = "white")
message("wrote paper/figures/fig3_usecases.png")
