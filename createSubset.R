library(CDMConnector)
library(DBI)
library(dplyr)
library(dbplyr)
library(tictoc)
library(rlang)

# parameters 
number_individuals <- 100000
schema_to_subset <- "..."
new_schema <- "..."
person_identifier <- "..."
person_table <- "..."
TABLESPACE <- NULL # only for postgres

# database connection
con <- dbConnect("...")

# read all tables
all_tables <- listTables(con = con, schema = schema_to_subset)

# create a reference
ref <- all_tables |>
  set_names() |>
  purrr::map(\(x) {
    tbl(src = con, inSchema(schema = schema_to_subset, table = name, dbms = dbms(con)))
  })
class(ref) <- "cdm_reference"
attr(ref, "cdm_source") <- dbSource(con = con, writeSchema = new_schema)

# subset table person
subsetPerson <- ref[[person_table]] |>
  collect() |>
  slice_sample(n = number_individuals)
ref <- insertTable(cdm = ref, name = person_table, table = subsetPerson)
subsetPerson <- select(cdm[[person_table]], all_of(person_identifier))

# subset rest of tables
for (table_name in all_tables[all_tables != person_table]) {
  tic()
  if (person_identifier %in% colnames(ref[[table_name]])) {
    cat(paste0("Subsetting ", table_name, ": "))
    ref[[table_name]] |>
      inner_join(subsetPerson, by = person_identifier) |>
      compute(name = table_name) |>
      invisible()
  } else {
    cat(paste0("Copying ", table_name, ": "))
    ref[[table_name]] |>
      compute(name = table_name) |>
      invisible()
  }
  toc()
}

if (!is.null(TABLESPACE)) {
  #Updating TABLESPACE for database backup
  for (table_name in all_tables) {
    cat(paste0("Updating TABLESPACE ", table_name, ": "))
    tic()
    sql_query <- paste("ALTER TABLE",new_schema,".",table_name, "SET TABLESPACE ", TABLESPACE)
    dbExecute(db, as.character(sql_query))
    invisible()
    toc()
  }
}