
=head1 NAME

  GMOD::Config  -- read gmod/conf/gmod.conf main settings to %ENV

=head1 USAGE

  use GMOD::Config;  # -- OR --   
  require GMOD::Config;
   # on use / require, looks for and reads conf/gmod.conf to %ENV
   # and also sets internal %CONF
   # expects gmod.conf to be in {rootpath}/conf/gmod.conf, 
   # with KEY=value lines
   
    # also use get()/put() to  access gmod.conf values
  $dbname= GMOD::Config::get('CHADO_DB_NAME');
  $oldname= GMOD::Config::put( CHADO_DB_NAME => 'mydb');

=head1 EXAMPLE

  ## command line call
  setenv DEBUG 1 # to see Config actions
  perl -I$b/gmod/lib  $b/daphnia/bin/gmod_list_db.pl  -h
   
  GMOD::Config reading configs at /Users/gilbertd/iubio/servers/daphnia/conf 
  GMOD::Config loading: gmod.conf
  setenv GMOD_ROOT=/bio/biodb/gmod
  setenv CHADO_DB_NAME=daphnia
  setenv DAPHNIA_PGDATA=/daphnia/indices/pgsql
  setenv CHADO_DB_USERNAME=gilbertd
  setenv CHADO_DB_PASSWORD=
  setenv CHADO_DB_HOST=localhost
  setenv CHADO_DB_PORT=7302
  setenv PERL5LIB=/bio/biodb/gmod/lib:/bio/biodb/common/perl/lib:/bio/biodb/common/system-local/perl/lib
  setenv GMOD_INIT=1

  Feature summary for Chado  database
  ============================================================
  Option h is ambiguous (help, host)

  
=head1 NOTES

Check %ENV for GMOD variables (ROOT path, etc.) 
and reads if needed conf/gmod.conf key value files into ENV
Assumes program is in project subfolder bin/ or like, and sibling conf/
folder exists with gmod.conf key=value settings to be loaded in %ENV at
run time.
  
=head1 SEE ALSO

More complex version is Argos::Config.
Chado::Config uses alternate methods for configs in xml.
Argos ROOT/bin/argos-env sets shell environ in similar manner.
(http://flybase.net/argos/, http://eugenes.org/argos/). 

=head1 AUTHOR

  Don Gilbert, Feb 2004.

=head1 METHODS

=cut

package GMOD::Config;

use strict;
use Config; # system Config ... namespace problems w/ lib use
use FindBin qw( $Bin $RealBin ); ## dang, this uses system Config.pm, name conflict here
use Cwd qw(getcwd abs_path);
use File::Spec;
use Exporter;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK %GmodConfig/;

our $DEBUG;

$VERSION = "0.2";
%GmodConfig=();
@ISA = qw(Exporter);
@EXPORT_OK = qw(get set);
#@EXPORT = qw(&get &set);

=item get(key)

  return value of key found in gmod.conf
  $db= GMOD::Config:get('CHADO_DB_NAME');
  %keyvals= GMOD::Config:get( qw(CHADO_DB_NAME CHADO_DB_USERNAME) );

=item put(key,val)

  put/set GMOD::Config value, returns any old value
  GMOD::Config:put('CHADO_DB_NAME',$dbname);
  %oldvals= GMOD::Config:put(
    CHADO_DB_NAME => $dbname,
    CHADO_DB_USERNAME => 'me',
    CHADO_DB_PASSWORD => 'guess',
    );

=cut

sub get {
  my @keys= @_;
  if (@keys>1 || wantarray) {
    my %vals=();
    foreach my $key (@keys) { $vals{$key}=  $GmodConfig{$key}; }
    return %vals;
    }
  else {
    return (defined $GmodConfig{$keys[0]} ? $GmodConfig{$keys[0]} : undef);
    }
}

sub put {
  my %keyvals= @_;
  my %oldvals=();
  foreach my $key (keys %keyvals) {
    $oldvals{$key}= (defined $GmodConfig{$key} ? $GmodConfig{$key} : undef);
    $GmodConfig{$key}= $keyvals{$key};
    }
  return %oldvals;
}

=item setenvKeyValueFile($dir,$file)

Read file of simple ^KEY="value"$ format into %ENV.
Comments are skipped.

=cut

sub setenvKeyValueFile {
  my($dir,$file)= @_;
  my $ok= 0;
  my $path= File::Spec->catfile($dir,$file);
  return $ok unless(-f $path);
  warn "GMOD::Config loading: $file\n" if $DEBUG;
  if (open(CONF,$path)){
    while(<CONF>){
      if (m,^(\w+)\s*=\s*["]?([^"\n\r]*),) {
        my ($k,$v)= ($1,$2); 
        $v =~ s/\$(\w+)/$ENV{$1}/g; # convert $KEY to $ENV{$KEY} to value
        $ENV{$k}= $GmodConfig{$k}= $v;
        $ok= 1;
        warn "setenv $k=$v\n" if $DEBUG; #> 1
        }
      }
    close(CONF);
    }
  return $ok;
}

=item setenvConfDir($root, $dir, $confpatt)

Process all config files of confpatt in dir folder.

=cut

sub setenvConfDir {
  my($root, $dir, $confpatt)= @_;
  my $ok= 0;
  my $path= File::Spec->catfile($root,$dir);
  return $ok unless(-d $path);
  warn "GMOD::Config reading configs at $path \n" if $DEBUG;
  if ( opendir( DIR, $path ) ) {
    my @conf = grep ( /$confpatt/, readdir(DIR));
    closedir(DIR);
    foreach my $file (sort @conf) { 
      my $ok1= setenvKeyValueFile( $path, $file); # check for .xml config?
      $ok ||= $ok1;
      }
    }
  return $ok;
}

=item BEGIN 

At eval time (use, require), this checks %ENV for GMOD_ROOT and
GMOD_INIT.  If not found, it looks in folder above calling script
(FindBin) for conf/gmod.conf as KEY=value to be loaded into %ENV.
ENV{GMOD_INIT}=1 prevents this loading.

=cut

BEGIN {

$DEBUG = $ENV{'DEBUG'} unless defined $DEBUG;
my $confpatt= 'gmod\.conf$';
my ($mybin, $myroot, $realroot)= (abs_path("$Bin"), abs_path("$Bin/.."), abs_path("$RealBin/.."));
my $servkey = 'GMOD'; 
my $ROOT= $servkey."_ROOT";  
my $INIT= $servkey."_INIT";

unless($ENV{$INIT}) {
  my $ok= 0;

  if (defined $ENV{$ROOT} && -d $ENV{$ROOT}) { $myroot= $ENV{$ROOT}; }
  else { $ENV{$ROOT}= $myroot; }
  
  my $ok1= setenvConfDir( $myroot, 'conf', $confpatt);
  $ok ||= $ok1;
  unless($ok) {
    $ok1= setenvConfDir( $mybin, 'conf', $confpatt);
    $ok ||= $ok1;
    $myroot= $mybin if ($ok1);
    }
  
  die "GMOD::Config - no $confpatt file at $myroot/conf; setenv $ROOT to locate."
    unless($ok);

  $ENV{$INIT}= 1;
  
  my @inc=();
  push(@inc,"$myroot/lib") if (-d "$myroot/lib");
  push(@inc, split /:/, $ENV{'PERL5LIB'}) if (defined $ENV{'PERL5LIB'});
  foreach my $p (@inc) {
    unshift(@INC,$p) unless( grep /^$p$/,@INC );
    }
  }
  
}


1;

