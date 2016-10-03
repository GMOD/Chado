#!/usr/bin/env perl
use strict;
use warnings;

use Bio::FeatureIO;
use Getopt::Long;
use FileHandle;
#use lib '/home/cain/cvs_stuff/schema/chado/lib';
#use lib '/home/scott/cvs_stuff/schema/chado/lib';
use Bio::GMOD::DB::Adapter;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

=head1 NAME

$0 - Prepares a GFF3 file for bulk loading into a chado database.

=head1 SYNOPSIS

  % gmod_gff_preprocessor [options] --gfffile <filename>

=head1 COMMAND-LINE OPTIONS

 --gfffile        The file containing GFF3 (optional, can read
                     from stdin)
 --outfile        The name kernel that will be used for naming result files
 --splitfile      Split the files into more managable chunks, providing
                     an argument to control splitting
 --onlysplit      Split the files and then quit (ie, don't sort)
 --nosplit        Don't split the files (ie, only sort)
 --hasrefseq      Set this if the file contains a reference sequence line
                     (Only needed if not splitting files)
 --dbprofile      Specify a gmod.conf profile name (otherwise use default)
 --inheritance_tiers How many levels of inheritance do you expect tis file
                     to have (default: 3)

=head1 DESCRIPTION


splitfile  -- Just setting this flag to 1 will cause the file to be split 
by reference sequence.  If you provide an optional argument, it will be
further split according to these rules:

 source=1     Splits files according to the value in the source column
 source=a,b,c Puts lines with sources that match (via regular expression)
                     'a', 'b', or 'c' in a separate file
 type=a,b,c   Puts lines with types that match 'a', 'b', or 'c' in a
                     separate file

For example, if you wanted all of your analysis results to go in a separate
file, you could indicate '--splitfile type=match', and all cDNA_match,
EST_match and cross_genome_match features would go into separate files
(separate by reference sequence).

inheritence_tiers -- The number of levels of inheritance this file has. 
For example, if the file has "central dogma" genes in it (gene/mRNA/
exon,polypeptide), then it has 3.  Up to 4 is supported but the higher
the number, the more slowly it performs.  If you don't know, 3 is a 
reasonable guess.

=head2 FASTA sequence

If the GFF3 file contains FASTA sequence at the end, the sequence
will be placed in a separate file with the extention '.fasta'.  This
fasta file can be loaded separately after the split and/or sorted
GFF3 files are loaded, using the command:

  gmod_bulk_load_gff3.pl -g <fasta file name>

=head1 AUTHOR

Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2006-2007

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my (@GFFFILE, $OUTFILE, $SPLITFILE,$ONLYSPLIT,$NOSPLIT,$HASREFSEQ,
    $DBPROFILE, $INHERITANCE_TIERS);

GetOptions(
    'gfffile=s'   => \@GFFFILE,
    'outfile=s'   => \$OUTFILE,
    'splitfile=s' => \$SPLITFILE,
    'onlysplit'   => \$ONLYSPLIT,
    'nosplit'     => \$NOSPLIT,
    'hasrefseq'   => \$HASREFSEQ,
    'dbprofile=s' => \$DBPROFILE,
    'inheritance_tiers=i' => \$INHERITANCE_TIERS,
) or ( system( 'pod2text', $0 ), exit -1 );

@GFFFILE = split(/,/,join(',',@GFFFILE));

$DBPROFILE ||='default';

$INHERITANCE_TIERS ||= 3;

my ($split_on_source, $split_on_type, $split_on_ref);
if ($SPLITFILE) {
    if ($SPLITFILE and $SPLITFILE !~ /=/ and $SPLITFILE == 1) {
        $split_on_ref = 1;
    } 
    else {
        my @splits = split /;/, $SPLITFILE;
        for (@splits) {
            my ($tag, $value) = split /=/;
            $value            =~ s/,/|/g;
            if ($tag eq 'source') {
                $split_on_source = $value;
            }
            elsif ($tag eq 'type') {
                $split_on_type   = $value;
            }
            else {
                die "unsupported splitfile tag: $tag\n";
            }
        }
    }
}


my %has_ref_seq;
my @gfffiles;
for my $GFFFILE (@GFFFILE) {
  $GFFFILE  ||='-';
  $OUTFILE  ||="$GFFFILE.out.gff3";
  my $FASTA = "$OUTFILE.fasta";

  if ($SPLITFILE && !$NOSPLIT) {

    open GFFIN, "<", $GFFFILE or die "couldn't open $GFFFILE for reading: $!";
    open FASTA, ">", $FASTA or die " couldn't open $FASTA for writing: $!";

    my $fasta_flag = 0;
    my %files;
    while ( <GFFIN> ) {
        if (/^##FASTA/) {
            $fasta_flag = 1;
            print FASTA;
            next;
        } elsif ($fasta_flag) {
            print FASTA;
            next;
        }
        next if /^#/;
        my @la = split /\t/;

        (warn "ignored gff line: $_" && next) if (scalar @la != 9);

        my $has_ref_seq;
        chomp $la[8];
        if ( $la[8] =~ /ID=([^;]+);*.*$/ ) {
            my $id = $1;
            if ( $id eq $la[0] ) {
                $has_ref_seq = $id;
            } 
        }

        if ( $split_on_source && $split_on_source eq 1 ) {
            my $source = $la[1];
            my $filename = "$la[0].$la[1].$OUTFILE";
            unless ( defined $files{ $filename } ) {
                $files{ $filename } = new FileHandle $filename, "w";
                push @gfffiles, $filename;
            }
            $files{ $filename }->print( $_ );

            push @{$has_ref_seq{ $filename }}, $has_ref_seq if $has_ref_seq;
        }
        elsif ( $split_on_source && $la[1] =~ /$split_on_source/) {
            my $filename = "$la[0].source.$OUTFILE";
            unless ( defined $files{ $filename } ) {
                $files{ $filename } = new FileHandle $filename, "w";
                push @gfffiles, $filename;
            }
            $files{ $filename }->print( $_ );

            push @{$has_ref_seq{ $filename }}, $has_ref_seq if $has_ref_seq;
        }
        elsif ( $split_on_type && $la[2] =~ /$split_on_type/) {
            my $filename = $la[0].'.type.'.$OUTFILE;
            unless ( defined $files{ $filename } ) {
                $files{ $filename } = new FileHandle $filename, "w";
                push @gfffiles, $filename;
            } 
            $files{ $filename }->print( $_ );
 
            push @{$has_ref_seq{ $filename }}, $has_ref_seq if $has_ref_seq;
        }
        else {
            my $filename = $la[0].'.'.$OUTFILE;
            unless ( defined $files{ $filename } ) {
                $files{ $filename } = new FileHandle $filename, "w";
                push @gfffiles, $filename;
            }
            $files{ $filename }->print( $_ );

            push @{$has_ref_seq{ $filename }}, $has_ref_seq if $has_ref_seq; 
        }
    } 

    for my $key (keys %files) {
        $files{$key}->close;
    }
  }
  else {
    push @gfffiles, $GFFFILE;
    push @{ $has_ref_seq{ $GFFFILE } }, $GFFFILE if $HASREFSEQ;
  }

}
exit(0) if $ONLYSPLIT;

my $gmod_conf = Bio::GMOD::Config->new();
my $db_conf   = Bio::GMOD::DB::Config->new($gmod_conf, $DBPROFILE);
my $db        = Bio::GMOD::DB::Adapter->new(
                    dbuser  => $db_conf->user,
                    dbpass  => $db_conf->password || '',
                    dbhost  => $db_conf->host,
                    dbport  => $db_conf->port,
                    dbname  => $db_conf->name,
                    notransact => 1, 
                    skipinit   => 1,
                );

$db->sorter_create_table;
for my $gfffile (@gfffiles) {
    $db->sorter_delete_from_table;

    my $outfile = $gfffile.'.sorted';
    my $fasta   = "$outfile.fasta";

    open IN, "<", $gfffile or die "couldn't open $gfffile for reading: $!\n";

    my $fasta_flag = 0;
    print STDERR "Sorting the contents of $gfffile ...\n";
    while( <IN> ) {
        if (/^##FASTA/) {
            $fasta_flag = 1;
            open FASTA, 
                 ">", $fasta or die "couldn't open $fasta for writing: $!\n";

            #print FASTA "##gff-version 3\n";
            #print FASTA;
            #print FASTA "\n";  #extra cr works around bug in Bio::FeatureIO::gff
            next;
        }
        elsif ($fasta_flag) {
            print FASTA;
            next;
        }
        my $line       = $_;
        my @line_array = split /\t/, $line;

        if ($line =~ /^#/ or scalar @line_array != 9) {
            next;
        }

        my $refseq = $line_array[0];

        my ($id, @parents,@derives_froms);
        if ( $line_array[8] =~ /ID=([^;]+);*.*$/ ) {
            $id = $1;
            chomp $id;
        }
        if ( $line_array[8] =~ /Parent=([^;]+);*.*$/ ) {
            @parents       = split /,/, $1;
        }
        if ( $line_array[8] =~ /Derives_from=([^;]+);*.*$/ ) {
            @derives_froms = split /,/, $1;
        }

        if (@parents > 0 || @derives_froms > 0) {
            for my $parent ( (@parents,@derives_froms) ) {
                chomp $parent;
                $db->sorter_insert_line($refseq, $id, $parent, $line);
            }
        }
        elsif ($id) {
            $db->sorter_insert_line($refseq, $id, undef, $line);
        }
        else {
            $db->sorter_insert_line($refseq, undef, undef, $line);
        }
    }
    close IN;
    close FASTA if $fasta_flag;

    print STDERR "Writing sorted contents to $outfile ...\n";
    open OUT,">", $outfile or die "couldn't open $outfile for writing: $!\n";

#to print:
#   -get ref seqs (refseq == id)
#   -get things with no parent

    print OUT "##gff-version 3\n";

    my @refseqs = $db->sorter_get_refseqs();
    for my $refseq (@refseqs) {
        print OUT $refseq;      #already has the line feed
    }

    my @no_parents = $db->sorter_get_no_parents();
    for my $no_parent (@no_parents) {
        print OUT $no_parent;
    }
    @no_parents = '';

    if ($INHERITANCE_TIERS >= 2) {
        my @second_tiers = $db->sorter_get_second_tier();
        for my $second_tier (@second_tiers) {
            print OUT $second_tier;
        }
    }

    if ($INHERITANCE_TIERS >= 3) {
        my @third_tiers = $db->sorter_get_third_tier();
        for my $third_tier (@third_tiers) {
            print OUT $third_tier;
        }
    }

#yes, four tiers can happen, like transposible_element->te_gene->mRNA->exon
    if ($INHERITANCE_TIERS >= 4) {
        my @forth_tiers = $db->sorter_get_fourth_tier();
        for my $fourth_tier (@forth_tiers) {
            print OUT $fourth_tier;
        }
    }

    close OUT;

}


