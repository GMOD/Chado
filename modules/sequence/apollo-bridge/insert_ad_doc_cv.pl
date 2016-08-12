#!/usr/bin/env perl
use strict;
use warnings;

open ONTO, "ad_hoc_cv" or die "couldn't open ad_hoc_cv:$!\n"; 
open INSERTS, ">cv_inserts.sql" or die "couldn't open cv_inserts.sql: $!\n";

my $cv;

while (<ONTO>) {
    if (/^#/) {
        print INSERTS "\n";
    }
    elsif (/^\[(.+)\]/) {
        $cv = $1;
        print INSERTS "INSERT INTO cv (name) VALUES ('$cv');\n";
    } elsif (/^(.+)$/) {
        my $term=$1;
        if ($term =~ /(.+)\s+\[REL\]/) {
            my $cvterm = $1;
            print INSERTS "INSERT INTO dbxref (db_id,accession) VALUES ((select db_id from db where name='null'), '$cv:$cvterm');\n";
            print INSERTS "INSERT INTO cvterm (cv_id,name,dbxref_id,is_relationshiptype) VALUES ((select cv_id from cv where name='$cv'),'$cvterm',(select dbxref_id from dbxref where accession='$cv:$cvterm'),1);\n";
        } else {
            my $cvterm = $term;
            print INSERTS "INSERT INTO dbxref (db_id,accession) VALUES ((select db_id from db where name='null'), '$cv:$cvterm');\n";
            print INSERTS "INSERT INTO cvterm (cv_id,name,dbxref_id) VALUES ((select cv_id from cv where name='$cv'),'$cvterm',(select dbxref_id from dbxref where accession='$cv:$cvterm'));\n";
        }
    }
}
close ONTO;
close INSERTS;

