# Find a local test data build whose inputs match the installed packages.
#
# Local builds live in `<.testdata_dir()>/local/<inputs_hash>/`, where
# `inputs_hash` is `fresh_inputs_hash()` of the packages at build time.
# Returns the folder, or `NULL` if none match.
.find_local_testdata_build <- function(root = .testdata_local_root()) {
  dirs <- list.dirs(root, recursive = FALSE)
  for (dir in dirs[.testdata_local_has_snapshot(dirs)]) {
    snapshot <- tryCatch(read_snapshot(dir), error = function(e) NULL)
    packages <- names(snapshot$packages)
    if (!length(packages)) {
      next
    }
    installed <- .testdata_installed(packages)
    if (identical(fresh_inputs_hash(installed), basename(dir))) {
      return(dir)
    }
  }
  NULL
}

.testdata_local_has_snapshot <- function(dirs) {
  vapply(dirs, .testdata_local_exists, logical(1), USE.NAMES = FALSE)
}
