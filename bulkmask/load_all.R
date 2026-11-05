# Convenience loader for interactive / scripted use without devtools.
#   source("bulkmask/load_all.R")        # from the repository root
# then call bulkmask functions directly. For a formal install use
#   R CMD INSTALL bulkmask   (or devtools::install("bulkmask")).
local({
  cand <- c("bulkmask/R", "R", file.path(getwd(), "bulkmask", "R"))
  rdir <- cand[dir.exists(cand)][1]
  if (is.na(rdir)) stop("bulkmask: cannot locate the R/ source directory")
  for (f in sort(list.files(rdir, pattern = "[.][Rr]$", full.names = TRUE)))
    sys.source(f, envir = globalenv())
  message("bulkmask loaded from ", rdir)
})
