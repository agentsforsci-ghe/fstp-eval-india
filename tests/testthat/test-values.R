numeric_values <- function(d) unlist(d[vapply(d, is.numeric, TRUE)])

test_that("no value is negative", {
  datasets <- list(plants, fstp_performance, stp_performance, sludge_characteristics,
                   removal_stages, samples, bod_compliance)
  for (d in datasets) {
    expect_true(all(numeric_values(d) >= 0, na.rm = TRUE))
  }
})

test_that("removal percentages are between 0 and 100", {
  for (d in list(fstp_performance, stp_performance, removal_stages)) {
    pct <- unlist(d[grepl("_pct$", names(d))])
    expect_true(all(pct >= 0 & pct <= 100, na.rm = TRUE))
  }
})

test_that("pH values are between 0 and 14, apart from one printed error", {
  for (d in list(fstp_performance, stp_performance, sludge_characteristics)) {
    expect_true(all(d$ph >= 0 & d$ph <= 14))
  }
  # Annexure II prints the inlet pH of Thirumangalam as 280.6
  known <- samples$plant_id == "tn-thirumangalam" & samples$sample_type == "Inlet"
  expect_equal(samples$ph[known], 280.6)
  expect_true(all(samples$ph[!known] >= 0 & samples$ph[!known] <= 14, na.rm = TRUE))
})

test_that("the only empty cell of Tables 9 to 13 is the BOD removal of Nalgonda", {
  missing <- is.na(as.matrix(fstp_performance[vapply(fstp_performance, is.numeric, TRUE)]))
  expect_equal(sum(missing), 1)
  expect_true(is.na(fstp_performance$bod_removal_pct[fstp_performance$plant_id == "tg-nalgonda"]))
  expect_false(anyNA(numeric_values(stp_performance)))
  expect_false(anyNA(numeric_values(sludge_characteristics)))
  expect_false(anyNA(numeric_values(removal_stages)))
})
