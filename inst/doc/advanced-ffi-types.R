## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
tcc_bind <- Rtinycc::tcc_bind
tcc_callback <- Rtinycc::tcc_callback
tcc_callback_async_drain <- Rtinycc::tcc_callback_async_drain
tcc_callback_close <- Rtinycc::tcc_callback_close
tcc_callback_ptr <- Rtinycc::tcc_callback_ptr
tcc_compile <- Rtinycc::tcc_compile
tcc_ffi <- Rtinycc::tcc_ffi
tcc_global <- Rtinycc::tcc_global
tcc_source <- Rtinycc::tcc_source
tcc_struct <- Rtinycc::tcc_struct

## -----------------------------------------------------------------------------
ffi <- tcc_ffi() |>
  tcc_source(
    "
    #include <stdlib.h>

    int* dup_array(int* x, int n) {
      if (n <= 0) return NULL;
      int* out = (int*)malloc(sizeof(int) * n);
      for (int i = 0; i < n; ++i) out[i] = x[i] * 2;
      return out;
    }
    "
  ) |>
  tcc_bind(
    dup_array = list(
      args = list("integer_array", "i32"),
      returns = list(type = "integer_array", length_arg = 2, free = TRUE)
    )
  ) |>
  tcc_compile()

ffi$dup_array(as.integer(c(1, 2, 3)), 3L)

## -----------------------------------------------------------------------------
cb <- tcc_callback(function(x) x * 3, "double (*)(double)")
cb_ptr <- tcc_callback_ptr(cb)

ffi_cb <- tcc_ffi() |>
  tcc_source(
    "
    double apply_cb(double (*cb)(void* ctx, double), void* ctx, double x) {
      return cb(ctx, x);
    }
    "
  ) |>
  tcc_bind(
    apply_cb = list(
      args = list("callback:double(double)", "ptr", "f64"),
      returns = "f64"
    )
  ) |>
  tcc_compile()

ffi_cb$apply_cb(cb, cb_ptr, 5)
tcc_callback_close(cb)

## -----------------------------------------------------------------------------
ffi_global <- tcc_ffi() |>
  tcc_source(
    "
    int global_counter = 7;
    "
  ) |>
  tcc_global("global_counter", "i32") |>
  tcc_compile()

ffi_global$global_global_counter_get()
ffi_global$global_global_counter_set(9L)
ffi_global$global_global_counter_get()

## -----------------------------------------------------------------------------
ffi_struct <- tcc_ffi() |>
  tcc_source(
    "
    struct point {
      double x;
      double y;
    };
    "
  ) |>
  tcc_struct("point", accessors = c(x = "f64", y = "f64")) |>
  tcc_compile()

pt <- ffi_struct$struct_point_new()
pt <- ffi_struct$struct_point_set_x(pt, 1.5)
pt <- ffi_struct$struct_point_set_y(pt, 2.5)
ffi_struct$struct_point_get_x(pt)
ffi_struct$struct_point_free(pt)

