# Cache management for YAML workflows from gsm.kri and gsm.mapping packages
# This helps avoid circular dependencies by downloading workflow files instead of depending on packages

# Load required packages for cache management
suppressPackageStartupMessages({
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    warning("jsonlite package not available - workflow caching will not work")
  }
})

#' Get the cache directory for workflow files
#' @return character path to cache directory
get_workflow_cache_dir <- function() {
  cache_dir <- file.path(testthat::test_path(), "workflow_cache")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  return(cache_dir)
}

#' Get metadata file path for a cache directory
#' @param cache_path character path to cache directory
#' @return character path to metadata file
get_cache_metadata_file <- function(cache_path) {
  file.path(cache_path, ".cache_metadata.rds")
}

#' Save metadata about cached files
#' @param cache_path character path to cache directory
#' @param file_metadata data.frame with file information from GitHub API
save_cache_metadata <- function(cache_path, file_metadata) {
  metadata_file <- get_cache_metadata_file(cache_path)
  saveRDS(file_metadata, metadata_file)
}

#' Load metadata about cached files
#' @param cache_path character path to cache directory
#' @return data.frame with cached file metadata or NULL if no metadata exists
load_cache_metadata <- function(cache_path) {
  metadata_file <- get_cache_metadata_file(cache_path)
  if (file.exists(metadata_file)) {
    readRDS(metadata_file)
  } else {
    NULL
  }
}

#' Check if files need updating by comparing SHAs
#' @param cache_path character path to cache directory
#' @param remote_metadata data.frame with remote file information
#' @return logical vector indicating which files need updating
files_need_update <- function(cache_path, remote_metadata) {
  cached_metadata <- load_cache_metadata(cache_path)

  if (is.null(cached_metadata)) {
    # No cache metadata, need to download all files
    return(rep(TRUE, nrow(remote_metadata)))
  }

  # Compare SHAs to detect changes
  needs_update <- logical(nrow(remote_metadata))
  for (i in seq_len(nrow(remote_metadata))) {
    file_name <- remote_metadata$name[i]
    remote_sha <- remote_metadata$sha[i]

    # Find matching cached file
    cached_file <- cached_metadata[cached_metadata$name == file_name, ]

    if (nrow(cached_file) == 0) {
      # File doesn't exist in cache
      needs_update[i] <- TRUE
    } else {
      # Compare SHAs
      needs_update[i] <- cached_file$sha[1] != remote_sha
    }
  }

  return(needs_update)
}

#' Download workflow files from a GitHub repository
#' @param repo character repository in format "owner/repo"
#' @param branch character branch name (default: "main")
#' @param workflow_path character path within repo to workflow directory
#' @param force_update logical whether to force update even if files exist
#' @param file_patterns character vector of regex patterns to match files (e.g., c("^kri000[1-3]", "AE\\.ya?ml$"))
#'   If NULL, downloads all YAML files
#' @return character path to cached workflow directory
download_workflow_files <- function(
  repo,
  branch = "main",
  workflow_path = "inst/workflow",
  force_update = FALSE,
  file_patterns = NULL
) {

  cache_dir <- get_workflow_cache_dir()

  # Create simple cache directory name based on repo, branch, and workflow path
  repo_name <- gsub(".*/", "", repo)  # Extract just the repo name
  workflow_name <- gsub(".*/", "", workflow_path)  # Extract just the workflow subdirectory
  repo_cache_dir <- file.path(cache_dir, workflow_name)

  # Create cache directory if it doesn't exist
  if (!dir.exists(repo_cache_dir)) {
    dir.create(repo_cache_dir, recursive = TRUE)
  }

  # Check if we need to update files (unless force_update)
  if (!force_update) {
    tryCatch({
      # Get remote file metadata
      remote_metadata <- get_remote_file_metadata(
        repo = repo,
        branch = branch,
        path = workflow_path,
        file_patterns = file_patterns
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
        path = workflow_path,
        dest_dir = repo_cache_dir,
        file_patterns = file_patterns,
        remote_metadata = remote_metadata,
        files_to_update = files_to_update
      )

      # Save updated metadata
      save_cache_metadata(repo_cache_dir, remote_metadata)

      return(repo_cache_dir)

    }, error = function(e) {
      warning(sprintf("Failed to check for updates from %s: %s. Using existing cache.", repo, e$message))
      if (dir.exists(repo_cache_dir) && length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0) {
        return(repo_cache_dir)
      }
      # If no cache exists, fall through to full download
    })
  }

  # Force update or no existing cache - download all files
  if (force_update && dir.exists(repo_cache_dir)) {
    unlink(repo_cache_dir, recursive = TRUE)
    dir.create(repo_cache_dir, recursive = TRUE)
  }

  # Download workflow files using GitHub API
  tryCatch({
    remote_metadata <- download_github_directory(
      repo = repo,
      branch = branch,
      path = workflow_path,
      dest_dir = repo_cache_dir,
      file_patterns = file_patterns
    )

    # Save metadata about downloaded files
    if (!is.null(remote_metadata)) {
      save_cache_metadata(repo_cache_dir, remote_metadata)
    }

    return(repo_cache_dir)
  }, error = function(e) {
    warning(sprintf("Failed to download workflows from %s: %s", repo, e$message))
    return(NULL)
  })
}

#' Get remote file metadata without downloading files
#' @param repo character repository in format "owner/repo"
#' @param branch character branch name
#' @param path character path within repo
#' @param file_patterns character vector of regex patterns to filter files (e.g., c("^kri0001", "AE\\.ya?ml$"))
#' @return data.frame with file metadata (name, sha, download_url, etc.)
get_remote_file_metadata <- function(repo, branch, path, file_patterns = NULL) {

  # GitHub API URL for directory contents
  api_url <- sprintf(
    "https://api.github.com/repos/%s/contents/%s?ref=%s",
    repo, path, branch
  )

  # Get directory listing
  response <- tryCatch({
    jsonlite::fromJSON(api_url)
  }, error = function(e) {
    stop(sprintf("Failed to access GitHub API for %s: %s", repo, e$message))
  })

  if (!is.data.frame(response)) {
    stop(sprintf("Unexpected response from GitHub API for %s", repo))
  }

  # Filter for YAML files and apply regex pattern matching
  yaml_files <- response[response$type == "file" & grepl("\\.ya?ml$", response$name), ]

  if (!is.null(file_patterns) && nrow(yaml_files) > 0) {
    # Filter files based on regex patterns
    matches <- rep(FALSE, nrow(yaml_files))
    for (pattern in file_patterns) {
      pattern_matches <- grepl(pattern, yaml_files$name, ignore.case = TRUE)
      matches <- matches | pattern_matches
    }
    yaml_files <- yaml_files[matches, ]
  }

  return(yaml_files)
}

#' Download directory from GitHub repository
#' @param repo character repository in format "owner/repo"
#' @param branch character branch name
#' @param path character path within repo to download
#' @param dest_dir character destination directory
#' @param file_patterns character vector of regex patterns to match files (e.g., c("^kri000[1-3]", "^AE\\.ya?ml$"))
#'   If NULL, downloads all YAML files
#' @param remote_metadata data.frame with remote file metadata (optional, will fetch if not provided)
#' @param files_to_update logical vector indicating which files to update (optional)
#' @return data.frame with metadata of processed files
download_github_directory <- function(repo, branch, path, dest_dir, file_patterns = NULL, remote_metadata = NULL, files_to_update = NULL) {

  # Get remote metadata if not provided
  if (is.null(remote_metadata)) {
    remote_metadata <- get_remote_file_metadata(repo, branch, path, file_patterns)
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

  # Process subdirectories recursively if needed
  # Get full directory listing for subdirectories
  api_url <- sprintf(
    "https://api.github.com/repos/%s/contents/%s?ref=%s",
    repo, path, branch
  )

  full_response <- tryCatch({
    jsonlite::fromJSON(api_url)
  }, error = function(e) {
    return(data.frame())  # Return empty df on error
  })

  if (is.data.frame(full_response)) {
    subdirs <- full_response[full_response$type == "dir", ]

    if (nrow(subdirs) > 0) {
      for (i in seq_len(nrow(subdirs))) {
        subdir <- subdirs[i, ]
        subdir_path <- file.path(dest_dir, subdir$name)
        dir.create(subdir_path, recursive = TRUE, showWarnings = FALSE)

        # Recursively process subdirectories
        subdir_metadata <- download_github_directory(
          repo = repo,
          branch = branch,
          path = subdir$path,
          dest_dir = subdir_path,
          file_patterns = file_patterns
        )

        # Combine metadata
        if (is.data.frame(subdir_metadata) && nrow(subdir_metadata) > 0) {
          remote_metadata <- rbind(remote_metadata, subdir_metadata)
        }
      }
    }
  }

  return(remote_metadata)
}

#' Download a single file from GitHub
#' @param download_url character direct download URL
#' @param dest_file character destination file path
download_file_from_github <- function(download_url, dest_file) {
  tryCatch({
    utils::download.file(
      download_url,
      dest_file,
      mode = "wb",
      quiet = TRUE
    )
  }, error = function(e) {
    warning(sprintf("Failed to download %s: %s", download_url, e$message))
  })
}

#' Get cached workflow path, downloading if necessary
#' @param package character package name ("gsm.kri" or "gsm.mapping")
#' @param workflow_subdir character subdirectory within workflow (e.g., "2_metrics", "2_metrics_custom")
#' @param branch character git branch to pull from (default: "main")
#' @param force_update logical whether to force refresh cache
#' @param file_patterns character vector of specific files to download (e.g., c("kri0001.yaml", "AE.yaml"))
#'   If NULL, downloads all YAML files
#' @return character path to workflow directory
get_cached_workflow_path <- function(
  package = c("gsm.kri", "gsm.mapping"),
  workflow_subdir = NULL,
  branch = "main",
  force_update = FALSE,
  file_patterns = NULL
) {

  package <- match.arg(package)

  # Repository mapping
  repo_map <- list(
    "gsm.kri" = "Gilead-BioStats/gsm.kri",
    "gsm.mapping" = "Gilead-BioStats/gsm.mapping"
  )

  repo <- repo_map[[package]]
  if (is.null(repo)) {
    stop(sprintf("Unknown package: %s", package))
  }

  # Determine the workflow path within the repo
  workflow_path <- "inst/workflow"
  if (!is.null(workflow_subdir)) {
    workflow_path <- file.path(workflow_path, workflow_subdir)
  }

  # Download workflow files
  cache_dir <- download_workflow_files(
    repo = repo,
    branch = branch,
    workflow_path = workflow_path,
    force_update = force_update,
    file_patterns = file_patterns
  )

  if (is.null(cache_dir)) {
    stop(sprintf("Failed to cache workflows for %s", package))
  }

  return(cache_dir)
}

#' Get path to local custom metrics workflows
#' Custom metrics are generated in this repo and should not be pulled from remote
#' @return character path to local custom metrics workflows
GetYamlPathCustomMetrics <- function() {
  # Custom metrics are local to this repository
  test_path("qual_workflows/2_metrics_custom")
}

#' Get cached mapping workflows from gsm.mapping
#' @param force_update logical whether to force refresh cache
#' @param branch character git branch to pull from (default: "main")
#' @param file_patterns character vector of regex patterns to match files (e.g., c("^AE\\.ya?ml$", "^SUBJ\\.ya?ml$"))
#' @return character path to mapping workflows
GetYamlPathMappings <- function(force_update = FALSE, branch = "main", file_patterns = NULL) {
  tryCatch({
    get_cached_workflow_path(
      package = "gsm.mapping",
      workflow_subdir = "1_mappings",
      branch = branch,
      force_update = force_update,
      file_patterns = file_patterns
    )
  }, error = function(e) {
    warning("Using local workflow files: ", e$message)
    test_path("qual_workflows/1_mappings")
  })
}

#' Get standard KRI metrics from gsm.kri
#' @param force_update logical whether to force refresh cache
#' @param branch character git branch to pull from (default: "main")
#' @param file_patterns character vector of regex patterns to match files (e.g., c("^kri000[1-3]\\.ya?ml$", "^kri0001b\\.ya?ml$"))
#' @return character path to standard metrics workflows
GetYamlPathStandardMetrics <- function(force_update = FALSE, branch = "main", file_patterns = NULL) {
  tryCatch({
    get_cached_workflow_path(
      package = "gsm.kri",
      workflow_subdir = "2_metrics",
      branch = branch,
      force_update = force_update,
      file_patterns = file_patterns
    )
  }, error = function(e) {
    warning("Using local workflow files: ", e$message)
    test_path("qual_workflows/2_metrics")
  })
}

#' Configure standard metrics source (not custom metrics)
#' Custom metrics are always local. This configures where standard metrics come from.
#' @param source character where to get standard metrics from:
#'   - "dev_branch": pull from dev branch of gsm.kri/2_metrics
#'   - "standard": pull from main branch of gsm.kri/2_metrics
#'   - "local": use local qual_workflows/2_metrics
#' @param force_update logical whether to force refresh cache
#' @param file_patterns character vector of specific files to download
#' @return character path to standard metrics workflows
configure_standard_metrics_source <- function(source = c("standard", "dev_branch", "local"), force_update = FALSE, file_patterns = NULL) {
  source <- match.arg(source)

  switch(source,
    "dev_branch" = {
      GetYamlPathStandardMetrics(
        force_update = force_update,
        branch = "dev",
        file_patterns = file_patterns
      )
    },
    "standard" = {
      GetYamlPathStandardMetrics(
        force_update = force_update,
        branch = "main",
        file_patterns = file_patterns
      )
    },
    "local" = {
      test_path("qual_workflows/2_metrics")
    }
  )
}

#' Check if workflow cache needs updating
#' @param max_age_hours numeric maximum age of cache in hours (default: 24)
#' @return logical whether cache should be updated
workflow_cache_needs_update <- function(max_age_hours = 24) {
  cache_dir <- get_workflow_cache_dir()
  if (!dir.exists(cache_dir)) {
    return(TRUE)
  }

  cache_info <- file.info(cache_dir)
  age_hours <- as.numeric(Sys.time() - cache_info$mtime, units = "hours")
  return(age_hours > max_age_hours)
}

#' Refresh workflow cache for all packages
#' @param packages character vector of packages to refresh (default: both gsm packages)  
#' @param force_update logical whether to force update regardless of changes (default: FALSE)
#' @return logical indicating success
refresh_workflow_cache <- function(packages = c("gsm.kri", "gsm.mapping"), force_update = FALSE) {
  success <- TRUE

  # Define standard subdirectories to check for each package
  package_subdirs <- list(
    "gsm.kri" = c("2_metrics"),
    "gsm.mapping" = c("1_mappings")
  )

  for (pkg in packages) {
    message(sprintf("Checking for updates to %s workflows...", pkg))
    
    subdirs <- package_subdirs[[pkg]]
    if (is.null(subdirs)) {
      warning(sprintf("Unknown package: %s", pkg))
      success <- FALSE
      next
    }
    
    for (subdir in subdirs) {
      tryCatch({
        message(sprintf("  Checking %s/%s...", pkg, subdir))
        
        # Check if cache directory exists first
        repo_map <- list("gsm.kri" = "Gilead-BioStats/gsm.kri", "gsm.mapping" = "Gilead-BioStats/gsm.mapping")
        repo <- repo_map[[pkg]]
        repo_name <- gsub(".*/", "", repo)
        cache_dir_name <- sprintf("%s_main_%s", repo_name, subdir)
        cache_path <- file.path(get_workflow_cache_dir(), cache_dir_name)
        
        if (!dir.exists(cache_path)) {
          message(sprintf("    No existing cache found for %s/%s - skipping", pkg, subdir))
          next
        }
        
        # Get list of currently cached files
        cached_files <- list.files(cache_path, pattern = "\\.ya?ml$", full.names = FALSE)
        if (length(cached_files) == 0) {
          message(sprintf("    No YAML files in cache for %s/%s - skipping", pkg, subdir))
          next
        }
        
        message(sprintf("    Found %d cached files to check", length(cached_files)))
        
        # Create regex patterns that match only the existing cached files
        existing_file_patterns <- paste0("^", gsub("\\.", "\\\\.", cached_files), "$")
        
        # Check cache against remote API for existing files only
        updated_cache_path <- get_cached_workflow_path(
          package = pkg, 
          workflow_subdir = subdir,
          force_update = force_update,
          file_patterns = existing_file_patterns  # Only check existing files
        )
        
        # Report results
        metadata_file <- get_cache_metadata_file(updated_cache_path)
        if (file.exists(metadata_file)) {
          metadata <- readRDS(metadata_file)
          file_count <- nrow(metadata)
          message(sprintf("    %d files checked/updated for %s/%s", file_count, pkg, subdir))
        } else {
          message(sprintf("    Cache updated for %s/%s", pkg, subdir))
        }
        
      }, error = function(e) {
        warning(sprintf("Failed to update workflow cache for %s/%s: %s", pkg, subdir, e$message))
        success <- FALSE
      })
    }
  }

  return(success)
}

#' Get specific workflow files using predefined patterns
#' @param workflow_type character type of workflow ("metrics" or "mappings")
#' @param pattern_name character name of predefined pattern or custom vector
#' @param force_update logical whether to force refresh cache
#' @param branch character git branch to pull from
#' @return character path to cached workflows
get_specific_workflows <- function(
  workflow_type = c("metrics", "mappings"),
  file_patterns = NULL,
  force_update = FALSE,
  branch = "main"
) {

  workflow_type <- match.arg(workflow_type)


  # Get the appropriate workflows
  if (workflow_type == "metrics") {
    GetYamlPathStandardMetrics(
      force_update = force_update,
      branch = branch,
      file_patterns = file_patterns
    )
  } else {
    GetYamlPathMappings(
      force_update = force_update,
      branch = branch,
      file_patterns = file_patterns
    )
  }
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
