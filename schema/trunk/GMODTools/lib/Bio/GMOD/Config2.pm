package Bio::GMOD::Config2;
use strict;

=head1 NAME

Bio::GMOD::Config2 -- an extended GMOD utility package for reading config files

=head1 SYNOPSIS


  $ export GMOD_ROOT=/usr/local/gmod
  ..
  
  use Bio::GMOD::Config2;
  
  my $conf2   = Bio::GMOD::Config2->new();
  my $confdir = $conf2->confdir();
  
  $confhash = $conf2->config();
  $confhash = $conf2->readConfig($file); # can be XML, Perl-Struct or key=value
  $confhash = $conf2->readConfDir($dir, '(gmod|\w+db)\.conf');
  
  $dbname  = $conf2->get('CHADO_DB_NAME');
  $oldname = $conf2->put( CHADO_DB_NAME => 'mydb');

  print $conf2->showConfig(); # XML::Simple output
  
=head1 NOTES

Check %ENV for GMOD variables (ROOT path, etc.) 
and reads if needed conf/gmod.conf key value files into ENV
Assumes program is in project subfolder bin/ or like, and sibling conf/
folder exists with gmod.conf key=value settings to be loaded in %ENV at
run time.
  
merge/extend of Bio::GMOD::Config from Scott Cain and older dgg version


=head1 AUTHOR

  Don Gilbert, Feb..Aug 2004.

=head1 METHODS

=cut


use Config; # system Config ... namespace problems w/ lib use
use FindBin qw( $Bin ); ## dang, this uses system Config.pm, name conflict here
use Cwd qw(abs_path);
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;
# use Exporter;

use Bio::GMOD::Config;

use vars qw/@ISA @EXPORT @EXPORT_OK $BASE $ROOT $INIT $Variables/;

our $DEBUG;
our $VERSION = "0.4";

BEGIN {
$DEBUG = 0;
@ISA = qw/ Bio::GMOD::Config /;
# @ISA = qw(Exporter);
# @EXPORT_OK = qw(get set);
#@EXPORT = qw(&get &set);
$ROOT= "GMOD_ROOT";  
$INIT= "GMOD_INIT";
$BASE= undef;
$Variables= \%ENV; #?
}



=head2 new

 Title   : new
 Usage   : my $config = Bio::GMOD::Config2->new('/path/to/gmod');
 Function: create new Bio::GMOD::Config object
 Returns : new Bio::GMOD::Config2
 Args    : optional path to gmod installation
 Status  : Public

Takes one optional argument that is the path to the root of the GMOD 
installation.  If that argument is not provided, Bio::GMOD::Config will
fall back to the enviroment variable GMOD_ROOT, which should be defined
for any GMOD installation.

=cut


sub new {
  my $self = shift;
  my $arg  = shift;

  my $root;
  if ($arg) {
    $root = $arg; #can override the environment variable
  } elsif($BASE)  {
    $root= $BASE->{'gmod_root'};
  } else {
    $root = $ENV{'GMOD_ROOT'};  #required
  }

  my $confdir = catdir($root, 'conf'); 
  my @db= ();
  my $confhash= {};
  my $confpatt= '(gmod|[\w_\-]+db)\.conf$'; # FIXME - need caller opts
  
#   die "Please set the GMOD_ROOT environment variable\n"
#      ."It is required from proper functioning of gmod" unless ($root);
# 
#   my $confdir = catdir($root, 'conf'); #not clear to me what should be in
#                                     #gmod.conf since db stuff should go in
#                                     #db.conf (per programmers guide)
# 
#   my @db;
#   opendir CONFDIR, $confdir
#      or die "couldn't open $confdir directory for reading:$!\n";
#   my $dbname;
#   while (my $dbfile = readdir(CONFDIR) ) {
#       ## dgg - too liberal - we store apache.conf, cmap.conf, other.conf in conf/ dir
#       if ($dbfile =~ /^(\w+)\.conf/) {
#           push @db, $1;
#       } else {
#           next;
#       }
#   }
#   closedir CONFDIR;
# 
#   my %conf;
#   my $conffile = catfile($confdir, 'gmod.conf');
#   open CONF, $conffile or die "Unable to open $conffile: $!\n";
#   while (<CONF>) {
#       next if /^\#/;
#       if (/(\w+)\s*=\s*(\S.*)$/) {
#           $conf{$1}=$2;
#       }
#   }
#   close CONF;

  #?? $self= $self->SUPER::new($root || abs_path("$Bin/.."));


  return bless {db       => \@db,
                conf     => $confhash,
                confdir  => $confdir,
                confpatt => $confpatt,
                gmod_root=> $root}, $self;
}


=head2 $confhash= config()

=head2 get(key)

  return value of key found in gmod.conf
  $db= $conf->get('CHADO_DB_NAME');
  %keyvals= $conf->get( qw(CHADO_DB_NAME CHADO_DB_USERNAME) );
  
  SEE ALSO get_tag_value
  
=head2 put(key,val)

  put/set GMOD::Config value, returns any old value
  $conf->put('CHADO_DB_NAME',$dbname);
  %oldvals= $conf->put(
    CHADO_DB_NAME => $dbname,
    CHADO_DB_USERNAME => 'me',
    CHADO_DB_PASSWORD => 'guess',
    );

=cut

sub config {
  return shift->{'conf'}; 
}

sub get {
  my $self = shift;
  my $confhash = $self->{'conf'}; # \%GmodConfig;
  my @keys= @_;
  if (@keys>1 || wantarray) {
    my %vals=();
    @vals{@keys} = @{%$confhash}{@keys};
    return %vals;
    }
  else {
    return (defined $confhash->{$keys[0]} ? $confhash->{$keys[0]} : undef);
    }
}

sub put {
  my $self = shift;
  my $confhash = $self->{'conf'}; # \%GmodConfig;
  my %keyvals= @_;
  my %oldvals=();
  my @keys= keys %keyvals;
  @oldvals{@keys} = @{%$confhash}{@keys};
  @{%$confhash}{@keys} = @keyvals{@keys};
  return %oldvals;
}


sub _cleanval {
 #?? my $self = shift;
  local $_= shift;
  s/^\s*//; s/\\?\s*$//; if (s/^(["'])//) { s/$1$//; }
  if ($Variables) {
    s/\$\{(\w+)\}/$Variables->{$1}/g; # convert $KEY to $ENV{$KEY} to value
    }
  return $_;
}


sub _find_file  {
  #?? my $self = shift;
  my($file, @search_path) = @_;
  my($filename, $filedir) = File::Basename::fileparse($file);

  if($filename ne $file) {        # Ignore searchpath if dir component
    return($file) if(-e $file);
    }
  else {
    foreach my $path (@search_path)  {
      my $fullpath = catfile($path, $file);
      return($fullpath) if(-e $fullpath);
      }
    }

  # If user did not supply a search path, default to current directory
  if(!@search_path) {
    if(-e $file) { return($file); }
    }
  return undef;
}


=head2 readKeyValue($confval, $confhash)

Read $confval string for key=value lines
Return hash-ref options

=cut

sub readKeyValue
{
  my $self = shift;
  my ($confval, $confhash)= @_;
  $confhash = $self->{'conf'} unless(ref $confhash);
  $confhash = {} unless(ref $confhash);
  my ($k,$v);
  foreach (split(/\n/,$confval)) {
    next if(/^\s*[\#\!]/ || /^\s*$/); # skip comments, etc.
    if (/^([^\s=:]+)\s*[=:]\s*(.*)$/) { # must have value=(*.) to allow blanks
      ($k,$v)=($1,$2);
      $confhash->{$k}= _cleanval($v);
      }
    elsif ($k && s/^\s+//) {
      $confhash->{$k} .= _cleanval($_);
      }
    }
  return $confhash;
}


=head2 readConfig($file, $opts)

Read configurations in these formats
  XML::Simple OR Perl-struct OR key=value config file
Parameters
  $file = input file; 
  $opts = XML::Simple options hash-ref
Return hash-ref options

=cut

our $readConfigOk;

sub readConfig
{
  my $self = shift;
  my($file, $opts, $confhash)= @_;
  $opts= ($opts) ? { %$opts } : {};
  $confhash = $self->{'conf'} unless(ref $confhash); # always exists ?
  $confhash = {} unless(ref $confhash);
  my $debug= delete $$opts{debug};
  $debug= $DEBUG unless defined $debug;
  $readConfigOk= 0;
  
  unless ($file && -e $file) {
    my($filename, $filedir);
    $opts->{searchpath}= [] unless ($opts->{searchpath});
    
    $filedir= $self->{confdir}; 
    push(@{$opts->{searchpath}},$filedir) if (-d $filedir);

    $filedir= "conf/";
    push(@{$opts->{searchpath}},$filedir) if (-d $filedir);
    
    ($filename, $filedir) =  File::Basename::fileparse($0);
    push(@{$opts->{searchpath}},$filedir)  if (-d $filedir);
    
    if ($file) {
      ($filename, $filedir) =  File::Basename::fileparse($file);
      push(@{$opts->{searchpath}},$filedir)  if (-d $filedir);
      }
    }
    
  unless( $file ) {
    my ($ScriptDir, $Extension);
    ($file, $ScriptDir, $Extension) = File::Basename::fileparse($0, '\.[^\.]+');
    }
  
  if ($file && !-f $file) {
    foreach my $suf (".conf", ".cnf", ".xml", "" ) {
      my $cnf= _find_file("$file$suf", @{$opts->{searchpath}});  
      if ($cnf) { $file= $cnf; last; }
      }
   }
   
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
    open(F,$file); my $confval= join("",<F>); close(F);
    if ($confval =~ m/=>/s && $confval =~ m/[\{\}\(\)]/s) {
      my $conf1= eval $confval; 
      if ($@) { warn " error $@"; }
      else { 
        my @keys= keys %$conf1;
        @{%$confhash}{@keys}= @{%$conf1}{@keys};
        $readConfigOk= 1;
        }  
      }
    else {
      #? check for \w+ [:=] lines first ?
      $confhash= $self->readKeyValue($confval, $confhash);
      $readConfigOk= 1;
      }
    }
  
  warn " reading: $file ok=$readConfigOk\n" if $debug;
  return $confhash;
}


=head2 showConfig($confhash, $opts)

  $confhash = options hash-ref
  $opts = XML::Simple options hash-ref (debug => 1 Data dumper out)
  return XML::Simple of input
  
=cut

sub showConfig
{
  my $self = shift;
  my($confhash,$opts)= @_;
  $confhash = $self->{'conf'} unless(ref $confhash); # always exists ?
  $opts= ($opts) ? { %$opts } : {};
  my $debug= delete $$opts{debug};
  $debug= $DEBUG unless defined $debug;
  my $xml ='';
  
  if ($debug) {
    require Data::Dumper;
    my $dd = Data::Dumper->new([$confhash]);
    $dd->Terse(1);
    $xml.=  "<!-- ========= config struct ===========\n";
    $xml.=   $dd->Dump();
    $xml.=   "======================================== -->\n";
    }
    
  require XML::Simple;
  my $xs = new XML::Simple( %$opts); #NoAttr => 1, KeepRoot => 1 
  $xml .= $xs->XMLout( $confhash );  
  
  return $xml;
}


sub _updir
{
  #? my $self = shift;
  my ($atdir,$todirs)= @_;
  my $dir= $atdir;
  my $ok= 0;
  my $cod; 
  foreach my $td (@$todirs) { $cod= catdir($dir, $td); $ok= (-d $cod); last if $ok; }
  while (!$ok && length($dir)>2) {
    $dir= "$dir/.."; ##NOT File::Basename::dirname($dir)."/..";
    $dir=`cd "$dir" && pwd`; chomp($dir);
    ##warn " _updir $dir\n" if $DEBUG;
    foreach my $td (@$todirs) { $cod= catdir($dir, $td); $ok= (-d $cod); last if $ok; }
    }
  return ($ok) ? $dir : $atdir;
}


=head2 $confhash= readConfDir( $dir, $confpatt, $confhash)

Process all config files of confpatt in dir folder.

=cut
our $readConfDirOk;

sub readConfDir {
  my $self = shift;
  my( $confdir, $confpatt, $confhash)= @_;
  $confdir  = $self->{'confdir'}  unless($confdir); 
  $confpatt = $self->{'confpatt'}  unless($confpatt); 
  $confhash = $self->{'conf'} unless(ref $confhash); # always exists ?
  $confhash = {} unless(ref $confhash);

  $readConfDirOk= 0;
  if ( opendir( DIR, $confdir ) ) {
    my @conf = grep ( /$confpatt/, readdir(DIR));
    closedir(DIR);
    foreach my $file (sort @conf) { 
      my $confpath= catfile($confdir,$file);
      $confhash= $self->readConfig( $confpath, { debug => $DEBUG, Variables => $Variables }, $confhash);
      $readConfDirOk ||= $readConfigOk;
      }
    }
  warn " readConfDir $confdir ok=$readConfDirOk\n" if $DEBUG;
  return $confhash;
}



sub init_conf 
{
  my $self= shift;
  my $myroot   = $self->{'gmod_root'};
  my $confpatt = $self->{'confpatt'};
   
  my $confhash = $self->readConfDir();
  unless($readConfDirOk) {
    warn " no $confpatt file at $myroot/conf; setenv $ROOT to locate."
    }
  else { # if ($SetEnv)
    my @keys= keys %$confhash;
    @ENV{@keys}= @{%$confhash}{@keys};
    }

  $ENV{$INIT}= 1;
  my @inc=();
  my $libdir=  catdir($myroot,"lib");
  push(@inc, $libdir) if (-d $libdir);
  push(@inc, split /:/, $ENV{'PERL5LIB'}) if (defined $ENV{'PERL5LIB'});
  foreach my $p (@inc) { unshift(@INC,$p) unless( grep /^$p$/i,@INC );  }
}


=head2 BEGIN 

At eval time (use, require), this checks %ENV for GMOD_ROOT and
GMOD_INIT.  If not found, it looks in folder above calling script
for conf/gmod.conf as KEY=value to be loaded into %ENV.
$ENV{GMOD_INIT}=1 prevents this loading.

=cut

BEGIN {

$DEBUG = $ENV{'DEBUG'} unless defined $DEBUG;

unless($ENV{$INIT}) {
  my $myroot;
  if (defined $ENV{$ROOT} && -d $ENV{$ROOT}) { $myroot= $ENV{$ROOT}; }
  else { $myroot= abs_path("$Bin"); }
  $myroot= _updir( $myroot, ["conf"] ); # in case we are not in bin/ folder
  $BASE= __PACKAGE__->new($myroot);
  #?? my $self= Bio::GMOD::Config2->new($myroot);
  $BASE->init_conf();
  }
  
}


1;

