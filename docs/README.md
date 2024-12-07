# Dataset Documentation

### Setup Database

Two notebooks are provided to setup the database. The first notebook `setup sqlite.ipynb` creates an SQLite database with the tables. The second notebook `setup rqlite.ipynb` creates a distributed database with the tables. The distributed database is created using rqlite, a lightweight, distributed relational database built on SQLite.

### UPC Lookup

A notebook [upc-lookup.ipynb](./upc-lookup.ipynb) is provided to lookup product information using a scanned UPC code using `upcitemdb.com`. 
The notebook uses the `upcitemdb` API to lookup product information.
