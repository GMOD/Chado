#!/usr/bin/perl 

=head1 NAME

gmod_load_newseq.pl

=head1 SYNOPSIS

Load a file of miscellany sequences into chado db, generating public IDs.
Sequences are assumed to be non-genomic, not located.

=head1 NOTES

Good for small seqs: cDNA, EST, microsats, ; left out genome-sized
methods. Need for nascent daphnia wFleaBase to get sequence public IDs
Cut from gmod_load_gff3.pl
 

=head1 EXAMPLE

  bin/gmod_load_newseq.pl -v \
   --dbname=daphnia --org="D.pulex"  \
   --in=$b/daphnia/data/CGBvntr.fa  --format=fasta  \
   --type=cDNA_clone  --idmake="WFcl"

  bin/gmod_load_newseq.pl --org="D.pulex" \
     --in=data/cDNA1.fa --format=fasta \
     --type=cDNA_clone --idmake="WFcl"
     
  Argos::Config using ARGOS_SERVICE=daphnia
  Argos::Config reading configs at /export/home/bio/biodb/gmod/conf 
  Argos::Config reading configs at /export/home/bio/biodb/daphnia/conf 
  GMOD::Chado::LoadDBI(Main,dbi:Pg:dbname=daphnia;port=7302;host=localhost,,passwd)
  Working with Daphnia pulex.
  .................................................. 50=WFcl0001545
  .................................................. 100=WFcl0001595
  .................................................. 150=WFcl0001645
  .................................................. 200=WFcl0001695
  .................................................. 250=WFcl0001745
  .................................................. 300=WFcl0001795
  .................................................. 350=WFcl0001845
  ...............................................
  397 features added


=head1 COMMAND-LINE OPTIONS

The following command line options are required.  Note that they
can be abbreviated to one letter.

  --organism <org name>      Common name of the organism
  --infile   <seq file>      input sequence file
  --format   <seqio format>  sequence format: FastA, GenBank, EMBL, ...
  --type     <seq  type>     sequence type, valid SO cvterm (you will be warned if not)
  --idmake   <id tag>        generate Public IDs with prefix + next_feature_id  (e.g. FBan, WFcl)
  --verbose                  talk about it
  --[no]checkdups            use checksum, seqlen, synonyms to screen duplicate entries
  --[no]diebadorganism       stop if organism (in data) not found
  --force                    reload from same infile (bad with -idmake)

The following DBI database command line options are supported.  
  --dbname --host --port --username --password
They are optional; %ENV and conf/gmod.conf will also be consulted for them .

=head1 SEE ALSO

  gmod_init_db.pl -- initialize a new database, adding organisms, intialize.sql,
     ontology data sets.
     
  gmod_dump_seq.pl -- output sequences selected by organism, publication (input file),
     seq type.
     
  gmod_list_db.pl  -- show feature statistics for chado db: # per organism, per seq type,
    per publication/infile, and checksum test for sequence duplications.

  GMOD::Chado::SeqUtils -- common methods for these chado seq scripts
      
=head1 AUTHORS

  Don Gilbert, Feb 2004

=head1 METHODS

=cut

use strict;
use warnings;

# use Argos::Config;   # loads config to ENV; or eval { "require Argos::Config;" };
use GMOD::Config; # simpler alternate, checks only conf/gmod.conf for ENV settings

use Bio::SeqIO;

# use Chado::LoadDBI; #< moved to  GMOD::Chado::SeqUtils
use GMOD::Chado::SeqUtils; # common methods for these seq tools
use Getopt::Long;
use Digest::MD5 qw(md5_hex);

our $DEBUG = 0 unless defined $DEBUG;

my $ID_TAG = undef;
my $ID_NUM = 0;
my $GENERATE_PUBID= 0;
my $SEQ_FORMAT = 'fasta';
my $SEQ_TYPE  = 'so';
my $ORGANISM  = undef;
my $CACHE_SIZE = 1000;
my $checkdups = 0;
my $reloading = 0;
my $verbose=0;
my $dieNoOrganism=1;

my @needed_cvterms =
  qw(description synonym region note develops_from part_of seq_file score protein);

my ( $SRC_DB, $INFILE, $FORCE_LOAD );
my ( $chado_db, $chado_organism, $nullpub, $nullcontact ) 
  = ( undef, undef, undef, undef );
my $feature_count = 0;        #for cache/flush
my @dupfeats = ();
my @transaction = ();


#-------------------- begin ---------------------
$| = 1;

print "Loading sequences to database.\n";

my $chadoseq= GMOD::Chado::SeqUtils->new;
my %dbvals= $chadoseq->getDatabaseOpenParams();

my $help=0;
my $ok= GetOptions(
  'checkdups!'  => \$checkdups,
  'format:s'    => \$SEQ_FORMAT,
  'force!'      => \$FORCE_LOAD,
  'infile:s'    => \$INFILE,
  'idmake:s'    => \$ID_TAG,
  'organism:s'  => \$ORGANISM,
  'type:s'      => \$SEQ_TYPE,
  'verbose!'  => \$verbose,
  'help'      => \$help,
  'debug!'    => \$DEBUG,
  'diebadorganism!' => \$dieNoOrganism,
  
  'dbname:s' => \$dbvals{NAME},
  'name:s' => \$dbvals{NAME},
  'host:s' => \$dbvals{HOST},
  'port:s' => \$dbvals{PORT},
  'username:s' => \$dbvals{USERNAME},
  'password:s' => \$dbvals{PASSWORD},
  );

unless($INFILE) {
  $ok=0; warn "\nYou must specify a sequence file\n";
  }
elsif (!-e $INFILE) {
  $ok=0; warn "$INFILE does not exist";
  }
if($help || !$ok) { system( 'pod2text', $0 ); exit -1 };
  
$GENERATE_PUBID = ($ID_TAG) ? 1 : 0;


#---------- open database, start work --------------------

# Chado::LoadDBI->init( %dbvals );
$chadoseq->openChadoDB( 
  verbose => $verbose, 
  readwrite => 1, ## WRITE 
  dbvalues => \%dbvals,
  );

# find needed cvterm and other pieces of information
$chadoseq->cache_cvterm($_) foreach (@needed_cvterms);
($nullpub)        = Bio::Chado::CDBI::Pub->search( miniref          => 'null' );
($nullcontact)    = Bio::Chado::CDBI::Contact->search( name         => 'null' );

$chado_organism= $chadoseq->getOrganism( $ORGANISM);
die unless($chado_organism);

my $seq_type= $chadoseq->getSeqType($SEQ_TYPE);
die unless($seq_type);


## daphnia project - use parser for specialized fasta deflines ...
my $seqSubformat= $SEQ_FORMAT;

if ( $SEQ_FORMAT =~ /fasta/ && 
    ($SEQ_FORMAT =~ /daphnia/ || $chado_organism->genus() =~ /daphnia/i) ) {
  $seqSubformat= 'daphniafasta1';
  $SEQ_FORMAT= 'fasta';
  }
print "parsing sequence as $seqSubformat\n" if $verbose;


my $mtime = ( stat($INFILE) )[9];
my ($pub) = Bio::Chado::CDBI::Pub->search( title => $INFILE . " " . $mtime );
if ( $pub ) { #and !$FORCE_LOAD 
    print "\nIt appears that you have already loaded this exact file\n";
    print "Do you want to continue [no]? ";
    chomp( my $response = <STDIN> );
    unless ( $response =~ /^[Yy]/ ) {
        print "OK--bye.\n";
        exit 0;
    }

    $reloading=1;
    my $featpubs= Bio::Chado::CDBI::Feature_Pub->search( pub_id  => $pub->id );
    if ($featpubs) {
      print "Deleting ".$featpubs->count." existing features for ".$pub->title."\n";
      ## $featpubs->delete_all; ## doesn't cascade over to delete assoc. features !
      for (my $fpub = $featpubs->first; ($fpub) ; $fpub= $featpubs->next) {
        my $chado_feature = $fpub->feature_id;
        $chado_feature->delete; #  should cause feature_pub + props, syns to delete on cascade
        }
      }
  }
else {
  my $pubtype= $chadoseq->cache_cvterm('seq_file');
  $pub = Bio::Chado::CDBI::Pub->find_or_create( {
          title      => $INFILE . " " . $mtime,
          miniref    => $INFILE . " " . $mtime,
          uniquename => $INFILE . " " . $mtime,
          type_id    => $pubtype->id,
      } );
  }

die "unable to find or create a pub entry in the pub table"
  unless $pub;

my $seqio = Bio::SeqIO->new(
    -file   => $INFILE,
    -format => $SEQ_FORMAT,
    );

$ID_NUM= $chadoseq->lastPublicId( $ID_TAG, $seq_type->name) 
  if ($GENERATE_PUBID);

my ($nadded, $ndups);

($nadded, $ndups)= loadSequences( $chado_organism->id, $seq_type->id, $seqio);

#  # -- OR, if need more complex input options:
# while ( my $seq = $seqio->next_seq() ) {
#   my ($added, $dup)= loadOneSequence( $chado_organism->id, $seq_type->id, $seq);
#   $nadded += $added; $ndups += $dup;
#   } 
  
$chadoseq->lastPublicId( $ID_TAG, $seq_type->name, $ID_NUM) 
  if ($GENERATE_PUBID);

$_->dbi_commit foreach @transaction; @transaction = ();

$seqio->close();

print "\n$nadded sequences added\n";

print "$ndups duplicate sequences skipped\n";
#if ($verbose) {
foreach my $dupft (@dupfeats) {
  print "  ",$dupft,"\n";
  }
#}
 
print "Done\n";
exit 0;


#---------- subs --------------


=item parseSeq($seq, $id)

  Parse input Bio::Seq for extra fields.
  Return these parts for chadodb 
    \@synonyms, \@dbxrefs, \%props

  subformat for daphnia fasta deflines: daphniafasta1 :
  >WFBid=397|clone=P2-G32000FW531070|taxon=D.pulicaria|strain=
  MarieLake,Oregon|library=CGBvntr|date=Jan2004|note1=|contact=JColbourne|

=cut

sub parseSeq {
  my ($seq, $id)= @_;
  my %props=();
  my @synonyms= ();
  my @dbxrefs= ();
  
  if ($seqSubformat eq 'daphniafasta1') {
    my $d=  $seq->display_id(); # all doc is in this long id..
    if ($d =~ m/=/ && $d =~ m/\|/) {
      %props = map { split /=/,$_,2; } split(/\|/, $d);
      }
    else {
      # $props{ID}= $d; #? fall back
      push(@synonyms, $d);  # which - prop or syn ?
      }
    if ($props{'WFBid'}) { push(@synonyms, 'WFBid'.delete $props{'WFBid'}); }
    #? is "clone=P2-G32000FW531070" a synonym or prop ?
    if ($props{'clone'}) { push(@synonyms, $props{'clone'}); }
    }
    
  else {  
    my $prop= $seq->display_id();
    push(@synonyms, $prop) if ($prop && $prop ne $id);
    $prop= $seq->accession_number();
    push(@synonyms, $prop) if ($prop && $prop ne $id);
    my $desc= $seq->desc();
    $props{description}= $desc if ($desc);
    my $keys= $seq->keywords() if ($seq->can('keywords'));
    $props{keywords}= $keys if ($keys);
    }

  return (\@synonyms, \@dbxrefs, \%props);
}


sub nextPublicId {
  my( $idnum )= @_;
  my $pubid= $ID_TAG . sprintf("%07d", ++$ID_NUM);
  ## my $pubid= getPublicId($ID_TAG, ++$ID_NUM);
  return $pubid;
}


=item loadSequences(organism_id,$seq_type_id, $seqin)

  read thru input sequence file, parsed by Bio::SeqIO 
  and load each to Bio::Chado::CDBI::Features table.
  Return ($nadded, $ndups)
  
=cut

sub loadSequences {
  my ($organism_id, $seq_type_id, $seqin)= @_;
  my $i   = 0;
  my $ndup= 0;
  
  # creates the features for each seq 
  while ( my $seq = $seqin->next_seq() ) {
    
    my @synonyms=();
    my @dbxrefs=();
    my %props=();
     
    my $id= ($GENERATE_PUBID) ? nextPublicId() : $seq->primary_id;  

    my ($synonyms, $dbxrefs, $props)= parseSeq($seq, $id);
    @synonyms= @$synonyms;
    @dbxrefs= @$dbxrefs;
    %props= %$props;

    my $org= $props{'taxon'} || $props{'species'} || $props{'organism'};
    if ($org && $org ne $ORGANISM) {
      my $chado_org= $chadoseq->getOrganism( $org, 1 );
      if ($chado_org) { $organism_id= $chado_org->id; $ORGANISM= $org; }
      else { 
        print STDERR "Couldn't find organism $org; Please update Organism table\n"; 
        die if ($dieNoOrganism); #  is this serious or not ?
        }
      }

    my $seqlen= $seq->length();
    # should calc, store md5checksum
    my $md5checksum= md5_hex($seq->seq);
    
    my $chado_feature= undef;
    
    ($chado_feature) = Bio::Chado::CDBI::Feature->search( { name => $id } )
      ; #unless ($GENERATE_PUBID); << do anyway, don't allow dups
      
    # add option here to check for $md5checksum + $seqlen ??
    if ( $checkdups && ! $chado_feature ) {
        # may be several matches, need to check each
      my $iter = Bio::Chado::CDBI::Feature->search( {
         organism_id => $organism_id,
         seqlen => $seqlen,
         md5checksum => $md5checksum,
        } );
       
      if ($iter) {  
        #? do we need to commit before search same data in transactions?
        $_->dbi_commit foreach @transaction; @transaction = ();
        
        for (my $feat = $iter->first; ($feat) ; $feat= $iter->next) {
          # check synonyms - some of these are valid 2nd entries (syn differ) 
          # some are same entry/diff file
          my $match= 0;
          my @altsyns= $chadoseq->getSynonyms($feat);
          foreach my $syn (@synonyms) {
            if (grep /^$syn$/i, @altsyns) { $match=1; last; }
            }
          if($match) { $chado_feature= $feat; last; }
          }  
        }
     }
     
    unless ( $chado_feature ) {
      $chado_feature = Bio::Chado::CDBI::Feature->create(
        {
          organism_id => $organism_id,
          name      => $id,
          uniquename  => $id,
          type_id   => $seq_type_id,
          residues  => $seq->seq,
          seqlen    => $seqlen,
          md5checksum => $md5checksum,
        }
      );

      $i++;
      $chado_feature->dbi_commit;
      ## $feature{ $chado_feature->name } = $chado_feature;
      if ($verbose) { print "$i. $id, len=$seqlen\n" ; }
      else { print "."; print " $i $id\n" if (($ndup+$i) % 50 == 0 ); }

      #?? should we update pub id counter as we go along?
      # .. otherwise failure in this loop will leave it bad
      #$chadoseq->lastPublicId( $ID_TAG, $seq_type->name, $ID_NUM) 
      #  if ($GENERATE_PUBID);

      add_Featurepub($chado_feature, $pub);
      }
    else {
      $ndup++;
      my $oldseq= $chadoseq->getFeatureDefline($chado_feature);
      my $newseq= $seq->display_id;
      push(@dupfeats, "new=$newseq\told=$oldseq");
      #$dupfeature{ $chado_feature->name } = $chado_feature;
      
      #? save also current skipped @syn, %props, for display?
      --$ID_NUM if ($GENERATE_PUBID);
      if ($verbose) { print ">> already loaded: ".$chado_feature->name."\n"; }
      else { print "-"; print " $i $id\n" if (($ndup+$i) % 50 == 0 ); }
    }
     
    #?? reload seq->seq if have feature?
    #?? reload these others?
    
    load_Synonyms($chado_feature, @synonyms) if @synonyms;

    load_Dbxref($chado_feature, @dbxrefs) if @dbxrefs; 

      ## use props for 'description', other info
    load_Properties($chado_feature, %props) if %props; 
      
      ## some other info for daphnia data ?
    # if ($props{contact}) { } ## add t contact table
    
    if ( $feature_count % $CACHE_SIZE == 0 ) {
      $_->dbi_commit foreach @transaction;
      @transaction = ();
      }

    }
 
  return ($i, $ndup);
}



=pod
                                                                                
=item load_Synonyms($chado_feature,@names)
                                                                                
Loads Name values.
                                                                                
=cut

sub load_Synonyms {
    my ($chado_feature,@names)   = @_;

    my $syntype= $chadoseq->cache_cvterm('synonym');
    print " load syns=".join(',',@names)."\n" if ($verbose);
    foreach my $name (@names) {
        my ($chado_synonym1) = Bio::Chado::CDBI::Synonym->find_or_create(
            {
                name         => $name,
                synonym_sgml => $name,
                type_id      => $syntype->id
            }
        );

        my ($chado_synonym2) = Bio::Chado::CDBI::Feature_Synonym->find_or_create(
            {
                synonym_id => $chado_synonym1->id,
                feature_id => $chado_feature->id,
                pub_id     => $pub->id,
            }
        );
        push @transaction, $chado_synonym1;
        push @transaction, $chado_synonym2;
    }
    
}


=pod
                                                                                
=item add_Featurepub($chado_feature,$pub)
                                                                                
 add feature_pub entry for each feature x $pub (INFILE reference)
                                                                               
=cut

sub add_Featurepub {
    my ($chado_feature,$pub)   = @_;

    my ($chado_fpub) = Bio::Chado::CDBI::Feature_Pub->find_or_create(
        {
            feature_id => $chado_feature->id,
            pub_id     => $pub->id,
        }
    );
    push @transaction, $chado_fpub;
}


=item load_Dbxref($chado_feature, @dbxrefs)

  @dbxrefs is array of DbName:DbAccession
  
=cut

sub load_Dbxref {
  my ($chado_feature, @dbxrefs)   = @_;

  print " load dbxref=".join(',',@dbxrefs)."\n" if ($verbose);
  foreach my $dbx (@dbxrefs) {
    my($tag,$accession)= split(/:/,$dbx,2);
    
    ## $tag= "DB:$tag";  << this is what gmod_load_gff3.pl does
    ## dgg - what is with this 'DB:' prefix to database names ?
    ## it is name stored in Db table, so shouldn't all be prefix-less??
    ## e.g. GenBank is public Db name, not DB:GenBank
    ## Standard accession is GenBank:AF000001, UniProt:AC000000, not DB:GenBank....
    ## should correspond to Bio::Chado::CDBI::Db->name":"Bio::Chado::CDBI::Dbxref->name
    
    my ($db) = Bio::Chado::CDBI::Db->search( name => $tag )
          ||  Bio::Chado::CDBI::Db->search( name => "DB:".$tag );
    unless ( $db ) {
        $db = Bio::Chado::CDBI::Db->find_or_create( {
                name       => $tag,
                contact_id =>  $nullcontact,
            } );
      }
    die "couldn't create db $db" unless $db;
    push @transaction, $db;

    my ($dbxref) = Bio::Chado::CDBI::Dbxref->find_or_create( {
            db_id     => $db->id,
            accession => $accession
        } );
    
    my ($feature_dbxref) = Bio::Chado::CDBI::Feature_Dbxref->find_or_create( {
            feature_id => $chado_feature->id,
            dbxref_id  => $dbxref->id,
        } );
    push @transaction, ( $dbxref, $feature_dbxref );
  }

}


=pod

=item load_Properties($chado_feature, %props)

Loads property values to the featureprop table.
%props is hash of property name => value

=cut

sub load_Properties {
  my ($chado_feature, %props)   = @_;

  print " load props=".join(',',keys %props)."\n" if ($verbose);
  foreach my $propname (keys %props) {
    my $proptype= $chadoseq->cache_cvterm($propname);
    my $value= $props{$propname};
    ##if (defined $value) {
    my ($featureprop) = Bio::Chado::CDBI::Featureprop->find_or_create( {
            feature_id => $chado_feature->id,
            type_id    => $proptype->id,
            value      => $value,
        } );
    push @transaction, ($featureprop);
    ##}
    }
}




__END__

working notes

patch database after loading for new PubicID storage ...

daphnia=# select * from db ;
daphnia=# select * from dbxref where db_id > 6;

 dbxref_id | db_id | accession | version |       description                   
-----------+-------+-----------+---------+-------------------------------------
       941 |     7 | WFcl      | 2511    | counter created by gmod_load_newseq
       942 |     8 | WFes      | 1016    | counter created by gmod_load_newseq
       943 |     9 | WFms      | 2315    | counter created by gmod_load_newseq


update db set name = 'PublicID:counter' where db_id=7;
DELETE FROM db where db_id = 8 or db_id = 9;

update dbxref set db_id = 7 where db_id > 7;
update dbxref set 
  description ='id counter for EST by gmod_load_newseq'
  where accession = 'WFes';
  
update dbxref set 
  description ='id counter for cDNA_clone by gmod_load_newseq'
  where accession = 'WFcl';

update dbxref set 
  description ='id counter for microsatellite by gmod_load_newseq'
  where accession = 'WFms';

-----
dghome2% bin/gmod_load_newseq.pl -v \
  --org="D.pulex" \
  --in=$b/daphnia/data/CGBvntr.fa --format=fasta \
  --type=cDNA --idmake="WFcl"
   --- type = cDNA_clone in SO
   
Argos::Config using ARGOS_SERVICE=GMOD at /bio/biodb/gmod/lib/Argos/Config.pm line 55.

GMOD::Chado::LoadDBI args=HOST=localhost,USERNAME=gilbertd,NAME=chado-test,PASSWORD=,PORT=7302 at /bio/biodb/gmod/lib/Chado/LoadDBI.pm line 89.
GMOD::Chado::LoadDBI set_db(Main,dbi:Pg:dbname=chado-test;port=7302;host=localhost,gilbertd,passwd) at /bio/biodb/gmod/lib/Chado/LoadDBI.pm line 118.
Working with Daphnia pulex.

Ontology Sequence Ontology is not loaded; using cDNA at bin/gmod_load_newseq.pl line 309.

parsing sequence as daphniafasta1
1. WFcd0000001, len=1103
 load syns=WFBid1,P1-11T7
 load props=note1,contact,library,date,strain,clone,taxon
2. WFcd0000002, len=1027
 load syns=WFBid2,P1-14T7
 load props=note1,contact,library,date,strain,clone,taxon
3. WFcd0000003, len=1026
 load syns=WFBid3,P1-1EP2-92FW
 load props=note1,contact,library,date,strain,clone,taxon

...

397. WFcd0000397, len=61
 load syns=WFBid397,P2-G32000FW531070
 load props=note1,contact,library,date,strain,clone,taxon

397 features added
Done


dghome2%  bin/gmod_dump_seq.pl -v -pub='%CGBvntr%' --org="D.pulex" |more
Argos::Config using ARGOS_SERVICE=GMOD at /bio/biodb/gmod/lib/Argos/Config.pm line 55.
GMOD::Chado::LoadDBI args=HOST=localhost,USERNAME=gilbertd,NAME=chado-test,PASSWORD=,PORT=7302 at /bio/biodb/gmod/lib/Chado/LoadDBI.pm line 89.
GMOD::Chado::LoadDBI set_db(Main,dbi:Pg:dbname=chado-test;port=7302;host=localhost,gilbertd,passwd) at /bio/biodb/gmod/lib/Chado/LoadDBI.pm line 118.
Working with Daphnia pulex.
getFeaturePub 5 n= 0

...



check sql
org 10 = Daphnia pulex


select f.name,f.feature_id,f.seqlen,p.value
from feature f, featureprop p
where f.organism_id = 10 and f.feature_id = p.feature_id

select f.name,f.feature_id,f.seqlen,s.name
from feature f, synonym s, feature_synonym sf
where f.organism_id = 10 
  and f.feature_id = sf.feature_id
  and s.synonym_id = sf.synonym_id

select count(f.feature_id) 
from feature f, featureprop p
where f.organism_id = 10 and f.feature_id = p.feature_id

select count(f.feature_id) 
from feature f, synonym s, feature_synonym sf
where f.organism_id = 10 
  and f.feature_id = sf.feature_id
  and s.synonym_id = sf.synonym_id

#--- drop bad data ...
delete 
from  feature
where feature.organism_id = 10 

delete 
from  featureprop
where feature.organism_id = 10 
  and feature.feature_id = featureprop.feature_id

delete 
from  feature_synonym
where feature.organism_id = 10 
  and feature.feature_id = feature_synonym.feature_id

delete 
from  synonym
where feature.organism_id = 10 
  and feature.feature_id = feature_synonym.feature_id
  and synonym.synonym_id = feature_synonym.synonym_id

  
dghome2%   bin/gmod_load_newseq.pl -v \
   --db=daphnia --o ->    --db=daphnia --org="D.pulex"  \
   --in=$b/daphnia/data/CGBvntr.fa ->    --in=$b/daphnia/data/CGBvntr.fa  --format=fasta  \
   --type=cDNA  --idmake="WFcd ->    --type=cDNA  --idmake="WFcd"
Argos::Config using ARGOS_SERVICE=GMOD at /bio/biodb/gmod/lib/Argos/Config.pm line 55.
GMOD::Chado::LoadDBI args=HOST=localhost,USERNAME=gilbertd,NAME=daphnia,PASSWORD=,PORT=7302 at /bio/biodb/gmod/lib/Chado/LoadDBI.pm line 89.
GMOD::Chado::LoadDBI set_db(Main,dbi:Pg:dbname=daphnia;port=7302;host=localhost,gilbertd,passwd) at /bio/biodb/gmod/lib/Chado/LoadDBI.pm line 118.
Working with Daphnia pulex.
These terms from Sequence Ontology match. Please choose one:
cDNA_match
cDNA_clone
chimeric_cDNA_clone
genomically_contaminated_cDNA_clone
genomic_polyA_primed_cDNA_clone
partially_unprocessed_cDNA_clone
CDS_supported_by_EST_or_cDNA_data
Died at bin/gmod_load_newseq.pl line 297.


