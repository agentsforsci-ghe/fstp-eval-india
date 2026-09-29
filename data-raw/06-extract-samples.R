# Extract Annexure II, Tables 1 to 7 (physico-chemical and biological
# parameters of all samples, report pages 171 to 177) into the dataset
# `samples`, with one row per plant and sample type. Values, plant names and
# sample types are kept exactly as printed. Names and sample types that run
# over several lines are joined. Empty cells, "NA" and "_" become NA.

source(here::here("data-raw", "00-helpers.R"))

value_cols <- c(
  "ph", "ts_mgl", "tds_mgl", "tss_mgl", "cod_mgl", "bod_mgl", "tkn_mgl",
  "ammoniacal_nitrogen_mgl", "total_phosphate_mgl", "faecal_coliform_mpn_100ml"
)

lines <- read_layout(171, 177)
lines <- lines[grep("Annexure II", lines$line)[1]:nrow(lines), ]

# A new sample row starts on a line with values, or on a line whose sample
# type is faecal sludge (FS), which in some plants has no values. Other lines
# continue the plant name or the sample type of the row above. A new plant
# starts with its first sample: FS, or the inlet after the outlet of the
# plant before.
is_fs <- function(type) grepl("^FS($|\\s|\\()", type)

rows <- list()
current <- NULL
annex_table <- NA_integer_
units <- NA_character_
boundary <- NA_integer_
previous_type <- NULL
for (i in seq_len(nrow(lines))) {
  line <- lines$line[i]
  trimmed <- trimws(line)
  if (!nzchar(trimmed) || grepl("^\\d+$", trimmed)) next
  if (grepl("report\\.indd|EVALUATION OF FSTPS|Annexure II|Consolidated physico", line)) next
  caption <- regmatches(trimmed, regexec("^Table (\\d+):", trimmed))[[1]]
  if (length(caption) > 0) {
    annex_table <- as.integer(caption[2])
    previous_type <- NULL
    next
  }
  # Header rows: the sample type column starts under "Sample"
  if (grepl("^Locations", trimmed)) {
    boundary <- regexpr("Sample", line)[1]
    next
  }
  if (grepl("\\((ppm|mg/L)\\)", line)) {
    units <- sub(".*\\((ppm|mg/L)\\).*", "\\1", line)
    next
  }
  if (grepl("^(type|Nitrogen|ml\\))", trimmed) || trimmed %in% c("from Uttarakhand", "Pradesh", "Pradesh and Chhattisgarh")) next

  tokens <- value_tokens(line, from = boundary)
  text <- substr(line, 1, if (nrow(tokens) > 0) tokens$start[1] - 1 else nchar(line))
  plant_text <- trimws(substr(text, 1, boundary - 1))
  type_text <- trimws(substr(text, boundary, nchar(text)))

  if (nrow(tokens) > 0 || is_fs(type_text)) {
    new_plant <- nzchar(plant_text) &&
      (is_fs(type_text) || is.null(previous_type) || grepl("^Outlet", previous_type))
    if (!is.null(current)) rows[[length(rows) + 1]] <- current
    current <- list(
      page = lines$page[i], segment = paste(lines$page[i], annex_table),
      annex_table = annex_table, units = units, new_plant = new_plant,
      plant = if (new_plant) plant_text else current$plant,
      plant_part = if (!new_plant && nzchar(plant_text)) plant_text else NA_character_,
      sample_type = type_text, tokens = tokens
    )
    previous_type <- type_text
  } else {
    if (nzchar(plant_text)) current$plant_part <- join_lines(c(current$plant_part, plant_text))
    if (nzchar(type_text)) {
      current$sample_type <- join_lines(c(current$sample_type, type_text))
      previous_type <- current$sample_type
    }
  }
}
rows[[length(rows) + 1]] <- current

# The plant name is the text of its first row plus the parts printed on the
# lines below, e.g. "Ukkadam," and "Coimbatore"
plant_group <- cumsum(vapply(rows, `[[`, TRUE, "new_plant"))
plant_names_printed <- tapply(seq_along(rows), plant_group, function(idx) {
  parts <- c(rows[[idx[1]]]$plant, vapply(rows[idx], `[[`, "", "plant_part"))
  join_lines(parts[!is.na(parts)])
})

samples <- data.frame(
  plant = unname(plant_names_printed[as.character(plant_group)]),
  sample_type = vapply(rows, `[[`, "", "sample_type"),
  units_as_printed = vapply(rows, `[[`, "", "units"),
  place_values(rows, value_cols)
)
annex_tables <- vapply(rows, `[[`, 0L, "annex_table")

expect_counts(
  table(factor(annex_tables, levels = 1:7)),
  setNames(c(36, 27, 51, 9, 36, 14, 24), 1:7),
  "Sample rows per table of Annexure II"
)
expect_counts(length(unique(samples$plant)), c(plants = 69), "The number of plants")

samples <- add_plant_id(samples, "annexure_2")

# The state in each caption agrees with the state in plant-names.csv
caption_states <- c("Telangana", "Tamil Nadu", "Odisha", "Rajasthan", "Uttar Pradesh", NA, "Uttarakhand")
check <- !is.na(caption_states[annex_tables])
if (any(samples$state[check] != caption_states[annex_tables][check])) {
  stop("The state of some plants differs from the caption of their table")
}

export_dataset(samples, "samples")
