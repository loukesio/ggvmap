# Record the animated hover demo for the README
# (man/figures/README-interactive.gif).  Drives the real ggiraph widget in
# headless Chrome via {chromote}, dispatching genuine mouse events so the
# hover highlight + tooltips seen in the GIF are the widget's own behaviour.
# Run from the package root:  Rscript data-raw/readme_interactive_gif.R
suppressPackageStartupMessages({
  devtools::load_all(".", quiet = TRUE)
  library(chromote)
  library(magick)
})

data(freshwater)
top10 <- freshwater[!grepl("^Rest of|Middle East", freshwater$country), ][1:10, ]
vm10 <- voronoi_map(top10$share, labels = top10$country,
                    clip = clip_circle(), seed = 42)
g <- ggvmap(vm10, interactive = TRUE, palette = "alger") |>
  vm_girafe(width_svg = 6, height_svg = 6)
html <- file.path(tempdir(), "ggvmap_hover_demo.html")
htmlwidgets::saveWidget(g, html, selfcontained = TRUE)

b <- ChromoteSession$new(width = 660, height = 640)
b$Page$navigate(paste0("file://", html))
Sys.sleep(2)

# Fit the emulated screen to the widget's actual SVG so nothing is cropped
b$Runtime$evaluate('document.body.style.margin = "0"')
bb <- jsonlite::fromJSON(b$Runtime$evaluate(
  'JSON.stringify(document.querySelector("svg").getBoundingClientRect())',
  returnByValue = TRUE)$result$value)
b$Emulation$setDeviceMetricsOverride(
  width = ceiling(bb$x + bb$width + 4), height = ceiling(bb$y + bb$height + 4),
  deviceScaleFactor = 1, mobile = FALSE)
Sys.sleep(1)

# Screen-space centre of each interactive cell, from the live SVG
boxes <- b$Runtime$evaluate('JSON.stringify(
  Array.from(document.querySelectorAll("[data-id]")).map(el => {
    const r = el.getBoundingClientRect();
    return {id: el.getAttribute("data-id"),
            x: r.x + r.width / 2, y: r.y + r.height / 2};
  }))', returnByValue = TRUE)$result$value
boxes <- do.call(rbind, lapply(jsonlite::fromJSON(boxes, simplifyDataFrame = FALSE),
                               as.data.frame))
boxes <- boxes[!duplicated(boxes$id), ]

shot <- function() {
  res <- b$Page$captureScreenshot(format = "png")
  magick::image_read(base64enc::base64decode(res$data))
}
move <- function(x, y) {
  b$Input$dispatchMouseEvent(type = "mouseMoved", x = x, y = y)
}

# Tour: Brazil -> Russia -> Canada -> US -> China, gliding between cells
order_ids <- as.character(match(c("Brazil", "Russia", "Canada",
                                  "United States", "China"), top10$country))
stops <- boxes[match(order_ids, boxes$id), ]

frames <- list()
pos <- c(stops$x[1], stops$y[1] + 120)  # enter from below the first cell
for (k in seq_len(nrow(stops))) {
  tgt <- c(stops$x[k], stops$y[k])
  for (s in seq(0.25, 1, by = 0.25)) {  # glide in 4 steps
    p <- pos + s * (tgt - pos)
    move(p[1], p[2]); Sys.sleep(0.12)
    frames <- c(frames, list(shot()))
  }
  Sys.sleep(0.25)
  for (i in 1:5) frames <- c(frames, list(shot()))  # dwell on the tooltip
  pos <- tgt
}
b$close()

gif <- magick::image_join(frames)
gif <- magick::image_scale(gif, "620")
gif <- magick::image_animate(gif, fps = 10, optimize = TRUE)
magick::image_write(gif, "man/figures/README-interactive.gif")
message("wrote man/figures/README-interactive.gif (",
        round(file.size("man/figures/README-interactive.gif") / 1e6, 1), " MB)")
