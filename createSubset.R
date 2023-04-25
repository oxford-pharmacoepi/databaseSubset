library(CDMConnector)
library(DBI)
library(log4r)
library(dplyr)
library(dbplyr)
library(here)
library(IncidencePrevalence)
library(readr)
library(tidyr)

number_individuals <- 100000

server_dbi <- "..."
user <- "..."
password <- "..."
port <- "..."
host <- "..."
dbms <- "..."
db <- dbConnect(
  RPostgres::Postgres(),
  dbname = server_dbi,
  port = port,
  host = host,
  user = user,
  password = password
)

# The name of the schema that contains the OMOP CDM with patient-level data
cdm_database_schema <- "public"

# The name of the schema where results tables will be created 
results_database_schema <- "public_100k"

# minimum counts that can be displayed according to data governance
minimum_counts <- 5

# create cdm reference ----
cdm <- CDMConnector::cdm_from_con(
  con = db,
  cdm_schema = cdm_database_schema,
  cdm_tables = tbl_group("all"),
  write_schema = results_database_schema,
  cdm_name = db_name
)

subsetPerson <- cdm$person %>%
  dplyr::select("person_id") %>%
  dplyr::mutate(rand = dbplyr::sql("random()")) %>%
  dplyr::arrange(.data$rand) %>%
  compute()

subsetPerson <- subsetPerson %>%
  head(number_individuals) %>%
  compute()

subsetPerson <- subsetPerson %>%
  dplyr::arrange() %>% 
  dplyr::select("person_id") %>%
  compute()

for (nam in names(cdm)) {
  print(nam)
  tictoc::tic()
  if ("person_id" %in% colnames(cdm[[nam]])) {
    xx <- cdm[[nam]] %>%
      dplyr::inner_join(subsetPerson, by = "person_id") %>%
      computeQuery(nam, FALSE, "public_100k", TRUE)
  } else {
    xx <- cdm[[nam]] %>%
      computeQuery(nam, FALSE, "public_100k", TRUE)
  }
  tictoc::toc()
}

cdm <- CDMConnector::cdm_from_con(
  con = db,
  cdm_schema = "public_100k",
  write_schema = "results",
  cdm_name = db_name
)
