## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
knitr::knit_engines$set(rtinycc = Rtinycc:::rtinycc_engine)
tcc_bind <- Rtinycc::tcc_bind
tcc_compile <- Rtinycc::tcc_compile
tcc_ffi <- Rtinycc::tcc_ffi
tcc_source <- Rtinycc::tcc_source
has_callme <- requireNamespace("callme", quietly = TRUE)
has_bench <- requireNamespace("bench", quietly = TRUE)

## -----------------------------------------------------------------------------
build_rtinycc_module <- function() {
  tcc_ffi() |>
    tcc_source(rtinycc_code) |>
    tcc_bind(
      noop = list(args = list(), returns = "void"),
      fill_rand = list(args = list("numeric_array", "i32"), returns = "void"),
      rand_unif = list(
        args = list("i32"),
        returns = list(type = "numeric_array", length_arg = 1, free = TRUE)
      )
    ) |>
    tcc_compile()
}

build_callme_module <- function() {
  before <- names(getLoadedDLLs())
  mod <- callme::compile(callme_code, env = NULL, verbosity = 0)
  dlls <- getLoadedDLLs()
  new_names <- setdiff(names(dlls), before)
  new_names <- new_names[startsWith(new_names, "callme_")]
  attr(mod, "dll_paths") <- unname(vapply(
    dlls[new_names],
    function(x) x[["path"]],
    character(1)
  ))
  mod
}

unload_callme_dlls <- function(dll_paths) {
  dll_paths <- rev(unique(dll_paths))
  if (is.null(dll_paths) || !length(dll_paths)) {
    return(invisible(NULL))
  }
  for (dll_path in dll_paths) {
    if (is.character(dll_path) && nzchar(dll_path) && file.exists(dll_path)) {
      try(dyn.unload(dll_path), silent = TRUE)
    }
  }
  invisible(NULL)
}

build_and_dispose_callme_module <- function() {
  mod <- build_callme_module()
  dll_paths <- attr(mod, "dll_paths", exact = TRUE)
  rm(mod)
  gc()
  unload_callme_dlls(dll_paths)
  invisible(NULL)
}

callme_runtime_reason <- NULL
can_run_callme <- FALSE

if (!has_callme) {
  callme_runtime_reason <- "`callme` is not installed."
} else if (.Platform$OS.type == "windows") {
  callme_runtime_reason <- paste(
    "`callme` comparisons are skipped on Windows during vignette builds",
    "because the helper DLL compilation step is not reliable in CI."
  )
} else {
  callme_probe <- tryCatch(
    {
      build_and_dispose_callme_module()
      NULL
    },
    error = identity
  )

  if (inherits(callme_probe, "error")) {
    callme_runtime_reason <- paste(
      "`callme` comparisons were skipped because runtime compilation failed:",
      conditionMessage(callme_probe)
    )
  } else {
    can_run_callme <- TRUE
  }
}

can_run_benchmarks <- can_run_callme && has_bench

if (is.null(callme_runtime_reason) && !has_bench) {
  callme_runtime_reason <- "`bench` is not installed."
} else if (is.null(callme_runtime_reason)) {
  callme_runtime_reason <- "Executable comparisons are enabled."
}

with_benchmark_modules <- function(fun) {
  rt_mod <- build_rtinycc_module()
  cm_mod <- build_callme_module()
  dll_paths <- attr(cm_mod, "dll_paths", exact = TRUE)

  on.exit({
    rm(rt_mod, cm_mod)
    gc()
    unload_callme_dlls(dll_paths)
  }, add = TRUE)

  fun(rt_mod, cm_mod)
}

median_elapsed <- function(expr, times = 3L) {
  expr <- substitute(expr)
  env <- parent.frame()
  stats::median(replicate(
    times,
    {
      gc()
      t0 <- proc.time()[["elapsed"]]
      eval(expr, envir = env)
      proc.time()[["elapsed"]] - t0
    }
  ))
}

run_noop <- function(fun, n) {
  for (i in seq_len(n)) {
    fun()
  }
  invisible(NULL)
}

run_rand <- function(fun, n, reps) {
  for (i in seq_len(reps)) {
    invisible(fun(n))
  }
  invisible(NULL)
}

run_fill <- function(fun, n, reps) {
  for (i in seq_len(reps)) {
    out <- numeric(n)
    invisible(fun(out, n))
  }
  invisible(NULL)
}

rtinycc_recipe <- tcc_ffi() |>
  tcc_source(rtinycc_code) |>
  tcc_bind(
    noop = list(args = list(), returns = "void"),
    fill_rand = list(args = list("numeric_array", "i32"), returns = "void"),
    rand_unif = list(
      args = list("i32"),
      returns = list(type = "numeric_array", length_arg = 1, free = TRUE)
    )
  )

generated_code <- Rtinycc:::generate_ffi_code(
  symbols = rtinycc_recipe$symbols,
  headers = rtinycc_recipe$headers,
  c_code = rtinycc_recipe$c_code,
  is_external = FALSE,
  structs = rtinycc_recipe$structs,
  unions = rtinycc_recipe$unions,
  enums = rtinycc_recipe$enums,
  globals = rtinycc_recipe$globals,
  container_of = rtinycc_recipe$container_of,
  field_addr = rtinycc_recipe$field_addr,
  struct_raw_access = rtinycc_recipe$struct_raw_access,
  introspect = rtinycc_recipe$introspect
)

## -----------------------------------------------------------------------------
has_callme

## -----------------------------------------------------------------------------
has_bench

## -----------------------------------------------------------------------------
can_run_callme

## -----------------------------------------------------------------------------
can_run_benchmarks

## -----------------------------------------------------------------------------
callme_runtime_reason

## ----eval = can_run_callme----------------------------------------------------
compile_times <- data.frame(
  implementation = c("Rtinycc", "callme"),
  seconds = c(
    median_elapsed(build_rtinycc_module(), times = 3L),
    median_elapsed(build_and_dispose_callme_module(), times = 3L)
  )
)

compile_times$milliseconds <- round(compile_times$seconds * 1000, 1)
compile_times

## ----results='asis'-----------------------------------------------------------
Rtinycc:::rtinycc_c_block(generated_code)

## ----eval = can_run_benchmarks------------------------------------------------
noop_bench <- with_benchmark_modules(function(rt_mod, cm_mod) {
  n_noop <- 1000L

  bench::mark(
    Rtinycc = run_noop(rt_mod$noop, n_noop),
    callme = run_noop(cm_mod$noop, n_noop),
    iterations = 20,
    check = TRUE,
    memory = TRUE,
    filter_gc = FALSE
  )
})

noop_bench

## ----eval = can_run_benchmarks------------------------------------------------
fill_bench_n4096 <- with_benchmark_modules(function(rt_mod, cm_mod) {
  bench::mark(
    Rtinycc = run_fill(rt_mod$fill_rand, 4096L, 100L),
    callme = run_fill(cm_mod$fill_rand, 4096L, 100L),
    iterations = 20,
    check = FALSE,
    memory = TRUE,
    filter_gc = FALSE
  )
})

fill_bench_n4096

## ----eval = can_run_benchmarks------------------------------------------------
rand_results <- with_benchmark_modules(function(rt_mod, cm_mod) {
  rand_bench_n1 <- bench::mark(
    Rtinycc = run_rand(rt_mod$rand_unif, 1L, 1000L),
    callme = run_rand(cm_mod$rand_unif, 1L, 1000L),
    iterations = 20,
    check = FALSE,
    memory = TRUE,
    filter_gc = FALSE
  )

  rand_bench_n4096 <- bench::mark(
    Rtinycc = run_rand(rt_mod$rand_unif, 4096L, 100L),
    callme = run_rand(cm_mod$rand_unif, 4096L, 100L),
    iterations = 20,
    check = FALSE,
    memory = TRUE,
    filter_gc = FALSE
  )

  list(rand_bench_n1 = rand_bench_n1, rand_bench_n4096 = rand_bench_n4096)
})

rand_results$rand_bench_n1
rand_results$rand_bench_n4096

