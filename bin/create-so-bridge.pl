#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use DBI;
use Getopt::Long;
use Time::HiRes qw( time );
#use GO::Parser;
use Data::Dumper;

# POD DOCS AT END

use constant MAX_RELATION_NAME_LEN => 100; # 31;

my $debug;
my $help;
my $db;
my $file;
my $user;
my $pass;
my $id_based;
my $PROPTYPE_ID = 'type_id';
my $drop;
my $counts;
my $RTYPE = 'VIEW';
my $schema = 'so';
my $so_name = 'sequence';
my $ontology = $so_name;
my $verbose;
my $do_closure=1;
my %custom_name_map;
my $use_custom_name_map;

GetOptions(
           "help|h"=>\$help,
	   "db|d=s"=>\$db,
	   "file|f=s"=>\$file,
	   "user|u=s"=>\$user,
	   "pass|p=s"=>\$pass,
	   "id_based|i"=>\$id_based,
           "count|c"=>\$counts,
	   "drop"=>\$drop,
	   "ptype_id=s"=>\$PROPTYPE_ID,
	   "rtype|r=s"=>\$RTYPE,
           "verbose|v"=>\$verbose,
           "ontology|o=s"=>\$ontology,
           "Custom_namemap:s"=>\$use_custom_name_map,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

$id_based = 1 unless ($ontology eq 'sequence');
$schema   = lc($ontology) unless ($ontology eq 'sequence');

if ($RTYPE ne 'VIEW' && $RTYPE ne 'TABLE') {
    die "RTYPE: $RTYPE is not VIEW or TABLE";
}

my $dbh;
my $DBI = 'DBIx::DBStag';
if ($db) {
    eval {
        require "DBIx/DBStag.pm";
        msg("Connecting via DBStag");
        my $sdbh = 
          DBIx::DBStag->connect($db, $user, $pass);
        $dbh = $sdbh->dbh;
    };
    if ($@) {
        # stag not installed - use DBI
        msg("Connecting via DBI");
        $dbh =
          DBI->connect($db, $user, $pass);
    }
    msg("Connected");
    $dbh->{RaiseError} = 1;
}

if (defined $use_custom_name_map and $use_custom_name_map eq '') {
    %custom_name_map = get_name_map_from_db();
} elsif ($use_custom_name_map) {
    my @pairs = split(',', $use_custom_name_map);
    for my $pair (@pairs) {
        my ($tag,$value) = split('=', $pair);
        $custom_name_map{$tag} = $value;
    }
}


my $child_term_query = "SELECT cvterm.cvterm_id,cvterm.name FROM cvterm JOIN cvterm_relationship ON (cvterm.cvterm_id = cvterm_relationship.subject_id) WHERE cvterm_relationship.object_id = ? AND cvterm_relationship.type_id in (SELECT cvterm_id FROM cvterm WHERE name='is_a') ";
my $child_query_handle = $dbh->prepare($child_term_query);

# ==============================================================
# PARSE SOFA  Removed for the time being--SO info from Chado 
# ==============================================================
#my $p = GO::Parser->new({handler=>'obj'});
#my $f = shift || die "must pass SO or SOFA file";
#$p->parse($f);
#my $graph = $p->handler->graph;


# ==============================================================
# GET FEATURE TYPES
# ==============================================================
# this is only the feature types for which a feature exists within
# the particular chado implementation
my @terms = get_so_terms($ontology);

# ==============================================================
# GET CVTERM IDS
# ==============================================================
my $trows = [];
my $used_type_ids;
if ($dbh) {
    msg("getting type to prop mappings");
    if ($ontology eq 'GO') {
      $trows =
        $dbh->selectall_arrayref("SELECT DISTINCT cvterm_id, cvterm.name
           FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='biological_process' or cv.name='molecular_function' or cv.name='cellular_component'");
    } 
    else {
      $trows =
        $dbh->selectall_arrayref("SELECT DISTINCT cvterm_id, cvterm.name
	   FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='$ontology'");
    }
    die "could not find terms" unless @$trows;

    if ($ontology eq 'GO') {
      $used_type_ids = $dbh->selectcol_arrayref("SELECT DISTINCT cvterm_id
          FROM cvterm INNER JOIN feature_cvterm USING (cvterm_id)
          WHERE cv_id IN (SELECT cv_id FROM cv WHERE
            cv.name='biological_process' 
            or cv.name='molecular_function' 
            or cv.name='cellular_component')");
    }
    elsif ($ontology ne 'sequence') {
      $used_type_ids = $dbh->selectcol_arrayref("SELECT DISTINCT cvterm_id
          FROM cvterm INNER JOIN feature_cvterm USING (cvterm_id)
          WHERE cv_id IN (SELECT cv_id FROM cv WHERE name = '$ontology'");
    }
    else { #sequence
      $used_type_ids = $id_based ?
        $dbh->selectcol_arrayref("SELECT DISTINCT type_id 
        FROM feature INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)")
      : $dbh->selectcol_arrayref("SELECT DISTINCT cvterm_id
        FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='sequence'");
    }
}
my %used_type_idh = map { $_=>1 } @$used_type_ids;
my %n2id = map { $_->[1] => $_->[0] } @$trows;
my %id2n = reverse %n2id;

my %namemap = ();
my %revnamemap = ();
my %abbrev = ();

# make them database-safe (remove certain characters)
$| = 1;

print "--This is an automatically generated file; do not edit it as changes will not\n";
print "--be saved.  Instead, modify bin/create-so-bridge.pl, which creates this file.\n\n\n";
if ($schema) {
    print "CREATE SCHEMA $schema;\nSET search_path=$schema,public,pg_catalog;\n\n";
}

msg("generating SO layer....");
foreach my $term (@terms) {
    my $tname    = $$term{name};
    my $def      = $$term{definition} || '';
    my $cvtermid = $$term{cvterm_id};
    my $vname    = safename($tname);

    next if $vname eq '-1';

    next if ($id_based && !$used_type_idh{$cvtermid});

    my (@cols, @selcols, $sel);

    my @fcols =
      qw(
	 feature_id
	 dbxref_id
	 organism_id
	 name
	 uniquename
	 residues
	 seqlen
	 md5checksum
	 type_id
	 is_analysis
	 timeaccessioned
	 timelastmodified
	);

    my @ifcols =
      qw(
	 feature_id
	 dbxref_id
	 organism_id
	 name
	 uniquename
	);
    
      

    my $vfmt =
      join("\n",
	   "CREATE $RTYPE $vname AS",
	   "  SELECT",
	   "    feature_id AS $vname"."_id,",
           "    feature.*",
	   "  FROM",
	   "    feature %s",
	   "  WHERE %s",
	  );

    my $from;
    if ($ontology eq 'sequence') {
        $from = "INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)";
    }
    else {
        $from = "INNER JOIN feature_cvterm USING (feature_id) INNER JOIN cvterm USING (cvterm_id)"; 
    }
    my $where = "cvterm.name = '$tname'";
    if ($id_based and $ontology eq 'sequence') {
        my $id = $n2id{$tname};        
        $where = "feature.type_id = $id";
    }
    if ($do_closure) {
        my @cterms = 
          get_recursive_child_terms_by_type_from_chado($$term{cvterm_id});
        push @cterms, $tname;

        my @pnames = @cterms;
#        if (%used_type_idh) {
#            @pnames = grep { $used_type_idh{$n2id{$_}} } @pnames;
#        }
#        @pnames = map {safename($_)} @pnames;
        if ($id_based and $ontology eq 'sequence') {
            $where = join(' OR ',
                        map {"feature.type_id = '$_'"} map {$n2id{$_}} @pnames);
        }
        else {
            $where = join(' OR ',
                        map {"cvterm.name = '$_'"} @pnames);
        }
              
    }
   
    my $cmnt = "";
    if ($id_based) {
        my $id = $n2id{$tname};        
        if (!$id) {
            print STDERR "no id for $tname\n" unless $id;
            next;
        }
	$from = "" if $ontology eq 'sequence';
	$cmnt = "--- This view is derived from the cvterm database ID.\n".
	  "--- This will be more efficient, but the views MUST be regenerated\n".
	    "--- when the underlying ontology in the database changes\n";
    }
    
    my $vsql =
      sprintf($vfmt,
	      $from,
	      $where);

    if ($drop) {
	print"DROP $RTYPE $vname  CASCADE;\n";
    }
    my $defcmt = '';
    if ($def) {
        my $S = 40;
        while ($def) {
            $defcmt .= sprintf("--- *** %-40s ***\n",substr($def,0,$S,''));
        }
    }

    my $print_str = "--- ************************************************\n".
           "--- *** relation: $vname ***\n".
           "--- *** relation type: $RTYPE                      ***\n".
           "--- ***                                          ***\n".
           $defcmt.
           "--- ************************************************\n".
           "---\n".
           "\n".
           "$vsql;\n\n";
    print $print_str;

    if ($RTYPE eq 'TABLE') {
	print "\n\n--- *** Auto-generated indexes ***\n";
	foreach my $col (@ifcols) {
	    print "CREATE INDEX $vname"."_idx_$col ON $vname ($col);\n";
	}
        print "\n\n";
    }


}

$dbh->disconnect if $dbh;

create_lookup_table(%namemap);

print "\n\nSET search_path=public,pg_catalog;\n";
print STDERR "Done!\n";
exit 0;

sub msg {
    return unless $verbose;
    print STDERR "@_\n";
}

# ==============================================================
# safename(string): returns string
# ==============================================================
# makes a name db-safe; also adds the mapping
# from the original name to safe name in the global lookup %namemap
sub safename {
    my $orig = shift;
    my $n = lc($orig);
    $n =~ s/[-.(),`'"]/_/g;
    my @parts = ();
    if ($orig =~ /\s/) {
      @parts = split(/ /, $n);
    }
    else {
      @parts = split(/_/, $n);
    }

#    @parts = map {$abbrev{$_} || $_} @parts;
    #start hard coding some short circuits to make sure everything gets a unqique name
    if ($custom_name_map{$orig}) {
      $n = $custom_name_map{$orig};
    }
    elsif ($n eq 'deficient_intrachromosomal_transposition') {
      $n = 'd_intrachr_transposition';
    }
    elsif ($n eq 'deficient_interchromosomal_transposition') {
      $n = 'd_interchr_transposition';
    }
    elsif ($n eq 'arginine_trna_primary_transcript') {
      $n = 'arg_trna_primary_transcript';
    }
    elsif ($n eq 'asparagine_tRNA_primary_transcript') {
      $n = 'asp_tRNA_primary_transcript';
    }
    elsif ($n eq 'tryptophan_trna_primary_transcript') {
      $n = 'try_trna_primary_transcript';
    }
    elsif ($n eq 'tyrosine_tRNA_primary_transcript') {
      $n = 'tyr_tRNA_primary_transcript';
    }
    elsif ($n eq 'threonine_trna_primary_transcript') {
      $n = 'thr_trna_primary_transcript';
    }
    elsif ($n eq 'trinucleotide_repeat_microsatellite_feature') {
      $n = 'trinuc_repeat_microsat';
    }
    elsif ($n eq 'tetranucleotide_repeat_microsatellite_feature') {
      $n = 'tetranuc_repeat_microsat';
    }
    elsif ($n eq 'phenylalanine_trna_primary_transcript') {
      $n = 'phe_trna_primary_transcript';
    }
    elsif ($n eq 'pyrrolysine_tRNA_primary_transcript') {
      $n = 'pyr_tRNA_primary_transcript';
    }
    elsif ($n eq 'two_prime_o_ribosyladenosine_phosphate') {
      $n = 'two_prime_o_riboA_phosphate';
    }
    elsif ($n eq 'two_prime_O_ribosylguanosine_phosphate') {
      $n = 'two_prime_O_riboG_phosphate';
    }
    elsif ($n eq 'five_methoxycarbonylmethyl_two_thiouridine') {
      $n = 'five_mcm_2_thiouridine';
    }
    elsif ($n eq 'five_methylaminomethyl_two_thiouridine') {
      $n = 'five_mam_2_thiouridine';
    }
    elsif ($n eq 'five_carbamoylmethyl_two_prime_o_methyluridine') {
      $n = 'five_cm_2_prime_o_methU';
    }
    elsif ($n eq 'five_carboxymethylaminomethyl_two_prime_O_methyluridine') {
      $n = 'five_cmam_2_prime_methU';
    }
    elsif ($n eq 'inverted_interchromosomal_transposition') {
      $n = 'invert_inter_transposition';
    }
    elsif ($n eq 'inverted_intrachromosomal_transposition') {
      $n = 'invert_intra_transposition';
    }
    elsif ($n eq 'uninverted_interchromosomal_transposition') {
      $n = 'uninvert_inter_transposition';
    }
    elsif ($n eq 'uninverted_intrachromosomal_transposition') {
      $n = 'uninvert_intra_transposition';
    }
    elsif ($n eq 'uninverted_insertional_duplication') {
      $n = 'uninvert_insert_dup';
    }
    elsif ($n eq 'unoriented_insertional_duplication') {
      $n = 'unorient_insert_dup';
    }
    elsif ($n eq 'unorientated_interchromosomal_transposition') {
      $n = 'unorient_inter_transposition';
    }
    elsif ($n eq 'unorientated_intrachromosomal_transposition') {
      $n = 'unorient_intra_transposition';
    }
    elsif ($n eq 'natural') {
      $n = 'so_natural';
    }
    elsif ($n eq 'foreign') {
      $n = 'so_foreign';
    }
    elsif ($n eq 'edited_transcript_by A_to_I_substitution') {
      $n = 'edit_trans_by_a_to_i_sub';
    }
    elsif ($n eq '7-methylguanine') {
      $n = 'seven_methylguanine';
    }
    elsif ($n eq '') {
      $n = '';
    }


    else {
      if (length("@parts") > MAX_RELATION_NAME_LEN) {
	@parts = split(/_/, $n);
	my $part_i = 0;
	while (length("@parts") > MAX_RELATION_NAME_LEN) {
	    if ($part_i > @parts) {
		die "cannot shorten $orig [got $n]";
	    }
	    my $part = $parts[$part_i];
	    my $ab = substr($part, 0, 1);
	    $abbrev{$part} = $ab;
	    $parts[$part_i] = $ab;
#	    print "  FROM: $part => $ab\n";
	    $part_i++;
	}
      }
      $n = '';
      $n = join('_', @parts);
#      while (my $part = shift @parts) {
#	$n .= $part;
#	if (@parts && (length($part) > 1 || length($parts[0]) > 1)) {
#	    $n.= '_';
#	}
#      }
    }
#    print "NAMEMAP: $orig -> $n\n";
    if ($revnamemap{$n}) {
        #figure out if there are any terms that use this term--if not, skip
        #it with a warning; if so die
        #We should probably provide a way for the user to supply custom
        #name mappings to get around this
        my $non_so_used_query = "SELECT count(feature_id) FROM feature_cvterm INNER JOIN cvterm USING (cvterm_id) WHERE cvterm.name = ?";
        my $sth = $dbh->prepare($non_so_used_query);
        $sth->execute($orig); 
        my ($exists) = $sth->fetchrow_array;

        if ($exists) {
          print STDERR "The short name $n already exists; the existing view\n";
          print STDERR "is called $revnamemap{$n}, and the current view is for $orig\n\n";
          print STDERR "You may supply the --Custom_namemap argument to overcome this;\n"; 
          print STDERR "see the documentation for more.  Exiting...\n\n";
          exit(-1);
        }
        else {
          print STDERR "The short name $n already exists; the existing view\n";
          print STDERR "is called $revnamemap{$n}, and the current view is for $orig.,\n";
          print STDERR "However, since there is no data that would be contained in this view,\n";
          print STDERR "it is being skipped.  You may supply the --Custom_namemap argument to overcome\n";
          print STDERR "this; see the documentation for more.\n\n";
          return -1; 
        }
    }
    $revnamemap{$n} = lc($orig);
    return $namemap{lc($orig)} = $n;
}

sub get_so_terms {
  my $ontology = shift;
  my ($query,$sth);
  if ($ontology eq 'GO') {
    $query = "SELECT cvterm_id, name, definition FROM cvterm  WHERE cv_id in (SELECT cv_id FROM cv WHERE cv.name='biological_process' or cv.name='molecular_function' or cv.name='cellular_component') and is_relationshiptype = 0 and name not like '%obsolete %' order by cvterm_id";
    $sth = $dbh->prepare($query);
    $sth->execute();
  }
  else {
    $query = "SELECT cvterm_id, cvterm.name, cvterm.definition FROM cvterm JOIN cv USING (cv_id) WHERE cv.name=? and is_relationshiptype = 0 and cvterm.name not like '%obsolete %' order by cvterm_id";
    $sth = $dbh->prepare($query);
    $sth->execute($ontology);
  }

  my @terms = ();
  while (my $hashref = $sth->fetchrow_hashref) {
    push @terms, $hashref;
  } 

  return @terms;
}

sub get_recursive_child_terms_by_type_from_chado {
  my $parent_id = shift;
  #this would be a lot easier if the closure were already calculated
  # but SO is small, so it isn't a big deal
  my @child_terms = ();

  $child_query_handle->execute($parent_id);

  my @idlist;
  while (my $hashref = $child_query_handle->fetchrow_hashref) {
    push @child_terms, $$hashref{name};
    push @idlist, $$hashref{cvterm_id};
  }

  for my $id (@idlist) {
    push @child_terms, get_recursive_child_terms_by_type_from_chado($id);
  }

  return @child_terms;
}

sub create_lookup_table {
  my %namemap = @_;

  my $table_name = $ontology."_cv_lookup_table";

  print "CREATE TABLE $table_name (".$table_name."_id serial not null, primary key(".$table_name."_id), original_cvterm_name varchar(1024), relation_name varchar(128));\n";

  for my $orig_name (keys %namemap) {
    my $munged_table_name = $namemap{$orig_name};

    print "INSERT INTO $table_name (original_cvterm_name,relation_name) VALUES ('$orig_name','$munged_table_name');\n";
  }

  print "\nCREATE INDEX ".$table_name."_idx ON $table_name (original_cvterm_name);\n";
  return; 
}

sub get_name_map_from_db {
  my %name_map;

  my $query = "SELECT original_name, abbreviation FROM custom_name_mapping";
  my $sth   = $dbh->prepare($query);
  $sth->execute;

  while (my $hashref = $sth->fetchrow_hashref) {
    $name_map{$$hashref{original_name}} = $$hashref{abbreviation};
  }

  return %name_map;
}
__END__

=head1 NAME

create-sofa-bridge.pl

=head1 SYNPOSIS

  create-sofa-bridge.pl -d 'dbi:Pg:dbname=chado' sofa.obo

=head1 ARGUMENTS

=over

=item -d DBI-LOCATOR

Database to use as source (does not actually write to database), like 
'dbi:Pg:database=chado;host=dbserver'

=item -i

use internal surrogate database IDs (layer will be NON-PORTABLE) and
only views for which there are features in the feature table will be created.

=item -r|rtype RELATION-TYPE

RELATION-TYPE must be either TABLE or VIEW; the default is VIEW

This determines whether the layer consists of materialized views (ie
TABLEs), or views

=item --drop

If this is specified, then DROP VIEW/TABLE statements will be created

this is useful if you wish to REPLACE an existing SO layer

=item -C|Custom_namemap

If specified without an argument, query the database for a table called
custom_name_mapping with a column called original_name that contains the
exact text of the original cvterm and a column called abbreviation that
has the text of relation name.  This table may contain other columns
(like a primary key or notes).

You may also specify a argument to -C that is a series of comma delimited
tag=value pairs, where the part before the equals sign is the orginal
name of the cvterm and the part after is the relation name.

=back

=head1 DESCRIPTION

Generates views for every term in SO or SOFA

Chado is a modular database for bioinformatics. The chado
sequence module is generic and has no built-in type system for
sequence feature data. Instead it relies on an external ontology to
provide semantics for feature types.

The canonical ontology for sequence features in the Sequence Ontology
(ref). Chado has a module specifically for housing ontologies. The
combination of SO plus Chado gives a rigorous yet flexible hybrid
relational-ontology model for storing and querying genomic and
proteomic data.

One negative impact of this hybrid model is that apparently simple
queries are hard to express, and may be inefficient. For example, an
SQL select to get the gene count in the database requires joining two
relations (ie tables), instead of one relation (as expected in a
database in which types are encoded relationally, such as ensembl). To
fetch mRNAs with exons attached requires a 5 relation join. Even more
joins must be introduced if we wish to perform the transitive closure
over types (for example, a query for transcripts should return
features directly typed to transcript, as well as to subtypes, such as
mRNA, tRNA, etc).

One solution is to deal with typing issues in the middleware; however,
a solution which allows a user to make ad-hoc queries regarding typed
features in the databae is still required.

We propose a solution to this problem - a chado Sequence Ontology
extension layer. This layer provides relations for all commonly used
sequence ontology types (for example, gene, exon,
transposable_element, intron, ...). These relations can be queried as
if they are any other relation in the database; for example:

  SELECT count(*) FROM gene;

  SELECT * FROM mrna WHERE name like 'CR400%';


IMPLEMENTATION
==============

LAYER TYPE
----------

The SO layer is generated directly from a chado database
instance. Perl scripts query the database and the SO OBO file.

The implementations are possible:

1. Portable SO View layer

These views are portable and can be applied to any instance of
chado. They work by joining on the name of the SO type; if SO names
change, then this layer will have to be rebuilt.

The underlying view looks like this:

  CREATE VIEW foo AS 
  SELECT feature.*
  FROM feature INNER JOIN cvterm ON (feature.type_id=cvterm.cvterm_id)
  WHERE cvterm.name = 'foo';

[this is for basic features only]

2. Non-portable SO View layer

These views are constructed from the surrogate primary key of the sequence
ontology term in chado (cvterm.cvterm_id). Surrogate primary keys are
not portable between database instantiations; surrogate keys should
never be exposed outside the database. This layer becomes obsolete if
the sequence ontology is ever reloaded (because the surrogate keys are
not guaranteed to be preserved between loads). We provide triggers
that removes a SO view if the underlying ontology term in the database
is updated or deleted [TODO].

This layer is faster and more efficient than the non-portable layer
(because it is not actually necessary to join to the cvterm table)

The underlying view looks like this:

  CREATE VIEW foo AS 
  SELECT feature.*
  FROM feature WHERE feature.type_id = 1234

(where 1234 is the surrogate primary key of type 'foo' in the cvterm relation)

The extra speed of this layer comes at the price of less update flexibility

3. Materialized View (Table) layer

This is the fastest yet most update-restrictive way to construct the
layer.

Each SO type gets a table rather than a view. This is the fastest; for
example, when fetching genes, the database engine knows to only look
in one single (smaller) table rather than filtering out the gene type
from the (possibly enormous) feature table.

The table is constructed like this:

  CREATE TABLE foo AS 
  SELECT feature.*
  FROM feature WHERE feature.type_id = 1234

(plus indexing SQL statements)

This layer is only practical if chado is used in "data-warehouse"
mode; modification of the underlying feature data renders the
materialized views stale. One possibility is automatically rebuilding
the materialized view when the underlying feature table changes;
however, this could lead to extremely slow updates 

IMPLICIT TYPES
--------------

Not all types are instantiated within a chado database; for example,
there are no intron or UTR features as these are derivable from other
features. Nevertheless it can be useful to perform queries on
derivable types as if they were actually present.

[this is all TODO]

These types are derived using type-specific rules. For example, an
intron rules can be stated in SQL as derived from exon sibling pairs
(cv above)

  [[EXAMPLE SQL]]
  [[SKOLEM FUNCTIONS]]

Again, implicit types can be implemented as portable or non-portable
views, or as materialized views (tables).

Implicit types

  intron
  utr3
  utr5
  splice_site
  dicistronic_gene
  protein_coding_gene    [currently implicit in chado via transcript type]
  exon5prime
  exon3prime
  coding_exon
  partially_coding_exon
  intergenic_region           [HARD]

discuss - expressing these rules in SQL vs expressing in some other
delcarative language (first order predicate logic; KIF; Prolog/horn
clauses) then translating automatically to SQL.

==========
DISCUSSION
==========

Selection of which of the 3 implementation strategies to use is purely
a DB admin decision. The person constructing the SQL queries need not
know or care (other than perhaps to be aware for efficiency reasons)
how the layer is implemented - as far as they are concerned they have
relations such as gene, transcript, variation etc that act just like
normal tables when queried (but not updated - discuss updates on
views)

The view layer is not necessarily limited to chado databases - any
relational database implemented with a DBMS that allows views
(currently any DBMS other than mysql) is fair game. For example, one
could take a postgres or oracle instantiation of ensembl and write a
SO layer generator. Note that ensembl already has a
relationally-expressed notion of entities such as gene, exon etc. One
way round that is to keep the SO layer seperate in the db; eg through
postgresql SCHEMAs.

This points the way forward to a unified standard for querying genomic
databases; whilst adoption of standards for genomic relational
databases is a fraught issue at best (different groups and projects
prefer their own schemas for good reasons), we can see the need for
there being a common user-query layer, based on a standard of feature
types (ie SO).

[discussion of difficulties with doing apparently simple (and complex)
queries on existing relational databases]

=cut




