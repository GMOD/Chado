
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

# use vars qw/ $VERSION %skipKeys /;
use XML::Parser::PerlSAX;
use Exporter;
use vars qw/$VERSION $ROOT_NODE $debug @skipKeys @ISA @EXPORT /;
@ISA = qw(Exporter);
@EXPORT = qw(&view);

$VERSION = "0.1";
$ROOT_NODE='chado';
$debug= 0;

BEGIN {
  # some of these are useful - later
 @skipKeys= qw/
    locgroup 
    timelastmodified timeaccessioned 
    residues md5checksum 
    rank prank strand
    is_nend_partial is_nbeg_partial
    min max
    is_current is_analysis
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

  perl -M'org::gmod::chado::ix::IxReadSax' -e 'view;' -- dump_gene_local_id.xml

=cut

sub view {
  # my $fn= shift @main::ARGV;  
  my $handler= new org::gmod::chado::ix::IxReadSax(); # (@_)
  $handler->parse(@main::ARGV);
  my $topnode= $handler->topnode();
  $topnode->printObj(0);
}


=item parse(@args)
  
  read and parse files or other input
  uses XML::Parser::PerlSAX::parse($args[0])
  
=cut

sub parse {
	my $self= shift;
  my $parser = XML::Parser::PerlSAX->new( Handler => $self );

  my ($infile)= @_;
#   warn("parsing <"+$infile+">\n") if ($debug);

  local(*XFILE);
	if ($infile =~ /\.(gz|Z)$/ && open(XFILE,"gzcat $infile|")) {
		$parser->parse( Source => { ByteStream => *XFILE} ); 
		close(XFILE);
		}
	else { 
	  $parser->parse( Source=>{SystemId=>$infile} ); # calls parsefile(filename)
		# $parser->parse( @_ );  # nogood
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
	
	my @skips= @skipKeys;
	if (ref($self->{skip}) =~ /ARRAY/) { @skips= @{$self->{skip}}; }
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

}

sub end_document {
	my ($self)= @_;

}

sub characters {
	my ($self, $element)= @_;
	$self->{vals}{$self->{inel}} .= $element->{Data};
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
  
		/^($ROOT_NODE|feature|feature_evidence|analysis|cvterm|cv|pub|organism)$/ &&  do { 
		  
      my $atid= $element->{Attributes}->{id}; 
      my $ft= new org::gmod::chado::ix::IxFeat( 
               tag => $_, id => $atid, handler => $self);
      $self->{$_}= $ft; #??
      $self->{curgenfeat}= $ft;
      push( @{$self->{genfeatstack}}, $ft);
      if (/^($ROOT_NODE|feature|feature_evidence)$/) { #|analysis
        $self->{curfeat}= $ft;
        push( @{$self->{featstack}}, $ft);
        }
      ## atid should be uniq for each ft - keep hash of them in chado object?
      $self->{idhash}{$atid}= $ft; #mostly for cvterm->name
      
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
			
 		/^(dbname|accession|pkey_id|pval|pub_id)$/ &&  do { 
		  $self->{$_}= undef;
			last SWITCH; 
			};  
		  
		/^(dbxref|dbxref_id|featureprop)$/ &&  do { #feature_dbxref|
      my $atid= $element->{Attributes}->{id}; 
      my $attr= new org::gmod::chado::ix::IxAttr( tag => $_ , handler => $self);
      if ($atid) { 
        $attr->set( id => $atid); 
        $self->{idhash}{$atid}= $attr;  
        }
      # push( @$self->{attr}, $attr);
      # $self->{curattr}= $attr;
      $self->{$_}= $attr; #??
			last SWITCH; 
			};  

		$nada= 1;
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
		
#	  //SINGLE PARAMETER ELEMENTS

 		/^(uniquename|organism_id|rawscore)$/  &&  do { ##|program|programversion
		  $self->{curfeat}->set( $_ => $val ) if ($hasval && !$self->{skipkeys}->{$_});
 		  last SWITCH; };  
 		    
 		/^(type_id)$/ &&  do {  
 	  # //CAN BE EITHER INSIDE A pub OR A feature OR a feature_relationship
		  if ($hasval && $val ne 'contains') {
		    if ($elpar eq 'feature_relationship') {
		      ## skip
		      }
		    elsif ($self->{curgenfeat}->{tag} =~ /(pub|feature)/) {
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
		    $self->{curfeat}->set( 'residuetype' => 'cdna' );
 		    }
 		  last SWITCH; };  
 		    
 		    ## general feature values - should be only 1/feature
 		/^(name|miniref|program|programversion)$/ &&  do {  
		  if ($hasval) {
		    if ($self->{curgenfeat}) {
		      $self->{curgenfeat}->set( $_ => $val ); #?
		      }
 		    else {
 		      warn "UNSAVED $_ = $val\n";
 		      }
 		    }
 		  last SWITCH; };  
 		  
 		/^(cvname)$/ &&  do {  
		  if ($hasval && $self->{cv}) {
 		    $self->{cv}->set( $_ => $val );
 		    }
 		  last SWITCH; };  
 		  
 		/^(cv_id)$/ &&  do {  
		  if ($hasval && $self->{cvterm}) {
 		    $self->{cvterm}->set( $_ => $val );
 		    }
 		  last SWITCH; };  


## 		//PUTTING PARAMETERS INTO OBJECTS
## IxFeat set:
##		/^($ROOT_NODE|feature|analysis|cvterm|cv|pub|organism)$/ 

 		/^(organism|pub|cvterm|cv|analysis)$/ &&  do {  
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
			  
			$self->{$ROOT_NODE}->add($ft);
			$self->{curgenfeat}= @{$self->{genfeatstack}}[-1]; #? need to pop last
 		  last SWITCH; };  
      
 		/^(feature|feature_evidence)$/ &&  do {  #|analysis 
      my $ft= pop( @{$self->{featstack}});
      my $parft= @{$self->{featstack}}[-1]; 
      $parft->add($ft);
			$self->{$_}= undef;
			$self->{curfeat}= $parft; 
			pop( @{$self->{genfeatstack}});
			$self->{curgenfeat}= $parft; #?
 		  last SWITCH; };  

##		//FEATURELOC 		  
 		/^(nbeg|nend|srcfeature_id)$/ &&  do { 
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

 		/^(dbxref_id)$/ &&  do {  
 		  my $attr= $self->{$_};
 		  $attr->setattr( $val) if $hasval; #? and not get() ?
 		  
#  		  my $fattr= $self->{feature_dbxref};
#  		  if ($fattr) {
#  		    $fattr->set( attr => $attr);
# 			  #	//THIS dbxref_id IS INSIDE A feature_dbxref
# 			  #	//IT IS NOW SUBSUMED
#  		    }
#  		  elsif
 		  if ( $self->{curfeat} ) {
#				//ADD TO FEATURE
 			  $self->{curfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
 		  last SWITCH; };  

 		/^(dbxref)$/ &&  do {  
 		  my $attr= $self->{$_};
 		  my $db = $self->{dbname};
 		  my $acc= $self->{accession};
 		  my $dbid= ($db) ? "$db:$acc" : $acc;
 		  $attr->setattr( $dbid); #  name =>

 		  my $dbxattr= $self->{dbxref_id};
  		if ($dbxattr) { $dbxattr->setattr( $attr ); }
 		  elsif ( $self->{curfeat} ) {
#				//ADD TO FEATURE
 			  $self->{curfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
 		  last SWITCH; };  

 		/^(featureprop)$/ &&  do {  
 		  my $attr= $self->{$_};
 		  my $pkey_id= $self->{pkey_id};
 		  $attr->set( pkey_id => $pkey_id) if $pkey_id;  
 		  my $pval= $self->{pval};
 		  $attr->setattr( $pval) if $pval;  # pval => $pval
 		  my $pub_id= $self->{pub_id};
 		  $attr->set( pub_id => $pub_id) if $pub_id;  

 		  if ( $self->{curfeat} ) {
#				//ADD TO FEATURE
 			  $self->{curfeat}->addattr($attr);
 		    }
	    $self->{$_}= undef;
 		  last SWITCH; };  


##		//ATTRIB FIELDS
 		/^(dbname|accession|pkey_id|pval|pub_id)$/ &&  do { 
 		  $self->{$_}= $val if ($hasval); ## ($hasval) ? $val : ''; 
 		  # urk, some have cvterm inside - need to keep
 		  last SWITCH; }; 

		$nada= 1;
		}
		
		
  if ($nada && ! $self->{skipkeys}->{$name}) { ##&& $hasval
    $self->{$ROOT_NODE}->set('unused_'.$name => $self->{elcount}{$name}); #??
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
