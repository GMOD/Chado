package CXGN::Tools::Identifiers;
use strict;
use warnings;

=head1 NAME

CXGN::Tools::Identifiers - useful functions for dealing with
identifiers, like SGN-E23412

=head1 SYNOPSIS

  my $nsname = identifier_namespace('SGN-E23412');
  #returns 'sgn_e'

  my $url = identifier_url('SGN-E23412');
  #$url is now '/search/est.pl?request_type=7&request=575150'

  my $link = link_identifier('SGN-E575150');
  #$link is now
  #'<a href="/search/est.pl?request_type=7&request=575150">SGN-E575150</a>'

  my $clean = clean_identifier('SGNE3423');
  #returns SGN-E3423, or undef if the identifier was not recognized

  my $uniq = unique_identifier('SGN-E3423');
  #returns 'SGN-E3423'
  $uniq = unique_identifier('SGN-E3423');
  #do it again, returns 'SGN-E3423_1'

  my $contents = parse_identifier('SGN-E12345');

=head1 DESCRIPTION

This module contains easy-to-use functions for working with the often
malformed strings of text that purport to be identifiers of some sort.

=head2 Supported Namespaces

=over 12

=item sgn_u

SGN unigene identifiers 'SGN-U2342'

=item cgn_u

CGN unigene identifers 'CGN-U122539'

=item sgn_e

SGN EST identifiers 'SGN-E234223'

=item sgn_s

SGN Microarray spot identifiers 'SGN-S1241'

=item sgn_m

SGN Marker identifier 'SGN-M1347'

=item sgn_t

SGN Trace (chromatogram) identifiers 'SGN-T1241'

=item microarray_spot

microarray spot identifiers like '1-1-1.2.3.4'

=item est

other kinds of EST identifiers like 'cLEC-23-A23'

=item bac_end

BAC end identifiers like 'LE_HBa0123A12_SP6_2342'

=item bac

BAC identifiers like 'LE_HBa0123A12'

By default, if a BAC has been assigned to a sequencing
project, its clean_identifier and link_identifier will
replace the LE_ or SL_ species name at the beginning
with a C##, where ## is the zero-padded chromosome number.

$CXGN::Tools::Identifier::insert_bac_chr_nums can be used
to enable or disable this.  To disable, set it to a 
false value.  To enable, set true.  Defaults to true.

=item bac_sequence

BAC sequence identifiers like 'LE_HBa0123A12.1'

=item bac_fragment

BAC fragment identifiers (identifies contigs in a bac that is
still partially assembled) like 'LE_HBa0123A12.1-4'

=item sgn_marker

SGN marker names like 'TG23'.  Good luck with this one.

=item tair_locus

TAIR locus identifiers like 'At1g67700.1'

=item species_binomial

e.g. 'Arabidopsis thaliana', 'Solanum lycopersicum'

=item species_common

e.g. 'Tomato' or 'Apple of Sodom'

=item genbank_gi

A genbank identifier containing a stable GI identification number.
Examples include gi|108883260|gb|EAT47485.1| or just gi|108883260|
or GI:108883260

=item genbank_accession

A genbank identifier containing a namespace and an identifier, such as
gb|EAT47485.1|.

=back

=cut

############ NAMESPACE DEFINITIONS ############
# To add a namespace:
# 1. make is_<namespace>, url_<namespace>, and clean_<namespace>
#    functions for your namespace at the end of this file
# 2. add its name to @namespace_list below

#NOTE: the ordering of this list is the order in which a given
#identifier is checked for membership in each class

# removed sgn_marker from this list because it always returns 
# a valid identifier
our @namespace_list = qw/
			 sgn_u
			 cgn_u
			 sgn_e
                         sgn_s
			 sgn_m
			 sgn_t
			 microarray_spot
			 est
			 bac_end
			 bac_fragment
			 bac_sequence
			 bac
			 tomato_contig
			 tair_gene_model
			 tair_locus
			 interpro_accession
			 genbank_gi
			 species_binomial
			 species_common
			 genbank_accession
		        /;

#return 1 if the given namespace is in this list
sub _is_valid_namespace {
  my ($ns) = @_;
  return 1 if grep {$ns eq $_} @namespace_list;
  return 0;
}

=head1 FUNCTIONS

All functions are EXPORT_OK.

=cut

# ABOUT THE ARCHITECTURE OF THIS MODULE
#
# each namespace supported by this module
# has:
#   a.) an entry in @namespace_list
#   b.) a is_<namespace> function
#   c.) a url_<namespace> function
#
# All of these are at the bottom of this file,
# where it says NAMESPACE DEFINITIONS.

use Carp;
use Tie::UrlEncoder;
our %urlencode;

BEGIN {
  our @EXPORT_OK = qw/  identifier_url
			link_identifier
			identifier_namespace
			clean_identifier
			list_namespaces
			parse_identifier
			unique_identifier
		     /;
}
use base qw/Exporter/;

use CXGN::DB::Connection;
use CXGN::Genomic::Clone;
use CXGN::Genomic::CloneIdentifiers qw/ parse_clone_ident assemble_clone_ident /;
use CXGN::Genomic::GSS;
use CXGN::Marker::Tools qw/clean_marker_name marker_name_to_ids/;
use CXGN::Tools::Text qw/trim/;


=head2 identifier_url

  Usage: my $url = identifier_url('SGN-E12141');
  Desc : get an information URL for an identifier.
  Ret  : a string containing an absolute or relative URL,
         suitable for putting in a href= in HTML
  Args : identifier string,
         (optional) namespace name if you know it
  Side Effects: might look things up in the database

=cut

sub identifier_url {
  my ($ident,$ns) = @_;
  $ident = trim($ident);
  $ns ||= identifier_namespace($ident)
    or return;
  return unless _is_valid_namespace($ns);
  #clean up the identifier if we can
  $ident = clean_identifier($ident,$ns) || $ident;
  no strict 'refs';
  return "url_$ns"->($ident);
}

=head2 link_identifier

  Usage: my $link = link_identifier('SGN-E575150');
         #returns '<a href="/search/est.pl?request_type=7&request=575150">SGN-E575150</a>'
  Desc : calls identifier_url() to get a URL for your identifier,
         then returns a complete HTML link to you, like
  Ret  : an html link, or undef if the link could not be made
  Args : single string containing an identifier,
         (optional) namespace name if you know it
  Side Effects: might look things up in the database

=cut

sub link_identifier {
  my ($ident,$ns) = @_;
  $ident = trim($ident);
  $ns ||= identifier_namespace($ident)
    or return;
  $ident = clean_identifier($ident,$ns) || $ident;
  my $url = identifier_url($ident,$ns)
    or return;
  #clean up the identifier if we can
  return qq|<a href="$url">$ident</a>|;
}

=head2 identifier_namespace

  Usage: my $ns = identifier_namespace('SGN-U1231');
         #returns 'sgn_u'
  Desc : get the namespace
  Ret  : a string containing the name of the namespace,
         or undef if it cannot identify the namespace
  Args : a string identifier
  Side Effects: might look things up in the database

=cut

#see bottom for namespace definitions
sub identifier_namespace {
  my ($identifier) = @_;
  $identifier = trim($identifier)
    or return;
  #identifiers have to be more than 2 chars, and they can't be all numbers
  length($identifier) > 2 && $identifier =~ /\D/
    or return;
  foreach my $ns (our @namespace_list) {
    no strict 'refs';
    return $ns if "is_$ns"->($identifier);
    #warn "$identifier is not in $ns\n";
  }
  return;
}

=head2 clean_identifier

  Usage: my $newident = clean_identifier('SGNE1231');
  Desc : attempt to guess the namespace of the identifier,
         and clean up any irregularities in it to put
         it in its canonical form
  Ret  : a cleaned string, or undef if the identifier
         is not in any recognized namespace
  Args : identifier to be cleaned
  Side Effects: may look things up in the database

=cut

sub clean_identifier {
  my ($ident,$ns) = @_;
  $ident = trim($ident);
  $ns ||= identifier_namespace($ident)
    or return;
  return unless _is_valid_namespace($ns);
  no strict 'refs';
  return "clean_$ns"->($ident);
}

=head2 list_namespaces

  Usage: my @namespaces = list_namespaces;
  Desc : get the list of namespace names supported by this module
  Ret  : list of valid namespace names
  Args : none
  Side Effects: none

=cut

sub list_namespaces {
  return @namespace_list;
}


=head2 parse_identifier

  Usage: my $data = parse_identifier($identifier, $namespace );
  Desc : many identifiers have data in them, for example, an SGN-E has the EST id
         in it, and a bac name (LE_HBa0001A02) has the organism, library, plate,
         row, and column in it.  This function parses that data out and gives it
         to you, as it appears in the string.  You might consider running
         clean_identifier() on what you give this function.
  Args : identifier to parse,
         optional list of namespace names it could be a member of,
                  guesses the namespace if not provided
  Ret  : nothing if the identifier could not be parsed, 
         otherwise a hashref of data in the identifier, which varies in its
         contents, looking like
           {  namespace => 'namespace_name',
              <other data in the identifier>
           }
  Side Effects: none
  Example:

     my $data = parse_identifier('C03HBa0001A02');
     #and now $data contains
     $data = { namespace => 'bac',
               lib       => 'LE_HBa',
               plate     => 1,
               row       => 'A',
               col       => 2,
               clonetype => 'bac',
               match     => 'C03HBa0001A02',
               chr       => 3,
             );

=cut

sub parse_identifier {
  my ($ident, $ns ) = @_;

  $ident = trim( $ident);
  $ns ||= identifier_namespace($ident)
    or return;

  return unless _is_valid_namespace($ns);

  no strict 'refs';
  my $p = "parse_$ns"->($ident)
    or return;
  $p->{namespace} = $ns;
  return $p;
}


=head2 unique_identifier

  Usage: my $uniq = unique_identifier($ident,'_',$ident_store);
  Desc : ensure this string is unique within the context of either the run
	 of this script, or some other context.  The 'some other context' part
	 comes in when you pass this function a reference to a (maybe tied)
	 hash it should use for looking up and storing identifiers that have
	 already been seen.
  Ret  : the identifier, possibly with a $sep.$cnt++ appended to it, where $sep
	 is the given separator string and $cnt is the number of times this
	 identifier string has been seen before
  Args : identifier string,
         (optional) separator string (default '_'),
         (optional) ref to identifier-storing hash,
         (optional) true value if you want to force appending to all identifiers
                    regardless of whether they have been seen before
  Side Effects: reads from and writes to the given hash or tied hash.
                DOES NOT look up identifiers anywhere except in that
                hash

=cut

our $global_unique_store = {};
sub unique_identifier {
  my ($ident,$sep,$store,$force) = @_;
  $sep   ||= '_';
  $store ||= $global_unique_store;

  if(my $prevcnt = $store->{$ident}++ || 0 or $force) {
    return $ident.$sep.$prevcnt;
  } else {
    return $ident;
  }
}

=head1 NAMESPACE FUNCTIONS

These functions are not exported, and
are only used internally by this module.
To add a namespace, follow the instructions inside this
file (they are in comments, not POD).

=cut

#for instructions, see ABOUT THE ARCHITECTURE OF THIS MODULE above

=head2 is_E<lt>namespaceE<gt>

  Usage: is_sgn_e('SGN-E2342');
  Desc : check if an identifier is in a given namespace
  Ret  : 1 if the given identifier is in that namespace,
         0 otherwise
  Args : identifier string
  Side Effects: may look up things in the database

=head2 url_E<lt>namespaceE<gt>

  Usage: url_sgn_e('SGN-E2342');
  Desc : get the info URL for a given identifier,
  Ret  : string with the URL, or undef if no
         url is available for this identifier
  Args : identifier string
  Side Effects: may look up things in the database

  NOTE: These functions will ONLY be called if it has already
        been determined that the identifier is in that namespace.

=head2 clean_E<lt>namespaceE<gt>

  Usage: my $clean = clean_sgn_e('sgne12311');
         #returns 'SGN-E12311'
  Desc : clean up any irregularities in the identifier string
  Ret  : cleaned up identifier string.  Should never fail,
         since this function will only be called on identifiers
         that are definitely in that namespace.
  Args : identifier string
  Side Effects: may look things up in the database

  NOTE: These functions will ONLY be called if it has already
        been determined that the identifier is in that namespace.
        If your is_<namespace> function says it's that type of
        identifier, your clean_<namespace> function had better
        be able to clean it.

=cut
#'
our $sgn_db;
#write an accessor routine that makes sure our connection does
#not go away due to timeouts or whatever
sub _sgn_db {
  $sgn_db ||= CXGN::DB::Connection->new('sgn');
  unless($sgn_db->ping) {
    $sgn_db = undef;
    $sgn_db = _sgn_db();
  }
  return $sgn_db;
}

######## sgn_u
sub is_sgn_u {
  is_letter_identifier('sgn','u',shift);
}
sub url_sgn_u {
  "/search/unigene.pl?unigene_id=".$urlencode{uc($_[0])};
}
sub clean_sgn_u {
  clean_letter_identifier('sgn','u',shift);
}
sub parse_sgn_u {
  parse_letter_identifier('sgn','u',shift);
}
######## cgn_u
sub is_cgn_u {
  is_letter_identifier('cgn','u',shift);
}
sub url_cgn_u {
  my ($cgnid) = shift =~ /(\d+)/ or return undef;
  my ($sgnid) = _sgn_db->selectrow_array('SELECT unigene_id FROM unigene WHERE sequence_name = ? AND database_name=? ',undef,$cgnid,'CGN')
    or return undef;
  return "/search/unigene.pl?unigene_id=".$urlencode{uc($sgnid)};
}
sub clean_cgn_u {
  clean_letter_identifier('cgn','u',shift);
}
sub parse_cgn_u {
  parse_letter_identifier('cgn','u',shift);
}
######### sgn_e
sub is_sgn_e {
  is_letter_identifier('sgn','e',shift);
}
sub url_sgn_e {
  "/search/est.pl?request_id=$urlencode{$_[0]}&request_from=0&request_type=automatic&search=Search";
}
sub clean_sgn_e {
  clean_letter_identifier('sgn','e',shift);
}
sub parse_sgn_e {
  parse_letter_identifier('sgn','e',shift);
}
######### sgn_s
sub is_sgn_s {
  is_letter_identifier('sgn','s',shift);
}
sub url_sgn_s {
  "/search/est.pl?request_id=$urlencode{$_[0]}&request_from=0&request_type=14&search=Search";
}
sub clean_sgn_s {
  clean_letter_identifier('sgn','s',shift);
}
sub parse_sgn_s {
  parse_letter_identifier('sgn','s',shift);
}
######### sgn_m
sub is_sgn_m {
  is_letter_identifier('sgn','m',shift);
}
sub url_sgn_m {
    my $id = shift;
    $id =~ s/sgn.*m(\d+)$/$1/i;
    return "/search/markers/markerinfo.pl?marker_id=$urlencode{$id}";
}
sub clean_sgn_m {
  clean_letter_identifier('sgn','m',shift);
}
sub parse_sgn_m {
  parse_letter_identifier('sgn','m',shift);
}
######### sgn_t
sub is_sgn_t {
  is_letter_identifier('sgn','t',shift);
}
sub url_sgn_t {
  "/search/est.pl?request_id=$urlencode{$_[0]}&request_from=0&request_type=9&search=Search";
}
sub clean_sgn_t {
  clean_letter_identifier('sgn','t',shift);
}
sub parse_sgn_t {
  parse_letter_identifier('sgn','t',shift);
}
######### microarray_spot
sub is_microarray_spot {
  return 1 if shift =~ /^\d-\d-\d+\.\d+\.\d+\.\d+$/;
  return 0;
}
sub url_microarray_spot {
  "/search/est.pl?request_id=$urlencode{$_[0]}&request_from=0&request_type=14&search=Search";
}
sub clean_microarray_spot {
  shift; #no cleaning is done here
}
sub parse_microarray_spot {
  warn 'WARNING: parsing not yet implemented for microarray_spot';
  return;
}
######### est
sub is_est {
  # XXX: stupid stupid stupid.  Coffee clones have names like
  # ccc<garbagegarbagegarbage>.
  return 0 if $_[0] =~ m|^ccc|i;
  return 1 if $_[0] =~ /^(c[A-Z]{2,3}|TUS)[^A-Z\d]*[0-9]+[^A-Z\d]*[A-P][^A-Z\d]*[0-9]{1,2}$/i;
  return 0;
}
sub url_est {
  "/search/est.pl?request_from=0&request_id=$urlencode{$_[0]}&request_type=automatic";
}
sub clean_est {
  my $ident = shift;
  $ident = uc($ident);
  $ident =~ s/^C/c/;

  if ($ident =~ /^([A-Z]{3,4})[^A-Z\d]*([0-9]+)[^A-Z\d]*([A-P])[^A-Z\d]*([0-9]{1,2})$/i) {
    $ident = "$1-$2-$3$4";
  }
  return $ident;
}
sub parse_est {
  warn 'WARNING: parsing not yet implemented for est';
  return;
}
######### bac_end
sub is_bac_end {
  my $parsed = parse_clone_ident(shift,'bac_end')
    or return 0;

  return 1;
}
sub url_bac_end {
  my $ident = shift;
  my $parsed = parse_clone_ident($ident,'bac_end')
    or confess 'not a valid bac end name';
  return "/maps/physical/clone_read_info.pl?chrid=$parsed->{chromat_id}";
}
sub clean_bac_end {
  my $ident = shift;
  my $parsed = parse_clone_ident($ident,'bac_end')
    or confess 'not a valid bac end name';
  my $gss = CXGN::Genomic::GSS->retrieve_from_parsed_name($parsed)
    or confess "could not fetch gss for ident '$ident'";
  return $gss->external_identifier;
}
sub parse_bac_end {
  parse_clone_ident(shift,'bac_end');
}
#bac
sub is_bac {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/agi_bac agi_bac_with_chrom old_cornell sanger_bac/)
      or return 0;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return 0 unless $parsed->{match} eq $ident and !defined($parsed->{version}) and !defined($parsed->{fragment});
  my $clone = _bac_cache($parsed)
    or return 0;
  return 1;
}
sub _bac_cache {
  #single-element cache of the last BAC ident we returned.  this speeds
  #up runs of multiple queries for the same bac
  my ($parsed) = @_;
  our $last_key;
  our $last_clone;
  my $key = join(',',@{$parsed}{qw/lib plate row col clonetype/});
  if($last_key && $last_key eq $key) {
#    warn "cache hit $key\n";
    return $last_clone;
  } else {
#    warn "cache miss $key\n";
    $last_key = $key;
    return $last_clone = CXGN::Genomic::Clone->retrieve_from_parsed_name($parsed);
  }
}
sub url_bac {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/agi_bac agi_bac_with_chrom old_cornell sanger_bac/)
      or return undef;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return undef unless $parsed->{match} eq $ident and !defined($parsed->{version}) and !defined($parsed->{fragment});
  my $clone = _bac_cache($parsed)
    or return undef;
  return "/maps/physical/clone_info.pl?id=".$clone->clone_id;
}
our $insert_bac_chr_nums = 1;
sub clean_bac {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/agi_bac agi_bac_with_chrom old_cornell sanger_bac/)
    or return undef;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return undef unless $parsed->{match} eq $ident and !defined($parsed->{version}) and !defined($parsed->{fragment});
  my $clone = _bac_cache($parsed)
    or return undef;
  return (our $insert_bac_chr_nums) && $clone->chromosome_num
    ? $clone->clone_name_with_chromosome : $clone->clone_name;

}
sub parse_bac {
  parse_clone_ident(shift,qw/agi_bac agi_bac_with_chrom old_cornell sanger_bac/);
}
#tomato_contig
sub is_tomato_contig {
  my ($ident) = @_;
  return 1 if $ident =~ /^C\d+\.\d+[^a-z\d]?contig\d+$/i;
  return 0;
}
sub url_tomato_contig {
  my ($ident) = @_;
  return;
}
sub clean_tomato_contig {
  my ($ident) = @_;
  $ident = uc $ident;
  $ident =~ s/CONTIG/contig/;
  $ident =~ s/[^a-z\d]?contig/_contig/;
  return $ident;
}
sub parse_tomato_contig {
  my ($ident)  = @_;
  $ident =~ /^C(\d+)\.(\d+)[^a-z\d]?contig(\d+)$/i
    or return;
  return { chr        => $1+0,
	   chr_ver    => $2+0,
	   ctg_num => $3+0,
	 };
}
#bac_sequence
sub is_bac_sequence {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/versioned_bac_seq/)
    or return 0;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return 0 unless $parsed->{match} eq $ident and defined($parsed->{version});
  my $clone = _bac_cache($parsed)
    or return 0;
  return 1;
}
sub url_bac_sequence {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/versioned_bac_seq/)
	or return;
#   use Data::Dumper;
#   die "$ident -> ",Dumper($parsed);
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return unless $parsed->{match} eq $ident and defined($parsed->{version});
  my $clone = _bac_cache($parsed)
    or return;
  return "/maps/physical/clone_info.pl?id=".$clone->clone_id;
}
sub clean_bac_sequence {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/versioned_bac_seq/)
	or return;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return undef unless $parsed->{match} eq $ident and defined($parsed->{version});
  my $clone = _bac_cache($parsed)
    or return;
  return assemble_clone_ident('versioned_bac_seq',$parsed);
}
sub parse_bac_sequence {
  parse_clone_ident(shift,qw/versioned_bac_seq/);
}
#bac_fragment
sub is_bac_fragment {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/versioned_bac_seq/)
    or return 0;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return 0 unless $parsed->{match} eq $ident and defined($parsed->{version}) and defined($parsed->{fragment});
  my $clone = _bac_cache($parsed)
    or return 0;
  return 1;
}
sub url_bac_fragment {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/versioned_bac_seq/)
	or return;
#   use Data::Dumper;
#   die "$ident -> ",Dumper($parsed);
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return unless $parsed->{match} eq $ident and defined($parsed->{version}) and defined($parsed->{fragment});
  my $clone = _bac_cache($parsed)
    or return;
  return "/maps/physical/clone_info.pl?id=".$clone->clone_id;
}
sub clean_bac_fragment {
  my ($ident) = @_;
  my $parsed = parse_clone_ident($ident,qw/versioned_bac_seq/)
	or return;
  #must match the whole identifier, cause we sometimes tack on
  #things to the ends of the names
  return undef unless $parsed->{match} eq $ident and defined($parsed->{version}) and defined($parsed->{fragment});
  my $clone = _bac_cache($parsed)
    or return;
  return assemble_clone_ident(versioned_bac_seq => $parsed);
}
sub parse_bac_fragment {
  parse_clone_ident(shift,qw/ versioned_bac_seq / );
}
#sgn_marker
sub is_sgn_marker {
  my $ident = shift;
  $ident = clean_sgn_marker($ident);
  my @ids = marker_name_to_ids(_sgn_db,$ident);
  return 1 if @ids == 1;
  return 0;
}
sub url_sgn_marker {
  my $ident = shift;
  $ident = clean_sgn_marker($ident);
  my @ids = marker_name_to_ids(_sgn_db,$ident);
  return unless @ids == 1;
  return "/search/markers/markerinfo.pl?marker_id=$ids[0]"
}
sub clean_sgn_marker {
  my $ident = shift;
  $ident =~ s/-(FPRIMER|RPRIMER|F|R)$//;
  return clean_marker_name($ident);
}
sub parse_sgn_marker {
  warn 'parsing sgn_marker not implemented';
  return;
}
#tair_locus
sub is_tair_locus {
  return 1 if shift =~ /^AT[1-5MC]G\d{5}$/i;
  return 0;
}
sub url_tair_locus {
  my ($locusname) = @_;
#  $locusname =~ s/\.\d+$//;
  "http://arabidopsis.org/servlets/TairObject?type=locus&name=$urlencode{$locusname}"
}
sub clean_tair_locus {
  my $ident = shift;
  $ident =~ s/^at/At/i; #properly capitalize the first at
  return $ident;
}
sub parse_tair_locus {
  my ($ident) = @_;
  warn 'WARNING: parsing not yet implemented for TAIR locus';
  return;
}
#tair_gene_model
sub is_tair_gene_model {
  return 1 if shift =~ /^AT[1-5MC]G\d{5}\.\d+$/i;
  return 0;
}
sub url_tair_gene_model {
  my $name = shift;
  "http://arabidopsis.org/servlets/TairObject?type=gene&name=$urlencode{$name}"
}
sub clean_tair_gene_model {
  my $ident = shift;
  $ident =~ s/^at/At/i; #properly capitalize the first at
  return $ident;
}
sub parse_tair_gene_model {
  warn 'WARNING: parsing not yet implemented for tair gene model';
  return;
}
#species binomial
sub is_species_binomial {
  return 1 if shift =~ /^[a-z]+ [a-z]+$|^[a-z]\.\s*[a-z]+$/i;
  return 0;
}
sub url_species_binomial {
  _wikipedia_link(@_);
}
sub clean_species_binomial {
  my $ident = shift;
  $ident =~ s/\.(?=\S)/\. /g;
  $ident =~ s/\s+/ /g;
  $ident = lc($ident);
  $ident = ucfirst($ident);
  return $ident;
}
sub parse_species_binomial {
  my ($ident) = @_;
  my @w = split qr/\W+/, $ident;
  return unless @w == 2;
  return { genus   => $w[0],
	   species => $w[1],
	 };
}
sub _wikipedia_link {
  my ($ident) = @_;
  $_ = $ident;
  my @w = split;
  return 'http://en.wikipedia.org/wiki/Special:Search/'.join('_',@w);
}
#species short name
sub is_species_common {
  my $ident = shift;
  $ident =~ s/\s+/ /g;
  return undef if $ident =~ /\d/;
  my $q = _sgn_db->prepare_cached(<<EOSQL,{},1);
select common_name from common_name where common_name ilike ?
EOSQL
  $q->execute($ident);
  return 1 if $q->rows > 0;
  return 0;
}
sub url_species_common {
  _wikipedia_link(@_);
}
sub clean_species_common {
  my $ident = shift;
  $ident =~ s/\s+/ /g;
  return undef if $ident =~ /\d/;
  my $q = _sgn_db->prepare_cached(<<EOSQL,{},1);
select common_name from common_name where common_name ilike ?
EOSQL
  $q->execute($ident);
  return undef unless $q->rows > 0;
  my ($clean) = @{$q->fetchrow_arrayref};
  return $clean;
}
sub parse_species_common {
  { common_name => shift }
}
#genbank_gi
sub is_genbank_gi {
  my ($ident) = @_;
  return 1 if $ident =~ /^gi[\|:]\d+[\|:]?$/i;
  return 0;
}
sub url_genbank_gi {
  my ($ident) = @_;
  $ident = clean_genbank_gi($ident) or return;
  "http://www.ncbi.nlm.nih.gov/gquery/gquery.fcgi?term=$urlencode{$ident}"
}
sub clean_genbank_gi {
  my ($ident) = @_;
  if($ident =~ /^gi[\|:](\d+)$/i) {
    return "gi|$1|";
  } else {
    return clean_genbank($ident)
  }
}
sub parse_genbank_gi {
  my ($ident) = @_;
  $ident =~ /^gi[\|:](\d+)[\|:]?$/i
    or return;
  return { gi => $1 + 0 };
}
#genbank_accession
sub is_genbank_accession {
  my ($ident) = @_;

  return 1 if
    $ident =~ /([a-z]{2,3})\|+\w+\d+(\.\d+)?\|?/i
      || $ident =~ /^[A-Z_]+\d{4,}(\.\d+)?$/;
  return 0;
}
sub url_genbank_accession {
  my ($ident) = @_;
  $ident = clean_genbank_accession($ident) or return;

  return "http://www.ncbi.nlm.nih.gov/gquery/gquery.fcgi?term=$urlencode{$ident}";
}
sub clean_genbank_accession { clean_genbank(@_) };
sub parse_genbank_accession {
  my ($ident) = @_;

  my %parsed;

  if( $ident =~ /[\|:]/ ) {
    my @fields = split /[\|:]+/, $ident;
    pop @fields if $fields[-1] =~ /^\[\d+\]$/;

    while( my $field = shift @fields ) {
      if( lc $field eq 'gi' ) {
	my $gi = shift @fields;
	$parsed{gi} = $gi + 0;
      }
      elsif( lc $field eq 'gb' ) {
	my $acc = shift @fields;
	my $locus = shift @fields;
	$parsed{locus} = $locus if defined $locus;
	my $accver = _gb_acc_ver($acc);
	@parsed{keys %$accver} = values %$accver;
      }
      else {
	if( $fields[0] && $field !~ /\d/ ) {
	  $parsed{$field} = shift @fields;
	} else {
	  $parsed{unknown} ||= [];
	  push @{$parsed{unknown}},$field;
	}
      }
    }
    return \%parsed;
  } else {
    return _gb_acc_ver($ident);
  }
}
sub _gb_acc_ver {
  my ($id) = @_;
  my %parsed;
  if( $id =~ /^([\w_]+\d+)\.(\d+)$/ ) {
    return { accession => $1,
	     version   => $2+0,
	   };
  }
  else {
    return { accession => $id };
  }
}

sub clean_genbank {
  my ($ident) = @_;
  $ident =~ s/^([a-z]{2,3})\|/lc($1).'|'/ie; #lowercase initial gi and namespace idents
  $ident =~ s/\|([a-z]{2,3})\|/'|'.lc($1).'|'/ie; #lowercase internal gi and namespace idents
  $ident =~ s/\[\d+\]//; #remove any bracketed gi numbers
  return $ident;
}

#interpro accession
sub is_interpro_accession {
  my ($ident) = @_;
  return 1 if $ident =~ /^IPR\d+$/i;
  return 0;
}
sub url_interpro_accession {
  my ($ident) = @_;
  $ident = clean_interpro_accession($ident) or return;
  return "http://www.ebi.ac.uk/interpro/IEntry?ac=" . $ident;
}
sub clean_interpro_accession {
  my ($ident) = @_;
  return uc($ident); 
}
sub parse_interpro_accession {
  my ($ident) = @_;
  return unless $ident =~ /^IPR(\d+)$/;
  return { id => $1+0 };
}


#### NAMESPACE HELPERS ###

#return 1 if the identifier is a SGN-X234232 identifier
#where X is the letter of your choice
sub is_letter_identifier {
  my ($dbname,$letter,$identifier) = @_;
  $dbname = uc($dbname);
  return 1 if $identifier =~ /^$dbname?\W?$letter\d{1,9}/i;
  return 0;
}

sub quick_search_url {
  "/search/quick_search.pl?term=".$urlencode{+shift}
}

sub clean_letter_identifier {
  my ($dbname,$letter,$identifier) = @_;
  $dbname = uc($dbname);
  $letter = uc($letter);
  my ($digits) = $identifier =~ /(\d+)/
    or return;
  $digits += 0;
  return "$dbname-$letter$digits";
}

sub parse_letter_identifier {
  my ($dbname,$letter,$identifier) = @_;
  $dbname = uc($dbname);
  $letter = uc($letter);
  my ($digits) = $identifier =~ /(\d+)/
    or return;
  return { id => $digits + 0 };
}


###
1;#do not remove
###
