#!/bin/bash

createdb chado;

psql chado <  /Chado/chado/schemas/1.4/default_schema.sql
