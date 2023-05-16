# Create a subset of an schema

## Parameters
This project can be used to subset an schema based on a set of parameters:
- `number_individuals`: Number of individuals that will be included in the subset.
- `schema_to_subset`: Original schema from which the new subset will be created.
- `new_schema`: Schema where the subset will be created. This schema has to exist in the database.
- `person_identifier`: Variable that identify different persons.
- `person_table`: Name of the table that contains a row for each individual in the database. The initial subset will be done in this table.

Example how to populate the parameters:
```r
number_individuals <- 100000
schema_to_subset <- "public"
new_schema <- "public_100k"
person_identifier <- "person_id"
person_table <- "person"
```

## Connect to the database
Example how to connect to a Postgress Database in the Oxford environment:
```r
db <- dbConnect(
  RPostgres::Postgres(),
  dbname = "cdm_gold_202201",
  port = "5432",
  host = "163.1.64.2",
  user = "...",
  password = "..."
)
```

Examples to connect to other databases can be found [here](https://darwin-eu.github.io/CDMConnector/articles/a04_DBI_connection_examples.html).
