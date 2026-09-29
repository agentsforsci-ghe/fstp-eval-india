# Build the dataset `bod_compliance` from the extracted tables: the average
# discharge BOD of the 69 sampled plants from Tables 9 and 10
# (`fstp_performance`, `stp_performance`) and from the final outlet rows of
# Annexure II (`samples`). The technology labels follow the manuscript
# analysis/bod-compliance.qmd. The result must equal the hand-typed file
# data-raw/bod-discharge.csv, which was checked against the PDF.

source(here::here("data-raw", "00-helpers.R"))

for (name in c("plants", "fstp_performance", "stp_performance", "samples")) {
  load(here("data", paste0(name, ".rda")))
}

labels <- c(
  "DEWATS" = "DEWATS", "MBBR" = "MBBR", "Geotube" = "Geotube", "Mizuchi" = "Mizuchi",
  "Electrocoagulation-flotation" = "Electrocoagulation",
  "Packaged STP" = "Packaged STP with pyrolysis",
  "SBR" = "SBR", "UASB" = "UASB", "WSP" = "Waste stabilisation pond", "ASP" = "ASP"
)

summary_tables <- rbind(
  data.frame(fstp_performance[c("plant_id", "technology", "discharge_bod_mgl")], plant_type = "FSTP"),
  data.frame(stp_performance[c("plant_id", "technology", "discharge_bod_mgl")], plant_type = "STP co-treatment")
)

# The final outlet of each plant: "Outlet", or "Outlet After chlorination"
# where the outlet was sampled before and after chlorination (Bharwara)
outlets <- samples[samples$sample_type %in% c("Outlet", "Outlet After chlorination"), ]
if (anyDuplicated(outlets$plant_id)) stop("More than one final outlet for a plant")

bod_compliance <- data.frame(
  plant_id = summary_tables$plant_id,
  plant = plants$plant_name[match(summary_tables$plant_id, plants$plant_id)],
  state = plants$state[match(summary_tables$plant_id, plants$plant_id)],
  plant_type = summary_tables$plant_type,
  technology = unname(labels[summary_tables$technology]),
  bod_summary_mgl = summary_tables$discharge_bod_mgl,
  bod_annex_mgl = outlets$bod_mgl[match(summary_tables$plant_id, outlets$plant_id)]
)

expect_counts(nrow(bod_compliance), c(rows = 69), "The number of plants")
if (anyNA(bod_compliance)) stop("Missing values in bod_compliance")

# Compare with the hand-typed file
hand <- read_csv(here("data-raw", "bod-discharge.csv"), show_col_types = FALSE)
compare <- c("plant", "state", "plant_type", "technology", "bod_summary_mgl", "bod_annex_mgl")
if (!isTRUE(all.equal(as.data.frame(bod_compliance[compare]), as.data.frame(hand[compare]),
                      check.attributes = FALSE))) {
  stop("bod_compliance differs from the hand-typed data-raw/bod-discharge.csv")
}

export_dataset(bod_compliance, "bod_compliance")
