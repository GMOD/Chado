#!/usr/bin/perl
                                                                                
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;
                                                                                
                                                                                
$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file = "gmod_$file.pl";
                                                                                
open OUT,">$file" or die "Can't create $file: $!";
print OUT "$Config{startperl} -w\n";
                                                                                

print OUT <<'!NO!SUBS!';
use strict;
use Bio::SeqIO;
use Bio::SeqFeature::Tools::Unflattener;

my $FILE_IN = $ARGV[0];

my @common_SOFA_types = (
  'region',
  'gene',
  'mRNA',
  'exon',
  'CDS',
  'chromosome_variation',
  'computed_feature_by_similarity',
  'repeat_region',
  'STS',
  'rRNA',
  'tRNA',
  'RNA',
  'SNP'
);

my $unflattener = Bio::SeqFeature::Tools::Unflattener->new;

my $seqio = Bio::SeqIO->new(
    -file   => $FILE_IN,
    -format => 'GenBank'
);

open OUT, ">$FILE_IN.gff" or die "unable to open $FILE_IN.gff: $!\n";

my $idcount = 1;
while ( my $seq = $seqio->next_seq() ) {
    my $acc = $seq->accession;

    # get top level unflattended SeqFeatureI objects
    my @sfs = $unflattener->unflatten_seq(
        -seq       => $seq,
        -use_magic => 1
    );

    #my @top_sfs = $unflattener->get_SeqFeatures;
    my @skipped_lines;
    

    # print a GFF header
    my $date = localtime;
    my $sname = $seq->accession || $seq->display_name;
    my $end   = length $seq->seq;
    print OUT "##gff-version 3\n",
              "##date $date\n";

#              "##sequence-region ",join(' ', $sname, 1, $end),"\n";

    foreach my $sf (@sfs) {

        $sf->seq_id($acc);
        $sf->gff_format( Bio::Tools::GFF->new( -gff_version => 3 ) );

        if ( $sf->primary_tag eq 'source' ) {
            $sf->add_tag_value( 'ID', $acc );
            $sf->primary_tag('region');
            warn "Setting source type as 'region', which is a more generic\n";
            warn "feature type than chromosome.  You may want to change this.\n";
        }

        if ( $sf->primary_tag eq 'CONTIG' ) {
            warn "Skipping 'CONTIG' type\n";
            next;
        }

        if ( $sf->primary_tag eq 'misc_feature' ) {
            my $new_primary_tag;
            if ($sf->has_tag('note')) {
                my @values = $sf->get_tag_values('note');
                foreach my $value (@values) {
                    if ($value =~ /similar/) {
                        $new_primary_tag = 'computed_feature_by_similarity';
                    }
                } 
            }
            if ($new_primary_tag) {
                $sf->primary_tag($new_primary_tag);
                warn "Converting misc_feature to 'computed_feature_by_similarity'\n";
                warn "which will result in this gff line:\n";
                warn $sf->gff_string . "\n\n";
            } else {
                warn "skipping misc_feature line\n";
                push @skipped_lines, $sf->gff_string . "\n";
                next;
            }
        }

        if ( $sf->primary_tag =~ /misc.*rna/i ) {
            $sf->primary_tag('RNA');
        }

        if ( $sf->primary_tag eq 'gene' ) {
            my @gene_name = $sf->has_tag('gene') 
                  ? $sf->get_tag_values('gene')
                  : $sf->get_tag_values('locus_tag');                            ;
            $sf->add_tag_value( 'ID', $gene_name[0] ) ;
        }

        if ( $sf->primary_tag eq 'variation' and $sf->length == 1 ) {
            $sf->primary_tag('SNP');
        } elsif ($sf->primary_tag eq 'variation') {
            $sf->primary_tag('chromosome_variation');
        }

        validate_tag($sf);

        validate_ID($sf,$acc);

        print OUT $sf->gff_string . "\n";

        my $localgeneid = 1;
        foreach my $sf2 ( $sf->get_SeqFeatures ) {
            $sf2->seq_id($acc);
            $sf2->gff_format( Bio::Tools::GFF->new( -gff_version => 3 ) );

            if ( $sf->has_tag('ID') ) {
                $sf2->add_tag_value( 'Parent', $sf->get_tag_values('ID') );
            }

            if ( $sf2->primary_tag eq 'variation' and $sf2->length == 1 ) {
                $sf2->primary_tag('SNP');
            } elsif ($sf2->primary_tag eq 'variation') {
                $sf2->primary_tag('chromosome_variation');
            }

            if ( $sf2->primary_tag() =~ /misc.*rna/i ) {
                $sf2->primary_tag('RNA');
            }

            if ( $sf2->primary_tag eq 'misc_feature' ) {
                my $new_primary_tag;
                if ($sf2->has_tag('note')) {
                    my @values = $sf2->get_tag_values('note');
                    foreach my $value (@values) {
                        if ($value =~ /similar/) {
                            $new_primary_tag = 'computed_feature_by_similarity';
                        }
                    }
                }
                if ($new_primary_tag) {
                    $sf2->primary_tag($new_primary_tag);
                    warn "Converting misc_feature to 'computed_feature_by_similarity'\n";
                    warn "which will result in this gff line:\n";
                    warn $sf2->gff_string . "\n\n";
                } else {
                    warn "skipping misc_feature line\n";
                    push @skipped_lines, $sf2->gff_string . "\n";
                    next;
                }
            }


            unless ( $sf2->source_tag ) {
                $sf2->source_tag( $sf->source_tag );
            }

            my @subfeats = $sf2->get_SeqFeatures;
            if (@subfeats > 0) {
                unless ($sf2->has_tag('ID')) {
                    my ($parentID) = $sf->get_tag_values('ID');
                    $sf2->add_tag_value( 'ID', "$parentID\_"
                                              .$sf2->primary_tag
                                              ."_$localgeneid" );
                    $localgeneid++;
                } 
            }

            validate_tag($sf2);

            validate_ID($sf2,$acc);


            print OUT $sf2->gff_string . "\n";

            foreach my $sf3 ( @subfeats ) {
                $sf3->seq_id($acc);
                $sf3->gff_format( Bio::Tools::GFF->new( -gff_version => 3 ) );

                if ( $sf2->has_tag('ID') ) {
                    my ($parentID) = $sf2->get_tag_values('ID');
                    $sf3->add_tag_value( 'Parent', $parentID );
                }

                unless ( $sf3->source_tag ) {
                    $sf3->source_tag( $sf2->source_tag );
                }

                validate_tag($sf3);

                validate_ID($sf3,$acc);

                print OUT $sf3->gff_string . "\n";

            }
        }
    }

    my $entire_seq = $seq->seq;
    print OUT ">$acc\n$entire_seq\n" if $entire_seq;

    if (@skipped_lines) {
        warn '-' x 72 . "\n";
        warn "skipped lines:\n";
        foreach my $line (@skipped_lines) {
            warn $line;
        }
    }
}

close OUT;


sub validate_tag {
    my $sf  = shift;
    my $tag = $sf->primary_tag;
    if (! ( grep( /^\Q$tag\E$/, @common_SOFA_types))) {
        warn "$tag is an uncommon (and possibly illegal) feature type\n";
        warn "It will result in a gff line like this:\n";
        warn $sf->gff_string . "\n";
    }
}

sub validate_ID {
    my $sf = shift;
    my $acc= shift;
    unless ( ($sf->has_tag('ID') || $sf->has_tag('Parent')) ) {
        $sf->add_tag_value( 'ID', "GFF_internal_id_$acc-$idcount");
        $idcount++;
    }
}

!NO!SUBS!


close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;
 
