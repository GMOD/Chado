#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;

my ($INFILE, $OUTFILE);

GetOptions(
    'infile=s'     => \$INFILE,
    'outfile=s'    => \$OUTFILE,
  ) or ( system( 'pod2text', $0 ), exit -1 );

die "You must supply an input file name via --infile\n" unless $INFILE;

$OUTFILE  ||='sorted.gff';

open OUT, ">", $OUTFILE or die "couldn't open $OUTFILE for writing:$!\n";
open IN,  "<", $INFILE  or die "couldn't open $INFILE for reading:$!\n";

my %parent_hash;
my %child_hash;  # has ID (of parent) as key
                 # and anon array of GFF3 lines as value
while (<IN>) {
    my $line = $_;
    my @la   = split "\t", $line;
    if (@la != 9) { #not a GFF line, so let it though unmolested
        print OUT $line;
    }
    else {
        if ($la[8] =~ /Parent=([^;]+)/ ) {
            my $id = $1;
            if ($parent_hash{$id}) {
                print OUT $line;
            }
            else {
                push @{ $child_hash{$id} }, $line;
            }
        }
        elsif ($la[8] =~ /ID=([^;]+)/ ) {
            my $id = $1;
            if ($parent_hash{$id}) {
#                die "This ID: $1 has appeared twice in this GFF file\n";
# can't die here; CDS features can share IDs
# (though the chado bulk loader doesn't support that yet).
            }
            else {
                print OUT $line;
  
                for my $c_line ( @{ $child_hash{$id} } ){
                    print OUT $c_line;
                }
                $child_hash{$id} = 1;
            }
            $parent_hash{$id} = 1;
        }
        else {
            print OUT $line;
        }
    }
}

for my $key (keys %child_hash) {
    if ($child_hash{$key} != 1 ) {
        print "Unresolved child relationship for this line:\n";
        for my $line (@{ $child_hash{$key} }) {
            print "$line\n";
        }
    }
}

close OUT;
close IN;

=pod

=head1 NAME

gmod_sort_gff3.pl - Sorts a GFF3 file to put lines with Parent tags after their parent.

=head1 SYNOPSIS

  % gmod_sort_gff3.pl --infile <gff file name> 

=head1 COMMAND-LINE OPTIONS

  --infile		Name of the input gff3 file (required)
  --outfile		Name of the output gff3 file
                           (default: sorted.gff)

=head1 DESCRIPTION

This is a very simple (and only lightly tested) script for sorting
gff3 files so that all lines that have Parent tags come after the
line that contains the parent ID tag.  Files thusly sorted are
required for the GMOD chado bulk loader, L<gmod_bulk_load_gff3.pl>.

=head1 AUTHORS

Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2006

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
