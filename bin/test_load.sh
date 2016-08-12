#!/bin/sh
DBHOST=$1
DBPORT=$2
DBUSER=$3
DBNAME=$4;

dropdb -h $DBHOST -p $DBPORT -U $DBUSER $DBNAME;
createdb -h $DBHOST -p $DBPORT -U $DBUSER $DBNAME;
createlang -h $DBHOST -p $DBPORT -U $DBUSER plpgsql $DBNAME;
cat modules/complete.sql | psql -h $DBHOST -p $DBPORT -U $DBUSER $DBNAME 2>&1 | grep -E 'ERROR|FATAL|No such file or directory';
echo "database $DBNAME created on $DBHOST:$DBPORT";
true;
