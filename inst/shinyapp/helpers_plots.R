# helpers_plots.R
# Reusable ggplot helpers for the agrinutri Shiny app.
# Loaded by global.R.

# Synthetic demo rasters and helpers
# ---------------------------------------------------------------------

# Generate a plausible NDVI raster over a given sf polygon. Returns a
# SpatRaster consumed by the terra-based pipeline.
.agrinutri_demo_ndvi <- function(field, res_m = 5, seed = 42) {
  if (!requireNamespace("terra", quietly = TRUE) ||
      !requireNamespace("sf", quietly = TRUE)) return(NULL)
  set.seed(seed)
  fp <- sf::st_transform(field, 3857)
  bb <- sf::st_bbox(fp)
  nx <- max(20, as.integer((bb$xmax - bb$xmin) / res_m))
  ny <- max(20, as.integer((bb$ymax - bb$ymin) / res_m))
  r  <- terra::rast(xmin = bb$xmin, xmax = bb$xmax,
                    ymin = bb$ymin, ymax = bb$ymax,
                    ncols = nx, nrows = ny, crs = "EPSG:3857")
  # Smooth gradient + two low-vigour patches + noise
  x <- seq(0, 1, length.out = nx)
  y <- seq(0, 1, length.out = ny)
  gx <- matrix(x, nrow = ny, ncol = nx, byrow = TRUE)
  gy <- matrix(y, nrow = ny, ncol = nx)
  base <- 0.72 + 0.05 * sin(4 * gx) + 0.04 * cos(5 * gy)
  patch1 <- 0.20 * exp(-(((gx - 0.30)^2 + (gy - 0.35)^2) / 0.008))
  patch2 <- 0.24 * exp(-(((gx - 0.70)^2 + (gy - 0.55)^2) / 0.006))
  z <- base - patch1 - patch2 + 0.03 * matrix(rnorm(nx * ny), ny, nx)
  z <- pmin(pmax(z, 0.30), 0.92)
  terra::values(r) <- as.vector(z)
  r <- terra::mask(r, terra::vect(fp))
  r
}

# A plausible NNI raster (0.7-1.25) synthesised the same way
.agrinutri_demo_nni <- function(field, res_m = 5, seed = 7) {
  r <- .agrinutri_demo_ndvi(field, res_m, seed)
  if (is.null(r)) return(NULL)
  # remap NDVI 0.3-0.9 -> NNI 0.7-1.25
  v <- terra::values(r, mat = FALSE)
  v <- 0.70 + (v - 0.30) / (0.90 - 0.30) * (1.25 - 0.70)
  terra::values(r) <- v
  r
}

# Palette matching the scientific article
.C_ADD_DARK   <- "#C0392B"
.C_ADD_FILL   <- "#F2D7D5"
.C_GREEN_DARK <- "#2F7A44"
.C_GREEN_FILL <- "#D5ECDB"
.C_BLUE_DARK  <- "#1F4E79"
.C_BLUE_FILL  <- "#D5E4F0"
.C_GOLD       <- "#C08A3C"
.C_GREY       <- "#888888"

# ---------------------------------------------------------------------
# Waterfall chart for the crop N balance.
# df has columns: term (factor), value (numeric, always positive),
# sign ('+' or '-').
# Returns a ggplot that walks from term A (additive) to the net N*,
# with connector segments between bars and the final Net bar highlighted.
# ---------------------------------------------------------------------
.agrinutri_waterfall <- function(df, net_value, mas_cap = NA) {
  if (is.null(df) || !all(c("term", "value", "sign") %in% names(df)) ||
      nrow(df) == 0)
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::annotate("text", x = 0, y = 0,
               label = "no balance terms available", size = 4,
               colour = "#888"))
  # Replace any NA value with 0 so cumsum doesn't propagate NA
  df$value[is.na(df$value) | !is.finite(df$value)] <- 0
  # Coerce net_value / mas_cap to scalar
  if (is.null(net_value) || length(net_value) == 0 ||
      !is.finite(suppressWarnings(as.numeric(net_value)[1])))
    net_value <- sum(ifelse(df$sign == "+", df$value, -df$value),
                      na.rm = TRUE)
  else net_value <- as.numeric(net_value)[1]
  if (is.null(mas_cap) || length(mas_cap) == 0) mas_cap <- NA_real_
  else mas_cap <- suppressWarnings(as.numeric(mas_cap)[1])

  df$signed <- ifelse(df$sign == "+", df$value, -df$value)
  df$cum_end   <- cumsum(df$signed)
  df$cum_start <- c(0, head(df$cum_end, -1))
  df$fill <- ifelse(df$sign == "+", .C_ADD_FILL, .C_GREEN_FILL)
  df$col  <- ifelse(df$sign == "+", .C_ADD_DARK, .C_GREEN_DARK)
  df$idx  <- seq_len(nrow(df))

  net_df <- data.frame(
    term      = "Net N*",
    idx       = nrow(df) + 1,
    cum_start = 0,
    cum_end   = net_value,
    signed    = net_value,
    fill      = .C_BLUE_FILL,
    col       = .C_BLUE_DARK
  )
  plot_df <- rbind(df[, c("term", "idx", "cum_start", "cum_end",
                           "signed", "fill", "col")],
                    net_df)
  # Connector segments between consecutive term-bars (not to Net)
  n_terms <- nrow(df)
  conn <- data.frame(
    x    = df$idx[-n_terms] + 0.4,
    xend = df$idx[-n_terms] + 0.6,
    y    = df$cum_end[-n_terms],
    yend = df$cum_end[-n_terms]
  )

  g <- ggplot2::ggplot(plot_df) +
    # zero line
    ggplot2::geom_hline(yintercept = 0, colour = "grey30") +
    # the bars
    ggplot2::geom_rect(
      ggplot2::aes(xmin = idx - 0.4, xmax = idx + 0.4,
                   ymin = cum_start, ymax = cum_end,
                   fill = I(fill), colour = I(col)),
      linewidth = 0.6) +
    # connector dotted segments
    ggplot2::geom_segment(
      data = conn,
      ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
      linetype = "13", colour = .C_GREY, linewidth = 0.5) +
    # value labels at the top of each bar
    ggplot2::geom_text(
      ggplot2::aes(x = idx, y = pmax(cum_start, cum_end),
                   label = sprintf("%+.0f", signed)),
      vjust = -0.4, size = 3.4, colour = "grey20") +
    # Net bar value at the bottom
    ggplot2::annotate("text",
      x = nrow(df) + 1, y = net_value * 0.5,
      label = sprintf("Net\n%.0f", net_value),
      fontface = "bold", colour = .C_BLUE_DARK, size = 4.2) +
    ggplot2::scale_x_continuous(
      breaks = plot_df$idx,
      labels = as.character(plot_df$term),
      expand = ggplot2::expansion(add = c(0.5, 0.5))) +
    ggplot2::labs(x = NULL, y = expression("kg N ha"^-1)) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.text.x        = ggplot2::element_text(face = "bold", size = 11))

  if (is.finite(mas_cap))
    g <- g +
      ggplot2::geom_hline(yintercept = mas_cap, linetype = "dashed",
                           colour = .C_ADD_DARK, linewidth = 0.7) +
      ggplot2::annotate("text",
        x = nrow(df) + 1, y = mas_cap,
        label = sprintf("MAS = %.0f", mas_cap),
        hjust = 1, vjust = -0.4, colour = .C_ADD_DARK, size = 3.3)
  g
}

# ---------------------------------------------------------------------
# Traffic-light semicircular gauge for MAS / ZVN compliance.
# 0-1 ratio, renders in ggplot.
# ---------------------------------------------------------------------
.agrinutri_gauge <- function(value, limit, label = "MAS",
                         ok_below = 0.80, warn_below = 1.00) {
  # Coerce NULL / length-0 / non-finite to scalar NA, then guard.
  value <- if (is.null(value) || length(value) == 0) NA_real_
            else suppressWarnings(as.numeric(value)[1])
  limit <- if (is.null(limit) || length(limit) == 0) NA_real_
            else suppressWarnings(as.numeric(limit)[1])
  if (is.na(value) || is.na(limit) ||
      !is.finite(value) || !is.finite(limit) || limit <= 0)
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::annotate("text", x = 0, y = 0,
               label = if (!is.na(label)) label else "--",
               size = 4, colour = "#999"))
  ratio <- value / limit
  clamped <- min(max(ratio, 0), 1.3)
  # Gauge arc from -90 deg to +90 deg
  arc_theta <- function(r) pi - pi * r / 1.0   # r=0 -> pi; r=1 -> 0
  theta_end <- arc_theta(pmin(clamped, 1.3))
  theta     <- seq(pi, 0, length.out = 180)
  # background segments
  bg_ok   <- data.frame(theta = seq(pi, arc_theta(ok_below),     length.out = 60))
  bg_wrn  <- data.frame(theta = seq(arc_theta(ok_below),
                                     arc_theta(warn_below),       length.out = 40))
  bg_bad  <- data.frame(theta = seq(arc_theta(warn_below),
                                     arc_theta(1.3),              length.out = 40))
  arc_df <- function(d, col) {
    d$r1 <- 0.9; d$r2 <- 1.0; d$col <- col; d
  }
  all_bg <- rbind(arc_df(bg_ok,  .C_GREEN_DARK),
                  arc_df(bg_wrn, .C_GOLD),
                  arc_df(bg_bad, .C_ADD_DARK))

  # The needle
  needle_theta <- arc_theta(clamped)
  needle <- data.frame(
    x = c(0, cos(needle_theta) * 0.92),
    y = c(0, sin(needle_theta) * 0.92)
  )

  g <- ggplot2::ggplot() +
    # coloured arcs (as segments on a dense polyline)
    ggplot2::geom_path(
      data = all_bg,
      ggplot2::aes(x = cos(theta) * 0.95, y = sin(theta) * 0.95,
                   colour = I(col), group = col),
      linewidth = 8, lineend = "butt") +
    # needle (single-row data so aesthetics have length 1)
    ggplot2::geom_segment(
      data = data.frame(x = needle$x[1], y = needle$y[1],
                        xend = needle$x[2], yend = needle$y[2]),
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      linewidth = 1.3, colour = "grey20",
      arrow = grid::arrow(length = grid::unit(0.15, "cm"))) +
    ggplot2::geom_point(ggplot2::aes(x = 0, y = 0),
                        size = 3, colour = "grey20") +
    # value and label
    ggplot2::annotate("text", x = 0, y = -0.22,
      label = sprintf("%.0f / %.0f", value, limit),
      size = 5.5, fontface = "bold",
      colour = if (ratio >= 1) .C_ADD_DARK else
               if (ratio >= ok_below) .C_GOLD else .C_GREEN_DARK) +
    ggplot2::annotate("text", x = 0, y = -0.45,
      label = label, size = 4.2, colour = "grey30") +
    ggplot2::coord_fixed(xlim = c(-1.1, 1.1),
                         ylim = c(-0.55, 1.1)) +
    ggplot2::theme_void()
  g
}

# ---------------------------------------------------------------------
# Compliance panel: two gauges side by side.
# ---------------------------------------------------------------------
.agrinutri_compliance_pair <- function(net, mas, zvn_applied, zvn_limit = 170) {
  # Coerce NULL / length-0 / non-finite to scalar NA so the inner
  # gauge helpers can render the "no data" fallback without crashing.
  sc <- function(x) if (is.null(x) || length(x) == 0) NA_real_
                    else suppressWarnings(as.numeric(x)[1])
  net         <- sc(net)
  mas         <- sc(mas)
  zvn_applied <- sc(zvn_applied)
  zvn_limit   <- sc(zvn_limit)
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    return(.agrinutri_gauge(net, mas, "Net N*  vs  MAS"))
  }
  g1 <- .agrinutri_gauge(net, mas, "Net N*  vs  MAS cap")
  g2 <- .agrinutri_gauge(zvn_applied, zvn_limit,
                     "Livestock N  vs  ZVN 170 kg/ha")
  patchwork::wrap_plots(g1, g2, ncol = 2)
}

# ---------------------------------------------------------------------
# Histogram of a raster layer, coloured by user-supplied bins.
# ---------------------------------------------------------------------
.agrinutri_raster_hist <- function(r, breaks, bin_colors = NULL,
                               xlab = "value", cumulative = TRUE) {
  vals <- tryCatch({
    v <- if (inherits(r, "SpatRaster"))
           terra::values(r, na.rm = TRUE)
         else terra::values(terra::rast(r), na.rm = TRUE)
    v[!is.na(v) & is.finite(v)]
  }, error = function(e) NULL)
  if (is.null(vals) || length(vals) == 0)
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::annotate("text", x = 0, y = 0, label = "no data"))
  df <- data.frame(v = vals)
  b  <- seq(min(vals), max(vals), length.out = 30)
  g <- ggplot2::ggplot(df, ggplot2::aes(x = v)) +
    ggplot2::geom_histogram(bins = 30, fill = .C_BLUE_FILL,
                            colour = .C_BLUE_DARK, linewidth = 0.3) +
    ggplot2::labs(x = xlab, y = "pixel count") +
    ggplot2::theme_minimal(base_size = 11)
  # Add threshold lines
  if (!is.null(breaks)) {
    g <- g +
      ggplot2::geom_vline(xintercept = breaks,
                          linetype = "dashed",
                          colour = .C_ADD_DARK, linewidth = 0.7)
  }
  g
}

# ---------------------------------------------------------------------
# Area-per-zone summary for NNI zone rasters (1 deficient / 2 optimal /
# 3 excessive).
# ---------------------------------------------------------------------
.agrinutri_zone_area <- function(zones_rast, pixel_area_m2 = NULL) {
  if (inherits(zones_rast, "SpatRaster")) {
    v <- terra::values(zones_rast, na.rm = TRUE)
    if (is.null(pixel_area_m2)) {
      res <- terra::res(zones_rast)
      pixel_area_m2 <- prod(res)
    }
  } else {
    zr <- terra::rast(zones_rast)
    v <- terra::values(zr, mat = FALSE)
    v <- v[!is.na(v)]
    if (is.null(pixel_area_m2)) {
      res <- terra::res(zr)
      pixel_area_m2 <- prod(res)
    }
  }
  tab <- table(factor(round(v), levels = 1:3))
  ha  <- as.numeric(tab) * pixel_area_m2 / 1e4
  pct <- if (sum(tab) > 0) 100 * as.numeric(tab) / sum(tab) else rep(0, 3)
  data.frame(
    zone    = c("Deficient", "Optimal", "Excessive"),
    code    = 1:3,
    ha      = round(ha, 2),
    percent = round(pct, 1),
    colour  = c(.C_ADD_DARK, .C_GREEN_DARK, .C_BLUE_DARK),
    stringsAsFactors = FALSE
  )
}

.agrinutri_zone_bar <- function(zone_df) {
  zone_df$zone <- factor(zone_df$zone,
                         levels = c("Deficient", "Optimal", "Excessive"))
  ggplot2::ggplot(zone_df,
    ggplot2::aes(x = zone, y = percent, fill = I(colour))) +
    ggplot2::geom_col(width = 0.7, colour = "grey30") +
    ggplot2::geom_text(ggplot2::aes(
      label = sprintf("%.1f %%\n(%.1f ha)", percent, ha)),
      vjust = -0.2, size = 3.6) +
    ggplot2::labs(x = NULL, y = "area fraction (%)") +
    ggplot2::ylim(0, max(zone_df$percent) * 1.20 + 5) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank())
}

# ---------------------------------------------------------------------
# Stacked bar chart for the distribution plan (pre-sowing organic vs
# mineral side-dress vs remaining target).
# ---------------------------------------------------------------------
.agrinutri_plan_stack <- function(applied_organic, applied_mineral,
                              n_target, mas_cap = NA, zvn = 170) {
  d <- data.frame(
    source = c("Pre-sowing organic", "In-season mineral"),
    value  = c(applied_organic, applied_mineral)
  )
  d$source <- factor(d$source, levels = rev(d$source))
  g <- ggplot2::ggplot(d,
    ggplot2::aes(x = "Applied N", y = value, fill = source)) +
    ggplot2::geom_col(width = 0.45, colour = "grey30") +
    ggplot2::scale_fill_manual(values = c(
      "Pre-sowing organic" = .C_GREEN_FILL,
      "In-season mineral"  = .C_BLUE_FILL)) +
    ggplot2::geom_hline(yintercept = n_target, linetype = "dashed",
                        colour = .C_BLUE_DARK, linewidth = 0.7) +
    ggplot2::annotate("text",
                       x = 1.3, y = n_target,
                       label = sprintf("N target = %.0f", n_target),
                       hjust = 0, size = 3.4, colour = .C_BLUE_DARK)
  if (is.finite(mas_cap))
    g <- g +
      ggplot2::geom_hline(yintercept = mas_cap, linetype = "dotted",
                          colour = .C_ADD_DARK, linewidth = 0.8) +
      ggplot2::annotate("text",
        x = 1.3, y = mas_cap,
        label = sprintf("MAS = %.0f", mas_cap),
        hjust = 0, size = 3.4, colour = .C_ADD_DARK)
  g +
    ggplot2::geom_hline(yintercept = zvn, linetype = "dotted",
                        colour = "grey40", linewidth = 0.6) +
    ggplot2::annotate("text", x = 1.3, y = zvn,
                       label = sprintf("ZVN limit = %.0f", zvn),
                       hjust = 0, size = 3.2, colour = "grey40") +
    ggplot2::coord_flip(clip = "off") +
    ggplot2::labs(x = NULL, y = expression("kg N ha"^-1),
                   fill = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(5, 90, 5, 5),
      legend.position = "top",
      panel.grid.major.y = ggplot2::element_blank())
}
