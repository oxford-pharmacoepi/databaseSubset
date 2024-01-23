library(CDMConnector)
library(DBI)
library(dplyr)
library(dbplyr)
library(tictoc)

# parameters 
number_individuals <- 100000
schema_to_subset <- "..."
new_schema <- "..."
person_identifier <- "..."
person_table <- "..."
TABLESPACE <- ""

# database connection
db <- dbConnect("...")

# read all tables
all_tables <- listTables(db, schema_to_subset)

# create a reference
reference <- lapply(setNames(all_tables, all_tables), function (name) {
  tbl(db, inSchema(schema_to_subset, name, dbms(db)))
})

# subset table person
subsetPerson <- reference[[person_table]] %>%
  mutate(rand = dbplyr::sql("random()")) %>%
  arrange(.data$rand) %>%
  head(number_individuals) %>%
  compute() %>%
  select(-"rand") %>%
  computeQuery(person_table, FALSE, new_schema, TRUE)

# subset rest of tables
for (table_name in all_tables[all_tables != person_table]) {
  cat(paste0("Subsetting ", table_name, ": "))
  tic()
  if (person_identifier %in% colnames(reference[[table_name]])) {
    reference[[table_name]] %>%
      inner_join(subsetPerson %>% select(all_of(person_identifier)), by = person_identifier) %>%
      computeQuery(table_name, FALSE, new_schema, TRUE) %>%
      invisible()
  } else {
    reference[[table_name]] %>%
      computeQuery(table_name, FALSE, new_schema, TRUE) %>%
      invisible()
  }
  toc()
}

#Updating TABLESPACE for database backup
for (table_name in all_tables) {
  cat(paste0("Updating TABLESPACE ", table_name, ": "))
  tic()
  sql_query <- paste("ALTER TABLE",new_schema,".",table_name, "SET TABLESPACE ", TABLESPACE)
  dbExecute(db, as.character(sql_query))
  invisible()
  toc()
}