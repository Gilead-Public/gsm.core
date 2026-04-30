# Workflow caching system for gsm.kri and gsm.mapping
# Uses persistent cache to avoid circular dependencies

suppressPackageStartupMessages({
  if (!requireNamespace("yaml", quietly = TRUE)) {
    warning("yaml package not available - workflow caching will not work")
  }
})

#' Get workflow cache directory
get_workflow_cache_dir <- function() {
  tryCatch(
    {
      cache_dir <- file.path(tools::R_user_dir("gsm", "cache"), "workflows")
      if (!dir.exists(cache_dir)) {
        dir.create(cache_dir, recursive = TRUE)
      }

      # Test write permissions
      test_file <- file.path(cache_dir, "test_write.tmp")
      writeLines("test", test_file)
      if (file.exists(test_file)) {
        unlink(test_file)
        return(cache_dir)
      }
    },
    error = function(e) {
      warning(sprintf(
        "Failed to use R_user_dir cache directory: %s",
        e$message
      ))
    }
  )

  # Fallback to temp directory
  cache_dir <- file.path(tempdir(), "gsm_workflows_cache")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  return(cache_dir)
}

#' Cache metadata operations
get_cache_metadata_file <- function(cache_path) {
  file.path(cache_path, ".cache_metadata.rds")
}

save_cache_metadata <- function(cache_path, file_metadata) {
  saveRDS(file_metadata, get_cache_metadata_file(cache_path))
}

load_cache_metadata <- function(cache_path) {
  metadata_file <- get_cache_metadata_file(cache_path)
  if (file.exists(metadata_file)) readRDS(metadata_file) else NULL
}

#' Check if cached files need updating
files_need_update <- function(cache_path, remote_metadata) {
  local_metadata <- load_cache_metadata(cache_path)
  if (is.null(local_metadata)) {
    return(rep(TRUE, nrow(remote_metadata)))
  }

  # Compare SHAs to determine which files need updating
  matches <- match(remote_metadata$name, local_metadata$name)
  local_shas <- local_metadata$sha[matches]
  remote_metadata$sha != local_shas | is.na(local_shas)
}

#' Download workflow files from GitHub repository
download_workflow_files <- function(
  repo,
  branch = "main",
  strPath = "inst/workflow",
  force_update = FALSE,
  strNames = NULL
) {
  cache_dir <- get_workflow_cache_dir()

  # Create simple cache directory name based on repo, branch, and workflow path
  repo_name <- gsub(".*/", "", repo) # Extract just the repo name
  workflow_name <- gsub(".*/", "", strPath) # Extract just the workflow subdirectory
  repo_cache_dir <- file.path(cache_dir, workflow_name)

  # Create cache directory if it doesn't exist
  if (!dir.exists(repo_cache_dir)) {
    dir.create(repo_cache_dir, recursive = TRUE)
  }

  # Check if we need to update files (unless force_update)
  if (!force_update) {
    tryCatch(
      {
        # Get remote file metadata
        remote_metadata <- get_remote_file_metadata(
          repo = repo,
          branch = branch,
          path = strPath,
          strNames = strNames
        )

        # Check which files need updating
        files_to_update <- files_need_update(repo_cache_dir, remote_metadata)

        if (!any(files_to_update)) {
          # No files need updating
          return(repo_cache_dir)
        }

        # Only download files that need updating
        download_github_directory(
          repo = repo,
          branch = branch,
          path = strPath,
          dest_dir = repo_cache_dir,
          strNames = strNames,
          remote_metadata = remote_metadata,
          files_to_update = files_to_update
        )

        # Save updated metadata
        save_cache_metadata(repo_cache_dir, remote_metadata)

        return(repo_cache_dir)
      },
      error = function(e) {
        warning(sprintf(
          "Failed to check for updates from %s: %s. Using existing cache if available.",
          repo,
          e$message
        ))
        if (
          dir.exists(repo_cache_dir) &&
            length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0
        ) {
          return(repo_cache_dir)
        }
        # If no cache exists, try full download once, but if it fails, provide informative error
      }
    )
  }

  # Force update or no existing cache - download all files
  if (force_update && dir.exists(repo_cache_dir)) {
    unlink(repo_cache_dir, recursive = TRUE)
    dir.create(repo_cache_dir, recursive = TRUE)
  }

  # Download workflow files using GitHub API
  tryCatch(
    {
      remote_metadata <- download_github_directory(
        repo = repo,
        branch = branch,
        path = strPath,
        dest_dir = repo_cache_dir,
        strNames = strNames
      )

      # Save metadata about downloaded files
      if (!is.null(remote_metadata)) {
        save_cache_metadata(repo_cache_dir, remote_metadata)
      }

      return(repo_cache_dir)
    },
    error = function(e) {
      error_msg <- sprintf(
        "Failed to download workflows from %s to %s: %s",
        repo,
        repo_cache_dir,
        e$message
      )

      # Check if there's any existing cache we can fall back to
      if (
        dir.exists(repo_cache_dir) &&
          length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0
      ) {
        warning(paste(error_msg, "Using existing cached files."))
        return(repo_cache_dir)
      }

      # If no cache exists and download failed, provide helpful error message
      warning(error_msg)
      warning(
        "Consider working offline with local workflow files or check network connectivity."
      )
      return(NULL)
    }
  )
}

#' Get remote file metadata without downloading files
get_remote_file_metadata <- function(repo, branch, path, strNames = NULL) {
  # GitHub API URL for directory contents
  api_url <- sprintf(
    "https://api.github.com/repos/%s/contents/%s?ref=%s",
    repo,
    path,
    branch
  )

  # Get directory listing
  response <- tryCatch(
    {
      # Download JSON response as text and parse with yaml
      json_text <- readLines(api_url, warn = FALSE)
      response_list <- yaml::yaml.load(paste(json_text, collapse = ""))
      # Convert to tibble using tidyr
      if (is.list(response_list) && !is.data.frame(response_list)) {
        response_data <- tibble::enframe(response_list, name = NULL) |>
          tidyr::unnest_wider(value)
      } else {
        response_data <- response_list
      }
      response_data
    },
    error = function(e) {
      stop(sprintf("Failed to access GitHub API for %s: %s", repo, e$message))
    }
  )

  if (!is.data.frame(response)) {
    if (is.list(response)) {
      response <- do.call(rbind.data.frame, response)
    } else {
      stop(sprintf("Unexpected response from GitHub API for %s", repo))
    }
  }

  # Filter for YAML files and apply regex pattern matching
  yaml_files <- response[
    response$type == "file" & grepl("\\.ya?ml$", response$name),
  ]

  if (!is.null(strNames) && nrow(yaml_files) > 0) {
    # Filter files based on regex patterns
    matches <- rep(FALSE, nrow(yaml_files))
    for (pattern in strNames) {
      pattern_matches <- grepl(pattern, yaml_files$name, ignore.case = TRUE)
      matches <- matches | pattern_matches
    }
    yaml_files <- yaml_files[matches, ]
  }

  return(yaml_files)
}

#' Download directory from GitHub repository
download_github_directory <- function(
  repo,
  branch,
  path,
  dest_dir,
  strNames = NULL,
  remote_metadata = NULL,
  files_to_update = NULL
) {
  # Get remote metadata if not provided
  if (is.null(remote_metadata)) {
    remote_metadata <- get_remote_file_metadata(repo, branch, path, strNames)
  }

  if (nrow(remote_metadata) == 0) {
    warning("No files found in remote metadata")
    return(data.frame())
  }

  # If files_to_update not specified, update all files
  if (is.null(files_to_update)) {
    files_to_update <- rep(TRUE, nrow(remote_metadata))
  }

  # Download only files that need updating
  for (i in seq_len(nrow(remote_metadata))) {
    if (files_to_update[i]) {
      file_info <- remote_metadata[i, ]

      download_file_from_github(
        file_info$download_url,
        file.path(dest_dir, file_info$name)
      )
    }
  }

  # Skip subdirectory processing for workflow directories since we want specific files only

  return(remote_metadata)
}

#' Download a single file from GitHub
download_file_from_github <- function(download_url, dest_file) {
  tryCatch(
    {
      utils::download.file(download_url, dest_file, mode = "wb", quiet = TRUE)
    },
    error = function(e) {
      warning(sprintf("Failed to download %s: %s", download_url, e$message))
    }
  )
}

#' Get cached workflows, downloading if necessary
get_cached_workflows <- function(
  strPackage = c("gsm.kri", "gsm.mapping"),
  workflow_subdir = NULL,
  branch = "main",
  force_update = FALSE,
  strNames = NULL,
  offline = FALSE,
  skip_if_unavailable = FALSE
) {
  strPackage <- match.arg(strPackage)

  # Repository mapping
  repo_map <- list(
    "gsm.kri" = "Gilead-BioStats/gsm.kri",
    "gsm.mapping" = "Gilead-BioStats/gsm.mapping"
  )

  repo <- repo_map[[strPackage]]
  if (is.null(repo)) {
    stop(sprintf("Unknown package: %s", strPackage))
  }

  # Determine the workflow path within the repo
  strPath <- "inst/workflow"
  if (!is.null(workflow_subdir)) {
    strPath <- file.path(strPath, workflow_subdir)
  }

  # If offline mode, skip download and check cache only
  if (offline) {
    cache_dir <- get_workflow_cache_dir()
    repo_name <- gsub(".*/", "", repo)
    workflow_name <- gsub(".*/", "", strPath)
    repo_cache_dir <- file.path(cache_dir, workflow_name)

    if (
      dir.exists(repo_cache_dir) &&
        length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0
    ) {
      return(repo_cache_dir)
    } else {
      stop(sprintf(
        "No cached workflows found for %s. Try running without offline=TRUE to download.",
        strPackage
      ))
    }
  }

  # Download workflow files
  cache_dir <- download_workflow_files(
    repo = repo,
    branch = branch,
    strPath = strPath,
    force_update = force_update,
    strNames = strNames
  )

  if (is.null(cache_dir)) {
    # Check if there's any existing cache we can fall back to even if it's stale
    cache_base_dir <- get_workflow_cache_dir()
    repo_name <- gsub(".*/", "", repo)
    workflow_name <- gsub(".*/", "", strPath)
    potential_cache_dir <- file.path(cache_base_dir, workflow_name)

    if (
      dir.exists(potential_cache_dir) &&
        length(list.files(potential_cache_dir, pattern = "\\.ya?ml$")) > 0
    ) {
      warning(sprintf(
        "Download failed for %s, but found existing cache. Using cached files from %s",
        strPackage,
        potential_cache_dir
      ))
      return(potential_cache_dir)
    }

    stop(sprintf(
      "Failed to cache workflows for %s. No cache available and download failed. Check network connectivity. You may need to run with internet access to download workflows initially.",
      strPackage
    ))
  }

  return(cache_dir)
}

#' Get path to mapping workflows
#' @return character path to mapping workflows
GetYamlPathMappings <- function() {
  file.path(get_workflow_cache_dir(), "1_mappings")
}

#' Get path to standard KRI metrics
#' @return character path to standard metrics workflows
GetYamlPathMetrics <- function() {
  file.path(get_workflow_cache_dir(), "2_metrics")
}


#' Clear workflow cache
#' @return logical indicating success
clear_workflow_cache <- function() {
  cache_dir <- get_workflow_cache_dir()

  if (dir.exists(cache_dir)) {
    unlink(cache_dir, recursive = TRUE)
    message("Workflow cache cleared")
    return(TRUE)
  } else {
    message("No workflow cache to clear")
    return(TRUE)
  }
}
