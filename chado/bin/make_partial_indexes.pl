#!/usr/bin/env perl 
use strict;
use warnings;

use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=gadfly",'','');

my $type = 'chromosome_arm';

my $sth = $dbh->prepare("select feature_id from feature f, cvterm cv
                        where cv.name = ? and cv.cvterm_id=f.type_id");
$sth->execute($type);

while (my $ida = $sth->fetchrow_arrayref) {
  my $id = $$ida[0];
  warn "creating partial index on srcfeature_id $id ...\n";
  $dbh->do("create index featureloc_src_$id on featureloc (fmin,fmax)
            where srcfeature_id = $id");  
}

$dbh->disconnect;
