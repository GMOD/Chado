# -*-Perl-*- mode (to keep my emacs happy)
# $Id: 00parse_gb_to_chaos.t,v 1.3 2004-12-23 16:43:55 cmungall Exp $

use strict;
use vars qw($DEBUG);
use Test;

BEGIN {     
    plan tests => 6;
}

END {
    #unlink("locuslink-test.out.embl");
}

use Bio::Chaos::ChaosGraph;
use Bio::SeqIO;
use Getopt::Long;

my ($fmt, $outfmt, $type, $writer) =
  qw(genbank chaos seq xml);
my $make_islands;
my $ascii;
my $nameby = 'feature_id';
GetOptions("fmt|i=s"=>\$fmt,
           "writer|w=s"=>\$writer,
           "outfmt|o=s"=>\$outfmt,
           "type|t=s"=>\$type,
	   "islands"=>\$make_islands,
	   "ascii|a"=>\$ascii,
	   "nameby|n=s"=>\$nameby,
	  );

my $W = Data::Stag->getformathandler($writer);
$W->fh(\*STDOUT);
my @files = (Bio::Root::IO->catfile("t","data",
				    "AE003734_modmdg4.gb"));

foreach my $file (@files) {
    my $seqio =
      Bio::SeqIO->new(-file=> $file,
		      -format => $fmt);
    my $seq = $seqio->next_seq();
    process_seq($seq);
    ok (!$seqio->next_seq);
}
exit 0;

sub process_seq {
    my $seq = shift;
    my $chaos;
    my $C =
      Bio::Chaos::ChaosGraph->new;
    my $unflattener = $C->unflattener;
    # we expect some complaints due to dicistronics
    $unflattener->error_threshold(3);
    $unflattener->ignore_problems; 
    my $type_mapper = $C->type_mapper;
    $unflattener->unflatten_seq(-seq=>$seq,
                                -use_magic=>1);
    $type_mapper->map_types_to_SO(-seq=>$seq);
    #my $testoutio = Bio::SeqIO->new( -format => 'asciitree');
    #$testoutio->write_seq($seq);

    my $outio = Bio::SeqIO->new( -format => 'chaos');
    $outio->write_seq($seq);
    $outio->end_of_data;
        
    my $stag = $outio->handler->stag;
    $C->init_from_stag($stag);

    my $seqfs = $C->top_unlocalised_features;
    my $seqf = shift @$seqfs;
    ok ($seqf);
    ok (!@$seqfs);
    my $islands;
    my $acc = $seqf->get_feature_id;
    printf "container feature: %s\n", $acc;
    my $fs = $C->top_features;
    my @islands = ();

    # transform all features to islands

    my $test1;
    my $test2;
    my $failed;
    my $n_prots = 0;
    foreach my $f (@$fs) {
        my $type = $f->get_type;
        $C->freak("no type", $f) unless $type;
        next unless $f->get_type eq 'gene';
        my $islandC = $C->make_island($f, 500);
        #		print $islandC->asciitree;
        my $ps = $islandC->get_features_by_type('protein');
        if (!@$ps) {
            if ($f->get_name eq 'Hsromega') {
                $test1 = 1;
                print "Hsromega has no protein; this is ok as it is ncRNA\n";
            } else {
                printf "no proteins for %s!\n", $f->get_name;
                $failed = 1;
            }
            next;
        }
        $n_prots += @$ps;
        my $p = shift @$ps;
        my $srcfid = $p->sget("featureloc/srcfeature_id");
        if (!$srcfid) {
            print $p->sxpr;
            die "no srcfid";
        }
        my $srcf = $islandC->feature_idx->{$srcfid};
        if (!$srcf) {
            print $p->sxpr;
            die "no srcf for $srcfid";
        }
        my $seqfs = $C->top_unlocalised_features;
        if (@$seqfs != 1) {
            $C->freak("top unlocalised feats!=1", @$seqfs);
        }
        my $seqf = shift @$seqfs;

        my $nbeg = $p->sget("featureloc/nbeg");
        my $srcres = $srcf->sget_residues;

        # check for ATG
        my $res = $islandC->cutseq($srcres, $nbeg, $nbeg+3);
        printf "RES:%s ID:%s Pname:%s nbeg:$nbeg SEGSTR:%s SEGLEN:%d \n", $res, $p->get_feature_id, $p->get_name, $srcf->sget("featureloc/strand"), length($srcres);
        if ($res ne 'ATG') {
            $failed = 1;
        }
    }
    ok(!$failed);
    ok($test1);
    printf "n_proteins: %d\n", $n_prots;
    ok($n_prots,54);
}
