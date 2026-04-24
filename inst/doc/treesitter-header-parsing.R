## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
tcc_bind <- Rtinycc::tcc_bind
tcc_compile <- Rtinycc::tcc_compile
tcc_ffi <- Rtinycc::tcc_ffi
tcc_generate_bindings <- Rtinycc::tcc_generate_bindings
tcc_map_c_type_to_ffi <- Rtinycc::tcc_map_c_type_to_ffi
tcc_source <- Rtinycc::tcc_source
tcc_struct <- Rtinycc::tcc_struct
tcc_treesitter_bindings <- Rtinycc::tcc_treesitter_bindings
tcc_treesitter_functions <- Rtinycc::tcc_treesitter_functions
tcc_treesitter_struct_accessors <- Rtinycc::tcc_treesitter_struct_accessors
has_treesitter <- requireNamespace("treesitter.c", quietly = TRUE) &&
  packageVersion("treesitter.c") >= "0.0.4"

## -----------------------------------------------------------------------------
has_treesitter

## -----------------------------------------------------------------------------
header <- paste(
  "double sqrt(double x);",
  "int add(int a, int b);",
  "struct point { double x; double y; };",
  "enum status { OK = 0, ERR = 1 };",
  sep = "\n"
)

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
tcc_treesitter_functions(header)

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
tcc_treesitter_bindings(header)

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
ffi <- tcc_ffi() |>
  tcc_source(
    "
    double sqrt(double x) { return x < 0 ? 0 : x; }
    int add(int a, int b) { return a + b; }
    struct point { double x; double y; };
    enum status { OK = 0, ERR = 1 };
    "
  )

ffi <- tcc_generate_bindings(
  ffi,
  header,
  functions = TRUE,
  structs = TRUE,
  enums = TRUE,
  unions = FALSE,
  globals = FALSE
)

compiled <- tcc_compile(ffi)

compiled$add(2L, 3L)
compiled$enum_status_OK()

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
tcc_treesitter_struct_accessors("struct point { double x; double y; };")

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
tcc_treesitter_struct_accessors(
  "struct flags { unsigned int flag : 1; unsigned int code : 6; };"
)

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
tcc_treesitter_struct_accessors(
  "struct child { int x; }; struct outer { struct child child; int y; };"
)

## -----------------------------------------------------------------------------
tcc_map_c_type_to_ffi("int")
tcc_map_c_type_to_ffi("double")
tcc_map_c_type_to_ffi("const char *")

## ----eval = requireNamespace("treesitter.c", quietly = TRUE) && packageVersion("treesitter.c") >= "0.0.4"----
string_mapper <- function(type) {
  if (trimws(type) == "const char *") {
    return("cstring")
  }
  tcc_map_c_type_to_ffi(type)
}

tcc_treesitter_bindings(
  "int puts(const char *s);",
  mapper = string_mapper
)

