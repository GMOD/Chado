#!/usr/bin/perl

package Chado::Affymetrixdchip;
use lib 'lib';
use Chado::AutoDBI;
use base 'Chado::DBI';
use Class::DBI::View qw(TemporaryTable);
use Class::DBI::Pager;

Chado::Affymetrixdchip->table('affymetrixdchip');

Chado::Affymetrixdchip->columns(All => qw(
  elementresult_id
  element_id
  quantification_id
  subclass_view
  signal
  se
  apcall
                                         ));

Chado::Affymetrixdchip->sequence('public.elementresult_elementresult_id_seq');

sub id { shift->elementresult_id }

Chado::Affymetrixdchip->has_a( element_id => 'Chado::Element' );

sub element {
  return shift->element_id
}

Chado::Affymetrixdchip->has_a( quantification_id => 'Chado::Quantification' );

sub quantification {
  return shift->quantification_id
}

#------------
package main;

use lib 'lib';
use strict;
use Bio::Expression::MicroarrayIO;
use Data::Dumper;
use Term::ProgressBar;
use Log::Log4perl;
Log::Log4perl::init('load/etc/log.conf');

my $LOG = Log::Log4perl->get_logger('load_affyxls');

my $arraydesigntype = shift @ARGV; $arraydesigntype ||= 'U133';
my $arrayfile = shift @ARGV;

Chado::Feature->set_sql(affy_probesets => qq{
  SELECT feature.name,feature.feature_id,element.element_id FROM feature,element,arraydesign WHERE
  arraydesign.name = '$arraydesigntype' and feature.feature_id = element.feature_id
});

my $affx = Bio::Expression::MicroarrayIO->new(
						-file     => $arrayfile,
						-format   => 'dchipxls', #dchipxls
					   );

$LOG->debug("created new Bio::Expression::MicroarrayIO $affx");

while(my $arrayio = $affx->next_array){
  my @txn = ();
  last unless $arrayio->id;

  print STDERR "loading array ".$arrayio->id."\n";
  $LOG->info("loading array: ".$arrayio->id);

  my $cvterms;
  my $sample_id;
  my $chip_id;
  my $newchip = 0;

  #we can do this on filename or arrayname.
  #if($arrayio->id =~ /^(\d+)\-(\d+)\-(\S+)/){
  if($arrayfile =~ m!/!){
    #has leading directory and cvterms
    if($arrayfile =~ /^.*\/(\d+)\-(\d+)\-(\S+)/){
      $chip_id   = $1;
      $sample_id = $2;
      $cvterms   = $3;
    #has leading directory
    } elsif($arrayfile =~ /^.*\/(\d+)\-(\d+)/){
      $chip_id   = $1;
      $sample_id = $2;
    }
  } else {
    #has cvterms
    if($arrayfile =~ /^(\d+)\-(\d+)\-(\S+)/){
      $chip_id   = $1;
      $sample_id = $2;
      $cvterms   = $3;
    #has nothing
    } elsif($arrayfile =~ /^(\d+)\-(\d+)/){
      $chip_id   = $1;
      $sample_id = $2;
    }
  }

  $LOG->info("chip_id: $chip_id");
  $LOG->info("sample_id: $sample_id");

  my %cvterm = make_cvterms($cvterms);
  $LOG->info("cvterms: ".join(', ', keys %cvterm));
  #might want to break here if %cvterm is undef (likely due to missing/malformed cvterm line in array file)

  ##############################
  # load feature and element ids
  ##############################
  my($sth,%feature);
  my $sth;
  $LOG->debug("caching features...");
  $sth = Chado::Feature->sql_affy_probesets;
  $sth->execute;
  while(my $row = $sth->fetchrow_hashref){
    #warn $row->{name};
	$feature{$row->{name}}{feature_id} = $row->{feature_id};
	$feature{$row->{name}}{element_id} = $row->{element_id};
  }
  $LOG->debug("cached features: ".scalar(keys %feature));

  my($array)     = Chado::Arraydesign->search(name => $arraytype);
  ($array)     ||= Chado::Arraydesign->search(name => 'unknown');
  $LOG->debug("loaded record for array type: ".$array->name);

  my($nulltype)               = Chado::Cvterm->search( name => 'null' );
  my($oligo)                  = Chado::Cvterm->search( name => 'microarray_oligo' );
  die "couldn't find ontology term 'microarray_oligo', did you load the Sequence Ontology?" unless ref($oligo);
  $LOG->debug("loaded records for generic cvterms");

  my($human)                  = Chado::Organism->search( common_name => 'Human' );
  $LOG->debug("loaded record for organism");
  my $operator                = Chado::Contact->find_or_create( { name => 'UCLA Microarray Core' });
  $LOG->debug("loaded record for hybridization operator");
  my $operator_quantification = Chado::Contact->find_or_create( { name => $ENV{USER} });
  $LOG->debug("loaded record for database operator");
  my $analysis                = Chado::Analysis->find_or_create({ name => 'keystone normalization', program => 'dChip unix', programversion => '1.0'});
  $LOG->debug("loaded record for normalization algorithm");

  my $protocol_assay          = Chado::Protocol->find_or_create({ name => 'default assay protocol', type_id => $nulltype });
  my $protocol_acquisition    = Chado::Protocol->find_or_create({ name => 'default acquisition protocol', type_id => $nulltype });
  my $protocol_quantification = Chado::Protocol->find_or_create({ name => 'default quantification protocol', type_id => $nulltype });
  $LOG->debug("loaded records for protocols");

  push @txn, $operator;
  push @txn, $operator_quantification;
  push @txn, $analysis;
  push @txn, $protocol_assay;
  push @txn, $protocol_acquisition;
  push @txn, $protocol_quantification;

  my $biomaterial = Chado::Biomaterial->find_or_create({ name => $sample_id , taxon_id => $human});
  if(!$biomaterial->description and $arrayio->id){
    $biomaterial->description($arrayio->id);
    $biomaterial->update;
    $newchip++ ;
  }
  $LOG->debug("biomaterial_id: ".$biomaterial->id);
  push @txn, $biomaterial;

  foreach my $cvterm (keys %cvterm){
    my($chado_cvterm) = Chado::Cvterm->search(name => $cvterm);
    if(!$chado_cvterm){
      my($chado_dbxref) = Chado::Dbxref->search(accession => $cvterm);
      my $fatal = undef;
      ($chado_cvterm) = Chado::Cvterm->search(dbxref_id => $chado_dbxref)
        or $fatal = "couldn't find cvterm for $cvterm, you need to create it";
      if($fatal){
        $LOG->fatal($fatal) and die $fatal;
      }
    }

	my $biomaterialprop = Chado::Biomaterialprop->find_or_create({
                                                          biomaterial_id => $biomaterial->id,
                                                          type_id => $chado_cvterm,
                                                          value => $cvterm{$cvterm},
                                                         });
    $LOG->info("biomaterial has prop: ". $chado_cvterm->name .", value: ". $cvterm{$cvterm});
    push @txn, $biomaterialprop;
  }

  my $assay = Chado::Assay->find_or_create({
									array_id => $array->id,
									operator_id => $operator->id,
                                    name => $chip_id,
									protocol_id => $protocol_assay->id,
								   });
  if($arrayio->id and !$assay->description){
    $assay->description($arrayio->id);
    $assay->update;
    $newchip++;
  }
  $LOG->debug("assay_id: ".$assay->id);
  push @txn, $assay;

  my $assay_biomaterial = Chado::Assay_Biomaterial->find_or_create({
                                                            biomaterial_id => $biomaterial->id,
                                                            assay_id => $assay->id,
                                                           });
  push @txn, $assay_biomaterial;

  my $acquisition = Chado::Acquisition->find_or_create({
												assay_id => $assay->id,
												protocol_id => $protocol_acquisition->id,
											   });
  if($arrayio->id and !$acquisition->name){
    $acquisition->name($arrayio->id);
    $acquisition->update;
    $newchip++;
  }
  push @txn, $acquisition;

  my $quantification = Chado::Quantification->find_or_create({
													  acquisition_id => $acquisition->id,
													  protocol_id => $protocol_acquisition->id,
													  operator_id => $operator_quantification->id,
													  analysis_id => $analysis->id,
													 });
  if($arrayio->id and !$quantification->name){
    $quantification->name($arrayio->id);
    $quantification->update;
    $newchip++;
  }
  push @txn, $quantification;


  my $total = scalar($arrayio->each_featuregroup);
  my $progress = Term::ProgressBar->new({name  => 'Probesets loaded',
                                            count => $total,
                                            ETA   => 'linear'
                                           });
  $progress->max_update_rate(1);
  my $progress_update = 0;

  $progress->message("already loaded") unless $newchip;
  $progress->update($total) and next unless $newchip;

  my $c = 0;
  $LOG->info("featuregroups loading...");
  foreach my $featuregroup ($arrayio->each_featuregroup){
    $c++;
    $progress_update = $progress->update($c) if($c > $progress_update);
    $progress->update($c) if($c >= $progress_update);
    $progress->update($total) if($progress_update >= $total);


	my $feature  = $feature{$featuregroup->id}{feature_id};
	my $element  = $feature{$featuregroup->id}{element_id};


    if(!$feature){
      #the feature may exist, but not be linked to an element (ergo array) yet.
      ($feature) = Chado::Feature->search(name => $featuregroup->id);

      if(!ref($feature)){
        $feature = Chado::Feature->find_or_create({
                                                   organism_id => $human,
                                                   type_id => $oligo,
                                                   name => $featuregroup->id,
                                                   uniquename => 'Affy:Transcript:HG-'. $arraydesigntype .':'. $featuregroup->id,
                                                  });

        $progress->message("creating feature: ".$featuregroup->id);
      }
      $feature{$featuregroup->id}{feature_id} = $feature->id;
      push @txn, $feature;
    }

	if(!$element){
      $progress->message("creating element for: ".$featuregroup->id);

	  $element = Chado::Element->find_or_create({
												 feature_id => $feature,
												 array_id => $array,
												 subclass_view => 'affymetrixdchip',
												});
	  $feature{$featuregroup->id}{element_id} = $element->id;
      push @txn, $element;
	}

	my $ad = Chado::Affymetrixdchip->create({
											 element_id => $element,
											 quantification_id => $quantification->id,
											 subclass_view => 'affymetrixdchip',
											 signal => $featuregroup->quantitation,
											 apcall => $featuregroup->presence,
											 se => 0,
								});
    push @txn, $ad;
  }
  $LOG->info("featuregroups loaded: ". $c);

  $LOG->info("transaction commiting...");
  $_->dbi_commit foreach @txn;
  $LOG->info("transaction commited...");
}

sub make_cvterms {
  my $cvterm_string = shift;

  ####
  # alert! this prevents unannotated files from being loaded.
  ####
  #warn "no cvterms!" and exit -1 unless $cvterms;
  ####
  #
  ####

  $cvterm_string ||= 'null';
  my @cvterms = split /[\;\,]/, $cvterm_string;
  #s/([A-Z]{1,7})(\d{1,7})/$1:$2/g foreach @cvterms;

  my %cvterm;
  @cvterms = map {_remap_cvterm($_)} @cvterms;
  foreach my $cvterm (@cvterms){
	my $val = undef;
	if($cvterm =~ /\@(.+)$/){
	  $val = $1;
	  $cvterm =~ s/^(.+)\@.+$/$1/;
	}

    $cvterm =~ /^(\D*?)(\d*?)$/g;
    next unless $1;
    $cvterm = $2 ? "$1:$2" : $1;
    $cvterm =~ s/:+/:/g while $cvterm =~ /::/;
    $cvterm{$cvterm} = $val;
  }
  return %cvterm;
}

#this is a mapping table for legacy annotation IDs based on GUSDB,
#and is only for internal use at UCLA.
sub _remap_cvterm {
  my $cvterm_id = shift;

  my %map = (
			 2   => 'MA:0000104',
			 4   => 'CL:0000138', #chondrocyte
			 23  => 'MA:0001359',
			 25  => 'MA:0000164',
			 26  => 'MA:0000165',
			 49  => 'MA:0000164', #heart
			 55  => 'MA:0000116',
			 56  => 'MA:0000120',
			 63  => 'MA:0000176',
			 66  => 'MA:0000129',
			 76  => 'CL:0000096', #leukocyte, changed to neutrophil
			 93  => 'CL:0000492', #helper T
			 102 => 'CL:0000576', #monocyte
			 114 => 'MA:0000141',
			 115 => 'MA:0000142',
			 118 => 'MA:0000145',
			 124 => 'MA:0000517',
			 129 => 'MA:0000167',
			 130 => 'MA:0000168',
			 136 => 'MA:0000179',
			 137 => 'MA:0000183',
			 144 => 'MA:0000198',
			 149 => 'MA:0000216',
			 168 => 'MA:0000335',
			 173 => 'MA:0000337',
			 175 => 'MA:0000339',
			 177 => 'MA:0000352',
			 179 => 'MA:0000346',
			 185 => 'MA:0000353',
			 190 => 'MA:0000358',
			 193 => 'MA:0000368',
			 196 => 'MA:0000384',
			 197 => 'MA:0000386',#placenta
			 200 => 'MA:0000389',
			 204 => 'MA:0000411',
			 207 => 'MA:0000415',
			 211 => 'MA:0000134',
			 223 => 'fetus',#fetus
             fetal => 'fetus',
			 233 => 'MA:0000404',
			 238 => 'MA:0000441',
			 247 => 'MA:0000813',
			 249 => 'MA:0000887',
			 252 => 'MA:0000893',
			 253 => 'MA:0000945',
			 254 => 'MA:0000188',
			 255 => 'MA:0000905',
			 256 => 'MA:0000916',
			 257 => 'MA:0000913',
			 258 => 'MA:0000941',
			 261 => 'CL:0000127',#astrocyte
			 262 => 'CL:0000128',#oligodendrocyte
			 263 => 'CL:0000030',#glioblast
			 266 => 'CL:0000031',#neuroblast
			 268 => 'CL:0000065',#ependymal
			 323 => 'MA:0001537',
			 591 => 'unknown',#unknown
			 629 => 'MPATH:458',#normal
			 632 => 'Schwannoma',#schwannoma
			 638 => 'meningioma',#meningioma
			 647 => 'sarcoma',#sarcoma
			 657 => 'oligodendroglioma',#oligodendroglioma
			 668 => 'adenocarcinoma',#adenocarcinoma
			 692 => 'medulloblastoma',#medulloblastoma
			 695 => 'astrocytoma',#astrocytoma
			 696 => 'glioblastoma',#glioblastoma
			 719 => 'obese',#obese
			 720 => 'asthma',#asthma
			 721 => ['morbid','obese'],#morbidly obese
			 722 => 'COPD',#COPD
			);

  return ref $map{$cvterm_id} eq 'ARRAY' ? @{$map{$cvterm_id}}
           : defined $map{$cvterm_id}    ? $map{$cvterm_id}
           : $cvterm_id;
}
