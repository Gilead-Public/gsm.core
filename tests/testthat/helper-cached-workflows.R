# Cache management for YAML workflows from gsm.kri and gsm.mapping packages
# This helps avoid circular dependencies by downloading workflow files instead of depending on packages
# Uses tools::R_user_dir("gsm") for persistent cross-session caching

# Load required packages for cache management
suppressPackageStartupMessages({
  if (!requireNamespace("yaml", quietly = TRUE)) {
    warning("yaml package not available - workflow caching will not work")
  }
})

#' Get the cache directory for workflow files
#' @return character path to cache directory
get_workflow_cache_dir <- function() {
  # Try R's standard user cache directory for persistent storage
  tryCatch({
    cache_dir <- file.path(tools::R_user_dir("gsm", "cache"), "workflows")
    if (!dir.exists(cache_dir)) {
      dir.create(cache_dir, recursive = TRUE)
    }
    
    # Test if we can write to this directory
    test_file <- file.path(cache_dir, "test_write.tmp")
    writeLines("test", test_file)
    if (file.exists(test_file)) {
      unlink(test_file)
      return(cache_dir)
    }
  }, error = function(e) {
    warning(sprintf("Failed to use R_user_dir cache directory: %s", e$message))
  })
  
  # Fallback to temp directory if R_user_dir fails
  cache_dir <- file.path(tempdir(), "gsm_workflows_cache")
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
#' @param strPath character path within repo to workflow directory
#' @param force_update logical whether to force update even if files exist
#' @param strNames character vector of regex patterns to match files (e.g., c("^kri000[1-3]", "AE\\.ya?ml$"))
#'   If NULL, downloads all YAML files
#' @return character path to cached workflow directory
download_workflow_files <- function(
  repo,
  branch = "main",
  strPath = "inst/workflow",
  force_update = FALSE,
  strNames = NULL
) {

  cache_dir <- get_workflow_cache_dir()

  # Create simple cache directory name based on repo, branch, and workflow path
  repo_name <- gsub(".*/", "", repo)  # Extract just the repo name
  workflow_name <- gsub(".*/", "", strPath)  # Extract just the workflow subdirectory
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

    }, error = function(e) {
      warning(sprintf("Failed to check for updates from %s: %s. Using existing cache if available.", repo, e$message))
      if (dir.exists(repo_cache_dir) && length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0) {
        return(repo_cache_dir)
      }
      # If no cache exists, try full download once, but if it fails, provide informative error
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
      path = strPath,
      dest_dir = repo_cache_dir,
      strNames = strNames
    )

    # Save metadata about downloaded files
    if (!is.null(remote_metadata)) {
      save_cache_metadata(repo_cache_dir, remote_metadata)
    }

    return(repo_cache_dir)
  }, error = function(e) {
    error_msg <- sprintf("Failed to download workflows from %s to %s: %s", repo, repo_cache_dir, e$message)
    
    # Check if there's any existing cache we can fall back to
    if (dir.exists(repo_cache_dir) && length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0) {
      warning(paste(error_msg, "Using existing cached files."))
      return(repo_cache_dir)
    }
    
    # If no cache exists and download failed, provide helpful error message
    warning(error_msg)
    warning("Consider working offline with local workflow files or check network connectivity.")
    return(NULL)
  })
}

#' Get remote file metadata without downloading files
#' @param repo character repository in format "owner/repo"
#' @param branch character branch name
#' @param path character path within repo
#' @param strNames character vector of regex patterns to filter files (e.g., c("^kri0001", "AE\\.ya?ml$"))
#' @return data.frame with file metadata (name, sha, download_url, etc.)
get_remote_file_metadata <- function(repo, branch, path, strNames = NULL) {

  # GitHub API URL for directory contents
  api_url <- sprintf(
    "https://api.github.com/repos/%s/contents/%s?ref=%s",
    repo, path, branch
  )

  # Get directory listing
  response <- tryCatch({
    # Download JSON response as text and parse with yaml
    json_text <- readLines(api_url, warn = FALSE)
    response_list <- yaml::yaml.load(paste(json_text, collapse = ""))
    # Convert to tibble using tidyr
    if (is.list(response_list) && !is.data.frame(response_list)) {
      response_data <- tibble::enframe(response_list, name = NULL) |> tidyr::unnest_wider(value)
    } else {
      response_data <- response_list
    }
    response_data
  }, error = function(e) {
    stop(sprintf("Failed to access GitHub API for %s: %s", repo, e$message))
  })

  if (!is.data.frame(response)) {
    if (is.list(response)) {
      response <- do.call(rbind.data.frame, response)
    } else {
      stop(sprintf("Unexpected response from GitHub API for %s", repo))
    }
  }

  # Filter for YAML files and apply regex pattern matching
  yaml_files <- response[response$type == "file" & grepl("\\.ya?ml$", response$name), ]

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
#' @param repo character repository in format "owner/repo"
#' @param branch character branch name
#' @param path character path within repo to download
#' @param dest_dir character destination directory
#' @param strNames character vector of regex patterns to match files (e.g., c("^kri000[1-3]", "^AE\\.ya?ml$"))
#'   If NULL, downloads all YAML files
#' @param remote_metadata data.frame with remote file metadata (optional, will fetch if not provided)
#' @param files_to_update logical vector indicating which files to update (optional)
#' @return data.frame with metadata of processed files
download_github_directory <- function(repo, branch, path, dest_dir, strNames = NULL, remote_metadata = NULL, files_to_update = NULL) {

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
#' @param strPackage character package name ("gsm.kri" or "gsm.mapping")
#' @param workflow_subdir character subdirectory within workflow (e.g., "2_metrics", "2_metrics_custom")
#' @param branch character git branch to pull from (default: "main")
#' @param force_update logical whether to force refresh cache
#' @param strNames character vector of specific files to download (e.g., c("kri0001.yaml", "AE.yaml"))
#'   If NULL, downloads all YAML files
#' @param offline logical whether to skip remote download and use only cached files (default: FALSE)
#' @param skip_if_unavailable logical whether to return NULL instead of erroring when workflows unavailable (default: FALSE)
#' @return character path to workflow directory, or NULL if skip_if_unavailable=TRUE and workflows not available
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
    
    if (dir.exists(repo_cache_dir) && length(list.files(repo_cache_dir, pattern = "\\.ya?ml$")) > 0) {
      return(repo_cache_dir)
    } else {
      stop(sprintf("No cached workflows found for %s. Try running without offline=TRUE to download.", strPackage))
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
    
    if (dir.exists(potential_cache_dir) && length(list.files(potential_cache_dir, pattern = "\\.ya?ml$")) > 0) {
      warning(sprintf("Download failed for %s, but found existing cache. Using cached files from %s", strPackage, potential_cache_dir))
      return(potential_cache_dir)
    }
    
    stop(sprintf("Failed to cache workflows for %s. No cache available and download failed. Check network connectivity. You may need to run with internet access to download workflows initially.", strPackage))
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
