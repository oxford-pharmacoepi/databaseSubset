library(CDMConnector)
library(DBI)
library(dplyr)
library(dbplyr)
library(tictoc)

# parameters 
number_individuals <- 10000
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
all_tables <- listTables(db, schema_to_subset)

# create a reference
reference <- lapply(setNames(all_tables, all_tables), function (name) {
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
for (table_name in all_tables[all_tables != person_table]) {
  cat(paste0("Subsetting ", table_name, ": "))
  tic()
  if (person_identifier %in% colnames(reference[[table_name]])) {
    reference[[table_name]] %>%
      inner_join(subsetPerson, by = person_identifier) %>%
      computeQuery(table_name, FALSE, new_schema, TRUE) %>%
      invisible()
  } else {
    reference[[table_name]] %>%
      computeQuery(table_name, FALSE, new_schema, TRUE) %>%
      invisible()
  }
  toc()
}
