#!/usr/local/bin/perl -w

use strict;

use Carp;
use DBI;
use Getopt::Long;
use Time::HiRes qw( time );

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
my $verbose;
GetOptions(
           "help|h"=>\$help,
	   "db|d=s"=>\$db,
	   "file|f=s"=>\$file,
	   "user|u=s"=>\$user,
	   "pass|p=s"=>\$pass,
	   "id_based|i"=>\$id_based,
           "count|c"=>\$count,
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
eval {
    require "DBIx/DBStag.pm";
    my $sdbh = 
      DBIx::DBStag->connect($db, $user, $pass);
    $dbh = $sdbh->dbh;
};
if ($@) {
    # stag not installed - use DBI
    $dbh =
      DBI->connect($db, $user, $pass);
}

$dbh->{RaiseError} = 1;

# ==============================================================
# GET FEATURE TYPES
# ==============================================================
my $ftypes =
  $dbh->selectall_arrayref(q[SELECT DISTINCT cvterm.cvterm_id, cvterm.name
			     FROM feature INNER JOIN cvterm ON (cvterm_id=type_id)
			    ]);
# ==============================================================
# GET FEATURE PROPERTY TAG NAMES
# ==============================================================
my $ptypes =
  $dbh->selectall_arrayref("SELECT DISTINCT cvterm.cvterm_id, cvterm.name
			     FROM featureprop INNER JOIN cvterm ON (cvterm_id=$PROPTYPE_ID)");

# ==============================================================
# GET FEATURE TYPE TO PROPERTY MAPPING
# ==============================================================
# some feature types only have some kind of property
my $ft2ps =
  $dbh->selectall_arrayref("SELECT DISTINCT  feature.type_id, featureprop.cvterm_id
			     FROM featureprop INNER JOIN feature USING (feature_id)");


# ==============================================================
# GET FEATURE FEATURE RELATIONSHIPS
# ==============================================================
# treat them all indiscriminately for now
my $partofs =
  $dbh->selectall_arrayref(q[SELECT DISTINCT subjf.type_id, objf.type_id
			     FROM feature_relationship INNER JOIN feature AS subjf ON (subjf.feature_id =subject_id)
			     INNER JOIN feature AS objf ON (objf.feature_id = object_id)
			    ]);

# ftypes and ptypes are two columns; id and name
# create a lookup table
my %typemap = map {$_->[0] => $_->[1]} (@$ftypes, @$ptypes);

my %namemap = ();
my %abbrev = ();

# get all the feature type names and property names
my @names = map {$_->[1]} (@$ftypes, @$ptypes);

# make them database-safe (remove certain characters)
my @safenames = map {safename($_)} @names;

foreach my $type (@$ftypes) {
    my $tname = $type->[1];
    my $vname = $namemap{lc($tname)} || die("nothing for @$type");

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
#	   "    CAST($vname' AS VARCHAR(64)) AS typestr,",
           "    feature.*",
	   "  FROM",
	   "    feature %s",
	   "  WHERE %s",
	  );
    my $from = "INNER JOIN cvterm ON (feature.type_id = cvterm.cvterm_id)";
    my $where = "cvterm.name = '$tname'";
    my $cmnt = "";
    if ($id_based) {
	$from = "";
	$where = "feature.type_id = $type->[0]";
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

    printf("--- ************************************************\n".
	   "--- *** relation: %-31s***\n".
	   "--- *** relation type: $RTYPE                      ***\n".
	   "--- ***                                          ***\n".
	   "--- *** Sequence Ontology 'Typed Feature' View   ***\n".
	   "--- ***                                          ***\n".
	   "--- ************************************************\n".
	   "---\n".
	   "--- SO Term:\n".
	   "--- \"$tname\"\n".
	   $cmnt.
	   "\n".
	   "$vsql;\n\n",
	  $vname);

    if ($RTYPE eq 'TABLE') {
	print "\n\n--- *** Auto-generated indexes ***\n";
	foreach my $col (@ifcols, $vname.'_id') {
	    print "CREATE INDEX $vname"."_idx_$col ON $vname ($col);\n";
	}
    }

    # PAIRS

    foreach my $is_consecutive (0 1) {
        my $pref = $is_consecutive ? 
        my $pvname = 'sib_'.$vname;
        if ($drop) {
            print"DROP $RTYPE $pvname  CASCADE;\n";
        }

        @cols = ();
        @selcols =
          map {
              my $n = $_;
              map {
                  my $alias = "$_$n";
                  #		   if (/(.*)_id/) {
                  #		       $alias = "$1$n"."_id";
                  #		   }
                  push(@cols, $alias);
                  "    $vname$n.$_ AS $alias" 
              } @fcols
          } qw(1 2);
    
        $sel =
          join(",\n", @selcols);

        my $vname1 = $vname . '1';
        my $vname2 = $vname . '2';
        printf("--- ************************************************\n".
               "--- *** relation: %-31s***\n".
               "--- *** relation type: $RTYPE                      ***\n".
               "--- ***                                          ***\n".
               "--- *** Sequence Ontology Feature Sibling View   ***\n".
               "--- *** features linked by common container      ***\n".
               "--- ************************************************\n".
               "---\n".
               "--- SO Term:\n".
               "--- \"$tname\"\n".
               "CREATE $RTYPE $pvname AS\n".
               "  SELECT\n".
               "    fr1.object_id,\n".
               "    fr1.rank AS rank1,\n".
               "    fr2.rank AS rank2,\n".
               "    fr2.rank - fr1.rank AS rankdiff,\n".
               "$sel\n".
               "  FROM\n".
               "    $vname AS $vname1 INNER JOIN\n". 
               "    feature_relationship AS fr1 ON ($vname1.$vname"."_id = fr1.subject_id)\n".
               "    INNER JOIN\n".
               "    feature_relationship AS fr2 ON (fr2.object_id = fr1.object_id)\n".
               "    INNER JOIN\n".
               "    $vname AS $vname2 ON ($vname1.$vname"."_id = fr2.subject_id);\n".
               "\n\n",
               $pvname);

        if ($RTYPE eq 'TABLE') {
            print "\n\n--- *** Auto-generated indexes ***\n";
            foreach my $col (@cols, 'rankdiff') {
                print "CREATE INDEX $pvname"."_idx_$col ON $pvname ($col);\n";
            }
        }
    }

    # INVERSE PAIRS

    $pvname = $vname . '_invpair';
    if ($drop) {
	print"DROP $RTYPE $pvname  CASCADE;\n";
    }
    @cols = ();
    @selcols =
      map {
	  my $n = $_;
	  map {
	      my $alias = "$_$n";
	      #		   if (/(.*)_id/) {
	      #		       $alias = "$1$n"."_id";
	      #		   }
	      push(@cols, $alias);
	      "    $vname$n.$_ AS $alias" 
	  } @fcols
      } qw(1 2);
    
    $sel =
      join(",\n", @selcols);
    $vname1 = $vname . '1';
    $vname2 = $vname . '2';
    printf("--- ************************************************\n".
	   "--- *** relation: %-31s***\n".
	   "--- *** relation type: $RTYPE                      ***\n".
	   "--- ***                                          ***\n".
	   "--- *** Sequence Ontology Feature Inverse Pair   ***\n".
	   "--- *** features linked by common contained      ***\n".
	   "--- *** child feature                            ***\n".
	   "--- ************************************************\n".
	   "---\n".
	   "--- SO Term:\n".
	   "--- \"$tname\"\n".
	   "CREATE $RTYPE $pvname AS\n".
	   "  SELECT\n".
	   "    fr1.subject_id,\n".
	   "    fr1.rank AS rank1,\n".
	   "    fr2.rank AS rank2,\n".
	   "    fr2.rank - fr1.rank AS rankdiff,\n".
	   "$sel\n".
	   "  FROM\n".
	   "    $vname AS $vname1 INNER JOIN\n". 
	   "    feature_relationship AS fr1 ON ($vname1.$vname"."_id = fr1.object_id)\n".
	   "    INNER JOIN\n".
	   "    feature_relationship AS fr2 ON (fr2.subject_id = fr1.subject_id)\n".
	   "    INNER JOIN\n".
	   "    $vname AS $vname2 ON ($vname1.$vname"."_id = fr2.object_id);\n".
	   "\n\n",
	  $pvname);

    if ($RTYPE eq 'TABLE') {
	print "\n\n--- *** Auto-generated indexes ***\n";
	foreach my $col (@cols) {
	    print "CREATE INDEX $pvname"."_idx_$col ON $pvname ($col);\n";
	}
    }

}

foreach my $po (@$partofs) {
    my ($stid, $otid) = @$po;
    my $st1 = $typemap{$stid} || die "no type for $stid";
    my $ot1 = $typemap{$otid} || die "no type for $otid";
    my $st = $namemap{lc($st1)} || die "no namemap for $st1";
    my $ot = $namemap{lc($ot1)} || die "no namemap for $ot1";
    my $vname = $ot."2".$st;

    my @cols = 
      (
       'feature_relationship_id',
       $st.'_id',
       $ot.'_id',
       'subject_id',
       'object_id'
      );

		  
    my $vsql =
      join("\n",
	   "CREATE $RTYPE $vname AS",
	   "  SELECT",
	   "    feature_relationship_id,",
	   "    subject_id AS $st"."_id,",
	   "    object_id AS $ot"."_id,",
	   "    subject_id,",
	   "    object_id,",
	   "    feature_relationship.type_id",
	   "  FROM",
	   "    $st INNER JOIN feature_relationship ON ($st.feature_id = subject_id)",
	   "        INNER JOIN $ot ON ($ot.feature_id = object_id)",
	  );

    if ($drop) {
	print"DROP $RTYPE $vname CASCADE;\n";
    }
    printf("--- ************************************************\n".
	   "--- *** relation: %-31s***\n".
	   "--- *** relation type: $RTYPE                      ***\n".
	   "--- ***                                          ***\n".
	   "--- *** Sequence Ontology PART-OF view           ***\n".
	   "--- ************************************************\n".
	   "---\n".
	   "--- Subject Type: $st\n".
	   "--- Object Type:  $ot\n".
	   "--- Predicate:    PART-OF\n".
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

$dbh->disconnect;
print STDERR "Done!\n";
exit 0;

# ==============================================================
# safename(string): returns string
# ==============================================================
# makes a name db-safe; also adds the mapping
# from the original name to safe name in the global lookup %namemap
sub safename {
    my $orig = shift;
    my $n = lc($orig);
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

create-so-layer.pl

=head1 SYNPOSIS

  create-so-layer.pl -d 'dbi:Pg:dbname=chado;hostname=mypghost.foo.org'

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

Other relations are also provided which represent instantiation
Sequence Ontology part_of and develops_from relationships. For
example, SO contains the relationship "transcript part_of gene", so we
would expect to find instantiations of this relationship in a chado
database. We create "virtual linking relations" for all these, for
example:

  gene2transcript  -- gene to *any* transcript feature
  gene2mrna        -- gene to mRNA feature specifically
  mrna2exon
  trna2exon
  mrna2protein   [polypeptide??]
  gene2mrna2exon

This allows a more natural way of expressing queries, for example over
gene models; compare:

  SELECT * 
  FROM 
    gene2mrna NATURAL JOIN mrna2exon NATURAL JOIN mrna2protein 
  NATURALJOIN
    gene NATURAL JOIN mrna NATURAL JOIN exon NATURAL JOIN protein

with:

  [equivalent direct chado SQL query without SO layer]

In addition, we provide relations for other more complex and
transitive relationship types in SO

Transitive relationship types: [TODO]

All relationship types in SO are transitive; for example, transcript
is proper part of gene, exon is proper part of transcripts; therefore
exon is transitively part of gene. Again, virtual linking tables can
be generated from a chado instance; so far we generate

  gene2exon
  gene2protein

Currently these are the only transitive non-isa chains in SO (TODO -
karen check..)

We also provide transitive linking tables that explicitly include the
full path:

  gene2transcript2exon
  gene2mrna2exon
  gene2trna2exon
  gene2ncrna2exon

Other relationship chains:

[THE FOLLOWING TWO FORMS ARE JUST SQLization OF KAREN'S IDEAS ON
MEREONOMY WITH SO; check with karen re the names "sibling pairs"
"parent pairs"]

Sibling pairs

Sibling pairs are features of any type related by a common parent; for
example, exons that share the same transcript container. We create
virtual linking tables for these; for example

  exon_pair
  transcript_pair
  protein_pair

Consecutive Sibling pairs [TODO]

These are sibling pairs when the siblings are explicitly consecutive;
this is provided by the feature_relationship.rank table in chado

Parent pairs:

An parent pair is two features with a child/contained feature in
common. For example, two mRNAs that produce the same protein; two
transcripts that contain the same exon (note that this is almost
always when the transcripts are siblings-by-parent-genes; but a parent
pair allows the user to see by which exons the transcripts are
related)

  transcript_invpair
  protein_invpair

PROPERTIES [TODO]

features can have any number of property name=value pairs attached to
them in chado. The name of the property comes from a controlled
vocabulary of sequence feature properties. Eventually the canonical
list of properties will be regulated by SO, for now they live in chado
as an external ontology.

Again, because the featureprop table has a foreign key to the primary
surrogate key in the cvterm table, some queries can be awkward to
express and involve many joins.

To get round this, the SO layer also provides views for common
properties; here we have a cross-product between relations, but not
all relations have all properties; for example, only exons and
predicted exons have the property KaKs

  feature_foo
  gene_foo
  feature_kaks
  exon_kaks

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




