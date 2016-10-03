#!/usr/bin/env perl
use strict;
use warnings;
use URI::Escape;

=head1 NAME

gmod_extract_dbxref_from_gff.pl - Extracts Dbxrefs from GFF3 lines that have Target attributes

=head1 SYNOPSIS

  % gmod_extract_dbxref_from_gff.pl gff_file_name > output_file

=head1 DESCRIPTION

For GFF3 lines of the form:

 chr1 CDNA  cDNA_match  69388   69593  0  -  .  Dbxref=Sorghum_CDNA:Contig_448;Target=Contig_448 75 295 +   

that is, that have both Target and Dbxref attributes, this script
extracts the Dbxref value and prints out a list of the database
and accession parts of the Dbxref value.  This functionality depends 
on a standard format for the Dbxref value, one where the name of
the database preceeds the accession and are separated by a colon.

=head2 Rationale

Another script, gmod_make_gff_from_dbxref.pl, takes a list of databases
and accessions (like this script provides) and a directory of FASTA files
and builds a GFF3 file that corresponds to those targets.  The use for
these files is to load them into Chado before that compuational 
analysis results are loaded to ensure that the database has a complete
picture of the analysis performed.


=head1 COMMAND-LINE OPTIONS

None.

=head1 AUTHOR

Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2007

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

if ($ARGV[0] =~ /-h/) {
    system( 'pod2text', $0);
    exit -1;
}

my %dbxref;
while (<>) {
    chomp;
    if (/^-h/) {
        system( 'pod2text');
        exit -1;
    }
    my @la = split /\t/;
    last if ($la[0] eq '##FASTA');
    next unless (scalar @la == 9);
    next unless ($la[2] =~ /match/);
    next unless ($la[8] =~ /Dbxref/);
    next unless ($la[8] =~ /Target/);
   
    my @pairs = split /\;/, $la[8]; 

    my ($db,$acc,$target);
    for (@pairs) {
        my @tagvalue = split /\=/;
        if ($tagvalue[0] eq 'Dbxref') {
            ($db, $acc) = split /\:/, $tagvalue[1];
            $db  = uri_unescape($db);
            $acc = uri_unescape($acc);
        }
        elsif ($tagvalue[0] eq 'Target') {
            ($target) = split /\s/, $tagvalue[1];
            $target   = uri_unescape($target);
        }
    }

    if ($db && $acc && $target && $acc eq $target) {
        $dbxref{$db}{$acc} = 1;
    }
}

for my $db (keys %dbxref) {
    for my $acc (keys %{$dbxref{$db}}) {
        print "$db $acc\n";
    }
}
