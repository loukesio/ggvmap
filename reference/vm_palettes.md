# List the built-in colour palettes

Returns the built-in named palettes that the `palette` argument of
[`ggvmap()`](https://loukesio.github.io/ggvmap/reference/ggvmap.md),
[`vm_add_ring()`](https://loukesio.github.io/ggvmap/reference/vm_add_ring.md)
and friends accepts as a string: the 32 palettes of the ltc package
(vendored, so ltc need not be installed; a few are curated for use as
map fills – pure-black and near-white entries are dropped). Palette
names are matched case-insensitively and ignore spaces, underscores, and
dashes. The `heatmap0`–`heatmap3` palettes are ordered ramps intended
for continuous fill (`fill_by = "data_weight"`) and are always
interpolated end-to-end.

## Usage

``` r
vm_palettes()
```

## Value

A named list of hex-colour vectors.

## Examples

``` r
names(vm_palettes())
#>  [1] "paloma"     "maya"       "dora"       "ploen"      "olga"      
#>  [6] "mterese"    "gaby"       "franscoise" "fernande"   "sylvie"    
#> [11] "expevo"     "minou"      "kiss"       "hat"        "reading"   
#> [16] "alger"      "trio1"      "trio2"      "trio3"      "trio4"     
#> [21] "heatmap0"   "pantone23"  "remains"    "midnight"   "lincoln"   
#> [26] "luminaries" "seafarer"   "shuggie"    "heatmap1"   "heatmap2"  
#> [31] "heatmap3"   "casa_natal"
vm_palettes()$casa_natal
#> [1] "#245E55" "#ED773C" "#808BC5" "#C63F3E" "#EAC119" "#EAA7C7" "#9ED6DF"
```
