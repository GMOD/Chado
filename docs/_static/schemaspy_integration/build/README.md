# Generate Chado Documentation using SchemaSpy

This directory provides scripts and templates which can be used to develop customized and branded Chado Schema documentation. It is expected that this documentation will be generated in the parent directory of these scripts.

## Requirements
1. [SchemaSpy 6.0](https://github.com/schemaspy/schemaspy)
2. [Java 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html)
3. [Java 8 PostgreSQL Driver](https://jdbc.postgresql.org/download.html)
4. GraphViz
5. [Local Chado repo](https://github.com/GMOD/Chado)

## Usage
Simply run a single command passing in all the important information as parameters :-) 
**This command must be run from the base of the chado-docs repository!**

Syntax:
```
./build/build_docs.sh -d [database name] -u [pgsql user] -p [pgsql user password] -s [schemaspy jar path] -g [PostgreSQL Driver path] -c [Local Chado Repository path]
```

Example:
```
./build/build_docs.sh -d chadodb -u chadouser -p chadopass -s /home/ubuntu/workspace/schemaspy-6.0.0-rc2.jar -g /home/ubuntu/workspace/postgresql-42.1.4.jar -c /home/ubuntu/workspace/Chado
```

### Parameters
All of the parameters are required!
 - d: The name of the database to create.
 - u: The name of the database user to own the database. This user should already exist and be able to create databases.
 - p: The password for the specified database user.
 - s: The full path to the SchemaSpy JAR
 - g: The full path to the PostgreSQL driver for Java 8.
