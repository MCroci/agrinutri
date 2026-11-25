# Layout alternatives of Figs. 2-6 for the authors to choose from (same panels, different arrangement).
# Each figure script is run with options(swx.nosave = TRUE), so it builds its panels without saving;
# the panels are then recombined here. Output: paper/softwarex/layouts/figN_X.png (300 dpi).
# Run from the package root:  Rscript paper/softwarex/layouts/layout_variants.R
suppressMessages({ library(ggplot2); library(patchwork); library(sf) })
options(swx.nosave = TRUE)
OUT <- "paper/softwarex/layouts"
run <- function(f) { e <- new.env(); source(file.path("paper/softwarex", f), local = e); e }
put <- function(p, name, w, h) ggsave(file.path(OUT, paste0(name, ".png")), p, device = ragg::agg_png,
                                      width = w, height = h, units = "mm", dpi = 300, bg = "white")

# ---- Fig. 2: farm --------------------------------------------------------------------------
e <- run("fig3_farm.R")
put(add_tags(e$pa + e$pb + plot_layout(widths = c(1, 1.3))), "fig2_A", 190, 72)
put(add_tags(e$pb + e$pa + plot_layout(widths = c(1.6, 1))), "fig2_B", 190, 72)
put(add_tags(e$pa / e$pb + plot_layout(heights = c(1, 1))), "fig2_C", 140, 150)
put(e$pb, "fig2_D", 140, 70)

# ---- Fig. 3: P01 nitrogen through the rotation --------------------------------------------------
e <- run("fig4_p01_years.R")
put(e$pa, "fig3_A", 190, 80)
put(e$pa + theme(legend.position = "top") + guides(fill = guide_legend(nrow = 1)), "fig3_B", 190, 90)
yk <- e$yk
pdose <- ggplot(yk, aes(lab, N, group = 1)) +
  geom_col(aes(y = MAS), width = 0.65, fill = "grey90", colour = "grey60", linewidth = 0.2) +
  geom_line(linewidth = 0.4) + geom_point(shape = 23, fill = "white", size = 2) +
  geom_text(aes(label = round(N)), vjust = -1.1, size = (BASE - 1) / .pt, family = FONT) +
  scale_y_continuous(limits = c(0, 320), expand = expansion(c(0, 0))) +
  labs(x = NULL, y = expression("N dose (kg N ha"^-1*")"), subtitle = "balance dose (diamonds) and crop maximum dose (grey bars)") +
  theme_sat() + theme(axis.text.x = element_blank(), plot.subtitle = element_text(size = BASE - 1))
put(add_tags(pdose / (e$pa + theme(legend.position = "right")) + plot_layout(heights = c(0.6, 1))), "fig3_C", 190, 130)
put(e$pa + coord_flip(ylim = c(-130, 310)) + theme(axis.text.y = element_text(size = BASE - 1.5, lineheight = 0.9)),
    "fig3_D", 140, 150)

# ---- Fig. 4: phosphorus and potassium -------------------------------------------------------------
e <- run("fig5_pk.R")
mt <- theme(plot.tag.location = "margin")
put(add_tags(e$pb / (e$pc | e$pd) + plot_layout(heights = c(0.8, 1))) & mt, "fig4_A", 190, 150)
put(add_tags((e$pb | e$pa + theme(legend.position = "none")) / (e$pc | e$pd) +
             plot_layout(heights = c(0.8, 1))) & mt, "fig4_B", 190, 150)
put(add_tags(e$pb | (e$pc / e$pd) + plot_layout(widths = c(1.6, 1))) & mt, "fig4_C", 190, 120)
put(add_tags(e$pb + e$pc + e$pd + plot_layout(widths = c(1.8, 1, 1))) & mt, "fig4_D", 190, 75)

# ---- Fig. 5: Sentinel-2 diagnosis ---------------------------------------------------------------
e <- run("fig5_rs.R")
put(add_tags(e$pa + e$pb), "fig5_A", 140, 75)
put(add_tags(e$pa + e$pb + e$pc), "fig5_B", 190, 75)
put(add_tags(e$pa / e$pb), "fig5_C", 90, 150)
put(add_tags(e$pb + e$pc), "fig5_D", 140, 75)

# ---- Fig. 6: precision-agriculture methods -------------------------------------------------------
e <- run("fig7_strategies.R")
tg <- function(n) plot_annotation(tag_levels = list(c(sprintf("(%s)", letters[1:6]), rep("", n))))
tt <- theme(plot.tag = element_text(family = FONT, face = "bold", size = BASE + 1))
put(e$fig, "fig6_A", 190, 90)
ks <- (plot_spacer() | e$key | plot_spacer())
blk <- function(k, first, vertical) {
  r <- e$rule_plot(k, first); m <- e$map_plot(k)
  if (vertical) wrap_elements(full = r / m + plot_layout(heights = c(0.8, 1))) else wrap_elements(full = r | m + plot_layout(widths = c(1.5, 1)))
}
nm <- names(e$M)
pB <- wrap_plots(Map(blk, nm, seq_along(nm) %in% c(1, 3, 5), FALSE), ncol = 2) / ks + plot_layout(heights = c(3, 0.09)) + tg(3) & tt
put(pB, "fig6_B", 190, 140)
pC <- wrap_plots(Map(blk, nm, seq_along(nm) %in% c(1, 4), TRUE), ncol = 3) / ks + plot_layout(heights = c(2.2, 0.08)) + tg(3) & tt
put(pC, "fig6_C", 190, 165)
# D: the six maps in one row and one panel with the cell-dose distribution of every method
dd <- do.call(rbind, lapply(nm, function(k) data.frame(method = e$TIT[[k]], dose = e$M[[k]], area = e$area)))
dd$method <- factor(dd$method, levels = rev(e$TIT[nm]))
pdist <- ggplot(dd, aes(dose, method)) +
  geom_vline(xintercept = e$Nstar, linetype = "dotted", linewidth = 0.35) +
  geom_jitter(aes(fill = dose, size = area), height = 0.15, width = 0, shape = 21, colour = "grey35", stroke = 0.12) +
  e$DOSE + guides(fill = "none") + scale_size_area(max_size = 1.2, guide = "none") +
  labs(x = expression("Cell dose (kg N ha"^-1*")"), y = NULL) + theme_sat()
maps <- wrap_plots(lapply(nm, function(k) e$map_plot(k) + labs(title = e$TIT[[k]]) +
                            theme(plot.title = element_text(size = BASE - 0.5, face = "bold", hjust = 0.5))), nrow = 1)
pD <- (maps / pdist + plot_layout(heights = c(1, 1.1))) + plot_annotation(tag_levels = list(c(rep("", 6), "")))
put(pD, "fig6_D", 190, 105)
cat("layout variants written to", OUT, "\n")
