#!/usr/bin/perl 

=head1 NAME

  gmod_list_db.pl

=head1 SYNOPSIS

Summarize feature entries in a Chado database, by publication (input file),
by Seq. Ontology type (cDNA, EST, etc.), by organism.  Add other categories
as needed.

=head1 COMMAND-LINE OPTIONS

The following command line options are required.  Note that they
can be abbreviated to one letter.

  --checksum     look for duplicate checksums
  
The following DBI database command line options are supported.  
  --name --host --port --username --password
They are optional; %ENV and conf/gmod.conf will also be consulted for them .

=head1 EXAMPLE

  dghome2% bin/gmod_list_db.pl -check
  Argos::Config using ARGOS_SERVICE=daphnia
  Argos::Config reading configs at /bio/biodb/gmod/conf 
  Argos::Config reading configs at /bio/biodb/daphnia/conf 
  
  Feature summary for Chado  database
  ============================================================
  Chado::LoadDBI(Main,dbi:Pg:dbname=daphnia;port=7302;host=localhost,gilbertd,passwd)

  Features by Chado::Organism  n=12
  2053    Daphnia pulex/D.pulex/waterflea
  ------------------------------------------------------------
  
  Features by Chado::Pub  n=5
  397     data/est1.fa 1076639361 type=seq_file
  858     data/microDNA.fa 1075475373 type=seq_file
  397     data/CGBvntr.fa 1076132020 type=seq_file
  401     data/cDNA1.fa 1076732417 type=seq_file
  ------------------------------------------------------------
  
  Features by Chado::Cv Sequence Ontology, n=897
  397     EST
  798     cDNA_clone
  858     microsatellite
  ------------------------------------------------------------
  
  
  Public ID counter
  ID_Tag  Last_ID Description
  WFcl    798     id counter for cDNA_clone by gmod_load_newseq
  WFms    858     id counter for microsatellite by gmod_load_newseq
  WFes    397     id counter for EST by gmod_load_newseq
  ------------------------------------------------------------
  
  Chado::Feature  total=2053
  
  Duplicate checksums
  Name____        Length  Seq_type        Synonym Feat_id Publication     Checksum
  WFcl0000685     386     cDNA_clone      P1-A4   1940    'data/cDNA1.fa 1076732417'  aa9fd3770c6750b1748edb68ce7b97e8
  WFcl0000687     386     cDNA_clone      P1-G9   1942    'data/cDNA1.fa 1076732417'  aa9fd3770c6750b1748edb68ce7b97e8
  ------------------------------------------------------------
  
  ============================================================
  Done

=cut

use strict;
use warnings;

# use Argos::Config;   # loads config to ENV; or eval { "require Argos::Config;" };
use GMOD::Config; # simpler alternate, checks only conf/gmod.conf for ENV settings

# use Chado::LoadDBI; #< moved to  GMOD::Chado::SeqUtils
use GMOD::Chado::SeqUtils; # common methods for these seq tools
use Getopt::Long;


$| = 1;

our $DEBUG = 0 unless defined $DEBUG;

print "\nFeature summary for Chado  database\n","="x60,"\n";

my $chadoseq= GMOD::Chado::SeqUtils->new;
my %dbvals  = $chadoseq->getDatabaseOpenParams();

my $verbose=0;
my $dochecksum= 0;
my $help=0;
my $ok= GetOptions(
  'checksum!'    => \$dochecksum,
  'debug!'    => \$DEBUG,
  'verbose!'  => \$verbose,
  'help'  => \$help,
  'dbname:s' => \$dbvals{NAME},
  'host:s' => \$dbvals{HOST},
  'port:s' => \$dbvals{PORT},
  'username:s' => \$dbvals{USERNAME},
  'password:s' => \$dbvals{PASSWORD},
  );

if($help || !$ok) { system( 'pod2text', $0 ); exit -1 };

$chadoseq->openChadoDB( 
  verbose => $verbose, 
  dochecksum => $dochecksum,
  readwrite => 0,
  dbvalues => \%dbvals,
  );


my $iter;

$iter = Chado::Organism->retrieve_all;
print "Features by Chado::Organism  n=",$iter->count,"\n";
for (my $org = $iter->first; ($org) ; $org= $iter->next) {
  my $fit= Chado::Feature->search( organism_id => $org->id  );
  next unless (defined $fit && $fit->count > 0);
  print $fit->count, "\t", $org->genus," ",$org->species,"/",$org->abbreviation,"/",$org->common_name,"\n";
  }
print "-"x60,"\n\n";  


$iter = Chado::Pub->retrieve_all;
print "Features by Chado::Pub  n=",$iter->count,"\n";
for (my $pub = $iter->first; ($pub) ; $pub= $iter->next) {
  my $fit = Chado::Feature_Pub->search( pub_id => $pub->id, );
  next unless (defined $fit && $fit->count > 0);
  print $fit->count, "\t", $pub->title, " type=",$pub->type_id->name, "\n";
  }
print "-"x60,"\n\n";  

   
my ($socv)= Chado::Cv->search( name => $chadoseq->SequenceOntology);
if ($socv) {
  $iter= Chado::Cvterm->search( cv_id => $socv->id );
  print "Features by Chado::Cv ".$chadoseq->SequenceOntology.", n=",$iter->count,"\n";
  for (my $sot = $iter->first; ($sot) ; $sot= $iter->next) {
    my $fit= Chado::Feature->search( type_id => $sot->id  );
    next unless (defined $fit && $fit->count > 0);
    print $fit->count, "\t", $sot->name,"\n";
    }
  }
print "-"x60,"\n\n";  

$chadoseq->listPublicIds(*STDOUT);

$iter = Chado::Feature->retrieve_all;
print "Chado::Feature  total=",$iter->count,"\n";

$chadoseq->listDupChecksums(*STDOUT, $iter) 
  if ($dochecksum);
  
print "="x60,"\n";

print "Done\n";
exit 0;


