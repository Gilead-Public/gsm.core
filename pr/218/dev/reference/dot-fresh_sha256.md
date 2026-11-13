# Compute a file's sha256, treating CRLF as LF in text files

Text files (no NUL bytes, the same heuristic Git uses) are hashed with
CRLF normalized to LF, so a copy whose line endings were converted (e.g.
by a Windows checkout or download tool) still verifies. Other files are
hashed byte for byte. For LF text and binary files this equals the plain
file sha256 (#215).

## Usage

``` r
.fresh_sha256(path)
```

## Arguments

- path:

  `character(1)` Path to the file.

## Value

`character(1)` The lowercase hex sha256.
