#!/bin/bash
/etc/init.d/postgresql start
flyway baseline
/bin/bash
