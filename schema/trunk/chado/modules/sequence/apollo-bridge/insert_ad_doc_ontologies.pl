#!/usr/bin/perl -w
use strict;

open ONTO, "ad_hoc_ontologies" or die "couldn't ope ad_hoc_ontologies:$!\n"; 
open INSERTS, ">ontology_inserts.sql" or die "couldn't open ontology_inserts.sql: $!\n";

my $cv;
my $cvterm;

while (<ONTO>) {
    if (/^#/) {
        print INSERTS "\n";
    }
    elsif (/\[(.+)\]/) {
        $cv = $1;
        print INSERTS "INSERT INTO cv (name) VALUES ('$cv');\n";
    } elsif (/^(.+)$/) {
        $cvterm=$1;
        print INSERTS "INSERT INTO dbxref (db_id,accession) VALUES ((select db_id from db where name='null'), '$cv:$cvterm');\n";
        print INSERTS "INSERT INTO cvterm (cv_id,name,dbxref_id) VALUES ((select cv_id from cv where name='$cv'),'$cvterm',(select dbxref_id from dbxref where accession='$cv:$cvterm'));\n";
    }
}
close ONTO;
close INSERTS;

