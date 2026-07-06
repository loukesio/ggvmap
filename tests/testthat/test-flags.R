test_that("country_to_iso resolves English and German names", {
  expect_equal(country_to_iso("China"), "cn")
  expect_equal(country_to_iso("Deutschland"), "de")
  expect_equal(country_to_iso("United Kingdom"), "gb")
  expect_equal(country_to_iso("Großbritannien"), "gb")
  expect_equal(country_to_iso(c("Norway", "Norwegen")), c("no", "no"))
})

test_that("country_to_iso passes through ISO codes and NAs unknowns", {
  expect_equal(country_to_iso("gr"), "gr")
  expect_true(is.na(country_to_iso("Freedonia")))
})

test_that("flag_url builds flagcdn URLs and respects NA", {
  expect_equal(flag_url("cn"), "https://flagcdn.com/w160/cn.png")
  expect_equal(flag_url("de", width = 320), "https://flagcdn.com/w320/de.png")
  expect_true(is.na(flag_url(NA_character_)))
})
