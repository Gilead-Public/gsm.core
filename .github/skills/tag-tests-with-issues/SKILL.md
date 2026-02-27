---
name: tag-tests-with-issues
description: Identify likely GitHub issues connected to test cases. Use when asked to tag tests with issues or get started with qcthat.
---

# Tag tests with issues

Add issue references (e.g., `(#123)`) to test descriptions to connect tests to the features or bugs they address. Execute with minimal interaction; skip chat output intended only for user review.

Note: Files without a full path are in `tests/testthat`.

## Step 1: Load test and issue context

Extract all tests and process them file-by-file. `MapTestFilesToPotentialIssues()` can be slow, so pre-compute the issue-commit mappings once with `MapLongIssueCommits()` and pass the result to each call. Do not try to speed up the process by avoiding this function. Its output is required for `PrepareTestIssueContext()`, and the output of `PrepareTestIssueContext()` is your source of all context for the remaining steps.

```r
library(qcthat)

dfFileTests <- ExtractTestsFromFiles()
lFileTestsSplit <- split(dfFileTests, dfFileTests$File)

# Pre-compute issue-commit mappings once (avoids redundant API calls per file)
dfIssueCommitsLong <- MapLongIssueCommits()

dfPotentialIssues <- MapTestFilesToPotentialIssues(
  lFileTestsSplit[[1]],
  dfIssueCommitsLong = dfIssueCommitsLong
)
dfTestIssueContext <- PrepareTestIssueContext(dfPotentialIssues)
```

Process files one at a time (`lFileTestsSplit[[1]]`, then `lFileTestsSplit[[2]]`, etc.) unless told otherwise, but use the same `dfIssueCommitsLong` instance for each.

`PrepareTestIssueContext()` returns a data frame with columns:

| Column | Type | Description |
|--------|------|-------------|
| `Test` | character | Test description |
| `File` | character | Test file name |
| `LineStart` / `LineEnd` | integer | Line numbers in the test file |
| `Issues` | list of integer vectors | Issues already tagged in the description |
| `PotentialIssueDetails` | list of tibbles | One tibble per test with `Issue`, `Title`, `Body` for each potentially related issue, identified by matching commits that modified the test with commits that closed issues |
| `TestCode` | list of character vectors | The actual test code |

## Step 2: Match tests to issues

For each test, compare code and description against `PotentialIssueDetails`. Do not use `git blame`, `gh`, or other tools — `dfTestIssueContext` contains everything you need. Matches must come only from the `Issue` column of `PotentialIssueDetails` for that test. Most tests match one issue; some match zero; a few match more than one.

### Decision process

For every test with non-empty `PotentialIssueDetails`:

**1. Read `TestCode` to understand what the test actually does.** Descriptions can be vague — code is the ground truth. Extract: the primary function called, what `expect_*()` calls verify, and any edge cases or context.

**2. Read the ENTIRE `Body` of each potential issue.** Titles are often vague or misleading. Note whether the body names the function being tested, describes the specific behavior, and what the issue is *for*: implementing the feature, fixing a bug, or something unrelated.

**3. Look for a function name match.** If an issue body mentions the function AND is about implementing, fixing, or extending it, that is a strong match. The issue must be *about* the function — one that merely mentions it in passing (e.g., "this refactoring touched `ProcessPayment()`") is not a match.

**4. If no function name match, look for a specific behavioral match.** Higher bar than step 3. The body must describe the *specific behavior* the test checks — not just the general feature area. If the connection is only that they're in the same feature area, that is not enough.

For example: a test that checks `ValidateCardNumber()` rejects expired cards does NOT match an issue about "Payment processing" whose body discusses order workflows. It DOES match an issue whose body says "add validation for expired card numbers," even without naming `ValidateCardNumber()`.

**5. Decide.**
- **Tag** if you found a strong match in step 3, or a specific behavioral match in step 4.
- **Skip** if potential issues are about unrelated functionality.
- **When uncertain**, lean slightly toward skipping. An untagged test can be found later; an incorrect tag must be identified and removed during review.

**6. Check for duplicates.** The `Issues` column shows what's already tagged. Do not re-add existing tags.

### Common errors to avoid

Do NOT match on superficial keyword overlap or feature-area proximity:

- **Keyword overlap in title only**: Test mentions "payments" → matching any issue with "payments" in the title when the body describes different work
- **Feature-area match without behavioral match**: Test checks `FormatReceipt()` handles refunds → matching an issue about "Payment processing" whose body discusses order validation
- **Body contradicts title**: Issue title sounds relevant but the body describes unrelated work — always trust the body over the title
- **Incidental file changes**: Issue is about infrastructure or cleanup that happened to touch the same file
- **Description vs. code mismatch**: Matching on the test description when `TestCode` shows the test checks something different

### Special cases

**Tests with `intIssue` in `ExpectUserAccepts()` calls**: Tag with the referenced issue number unless the value is obviously test data (e.g., 1, 12, 123).

**Tests already tagged**: If `Issues` is non-empty and looks correct, skip. When adding new tags, preserve existing ones and keep issue numbers in ascending order.

**Disambiguating similar issues**: Read each body completely and pick the one that most specifically describes the behavior tested. Reject issues about infrastructure or the broader feature area. Tag with all if multiple genuinely pass steps 3–4, but this should be uncommon.

### Example

```r
test <- dfTestIssueContext[5, ]

test$Test
# "ProcessPayment handles declined cards"
test$TestCode[[1]]
# test_that("ProcessPayment handles declined cards", {
#   local_mocked_bindings(GetAPIResult = function(...) list(result = "declined"))
#   expect_error(ProcessPayment(), class = "error-payment_declined")
# })

test$PotentialIssueDetails[[1]]
#   Issue Title                                Body
#   42    "Payment system overhaul"            "Refactor payment module architecture..."
#   87    "Payment processing error handling"  "Implement ProcessPayment() to handle declined
#                                               cards, expired cards, and..."
#   104   "Add logging to payment module"      "Add debug logging throughout payment..."

# Issue 42: about refactoring, not implementing ProcessPayment → NO
# Issue 87: explicitly mentions ProcessPayment() and declined cards → YES
# Issue 104: about logging, unrelated → NO

# Decision: Tag with #87
```

## Step 3: Tag untagged tests by title match

After commit-based matching, attempt to tag any tests that still have no issue tags. Fetch the full issue list once before the file loop begins:

```r
dfAllIssues <- FetchRepoIssues()  # returns Issue (integer) and Title (character) at minimum
```

For each test where `length(test$Issues[[1]]) == 0`, compare the test description to all issue titles. Apply a **higher bar** than Step 2 — titles alone carry less signal than commit history plus issue bodies. Only tag if the title unambiguously describes the specific behavior the test checks. Do not match on shared keywords or feature-area overlap.

Mark these in `test_tag_reasons.qmd` with **"Title match"** in the Reason column so reviewers know they are lower-confidence.

## Step 4: Edit test files

### Tag format

- Single issue: `test_that("does something (#123)", { ... })`
- Multiple issues: `test_that("does something (#123, #456)", { ... })`

### Editing guidelines

- **Only edit** the parenthetical issue tags in the `test_that()` description. Do not change anything else.
- Preserve existing tags; sort issue numbers ascending.
- Use `File`, `LineStart`, and `LineEnd` to locate each test.
- Batch edits to the same file; preserve code style and indentation.

### Editing code

```r
IssuesToTag <- 87L  # include existing tags if any
test$IssueTags <- glue::glue("#{IssuesToTag}") |>
  glue::glue_collapse(sep = ", ")

readLines(test$File) |>
  stringr::str_replace(
    stringr::fixed(test$Test),
    glue::glue_data(test, "{Test} ({IssueTags})")
  ) |>
  writeLines(test$File)
```

## Step 5: Log reasoning

Keep a running log in `test_tag_reasons.qmd` (renders to HTML). Include a table per file with columns "Test", "Issue" (as a GitHub link), and "Reason" (1–2 sentences). Update as you work, not all at once at the end.

## Validation

After tagging:
- Run `devtools::test(reporter = "check")` — only descriptions should change (snapshots may update)
- Re-run `ExtractTestsFromFiles()` and confirm `Issues` contains the tagged numbers
- Render `test_tag_reasons.qmd`
