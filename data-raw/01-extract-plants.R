# Extract Tables 1 to 8 (treatment technologies evaluated in each state,
# report pages 26 to 33) into the dataset `plants`. The cells hold text over
# several lines, so the words are placed by their coordinates on the page:
# each word goes to the column whose header starts at or left of the word.

source(here::here("data-raw", "00-helpers.R"))

table_states <- c("Telangana", "Tamil Nadu", "Odisha", "Rajasthan", "Uttar Pradesh",
                  "Madhya Pradesh", "Chhattisgarh", "Uttarakhand")

w <- read_words(26, 33)
w$y <- round(w$y0, 1)

# Drop running heads, page footers, page numbers and the Odisha footnote
line_key <- paste(w$page, w$y)
line_text <- tapply(w$text, line_key, paste, collapse = " ")
drop <- names(line_text)[grepl("EVALUATION OF FSTPS|report\\.indd|^\\d+$|^\\*\\*", line_text)]
w <- w[!line_key %in% drop, ]
w <- w[order(w$page, w$y, w$x0), ]

# Each word belongs to the table whose caption is above it, on the same page
# or on an earlier page
cap_idx <- which(w$text == "Table" & grepl("^[1-8]:$", c(w$text[-1], "")))
caps <- data.frame(
  page = w$page[cap_idx], y = w$y[cap_idx],
  table = as.integer(sub(":", "", w$text[cap_idx + 1]))
)
w$table <- NA_integer_
current <- NA_integer_
for (p in sort(unique(w$page))) {
  page_caps <- caps[caps$page == p, ]
  for (i in which(w$page == p)) {
    above <- page_caps[page_caps$y <= w$y[i], ]
    w$table[i] <- if (nrow(above) > 0) above$table[nrow(above)] else current
  }
  if (nrow(page_caps) > 0) current <- page_caps$table[nrow(page_caps)]
}
w <- w[!is.na(w$table) & !paste(w$page, w$y) %in% paste(caps$page, caps$y), ]

# Column start positions from the header row of each table on each page
header_columns <- function(seg) {
  header_y <- seg$y[seg$text == "Capacity"][1]
  header <- seg[abs(seg$y - header_y) <= 1, ]
  x <- function(pattern) {
    v <- header$x0[grepl(pattern, header$text)]
    if (length(v) > 0) min(v) else NA
  }
  cols <- c(
    sno = x("^S$"), plant = x("^(FSTP|STP)$"), capacity = x("^Capacity$"),
    capex = x("^Capex"), opex = x("^Opex"), technology = x("^Technology$"),
    description = x("^Description$"), post_treatment = x("^Post-")
  )
  sort(cols[!is.na(cols)])
}

rows <- list()
for (seg_key in unique(paste(w$page, w$table))) {
  seg <- w[paste(w$page, w$table) == seg_key, ]
  cols <- header_columns(seg)
  header_y <- seg$y[seg$text == "Capacity"][1]
  # A row starts with its S No, printed left of the location column
  starts <- seg[seg$x0 < cols["plant"] - 2 & grepl("^-?\\d+$", seg$text) & seg$y > header_y, ]
  words <- seg[seg$y >= min(starts$y) - 1, ]
  words$row <- findInterval(words$y + 1, starts$y)
  words$col <- names(cols)[pmax(findInterval(words$x0 + 2, cols), 1)]
  for (r in seq_len(nrow(starts))) {
    row_words <- words[words$row == r, ]
    cell <- function(col) {
      x <- row_words[row_words$col == col, ]
      if (nrow(x) == 0) return(NA_character_)
      x <- x[order(x$y, x$x0), ]
      join_lines(tapply(x$text, x$y, paste, collapse = " "))
    }
    rows[[length(rows) + 1]] <- data.frame(
      state = table_states[seg$table[1]],
      # Row 7 of Table 2 is printed as "-7"
      sno = as.integer(sub("^-", "", starts$text[r])),
      plant = cell("plant"), capacity = cell("capacity"), technology = cell("technology"),
      description = cell("description"), post_treatment = cell("post_treatment"),
      capex = cell("capex"), opex = cell("opex")
    )
  }
}
plants <- do.call(rbind, rows)

expect_counts(
  table(factor(plants$state, levels = table_states)),
  setNames(c(12, 9, 21, 3, 10, 4, 2, 12), table_states),
  "Plants per state"
)

# Plant IDs, joined on state and S No because Table 5 prints "Jhansi" twice
lookup <- plant_names()
idx <- match(paste(plants$state, plants$sno), paste(lookup$state, lookup$tables_1_8_sno))
if (anyNA(idx)) stop("No plant_id for some rows of Tables 1 to 8")
if (any(lookup$tables_1_8[idx] != plants$plant)) {
  stop("Printed names differ from plant-names.csv for: ",
       paste(plants$plant[lookup$tables_1_8[idx] != plants$plant], collapse = "; "))
}

number_before <- function(x, unit_pattern) {
  out <- rep(NA_real_, length(x))
  hit <- !is.na(x) & grepl(unit_pattern, x)
  out[hit] <- as.numeric(sub(paste0("^.*?([0-9.]+)\\s*", unit_pattern, ".*$"), "\\1", x[hit], perl = TRUE))
  out
}

plants <- data.frame(
  plant_id = lookup$plant_id[idx],
  plant_name = lookup$plant_name[idx],
  state = plants$state,
  plant_type = lookup$plant_type[idx],
  plants[c("sno", "plant", "capacity")],
  capacity_value = as.numeric(sub("^([0-9.]+).*$", "\\1", plants$capacity)),
  capacity_unit = sub("^[0-9.]+\\s*", "", plants$capacity),
  plants[c("technology", "description", "post_treatment", "capex", "opex")],
  capex_inr_crore = number_before(plants$capex, "Cr"),
  opex_inr_lakh = number_before(plants$opex, "[Ll]akh"),
  sampled = !grepl("\\*\\*", plants$plant)
)

export_dataset(plants, "plants")
