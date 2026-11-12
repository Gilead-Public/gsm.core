test_that(".testdata_inputs_hash() hashes packages (#206)", {
  # From data-index builds/71ba4400...json (gsm.datasim#153).
  pkgs <- helper_pkg_state(
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
  index <- helper_fake_index(
    helper_fake_build(
      fp_a,
      helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1")),
      "2026-01-02T00:00:00Z"
    ),
    helper_fake_build(
      fp_b,
      helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k2")),
      "2026-01-03T00:00:00Z"
    )
  )
  pick <- .testdata_select(
    index,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1"))
  )
  expect_equal(pick$match, "exact")
  expect_equal(pick$build$fingerprint, fp_a)
})

test_that(".testdata_select() filters by SHA, then version (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  fp_c <- strrep("c", 64)
  index <- helper_fake_index(
    helper_fake_build(
      fp_a,
      helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "1.0.0"),
      "2026-01-05T00:00:00Z"
    ),
    helper_fake_build(
      fp_b,
      helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "2.0.0"),
      "2026-01-02T00:00:00Z"
    ),
    helper_fake_build(
      fp_c,
      helper_pkg_state(gsm.core = c("1.0.0", "s2"), gsm.kri = "2.0.0"),
      "2026-01-06T00:00:00Z"
    )
  )
  pick <- .testdata_select(
    index,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("2.0.0", "k9"))
  )
  expect_equal(pick$match, "filtered")
  expect_equal(pick$build$fingerprint, fp_b)
  # gsm.kri not installed: no filter, newest SHA match wins.
  expect_equal(
    helper_select_fingerprint(index, helper_pkg_state(gsm.core = c("1.0.0", "s1"))),
    fp_a
  )
})

test_that("an unbuilt version falls back to the newest build at or below it (#206)", {
  fp_a <- strrep("a", 64)
  fp_b <- strrep("b", 64)
  fp_c <- strrep("c", 64)
  index <- helper_fake_index(
    helper_fake_build(fp_a, helper_pkg_state(gsm.core = "1.0.0"), "2026-01-03T00:00:00Z"),
    helper_fake_build(fp_b, helper_pkg_state(gsm.core = "1.1.0"), "2026-01-02T00:00:00Z"),
    helper_fake_build(fp_c, helper_pkg_state(gsm.core = "1.3.0"), "2026-01-04T00:00:00Z")
  )
  expect_equal(
    helper_select_fingerprint(index, helper_pkg_state(gsm.core = "1.2.0.9000")),
    fp_a
  )
})

test_that("no surviving build errors, naming the blocking package (#206)", {
  index <- helper_fake_index(
    helper_fake_build(
      strrep("a", 64),
      helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "2.0.0")
    )
  )
  expect_snapshot(
    .testdata_select(
      index,
      helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k9"))
    ),
    error = TRUE
  )
  expect_error(
    .testdata_select(index, helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")),
    class = "gsm_testdata_no_match"
  )
})

test_that(".testdata_parse_index() drops overrides and validates format (#206)", {
  fp_a <- strrep("a", 64)
  index <- helper_fake_index(
    helper_fake_build(fp_a, helper_pkg_state(gsm.core = "1.0.0"), "2026-01-02T00:00:00Z"),
    helper_fake_build(
      strrep("b", 64),
      helper_pkg_state(gsm.core = "1.0.0"),
      "2026-01-05T00:00:00Z",
      source = "override"
    )
  )
  expect_equal(
    helper_select_fingerprint(index, helper_pkg_state(gsm.core = "1.0.0")),
    fp_a
  )
  expect_error(
    .testdata_parse_index(list(format = .testdata_index_format + 1)),
    "format 3"
  )
  expect_error(.testdata_parse_index(list()), "format")
  empty <- .testdata_parse_index(list(format = 2, packages = character()))
  expect_error(.testdata_select(empty, list()), "no builds")
})

test_that("the checker resolves a tag and verifies the snapshot key (#206)", {
  fp_a <- strrep("a", 64)
  server <- local_fake_releases()
  fp <- server$release(list(lSource = list(x = 1)))
  server$index(helper_fake_build(
    fp,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  ))
  installed <- helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  cache <- local_testdata_env(server, function() installed)

  expect_equal(helper_run_checker(cache), paste0("data-", substr(fp, 1, 12)))

  bad <- local_fake_releases()
  bad$release(list(lSource = 1), fingerprint = fp_a)
  bad$index(helper_fake_build(fp_a, helper_pkg_state(gsm.core = "1.0.0")))
  # Corrupt the key so it no longer matches the fingerprint.
  path <- file.path(
    bad$root,
    paste0("data-", substr(fp_a, 1, 12)),
    "snapshot.json"
  )
  snap <- jsonlite::read_json(path)
  snap$key <- "sha256:other"
  jsonlite::write_json(snap, path, auto_unbox = TRUE)
  cache2 <- local_testdata_env(bad, function() {
    helper_pkg_state(gsm.core = "1.0.0")
  })
  expect_error(helper_run_checker(cache2), "doesn't match the index")
})

test_that("an exact match skips the index until packages change (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  server$index(helper_fake_build(
    fp,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  ))
  installed <- helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  cache <- local_testdata_env(server, function() installed)
  helper_run_checker(cache)

  server$reset_requests()
  helper_run_checker(cache)
  expect_length(server$requests(), 0)

  installed <- helper_pkg_state(gsm.core = "1.0.0")
  helper_run_checker(cache)
  expect_true(any(grepl("index\\.json", server$requests())))
})

test_that("an unreachable index falls back to the last release (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  server$index(helper_fake_build(
    fp,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  ))
  # No RemoteSha, so not an exact match: every check reads the index.
  installed <- helper_pkg_state(gsm.core = "1.0.0")
  cache <- local_testdata_env(server, function() installed)
  tag <- helper_run_checker(cache)

  unlink(file.path(server$root, "index.json"))
  expect_message(expect_equal(helper_run_checker(cache), tag), "last chosen release")

  fresh <- withr::local_tempdir()
  expect_error(helper_run_checker(fresh), "Can't read the gsm.datasim test data index")
})

test_that("use_testdata_tag() pins a release without the index (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = 1))
  cache <- local_testdata_env(server, function() helper_pkg_state(gsm.core = "1.0.0"))
  tag <- paste0("data-", substr(fp, 1, 12))
  use_testdata_tag(tag)

  expect_equal(helper_run_checker(cache), tag)
  expect_false(any(grepl("index\\.json", server$requests())))

  use_testdata_tag("data-missing")
  expect_error(helper_run_checker(cache), "Can't find test data release")
  use_testdata_tag(c("a", "b"))
  expect_error(helper_run_checker(cache), "single string")
  use_testdata_tag("bad tag")
  expect_error(helper_run_checker(cache), "must match")
})

test_that("bindings load release objects, with state and cache in .testdata_dir() (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(analyticsInput = mtcars, lSource = list(x = 1)))
  server$index(helper_fake_build(fp, helper_pkg_state(gsm.core = "1.0.0")))
  cache <- local_testdata_env(server, function() helper_pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  handle <- .register_testdata(env)
  expect_equal(env$analyticsInput, mtcars)
  expect_equal(env$lSource$x, 1)
  expect_error(env$reportingGroups, "has no .*reportingGroups")
  expect_s3_class(handle$cache, "cache_disk")
  expect_equal(
    normalizePath(handle$cache$info()$dir),
    normalizePath(file.path(cache, "values"))
  )
  expect_true(file.exists(file.path(cache, "testdata-state.rds")))
})

test_that("gsm_testdata(cache = ) swaps the cache and sets the option (#206)", {
  server <- local_fake_releases()
  local_testdata_env(server, function() helper_pkg_state(gsm.core = "1.0.0"))

  handle <- .register_testdata(new.env())
  expect_identical(gsm_testdata(), handle)

  mine <- cachem::cache_mem()
  gsm_testdata(cache = mine)
  expect_identical(handle$cache, mine)
  expect_identical(getOption("gsm.testdata_cache"), mine)
})

test_that("use_testdata_snapshot() reads a snapshot with no network or cache (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  local_testdata_env(server, function() helper_pkg_state(gsm.core = "1.0.0"))

  env <- new.env()
  handle <- .register_testdata(env)
  use_testdata_snapshot(file.path(server$root, paste0("data-", substr(fp, 1, 12))))
  # Takes priority over a pinned tag.
  use_testdata_tag("data-nope")

  expect_equal(env$lSource, mtcars)
  expect_length(server$requests(), 0)

  expect_false(is.null(use_testdata_snapshot(NULL)))
  expect_null(handle$snapshot)
})

test_that("a bad use_testdata_snapshot() folder rolls back, or warns at load (#206)", {
  server <- local_fake_releases()
  fp <- server$release(list(lSource = mtcars))
  dir <- file.path(server$root, paste0("data-", substr(fp, 1, 12)))
  local_testdata_env(server, function() helper_pkg_state(gsm.core = "1.0.0"))

  .register_testdata(new.env())
  use_testdata_snapshot(dir)

  # Folder validation is refresh's (test-refresh-snapshot.R); the rollback is
  # gsm.core's.
  expect_error(use_testdata_snapshot(file.path(server$root, "missing")))
  expect_equal(gsm$testdata_dir, dir)

  assign("testdata_dir", file.path(server$root, "missing"), envir = gsm)
  expect_warning(.register_testdata(new.env()), "Ignoring the test data folder")
})

test_that("setter defaults read environment variables (#206)", {
  local_testdata_settings()
  withr::local_envvar(GSM_TESTDATA_SNAPSHOT = "some/dir", GSM_TESTDATA_TAG = NA)
  # No handle yet (as in .onLoad), so setting never errors.
  use_testdata_snapshot()
  use_testdata_tag()
  expect_equal(gsm$testdata_dir, "some/dir")
  expect_null(.testdata_setting("testdata_tag"))
})

test_that("use_testdata_cache_dir() sets the option and switches the cache (#206)", {
  server <- local_fake_releases()
  cache <- local_testdata_env(server, function() helper_pkg_state(gsm.core = "1.0.0"))
  handle <- .register_testdata(new.env(), cache = cachem::cache_mem())

  dir <- file.path(withr::local_tempdir(), "cache")
  expect_null(use_testdata_cache_dir(dir))
  expect_identical(handle$cache, getOption("gsm.testdata_cache"))
  expect_equal(normalizePath(handle$cache$info()$dir), normalizePath(dir))

  # NULL returns to the default cache.
  use_testdata_cache_dir(NULL)
  expect_null(getOption("gsm.testdata_cache"))
  expect_equal(
    normalizePath(handle$cache$info()$dir),
    normalizePath(file.path(cache, "values"))
  )

  expect_error(use_testdata_cache_dir(""), "non-empty")
})

test_that("testdata_is_available() validates names and loads objects (#206)", {
  expect_error(testdata_is_available("nope"), "Unknown test data object")
  skip_if_no_testdata()
  expect_true(testdata_is_available("lSource"))
})
