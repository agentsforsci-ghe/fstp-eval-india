# Extract Table 11 (faecal sludge collected at the discharge points of the
# plants, report pages 46 and 47) into the dataset `sludge_characteristics`.
# Values and plant names are kept exactly as printed. The printed mean and
# median rows are not part of the dataset. The tests compare them with the
# mean and median of the extracted values.

source(here::here("data-raw", "00-helpers.R"))

value_cols <- c(
  "ph", "ts_mgl", "cod_mgl", "bod_mgl", "faecal_coliform_mpn_100ml",
  "ts_cod_ratio", "cod_bod_ratio"
)

rows <- read_numeric_table(46, 47, "Table 11:", "^\\s*Median", value_cols)
summary_rows <- rows$name %in% c("Mean", "Median")
if (sum(summary_rows) != 2) stop("Table 11 should end with a Mean and a Median row")
table_11 <- data.frame(plant = rows$name, rows[value_cols])[!summary_rows, ]

expect_counts(nrow(table_11), c(rows = 45), "The number of rows")

sludge_characteristics <- add_plant_id(table_11, "tables_11_13")
export_dataset(sludge_characteristics, "sludge_characteristics")
