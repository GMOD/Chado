#!/usr/bin/perl 

=head1 NAME

gmod_dump_seq.pl - Print sequences from ChadoDB

=head1 SYNOPSIS

Dump sequence file of Chado features, with feature props, synonyms, dbxrefs
xSelect by organism, by 'pub' = input file,  seq type, feat props 
Need for nascent daphnia wFleaBase to use sequence public IDs

Good for small seqs: cDNA, EST, microsats. Left out genome-sized methods. 
Only does fasta format now

=head1 EXAMPLE dump

  bin/gmod_dump_seq.pl -v -dbname=daphnia \
   -pub='%CGBvntr%' -out=daph-CGBvntr.fa  
    
  bin/gmod_dump_seq.pl -type=cDNA_clone 
   
  >WFcd0000100 len=567;type=cDNA_clone;synonym=P1-E62000FW40325,WFBid100;contact=JColbo
  urne;library=CGBvntr;date=Jan2004;taxon=D.pulicaria;clone=P1-E62000FW40325;strain=Mar
  ieLake,Oregon
  GCGGGAGNCCGGTATATTGCAGAGTGGCATTATGGCCGNGAAGCAGTNGT
  ATCAACGCANAGTGGCCATTATGGCCGGGAAGCAGTGGTATCAACGCACG
  AGCTGGCCACTTCATGGCCGGGGATCTNCCGCTTGCTCCTCGTTCTCGAG
  CTAAGGCCTCTCCTTGTGCGCGACTTGCATTTATCTGTAACATCCGTNCA
  GAAACTTCATCGAAATGGCTGATCAAACGCAGAGACGAATTGGCTTGTGT
  CTACGCTGCTCTCGTTCTTTTAGACAGATTATGTAGCCATCACGGATGAA
  AAGATCCAAACCGATCTTGAAAGCTGCCGATGTTCAGGTAGAACCATACT
  GGCCTGGTCTTGTTCGCTAAGGCTTAGGATGGTCTTAACCTTAAGAGCAT
  GATCACCAACGTCGGCTCAGAGAGCTTCGGTGCACGCCCCAGCAGCTGGA
  GCTGCTGCCGCAGCCCCTGCTGATGCCGCCCCAGCACGCCAAAGAGGAAA
  AGAAGGAGGAGAAGAAGAAGGAAGAGTCCGANAGAGGAGGATGATGACAT
  GGGCTAGGTCCAGACCG
    
=head1 EXAMPLE Chado database create/load 

  bin/gmod_init_db.pl -dbname daphnia \
     -org='waterflea,Daphnia pulex' \
     -org='waterflea,Daphnia magna' \
     -org='waterflea,Daphnia pulicaria' \
     -ontology=obo_rel,song

    -- create database daphnia  & loads modules/complete.sql
    -- load install/initialize.sql (other folder?)
    -- add three new organisms
    -- loads all ontologies in subfolders of data/ontologies/ 
         (e.g., go, obo_rel, song)
   
  bin/gmod_load_newseq.pl -v \
   -dbname=daphnia -org="D.pulex"  \
   -in=$b/daphnia/data/CGBvntr.fa  -format=fasta  \
   -type=cDNA_clone -idmake="WFcd"
   
    -- loads fasta sequence of SO type cDNA_clone
    -- generates public IDs for sequences (WFcd0000001..)


=head1 COMMAND-LINE OPTIONS

The following command line options are required.  Note that they
can be abbreviated to one letter.

  --organism <org name>      Common name of the organism
  --outfile   <seq file>     output sequence file [or STDOUT]
  --format   <seqio format>  sequence format: FastA, GenBank, EMBL, ...
  --type     <seq type>      sequence type, valid SO cvterm 
  --pub     <title>          publication title (OPTIONAL, e.g. input file name)
  --verbose                  talk about it
  
The following DBI database command line options are supported.  
  --name --host --port --username --password
They are optional; %ENV and conf/gmod.conf will also be consulted for them .
  
=head1 AUTHORS

  Don Gilbert, Feb 2004

=cut

use strict;
use warnings;

# use Argos::Config;   # loads config to ENV; or eval { "require Argos::Config;" };
use GMOD::Config; # simpler alternate, checks only conf/gmod.conf for ENV settings

use Bio::SeqIO;
# use Chado::LoadDBI; #< moved to  GMOD::Chado::SeqUtils
use GMOD::Chado::SeqUtils; # common methods for these seq tools
use Getopt::Long;


$| = 1;

our $DEBUG = 0 unless defined $DEBUG;

my $SEQ_FORMAT = 'fasta';
my $SEQ_TYPE   = undef;
my $ORGANISM   = undef;
my $OUTFILE    = undef;
my $verbose=0;
my $dochecksum = 0;
my $pubTitle= undef;

my $chadoseq= GMOD::Chado::SeqUtils->new;

my %dbvals= $chadoseq->getDatabaseOpenParams();

my $help;
my $ok= GetOptions(
  'organism:s' => \$ORGANISM,
  'outfile:s'  => \$OUTFILE,
  'format:s'    => \$SEQ_FORMAT,
  'type:s'      => \$SEQ_TYPE,
  'pub:s'     => \$pubTitle,
  'checksum!' => \$dochecksum,
  'verbose!'  => \$verbose,
  'help'      => \$help,
  'debug!'    => \$DEBUG,

  'dbname:s' => \$dbvals{NAME},
  'name:s' => \$dbvals{NAME},
  'host:s' => \$dbvals{HOST},
  'port:s' => \$dbvals{PORT},
  'username:s' => \$dbvals{USERNAME},
  'password:s' => \$dbvals{PASSWORD},
  );

if ($ok) {
  $ok=  $SEQ_TYPE || $ORGANISM || $pubTitle;
  warn "Need selector: type, organism, pub\n" unless $ok;
  }
if($help || !$ok) { system( 'pod2text', $0 ); exit -1 };

# Chado::LoadDBI->init( %dbvals );
$chadoseq->openChadoDB( 
  verbose => $verbose, 
  dochecksum => $dochecksum,
  readwrite => 0,
  dbvalues => \%dbvals,
  );


#---- Select features here -- could use more options, still needs work to 
#---- do complex select with Chado::DBI->search()
#---- want cross-table search to use $pub: Feature_Pub & Feature search

my @chado_features= ();
my $featiter= undef;

my ($pub)= Chado::Pub->search_like( title => $pubTitle ) if ($pubTitle) ;
if ($pub) {
  # @chado_features=  
  $featiter= $chadoseq->getPubFeatures($pub);
  }

else {
  my @where=();
  
  if ($SEQ_TYPE) {
    ## this *should* be an ontology search. e.g. all subtypes match supetype
    my $seq_type= $chadoseq->getSeqType($SEQ_TYPE);
    die unless ($seq_type)  ; # already warned ..
    push @where, ( 'type_id' => $seq_type->id );
    }
    
  if ($ORGANISM) {
    # want to allow multiple orgs - need Class::DBI->search( a OR b) ...
    my $org= $chadoseq->getOrganism($ORGANISM);
    die unless ($org)  ; # already warned ..
    push @where, ( 'organism_id' => $org->id );
    }
  
  print "Chado::Feature->search where=",join(',',@where),"\n" if $verbose;
  # @chado_features= 
  $featiter= Chado::Feature->search( 
      @where, { 'order_by' => 'feature_id' } 
      );
  }

# >> this is hassle if we want only fasta out-- need to make Bio::Seq objects
# my $seqio = Bio::SeqIO->new( -file => $OUTFILE, -format => $SEQ_FORMAT, );

my $seqio = *STDOUT;
if ($OUTFILE && open(SQ,">$OUTFILE")) { $seqio= *SQ; }

my $ndumped= 0;
$ndumped = $chadoseq->dumpSequences( $seqio, $featiter); # \@chado_features 

close($seqio) if ($OUTFILE); # $seqio->close();

print "\n$ndumped features dumped\nDone\n" if $verbose;

exit 0;



