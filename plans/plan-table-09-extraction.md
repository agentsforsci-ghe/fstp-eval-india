# Plan: extract Table 9 as a CSV, document it in a DOCX manuscript, and move the repo to the new layout

## Context

The CSE Phase II report gives the performance of all 47 FSTPs in Table 9 (PDF pages 34 and 35). The table is only available as a PDF, so the goal is a CSV of Table 9 made by a script that anyone can rerun, plus a Quarto document that renders to DOCX and explains how the CSV was made and checked.

The user's project conventions are:

- raw data in `data/raw_data/`
- derived data in `data/derived_data/`
- a codebook in `data/metadata/codebook.csv`
- manuscripts in `analysis/`
- file names in lowercase with dashes, and a two-digit prefix for scripts

The user chose to apply these conventions to the whole repo, including the v0.1.0 BOD work. Numbered scripts go in `analysis/`. Work happens on `dev`, which is in sync with `main` at `68bd3eb`. Nothing is committed unless the user asks.

## Target layout

```
data/
  raw_data/1689832445895.pdf          (git mv from data/)
  derived_data/bod-discharge.csv      (git mv from data/)
  derived_data/table-09-fstp.csv      (new, script output)
  metadata/codebook.csv               (new)
analysis/
  01-extract-table-09.R               (new)
  bod-compliance.qmd                  (git mv from index.qmd)
  table-09-extraction.qmd             (new)
  references.bib                      (git mv from references.bib)
  bod-compliance.html / .docx         (rendered)
  table-09-extraction.docx            (rendered)
_quarto.yml                           (rewritten)
_manuscript/                          (git rm, replaced by outputs in analysis/)
```

The PDF keeps its name, because `1689832445895.pdf` already fits the naming rule and raw data stays as received. `prompts/` and `.gitignore` stay as they are.

## Steps

### 1. Move the existing files with `git mv`, so their history is kept

- Move the PDF, `bod-discharge.csv`, `index.qmd` (renamed to `bod-compliance.qmd`) and `references.bib` as shown above.
- Remove `_manuscript/` with `git rm -r`. The old outputs are replaced by new renders in `analysis/`, and v0.1.0 keeps the old ones.

### 2. Change the root `_quarto.yml` to a default project

A manuscript project allows only one article, and the repo now has two documents.

```yaml
project:
  type: default
  render:
    - analysis/*.qmd

execute:
  echo: false
  warning: false
  message: false
```

Output formats move into each document's front matter, and the rendered files land next to the sources in `analysis/`.

### 3. Update `analysis/bod-compliance.qmd`, with no change to content or results

- Front matter:
  - `format: html` with `toc: true`, `number-sections: true` and `embed-resources: true`, so the HTML is a single file
  - `format: docx` with `number-sections: true` and `fig-dpi: 300`
  - `bibliography: references.bib`
- Read the data with `here::here("data", "derived_data", "bod-discharge.csv")`. The `.Rproj` file sits at the repo root, so `here` finds the right folder whichever directory the render runs from.
- Change the two path mentions in the prose: `data/1689832445895.pdf` becomes `data/raw_data/1689832445895.pdf`, and `data/bod-discharge.csv` becomes `data/derived_data/bod-discharge.csv`.

### 4. Create `analysis/01-extract-table-09.R`

- Stop with a clear message if `Sys.which("pdftotext")` is empty. The Homebrew `pdftotext` is installed and `pdftools` is not, so no new R package is needed.
- Read pages 34 to 35 of `here("data", "raw_data", "1689832445895.pdf")` with `system2("pdftotext", c("-layout", "-f", "34", "-l", "35", pdf, "-"))`.
- Give each row the technology of the most recent group header. The six fixed header strings are DEWATS, MBBR, geotube, Mizuchi, electrocoagulation-flotation and packaged STP.
- Match data rows with a regex for S No, plant name and numeric tokens, and record each token's character position.
- Assign tokens to columns by position. On each page, take the column centres from the rows that have all 7 numbers, then map every token to the nearest centre. The one empty cell in the table (Nalgonda's BOD removal) then becomes `NA` instead of shifting the values after it.
- Keep values and plant names exactly as printed, e.g., "Modinagar*" and "Kalibilod, Indore". The script makes no corrections.
- Stop with an error unless:
  - there are 47 rows
  - the group counts are 33/6/3/3/1/1
  - S No runs from 1 to n within each group
- Write `here("data", "derived_data", "table-09-fstp.csv")` with `readr::write_csv()` and empty cells for `NA`.
- Columns: `technology, sno, plant, cod_removal_pct, bod_removal_pct, tkn_removal_pct, ph, faecal_coliform_mpn_100ml, discharge_cod_mgl, discharge_bod_mgl`.

### 5. Create `data/metadata/codebook.csv` by hand

- Columns: `directory, file_name, variable_name, variable_type, unit, description`.
- One row per variable of both derived files, i.e., 10 variables for `table-09-fstp.csv` and 7 for `bod-discharge.csv`.

### 6. Create `analysis/table-09-extraction.qmd`

- Front matter: title "Table 9 of the CSE Phase II report as a CSV file", `format: docx` with `number-sections: true`, and `bibliography: references.bib`.
- It reads the Table 9 CSV, `bod-discharge.csv` and the codebook through `here()`. All numbers in the text come from inline R. There is no figure. If one is added later, it comes from an R chunk with `echo: false`.
- The prose follows the plain writing style with sentence case headings, no dashes and a blank line after every heading.
- Sections:
  - Introduction: what Table 9 is and why a CSV is useful.
  - Methods: the source pages, the extraction script and a data dictionary table built from the `codebook.csv` rows for `table-09-fstp.csv`. It then lists the checks:
    - row and group counts
    - value ranges: percentages from 0 to 100, pH from 0 to 14, no negative values
    - the codebook lists exactly the columns in the CSV
    - discharge BOD matches `bod_summary_mgl` in `bod-discharge.csv`. That file was typed by hand from the PDF and already checked against it, so this compares two independent routes. The two files are joined through a small lookup for names that differ, e.g., "Kalibilod, Indore" and "Kalibillod".
  - Results:
    - a table of rows per technology
    - the outcome of each check
    - known problems in the source table, with page references, all left uncorrected in the CSV:
      - Nalgonda has no BOD removal value, while Graph 5 shows 97.2%.
      - Amethi shows 1.2% COD and BOD removal, 168 mg/L COD and 48.3 mg/L BOD. Graph 4 and Annexure II give 107 and 30.1 mg/L.
      - Dhenkanal shows 30.6 mg/L BOD, while Annexure II gives 14.0 mg/L.
      - Table 9 doesn't explain the asterisk on Modinagar. Table 5 lists Modinagar as a hyper core (lamella) pilot plant.
  - Use notes for anyone reusing the CSV.
  - References, and an appendix with all 47 rows in a `::: {.landscape}` div, so that the 10 columns fit the DOCX page.

## Verification

1. Run `Rscript analysis/01-extract-table-09.R`. It finishes without error and the CSV has 47 rows and 10 columns. Nalgonda's `bod_removal_pct` is empty and Kamareddy's `discharge_cod_mgl` is 40.33.
2. Check every cell against the PDF text with a throwaway script in the scratchpad, not committed. For each CSV row, the non-empty values must appear in order in the matching `pdftotext -layout` line.
3. Run `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render` at the root. It writes `analysis/bod-compliance.html`, `analysis/bod-compliance.docx` and `analysis/table-09-extraction.docx` without errors or warnings.
4. Confirm the BOD document is unchanged. Convert the new `bod-compliance.docx` and the v0.1.0 DOCX (`git show v0.1.0:_manuscript/index.docx`) to plain text with the bundled pandoc and diff them. Only the two path mentions may differ.
5. Check the Table 9 DOCX. It contains every table and caption, all checks read "passed", and the reference is listed.
6. `git status` shows the four moves as renames, the removal of `_manuscript/`, and only the planned new files.
7. (Visual, user) Open `table-09-extraction.docx` and check that the landscape appendix table is readable.
