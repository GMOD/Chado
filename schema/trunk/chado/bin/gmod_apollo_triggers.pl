#!/usr/bin/perl -w
use strict;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

my $USAGE = 'gmod_apollo-triggers.pl  drop|add';

my $conf = Bio::GMOD::Config->new();
my $gmod_root = $conf->gmod_root();
my $dbconf = Bio::GMOD::DB::Config->new($conf);
my $dbh = $dbconf->dbh();

if ($ARGV[0] && $ARGV[0] =~ /drop/i) {

    $dbh->do("DROP TRIGGER tr_feature_del  ON feature");
    $dbh->do("DROP TRIGGER feature_assignname_tr_i ON feature");
    $dbh->do("DROP TRIGGER feature_relationship_tr_d  ON feature_relationship");
    $dbh->do("DROP TRIGGER feature_relationship_propagatename_tr_i ON feature_relationship");
    $dbh->do("DROP TRIGGER feature_update_name_tr_u ON feature");

} elsif ($ARGV[0] && $ARGV[0] =~ /add/i) {

    $dbh->do("CREATE TRIGGER tr_feature_del BEFORE DELETE ON feature for EACH ROW EXECUTE PROCEDURE fn_feature_del()");
    $dbh->do("CREATE TRIGGER feature_assignname_tr_i AFTER INSERT ON feature for EACH ROW EXECUTE PROCEDURE feature_assignname_fn_i()");
    $dbh->do("CREATE TRIGGER feature_relationship_tr_d BEFORE DELETE ON feature_relationship for EACH ROW EXECUTE PROCEDURE feature_relationship_fn_d()");
    $dbh->do("CREATE TRIGGER feature_relationship_propagatename_tr_i AFTER INSERT ON feature_relationship FOR EACH ROW EXECUTE PROCEDURE feature_relationship_propagatename_fn_i()");
    $dbh->do("CREATE TRIGGER feature_update_name_tr_u BEFORE UPDATE ON feature FOR EACH ROW EXECUTE PROCEDURE feature_fn_u()");

} else {
  die "$USAGE\n";
}
