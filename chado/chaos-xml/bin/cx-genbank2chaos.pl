#!/usr/local/bin/perl -w
use strict;

use Bio::Chaos::ChaosGraph;
use Bio::SeqIO;
use Getopt::Long;

my ($fmt, $outfmt, $type, $writer) =
  qw(genbank chaos seq xml);
my @remove_types = ();
my $make_islands;
my $ascii;
my $nameby = 'feature_id';
my $error_threshold = 3;
my $dir = '.';
GetOptions("fmt|i=s"=>\$fmt,
           "writer|w=s"=>\$writer,
           "outfmt|o=s"=>\$outfmt,
           "type|t=s"=>\$type,
	   "islands"=>\$make_islands,
           "dir=s"=>\$dir,
	   "ascii|a"=>\$ascii,
	   "nameby|n=s"=>\$nameby,
	   "ethresh|e=s"=>\$error_threshold,
	   "remove_type=s@"=>\@remove_types,
	   "help|h"=>sub {
	       system("perldoc $0"); exit 0;
	   }
	  );

my $W = Data::Stag->getformathandler($writer);
$W->fh(\*STDOUT);
my $next_idn = 0;
mkdir($dir) unless $dir eq '.';
foreach my $file (@ARGV) {
    print STDERR "CONVERTING: $file\n";
    my $chaos;
    my $seqio =
      Bio::SeqIO->new(-file=> $file,
                      -format => $fmt);
    while (my $seq = $seqio->next_seq()) {
        printf STDERR "  Got bioperl Seq: %s [$file]\n", $seq->accession;
        my $C =
          Bio::Chaos::ChaosGraph->new;
        $C->next_idn($next_idn);
        my $unflattener = $C->unflattener;
        my $type_mapper = $C->type_mapper;
        $unflattener->error_threshold($error_threshold);
        $unflattener->remove_types(-seq=>$seq,
                                   -types=>\@remove_types)
          if @remove_types;
            
        printf STDERR "  Unflattening Seq: %s [$file]\n", $seq->accession;
        eval {
            $unflattener->unflatten_seq(-seq=>$seq,
                                        -use_magic=>1);
            $unflattener->report_problems(\*STDERR);
            $type_mapper->map_types_to_SO(-seq=>$seq);
        };
        if ($@) {
            print $@;
            printf STDERR "  Problems unflattening: %s BYE BYE [$file]\n", $seq->accession;
            exit 1;
        }
        my $outio = Bio::SeqIO->new( -format => 'chaos');
        $outio->write_seq($seq); # "writes" to a stag object
        $outio->end_of_data;

        # free memory
        %$seq = ();
        my $stag = $outio->handler->stag;
        $C->init_from_stag($stag);
	
        my $seqfs = $C->top_unlocalised_features;
        if (@$seqfs == 0) {
            $C->freak("no top level feature");
        }
        if (@$seqfs > 1) {
            $C->freak("top unlocalised feats!=1", @$seqfs);
        }
        my $seqf = shift @$seqfs;
        my $islands;
        if ($make_islands) {
            my $acc = $seqf->get_feature_id;
            my $path_prefix = "$dir/$acc";
            mkdir($path_prefix) unless -d $path_prefix;

            my $fs = $C->top_features;
            my @islands = ();
            foreach my $f (@$fs) {
                my $type = $f->get_type;
                $C->freak("no type", $f) unless $type;
                next unless $f->get_type eq 'gene';
                eval {
                    my $islandC = $C->make_island($f, 500);
                    #		print $islandC->asciitree;
                    my $W = Data::Stag->getformathandler($writer);
                    my $id = $f->get($nameby);
                    $id =~ tr/A-Za-z0-9_:;\.//cd; # make name safe
                    my $fn = sprintf("%s/%s.%s",
                                     $path_prefix,
                                     $id,
                                     $writer);
                    my $fh = FileHandle->new(">$fn") || die "can't open $fn";
                    $W->fh($fh);
                    my $res = $seqf->sget_residues;
                    $seqf->unset_residues;
                    $islandC->metadata(Data::Stag->new(focus_feature_id=>$f->get_feature_id));
                    $islandC->stag->events($W);
                    $seqf->set_residues($res);
                    $fh->close;
                };
                if ($@) {
                    print STDERR $@;
                    print STDERR "Problem with feature\n";
                    print STDERR $f->sxpr;
                }
            }
        } else {
            #	print $C->asciitree;
            if ($ascii) {
                print $C->asciitree;
            } else {
                $chaos = $C->stag;
                $chaos->sax($W);
            }
        }

        $next_idn = $C->next_idn;
    }
}
print STDERR "ALL DONE!\n";
exit 0;

__END__

=head1 NAME 

  cx-genbank2chaos.pl.pl

=head1 SYNOPSIS

  cx-genbank2chaos.pl.pl sample-data/AE003734.gbk > AE003734.chaos.xml

  cx-genbank2chaos.pl.pl -islands sample-data/AE003734.gbk

=head1 DESCRIPTION

Converts a genbank file to a chaos xml file (or a collection of chaos
xml files).

The genbank file is 'unflattened' in order to infer the relationships
between features

with the -islands option set, this loops through a list of
genbank-formatted files and builds a chaos file for every gene

by default it will store each gene in a directory named by the
sequence accession. it will name each file by the unique feature_id;
for example

  AE003644.2/
    gene:EMBLGenBankSwissProt:AE003644:128108:128179.xml
    gene:EMBLGenBankSwissProt:AE003644:128645:128716.xml
    gene:EMBLGenBankSwissProt:AE003644:128923:128994.xml

You can change the field used to name the file with -nameby; for
example, if you use the chado/chaos B<name> field like this:

  cx-genbank2chaos.pl.pl -islands -nameby name AE003734.gbk

You will get

  AE003644.3/
   noc.xml
   osp.xml
   BG:DS07721.3.xml

the default is the B<feature_id> field, which is usually more
unix-friendly (fly genes can have all kinds of weird characters in
their name); also using the 'name' field could run into uniqueness
issues.

=head1 HOW IT WORKS

=over

=item 1 - parse genbank to bioperl

uses L<Bio::SeqIO::genbank>

=item 2 - unflatten the flat list of bioperl SeqFeatures

uses L<Bio::Seqfeature::Tools::Unflattener>

=item 3 - turn bioperl objects into chaos datastructure

uses L<Bio::SeqIO::chaos>

=item 4 - remap every gene to an 'island' (virtual contig)

uses L<Bio::Chaos::ChaosGraph>

=item 5 - spit out each virtual contig chaos graph to a file

uses L<Bio::Chaos::ChaosGraph>

=back

=head1 REQUIREMENTS

You will need a very up to date bioperl, probably from cvs, with the
Unflattener modules added

=cut

