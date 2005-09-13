#!perl -w

use Config;
use File::Basename qw(&basename &dirname);
use FindBin '$Bin';
use Cwd;


$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file = "gmod_$file.pl";

my %OPTIONS;
if (open F,"$Bin/../../build.conf") {
  while (<F>) {
    next if /^\#/;
    chomp;
    $OPTIONS{$1} = $2 if /^(\w+)\s*=\s*(.+)/;
  }
  close F;
}


open OUT,">$file" or die "Can't create $file: $!";
print OUT "$Config{startperl} -w\n";

if ($OPTIONS{LIB}) {
  print OUT "use lib '$OPTIONS{LIB}';\n";
}
if ($OPTIONS{PREFIX}) {
  print OUT "use lib '$OPTIONS{PREFIX}/lib';\n";
}

print OUT <<'!NO!SUBS!';
use strict;
use Getopt::Long;

=head1 OPTIONS

  --database <dbname>    Name of the database to use
  --available_dbs        List of available chado databases
  --all_tags             List of all parameters known about a database
  --has_tag <tag>        Returns 1 or 0 on stdout if 
                          the given parameter is available
  --get_tag_value <tag>  Returns the value for the given tag
  --confdir              Returns the path for the configuration files
  --tmpdir               Returns the tmp directory path
  --gmod_root            Returns the gmod_root path
  --user                 Returns the username for the database
  --password             Returns the password for the database
  --host                 Returns the host name for the database
  --port                 Returns the port number for the database
  --driver               Returns the database driver for the database 
  --name                 Returns the name of the database
  --sqlfile              Returns the full path to the DDL file for the database
  --organism             Returns the common name of the default organism

=cut

GetOptions(
  'available_dbs'   => \$AVAIL,
  'all_tags'        => \$ALL_TAGS,
  'has_tag=s'       => \$HAS_TAG,
  'get_tag_value=s' => \$GET_TAG_VALUE,
  'confdir'         => \$CONFDIR,
  'tmpdir'          => \$TMPDIR,
  'gmod_root:s'     => \$GMOD_ROOT,
  'user'            => \$USER,
  'password'        => \$PASSWORD,
  'host'            => \$HOST,
  'port'            => \$PORT,
  'driver'          => \$DRIVER,
  'name'            => \$NAME,
  'sqlfile'         => \$SQLFILE,
  'organism'        => \$ORGANISM,
  'database:s'      => \$DATABASE,
) or ( system ('pod2text', $0), exit -1);




my $gmod_conf = $ENV{'GMOD_ROOT'} || "/var/lib/gmod";

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
chdir $origdir;

