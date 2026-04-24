## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
tcc_compile <- Rtinycc::tcc_compile
tcc_link <- Rtinycc::tcc_link
is_windows <- .Platform$OS.type == "windows"
find_system_math_library <- function() {
  if (is_windows) {
    return(NULL)
  }

  sysname <- as.character(unname(Sys.info()[["sysname"]]))
  paths <- unique(Rtinycc:::tcc_library_search_paths(sysname))
  patterns <- switch(
    sysname,
    Linux = c("^libm\\.so(\\.[0-9]+)+$"),
    Darwin = c("^libSystem\\.B\\.dylib$", "^libm\\.dylib$"),
    character(0)
  )

  for (pattern in patterns) {
    for (path in paths) {
      if (!dir.exists(path)) {
        next
      }
      candidates <- list.files(
        path,
        pattern = pattern,
        full.names = TRUE
      )
      if (length(candidates) > 0L) {
        return(candidates[[1]])
      }
    }
  }

  NULL
}
math_lib_path <- find_system_math_library()

## ----eval = !is_windows && !is.null(math_lib_path)----------------------------
math <- tcc_link(
  math_lib_path,
  symbols = list(
    sqrt = list(args = list("f64"), returns = "f64"),
    cos = list(args = list("f64"), returns = "f64")
  )
)

math$sqrt(25)
math$cos(0)

## ----eval = !is_windows && !is.null(math_lib_path)----------------------------
math_helpers <- tcc_link(
  math_lib_path,
  symbols = list(
    sqrt = list(args = list("f64"), returns = "f64"),
    hypot2_checked = list(args = list("f64", "f64"), returns = "f64")
  ),
  user_code = "
    #include <math.h>

    double hypot2_checked(double x, double y) {
      if (x < 0 || y < 0) {
        return NAN;
      }
      return sqrt(x * x + y * y);
    }
  "
)

math_helpers$hypot2_checked(3, 4)
is.nan(math_helpers$hypot2_checked(-1, 4))

