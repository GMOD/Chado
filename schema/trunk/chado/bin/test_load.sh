#!/bin/sh
DBHOST=$1
DBNAME=$2;

dropdb -h $DBHOST $DBNAME;
createdb -h $DBHOST $DBNAME;
cat modules/complete.sql | psql -h $DBHOST $DBNAME 2>&1 | grep -E 'ERROR|FATAL|No such file or directory';
echo "database $DBNAME created on $DBHOST";
true;
