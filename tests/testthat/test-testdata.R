test_that(".testdata_inputs_hash() matches gsm.datasim's definition (#206)", {
  # From data-index builds/71ba4400...json (gsm.datasim#153).
  pkgs <- pkg_state(
    workr = c("1.1.1", "f8346be02ed3e10971d96441ac82e13a49c0cd4f"),
    gsm.core = c("1.3.2.9000", "78cc77564ac39cc6a3ed159f25ca2d31f2126c10"),
    gsm.datasim = c("2.1.0.9000", "4b32049afd901365ea4521d5d8cbb844158f4c50"),
    gsm.kri = c("1.8.0.9000", "89e27713c3224bc92190a50d9dce76150f03a965"),
    gsm.mapping = c("1.2.0.9000", "f0d698561d44c4c80bd4b786add145358478e2b8"),
    gsm.qtl = c("1.4.0", "7417fc43d7b706fc875306e81990c235dd47b1d0"),
    gsm.reporting = c("1.1.8.9000", "c33bceb984f986879b2715833254e138e4f858a0")
  )
  expect_equal(
    .testdata_inputs_hash(pkgs),
    "71ba44000382e6e98b60e2a0ebd495927cbe26f83a75f6d741f91c164f79dc4b"
  )
})

test_that(".testdata_select() prefers an exact inputs_hash match (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  index <- fake_index(
    fake_build(
      fp_a,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1")),
      "2026-01-02T00:00:00Z"
    ),
    fake_build(
      fp_b,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k2")),
      "2026-01-03T00:00:00Z"
    )
  )
  pick <- .testdata_select(
    index,
    pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1"))
  )
  expect_equal(pick$match, "exact")
  expect_equal(pick$build$fingerprint, fp_a)
})

test_that(".testdata_select() filters by RemoteSha when it was built (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  index <- fake_index(
    fake_build(
      fp_a,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1")),
      "2026-01-02T00:00:00Z"
    ),
    fake_build(
      fp_b,
      pkg_state(gsm.core = c("1.0.0", "s2"), gsm.kri = c("1.0.0", "k1")),
      "2026-01-03T00:00:00Z"
    )
  )
  # gsm.kri isn't installed, so only gsm.core's SHA filters.
  pick <- .testdata_select(index, pkg_state(gsm.core = c("1.0.0", "s1")))
  expect_equal(pick$match, "filtered")
  expect_equal(pick$build$fingerprint, fp_a)
})

test_that("packages that aren't installed don't filter (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  index <- fake_index(
    fake_build(
      fp_a,
      pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0"),
      "2026-01-02T00:00:00Z"
    ),
    fake_build(
      fp_b,
      pkg_state(gsm.core = "1.0.0", gsm.kri = "2.0.0"),
      "2026-01-03T00:00:00Z"
    )
  )
  expect_equal(selected_fp(index, pkg_state(gsm.core = "1.0.0")), fp_b)
  expect_equal(
    selected_fp(index, pkg_state(gsm.core = "1.0.0", gsm.kri = NA_character_)),
    fp_b
  )
})

test_that("no or unknown RemoteSha falls back to the same version (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  index <- fake_index(
    fake_build(
      fp_a,
      pkg_state(gsm.core = c("1.0.0", "s1")),
      "2026-01-02T00:00:00Z"
    ),
    fake_build(
      fp_b,
      pkg_state(gsm.core = c("1.1.0", "s2")),
      "2026-01-03T00:00:00Z"
    )
  )
  expect_equal(selected_fp(index, pkg_state(gsm.core = "1.0.0")), fp_a)
  expect_equal(
    selected_fp(index, pkg_state(gsm.core = c("1.0.0", "unbuilt"))),
    fp_a
  )
})

test_that("an unbuilt version falls back to the newest build at or below it (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  fp_c <- strrep("c", 64)
  index <- fake_index(
    fake_build(fp_a, pkg_state(gsm.core = "1.0.0"), "2026-01-03T00:00:00Z"),
    fake_build(fp_b, pkg_state(gsm.core = "1.1.0"), "2026-01-02T00:00:00Z"),
    fake_build(fp_c, pkg_state(gsm.core = "1.3.0"), "2026-01-04T00:00:00Z")
  )
  # Local dev version 1.2.0.9000: 1.0.0 and 1.1.0 qualify; newest built wins.
  expect_equal(selected_fp(index, pkg_state(gsm.core = "1.2.0.9000")), fp_a)
})

test_that("multiple surviving fingerprints resolve to the newest built_at (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  fp_c <- strrep("c", 64)
  index <- fake_index(
    fake_build(
      fp_a,
      pkg_state(gsm.core = "1.0.0.9000"),
      "2026-01-02T00:00:00Z"
    ),
    fake_build(
      fp_b,
      pkg_state(gsm.core = "1.0.0.9000"),
      "2026-01-05T00:00:00Z"
    ),
    fake_build(fp_c, pkg_state(gsm.core = "1.0.0.9000"), "2026-01-03T00:00:00Z")
  )
  expect_equal(selected_fp(index, pkg_state(gsm.core = "1.0.0.9000")), fp_b)
})

test_that("filters combine across packages (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  fp_c <- strrep("c", 64)
  index <- fake_index(
    fake_build(
      fp_a,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "1.0.0"),
      "2026-01-05T00:00:00Z"
    ),
    fake_build(
      fp_b,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "2.0.0"),
      "2026-01-02T00:00:00Z"
    ),
    fake_build(
      fp_c,
      pkg_state(gsm.core = c("1.0.0", "s2"), gsm.kri = "2.0.0"),
      "2026-01-06T00:00:00Z"
    )
  )
  expect_equal(
    selected_fp(
      index,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "2.0.0")
    ),
    fp_b
  )
})

test_that("no surviving build errors, naming the blocking package (#206)", {
  fp_a <- strrep("a", 64)
  index <- fake_index(
    fake_build(fp_a, pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "2.0.0"))
  )
  expect_error(
    .testdata_select(
      index,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "1.0.0")
    ),
    class = "gsm_testdata_no_match"
  )
  expect_snapshot(
    .testdata_select(
      index,
      pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "1.0.0")
    ),
    error = TRUE
  )
})

test_that("override builds are ignored and newer formats are rejected (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  index <- fake_index(
    fake_build(fp_a, pkg_state(gsm.core = "1.0.0"), "2026-01-02T00:00:00Z"),
    fake_build(
      fp_b,
      pkg_state(gsm.core = "1.0.0"),
      "2026-01-05T00:00:00Z",
      source = "override"
    )
  )
  expect_equal(selected_fp(index, pkg_state(gsm.core = "1.0.0")), fp_a)
  expect_error(.testdata_parse_index(list(format = 3)), "format 3")
  expect_error(.testdata_parse_index(list()), "format")
})

test_that("the checker resolves a tag and verifies the snapshot key (#206)", {
  fp_a <- strrep("a", 64)
  server <- local_fake_releases()
  fp <- server$release(list(lSource = list(x = 1)))
  server$index(fake_build(fp, pkg_state(gsm.core = c("1.0.0", "s1"))))
  installed <- pkg_state(gsm.core = c("1.0.0", "s1"))
  cache <- local_testdata_env(server, function() installed)

  expect_equal(run_checker(cache), paste0("data-", substr(fp, 1, 12)))

  bad <- local_fake_releases()
  bad$release(list(lSource = 1), fingerprint = fp_a)
  bad$index(fake_build(fp_a, pkg_state(gsm.core = "1.0.0")))
  # Corrupt the key so it no longer matches the fingerprint.
  path <- file.path(
    bad$root,
    paste0("data-", substr(fp_a, 1, 12)),
    "snapshot.json"
  )
  snap <- jsonlite::read_json(path)
  snap$key <- "sha256:other"
  jsonlite::write_json(snap, path, auto_unbox = TRUE)
  cache2 <- local_testdata_env(bad, function() pkg_state(gsm.core = "1.0.0"))
  expect_error(run_checker(cache2), "doesn't match the index")
})

test_that("an exact match skips the index until packages change (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  server$index(fake_build(fp, pkg_state(gsm.core = c("1.0.0", "s1"))))
  installed <- pkg_state(gsm.core = c("1.0.0", "s1"))
  cache <- local_testdata_env(server, function() installed)
  run_checker(cache)

  server$reset_requests()
  run_checker(cache)
  expect_length(server$requests(), 0)

  installed <- pkg_state(gsm.core = "1.0.0")
  run_checker(cache)
  expect_true(any(grepl("index\\.json", server$requests())))
})

test_that("an unreachable index falls back to the last release (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  server$index(fake_build(fp, pkg_state(gsm.core = c("1.0.0", "s1"))))
  # No RemoteSha, so not an exact match: every check reads the index.
  installed <- pkg_state(gsm.core = "1.0.0")
  cache <- local_testdata_env(server, function() installed)
  tag <- run_checker(cache)

  unlink(file.path(server$root, "index.json"))
  expect_message(expect_equal(run_checker(cache), tag), "last chosen release")

  fresh <- withr::local_tempdir()
  expect_error(run_checker(fresh), "Can't read the gsm.datasim test data index")
})

test_that("use_testdata_tag() pins a release without the index (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  installed <- pkg_state(gsm.core = "1.0.0")
  cache <- local_testdata_env(server, function() installed)
  tag <- paste0("data-", substr(fp, 1, 12))
  use_testdata_tag(tag)

  expect_equal(run_checker(cache), tag)
  expect_false(any(grepl("index\\.json", server$requests())))

  use_testdata_tag("data-missing")
  expect_error(run_checker(cache), "Can't find test data release")
  use_testdata_tag(c("a", "b"))
  expect_error(run_checker(cache), "single string")
})

test_that("bindings download, verify, and cache objects end to end (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(analyticsInput = mtcars, lSource = list(x = 1)))
  server$index(fake_build(fp, pkg_state(gsm.core = "1.0.0")))
  installed <- pkg_state(gsm.core = "1.0.0")
  cache <- local_testdata_env(server, function() installed)

  env <- new.env()
  handle <- .register_testdata(env)
  expect_equal(env$analyticsInput, mtcars)
  expect_equal(env$lSource$x, 1)
  expect_identical(gsm_testdata(), handle)
  expect_s3_class(handle$cache, "cache_disk")
  expect_length(handle$cache$keys(), 2)
  expect_true(file.exists(file.path(cache, "testdata-state.rds")))

  # Second load: served from disk, no object downloads.
  server$reset_requests()
  clear_testdata_snapshots()
  env2 <- new.env()
  .register_testdata(env2)
  expect_equal(env2$analyticsInput, mtcars)
  expect_false(any(grepl("\\.rds$", server$requests())))
})

test_that("a corrupted object fails the checksum (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  server$index(fake_build(fp, pkg_state(gsm.core = "1.0.0")))
  saveRDS(
    iris,
    file.path(server$root, paste0("data-", substr(fp, 1, 12)), "lSource.rds")
  )
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  .register_testdata(env)
  expect_error(env$lSource, "Checksum mismatch")
})

test_that("a release missing a bound object errors clearly (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  server$index(fake_build(fp, pkg_state(gsm.core = "1.0.0")))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  .register_testdata(env)
  expect_error(env$analyticsInput, "has no .*analyticsInput")
})

test_that("the gsm.testdata_cache option supplies the user's cache (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  server$index(fake_build(fp, pkg_state(gsm.core = "1.0.0")))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))
  mine <- cachem::cache_mem()
  withr::local_options(gsm.testdata_cache = mine)

  env <- new.env()
  handle <- .register_testdata(env)
  env$lSource
  expect_identical(handle$cache, mine)
  expect_length(mine$keys(), 1)
})

test_that("gsm_testdata(cache = ) swaps the cache and sets the option (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  server$index(fake_build(fp, pkg_state(gsm.core = "1.0.0")))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  handle <- .register_testdata(env)
  expect_s3_class(handle$cache, "cache_disk")
  expect_identical(gsm_testdata()$cache, handle$cache)

  mine <- cachem::cache_mem()
  gsm_testdata(cache = mine)
  expect_identical(handle$cache, mine)
  expect_identical(getOption("gsm.testdata_cache"), mine)
  env$lSource
  expect_length(mine$keys(), 1)
})

test_that("use_testdata_snapshot() reads a snapshot with no network or cache (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  handle <- .register_testdata(env)
  use_testdata_snapshot(file.path(
    server$root,
    paste0("data-", substr(fp, 1, 12))
  ))
  # Takes priority over a pinned tag.
  use_testdata_tag("data-nope")

  expect_equal(env$lSource, mtcars)
  expect_length(server$requests(), 0)
  expect_length(handle$cache$keys(), 0)
  expect_equal(handle$key(), paste0("sha256:", fp))

  expect_false(is.null(use_testdata_snapshot(NULL)))
  expect_null(handle$snapshot)
})

test_that("use_testdata_snapshot() set before loading is applied at load (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))
  use_testdata_snapshot(file.path(
    server$root,
    paste0("data-", substr(fp, 1, 12))
  ))

  env <- new.env()
  .register_testdata(env)
  expect_equal(env$lSource, mtcars)
  expect_length(server$requests(), 0)
})

test_that("use_testdata_snapshot() verifies checksums and rejects bad folders (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  dir <- file.path(server$root, paste0("data-", substr(fp, 1, 12)))
  saveRDS(iris, file.path(dir, "lSource.rds"))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  .register_testdata(env)
  use_testdata_snapshot(dir)
  expect_error(env$lSource, "Checksum mismatch")

  expect_error(
    use_testdata_snapshot(file.path(server$root, "missing")),
    "does not exist"
  )
  expect_error(
    use_testdata_snapshot(withr::local_tempdir()),
    "No .*snapshot.json"
  )
  # A failed setting is rolled back.
  expect_equal(gsm$testdata_dir, dir)

  # At load, a bad folder warns instead of failing.
  assign("testdata_dir", file.path(server$root, "missing"), envir = gsm)
  expect_warning(.register_testdata(new.env()), "Ignoring the test data folder")
})

test_that("setter defaults read environment variables (#206)", {
  local_testdata_settings()
  withr::local_envvar(GSM_TESTDATA_SNAPSHOT = "some/dir", GSM_TESTDATA_TAG = NA)
  # No handle yet (as in .onLoad), so setting never errors.
  expect_no_error({
    use_testdata_snapshot()
    use_testdata_tag()
  })
  expect_equal(gsm$testdata_dir, "some/dir")
  expect_null(.testdata_setting("testdata_tag"))
})

test_that("use_testdata_cache_dir() sets the option and switches the cache (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  server$index(fake_build(fp, pkg_state(gsm.core = "1.0.0")))
  local_testdata_env(server, function() pkg_state(gsm.core = "1.0.0"))
  env <- new.env()
  handle <- .register_testdata(env, cache = cachem::cache_mem())

  dir <- file.path(withr::local_tempdir(), "cache")
  expect_null(use_testdata_cache_dir(dir))
  expect_s3_class(getOption("gsm.testdata_cache"), "cache_disk")
  expect_identical(handle$cache, getOption("gsm.testdata_cache"))
  env$lSource
  expect_length(handle$cache$keys(), 1)
  expect_true(dir.exists(dir))

  expect_error(use_testdata_cache_dir(""), "non-empty")
  expect_error(use_testdata_cache_dir(c("a", "b")), "non-empty")
})
