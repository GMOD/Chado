#!/bin/sh
cat modules/complete.sql | psql test 2>&1 | grep -E 'ERROR|FATAL';
true;
