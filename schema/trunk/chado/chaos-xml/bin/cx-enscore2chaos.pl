#!/usr/local/bin/perl -w
use strict;

use Bio::Chaos::ChaosGraph;
use Bio::Chaos::FeatureUtil qw(:all);
use DBIx::DBStag;
use Getopt::Long;
use Datastore::MD5;

my ($fmt, $outfmt, $type, $writer) =
  qw(genbank chaos seq xml);
my $make_islands;
my $ascii;
my $nameby = 'feature_id';
my $dbname;
GetOptions("fmt|i=s"=>\$fmt,
           "outfmt|o=s"=>\$outfmt,
	   "dbname|d=s"=>\$dbname,
	   "help|h"=>sub {
	       system("perldoc $0"); exit 0;
	   }
	  );

my $dstore = Datastore::MD5->new(root=>'.', depth=>1);
my $dbh = DBIx::DBStag->connect($dbname) || die $dbname;

my @gnames = @ARGV;
if (!@gnames) {
    @gnames = @{$dbh->selectcol_arrayref(q[SELECT DISTINCT stable_id FROM gene NATURAL JOIN gene_stable_id])}; 
}
my $gtemplate =
  $dbh->find_template("enscore-genemodel");
my $ctemplate =
  $dbh->find_template("enscore-contigdna");

foreach my $gn (@gnames) {
#    print STDERR "GENE: $gn\n";
    my $gset =
      $dbh->selectall_stag(-template=>$gtemplate,
			   -bind=>{stable_id=>$gn});
    my $g = $gset->sget_gene;
    if (!$g) {
	print STDERR "No such gene as $gn\n";
	next;
    }
    my @contig_ids =
      $g->find("exon/contig_id");
    my %u = map {$_=>1} @contig_ids;
    @contig_ids = keys %u;
    my %contigh =
      map {
	  my $id = $_;
	  my $ctgset = 
	    $dbh->selectall_stag(-template=>$ctemplate,
				 -bind=>{contig_id=>$id});
	  ($id => $ctgset->sget_contig)
      } @contig_ids;
    my @g_exons = $g->find_exon;
    my @transcripts = $g->get_transcript;
    my @F = ();
    my %chromh = ();
    push(@F,
	 map {
	     my $cfid = $_->sget_contig_id."-ct";
	     my $assembly = $_->sget_assembly;
	     my ($min, $max, $strand) =
	       $assembly->getl(qw(contig_start contig_end contig_ori));
	     my $chrom = $assembly->sget_chromosome;
	     $chromh{$assembly->sget_chromosome_id} = $chrom;
	     my ($nb, $ne) = bcmm2ibv($min, $max, $strand);
	     N(feature=>[feature_id=>$cfid,
			 uniquename=>$_->sget_name,
			 name=>$_->sget_name,
			 type=>'contig',
			 featureloc=>[
				      nbeg=>$nb,
				      nend=>$ne,
				      strand=>$strand,
				      srcfeature_id=>$assembly->sget_chromosome_id . '-chr',
				     ],
			 residues=>$_->sget("dna/sequence"),
			]);
	 } values %contigh);
    unshift(@F,
	 map {
	     N(feature=>[feature_id=>$_->sget_chromosome_id . '-chr',
			 uniquename=>$_->sget_name,
			 name=>$_->sget_name,
			 type=>'chromosome',
			 seqlen=>$_->sget_length,
			]);
	 } values %chromh);
    my $gfid = $g->sget_gene_id."-gn";
    my $gfacc = $g->sget("gene_stable_id/stable_id");
    my $gfn = $g->sget("xref/display_label") || $gfacc;
    
    my $gC = 
      N(feature=>[feature_id=>$gfid,
		  uniquename=>$gfacc,
		  name=>$gfn,
		  dbxrefstr=>"ensembl:$gfacc",
		  type=>'gene',
		  featureloc=>[],
		 ]);
    push(@F, $gC);
    my $gfloc = $gC->sget_featureloc;

    my @tC = ();
    foreach my $t (@transcripts) {
	my @exons = $t->get("exon_transcript/exon");
	my $tfid = $t->sget_transcript_id."-tr";
	my $tC =
	  N(feature=>[feature_id=>$tfid,
		      uniquename=>$tfid,
		      type=>'mRNA',
		      featureloc=>[],
		     ]);
	push(@F, $tC);
	my $tfloc = $tC->sget_featureloc;

	my $translation = $t->sget_translation;
	my $tnid = $translation->get_translation_id . "-tn";

	# protein feature - we set floc later
	my $tnC =
	  N(feature=>[
		      feature_id=>$tnid,
		      uniquename=>$tnid,
		      type=>'protein',
		      featureloc=>[
				  ],
		     ]);
	my $tnfloc = $tnC->sget_featureloc;
	my ($tnstart, $tnend) = $translation->getl(qw(seq_start seq_end));
	push(@F, $tnC);
	push(@F,
	     N(feature_relationship=>[subject_id=>$tnid,
				      object_id=>$tfid,
				      type=>'produced_by',
				     ]));
	
	my @exC = ();
	my $mrnaseq = '';
	my $cdsseq = '';
	my $in_cds = 0;
	foreach my $exon (@exons) {
	    my ($min, $max, $strand, $contig_id) = 
	      $exon->getl(qw(contig_start contig_end contig_strand contig_id));
	    my $ctgid = $exon->sget_contig_id."-ct";
	    my ($nb, $ne) = bcmm2ibv($min, $max, $strand);
	    my $contig = $contigh{$contig_id};
	    my $dna = $contig->sget("dna/sequence");
	    my $exonseq = cutseq($dna, $nb, $ne);
	    $mrnaseq .= $exonseq;

	    # cds
	    if ($exon->sget_exon_id eq
		$translation->sget_start_exon_id) {
		$in_cds = 1;
		# start of CDS
		my $tnrelpos = $translation->sget_seq_start -1;
		$cdsseq =
		  cutseq($exonseq, 
			 $tnrelpos,
			 length($exonseq),
			 1);
		$tnfloc->set_nbeg($nb + $tnrelpos * $strand);
		$tnfloc->set_srcfeature_id($ctgid);
		if ($exon->sget_exon_id eq
		    $translation->sget_end_exon_id) {

		    $tnfloc->set_nend($nb + 
				      $translation->sget_seq_end * $strand);
		}
	    }
	    elsif ($exon->sget_exon_id eq
		   $translation->sget_end_exon_id) {
		$in_cds = 0;
		# end of CDS
		my $tnrelpos = $translation->sget_seq_end;
		$cdsseq .=
		  cutseq($exonseq, 
			 0,
			 $tnrelpos,
			 1);
		$tnfloc->set_nend($nb + $tnrelpos * $strand);
		if ($ctgid ne $tnfloc->sget_srcfeature_id) {
		    $tnC->add_featureprop(N(featureprop=>[type=>"problem",
							  value=>"CDS range split across contigs; also on $ctgid"]));
		}
	    }
	    else {
		# continuation of CDS
		$cdsseq .= $exonseq if $in_cds;
	    }
	    

#	    if ($strand == 1) {
#		if ($exon->sget_exon_id eq
#		    $translation->sget_start_exon_id) {
#		    $in_cds = 1;
#		    $cdsseq =
#		      cutseq($exonseq, 
#			     $translation->sget_seq_start -1,
#			     length($exonseq),
#			     1);
#		}
#		elsif ($exon->sget_exon_id eq
#		    $translation->sget_end_exon_id) {
#		    $in_cds = 0;
#		    $cdsseq .=
#		      cutseq($exonseq, 
#			     0,
#			     $translation->sget_seq_end,
#			     1);
#		}
#		else {
#		    $cdsseq .= $exonseq if $in_cds;
#		}
#	    }
#	    else {
#		if ($exon->sget_exon_id eq
#		    $translation->sget_end_exon_id) {
#		    $in_cds = 1;
#		    $cdsseq =
#		      cutseq($exonseq, 
#			     length($exonseq) - $translation->sget_seq_end,
#			     length($exonseq),
#			     1);
#		}
#		elsif ($exon->sget_exon_id eq
#		    $translation->sget_start_exon_id) {
#		    $in_cds = 0;
#		    $cdsseq .=
#		      cutseq($exonseq, 
#			     0,
#			     length($exonseq) - ($translation->sget_seq_start-1),
#			     1);
#		}
#		else {
#		    $cdsseq .= $exonseq if $in_cds;
#		}
#	    }

	    my $fid = $exon->sget_exon_id."-ex";
	    my $f =
	      N(feature=>[
			  feature_id=>$fid,
			  uniquename=>$fid,
			  type=>'exon',
			  featureloc=>[
				       nbeg=>$nb,
				       nend=>$ne,
				       strand=>$strand,
				       srcfeature_id=>$ctgid,
				      ]
			  ]);
	    push(@exC, $f);
	    push(@F, $f);
	    push(@F, 
		 N(feature_relationship=>[subject_id=>$fid,
					  object_id=>$tfid,
					  type=>'part_of',
					 ]));
	}
	$tC->set_residues($mrnaseq);
	$tnC->set_residues(translate($cdsseq)) if $cdsseq;
	$tnC->add_featureprop(N(featureprop=>[type=>"cdsseq",
					      value=>$cdsseq])) if $cdsseq;
	# transcript loc determined by exons
	$tfloc->set_nbeg($exC[0]->sget("featureloc/nbeg"));
	$tfloc->set_nend($exC[-1]->sget("featureloc/nend"));
	$tfloc->set_strand($exC[0]->sget("featureloc/strand"));
	$tfloc->set_srcfeature_id($exC[0]->sget("featureloc/srcfeature_id"));
	push(@tC, $tC);

	push(@F, 
	     N(feature_relationship=>[subject_id=>$tfid,
				      object_id=>$gfid,
				      type=>'part_of',
				     ]));
    }
    $gfloc->set_nbeg($tC[0]->sget("featureloc/nbeg"));
    $gfloc->set_nend($tC[-1]->sget("featureloc/nend"));
    $gfloc->set_strand($tC[0]->sget("featureloc/strand"));
    $gfloc->set_srcfeature_id($tC[0]->sget("featureloc/srcfeature_id"));

#    print $_->sxpr foreach @F;
    my $C =
      Bio::Chaos::ChaosGraph->new;
    my $S = Data::Stag->new(chaos=>[@F]);
    $C->init_from_stag($S);
    $C->name_all_features;
    $S = $C->stag;
    my $md = $S->sget_metadata;
    
    if (@gnames < 2) {
	print $S->xml;
    }
    else {
	$dstore->mkdir($gfacc);
	my $ndir = $dstore->id_to_dir($gfacc);
	print "ndir=$ndir\n";
	open(F, ">$ndir/$gfacc.chaos.xml");
	print F $S->xml;
	close(F);
    }
    
}
$dbh->disconnect;
print STDERR "DONE!\n";

sub N {
    Data::Stag->unflatten(@_);
}
