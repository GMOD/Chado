#!/bin/sh
DBHOST=$1
DBPORT=$2
DBNAME=$3;

dropdb -h $DBHOST -p $DBPORT $DBNAME;
createdb -h $DBHOST -p $DBPORT $DBNAME;
cat modules/complete.sql | psql -h $DBHOST -p $DBPORT $DBNAME 2>&1 | grep -E 'ERROR|FATAL|No such file or directory';
echo "database $DBNAME created on $DBHOST:$DBPORT";
true;
