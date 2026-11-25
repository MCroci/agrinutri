# Layout alternatives of Fig. 8 (precision-agriculture methods). Run from the package root:
#   Rscript paper/softwarex/layouts/fig8_variants.R ; then python layouts/contact_sheets.py from paper/softwarex/
options(swx.nosave = TRUE)
e <- new.env(); source("paper/softwarex/fig7_strategies.R", local = e)
library(patchwork); library(ggplot2)
OUT <- "paper/softwarex/layouts"
put <- function(p, name, w, h) ggsave(file.path(OUT, paste0(name, ".png")), p, device = ragg::agg_png,
                                      width = w, height = h, units = "mm", dpi = 300, bg = "white")
nm <- names(e$M); R <- function(i, first) e$rule_plot(nm[i], first); Mp <- function(i) e$map_plot(nm[i])
ks <- (plot_spacer() | e$key | plot_spacer())
stk <- function(g, h) wrap_plots(list(wrap_elements(full = g), ks), ncol = 1, heights = h)   # grid above the dose key
# A: two rows of three, rule above map (current)
put(e$fig, "fig8_A", 190, 175)
# B: three rows of two, rule beside map
blkB <- function(i) wrap_elements(full = R(i, TRUE) + Mp(i) + plot_layout(widths = c(1.4, 1)))
put(stk(wrap_plots(lapply(1:6, blkB), ncol = 2), c(3, 0.06)), "fig8_B", 190, 170)
# C: two rows of three, short rules (compact)
row3 <- function(ii) c(Map(R, ii, ii %in% c(1, 4)), lapply(ii, Mp))
put(stk(wrap_plots(c(row3(1:3), row3(4:6)), ncol = 3, byrow = TRUE, heights = c(0.45, 1, 0.45, 1)), c(3, 0.05)), "fig8_C", 190, 150)
# D: three rows of two, rule above map
row2 <- function(ii) c(Map(R, ii, ii %in% c(1, 3, 5)), lapply(ii, Mp))
put(stk(wrap_plots(c(row2(1:2), row2(3:4), row2(5:6)), ncol = 2, byrow = TRUE, heights = rep(c(0.6, 1), 3)), c(4, 0.05)), "fig8_D", 140, 230)
# E: two rows of three, map left and small rule right inside each block
blkE <- function(i) wrap_elements(full = Mp(i) + R(i, i %in% c(1, 4)) + plot_layout(widths = c(1, 1)))
put(stk(wrap_plots(lapply(1:6, blkE), ncol = 3), c(2, 0.05)), "fig8_E", 190, 105)
# F: one column, six rows (rule | map), for a single-column figure
put(stk(wrap_plots(lapply(1:6, blkB), ncol = 1), c(6, 0.08)), "fig8_F", 90, 230)
cat("fig8 variants written\n")
