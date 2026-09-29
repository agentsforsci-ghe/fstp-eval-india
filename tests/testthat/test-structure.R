states <- c("Telangana", "Tamil Nadu", "Odisha", "Rajasthan", "Uttar Pradesh",
            "Madhya Pradesh", "Chhattisgarh", "Uttarakhand")

test_that("each dataset has the number of rows of the printed tables", {
  expect_equal(nrow(plants), 73)
  expect_equal(nrow(fstp_performance), 47)
  expect_equal(nrow(stp_performance), 22)
  expect_equal(nrow(sludge_characteristics), 45)
  expect_equal(nrow(removal_stages), 90)
  expect_equal(nrow(samples), 197)
  expect_equal(nrow(bod_compliance), 69)
})

test_that("the rows per state and technology agree with the printed tables", {
  expect_equal(as.vector(table(factor(plants$state, levels = states))),
               c(12, 9, 21, 3, 10, 4, 2, 12))
  fstp_groups <- c("DEWATS", "MBBR", "Geotube", "Mizuchi",
                   "Electrocoagulation-flotation", "Packaged STP")
  expect_equal(as.vector(table(factor(fstp_performance$technology, levels = fstp_groups))),
               c(33, 6, 3, 3, 1, 1))
  stp_groups <- c("SBR", "MBBR", "UASB", "WSP", "ASP")
  expect_equal(as.vector(table(factor(stp_performance$technology, levels = stp_groups))),
               c(11, 5, 3, 2, 1))
  expect_equal(as.vector(table(factor(removal_stages$parameter, levels = c("COD", "BOD")))),
               c(45, 45))
  expect_equal(length(unique(samples$plant_id)), 69)
})

test_that("plant_id identifies each plant once in each dataset", {
  expect_false(anyDuplicated(plants$plant_id) > 0)
  expect_false(anyDuplicated(fstp_performance$plant_id) > 0)
  expect_false(anyDuplicated(stp_performance$plant_id) > 0)
  expect_false(anyDuplicated(sludge_characteristics$plant_id) > 0)
  expect_false(anyDuplicated(bod_compliance$plant_id) > 0)
  expect_false(anyDuplicated(paste(removal_stages$plant_id, removal_stages$parameter)) > 0)
  expect_false(anyDuplicated(paste(samples$plant_id, samples$sample_type)) > 0)
})

test_that("plant_id links every dataset to plants, with the same state", {
  datasets <- list(fstp_performance, stp_performance, sludge_characteristics,
                   removal_stages, samples, bod_compliance)
  for (d in datasets) {
    idx <- match(d$plant_id, plants$plant_id)
    expect_false(anyNA(idx))
    expect_equal(d$state, plants$state[idx])
  }
})

test_that("the FSTPs and STPs in Tables 9 and 10 are the sampled plants", {
  sampled <- plants$plant_id[plants$sampled]
  expect_setequal(c(fstp_performance$plant_id, stp_performance$plant_id), sampled)
  expect_true(all(plants$plant_type[match(fstp_performance$plant_id, plants$plant_id)] == "FSTP"))
  expect_true(all(plants$plant_type[match(stp_performance$plant_id, plants$plant_id)] == "STP co-treatment"))
})
