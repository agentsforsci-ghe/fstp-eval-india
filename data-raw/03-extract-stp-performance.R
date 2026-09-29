# Extract Table 10 (performance of the 22 STPs with co-treatment of faecal
# sludge, report page 40) into the dataset `stp_performance`. Values and plant
# names are kept exactly as printed. Table 10 has no S No column.

source(here::here("data-raw", "00-helpers.R"))

value_cols <- c(
  "cod_removal_pct", "bod_removal_pct", "tkn_removal_pct", "ph",
  "faecal_coliform_mpn_100ml", "discharge_cod_mgl", "discharge_bod_mgl"
)

# Group header rows as printed in Table 10, and the short label used in the data
headers <- c(
  "Sequential batch reactors (SBR)" = "SBR",
  "Moving Bed Biofilm Reactor (MBBR)" = "MBBR",
  "Up Flow - Anaerobic Sludge Blanket Reactor (UASB)" = "UASB",
  "Waste Stabilization Pond (WSP)" = "WSP",
  "Activated Sludge Process (ASP)" = "ASP"
)

rows <- read_numeric_table(40, 40, "Table 10:", "report\\.indd", value_cols,
                           header_labels = headers)
table_10 <- data.frame(technology = rows$group, plant = rows$name, rows[value_cols])

expect_counts(nrow(table_10), c(rows = 22), "The number of rows")
expect_counts(
  table(factor(table_10$technology, levels = headers)),
  setNames(c(11, 5, 3, 2, 1), headers),
  "Rows per technology"
)

stp_performance <- add_plant_id(table_10, "table_10")
export_dataset(stp_performance, "stp_performance")
