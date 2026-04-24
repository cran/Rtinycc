## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
tcc_bind <- Rtinycc::tcc_bind
tcc_compile <- Rtinycc::tcc_compile
tcc_ffi <- Rtinycc::tcc_ffi
tcc_free <- Rtinycc::tcc_free
tcc_malloc <- Rtinycc::tcc_malloc
tcc_source <- Rtinycc::tcc_source

## -----------------------------------------------------------------------------
ffi <- tcc_ffi() |>
  tcc_source(
    "
    int add_i32(int a, int b) { return a + b; }
    double mul_f64(double x, double y) { return x * y; }
    int negate_bool(_Bool x) { return !x; }
    "
  ) |>
  tcc_bind(
    add_i32 = list(args = list("i32", "i32"), returns = "i32"),
    mul_f64 = list(args = list("f64", "f64"), returns = "f64"),
    negate_bool = list(args = list("bool"), returns = "bool")
  ) |>
  tcc_compile()

ffi$add_i32(2L, 3L)
ffi$mul_f64(2, 4)
ffi$negate_bool(TRUE)

## -----------------------------------------------------------------------------
ffi_str <- tcc_ffi() |>
  tcc_source(
    "
    const char* echo_cstring(const char* s) { return s; }
    void* echo_ptr(void* p) { return p; }
    "
  ) |>
  tcc_bind(
    echo_cstring = list(args = list("cstring"), returns = "cstring"),
    echo_ptr = list(args = list("ptr"), returns = "ptr")
  ) |>
  tcc_compile()

ptr <- tcc_malloc(8)

ffi_str$echo_cstring("hello")
inherits(ffi_str$echo_ptr(ptr), "externalptr")

tcc_free(ptr)

## -----------------------------------------------------------------------------
ffi_arr <- tcc_ffi() |>
  tcc_source(
    "
    int first_int(int* x) { return x[0]; }
    double second_num(double* x) { return x[1]; }
    "
  ) |>
  tcc_bind(
    first_int = list(args = list("integer_array"), returns = "i32"),
    second_num = list(args = list("numeric_array"), returns = "f64")
  ) |>
  tcc_compile()

ffi_arr$first_int(as.integer(c(10, 20, 30)))
ffi_arr$second_num(c(1.5, 2.5))

## -----------------------------------------------------------------------------
ffi_sexp <- tcc_ffi() |>
  tcc_source(
    "
    #include <Rinternals.h>

    SEXP id_sexp(SEXP x) { return x; }
    "
  ) |>
  tcc_bind(
    id_sexp = list(args = list("sexp"), returns = "sexp")
  ) |>
  tcc_compile()

ffi_sexp$id_sexp(list(a = 1, b = 2))

