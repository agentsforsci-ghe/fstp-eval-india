# Extract Table 9 (performance of the 47 FSTPs) from the CSE Phase II report
# into data/derived_data/table-09-fstp.csv. Values and plant names are kept
# exactly as printed. Requires pdftotext (poppler), e.g. brew install poppler.

library(here)
library(readr)

pdf <- here("data", "raw_data", "1689832445895.pdf")
out <- here("data", "derived_data", "table-09-fstp.csv")

if (Sys.which("pdftotext") == "") {
  stop("pdftotext not found. Install poppler, e.g. with `brew install poppler`.")
}

# Table 9 is on PDF pages 34 and 35
txt <- system2("pdftotext", c("-layout", "-f", "34", "-l", "35", shQuote(pdf), "-"), stdout = TRUE)
pages <- cumsum(grepl("\f", txt, fixed = TRUE)) + 1
txt <- gsub("\f", "", txt, fixed = TRUE)

# Group header rows as printed in Table 9, and the short label used in the CSV
headers <- c(
  "Decentralized wastewater treatment system (DWWTs/DEWATS)" = "DEWATS",
  "Moving Bed Biofilm Reactor (MBBR)" = "MBBR",
  "Geotube Technology" = "Geotube",
  "Mizuchi treatment technology" = "Mizuchi",
  "Electrocoagulation-Flotation (ECF)" = "Electrocoagulation-flotation",
  "Packaged sewage treatment plant (P-STP)" = "Packaged STP"
)

value_cols <- c(
  "cod_removal_pct", "bod_removal_pct", "tkn_removal_pct", "ph",
  "faecal_coliform_mpn_100ml", "discharge_cod_mgl", "discharge_bod_mgl"
)

# Collect data rows: S No, plant name, and each number with its column position
rows <- list()
technology <- NA_character_
for (i in seq_along(txt)) {
  line <- txt[i]
  if (trimws(line) %in% names(headers)) {
    technology <- headers[[trimws(line)]]
    next
  }
  if (!is.na(technology) && grepl("^\\s*pH\\s*$", line)) break
  m <- regmatches(line, regexec("^\\s*(\\d+)\\s+(\\S.*?)\\s{2,}(\\d.*)$", line, perl = TRUE))[[1]]
  if (is.na(technology) || length(m) == 0) next

  values_start <- nchar(line) - nchar(m[4]) + 1
  pos <- gregexpr("\\d+(\\.\\d+)?", m[4])[[1]]
  tokens <- regmatches(m[4], list(pos))[[1]]
  rows[[length(rows) + 1]] <- list(
    page = pages[i],
    technology = technology,
    sno = as.integer(m[2]),
    plant = m[3],
    tokens = as.numeric(tokens),
    centres = values_start - 1 + pos + attr(pos, "match.length") / 2
  )
}

# Column centres per page, from the rows that have all seven values
centres <- lapply(split(rows, vapply(rows, `[[`, 0, "page")), function(page_rows) {
  full <- Filter(function(r) length(r$tokens) == length(value_cols), page_rows)
  apply(do.call(rbind, lapply(full, `[[`, "centres")), 2, median)
})

# Assign each number to the nearest column centre, so that an empty cell
# becomes NA instead of shifting the values after it
table_09 <- do.call(rbind, lapply(rows, function(r) {
  page_centres <- centres[[as.character(r$page)]]
  col <- vapply(r$centres, function(x) which.min(abs(page_centres - x)), 0L)
  if (anyDuplicated(col)) stop("Two values fall into the same column for ", r$plant)
  values <- rep(NA_real_, length(value_cols))
  values[col] <- r$tokens
  data.frame(
    technology = r$technology, sno = r$sno, plant = r$plant,
    as.list(setNames(values, value_cols))
  )
}))

# Checks against the structure of the printed table
expected_groups <- c(DEWATS = 33, MBBR = 6, Geotube = 3, Mizuchi = 3,
                     "Electrocoagulation-flotation" = 1, "Packaged STP" = 1)
group_counts <- table(factor(table_09$technology, levels = names(expected_groups)))
stopifnot(
  "Table 9 should have 47 rows" = nrow(table_09) == 47,
  "Rows per technology differ from the printed table" =
    all(group_counts == expected_groups),
  "S No should run from 1 to n within each technology" =
    all(tapply(table_09$sno, table_09$technology, function(x) identical(x, seq_along(x))))
)

write_csv(table_09, out, na = "")
message("Wrote ", nrow(table_09), " rows and ", ncol(table_09), " columns to ", out)
