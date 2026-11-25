# Fig. 6: phosphorus and potassium. (a) P2O5 and K2O doses of plot P01 through the rotation 2019-2026
# (Fig. 3); (b, c) availability classes of
# Olsen P and exchangeable K on the regional 100 m soil maps around the farm, which set the
# strategy (enrichment, maintenance, reduction) of every balance.
# Run from the package root after fig4_p01_years.R:  Rscript paper/softwarex/fig6_pk.R
suppressMessages({ library(sf); library(terra); library(ggplot2); library(patchwork) })
pkgload::load_all(".", quiet = TRUE)
source("paper/softwarex/theme_swx.R")
D <- "paper/softwarex/data"

farm <- st_read(system.file("extdata/piacenza_farm.geojson", package = "agrinutri"), quiet = TRUE)
out  <- farm_balance(farm, p_balance = TRUE, k_balance = TRUE)
yr   <- read.csv(file.path(D, "p01_years.csv"), stringsAsFactors = FALSE)
EN <- c("mais" = "Maize", "cereali vernini" = "Winter cereals", "prato e medica" = "Alfalfa",
        "pomodoro" = "Processing tomato", "altre estive" = "Other summer crops")
yr$class <- ifelse(yr$class %in% names(EN), EN[yr$class], yr$class)

NUT <- c("P[2]*O[5]" = "#999933", "K[2]*O" = "#332288")
bars <- function(d, x) list(
  geom_col(aes(fill = nutrient), position = position_dodge(width = 0.75), width = 0.7,
           colour = "grey20", linewidth = 0.15),
  scale_fill_manual(values = NUT, labels = scales::parse_format(), name = NULL),
  theme_sat(), theme(legend.position = "top", legend.key.size = unit(2.5, "mm")))

fd <- data.frame(plot = rep(paste0(out$plot, "\n", sub(" ", "\n", farm$c2024)), 2), nutrient = rep(names(NUT), each = nrow(out)),
                 kg = c(out$P2O5_target, out$K2O_target))
fd$plot <- factor(fd$plot, levels = unique(fd$plot))
fd$nutrient <- factor(fd$nutrient, levels = names(NUT))
pa <- ggplot(fd, aes(plot, kg)) + bars() + scale_y_continuous(limits = c(0, 310), expand = expansion(c(0, 0.02))) +
  labs(x = NULL, y = expression("Dose (kg ha"^-1*")")) + theme(axis.text.x = element_text(lineheight = 0.9))

yr$lab <- factor(paste0(yr$year, "\n", gsub(" ", "\n", yr$class)), levels = paste0(yr$year, "\n", gsub(" ", "\n", yr$class)))
yd <- data.frame(lab = rep(yr$lab, 2), nutrient = factor(rep(names(NUT), each = nrow(yr)), levels = names(NUT)),
                 kg = c(yr$P2O5, yr$K2O))
pb <- ggplot(yd, aes(lab, kg)) + bars() + scale_y_continuous(limits = c(0, 310), expand = expansion(c(0, 0.02))) +
  labs(x = NULL, y = NULL) + theme(axis.text.x = element_text(size = BASE - 1.5, lineheight = 0.9))

# availability classes on the regional maps (each pixel with its own texture group)
rer <- rast(system.file("extdata/rer_soil_piacenza.tif", package = "agrinutri"))
px  <- as.data.frame(rer, xy = TRUE, na.rm = TRUE)
grp <- mapply(function(c, s) calc_soil_group_and_id_rag(c, s)$soil.group, px$clay, px$sand)
LV  <- c("very low", "low", "medium", "high", "very high")
px$P <- factor(vapply(px$olsen_p, function(v) as.character(classify_P_olsen(v, unit = "P")$rating), ""), levels = LV)
px$K <- factor(mapply(function(v, g) as.character(classify_K(v, unit = "K", soil_group = g)$rating), px$k_exch, grp),
               levels = LV)
CLS <- setNames(c("#b2182b", "#ef8a62", "#d9d9d9", "#67a9cf", "#2166ac"), LV)
fo  <- st_transform(farm, crs(rer))
p1  <- fo[fo$plot == "P01", ]
bb  <- st_bbox(fo)
cmap <- function(v, name) ggplot(px) + geom_raster(aes(x, y, fill = .data[[v]])) +
  geom_sf(data = fo, fill = NA, colour = "black", linewidth = 0.35, inherit.aes = FALSE) +
  geom_sf(data = p1, fill = NA, colour = "black", linewidth = 0.9, inherit.aes = FALSE) +
  scale_fill_manual(values = CLS, name = name) +              # classes present only, fixed colours
  map_furniture(st_bbox(rer), len = 1000) + coord_sf(datum = NA, expand = FALSE) + theme_map() +
  theme(legend.key.width = unit(3, "mm"), legend.key.height = unit(3, "mm")) +
  guides(fill = guide_legend(title.position = "top", nrow = 2))
pc <- cmap("P", "Olsen P class")
pd <- cmap("K", "Exchangeable K class")
cat("classes around the farm\n"); print(table(P = px$P)); print(table(K = px$K))
print(st_drop_geometry(out)[, c("plot", "crop", "P2O5_target", "K2O_target")])

pb <- pb + labs(y = expression("Dose (kg ha"^-1*")"))
pa <- pa + theme(legend.position = "none")
save_fig(add_tags(pb / (pc | pd) + plot_layout(heights = c(0.85, 1))) & theme(plot.tag.location = "margin"), "fig6_pk", "double", 135)
