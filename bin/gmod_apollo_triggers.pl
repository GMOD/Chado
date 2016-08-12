#!/usr/bin/env perl
use strict;
use warnings;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

my $USAGE = 'gmod_apollo-triggers.pl  create|drop|add';

my $conf = Bio::GMOD::Config->new();
my $gmod_root = $conf->gmod_root();
my $dbconf = Bio::GMOD::DB::Config->new($conf);
my $dbname = $dbconf->name();
my $dbh = $dbconf->dbh();

if ($ARGV[0] && $ARGV[0] =~ /drop/i) {

    $dbh->do("DROP TRIGGER tr_feature_del  ON feature");
    $dbh->do("DROP TRIGGER feature_assignname_tr_i ON feature");
    $dbh->do("DROP TRIGGER feature_relationship_tr_d  ON feature_relationship");
    $dbh->do("DROP TRIGGER feature_relationship_propagatename_tr_i ON feature_relationship");
    $dbh->do("DROP TRIGGER feature_update_name_tr_u ON feature");

} elsif ($ARGV[0] && $ARGV[0] =~ /add/i) {

    $dbh->do("CREATE TRIGGER tr_feature_del 
                  BEFORE DELETE ON feature 
                  FOR EACH ROW EXECUTE PROCEDURE fn_feature_del()");
    $dbh->do("CREATE TRIGGER feature_assignname_tr_i 
                  AFTER INSERT ON feature 
                  FOR EACH ROW EXECUTE PROCEDURE feature_assignname_fn_i()");
    $dbh->do("CREATE TRIGGER feature_relationship_tr_d 
                  BEFORE DELETE ON feature_relationship 
                  FOR EACH ROW EXECUTE PROCEDURE feature_relationship_fn_d()");
    $dbh->do("CREATE TRIGGER feature_relationship_propagatename_tr_i 
                  AFTER INSERT ON feature_relationship 
                  FOR EACH ROW EXECUTE PROCEDURE feature_relationship_propagatename_fn_i()");
    $dbh->do("CREATE TRIGGER feature_update_name_tr_u 
                  BEFORE UPDATE ON feature 
                  FOR EACH ROW EXECUTE PROCEDURE feature_fn_u()");

} elsif ($ARGV[0] && $ARGV[0] =~ /create/i) {
    # select for apollo cv; bail if found
    #ontology_inserts.sql to add ad hoc ontologies that apollo needs
    #apollo.inserts to prepdb
    #cat apollo-triggers.plpgsql

    my $sth = $dbh->prepare("select * from cv where name='apollo'");    
    $sth->execute();

    if ($sth->rows > 0) {
        die <<END;

--------------------------WARNING-----------------------------------

It appears that you've already run `gmod_apollo_triggers.pl create`
Since running it again may have unintended bad concequences, you 
must continue by hand.  Chances are, you only want to update the
trigger functions.  If so, do this:

  cat $gmod_root/src/chado/modules/sequence/apollo-bridge/apollo-triggers.plpgsql | psql $dbname

after you have made your changes to the file.

--------------------------WARNING-----------------------------------
END
;
    }

    system ("cat $gmod_root/src/chado/modules/sequence/apollo-bridge/ontology_inserts.sql | psql $dbname");

    system ("cat $gmod_root/src/chado/modules/sequence/apollo-bridge/apollo.inserts | psql $dbname");

    system ("cat $gmod_root/src/chado/modules/sequence/apollo-bridge/apollo-triggers.plpgsql | psql $dbname");

} else {
  die "$USAGE\n";
}
