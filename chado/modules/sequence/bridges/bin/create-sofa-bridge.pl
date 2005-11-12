#!/usr/local/bin/perl -w

use strict;

use Carp;
use DBI;
use Getopt::Long;
use Time::HiRes qw( time );
use GO::Parser;
use Data::Dumper;

# POD DOCS AT END

use constant MAX_RELATION_NAME_LEN => 31;

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
my $schema = 'sofa';
my $verbose;
my $do_closure=1;
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
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

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
# ==============================================================
# PARSE SOFA
# ==============================================================
my $p = GO::Parser->new({handler=>'obj'});
my $f = shift || die "must pass SO or SOFA file";
$p->parse($f);
my $graph = $p->handler->graph;


# ==============================================================
# GET FEATURE TYPES
# ==============================================================
# this is only the feature types for which a feature exists within
# the particular chado implementation
my @terms = grep {!$_->is_relationship_type} @{$graph->get_all_terms};

# ==============================================================
# GET CVTERM IDS
# ==============================================================
my $trows = [];
my $used_type_ids;
if ($dbh) {
    msg("getting type to prop mappings");
    $trows =
      $dbh->selectall_arrayref("SELECT DISTINCT cvterm_id, cvterm.name
			     FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='sequence'");
    die "could not find terms" unless @$trows;
    $used_type_ids =
      $dbh->selectcol_arrayref("SELECT DISTINCT type_id FROM feature");
}
my %used_type_idh = map { $_=>1 } @$used_type_ids;
my %n2id = map { $_->[1] => $_->[0] } @$trows;
my %id2n = reverse %n2id;

my %namemap = ();
my %abbrev = ();

# make them database-safe (remove certain characters)
if ($schema) {
    print "CREATE SCHEMA $schema;\n\n";
}

msg("generating SO layer....");
foreach my $term (@terms) {
    my $tname = $term->name;
    my $def = $term->definition || '';
    my $vname = safename($tname);


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
    my $from = "INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)";
    my $where = "cvterm.name = '$tname'";
    if ($id_based) {
        my $id = $n2id{$tname};        
        $where = "feature.type_id = $id";
    }
    if ($do_closure) {
        my $cterms = 
          $graph->get_recursive_child_terms_by_type($term->acc);
        my @pnames = map {$_->name} @$cterms;
        if (%used_type_idh) {
            @pnames = grep { $used_type_idh{$n2id{$_}} } @pnames;
        }
        @pnames = map {safename($_)} @pnames;
        if ($id_based) {
            $where = join(' OR ',
                          map {"cvterm.name = '$_'"} map {$n2id{$_}} @pnames);
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
	$from = "";
	$cmnt = "--- This view is derived from the cvterm database ID.\n".
	  "--- This will be more efficient, but the views MUST be regenerated\n".
	    "--- when the Sequence Ontology in the database changes\n";
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
    printf("--- ************************************************\n".
	   "--- *** relation: %-31s***\n".
	   "--- *** relation type: $RTYPE                      ***\n".
	   "--- ***                                          ***\n".
           $defcmt.
	   "--- ************************************************\n".
	   "---\n".
	   "\n".
	   "$vsql;\n\n",
	  $vname);

    if ($RTYPE eq 'TABLE') {
	print "\n\n--- *** Auto-generated indexes ***\n";
	foreach my $col (@cols) {
	    print "CREATE INDEX $vname"."_idx_$col ON $vname ($col);\n";
	}
    }


}

$dbh->disconnect if $dbh;
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
    $n =~ s/\./_/;
    my @parts = ();
    @parts = split(/_/, $n);
    @parts = map {$abbrev{$_} || $_} @parts;
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
    while (my $part = shift @parts) {
	$n .= $part;
	if (@parts && (length($part) > 1 || length($parts[0]) > 1)) {
	    $n.= '_';
	}
    }
#    print "NAMEMAP: $orig -> $n\n";
    $namemap{lc($orig)} = $n;
}

__END__

=head1 NAME

create-sofa-bridge.pl

=head1 SYNPOSIS

  create-sofa-bridge.pl -d 'dbi:Pg:dbname=chado' sofa.obo

=head1 ARGUMENTS

=over

=item -d DBI-LOCATOR

Database to use as source (does not actually write to database)

=item -i

use internal surrogate database IDs (layer will be NON-PORTABLE)

=item -r|rtype RELATION-TYPE

RELATION-TYPE must be either TABLE or VIEW; the default is VIEW

This determines whether the layer consists of materialized views (ie
TABLEs), or views

=item -d|drop

If this is specified, then DROP VIEW/TABLE statements will be created

this is useful if you wish to REPLACE an existing SO layer

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




