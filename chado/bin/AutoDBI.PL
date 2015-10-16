#!perl
use Config;
use File::Basename qw(&basename &dirname);
use File::Spec;
use FindBin '$Bin';
use Cwd;
  
my %OPTIONS;
if (open F,"$Bin/../build.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}

$file   = basename($0, '.PL','.PLS');
$file   = "$Bin/../lib/Bio/Chado/$file.pm";

open OUT,">$file" or die "Can't create $file: $!";
        
print "Extracting $file (with variable substitutions)\n";
               
my $startperl = $Config{startperl} ne '#!perl'
  ? $Config{startperl}
  : "#!$Config{perlpath}";
                       
print OUT <<'!NO!SUBS!';
########DBI########
package Bio::Chado::DBI;

# Created by SQL::Translator::Producer::TTSchema
# Template used: dbi.tt2

use strict;
use Data::Dumper;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
no warnings 'redefine';
use base qw(Class::DBI::Pg);

# This is how you normally connect with Class DBI's connection pooling but
# its very fragile for me on FC2.  I'm replacing it with the db_Main method below
#Bio::Chado::DBI->set_db('Main', 'dbi:Pg:dbname=chado', 'scott', '');

my $db_options = { __PACKAGE__->_default_attributes };
__PACKAGE__->_remember_handle('Main'); # so dbi_commit works
$db_options->{AutoCommit} = 0;

sub db_Main {
  my $DBPROFILE ||= 'default';   #might want to allow passing this in somehow
  my $gmod_conf = Bio::GMOD::Config->new();
  my $db_conf = Bio::GMOD::DB::Config->new( $gmod_conf, $DBPROFILE );

  my $dbname = $db_conf->name;
  my $dbhost = $db_conf->host;
  my $dbport = $db_conf->port;
  my $dbuser = $db_conf->user;
  my $dbpass = $db_conf->password;
 
  my $dbh;
  $dbh = DBI->connect_cached( 
      "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport", 
      $dbuser, 
      $dbpass, 
      $db_options );
  # clear the connection cache if can't ping
  if ($dbh->ping() < 1) {
    my $CachedKids_hashref = $dbh->{Driver}->{CachedKids};
    %$CachedKids_hashref = () if $CachedKids_hashref;
    $dbh = DBI->connect_cached(
       "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport",
       $dbuser, 
       $dbpass, 
       $db_options );
       warn("Database handle reset!: ".$dbh." ping: ".$dbh->ping());
  }
  return($dbh);
}

sub search_ilike { shift->_do_search(ILIKE => @_ ) }
sub search_lower {
   my $c = shift;
   my %q = @_;
   my %t;
   foreach my $k (keys %q){
     $t{"lower($k)"} = lc($q{$k});
   }
   $c->_do_search(LIKE => %t);
}


# debug method
sub dump {
  my $self = shift;
  my %arg  = %{shift @_};
  $arg{'indent'} ||= 1;
  $arg{'depth'} ||= 3;
  $Data::Dumper::Maxdepth = $arg{'depth'} if defined $arg{'depth'};
  $Data::Dumper::Indent = $arg{'indent'} if defined $arg{'indent'};
  return(Dumper($arg{'object'}));
}

#
#
# NOT PART OF THE API, but useful function which returns a single row
#  and throws an error if more than one is returned
#
# Added as a utility function for modware
#
sub get_single_row {
   my ($proto, @args) = @_;
   my $class = ref $proto || $proto;

   my @rows  = $class->search( @args );

   my $count = @rows;
   die "only one row expected, @rows returned" if @rows > 1;

   return $rows[0];
}


1;
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
