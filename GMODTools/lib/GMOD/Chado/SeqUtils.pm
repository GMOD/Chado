
=head1 NAME

  GMOD::Chado::SeqUtils  -- common sequence in/out/check methods for Chado DB

=head1 SYNOPSIS

 
=head1 SEE ALSO

  GMOD Chado sequence scripts for init_db, load_newseq, dump_seq, list_db .

  gmod_init_db.pl -- initialize a new database, adding organisms, intialize.sql,
     ontology data sets.
     
  gmod_load_newseq.pl -- add miscellaneous organism sequences, cDNA, EST, 
     microsatellites, etc. not located on genome.  Optionally 
     generate PublicID for these.

  gmod_dump_seq.pl -- output sequences selected by organism, publication (input file),
     seq type.
     
  gmod_list_db.pl  -- show feature statistics for chado db: # per organism, per seq type,
    per publication/infile, and checksum test for sequence duplications.


=head1 AUTHOR

  Don Gilbert, Feb 2004.

=head1 METHODS

=cut

package GMOD::Chado::SeqUtils;

use strict;

# use lib('/bio/biodb/common/perl/lib','/bio/biodb/common/system-local/perl/lib'); # test

use GMOD::Chado::LoadDBI;

use vars qw( 
  @dbparts 
  %cvterm
  %org_cache
  $nullcontact
  );

our $DEBUG;

use constant SequenceOntology => 'Sequence Ontology';
use constant IDCounter => 'PublicID:counter'; # dbIdCounter == # Db->name key

BEGIN {
  $DEBUG= 0 unless defined $DEBUG;
  @dbparts= qw(NAME HOST PORT USERNAME PASSWORD); #? get from Chado::LoadDBI ?
  %cvterm   = ();
  %org_cache = ();
}

sub new {
	my $that= shift;
	my $class= ref($that) || $that;
	my %fields = @_;  
	my $self = \%fields;
	bless $self, $class;
  $self->init();
	return $self;
}

sub init {
  my $self= shift;
  $self->{readwrite}= 0 unless defined $self->{readwrite};
  $self->{verbose}= 0 unless defined $self->{verbose};
  $self->{dochecksum}= 0 unless defined $self->{dochecksum};
  $self->{defline_species}= 1 unless defined $self->{defline_species};
  
  # $self->{autocv}= 0 unless defined $self->{autocv};
}


=item openChadoDB( %params )

  basically calls Chado::LoadDBI->init( %$dbvals )
  and setReadWrite flag, inits some values from db
  parameters:
    verbose => 1/0
    readwrite => 1/0, r/w, t/f
    dbvalues => \%dbvalues from getDatabaseOpenParams
    
=cut

sub openChadoDB {
  my $self = shift;
  my %opts = @_;  
  $self->{$_}= $opts{$_} foreach (keys %opts); 
  
  die "openChadoDB: call with dbvalues => \%dbvalues from getDatabaseOpenParams" 
    unless (ref $self->{dbvalues});
  GMOD::Chado::LoadDBI->init( %{$self->{dbvalues}} );
  
  # some useful values for readwrite only ?
  # ($nullpub)    = Chado::Pub->search( miniref   => 'null' );
  ($nullcontact) = Chado::Contact->search( name  => 'null' );
  $self->initAutoCvTable();
}



=item getDatabaseOpenParams()

 Runtime checks for Chado::LoadDBI values of
   NAME HOST PORT USERNAME PASSWORD  [from getDatabaseParamKeys()]

 Checks %ENV for $GMOD_SERVICE_key, CHADO_DB_key,  e.g. 
  FLYBASE_DB_NAME = flybase-chado1
  FLYBASE_DB_PORT = 7404
    -- fallback to CHADO if GMOD_SERVICE is not defined
  CHADO_DB_NAME = chado-test 
  CHADO_DB_PORT = 7302
 Returns hash with these values, suitable for call to @ARG GetOptions()

  my %dbvals= getDatabaseOpenParams();
  
  my $ok= GetOptions(
    'dbname:s'  => \$dbvals{NAME},
    'name:s' => \$dbvals{NAME},
    'host:s' => \$dbvals{HOST},
    'port:s' => \$dbvals{PORT},
    'username:s' => \$dbvals{USERNAME},
    'password:s' => \$dbvals{PASSWORD},
    @otherOpts,
    );

=cut

sub getDatabaseParamKeys { my $self= shift; return @dbparts; } 

sub getDatabaseOpenParams {
  my $self= shift; 
  my %dbvals= map { $_ => '' } @dbparts;

  ## check %ENV -  first service_db keys, default to chado_db =  flybase, eugenes, daphnia, etc.
  my @service_db= ('CHADO_DB'); # what service is calling us ?
  unshift(@service_db, $ENV{'GMOD_SERVICE'}.'_DB')  if (defined $ENV{'GMOD_SERVICE'}); 
  unshift(@service_db, $ENV{'ARGOS_SERVICE'}.'_DB')  if (defined $ENV{'ARGOS_SERVICE'}); 

  foreach my $service_db (@service_db) {
    foreach my $part (@dbparts) {
      next if ($dbvals{$part});  
      my $v= $ENV{$service_db.'_'.uc($part)};
      $dbvals{$part}= $v if ($v);
      }
    }
  return %dbvals;
}


=item getSeqType($seqtype, $ontology)

 return Chado::Cvterm matching seqtype from ontology. 
 Supports use of SO seq types

=cut
 
sub getSeqType {
  my ($self, $seqtype, $ontname)= @_;
  my $type_id= undef;
  my $sotype = undef;
  $ontname = SequenceOntology unless($ontname);
  
  return $cvterm{$seqtype} if ($cvterm{$seqtype});
  
  my @sotype =  Chado::Cvterm->search( name => $seqtype ) 
             || Chado::Cvterm->search_like( name => "%$seqtype%" );  
  
  unless(@sotype) {
    print STDERR "Seq type=$seqtype not found. Please choose a type from $ontname";
    return undef;
    }
  elsif (@sotype > 1) {
    print STDERR "These terms from $ontname match '$seqtype'.\n";
    print STDERR "  ",$_->name,"\n" foreach (@sotype);
    # allow user choice here..
    print STDERR "Choose Sequence type? \n"; #? STDERR?
    chomp( $seqtype = <STDIN> );
    foreach my $sot (@sotype) {
      if ($sot->name eq $seqtype) { $sotype= $sot; last; }
      }
    return undef unless($sotype);
    }
  else { $sotype= shift @sotype; }
     
  $sotype = $sotype->first() 
    if defined( $sotype ) and $sotype->isa('Class::DBI::Iterator');

  my ($socv) = Chado::Cv->search( name => $ontname );
  unless ($socv) {
    print STDERR "Ontology $ontname is not loaded; using $seqtype";
    $self->cache_cvterm($seqtype);
    }
  elsif( $sotype->cv_id == $socv->id) {  
    print "Using seq type=".$sotype->name." from $ontname\n" if $self->{verbose};
    $cvterm{$seqtype}= $sotype;
    }
  else {
    print STDERR "$seqtype is not listed in $ontname";
    return undef;
    }

  return $cvterm{$seqtype};
}



sub initAutoCvTable {
  my ( $self ) = @_;
  ($self->{autocv}) = Chado::Cv->search( name => 'autocreated' );
  
  if(!$self->{autocv} && $self->{readwrite}) {   
    ($self->{autocv}) = Chado::Cv->find_or_create( {
      name       => 'autocreated',
      definition => "auto created by $0",
      } );
  }
}

=item cache_cvterm( $name [, $cv] )

 Look for $name in Chado::Cvterm.
 If not found and readwrite, add to cvterm table, with cv->id (autocv default)
 Store in hash for frequent reuse.
 return Chado::Cvterm  

=cut

sub cache_cvterm {
  my ( $self, $name, $cv ) = @_;
  return unless $name;  
  $cv= $self->{autocv} unless($cv);

  unless (defined $cvterm{$name}) {
    my ($term) =
       Chado::Cvterm->search( name => $name )
    || Chado::Cvterm->search( name => ucfirst($name) );
    
    if ( $term ) {
      $term = $term->first() if defined( $term ) and $term->isa('Class::DBI::Iterator');
      } 
    elsif ($self->{readwrite} && $cv) {
      $term = Chado::Cvterm->find_or_create( {
              name       => $name,
              cv_id      => $cv->id,
              definition => "auto created by $0",
              } ) ;
      warn "unable to create a '$name' entry in the cvterm table"
        unless($term);
      }
    $cvterm{$name} = $term; 
    }
    
  return $cvterm{$name}; 
}




=item getOrganism( $organism, $quiet)

 return Chado::Organism matching common name, abbreviation (best) or genus.
 Prompts for choice if ! $quiet

=cut

sub getOrganism {
  my ($self, $organism, $quiet)= @_;
  return undef unless($organism);
  my $chadorg= $org_cache{$organism};
  return $chadorg if $chadorg;

  my $iter = Chado::Organism->search( common_name => lc($organism) )
    || Chado::Organism->search( abbreviation => ucfirst($organism) )
    || Chado::Organism->search( genus => $organism  );

  if ($iter) { 
    if ( $iter->count == 1 ) { #? || quiet
      $chadorg = $iter->first();  
    } elsif (!$quiet) {
      print STDERR "The organism '$organism' matches these:\n";
      for (my $org = $iter->first; ($org) ; $org= $iter->next) {
        print STDERR "  ".$org->genus." ".$org->species."/".$org->abbreviation."/".$org->common_name."\n"; 
        }
      print STDERR "Select organism? (abbreviation): \n";
      chomp( $organism = <STDIN> );
      for (my $org = $iter->first; ($org) ; $org= $iter->next) {
        if ($org->abbreviation() eq $organism) { $chadorg= $org; last; }
        }
      }
    }
    
  else { 
    print STDERR "The organism '$organism' could not be found.\n";
    unless($quiet) {
      print STDERR "Available organisms:\n";
      $iter = Chado::Organism->retrieve_all;
      for (my $org = $iter->first; ($org) ; $org= $iter->next) {
        print STDERR "  ".$org->genus." ".$org->species."/".$org->abbreviation."/".$org->common_name."\n"; 
        }
      print STDERR "Select organism? (abbreviation): \n";
      chomp( $organism = <STDIN> );
      for (my $org = $iter->first; ($org) ; $org= $iter->next) {
        if ($org->abbreviation() eq $organism) { $chadorg= $org; last; }
        }
      }
    }
  if ($chadorg) {
    $org_cache{$organism}= $chadorg;
    print "Working with ".$chadorg->genus." ".$chadorg->species.".\n";
    }
  return $chadorg;
}



=pod
                                                                                
=item getSynonyms($chado_feature)
                                                                                
fetch synonym values, returns (wantarray) ? list : first
                                                                                
=cut

sub getSynonyms {
  my ($self, $chado_feature)   = @_;
  my @ftsyn  = Chado::Feature_Synonym->search(
              feature_id => $chado_feature->id,
              # pub_id     => $pub->id,
              );
  if (wantarray) {
    my @names= ();
    push @names, $_->synonym->name() foreach (@ftsyn);
    return @names; 
    }
  else {
    return (@ftsyn) ? $ftsyn[0]->synonym->name() : undef;
    }
}



=pod
                                                                                
=item getPubFeatures($pub)
                                                                                
 return features given $pub->id (OUTFILE reference)
                                                                               
=cut

sub getPubFeatures {
  my ($self, $pub)   = @_;
  my @allfeats= ();
  my @fpub = Chado::Feature_Pub->search(
      pub_id     => $pub->id,
      { order_by=>'feature_id' },
      );
  # print "getPubFeatures ".$pub->id." n= ".scalar(@fpub)."\n"  if $self->{verbose};

  push @allfeats, $_->feature_id foreach (@fpub);
  return @allfeats;     
}



=pod
                                                                                
=item getFeaturePubs($feat)
                                                                                
 return pubs given $feat->feature_id  
                                                                               
=cut

sub getFeaturePubs {
  my ($self, $ft)   = @_;
  my @items= ();
  my @fpub = Chado::Feature_Pub->search(
      feature_id     => $ft->id,
      { order_by=>'pub_id' },
      );
  push @items, $_->pub_id foreach (@fpub);
  return @items;     
}


=item getDbxrefs($chado_feature)

  @dbxrefs is array of DbName:DbAccession
  
=cut

sub getDbxrefs {
  my ($self, $chado_feature)   = @_;
  my @dbxrefs= ();
  
  my @feature_dbxref = Chado::Feature_Dbxref->search(
    feature_id => $chado_feature->id,
    );

  foreach my $d (@feature_dbxref) {
    next unless $d->dbxref_id;
    my $acc= $d->dbxref_id->accession;
    my $db = $d->dbxref_id->db_id->name; ## cache this one
    push(@dbxrefs, "$db:$acc");
    }
    
  return @dbxrefs;     
}



=pod

=item getProperties($chado_feature)

get property values from the featureprop table.
%props is hash of property name => value
 -- need bag, not hash - many vals per name
 
=cut

sub getProperties {
  my ($self, $chado_feature)   = @_;
  my %props= ();

   my @featureprop = Chado::Featureprop->search(
      feature_id => $chado_feature->id,
      );
    
  foreach my $p (@featureprop) {
    next unless $p->type_id;
    my $tpid= $p->type_id;
    my $tpname= $self->{type_id}{$tpid};
    unless($tpname) { $self->{type_id}{$tpid}= $tpname= $tpid->name; }

    #my $tpname= $p->type_id->name;
    $props{$tpname} .= "," if ($props{$tpname});
    $props{$tpname} .= $p->value;
    }
    
  return %props;     
}


=item dumpSequences($outh, @chado_features)

  Write sequences to $outh from Chado::Features.
  Includes seq_type, synonyms, feature_properties, feature_dbxrefs on defline
  Only fasta dump now.  E.g.
  
  >WFcd0000100 len=567;type=cDNA_clone;synonym=P1-E62000FW40325,WFBid100;contact=JColbo
  urne;library=CGBvntr;date=Jan2004;taxon=D.pulicaria;clone=P1-E62000FW40325;strain=Mar
  ieLake,Oregon
  GCGGGAGNCCGGTATATTGCAGAGTGGCATTATGGCCGNGAAGCAGTNGT
  ATCAACGCANAGTGGCCATTATGGCCGGGAAGCAGTGGTATCAACGCACG
  
  ## this is SLOW for 15K seq-feature database ...
  .. use iterator, not @feaure array ..
  .. cache common values ..
  
=cut

sub dumpSequences {
  my ($self, $outh, $chado_features)= @_;
  my $i   = 0;
  # print "dumpSequences n= ".scalar(@chado_features)."\n"  if $self->{verbose};
    
  if (!defined($chado_features)) {
    warn "Need Chado::Feature param"; 
    return -1;
    }
  elsif ($chado_features->isa('Class::DBI::Iterator')) {
    for (my $ft = $chado_features->first; ($ft) ; $ft= $chado_features->next) {
      my $res = $ft->residues;
      my $defline= $self->getFeatureDefline($ft);
      print $outh $defline,"\n";
      
      $res =~ s/(.{1,50})/$1\n/g;
      print $outh $res,"\n";   
      $i++;
      }
    return $i;
    }
    
  my @fts=();
  if (ref $chado_features =~ /ARRAY/) {
    @fts= @$chado_features;
    }
  elsif ($chado_features->isa('Chado::Feature')) {
    @fts= ($chado_features);
    }
  foreach my $ft (@fts) {
    my $res = $ft->residues;
    my $defline= $self->getFeatureDefline($ft);
    print $outh $defline,"\n";

    $res =~ s/(.{1,50})/$1\n/g;
    print $outh $res,"\n";   
    
    $i++;
    }
     
  return $i;
}


=item getFeatureDefline($chado_feature)

  return basic >fasta string of chado_feature information 

=cut

sub getFeatureDefline {
  my ($self, $chado_feature)= @_;
  #should we bother w/ Bio::Seq construction -> SeqIO::writeseq(seq); ?

  my $name= $chado_feature->name;
  my $len = $chado_feature->seqlen;
  my $defline= ">$name len=$len";

  my $tpid= $chado_feature->type_id;
  my $tpname= $self->{type_id}{$tpid};
  unless($tpname) { $self->{type_id}{$tpid}= $tpname= $tpid->name; }
  $defline .= "; type=" . $tpname; ## $tpid->name $ cache this
  
  my @synonyms= $self->getSynonyms($chado_feature);
  $defline .= "; synonym=".join(",",@synonyms) if @synonyms;

  my %props= $self->getProperties($chado_feature);

  if ($self->{defline_species}) { 
    #?? always/sometimes add species=$org->genus." ".$org->species;
    my $org= $chado_feature->organism_id;
    
    # my $ospp= $org->species;
    # my $species= $org->genus." ".$org->species;

    my $ospp= $self->{spponly}{$org};
    unless($ospp) { $self->{spponly}{$org}= $ospp= $org->species; }

    my $species= $self->{species}{$org};
    unless($species) { $self->{species}{$org}= $species= $org->genus." ".$org->species; }
    
    foreach (qw(taxon species organism)) {
      my $spp= $props{$_}; 
      if ($spp && $spp =~ /$ospp/i) { delete $props{$_}; } #what - do both?; ignore this?
      }
      
    $defline .= "; species=".$species;
    }
  
  $defline .= "; ".join("; ", (map{ "$_=$props{$_}"} sort keys %props))  
    if %props;

  my @dbxrefs= $self->getDbxrefs($chado_feature);
  $defline .= "; dbxref=".join(",",@dbxrefs) if @dbxrefs;
  
  if ($self->{dochecksum}) { # only if really want
    my $check= $chado_feature->md5checksum; ## add if not 0
    $defline .= "; checksum=$check" if ($check);
    }
  
  return $defline;
}


#? *defline = &getFeatureDefline;


=item lastPublicId($idtag, [$lastid])

  Get [Set] last public id number for given idtag

=cut

sub lastPublicId {
  my($self, $idtag, $idclass, $lastid)= @_;

  my ($iddb) = Chado::Db->search( name => IDCounter ); # $dbIdCounter  
  if (!$iddb && $self->{readwrite}) {  
    ($iddb) = Chado::Db->find_or_create( {
          name       =>  IDCounter,
          description => "database id counters created by $0",
          contact_id => $nullcontact, #??
          # urlprefix => $idtag,   #?
          # url => $url, 
        } ) ;
    $iddb->dbi_commit if $iddb;  
    }

  #? save idbx
  my ($idbx) = Chado::Dbxref->search( accession => $idtag , db_id => $iddb->id);
  $idbx = $idbx->first()  
    if defined($idbx) and $idbx->isa('Class::DBI::Iterator');

  if($idbx) {
    if (defined $lastid && $self->{readwrite}) { 
      $idbx->version($lastid); 
      $idbx->update(); $idbx->dbi_commit(); 
      print "Put last id for $idtag = $lastid\n" if ($self->{verbose});
      }
    else { 
      $lastid= $idbx->version();  
      print "Get last id for $idtag = $lastid\n" if ($self->{verbose});
      }
  } else {
    $lastid= 0;
    if ( $self->{readwrite} ) {
      $idbx=  Chado::Dbxref->find_or_create( {
                accession  => $idtag,
                version    => $lastid,  # our data !
                db_id      => $iddb->id,
                description => "id counter for $idclass by $0",
            } );
      $idbx->dbi_commit if $idbx; 
      print "New last id for $idtag = $lastid\n" if ($self->{verbose});
      }
    }
  return $lastid;
}


=item listPublicIds($outhandle)

list public id counters
 
=cut

sub listPublicIds {
  my ($self, $outhandle)= @_;
  print $outhandle "\nPublic ID counter\n";
  print $outhandle join("\t",qw(ID_Tag Last_ID Description)),"\n";
  my ($iddb) = Chado::Db->search( name => IDCounter );
  if ($iddb) {
    my $iter = Chado::Dbxref->search( db_id => $iddb->id);
    for (my $idbx= $iter->first(); ($idbx); $idbx= $iter->next()) {
       my $idtag = $idbx->accession();
       my $lastid= $idbx->version();  
       my $desc  = $idbx->description();
       print $outhandle  join("\t", $idtag, $lastid, $desc),"\n";
       }
    }
  print $outhandle "-"x60,"\n\n";  
}


=item listDupChecksums( $outhandle, [$feature_iterator])

checks thru features md5checksum for duplicates and lists any
if feature_iterator is null, checks all Chado::Feature 
 
=cut

sub listDupChecksums {
  my ($self, $outhandle, $iter)= @_;
  print $outhandle "\nDuplicate checksums\n";
  print $outhandle 
    join("\t",qw(Name____ Length Seq_type Synonym Feat_id Publication Checksum)),"\n";
  
  my %checks=();
  $iter = Chado::Feature->retrieve_all unless($iter);
  for (my $fit = $iter->first; ($fit) ; $fit= $iter->next) {
    my $ck= $fit->md5checksum;
    next unless($ck);
    $checks{$ck}++;
    }
    
  foreach my $ck (keys %checks) {
    next unless ($checks{$ck}>1);
    $iter= Chado::Feature->search( md5checksum => $ck  );
    for (my $fit = $iter->first; ($fit) ; $fit= $iter->next) {
      my $syn= $self->getSynonyms($fit);
      my @pub= $self->getFeaturePubs($fit); 
      my $pub= (@pub ? "'".$pub[0]->title()."'" : '');
      print $outhandle join("\t", $fit->name, $fit->seqlen,
            $fit->type_id->name, $syn, $fit->feature_id, $pub, $ck), 
            "\n";
      }
    }
  print $outhandle "-"x60,"\n\n";  
}


1;
