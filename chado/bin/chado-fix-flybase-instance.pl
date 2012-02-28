#!/usr/bin/env perl

use strict;
use warnings;
use DBIx::DBStag;
use Getopt::Long;

$|= 1;

my $opt = {};
GetOptions($opt,
           "skip_type_id=s",
           "commands|c=s",
           "db|d=s");

my @commands = split(//,$opt->{commands});
my $dbh = DBIx::DBStag->connect($opt->{db});
$dbh->dbh->{AutoCommit} = 1;

print <<EOM

chado-fix-flybase-instance.pl

the chado available from FlyBase uses an older schema. Most of this
can be migrated using chado/doc/flybase_chado/schema_notes.txt

however, making cvterm.dbxref_id NOT NULL (to use it in a UNIQUE
constraint) is more problematic

skipping interactive mode; pre-answer questions like this:
chado-fix-flybase-instance.pl -c nnnnyyynnny

EOM
;

print "Please answer the following questions. y/n\n";
print "Type 'h' for an explanation. If in doubt, select YES\n\n\n";

dosql("UPDATE cv SET name='obs_sequence' WHERE name='SO'");
dosql("UPDATE db SET name='obs_SO' WHERE name='SO'");
dosql("UPDATE cv SET name='obs_relationship' WHERE name='relationship type'");

# triggers slow things down
dosql("drop trigger feature_propagatename_tr_u on feature");
dosql("drop trigger feature_upd_audit on feature");

my $cvterm_rows =
  $dbh->selectall_arrayref("SELECT cvterm_id, cv.name, cvterm.name FROM cvterm INNER JOIN cv USING (cv_id) WHERE dbxref_id IS NULL");

if (yesno("generate fake cvterm dbxrefs",
          "flybase chado was built when cvterm.dbxref_id was nullable. we need to add the NOT NULL constraint, but we first need to make sure every cvterm has a unique dbxref. We create fakes ones where db=cv and accession=cvterm.name")) {
    $dbh->trust_primary_key_values(1);
    $dbh->is_caching_on('db',1);
    foreach my $r (@$cvterm_rows) {
        my ($id,$cv,$name) = @$r;
        next if $cv =~ /molecular_function/;
        next if $cv =~ /biological_process/;
        next if $cv =~ /cellular_component/;
        my $node = Data::Stag->new(cvterm=>[
                                            [cvterm_id=>$id],
                                            [is_obsolete=>1],
                                            [dbxref=>[
                                                      [db=>[
                                                            [name=>$cv]
                                                           ]],
                                                      [accession=>$name]
                                                     ]],
                                           ]);
        $dbh->storenode($node);
    }
}

dosql("ALTER TABLE cvterm ALTER COLUMN dbxref_id SET NOT NULL");
dosql("ALTER TABLE cvterm ADD CONSTRAINT cvterm_c1 unique (dbxref_id)");
dosql("ALTER TABLE cvterm ADD CONSTRAINT cvterm_c2 unique (name, cv_id, is_obsolete)");

my $ontol_dir = $ENV{ONTOL_DIR} || "$ENV{HOME}/cvs";
my @onts =
  (
   [relationship=>"$ontol_dir/obo/ontology/OBO_REL/relationship.obo"],
   [sequence=>"$ontol_dir/song/ontology/so.obo"],
   [featureprop=>"$ontol_dir/song/ontology/fpo/feature_property.obo"],
  );
# TODO - load real ontologies

foreach my $pair (@onts) {
    my ($ont,$path) = @$pair;
    if (yesno("load ont: $ont", "the pre-loaded ontologies in flybase are problematic. the cv.name is wrong, and they may be out of date")) {
        my $outf = "$ont.chado-xml";
        my $cmd = "go2chadoxml $path > $outf";
        system($cmd) && die("problem with: $cmd");
        my $chadonode = Data::Stag->parse($outf);
        $dbh->storenode($_) foreach $chadonode->subnodes;
    }
}

migrate_type_id("feature","type_id","sequence","golden_path_region","golden_path_fragment");
migrate_type_id("feature_relationship","type_id","relationship","partof","part_of");
migrate_type_id("feature_relationship","type_id","relationship","producedby","derives_from");
if (yesno("Migrate type_ids to real ontologies",
          "various type_ids may point to the old incorrect ontologies. this fixes that and points to the canonical ontologies: sequence, relationship and feature_property")) {
    migrate_type_ids_by_table("feature_relationship","type_id","relationship");
    migrate_type_ids_by_table("feature","type_id","sequence");
    migrate_type_ids_by_table("featureprop","type_id","feature_property");
}

if (yesno("set type for all subject match features (eg HSPs) to match_part",
          "flybase has match part_of match for hits/HSPs. make the subfeature a match part")) {
    my $match_id =
      selectcol("SELECT DISTINCT cvterm_id FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='sequence' AND cvterm.name='match'");
    my $match_part_id =
      selectcol("SELECT DISTINCT cvterm_id FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='sequence' AND cvterm.name='match_part'");
    dosql("UPDATE feature SET type_id = $match_part_id WHERE type_id = $match_id AND feature_id IN (SELECT subject_id FROM feature_relationship)");
}

exit 0;

# ---

our %db_id_by_name = ();
sub store_db {
    my $n = shift;
    my $id =
      $db_id_by_name{$n};
    return $id if $id;
    
}

sub dosql {
    my $cmd = shift;
    if (yesno($cmd, "execute the given SQL")) {
        $dbh->do($cmd)
    }
}

sub selectall {
    my $sql = shift;
    print STDERR "QUERY:$sql\n";
    return $dbh->selectall_arrayref($sql);
}

sub selectcol {
    my $sql = shift;
    my $rows = selectall($sql);
    my $row = shift @$rows;
    if (!$row) {
        die("expected row!");
    }
    return $row->[0];
}

sub yesno {
    my ($prompt,$help) = @_;
    print "$prompt ";
    print "[y/n/help]? ";
    my $ans;
    if (@commands) {
        $ans = shift @commands;
    }
    else {
        $ans = <STDIN>;
    }
    if ($ans =~ /^h/i) {
        print "EXPLANATION:\n$help\n\n";
        return yesno($prompt, "I can't tell you anything more!");
    }
    my $yn;
    $yn = 1 if $ans =~ /^y/i;
    if ($yn) {
        print "OK!\n";
    }
    else {
        print "Skipping\n";
    }
    return $yn;
}

sub migrate_type_ids_by_table {
    my ($table,$col,$cv) = @_;
    my $pk = $table."_id";

    my $skip = $opt->{skip_type_id};
    my $rows =
      selectall("SELECT DISTINCT t2.cvterm_id, t.cvterm_id FROM $table AS x INNER JOIN cvterm AS t ON (x.$col = t.cvterm_id) INNER JOIN cvterm AS t2 ON (t.name=t2.name) INNER JOIN cv ON (cv.cv_id = t2.cv_id) WHERE cv.name='$cv' AND t.cv_id != cv.cv_id");

    foreach my $r (@$rows) {
        my ($cvterm_id,$old_cvterm_id) = @$r;
        if ($skip) {
            if ($old_cvterm_id == $skip) {
                print STDERR "SKIPPING $old_cvterm_id to $cvterm_id\n";
                next;
            }
        }
	print STDERR "mapping $old_cvterm_id to $cvterm_id\n";
	$dbh->do("UPDATE feature SET type_id = $cvterm_id WHERE type_id=$old_cvterm_id");
        print STDERR "Done!\n";
	#print "UPDATE feature SET type_id = $cvterm_id WHERE type_id=$old_cvterm_id\n";
    }
}

sub migrate_type_id {
    my ($table,$col,$cv,$from,$to) = @_;
    my $pk = $table."_id";

    if (yesno("map $from to $cv/$to in $table.$col",
              "the type_ids in the table \"$table\" point to a deprecated cvterm \"$from\" - make them point to \"$to\", which is in the newly loaded \"$cv\" cv")) {
        my $rows =
          selectall("SELECT DISTINCT cvterm_id FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name!='$cv' AND cvterm.name='$from'");
        return unless @$rows; # done already
        if (@$rows > 1) {
            die("assertion error!");
        }
        my $old_type_id = $rows->[0]->[0];
        $rows =
          selectall("SELECT DISTINCT cvterm_id FROM cvterm INNER JOIN cv USING (cv_id) WHERE cv.name='$cv' AND cvterm.name='$to'");
        if (@$rows != 1) {
            die("assertion error! expected one row for $to in $cv; got: @$rows");
        }
        my $new_type_id = $rows->[0]->[0];
        
        print STDERR "map $old_type_id to $new_type_id in $table.$col\n";
        $dbh->do("UPDATE $table SET $col = $new_type_id WHERE $col=$old_type_id");
        print STDERR "Done!\n";
    }
}
