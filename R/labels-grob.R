#' Like the margin function in ggplot2
#'
#' @param t,r,b,l top, right, bottom, left margins
#' @param unit unit in which margins are measured
#' @export
mar <- function(t = 0, r = 0, b = 0, l = 0, unit = "pt") {
  structure(unit(c(t, r, b, l), unit), class = c("margin", "unit"))
}

#' Create grob representing one or more labels
#'
#' The function `labels_grob()` creates one or more labels. All label data is provided
#' in the form of a data frame/tibble holding aesthetic values as columns and label
#' information as rows.
#'
#' @param label_data Tibble holding the label data. At a minimum, needs a
#'   `label` column holding the text labels to be drawn
#' @param align_frames Bool indicating whether frames should have equal
#'   sizes (`TRUE`) or not (`FALSE`).
#' @param gp Additional graphical parameters not provided via `label_data`.
#' @param debug Bool indicating whether debugging info should be drawn.
#' @examples
#' library(grid)
#' library(tibble)
#'
#' label_data <- tibble(
#'   label = c("Descenders: pgqjy", "This is a label\nwith two lines", "Hello!"),
#'   x = unit(.4, "npc"),
#'   y = unit(c(.9, .5, .3), "npc"),
#'   box_hjust = 0,
#'   box_vjust = 0.5,
#'   hjust = 1,
#'   vjust = 1,
#'   color = "blue",
#'   fill = "azure1",
#'   fontsize = 10,
#'   fontfamily = "Comic Sans MS",
#'   angle = c(0, 45, -45),
#'   padding = list(mar(5, 5, 3, 5)),
#'   margin = list(mar(5, 5, 5, 5))
#' )
#'
#' grid.newpage()
#' g <- labels_grob(label_data, align_frames = TRUE)
#' grid.draw(g)
#'
#'
#' label_data <- tibble(
#'   label = c("This", "is", "a", "test", "x-axis"),
#'   x = unit(c(.1, .3, .5, .7, .9), "npc"),
#'   y = unit(0.5, "npc"),
#'   box_hjust = 0.5,
#'   box_vjust = 1,
#'   hjust = 0.5,
#'   vjust = 1,
#'   angle = 0,
#'   fontsize = 10, fontfamily = "Comic Sans MS",
#'   padding = list(mar(5, 5, 3, 5)),
#'   margin = list(mar(5, 5, 5, 5))
#' )
#' grid.newpage()
#' g <- labels_grob(label_data, align_frames = TRUE, debug = TRUE)
#' grid.draw(g)
#'
#'
#' label_data <- tibble(label = "abcqgy", fontsize = 50, fontfamily = "Comic Sans MS")
#' grid.newpage()
#' grid.draw(labels_grob(label_data))
#' @export
labels_grob <- function(label_data, align_frames = FALSE, debug = FALSE) {
  txt_grobs <- pmap(label_data, text_grob)
  width_pt <- vapply(txt_grobs, grob_width_pt, numeric(1))
  height_pt <- vapply(txt_grobs, grob_height_pt, numeric(1))
  descent_pt <- vapply(txt_grobs, grob_descent_pt, numeric(1))

  if (isTRUE(align_frames)) { # if label frames should be equalized
    width_pt <- max(width_pt)
    height_pt <- max(height_pt)
  }

  txt_data <- tibble(
    grob = txt_grobs,
    width_pt = width_pt,
    height_pt = height_pt,
    descent_pt = descent_pt
  )

  txt_data <- cbind(txt_data, label_data)
  grobs <- pmap(txt_data, add_box, debug = debug)

  children <- do.call(gList, grobs)
  grobTree(children)
}

#' create individual labels for labels_grob
text_grob <- function(label, hjust = 0.5, vjust = 0.5, fontfamily = "", fontface = "plain",
                      fontsize = 12, lineheight = 1.1, color = "black", ...) {
  gp <- gpar(
    col = color,
    fontfamily = fontfamily,
    fontface = fontface,
    fontsize = fontsize,
    lineheight = lineheight
  )
  textGrob(label, x = hjust, y = vjust, hjust = hjust, vjust = vjust, gp = gp)
}

#' make frame around text grobs
add_box <- function(grob, width_pt, height_pt, descent_pt,
                    x = unit(0.5, "npc"), y = unit(0.5, "npc"),
                    box_hjust = 0.5, box_vjust = 0.5, padding = mar(0, 0, 0, 0),
                    margin = mar(0, 0, 0, 0), angle = 0, fill = NA, color = NA,
                    frame_color = NULL,
                    ..., debug = FALSE) {
  widths <- unit.c(margin[4], padding[4], unit(width_pt, "pt"), padding[2], margin[2])
  heights <- unit.c(margin[1], padding[1], unit(c(height_pt, descent_pt), "pt"), padding[3], margin[3])

  vp <- viewport(
    x = x, y = y, just = c(box_hjust, box_vjust),
    width = sum(widths),
    height = sum(heights),
    angle = angle,
    layout = grid.layout(6, 5, heights = heights, widths = widths)
  )

  text_grob <- editGrob(
    grob,
    vp = viewport(layout.pos.row = 3, layout.pos.col = 3)
  )

  color <- frame_color %||% color

  if (isTRUE(debug)) {
    if (is.na(color)) color <- "black"
    if (is.na(fill)) fill <- "azure1"
  }

  pad_grob <- rectGrob(
    gp = gpar(fill = fill, col = color),
    vp = viewport(layout.pos.row = c(2, 5), layout.pos.col = c(2, 4))
  )

  if (isTRUE(debug)) {
    marg_grob <- rectGrob(
      gp = gpar(fill = "azure2", col = NA),
      vp = viewport(layout.pos.row = c(1, 6), layout.pos.col = c(1, 5))
    )

    point_grob <- pointsGrob(
      unit(box_hjust, "npc"), unit(box_vjust, "npc"), pch = 20, gp = gpar(col = "azure4"),
      vp = viewport(layout.pos.row = c(1, 6), layout.pos.col = c(1, 5))
    )

    children <- gList(
      marg_grob, pad_grob, point_grob, text_grob
    )
  } else {
    children <- gList(pad_grob, text_grob)
  }

  grobTree(
    children,
    vp = vp
  )
}

