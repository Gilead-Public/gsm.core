source_dir <- "inst/slides"
dest_dir <- "pkgdown/extra/slides"

dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

files_to_copy <- unlist(lapply(
  c("*.qmd", "*.css", "*.png"),
  function(pattern) {
    list.files(source_dir, pattern = glob2rx(pattern), full.names = TRUE)
  }
), use.names = FALSE)

theme_picker <- file.path(source_dir, "theme-picker.html")
if (file.exists(theme_picker)) {
  files_to_copy <- c(files_to_copy, theme_picker)
}

if (length(files_to_copy)) {
  file.copy(files_to_copy, dest_dir, overwrite = TRUE)
}

slide_qmds <- list.files(dest_dir, pattern = "\\.qmd$", full.names = TRUE)
for (qmd_file in slide_qmds) {
  quarto::quarto_render(qmd_file)
}

if (length(slide_qmds)) {
  file.remove(slide_qmds)
}