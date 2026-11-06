# no surviving build errors, naming the blocking package (#206)

    Code
      .testdata_select(index, pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = "1.0.0"))
    Condition
      Error in `.testdata_abort_no_match()`:
      ! No published gsm test data matches gsm.kri 1.0.0 together with your other installed gsm packages.
      i gsm.kri is probably out of step with the other gsm packages. Updating it (or them) to a compatible set usually fixes this.
      i To use specific data anyway, see `use_testdata_tag()` or `use_testdata_snapshot()`.

