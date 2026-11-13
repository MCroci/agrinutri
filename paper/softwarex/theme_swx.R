# House style of the SoftwareX figures (Elsevier): Arial, 7 pt text at final size, column widths
# 90 / 140 / 190 mm, bold panel tags (a), (b), no titles inside the figures (they go in the
# captions), fixed palettes, scale bar and north arrow on maps, PNG at 600 dpi plus vector PDF.
# Figure 1 (fig1_architecture.py, pubfig.py) follows the same font, sizes and tags.
suppressMessages({ library(ggplot2); library(patchwork); library(scales) })

FONT <- "Arial"
BASE <- 7                                              # pt at final size
WIDTH <- c(single = 90, onehalf = 140, double = 190)    # mm
OKABE <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#0072B2", "#D55E00", "#CC79A7", "#F0E442")

theme_sat <- function(base = BASE) {
  theme_bw(base_size = base, base_family = FONT) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(linewidth = 0.2, colour = "grey90"),
          panel.border = element_rect(linewidth = 0.4, colour = "grey30"),
          axis.ticks = element_line(linewidth = 0.3, colour = "grey30"),
          axis.text = element_text(size = base - 1, colour = "black"),
          legend.title = element_text(size = base), legend.text = element_text(size = base - 1),
          legend.key.size = unit(3, "mm"), legend.background = element_blank(),
          strip.background = element_blank(), strip.text = element_text(size = base, face = "bold"),
          plot.title = element_text(size = base, face = "plain", hjust = 0),
          plot.margin = margin(2, 3, 2, 2))
}
theme_map <- function(base = BASE) {
  theme_void(base_size = base, base_family = FONT) +
    theme(legend.position = "bottom", legend.title = element_text(size = base, vjust = 0.9),
          legend.text = element_text(size = base - 1),
          legend.key.width = unit(9, "mm"), legend.key.height = unit(1.8, "mm"),
          plot.title = element_text(size = base, hjust = 0.5, margin = margin(b = 2)),
          plot.margin = margin(2, 2, 2, 2))
}
# panel tags (a), (b), ... on a patchwork: add_tags(p1 + p2)
add_tags <- function(p) (p + plot_annotation(tag_levels = "a", tag_prefix = "(", tag_suffix = ")")) &
  theme(plot.tag = element_text(family = FONT, face = "bold", size = BASE + 1))
invisible(Sys.setlocale("LC_TIME", "C"))                 # English month names on date axes
cbar <- function() guides(fill = guide_colourbar(title.position = "top", title.hjust = 0.5))

# palettes: nitrogen dose, its uncertainty, Nitrogen Nutrition Index
fill_N   <- function(name = expression("N (kg N ha"^-1*")"), ...)
  scale_fill_viridis_c(option = "mako", direction = -1, na.value = "transparent", name = name, ...)
fill_SD  <- function(name = expression("SD (kg N ha"^-1*")"), ...)
  scale_fill_viridis_c(option = "rocket", direction = -1, na.value = "transparent", name = name, ...)
fill_NNI <- function(name = "NNI", ...)
  scale_fill_gradientn(colours = c("#b2182b", "#ef8a62", "#f7f7f7", "#67a9cf", "#2166ac"),
                       values = rescale(c(0.6, 0.9, 1.0, 1.1, 1.4)), limits = c(0.6, 1.4),
                       oob = squish, na.value = "transparent", name = name, ...)

# scale bar and north arrow (projected coordinates in metres), placed in the lower-left corner
map_furniture <- function(bb, len = 200) {
  dx <- bb[["xmax"]] - bb[["xmin"]]; dy <- bb[["ymax"]] - bb[["ymin"]]
  x0 <- bb[["xmin"]] + 0.03 * dx; y0 <- bb[["ymin"]] + 0.04 * dy
  xn <- bb[["xmin"]] + 0.03 * dx; yn <- bb[["ymax"]] - 0.16 * dy
  list(annotate("segment", x = x0, xend = x0 + len, y = y0, yend = y0, linewidth = 0.8),
       annotate("text", x = x0 + len / 2, y = y0 + 0.025 * dy, label = if (len >= 1000) paste(len / 1000, "km") else paste(len, "m"),
                size = (BASE - 1) / .pt, family = FONT, vjust = 0),
       annotate("segment", x = xn, xend = xn, y = yn, yend = yn + 0.1 * dy,
                arrow = arrow(length = unit(1.4, "mm"), type = "closed"), linewidth = 0.5),
       annotate("text", x = xn, y = yn - 0.015 * dy, label = "N", size = BASE / .pt,
                family = FONT, fontface = "bold", vjust = 1))
}

save_fig <- function(p, file, width = "double", height = 80, dir = "paper/softwarex/figures") {
  w <- if (is.character(width)) WIDTH[[width]] else width
  ggsave(file.path(dir, paste0(file, ".png")), p, device = ragg::agg_png, width = w, height = height,
         units = "mm", dpi = 600, bg = "white")
  ggsave(file.path(dir, paste0(file, ".pdf")), p, device = cairo_pdf, width = w, height = height,
         units = "mm", bg = "white")
  invisible(file)
}
