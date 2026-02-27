## General

- When running R from the console, use `--quiet --vanilla`.
- Always run `air format .` after generating code.
- After adding or changing functions, update their documentation per @.github/skills/document/SKILL.md.

## Skills

Load skills from @.github/skills when the user triggers them.

| Trigger               | Path                                           |
|------------------------|------------------------------------------------|
| tag tests with issues | @.github/skills/tag-tests-with-issues/SKILL.md |
| document functions    | @.github/skills/document/SKILL.md              |

## Testing

- Tests for `R/{name}.R` go in `tests/testthat/test-{name}.R`.
- `devtools::test(reporter = "check")` runs all tests; add `filter = "name"` to run one file.
- All new code needs a test; place it next to similar existing tests.

### Coverage

Goal: 100% file-level coverage. After editing a file, verify (excluding `R/gsm.reporting-package.R`):

```r
covr_res <- devtools:::test_coverage_active_file("R/FileName.R")
which(purrr::map_int(covr_res, "value") == 0)
```
