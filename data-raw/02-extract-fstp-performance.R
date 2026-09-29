# Extract Table 9 (performance of the 47 FSTPs, report pages 34 and 35) into
# the dataset `fstp_performance`. Values and plant names are kept exactly as
# printed. The table is also written to data-raw/table-09-fstp.csv, which the
# document analysis/table-09-extraction.qmd reads.

source(here::here("data-raw", "00-helpers.R"))

value_cols <- c(
  "cod_removal_pct", "bod_removal_pct", "tkn_removal_pct", "ph",
  "faecal_coliform_mpn_100ml", "discharge_cod_mgl", "discharge_bod_mgl"
)

# Group header rows as printed in Table 9, and the short label used in the data
headers <- c(
  "Decentralized wastewater treatment system (DWWTs/DEWATS)" = "DEWATS",
  "Moving Bed Biofilm Reactor (MBBR)" = "MBBR",
  "Geotube Technology" = "Geotube",
  "Mizuchi treatment technology" = "Mizuchi",
  "Electrocoagulation-Flotation (ECF)" = "Electrocoagulation-flotation",
  "Packaged sewage treatment plant (P-STP)" = "Packaged STP"
)

rows <- read_numeric_table(34, 35, "Table 9:", "^\\s*pH\\s*$", value_cols,
                           header_labels = headers, sno = TRUE)
table_09 <- data.frame(technology = rows$group, sno = rows$sno, plant = rows$name,
                       rows[value_cols])

expect_counts(nrow(table_09), c(rows = 47), "The number of rows")
expect_counts(
  table(factor(table_09$technology, levels = headers)),
  setNames(c(33, 6, 3, 3, 1, 1), headers),
  "Rows per technology"
)
if (!all(tapply(table_09$sno, table_09$technology, function(x) identical(x, seq_along(x))))) {
  stop("S No should run from 1 to n within each technology")
}

write_csv(table_09, here("data-raw", "table-09-fstp.csv"), na = "")

fstp_performance <- add_plant_id(table_09, "table_9")
export_dataset(fstp_performance, "fstp_performance")
