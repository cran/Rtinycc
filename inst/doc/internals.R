## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
tcc_bind <- Rtinycc::tcc_bind
tcc_callback_close <- Rtinycc::tcc_callback_close
tcc_compile <- Rtinycc::tcc_compile
tcc_cstring <- Rtinycc::tcc_cstring
tcc_data_ptr <- Rtinycc::tcc_data_ptr
tcc_ffi <- Rtinycc::tcc_ffi
tcc_get_symbol <- Rtinycc::tcc_get_symbol
tcc_link <- Rtinycc::tcc_link
tcc_malloc <- Rtinycc::tcc_malloc
tcc_relocate <- Rtinycc::tcc_relocate
tcc_set_options <- Rtinycc::tcc_set_options
tcc_source <- Rtinycc::tcc_source

## -----------------------------------------------------------------------------
ffi <- tcc_ffi() |>
  tcc_source("int add(int a, int b) { return a + b; }") |>
  tcc_bind(add = list(args = list("i32", "i32"), returns = "i32"))

names(ffi)

## -----------------------------------------------------------------------------
code <- Rtinycc:::generate_ffi_code(
  symbols = ffi$symbols,
  headers = ffi$headers,
  c_code = ffi$c_code,
  is_external = FALSE,
  structs = ffi$structs,
  unions = ffi$unions,
  enums = ffi$enums,
  globals = ffi$globals,
  container_of = ffi$container_of,
  field_addr = ffi$field_addr,
  struct_raw_access = ffi$struct_raw_access,
  introspect = ffi$introspect
)

grepl("SEXP R_wrap_add", code, fixed = TRUE)

## -----------------------------------------------------------------------------
Rtinycc:::generate_c_input("x", "arg1_", "i32")
Rtinycc:::generate_c_return("res", "f64")

