# Extract Tables 12 and 13 (COD and BOD in faecal sludge, leachate inlet and
# treated outlet, and the per cent removal in the two stages of treatment,
# report pages 48 to 51) into the dataset `removal_stages`, with one row per
# plant and parameter. Values and plant names are kept exactly as printed.
# The printed mean rows are not part of the dataset.

source(here::here("data-raw", "00-helpers.R"))

value_cols <- c(
  "fs_mgl", "inlet_mgl", "outlet_mgl", "fs_to_inlet_removal_pct",
  "fs_to_outlet_removal_pct", "inlet_to_outlet_removal_pct"
)

read_stage_table <- function(first, last, start, end, parameter) {
  rows <- read_numeric_table(first, last, start, end, value_cols)
  rows <- rows[!rows$name %in% c("Mean", "Mean value"), ]
  expect_counts(nrow(rows), c(rows = 45), paste("The number of rows for", parameter))
  data.frame(plant = rows$name, parameter = parameter, rows[value_cols])
}

removal_stages <- rbind(
  read_stage_table(48, 49, "Table 12:", "^\\s*Mean\\s", "COD"),
  read_stage_table(50, 51, "Table 13:", "^\\s*Mean value", "BOD")
)

removal_stages <- add_plant_id(removal_stages, "tables_11_13")
export_dataset(removal_stages, "removal_stages")
