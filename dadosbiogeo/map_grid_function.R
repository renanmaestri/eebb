#' Map grid data using R base with lat/lon axes
#'
#' @param x        numeric vector of x coordinates (projected meters or degrees)
#' @param y        numeric vector of y coordinates
#' @param z        values to colour-map: numeric (sequential/diverging) or factor/integer (categorical)
#' @param worldmap sf object for continent outlines (e.g. epm:::worldmap). Omit or NULL to skip.
#' @param crs      PROJ string, integer EPSG code, or st_crs object. 
#'                 Use 4326 (or NULL) for unprojected decimal-degree data.
#' @param palette  colour specification: a function (e.g. colorRampPalette(...) or viridisLite::turbo),
#'                 a character vector of colours, or NULL for sensible defaults.
#' @param n_col    number of colour bins for continuous data (default 100).
#' @param type     one of "auto", "sequential", "diverging", "categorical".
#'                 Auto detects: diverging if z crosses 0, categorical if factor/integer with <= 12 levels.
#' @param zlim     custom range c(min, max) for continuous data.
#' @param legend_title  legend title (character).
#' @param legend_position legend position, passed to legend().
#' @param pch,cex  point symbol and size.
#' @param ...      additional arguments passed to plot() (main, xlab, ylab, etc.).
#'
#' @return invisibly returns list(cols, palette, type, z_range).
#'
#' @examples
#' \dontrun{
#'   sr <- rowSums(occurrence.spp)
#'   map_grid(coords$x, coords$y, sr, worldmap = epm:::worldmap,
#'            xlab = "Longitude", ylab = "Latitude",
#'            legend_title = "SR", main = "Richness")
#' }

map_grid <- function(x, y, z,
                     worldmap = NULL,
                     crs = '+proj=moll +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs',
                     palette = NULL,
                     n_col = 100,
                     type = c("auto", "sequential", "diverging", "categorical"),
                     zlim = NULL,
                     legend_title = "",
                     legend_position = "bottomleft",
                     pch = 15,
                     cex = 1,
                     ...) {

  type <- match.arg(type)
  has_world <- !is.null(worldmap)
  has_crs <- !is.null(crs)

  # ---- detect type ----
  if (type == "auto") {
    if (is.factor(z) || is.integer(z) && length(unique(z)) <= 12) {
      type <- "categorical"
    } else if (any(z < 0, na.rm = TRUE) && any(z > 0, na.rm = TRUE)) {
      type <- "diverging"
    } else {
      type <- "sequential"
    }
  }

  # ---- build palette & bins ----
  if (type == "categorical") {
    uv <- sort(unique(z))
    n_lev <- length(uv)
    if (is.null(palette)) {
      qual <- c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#FFFF33",
                "#A65628","#F781BF","#999999","#66C2A5","#FC8D62","#8DA0CB")
      pal <- rep(qual, length.out = n_lev)
    } else if (is.function(palette)) {
      pal <- palette(n_lev)
    } else {
      pal <- rep(palette, length.out = n_lev)
    }
    names(pal) <- as.character(uv)
    cols <- pal[as.character(z)]
    rng <- NULL
    brk <- NULL

  } else {
    rng <- if (!is.null(zlim)) zlim else range(z, na.rm = TRUE)
    if (diff(rng) == 0) rng <- rng + c(-1, 1) * 1e-6

    if (type == "diverging") {
      if (is.null(palette)) {
        if (rng[1] >= 0) {
          pal <- colorRampPalette(c("#f7f7f7", "#d73027"))(n_col)
          brk <- seq(rng[1], rng[2], length.out = n_col + 1)
        } else if (rng[2] <= 0) {
          pal <- colorRampPalette(c("#2166ac", "#f7f7f7"))(n_col)
          brk <- seq(rng[1], rng[2], length.out = n_col + 1)
        } else {
          prop_neg <- -rng[1] / diff(rng)
          n_neg <- max(1, round(n_col * prop_neg))
          n_pos <- max(1, n_col - n_neg)
          pal_neg <- colorRampPalette(c("#2166ac", "#f7f7f7"))(n_neg + 1)[seq_len(n_neg)]
          pal_pos <- colorRampPalette(c("#f7f7f7", "#d73027"))(n_pos + 1)[-1]
          pal <- c(pal_neg, pal_pos)
          brk <- seq(rng[1], rng[2], length.out = n_col + 1)
        }
      } else if (is.function(palette)) {
        pal <- palette(n_col)
        brk <- seq(rng[1], rng[2], length.out = n_col + 1)
      } else {
        pal_fn <- colorRampPalette(palette)
        pal <- pal_fn(n_col)
        brk <- seq(rng[1], rng[2], length.out = n_col + 1)
      }
    } else {
      if (is.null(palette)) {
        pal_fn <- colorRampPalette(c("#00007F","blue","#007FFF","cyan",
                                     "#7FFF7F","yellow","#FF7F00","red","#7F0000"))
      } else if (is.function(palette)) {
        pal_fn <- palette
      } else {
        pal_fn <- colorRampPalette(palette)
      }
      pal <- pal_fn(n_col)
      brk <- seq(rng[1], rng[2], length.out = n_col + 1)
    }
    binned <- cut(z, breaks = brk, include.lowest = TRUE, labels = FALSE)
    cols <- pal[binned]
  }

  # ---- plot with blank axes ----
  plot(x, y, col = cols, pch = pch, cex = cex, axes = FALSE, ...)

  # ---- custom lat/lon axes for projected data ----
  is_wgs84 <- FALSE
  if (has_crs) {
    crs_obj <- tryCatch(st_crs(crs), error = function(e) NULL)
    if (!is.null(crs_obj) && length(crs_obj$epsg) == 1 && !is.na(crs_obj$epsg)) {
      is_wgs84 <- crs_obj$epsg == 4326
    }
  }
  if (has_crs && !is_wgs84) {
    at_x <- pretty(x)
    at_y <- pretty(y)
    m_y <- mean(y, na.rm = TRUE)
    m_x <- mean(x, na.rm = TRUE)
    xy_x <- st_sfc(lapply(at_x, function(v) st_point(c(v, m_y))), crs = st_crs(crs))
    xy_y <- st_sfc(lapply(at_y, function(v) st_point(c(m_x, v))), crs = st_crs(crs))
    xy_x <- st_transform(xy_x, 4326)
    xy_y <- st_transform(xy_y, 4326)
    axis(1, at = at_x, labels = round(sapply(xy_x, function(p) p[1]), 1))
    axis(2, at = at_y, labels = round(sapply(xy_y, function(p) p[2]), 1))
  } else {
    axis(1)
    axis(2)
  }
  box()

  # ---- worldmap overlay ----
  if (has_world) {
    if (has_crs && !is_wgs84) {
      wm <- st_transform(worldmap, st_crs(crs))
    } else {
      wm <- worldmap
    }
    plot(wm, lwd = 0.8, add = TRUE)
  }

  # ---- legend ----
  if (type == "categorical") {
    legend(legend_position, legend = names(pal), fill = pal,
           title = legend_title, bty = "n")
  } else {
    lbl <- pretty(rng, 5)
    lbl <- lbl[lbl >= rng[1] & lbl <= rng[2]]
    if (length(lbl) < 2) lbl <- seq(rng[1], rng[2], length.out = 5)
    lcols <- pal[cut(lbl, breaks = brk, include.lowest = TRUE, labels = FALSE)]
    legend(legend_position, legend = round(lbl, 2), fill = lcols,
           title = legend_title, bty = "n")
  }

  invisible(list(cols = cols, palette = pal, type = type, z_range = rng))
}
