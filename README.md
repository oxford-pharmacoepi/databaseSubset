# Create a subset of an schema

This projects contains two codes to subset a database:

- `createSubset` is a **PostgreSQL** specific code to create a subset of a database. This is a **PostgreSQL** specific code, but general to any database (not *OMOP CDM* specific).
- `subsetCdm` is a **cdm** specific code used to subset a cdm object. This code works for any **dbms** but it has to contain *OMOP CDM* data.


## `createSubset` instructions

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

## `subsetCdm` instructions

This project can be used to subset a cdm based on a set of parameters:
- `number_individuals`: Number of individuals that will be included in the subset.
- `schema_to_subset`: Original schema from which the new subset will be created. This must contain at least `person` and `observation_period` tables so a minimal *OMOP CDM* reference can be created.
- `new_schema`: Schema where the subset will be created. This schema has to exist in the database.

Example how to populate the parameters:
```r
number_individuals <- 100000
schema_to_subset <- "public"
new_schema <- "public_100k"
```

## How to connect to a database using the *DBI* package

Example how to connect to a Postgress Database:
```r
library(DBI)
library(RPostgres)

con <- dbConnect(
  Postgres(),
  dbname = "...",
  port = "...",
  host = "...",
  user = "...",
  password = "..."
)
```
Examples to connect to other databases can be found [here](https://darwin-eu.github.io/CDMConnector/articles/a04_DBI_connection_examples.html).
