library(CDMConnector)
library(DBI)
library(dplyr, warn.conflicts = FALSE)
library(tictoc)

# parameters 
number_individuals <- 100000
schema_to_subset <- "..."
new_schema <- "..."

# database connection
con <- dbConnect("...")

# create cdm reference
cdm <- cdmFromCon(con = con, cdmSchema = schema_to_subset, writeSchema = new_schema, .softValidation = TRUE)

# subset table person
subsetPerson <- cdm$person |>
  collect() |>
  slice_sample(n = number_individuals)
cdm <- insertTable(cdm = cdm, name = "person", table = subsetPerson)
subsetPerson <- cdm$person |>
  select("person_id")

# subset rest of tables
for (table_name in names(cdm)) {
  tic()
  if ("person_id" %in% colnames(cdm[[table_name]])) {
    cat(paste0("\033[3mSubsetting \033[34m", table_name, "\033[0m\n"))
    cdm[[table_name]] |>
      inner_join(subsetPerson, by = "person_id") |>
      compute(name = table_name) |>
      invisible()
  } else {
    cat(paste0("\033[3mCopying \033[34m", table_name, "\033[0m\n"))
    cdm[[table_name]] |>
      compute(name = table_name) |>
      invisible()
  }
  toc()
}
