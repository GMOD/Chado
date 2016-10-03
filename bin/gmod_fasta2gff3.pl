#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use Bio::DB::Fasta;

my ($FASTA_DIR, $GFFFILENAME, $TYPE, $SOURCE, $ATTRIBUTES, $NOSEQUENCE);

GetOptions(
    'fasta_dir=s'    => \$FASTA_DIR,
    'gfffilename=s'  => \$GFFFILENAME,
    'type=s'         => \$TYPE,
    'source=s'       => \$SOURCE,
    'attributes=s'   => \$ATTRIBUTES,
    'nosequence'     => \$NOSEQUENCE,
  ) or ( system( 'pod2text', $0 ), exit -1 );

my $fastadir = $FASTA_DIR   || './fasta';
my $gfffile  = $GFFFILENAME || 'out.gff';
my $type     = $TYPE        || 'EST';
my $source   = $SOURCE      || '.';

-r $fastadir or die "fasta dir '$fastadir' not found or not readable\n";

open OUT, ">", $gfffile or die "couldn't open $gfffile for writing: $!\n";

my $stream = Bio::DB::Fasta->new($fastadir)->get_PrimarySeq_stream;

print OUT "##gff-version 3\n";
print OUT "#this file generated from $0\n";
while (my $seq = $stream->next_seq) {
    my $atts;
    if ($ATTRIBUTES) {
        $atts = "ID=".$seq->id.";Name=".$seq->id.";$ATTRIBUTES";
    }
    else {
        $atts = "ID=".$seq->id.";Name=".$seq->id;
    }
    print OUT join("\t",
                   $seq->id,
                   $source,
                   $type,
                   1,
                   $seq->length,
                   ".",".",".",
                   $atts 
                  ),"\n";
}

if (!$NOSEQUENCE) {
    print OUT "##FASTA\n";

    #reset the seq stream
    $stream = Bio::DB::Fasta->new($fastadir)->get_PrimarySeq_stream;   

    while (my $seq = $stream->next_seq) {
        print OUT ">".$seq->id."\n";
        print OUT $seq->seq . "\n"; 
    } 
}

close  OUT;

=pod

=head1 NAME

$O - Convert FASTA to simple GFF3

=head1 SYNOPSYS

  % $O [options]

=head1 COMMAND-LINE OPTIONS

  --fasta_dir		Directory contain fasta files
                           (default: ./fasta)
  --gfffilename		Name of GFF3 file to be created
                           (default: ./out.gff)
  --type                SO type to assign to each feature
                           (default: EST)
  --source		Text to appear in source column
                           (default: .)
  --attributes		Additional tag=value pairs to appear in column 9
  --nosequence		Suppress the ##FASTA section (ie, don't
			   print DNA sequences)

=head1 DESCRIPTION

This script simply takes a collection of fasta files and converts them
to simple GFF3 suitable for loading into chado.

=head1 AUTHORS

Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2006

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

