#!/usr/bin/env perl

#
# A simple script to create the Chado database and tables.
#

use strict;

my $dbname = shift or exit;
my @list   = `psql -l`;
my %dbs;
my $ok = 0;
for my $line ( @list ) {
    ;
    if ( $line =~ m/^\s*Name\s*|\s*Owner\s*/ ) {
        $ok = 1;
        next;
    }
    elsif ( $ok ) {
        if ( $line =~ m/^\s*(\w+)\s*\|\s*\w+\s*/ ) {
            $dbs{ $1 } = 1;
        }
    }
}

if ( $dbs{ $dbname } ) {
    print "A database called '$dbname' already exists.\n";
    print "OK to drop database '$dbname'? [Y/n] ";
    chomp( my $answer = <STDIN> );
    unless ( $answer =~ m/^[Nn]/ ) {
        print "Dropping database '$dbname'\n";
        system( "dropdb $dbname" ) == 0 or die "Cannot drop database: $?";
    }
    else {
        print "Will not drop database '$dbname'.  Exiting.\n";
        exit(0);
    }
}

print "Creating new database called '$dbname'\n";
system( "createdb $dbname" ) == 0 or die "Cannot create database: $?";

print "Creating tables\n";
system( 
    "psql -f modules/complete.sql $dbname 2>&1 | grep -E 'ERROR|FATAL|No such file or directory'"
) == 0 or die "Problem creating tables: $?";

print "Database '$dbname' created\n";
exit(0);
