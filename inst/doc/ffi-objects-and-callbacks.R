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
tcc_source <- Rtinycc::tcc_source
tcc_struct <- Rtinycc::tcc_struct

## -----------------------------------------------------------------------------
ffi_struct <- tcc_ffi() |>
  tcc_source(
    "
    struct point {
      double x;
      double y;
    };

    double point_norm2(struct point* p) {
      return p->x * p->x + p->y * p->y;
    }
    "
  ) |>
  tcc_struct("point", accessors = c(x = "f64", y = "f64")) |>
  tcc_bind(
    point_norm2 = list(args = list("ptr"), returns = "f64")
  ) |>
  tcc_compile()

pt <- ffi_struct$struct_point_new()
pt <- ffi_struct$struct_point_set_x(pt, 3)
pt <- ffi_struct$struct_point_set_y(pt, 4)

ffi_struct$point_norm2(pt)
ffi_struct$struct_point_free(pt)

## -----------------------------------------------------------------------------
cb <- tcc_callback(
  function(x) x * 2,
  signature = "double (*)(double)"
)
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

