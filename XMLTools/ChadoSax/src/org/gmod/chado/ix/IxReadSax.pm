
=head1 NAME

org::gmod::chado::ix::IxReadSax

=head1 DESCRIPTION

Read Chado XML into data records.

=head1 SYNOPSIS

  perl -M'org::gmod::chado::ix::IxReadSax' -e 'view;' -- \
    XORT/Config/dump_gene_local_id.xml

  use org::gmod::chado::ix::IxReadSax;
  my $rd= new org::gmod::chado::ix::IxReadSax(
    [ skip => [residues,md5checksum], ]
    );
  $rd->parse('mychado.xml');

  my $top= $rd->topnode();
  $top->printObj(0);
  my @allrecs= $top->getfeats();
  my @feats= $top->getfeats('feature');
   

IxReadSax.java provided initial parsing structure, and with effort
and luck will be co-developed with the Perl modules to do equivalent for
Java.

This parses input chado.xml into a structure of IxFeat objects.
Top level 'chado' record is now assumed, containing a list
of main 'feature' records (gene annotations, features, etc.)
The object structure is held in

  org::gmod::chado::ix::IxBase; - ancestor object
  org::gmod::chado::ix::IxFeat; - 'feature' record contains
       (a) hash of single value fields (id,name,..)
       (b) list of child sub-features
       (c) list of attributes (IxAttr)
       (d) list of feature locations (IxSpan)
       
  org::gmod::chado::ix::IxAttr;  - attribute (values)
  org::gmod::chado::ix::IxSpan; - simple feature location attribute (nbeg,nend)

Parsing moves some general definitions (cvterms, organisms,
publications, analysis records, ...) which are constant references to
all records to the top level chado node.  Feature node contents are
rearranged to make them a bit more usable objects.  

=head1 SEE ALSO

  org.gmod.chado.ix.IxReadSax.java
  org::gmod::chado::ix::IxFeat.pm;
  XORT::Dumper::DumperXML.pm;
  http://www.gmod.org/ 

=head1 AUTHOR

D.G. Gilbert, May 2003, gilbertd@indiana.edu

=cut

#-----------------

package org::gmod::chado::ix::IxReadSax;

use strict;

use org::gmod::chado::ix::IxFeat;
use org::gmod::chado::ix::IxAttr;
use org::gmod::chado::ix::IxSpan;

use Getopt::Long;    
use XML::Parser::PerlSAX;
use Exporter;
use vars qw/$VERSION $ROOT_NODE $debug @skipKeys @ISA @EXPORT /;
@ISA = qw(Exporter);
@EXPORT = qw(&view);

$VERSION = "0.5";
$ROOT_NODE='chado';
$debug= 0;

BEGIN {
  # some of these are useful - later // timelastmodified 
  # dec03 - drop residues  from skipset - let user decide w/ -skip opt
  ## need is_current for valid/old ids/dbxref/other
  ## need is_internal for data screening
  ## need is_analysis for "" ?
  @skipKeys= qw/
    locgroup 
    timeaccessioned 
    md5checksum 
    rank prank strand
    min max
    is_nend_partial is_nbeg_partial
    is_fmin_partial is_fmax_partial
    evidence_id
    organism_id 
    _appdata
    /;
}

=head1 METHODS

=item view(inputChado.xml)
 
  Example main callable method
 - makes new IxReadSax with input filename 
 - parses and dumps output in pseudo-asn1 for reading data structure

  perl -M'org::gmod::chado::ix::IxReadSax' -e 'view;' -- mychado.xml

  sample test with GMOD XORT (test data from may03)
  curl  'http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/gmod/schema/XMLTools/XORT/Config/dump_gene_local_id.xml?rev=1.1&content-type=text/plain' \
    > dump_gene_local_id.xml


  perl -I./ChadoSax/src -M'org::gmod::chado::ix::IxReadSax' -e'view;' -- \
    -skip=residues r3.2_16_xml/AE003583*.xml



=cut

sub view {

  my @skipf=();
  my $optok= Getopt::Long::GetOptions( 
    'debug!' => \$debug,
    #'outfile=s' => \$outf,
    'skipfeat=s' => \@skipf,
    );
  
  my $handler= new org::gmod::chado::ix::IxReadSax( 
    METHOD => 'view', # cant do like handleObj; need to wait till doc is finished
    debug => $debug,
    skip => \@skipf,
    );  

  $handler->parse(@main::ARGV);
  
 # my $topnode= $handler->topnode();
 # $topnode->printObj(0);
}


=item parse(@args)
  
  read and parse files or other input
  uses XML::Parser::PerlSAX::parse($args[0])
  
=cut

sub parse {
	my $self= shift;
        
  if (my($arg)= grep(/debug/,@_)) { $debug= ($arg=~/nodebug/) ? 0 : 1; }
  ## need flag for NO_CLEAR - keep all parsed docs ?
  ## probably too much for large docs
  my $zcat=`which zcat`;
  if ($? != 0) {$zcat=`which gzcat`;}
  chomp($zcat);
  
  foreach my $infile ( @_ ) {
    next if ($infile =~ m/^\-/); # option?
    warn "# IxReadSax parse <$infile>\n" if ($debug);
    my $err;
    local(*XFILE);
      ## new instance for each file, in case of eval{} errors
    my $parser = XML::Parser::PerlSAX->new( Handler => $self );
    $self->{infile}= $infile;
      
    if ($infile =~ /\.(gz|Z)$/ && open(XFILE,"$zcat $infile|")) {
      eval { $parser->parse( Source => { ByteStream => *XFILE} ); }; 
      $err= $@;
      close(XFILE);
      }
    elsif ($infile =~ /\.(bz2)$/ && open(XFILE,"bzcat $infile|")) {
      eval { $parser->parse( Source => { ByteStream => *XFILE} ); };
      $err= $@;
      close(XFILE);
      }
    else { 
      eval { $parser->parse( Source => { SystemId => $infile } ); };
      $err= $@;
      # $parser->parse( @_ );  # nogood
      }
    if ($err) {
      warn "#>> IxReadSax XML parse($infile) error: $err\n";
      $self->end_document('error='.$err);
      }	
    
    ## need to do here if have multiple files  
    if ($self->{METHOD} eq 'view' || $self->{METHOD} eq 'printObj' ) 
        { $self->topnode()->printObj(0); }
    
    }
	
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
	$self->{tag}= 'IxReadSax' unless (exists $self->{tag} );
	$debug= $self->{debug} if $self->{debug};
	$self->{idhash}= ();
	
	my @skips= @skipKeys; #? keep these always? and append user {skip} ?
	if (ref($self->{skip}) =~ /ARRAY/) { push(@skips, @{$self->{skip}}); }
  my %sh= map { $_,1; } @skips;
  $self->{skipkeys} = \%sh;
	
# 	$self->{views}= [ 'text/asn1', 'text/acode', 'text/xml;game' ]
# 		unless (exists $self->{views} );

}


=item getfeats([classTypes])

  return list of child sub-feature  
  classTypes - optional list of feature types to return
  getfeats('feature') - returns main feature list (e.g. gene records)
  
=cut

sub getfeats {
	my $self= shift;
  my $topnode= $self->topnode();
  return $topnode->getfeats(@_);
}

=item $obj= topnode()

  return top node of object hierachy; should be 'chado' feature now
   
=cut

sub topnode {
	my $self= shift;
  my $top= @{$self->{featstack}}[0];  #??
  $top= $self->{$ROOT_NODE} unless($top); #? always use $ROOT_NODE
  return $top;
}

sub getTopNode; *getTopNode = \&topnode; # java alias


=item parsing notes

 started from Java apr03 version parser, made major changes
 to account for new schema fields or missing data needed.
 
 added cv_id,cv,cvname handling for cvterm --
    <cvterm id="cvterm_4">
           <cv_id>
                  <cv id="cv_1">
                         <cvname>SO</cvname>
                  </cv>
           </cv_id>
           <name>mRNA</name>
    </cvterm>

note2: these are grouping 'features' not now checked:
  feature_evidence/evidence_id
  feature_evidence/../feature_relationship 
  feature_cvterm == go terms for gene-feature
  feature_evidence/../analysisfeature ==  scores for analyses
  feature_evidence/../featureloc/../srcfeature_id/feature/featureloc* == many parts
  
  skip these: featureloc/feature_id/feature/...

JUNE 03 variants:
  prediction_evidence, alignment_evidence replace feature_evidence
  added fmin, fmax replacements for nbeg, nend
  need to catch these containers:
     feature_synonym feature_relationship  feature_dbxref ? feature_cvterm ?  

     feature_synonym > should become an attribute of parent feature ?
       (encloses synonym, synonym_id tags)

=item XML handlers

handlers define for PerlSAX
and subs used in xml parsing

=cut

sub cleanval {
  my $self = shift;
  local $_ = shift;
  s/^\s+//; s/\s+$//;
  s/\n\s*/ /sg; #? or use some fake newline syntax like \\n
  return $_;
}

sub path {
  my $self = shift;
  my $xpath= join("/",@$self->{els},@_);
  return $xpath;
}  

sub start_document {
	my ($self)= @_;
  $self->clear() unless($self->{NO_CLEAR});

  if ($self->{handleObj}) {
    $self->{handleObj}->comment("parser: ".$self->{handleObj});
    my $fn= $self->{infile};
    $fn =~ s,^.*/,,;
    $self->{handleObj}->comment("source: $fn");
    #if (-r $fn) {
    #  # my $dt= POSIX::strftime($t);
    #  # $self->{handleObj}->comment("source-date: $dt");
    #  }
    }
}

sub end_document {
	my ($self,$err)= @_;
  ## need error handling - this is called on bad XML ??

## 		/^(feature|feature_evidence|prediction_evidence|alignment_evidence)$/ &&  do {  #|analysis 
  while (defined $self->{featstack} && @{$self->{featstack}}>1 ) {
    my $ft= pop( @{$self->{featstack}});
    warn "end_document pop: ".$ft->name()."/".$ft->{id}."\n" if $debug;
    my $parft= @{$self->{featstack}}[-1]; 
    $parft->add($ft);
    pop( @{$self->{genfeatstack}});
    $self->{curgenfeat}= @{$self->{genfeatstack}}[-1]; 
    
    ## test sep03
    if ( $self->{handleObj} && $parft == $self->{$ROOT_NODE} ) {
      $self->{handleObj}->handleObj(0, $ft, $err);
      }
		}	
		
  ## delete some of current document?? or wait for start if doing another ??
  		
}

sub characters {
	my ($self, $element)= @_;
	$self->{vals}{$self->{inel}} .= $element->{Data};
}

sub clear {
 	my ($self)= @_;
  
    ## more than these... fix me
    ## change storage of parsed elements to self->{els}->{$elname} ?
    ## keep main self->{main} vars limited to: idhash, featstack, vals, root, ..
    
  my @k= qw(
   idhash genfeatstack featstack
   curfeat curgenfeat vals
   $ROOT_NODE 
   feature feature_evidence prediction_evidence alignment_evidence
   analysis feature_cvterm cvterm cv db pub 
   synonym organism
   dbxref featureprop feature_synonym feature_dbxref
   );
   
  foreach (@k) { delete $self->{$_}; }
}


sub start_element {
	my ( $self, $element)= @_;
  my $name= $element->{Name};
  local $_= $name;
  my $elpar= $self->{inel};
  push(@{$self->{els}}, $elpar) if ($elpar);
  $self->{inel}= $_;
  $self->{vals}{$_}= '';
  $self->{elcount}{$_}++; # debug only
  return if ($self->{skipkids});

  my $nada= 0;
  SWITCH: {
  
		/^($ROOT_NODE|feature|feature_evidence|prediction_evidence|alignment_evidence|analysis|feature_cvterm|cvterm|cv|db|pub|synonym|organism)$/ &&  do { 
		  
      my $atid= $element->{Attributes}->{id}; 
      my $ft;
      
		    ## dont make another root ... may be handling several docs ??
		  if (/$ROOT_NODE/ && $self->{$ROOT_NODE}) {
       $ft= $self->{$ROOT_NODE};
        # $self->{idhash}{$atid}= $self->{$ROOT_NODE} if $atid;  
		    # last SWITCH;
		    }
      else {
        $ft= new org::gmod::chado::ix::IxFeat( 
               tag => $_, id => $atid, handler => $self);
         }
         
      $self->{$_}= $ft;
         ## atid should be uniq for each ft - keep hash of them in chado object?
      $self->{idhash}{$atid}= $ft if ($atid); #mostly for cvterm->name
      
      $self->{curgenfeat}= $ft;
      push( @{$self->{genfeatstack}}, $ft);
      
        # these are main feature objects...
      if (/^($ROOT_NODE|feature|feature_evidence|prediction_evidence|alignment_evidence)$/) { #|analysis
        $self->{curfeat}= $ft;
        push( @{$self->{featstack}}, $ft);
        }
      
      if (/^feature$/ && $elpar eq 'srcfeature_id') {
       $self->{srcfeature_id}= $atid; # save 
       }

			last SWITCH; 
			};  

	  /^feature_id$/ && do {
	    if ($elpar eq 'featureloc') { $self->{skipkids}= 'feature_id'; }
			last SWITCH; 
			};  

#		# handle cv_id ref to cv - has id attr if cv/cvname is defined
# 		/^(cv_id)$/ &&  do { 
#       my $atid= $element->{Attributes}->{id}; 
#       if ($atid) {
#         # my $cv= $self->{cvlist}{$atid}; #??
#         # my $cvset= $cv->get('cvname'); - need to prefix cvterm/name w/ cvset?
#         }
# 			last SWITCH; 
# 			};  
	
    /^(featureloc)$/ &&  do { 
      my $span= new org::gmod::chado::ix::IxSpan( tag => $_ , handler => $self);
      $self->{curfeat}->{span}= $span;
 		  ## $self->{curfeat}->addloc($span);
			last SWITCH; 
			};  
			
 		/^(dbname|accession|pkey_id|is_current|is_internal|is_analysis|pval|pub_id)$/ &&  do { 
			## summer03 -- xml dropped pkey_id, pval, dbname -- cvterm_id/cvterm instead
		  $self->{$_}= undef;
			last SWITCH; 
			};  
		  
		  ## jun03 added feature_cvterm, feature_synonym== attributes?
		  ## feature_cvterm is handled ok by nested cvterm/dbxref == GO terms + ids
		  ## or handle like featureprop ?
		  
		/^(dbxref|featureprop|feature_synonym|feature_dbxref)$/ &&  do { 
      my $atid= $element->{Attributes}->{id}; 
      my $attr= new org::gmod::chado::ix::IxAttr( tag => $_ , handler => $self);
      if ($atid) { 
        $attr->set( id => $atid); 
        $self->{idhash}{$atid}= $attr;  
        }
      $self->{$_}= $attr; #??
      # $self->{curattr}= $attr; #??
      # push( @{$self->{attrstack}}, $attr); #??  
			last SWITCH; 
			};  

		$nada= 1;
		}
  
}

sub setAttrs {
	my ( $self, $attr, @keys)= @_;
	foreach my $key (@keys) {
	  if (defined $self->{$key}) {
      my $val= $self->{$key};
      $attr->set( $key => $val);  
      $self->{$key} = undef; # not delete?
      }
    }
}

sub end_element {
	my ( $self, $element)= @_;
  my $name= $element->{Name};
  local $_= $name;
	my $elpar= $self->{inel} = pop(@{$self->{els}}); #== one above current $elem
  my $val = $self->cleanval($self->{vals}{$_});
  my $hasval= ($val =~ /\S/);
  if ( $self->{skipkids} ) {
    if ( $self->{skipkids} eq $name ) { $self->{skipkids}= undef; }
    else { return; }
    }
    
  my $nada= 0;
  SWITCH: {
		
 		/^(organism_id|rawscore)$/  &&  do { ##|program|programversion
		  $self->{curfeat}->set( $_ => $val ) if ($hasval && !$self->{skipkeys}->{$_});
 		  last SWITCH; };  
 		    
 		/^(type_id)$/ &&  do {  
 	  # //CAN BE INSIDE  pub OR feature OR feature_relationship OR synonym
		  if ($hasval ) { # && $val ne 'contains'
		    if ($elpar eq 'feature_relationship') {
		      ## skip
		      }
		    elsif ($elpar =~ /^(dbxref|featureprop|feature_synonym|feature_dbxref)$/) {
		      ## attributes now use type_id
 		      $self->{$elpar}->set( $_ => $val ) ;
		      }
		    
		    elsif ($self->{curgenfeat}->{tag} =~ /(pub|synonym|feature)/) {
		      #?? check for existing val? getting bad type_id vals for main feature
 		      $self->{curgenfeat}->set( $_ => $val ) ;
 		      }
 		    else {
 		      warn "UNKNOWN GENFEAT: $_ = $val\n"; # if $debug>0;
 		      }
 		    }
 		  last SWITCH; };  

 		/^(residues)$/ &&  do {  
		  if ( $hasval && ! $self->{skipkeys}->{$_}) {
		    $self->{curfeat}->set( $_ => $val );
		    $self->{curfeat}->set( 'residuetype' => 'cdna' ); #? is this correct
 		    }
 		  last SWITCH; };  
 		    
 		/^(name|uniquename|miniref|program|sourcename|programversion|seqlen|cvterm_id|analysis_id|timelastmodified)$/ &&  do {  
 		    ## general feature values - should be only 1/feature
		  if ($hasval) {
		    if ($self->{curgenfeat}) {
		      $self->{curgenfeat}->set( $_ => $val ); #?
		      }
 		    else {
 		      warn "UNSAVED $_ = $val\n";
 		      }
 		    }
 		  last SWITCH; };  
 		  
 		/^(cvname)$/ &&  do {  ## changed from cvname to name; summer'03
		  if ($hasval && $self->{cv}) {
 		    $self->{cv}->set( $_ => $val );
 		    }
 		  last SWITCH; };  
 		  
 		/^(cv_id)$/ &&  do {  
		  if ($hasval && $self->{cvterm}) {
 		    $self->{cvterm}->set( $_ => $val );
 		    }
 		  last SWITCH; };  

		/^(db_id)$/ &&  do {  
		  if ($hasval && $self->{dbxref}) {
 		    $self->{dbxref}->set( $_ => $val );
 		    }
 		  last SWITCH; };  


## 		//PUTTING PARAMETERS INTO OBJECTS
## IxFeat set:
##		/^($ROOT_NODE|feature|analysis|cvterm|cv|pub|organism)$/ 
      # synonym not top level...
      
 		/^(organism|pub|cvterm|cv|db|analysis|feature_cvterm|synonym)$/ &&  do {  
      ## // top level chado params
 		  ## here, if cvterm and cv_id has id attrib, add link to cv?
 		  ## moved analysis 'feature' to top level chado list ? == organism/pub/...
 		  
			my $ft= $self->{$_}; # or curgenfeat   or pop(genfeatstack)
			$self->{$_}= undef;
			pop( @{$self->{genfeatstack}});

			## trick here - push id of this into $elpar value
			unless($self->{vals}{$elpar} =~ /\S/) {
			  $self->{vals}{$elpar}= $ft->{id};
			  }
	
			if (/(synonym|feature_cvterm)$/) {
        $self->{curfeat}->add($ft);
			  }
			else { 
			  ## there are some 'stutters' in XORT output - got lots of duplicate cvterm defs for
			  ## chromosome_arm == cvterm_210 
			  
			  $self->{$ROOT_NODE}->add($ft); 
			  }
			
			$self->{curgenfeat}= @{$self->{genfeatstack}}[-1]; 
 		  last SWITCH; };  
      
 		/^(feature|feature_evidence|prediction_evidence|alignment_evidence)$/ &&  do {  #|analysis 
      my $ft= pop( @{$self->{featstack}});
      my $parft= @{$self->{featstack}}[-1]; 
      $parft->add($ft);
			$self->{$_}= undef;
			$self->{curfeat}= $parft; 
			pop( @{$self->{genfeatstack}});
			# $self->{curgenfeat}= $parft; #?
			$self->{curgenfeat}= @{$self->{genfeatstack}}[-1]; 
			
			## test sep03
			if ( $self->{handleObj} && $parft == $self->{$ROOT_NODE} ) {
			  $self->{handleObj}->handleObj(0, $ft);
			  }
			  
			  ## cant do printObj till all of doc read and ROOT has all toplevel items
			  ## or revise printObj to print as they come (toplevel items)
# 			elsif ( $self->{printObj} && $parft == $self->{$ROOT_NODE} ) {
# 			  $ft->printObj(1);
# 			  }
			  
 		  last SWITCH; };  


 		/^(fmin|fmax|strand|nbeg|nend|srcfeature_id)$/ &&  do { 
##		//FEATURELOC 		  
##  jun02 - fmin,fmax replace nbeg,nend
 		  unless( $hasval ) {
 		    $val= $self->{$_}; $hasval= ($val =~ /\S/);
 		    }
 		  if ( $hasval ) { 
        s/srcfeature_id/src/;
        my $span= $self->{curfeat}->{span};
        $span->set( $_ => $val);
 		    # $self->{$_}= $val; 
 		    }
 		  else {
 		    # look for nested feature id=xxx - see feature/start
 		    }
 		  last SWITCH; }; 
 		  
 		/^(featureloc)$/ &&  do { 
      my $span= $self->{curfeat}->{span};
 		  $self->{curfeat}->addloc($span);
      delete $self->{curfeat}->{span};
      
 		  ## this is not good - have feature/featureloc embedded inside other featureloc
      ## cant use set, need list to keep all IxSpan 
# 		  if ($self->{curfeat}->get('span')) {
#  		    $self->{curfeat}->set( 'altspan' => $span );
# 		    }
# 		  else {
#  		    $self->{curfeat}->set( 'span' => $span );
#  		    }
 		  last SWITCH; }; 
	 	      
##		//ATTRIB

#  		/^(feature_dbxref)$/ &&  do {  
# 			$self->{curfeat}->addattr($self->{$_});
#       $self->{$_}= undef;
#  		  last SWITCH; };  

#  		/^(dbxref_id)$/ &&  do {  
#  		  my $attr= $self->{$_};
#  		  $attr->setattr( $val) if $hasval; #? and not get() ?
#  		  
# #  		  my $fattr= $self->{feature_dbxref};
# #  		  if ($fattr) {
# #  		    $fattr->set( attr => $attr);
# # 			  #	//THIS dbxref_id IS INSIDE A feature_dbxref
# # 			  #	//IT IS NOW SUBSUMED
# #  		    }
# #  		  elsif
#  		  if ( $self->{curfeat} ) {
# #				//ADD TO FEATURE
#  			  $self->{curfeat}->addattr($attr);
#  		    }
# 	    $self->{$_}= undef;
#  		  last SWITCH; };  

 		/^(dbxref)$/ &&  do {  
      # now also in attrstack
 		  my $attr= $self->{$_};
 		  my $acc= $self->{accession};

 		  my $db = $self->{dbname}; ## change to db/db_id
 		  unless ($db) { 
 		    my $key="db_id"; 
 		    my $val= $self->{$key}; 
 		    if ($val) { ($key,$db)= $self->{$ROOT_NODE}->id2name($key,$val); }
 		    }

 		  my $dbid= ($db) ? "$db:$acc" : $acc;
 		  $attr->setattr( $dbid); #  name =>

      $self->setAttrs($attr, qw(is_current is_internal is_analysis));
#  		  my $is_current= $self->{is_current};
#  		  $attr->set( is_current => $is_current) if defined $is_current;  
#       $self->{is_current}= undef;

#  		  my $dbxattr= $self->{dbxref_id};
#   		if ($dbxattr) { $dbxattr->setattr( $attr ); }
#  		  elsif
 		  if ( $self->{curgenfeat} ) {
 			  $self->{curgenfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
 		  last SWITCH; };  
      
    
		/^(feature_dbxref)$/ &&  do {  
		  ##mar04: need feature_dbxref instead of dbxref_id/name to get is_current
      my $attr= $self->{$_};
      $self->setAttrs($attr, qw(dbxref_id is_current is_internal));
 		  if ( $self->{curgenfeat} ) { 
 			  $self->{curgenfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
      last SWITCH; };  
	  
		/^(feature_synonym)$/ &&  do {  ## or synonym -- done by synonym == par->add(ft)
      # now also in attrstack
 		  my $attr= $self->{$_};

      $self->setAttrs($attr, qw(synonym_id pub_id is_current is_internal is_analysis));
 		  
 		  ## synonym_id always seems to enclose only synonym struct 
# # 		  my $synonym_id= $self->{synonym_id};
#  		  $attr->set( synonym_id => $synonym_id) if $synonym_id;  
#       $self->{synonym_id}= undef;
#       ##?? change id=feature_synonym_1894 to id=synonym_1894 
#       
#       ## synonym struct is: id,name,type_id
# #  	    my $synonym= $self->{synonym};
# #  		  $attr->set( synonym => $synonym) if $synonym;  
# 
#  		  my $pub_id= $self->{pub_id};
#  		  $attr->set( pub_id => $pub_id) if $pub_id;  
# 
#  		  my $is_current= $self->{is_current};
#  		  $attr->set( is_current => $is_current) if defined $is_current;  
#       $self->{is_current}= undef;
      
 		  if ( $self->{curgenfeat} ) { # was curfeat
 			  $self->{curgenfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
 		  last SWITCH; };  
      
 		/^(featureprop)$/ &&  do {  
       # now also in attrstack
		  my $attr= $self->{$_};
 		  
 		  my $pkey_id= $self->{type_id}; ## new
 		  unless($pkey_id) { $pkey_id= $self->{pkey_id}; } ## old
 		  $attr->set( pkey_id => $pkey_id) if $pkey_id;  
 		  
 		  my $pval= $self->{value};
 		  unless($pval) { $pval= $self->{pval}; } # now is 'value'
 		  $attr->setattr( $pval) if $pval;  # pval => $pval
 		  
      $self->setAttrs($attr, qw(pub_id is_current is_internal is_analysis));

# 		  my $pub_id= $self->{pub_id};
#  		  $attr->set( pub_id => $pub_id) if $pub_id;  
# 
#  		  my $is_current= $self->{is_current};
#  		  $attr->set( is_current => $is_current) if defined $is_current;  
#       $self->{is_current}= undef;

 		  if ( $self->{curgenfeat} ) {
#				//ADD TO FEATURE -- was curfeat - use curgenfeat instead?
 			  $self->{curgenfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
 		  last SWITCH; };  


 		/^(dbname|accession|value|is_current|is_internal|is_analysis|pkey_id|pval|pub_id|dbxref_id|synonym_id)$/ &&  do { 
##		//ATTRIB FIELDS -- dbname, pkey, pval have gone
 		  $self->{$_}= $val if ($hasval); ## ($hasval) ? $val : ''; 
 		  # urk, some have cvterm inside - need to keep
 		  last SWITCH; }; 

		$nada= 1;
		}
		
		
  if ($nada && ! $self->{skipkeys}->{$name}) { ##&& $hasval
    $self->{$ROOT_NODE}->set('unused_'.$name => $self->{elcount}{$name},  replace=>1); #??
    if ($hasval) {
      my $attr= new org::gmod::chado::ix::IxAttr( tag => $name, handler => $self);
 	    $attr->setattr( $val);
 	    #? $attr->set( unused => 1);
      $self->{curgenfeat}->addattr( $attr); #? may cause confusion
  	  # warn "# unused <$name>$val</$name>\n" if $debug>1;
      }
	  }	

  
}


1;
