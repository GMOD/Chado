#!/bin/sh
DBNAME=test;
#DBNAME=gadfly07;

dropdb $DBNAME;
createdb $DBNAME;
cat modules/complete.sql | psql $DBNAME 2>&1 | grep -E 'ERROR|FATAL|No such file or directory';
echo "database $DBNAME created";
true;
