# The fixture bod-discharge-hand-typed.csv holds the discharge BOD of the 69
# sampled plants, typed by hand from Tables 9 and 10 and from Annexure II of
# the report and checked against the PDF. It was made independently of the
# extraction scripts, so agreement checks both.
hand <- read.csv(test_path("fixtures", "bod-discharge-hand-typed.csv"))
hand$plant_id <- plants$plant_id[match(hand$plant, plants$plant_name)]

test_that("every plant of the hand-typed file has a plant_id", {
  expect_false(anyNA(hand$plant_id))
})

test_that("the discharge BOD of Tables 9 and 10 agrees with the hand-typed file", {
  extracted <- rbind(fstp_performance[c("plant_id", "discharge_bod_mgl")],
                     stp_performance[c("plant_id", "discharge_bod_mgl")])
  expect_equal(extracted$discharge_bod_mgl[match(hand$plant_id, extracted$plant_id)],
               hand$bod_summary_mgl)
})

test_that("the final outlet BOD of Annexure II agrees with the hand-typed file", {
  outlets <- samples[samples$sample_type %in% c("Outlet", "Outlet After chlorination"), ]
  expect_equal(outlets$bod_mgl[match(hand$plant_id, outlets$plant_id)], hand$bod_annex_mgl)
})

test_that("bod_compliance equals the hand-typed file", {
  cols <- c("plant", "state", "plant_type", "technology", "bod_summary_mgl", "bod_annex_mgl")
  expect_equal(as.data.frame(bod_compliance[cols]), hand[cols])
})

test_that("the mean and median of Table 11 agree with its printed rows", {
  cols <- c("ph", "ts_mgl", "cod_mgl", "bod_mgl", "faecal_coliform_mpn_100ml",
            "ts_cod_ratio", "cod_bod_ratio")
  printed_mean <- c(7.5, 29665.8, 50421.0, 8142.7, 4187322.5, 0.7, 7.7)
  printed_median <- c(7.7, 27580.0, 48905.0, 6928.0, 1275000.0, 0.6, 5.5)
  # The printed rows have one decimal, and some are cut off rather than
  # rounded, so the recomputed values may differ by up to 0.15
  expect_true(all(abs(vapply(sludge_characteristics[cols], mean, 0) - printed_mean) <= 0.15))
  expect_true(all(abs(vapply(sludge_characteristics[cols], median, 0) - printed_median) <= 0.15))
})
