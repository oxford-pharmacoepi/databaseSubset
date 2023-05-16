library(CDMConnector)
library(DBI)
library(dplyr)
library(dbplyr)
library(tictoc)

# parameters 
server_dbi <- "..."
user <- "..."
password <- "..."
port <- "..."
host <- "..."
number_individuals <- 100000
schema_to_subset <- "..."
new_schema <- "..."
person_identifier <- "..."
person_table <- "..."

# database connection
db <- dbConnect(
  RPostgres::Postgres(),
  dbname = server_dbi,
  port = port,
  host = host,
  user = user,
  password = password
)

# read all tables
reference <- lapply(listTables(db, schema_to_subset), function (name) {
  tbl(db, inSchema(schema_to_subset, name, dbms(db)))
})

# subset table person
subsetPerson <- reference[[person_table]] %>%
  mutate(rand = dbplyr::sql("random()")) %>%
  window_order(.data$rand) %>%
  head(number_individuals) %>%
  select(-"rand") %>%
  computeQuery(person_table, FALSE, new_schema, TRUE)

# subset rest of tables
for (table_name in names(reference)) {
  print(paste0("Subsetting table: ", table_name))
  tic()
  if (person_identifier %in% colnames(reference[[table_name]])) {
    reference[[table_name]] %>%
      inner_join(subsetPerson, by = person_identifier) %>%
      computeQuery(table_name, FALSE, new_schema, TRUE) %>%
      invisible()
  } else {
    reference[[table_name]] %>%
      inner_join(subsetPerson, by = person_identifier) %>%
      computeQuery(table_name, FALSE, new_schema, TRUE) %>%
      invisible()
  }
  toc()
}
