noMargins <- function(..., topkey = FALSE, rightkey = FALSE) {
  
  nmlist <- list(
    layout.heights = list(
      top.padding = 0,
      #main.key.padding = 0,
      #key.axis.padding = 0,
      #axis.xlab.padding = 0,
      #xlab.key.padding = 0,
      #key.sub.padding = 0,
      bottom.padding = 0.5
    ),
    layout.widths = list(
      left.padding = 0,
      #key.ylab.padding = 0,
      #ylab.axis.padding = 0,
      #axis.key.padding = 0,
      right.padding = 0.6
    ),
    axis.components = list(
      top = list(pad1 = ifelse(topkey, 2, 1), pad2 = ifelse(topkey, 2, 0)), # padding above top axis
      right = list(pad1 = 0, pad2 = 0)
    )
  )
  # TODO: allow "..." to override any elements in "nmlist"
  c(nmlist, ...)
}

# helper function to display color palette
pal <- function(col, border = "light gray", ...) {
  n <- length(col)
  plot(0, 0, type = "n", xlim = c(0, 1), ylim = c(0, 1), axes = FALSE, xlab = "", 
       ylab = "", ...)
  rect(0:(n - 1)/n, 0, 1:n/n, 1, col = col, border = border)
}