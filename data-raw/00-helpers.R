# Shared functions for the extraction scripts in data-raw/. Each script
# sources this file. Values and names are kept exactly as printed in the
# report. Requires pdftotext (poppler), e.g. brew install poppler.

library(here)
library(readr)

pdf_file <- here("data-raw", "1689832445895.pdf")

check_pdftotext <- function() {
  if (Sys.which("pdftotext") == "") {
    stop("pdftotext not found. Install poppler, e.g. with `brew install poppler`.")
  }
}

# Text of PDF pages with the page layout kept. Returns one row per line with
# the PDF page number.
read_layout <- function(first, last) {
  check_pdftotext()
  pages <- lapply(first:last, function(p) {
    txt <- system2("pdftotext", c("-layout", "-f", p, "-l", p, shQuote(pdf_file), "-"), stdout = TRUE)
    data.frame(page = p, line = gsub("\f", "", txt, fixed = TRUE))
  })
  do.call(rbind, pages)
}

# Words of PDF pages with their coordinates (points from the top left).
read_words <- function(first, last) {
  check_pdftotext()
  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp))
  system2("pdftotext", c("-bbox", "-f", first, "-l", last, shQuote(pdf_file), shQuote(tmp)))
  doc <- xml2::xml_ns_strip(xml2::read_xml(tmp))
  pages <- xml2::xml_find_all(doc, ".//page")
  words <- lapply(seq_along(pages), function(i) {
    w <- xml2::xml_find_all(pages[[i]], ".//word")
    data.frame(
      page = first + i - 1,
      x0 = as.numeric(xml2::xml_attr(w, "xMin")),
      y0 = as.numeric(xml2::xml_attr(w, "yMin")),
      text = xml2::xml_text(w)
    )
  })
  do.call(rbind, words)
}

# Join text fragments from several lines of one cell. A fragment that ends
# with a hyphen is joined to the next one without a space.
join_lines <- function(fragments) {
  fragments <- trimws(fragments[!is.na(fragments)])
  fragments <- fragments[nzchar(fragments)]
  if (length(fragments) == 0) return(NA_character_)
  out <- fragments[1]
  for (f in fragments[-1]) {
    out <- if (grepl("-$", out)) paste0(out, f) else paste(out, f)
  }
  out
}

# Positions of value tokens (numbers, and "NA" or "_" for missing values)
# in a line of layout text. Returns start, centre and value of each token.
value_tokens <- function(line, from = 1) {
  pos <- gregexpr("(?<![^ ])(\\d+(\\.\\d+)?|NA|_)(?![^ ])", line, perl = TRUE)[[1]]
  if (pos[1] == -1) return(data.frame(start = integer(), centre = numeric(), value = numeric()))
  tokens <- regmatches(line, list(pos))[[1]]
  keep <- pos >= from
  data.frame(
    start = pos[keep],
    centre = (pos + attr(pos, "match.length") / 2)[keep],
    value = suppressWarnings(as.numeric(tokens[keep]))
  )
}

# Place the value tokens of each row into columns. The column centres are
# the medians of the token centres of the rows in the same segment (a page,
# or one table on a page) that have a value in every column. A missing cell
# therefore stays NA instead of shifting the values after it.
place_values <- function(rows, value_cols) {
  n <- length(value_cols)
  segment <- function(r) if (is.null(r$segment)) as.character(r$page) else r$segment
  full <- Filter(function(r) nrow(r$tokens) == n, rows)
  centres <- lapply(split(full, vapply(full, segment, "")), function(seg_rows) {
    apply(do.call(rbind, lapply(seg_rows, function(r) r$tokens$centre)), 2, median)
  })
  values <- lapply(rows, function(r) {
    out <- setNames(rep(NA_real_, n), value_cols)
    if (nrow(r$tokens) == 0) return(out)
    seg_centres <- centres[[segment(r)]]
    if (is.null(seg_centres)) stop("No complete row in segment ", segment(r), " to find the columns")
    col <- vapply(r$tokens$centre, function(x) which.min(abs(seg_centres - x)), 0L)
    if (anyDuplicated(col)) stop("Two values fall into the same column in segment ", segment(r))
    out[col] <- r$tokens$value
    out
  })
  as.data.frame(do.call(rbind, values))
}

# Rows of a numeric table: each line with a name followed by value tokens.
# Lines between `start` and `end` (regular expressions matching a line) are
# read. `header_labels` maps group header lines to a label; `skip` lists
# lines that are neither rows nor headers. Returns the name, the group
# label and the values placed into `value_cols`.
read_numeric_table <- function(first, last, start, end, value_cols,
                               header_labels = NULL, sno = FALSE, skip = NULL) {
  lines <- read_layout(first, last)
  from <- grep(start, lines$line)[1]
  to <- grep(end, lines$line)
  to <- to[to > from][1]
  lines <- lines[from:to, ]

  row_pattern <- if (sno) {
    "^\\s*(\\d+)\\s+(\\S.*?)\\s{2,}(\\d.*)$"
  } else {
    "^\\s*()(\\S.*?)\\s{2,}(\\d.*)$"
  }
  rows <- list()
  group <- NA_character_
  pending <- NULL
  for (i in seq_len(nrow(lines))) {
    line <- lines$line[i]
    trimmed <- trimws(line)
    if (trimmed %in% names(header_labels)) {
      group <- header_labels[[trimmed]]
      next
    }
    # Page footers and running heads are not part of the table
    if (grepl("report\\.indd|EVALUATION OF FSTPS", line)) next
    if (!is.null(skip) && any(vapply(skip, grepl, TRUE, x = trimmed))) next
    # In a few rows the values are printed one line above the name
    # (e.g. Khandela in Table 13). Keep such values until the name follows.
    # A line with a single number is a page number.
    if (!sno && grepl("^\\s*\\d[\\d.\\s]*$", line, perl = TRUE)) {
      tokens <- value_tokens(line)
      if (nrow(tokens) >= 2) pending <- list(page = lines$page[i], tokens = tokens)
      next
    }
    if (!is.null(pending) && nzchar(trimmed) && nrow(value_tokens(line)) == 0) {
      rows[[length(rows) + 1]] <- list(
        page = pending$page, group = group, sno = NA_integer_,
        name = trimmed, tokens = pending$tokens
      )
      pending <- NULL
      next
    }
    m <- regmatches(line, regexec(row_pattern, line, perl = TRUE))[[1]]
    if (length(m) == 0) next
    values_start <- nchar(line) - nchar(m[4]) + 1
    rows[[length(rows) + 1]] <- list(
      page = lines$page[i],
      group = group,
      sno = if (sno) as.integer(m[2]) else NA_integer_,
      name = m[3],
      tokens = value_tokens(line, from = values_start)
    )
  }
  values <- place_values(rows, value_cols)
  data.frame(
    group = vapply(rows, `[[`, "", "group"),
    sno = vapply(rows, `[[`, 0L, "sno"),
    name = vapply(rows, `[[`, "", "name"),
    values
  )
}

# Plant IDs: data-raw/plant-names.csv maps the name printed in each part of
# the report to one plant_id per plant.
plant_names <- function() {
  read_csv(here("data-raw", "plant-names.csv"), show_col_types = FALSE,
           col_types = cols(.default = col_character(), tables_1_8_sno = col_integer()))
}

# Add plant_id and state for the names printed in one part of the report.
# Stops if a printed name has no plant_id.
add_plant_id <- function(data, source_col, name_col = "plant") {
  lookup <- plant_names()
  lookup <- lookup[!is.na(lookup[[source_col]]), c("plant_id", "state", source_col)]
  idx <- match(data[[name_col]], lookup[[source_col]])
  if (anyNA(idx)) {
    stop("No plant_id for: ", paste(unique(data[[name_col]][is.na(idx)]), collapse = "; "))
  }
  cbind(lookup[idx, c("plant_id", "state")], data, row.names = NULL)
}

# Export a dataset as in the washr template: data/<name>.rda and
# inst/extdata/<name>.csv and .xlsx.
export_dataset <- function(data, name) {
  data <- tibble::as_tibble(data)
  assign(name, data)
  do.call(usethis::use_data, list(as.name(name), overwrite = TRUE))
  fs::dir_create(here("inst", "extdata"))
  write_csv(data, here("inst", "extdata", paste0(name, ".csv")), na = "")
  openxlsx::write.xlsx(data, here("inst", "extdata", paste0(name, ".xlsx")))
  message("Exported ", name, ": ", nrow(data), " rows, ", ncol(data), " columns")
  invisible(data)
}

# Stop with an error when counts differ from the printed table.
expect_counts <- function(observed, expected, what) {
  if (is.null(names(observed))) names(observed) <- names(expected)
  observed <- c(observed)[names(expected)]
  if (anyNA(observed) || any(observed != expected)) {
    stop(what, " differ from the printed table. Expected ",
         paste(names(expected), expected, sep = " = ", collapse = ", "),
         ". Found ", paste(names(expected), observed, sep = " = ", collapse = ", "))
  }
}
