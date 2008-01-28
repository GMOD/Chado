package Chado::LoadDBI;

use strict;
use lib 'lib';
use Chado::AutoDBI;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

sub init
{
  my $DBPROFILE ||= 'default';   #might want to allow passing this in somehow
  my $gmod_conf = Bio::GMOD::Config->new();
  my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE );

  my $dbname = $db_conf->name;
  my $dbhost = $db_conf->host;
  my $dbport = $db_conf->port;
  my $dbuser = $db_conf->user;
  my $dbpass = $db_conf->password;

  Chado::DBI->set_db('Main',
    "dbi:Pg:dbname=$dbname;port=$dbport;host=$dbhost", 
    $dbuser,
    $dbpass,
    {
      AutoCommit => 0
    }
  );
}

1;
