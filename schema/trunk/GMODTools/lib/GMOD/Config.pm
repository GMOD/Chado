
=head1 NAME

  GMOD::Config  -- read gmod/conf/gmod.conf 

=head1 SYNOPSIS

  use GMOD::Config;  # -- OR --   
  require GMOD::Config;
   # on use / require, finds and reads conf/gmod.conf to %ENV / internal %CONF
   # expects gmod.conf to be in {rootpath}/conf/gmod.conf, 
   
  $confhash= GMOD::Config::readConfig($file,$opthash);

  $confhash= GMOD::Config::readConfDir($root,$dir,$confpattern);

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
# should merge/extend Bio::GMOD::Config from Scott Cain



use strict;
use Config; # system Config ... namespace problems w/ lib use
use FindBin qw( $Bin $RealBin ); ## dang, this uses system Config.pm, name conflict here
use Cwd qw(getcwd abs_path);
use File::Spec;
use Exporter;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK 
  %GmodConfig $servkey $ROOT $INIT $confpatt $Variables/;

our $DEBUG;

BEGIN {
$VERSION = "0.4";
@ISA = qw(Exporter);
@EXPORT_OK = qw(get set);
#@EXPORT = qw(&get &set);
$servkey = 'GMOD'; 
$ROOT= $servkey."_ROOT";  
$INIT= $servkey."_INIT";
$confpatt= 'gmod\.conf$';
$Variables= \%ENV; #?
}


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
    @vals{@keys} = @GmodConfig{@keys};
    return %vals;
    }
  else {
    return (defined $GmodConfig{$keys[0]} ? $GmodConfig{$keys[0]} : undef);
    }
}

sub put {
  my %keyvals= @_;
  my %oldvals=();
  my @keys= keys %keyvals;
  @oldvals{@keys} = @GmodConfig{@keys};
  @GmodConfig{@keys} = @keyvals{@keys};
  return %oldvals;
}


sub cleanval {
  local $_= shift;
  s/^\s*//; s/\\?\s*$//; if (s/^(["'])//) { s/$1$//; }
  if ($Variables) {
    s/\$\{(\w+)\}/$Variables->{$1}/g; # convert $KEY to $ENV{$KEY} to value
    }
  return $_;
}

sub readKeyValue
{
  my ($conf, $confhash)= @_;
  $confhash= {} unless(ref $confhash);
  my ($k,$v);
  foreach (split(/\n/,$conf)) {
    next if(/^\s*[\#\!]/ || /^\s*$/); # skip comments, etc.
    if (/^([^\s=:]+)\s*[=:]\s*(.*)$/) { # must have value=(*.) to allow blanks
      ($k,$v)=($1,$2);
      $confhash->{$k}= cleanval($v);
      }
    elsif ($k && s/^\s+//) {
      $confhash->{$k} .= cleanval($_);
      }
    }
  return $confhash;
}



sub find_file  {
  my($file, @search_path) = @_;
  my($filename, $filedir) = File::Basename::fileparse($file);

  if($filename ne $file) {        # Ignore searchpath if dir component
    return($file) if(-e $file);
    }
  else {
    foreach my $path (@search_path)  {
      my $fullpath = File::Spec->catfile($path, $file);
      return($fullpath) if(-e $fullpath);
      }
    }

  # If user did not supply a search path, default to current directory
  if(!@search_path) {
    if(-e $file) { return($file); }
    # warn "File does not exist: $file";
    }
  # warn "Could not find $file in ", join(':', @search_path);
  return undef;
}


=head2 readConfig($file, $opts)

Read an XML::Simple OR Perl-struct OR key=value config file
Parameters
  $file = input; 
  $opts = XML::Simple options hash-ref
Return hash-ref options

=cut

our $readConfigOk;

sub readConfig
{
  my($file, $opts, $confhash)= @_;
  $opts= { %$opts }; # copy so delete/change ok
  $confhash = {} unless(ref $confhash);
  my $debug= delete $$opts{debug};
  $readConfigOk= 0;
  
  if (!$file || ! -e $file) {
    my($filename, $filedir);
    $opts->{searchpath}= [] unless ($opts->{searchpath});
    
    $filedir= "conf/";
    push(@{$opts->{searchpath}},$filedir) if (-d $filedir);
    
    #$filedir= "$ENV{ARGOS_SERVICE_ROOT}/conf/";
    $filedir= "$ENV{$ROOT}/conf/";
    push(@{$opts->{searchpath}},$filedir) if (-d $filedir);
    
    ($filename, $filedir) =  File::Basename::fileparse($0);
    push(@{$opts->{searchpath}},$filedir)  if (-d $filedir);
    
    if ($file) {
      ($filename, $filedir) =  File::Basename::fileparse($file);
      push(@{$opts->{searchpath}},$filedir)  if (-d $filedir);
      }
    }
    
  if (! $file ) {
    my ($ScriptDir, $Extension);
    ($file, $ScriptDir, $Extension) = File::Basename::fileparse($0, '\.[^\.]+');
    }
  
  if ($file && !-f $file) {
    foreach my $suf (".conf", ".cnf", ".xml", "" ) {
      my $cnf= find_file("$file$suf", @{$opts->{searchpath}});  
      if ($cnf) { $file= $cnf; last; }
      #if (-f "$file.$suf") { $file="$file.$suf"; last; }
      }
   }
  warn "GMOD::Config reading: $file\n" if $debug;
   
  if (!$file || ($file =~ /\.xml/ && -f $file)) {
    require XML::Simple; ## will attemp to read $0.xml file if no file given
    my $xs = new XML::Simple(%$opts); # (NoAttr => 1, KeepRoot => 1);#options
    my $conf1 = $xs->XMLin( $file); 
    if ($conf1) { 
      my @keys= keys %$conf1;
      @{%$confhash}{@keys}= @{%$conf1}{@keys};
      $readConfigOk= 1;
      }  
    }
  
  elsif (-f $file) {
    ## handle key-value file OR perl-struct
    open(F,$file); my $conf= join("",<F>); close(F);
    print STDERR "eval config\n" if $debug;
    if ($conf =~ m/=>/s && $conf =~ m/[\{\}\(\)]/s) {
      my $conf1= eval $conf; 
      if ($@) { warn "error $@"; }
      else { 
        my @keys= keys %$conf1;
        @{%$confhash}{@keys}= @{%$conf1}{@keys};
        $readConfigOk= 1;
        }  
      }
    else {
      $confhash= readKeyValue($conf, $confhash);
      $readConfigOk= 1;
      }
    }
  
  return $confhash;
}


=head2 printConfig($config, $opts)

  $config = options hash-ref
  $opts = XML::Simple options hash-ref (debug => 1 Data dumper out)
  return XML::Simple of input
  
=cut

sub showConfig
{
  my($config,$opts)= @_;
  $opts= { %$opts };
  my $debug= delete $$opts{debug};
  my $xml ='';
  
  if ($debug) {
    require Data::Dumper;
    my $dd = Data::Dumper->new([$config]);
    $dd->Terse(1);
    $xml.=  "<!-- ========= config struct ===========\n";
    $xml.=   $dd->Dump();
    $xml.=   "======================================== -->\n";
    }
    
  require XML::Simple;
  my $xs = new XML::Simple( %$opts); #NoAttr => 1, KeepRoot => 1 
  $xml.= $xs->XMLout( $config );  
  
  return $xml;
}


sub updir
{
  my ($atdir,$todirs)= @_;
  my $dir= $atdir;
  my $ok= 0;
  foreach my $td (@$todirs) { $ok= (-e "$dir/$td"); last if $ok; }
  while (!$ok && length($dir)>4) {
    $dir= File::Basename::dirname($dir)."/..";
    $dir=`cd "$dir" && pwd`; chomp($dir);
    foreach my $td (@$todirs) { $ok= (-e "$dir/$td"); last if $ok; }
    }
  return ($ok) ? $dir : $atdir;
}


=item $confhash= readConfDir($root, $dir, $confpatt, $confhash)

Process all config files of confpatt in dir folder.

=cut
our readConfDirOk;

sub readConfDir {
  my($root, $dir, $confpatt, $confhash)= @_;
  $readConfDirOk= 0;
  my $path= File::Spec->catfile($root,$dir);
  return $ok unless(-d $path);
  warn "GMOD::Config reading configs at $path \n" if $DEBUG;
  if ( opendir( DIR, $path ) ) {
    my @conf = grep ( /$confpatt/, readdir(DIR));
    closedir(DIR);
    foreach my $file (sort @conf) { 
      my $confpath= File::Spec->catfile($path,$file);
      $confhash= readConfig( $confpath, { debug => $DEBUG, Variables => $Variables }, $confhash);
      $readConfDirOk ||= $readConfigOk;
      }
    }
  return $confhash;
}



=item BEGIN 

At eval time (use, require), this checks %ENV for GMOD_ROOT and
GMOD_INIT.  If not found, it looks in folder above calling script
(FindBin) for conf/gmod.conf as KEY=value to be loaded into %ENV.
ENV{GMOD_INIT}=1 prevents this loading.

=cut

BEGIN {

# $servkey = 'GMOD'; 
# $confpatt= 'gmod\.conf$';

$DEBUG = $ENV{'DEBUG'} unless defined $DEBUG;

my $mybin= abs_path("$Bin");
my $myroot= updir( $mybin, ["common","conf"] ); # in case we are not in bin/ folder

unless($ENV{$INIT}) {
  my $ok= 0;
  %GmodConfig= ();
  
  if (defined $ENV{$ROOT} && -d $ENV{$ROOT}) { $myroot= $ENV{$ROOT}; }
  else { $ENV{$ROOT}= $myroot; }
  
  readConfDir( $myroot, 'conf', $confpatt, \%GmodConfig);
  $ok= $readConfDirOk;
  unless($ok && $myroot ne $mybin) {
    readConfDir( $mybin, 'conf', $confpatt, \%GmodConfig);
    $ok ||= $readConfDirOk;
    $myroot= $mybin if ($readConfDirOk);
    }
  
  unless($ok) {
    warn "GMOD::Config - no $confpatt file at $myroot/conf; setenv $ROOT to locate."
    }
  else { # if ($SetEnv)
    my @keys= keys %GmodConfig;
    @ENV{@keys}= @GmodConfig{@keys};
    }

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

