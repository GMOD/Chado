#!/usr/bin/perl -w
use XML::DOM;

=item C<create_ch_stock>

 CREATE stock element
 params
 doc - XML::DOM::Document required
 uniquename - string required
 type_id - string or XML::DOM cvterm element required Note: if string will
           default to using FlyBase miscellaneous cv unless a cvname is provided
 cvname - string optional to specify a cv other than FlyBase miscellaneous CV for the type_id
          do not use if providing a cvterm element to type_id
 organism_id - XML::DOM organism element required if no genus and species
 genus - string required if no organism
 species - string required if no organism
 dbxref_id - XML::DOM dbxref element optional
 name - string optional
 description sting optional
 is_obsolete - boolean 't' or 'f' default = 'f' optional
 with_id - boolean optional if 1 then stock_id element is returned

=item C<create_ch_stock_dbxref>

 CREATE stock_dbxref element
 params
 doc - XML::DOM::Document required
 dbxref_id - XML::DOM dbxref element - required unless accession and db provided
 accession - string required unless dbxref_id provided
 db_id - string = db name or XML::DOM db element required unless dbxref_id provided
 version - string optional
 description - string optional
 is_current - string 't' or 'f' boolean default = 't' so don't pass unless
              this should be changed

=item C<create_ch_stock_pub>

 CREATE stock_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of stock_pub
      or just appending the pub element to stock_pub if that is passed 
 params
 doc - XML::DOM::Document required
 pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
 uniquename - string required
 type_id - string from pub type cv or XML::DOM cvterm element optional unless 
        creating a new pub (i.e. not null value but not part of unique key
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_sr>

 CREATE stock_relationship element
 NOTE: this will create either a subject_id or object_id stock_relationship element
 but you have to attach this to the related stock elsewhere
 params
 doc - XML::DOM::Document required
 is_object - boolean 't'     Note: either is_subject OR is_object and NOT both must be passed
 is_subject - boolean 't'          this flag indicates if the stock info provided should be 
                                   added in as subject or object stock
 rtype - string for relationship type or XML::DOM cvterm element (Note: currently all is_relationship = '0'
         note: if relationship name is given will be assigned to relationship_type cv
 rank - integer optional with default = 0
 stock - XML::DOM stock element required unless minimal stock bits provided
 uniquename - string required unless stock provided
 organism - XML::DOM organism element required unless stock or (genus & species) provided
 genus - string required unless stock or organism provided
 species - string required unless stock or organism provided
 ftype - string = name or XML::DOM cvterm element required unless stock provided

=item C<create_ch_stockprop>

 CREATE stockprop element
 params
 doc - XML::DOM::Document required
 value - string - not strictly required but if you don't provide this then not much point
 type_id - string from property type cv or XML::DOM cvterm element required 
        Note: will default to making a stockprop from 'property type' cv unless cvname is provided
 cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_stockprop_pub>

 CREATE stockprop_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of stockprop_pub
      or just appending the pub element to stockprop_pub if that is passed
 params
 doc - XML::DOM::Document required
 pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
 uniquename - string required
 type_id - string from pub type cv or XML::DOM cvterm element optional unless 
        creating a new pub (i.e. not null value but not part of unique key
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=item C<create_ch_stock_cvterm>

 CREATE stock_cvterm element
 params
 doc - XML::DOM::Document required
 cvterm_id - XML::DOM cvterm element unless other cvterm bits are provided
 name - string required unless cvterm_id provided
 cv_id - string = cvname or XML::DOM cv element required unless cvterm_id provided
 pub_id - XML::DOM pub element or pub uniquename required Note: cannot create a new pub if uniquename provided

=item C<create_ch_stockcollection>

 CREATE stockcollection or stockcollection_id element
 params
 doc - XML::DOM::Document
 uniquename - string required
 type_id - string or XML::DOM cvterm element required
 contact_id - string or XML::DOM contact element required
 name - string optional
 with_id - boolean optional if 1 then db_id element is returned

=item C<create_ch_stockcollectionprop>

 CREATE stockcollectionprop element
 params
 doc - XML::DOM::Document required
 value - string - not strictly required but if you don't provide this then not much point
 type_id - string from realtionship property type cv or XML::DOM cvterm element required 
        Note: will default to making a stockcollectionprop from 'stockcollection property type' cv unless cvname is provided
 cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
 rank - integer with a default of zero so don't use unless you want a rank other than 0

=item C<create_ch_stockcollection_pub>

 CREATE stockcollection_pub element
 Note that this is just calling create_ch_pub setting with_id = 1 
      and adding returned pub_id element as a child of stockcollection_pub
      or just appending the pub element to stockcollection_pub if that is passed
 params
 doc - XML::DOM::Document required
 pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
 uniquename - string required
 type_id - string from pub type cv or XML::DOM cvterm element optional unless 
        creating a new pub (i.e. not null value but not part of unique key
 title - optional string
 volumetitle - optional string
 volume - optional string
 series_name - optional string
 issue - optional string
 pyear - optional string
 pages - optional string
 miniref - optional string
 is_obsolete - optional string 't' boolean value with default = 'f'
 publisher - optional string

=head1 TODO

=cut

# stock and stock_id
# stock_dbxref
# stock_pub
# stock_relationship
# stockprop
# stockprop_pub
# stock_cvterm
# stockcollection and stockcollection_id
# stockcollectionprop
# stockcollection_pub

# CREATE stock element
# params
# doc - XML::DOM::Document required
# uniquename - string required
# type_id - string or XML::DOM cvterm element required Note: if string will
#           default to using FlyBase miscellaneous cv unless a cvname is provided
# cvname - string optional to specify a cv other than FlyBase miscellaneous CV for the type_id
#          do not use if providing a cvterm element to type_id
# organism_id - XML::DOM organism element required if no genus and species
# genus - string required if no organism
# species - string required if no organism
# dbxref_id - XML::DOM dbxref element optional
# name - string optional
# is_obsolete - boolean 't' or 'f' default = 'f' optional
# # with_id - boolean optional if 1 then stock_id element is returned
sub create_ch_stock {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fid_el = $ldoc->createElement('stock_id') if $params{with_id};

    ## stock element (will be returned)
    my $f_el = $ldoc->createElement('stock');

    #create organism_id element if genus and species are provided
    unless ($params{organism_id}) {
	my $org_id = create_ch_organism(doc => $ldoc,
					genus => $params{genus},
					species => $params{species},
					);
	$params{organism_id} = $org_id;
	delete $params{genus}; delete $params{species};
    }

    my $cv = 'FlyBase miscellaneous CV';
    if ($params{cvname}) {
	$cv = $params{cvname};
	delete $params{cvname};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'with_id');
	if ($e eq 'type_id') {
	    if (!ref($params{$e})) {
		my $cv_el = create_ch_cv(doc => $ldoc,
					 name => $cv,
					);
		my $ct_el = create_ch_cvterm(doc => $ldoc,
					     name => $params{$e},
					     cv_id => $cv_el,
					    );
		$f_el->appendChild(_build_element($ldoc, 'type_id',$ct_el));
	    } else {
		 $f_el->appendChild(_build_element($ldoc, $e,$params{$e}));
	    }
	} else {
	    $f_el->appendChild(_build_element($ldoc, $e,$params{$e}));
	}
    }

    if ($fid_el) {
	$fid_el->appendChild($f_el);
	return $fid_el;
    }
    return $f_el;
}


# CREATE stock_dbxref element
# params
# doc - XML::DOM::Document required
# dbxref_id - XML::DOM dbxref element - required unless accession and db provided
# accession - string required unless dbxref_id provided
# db_id - string = db name or XML::DOM db element required unless dbxref_id provided
# version - string optional
# description - string optional
# is_current - string 't' or 'f' boolean default = 't' so don't pass unless
#              this shoud be changed
sub create_ch_stock_dbxref {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fd_el = $ldoc->createElement('stock_dbxref');

    if ($params{is_current}) { #assign value to a var and then remove from params
	my $ic = $params{is_current};
	delete $params{is_current};
    }

    unless ($params{dbxref_id}) { # create a dbxref element if necessary
	$params{dbxref_id} = create_ch_dbxref(%params);
    }

    $fd_el->appendChild(_build_element($ldoc,'dbxref_id',$params{dbxref_id})); #add dbxref element
    $fd_el->appendChild(_build_element($ldoc,'is_current',$ic)) if $ic;

    return $fd_el;
}


# CREATE stock_pub element
# Note that this is just calling create_ch_pub setting with_id = 1 
#      and adding returned pub_id element as a child of stock_pub
#      or just appending the pub element to stock_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - string from pub type cv or XML::DOM cvterm element optional unless 
#        creating a new pub (i.e. not null value but not part of unique key
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_stock_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $fp_el = $ldoc->createElement('stock_pub');

    if ($params{pub_id}) {
	$fp_el->appendChild(_build_element($ldoc,'pub_id',$params{pub_id}));
    } else {
	$params{with_id} = 1;
	my $pub_el = create_ch_pub(%params); #will return a pub_id element
	$fp_el->appendChild($pub_el);
    }
    return $fp_el;
}


# CREATE stockprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - string from property type cv or XML::DOM cvterm element required 
#        Note: will default to making a featureprop from 'property type' cv unless cvname is provided
# cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
# just calling create_ch_prop with correct params to make desired prop
# note that there are cases here where the value is null

sub create_ch_stockprop {
    my %params = @_;
    $params{parentname} = 'stock';
    if (! ref($params{type_id})) {
        $params{cvname} = 'property type' unless $params{cvname};
    }
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}


# CREATE stock_cvterm element
# params
# doc - XML::DOM::Document required
# cvterm_id - XML::DOM cvterm element unless other cvterm bits are provided
# name - string required unless cvterm_id provided
# cv_id - string = cvname or XML::DOM cv element required unless cvterm_id provided
# pub_id - XML::DOM pub element or pub uniquename required Note: cannot create a new pub if uniquename provided

sub create_ch_stock_cvterm {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $ldoc = $params{doc};    ## XML::DOM::Document

    my $sct_el = $ldoc->createElement('stock_cvterm');

    #create a cvterm element
    unless($params{cvterm_id}) {
	my $cvt_el = create_ch_cvterm(doc => $ldoc,
				      name => $params{name},
				      cv_id => create_ch_cv(doc => $ldoc,
							    name => $params{cv_id},
							   ),
				     );
	$params{cvterm_id} = $cvt_el;
	delete $params{name}; delete $params{cv_id};
    }

    foreach my $e (keys %params) {
	next if ($e eq 'doc');
	if ($e eq 'pub_id') {
	    if (!ref($params{$e})) {
		$sct_el->appendChild(create_ch_pub(doc => $ldoc,
						   uniquename => $params{$e},
						   with_id => 1,));
	    } else {
		 $sct_el->appendChild(_build_element($ldoc,$e,$params{$e}));
	    }
	} else {
	    $sct_el->appendChild(_build_element($ldoc,$e,$params{$e}));
	}
    }

    return $sct_el;
}

# CREATE stockcollection or stockcollection_id element
# params
# doc - XML::DOM::Document
# uniquename - string required
# type_id - string or XML::DOM cvterm element required
# name - string optional
# with_id - boolean optional if 1 then db_id element is returned
sub create_ch_stockcollection {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $sldoc = $params{doc};    ## XML::DOM::Document

    my $slibid_el = $sldoc->createElement('stockcollection_id') if $params{with_id};
    my $slib_el = $sldoc->createElement('stockcollection');

    foreach my $e (keys %params) {
	next if ($e eq 'doc' || $e eq 'with_id');
	if ($e eq 'type_id') {
	    if (!ref($params{$e})) {
		my $cv_el = create_ch_cv(doc => $sldoc,
					 name => 'FlyBase miscellaneous CV',
					);
		my $ct_el = create_ch_cvterm(doc => $sldoc,
					     name => $params{$e},
					     cv_id => $cv_el,
					    );
		$slib_el->appendChild(_build_element($sldoc, 'type_id',$ct_el));
	    } else {
		 $slib_el->appendChild(_build_element($sldoc, $e,$params{$e}));
	    }
	} 
	elsif ($e eq 'contact_id') {
	  if (!ref($params{$e})) {
	    my $c_el = create_ch_contact(doc => $sldoc,
					 name => $params{$e},
					);
	    $slib_el->appendChild(_build_element($sldoc, 'contact_id',$c_el));
	  } else {
		 $slib_el->appendChild(_build_element($sldoc, $e,$params{$e}));
	       }
	} else {
	    $slib_el->appendChild(_build_element($sldoc, $e,$params{$e}));
	}
    }

    if ($slibid_el) {
	$slibid_el->appendChild($slib_el);
	return $slibid_el;
    }
    return $slib_el;
}


# CREATE stockcollectionprop element
# params
# doc - XML::DOM::Document required
# value - string - not strictly required but if you don't provide this then not much point
# type_id - string from realtionship property type cv or XML::DOM cvterm element required 
#        Note: will default to making a stockcollectionprop from 'stockcollection property type' cv unless cvname is provided
# cvname - string 'optional' but see above for type and do not provide if passing a cvterm element
# rank - integer with a default of zero so don't use unless you want a rank other than 0
sub create_ch_stockcollectionprop {
    my %params = @_;
    $params{parentname} = 'stockcollection';
    if (! ref($params{type_id})) {
        $params{cvname} = 'stockcollection property type' unless $params{cvname};
    }
    my $fp_el = create_ch_prop(%params);
    return $fp_el;
}

# CREATE stockcollection_pub element
# Note that this is just calling create_ch_pub setting with_id = 1 
#      and adding returned pub_id element as a child of stockcollection_pub
#      or just appending the pub element to stockcollection_pub if that is passed
# params
# doc - XML::DOM::Document required
# pub_id - XML::DOM pub element - if this is used then pass this and doc as only params
# uniquename - string required
# type_id - string from pub type cv or XML::DOM cvterm element optional unless 
#        creating a new pub (i.e. not null value but not part of unique key
# title - optional string
# volumetitle - optional string
# volume - optional string
# series_name - optional string
# issue - optional string
# pyear - optional string
# pages - optional string
# miniref - optional string
# is_obsolete - optional string 't' boolean value with default = 'f'
# publisher - optional string
sub create_ch_stockcollection_pub {
    my %params = @_;
    print "WARNING -- no XML::DOM::Document specified\n" and return unless $params{doc};
    my $sldoc = $params{doc};    ## XML::DOM::Document

    my $slp_el = $sldoc->createElement('stockcollection_pub');

    if ($params{pub_id}) {
	$slp_el->appendChild(_build_element($sldoc,'pub_id',$params{pub_id}));
    } else {
	$params{with_id} = 1;
	my $pub_el = create_ch_pub(%params); #will return a pub_id element
	$slp_el->appendChild($pub_el);
    }
    return $slp_el;
}


1;
