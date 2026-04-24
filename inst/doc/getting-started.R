## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
tcc_bind <- Rtinycc::tcc_bind
tcc_compile <- Rtinycc::tcc_compile
tcc_ffi <- Rtinycc::tcc_ffi
tcc_global <- Rtinycc::tcc_global
tcc_include_paths <- Rtinycc::tcc_include_paths
tcc_lib_paths <- Rtinycc::tcc_lib_paths
tcc_link <- Rtinycc::tcc_link
tcc_path <- Rtinycc::tcc_path
tcc_source <- Rtinycc::tcc_source

## -----------------------------------------------------------------------------
tcc_path()
tcc_include_paths()
tcc_lib_paths()

## -----------------------------------------------------------------------------
ffi <- tcc_ffi() |>
  tcc_source(
    "
    static double affine(double x, double slope, double intercept) {
      return slope * x + intercept;
    }
    "
  ) |>
  tcc_bind(
    affine = list(
      args = list("f64", "f64", "f64"),
      returns = "f64"
    )
  ) |>
  tcc_compile()

ffi$affine(2, 3, 4)

## -----------------------------------------------------------------------------
ffi_globals <- tcc_ffi() |>
  tcc_source(
    "
    int shared_counter = 1;

    void bump_counter(void) {
      shared_counter += 1;
    }
    "
  ) |>
  tcc_bind(
    bump_counter = list(args = list(), returns = "void")
  ) |>
  tcc_global("shared_counter", "i32") |>
  tcc_compile()

ffi_globals$global_shared_counter_get()
ffi_globals$bump_counter()
ffi_globals$global_shared_counter_get()

