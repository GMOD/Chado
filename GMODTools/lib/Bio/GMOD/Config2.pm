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

### use Bio::GMOD::Config;

use vars qw/@ISA $BASE @CONF_SUF $ROOT $INIT $Variables/;

our $DEBUG;
our $VERSION = "0.5";

BEGIN {
### @ISA = qw/ Bio::GMOD::Config /;  ## DO WE NEED THIS base package at all?
#? $DEBUG = 0;
$ROOT= "GMOD_ROOT";  
$INIT= "GMOD_INIT";
$BASE= undef;
@CONF_SUF=  (".conf", ".cnf", ".xml", "" );
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
  my %args=();
  if (ref($arg) =~ /ARRAY/)   { %args= @$arg;  $root= $args{'gmod_root'}; }
  elsif (ref($arg) =~ /HASH/) { %args= %$arg;  $root= $args{'gmod_root'}; }
  elsif ($arg) { $root = $arg; } #can override the environment variable
  $DEBUG= $args{debug} if defined $args{debug};
   
  unless($root){
    if ($BASE)  { $root= $BASE->{'gmod_root'}; }
    else { $root = $ENV{'GMOD_ROOT'}; }  #required
    }

  my @db= ();   # dgg - drop this ?
  my $confhash= {};
  
    # need options for subdirs inside conf/ at least: bulkfiles/ gbrowse.conf/ ...
  my @sp= ();
  if ($args{searchpath}) {
  foreach my $sp (@ { $args{searchpath} }) {
    ##print STDERR "Config2: searchpath $sp\n"; #DEBUG
    if (-d $sp) { push(@sp, $sp); }
    else {
      $sp= catdir($root, $sp);
      push(@sp, $sp) if (-d $sp);
      }
    }
  }
  my $searchpath= \@sp;
  
  my $confdir = $args{confdir} || 'conf';
  $confdir= catdir($root, $confdir) unless($confdir =~ m,^/,); #unixism
    
  my $confpatt= $args{confpatt} || '(gmod|[\w_\-]+db)\.conf$'; # FIXME - need caller opts
  my $read_includes= $args{read_includes} || 0;
  my $showtags= $args{showtags} || [];
  
  if (%args) {
    delete $args{conf};  # can we delete @args{qw( conf confdir ..)} 
    delete $args{confdir};
    delete $args{confpatt};
    delete $args{read_includes};
    delete $args{showtags};
    delete $args{gmod_root};
    delete $args{searchpath};
    
    my @keys= keys %args;
    @$confhash{@keys}= @args{@keys} if @keys;
    }

  return bless {db       => \@db,
                conf     => $confhash,
                confdir  => $confdir,
                confpatt => $confpatt,
                showtags => $showtags,
                read_includes => $read_includes,
                searchpath => $searchpath,
                gmod_root=> $root }, $self;
}

sub setargs {
  my $self = shift;
  my %args= @_;
  # searchpath confdir need handlin.... 
  foreach my $k (qw(confpatt read_includes showtags)) {
    $self->{$k}= $args{$k} if defined $args{$k};
    }
}

=head2 $confhash= config()

=head2 $rootpath= gmod_root()

=head2 $configdir= confdir()

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

sub config { return shift->{'conf'};  }

# same as Bio::GMOD::Config
sub gmod_root { return shift->{gmod_root}; }
sub confdir { return shift->{confdir}; }

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
  local $_= shift;
  s/^\s*//; s/\\?\s*$//; if (s/^(["'])//) { s/$1$//; }
  if ($Variables) {
    s/\$\{(\w+)\}/$Variables->{$1}/g; # convert $KEY to $ENV{$KEY} to value
    }
  return $_;
}


sub _find_file  {
  my($file, @search_path) = @_;
  my($filename, $filedir) = File::Basename::fileparse($file);
  if(!@search_path || $filename ne $file) { 
    return($file) if(-e $file);
    }
  else {
    foreach my $path (@search_path)  {
      my $fullpath = catfile($path, $file);
      return($fullpath) if(-e $fullpath);
      }
    }
  return undef;
}

sub _find_file2  {
  my($file, $suffix, $search_path) = @_;
  my($filename, $filedir) = File::Basename::fileparse($file);
  
  if(!$search_path || $filename ne $file) { 
    foreach my $sf (@$suffix) {
      my $fullpath = $file . $sf;
      ##print STDERR "Config2::_find_file2 look at $fullpath\n" ;#if $DEBUG;
      return($fullpath) if(-e $fullpath);
      }
    }
  else {
    foreach my $path (@$search_path)  {
      foreach my $sf (@$suffix) {
      my $fullpath = catfile($path, $file) .  $sf;
      ##print STDERR "Config2::_find_file2 look at $fullpath\n" ;#if $DEBUG;
      return($fullpath) if(-e $fullpath);
      }
      }
    }
  return undef;
}

=head2 appendHash($tohash, $addhash, $replace)

add keys to hash without  replacing existing .. prefered behavior ?
unless $replace is flagged

=cut

sub appendHash 
{
  my $self = shift;
  my ($tohash, $addhash, $replace)= @_;
  # -- need to be careful here, DONT replace existing key ?
  my @keys= keys %$addhash;
  if ($replace) { 
    @{$tohash}{@keys}= @{%$addhash}{@keys}; 
    }
  else {
    foreach my $k (@keys) { $$tohash{$k}= $$addhash{$k} unless defined $$tohash{$k}; } 
    }
}

=head2 readKeyValue($confval, $confhash)

Read $confval string for key=value lines
Return hash-ref options

=cut

sub readKeyValue
{
  my $self = shift;
  my ($confval, $confhash, $replace)= @_;
  $confhash = $self->{'conf'} unless(ref $confhash);
  $confhash = {} unless(ref $confhash);
  my ($k,$v,$noappend);
  foreach (split(/\n/,$confval)) {
    next if(/^\s*[\#\!]/ || /^\s*$/); # skip comments, etc.
    if (/^([^\s=:]+)\s*[=:]\s*(.*)$/) { # must have value=(*.) to allow blanks
      ($k,$v)=($1,$2);
      $noappend= (defined $confhash->{$k} && !$replace);
      $confhash->{$k}= _cleanval($v) unless($noappend);
      }
    elsif ($k && s/^\s+//) {
      $confhash->{$k} .= _cleanval($_) unless($noappend);
      }
    }
  return $confhash;
}



our $readConfigOk;

sub readConfigOk { return $readConfigOk; }

=head2 readConfigFile($file, $opts)

read one file; see readConfig 

=cut

sub readConfigFile
{
  my $self = shift;
  my($file, $opts, $included)= @_;
  my $confhash = {};

  unless ($file && -e $file) {
    my($filename, $filedir);
    
    $filedir= $self->{confdir}; # full path
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
  
  if ($file && !-e $file) {
    my @suf= @CONF_SUF; ##(".conf", ".cnf", ".xml", "" );
    my $cnf= _find_file2( $file, \@suf, $opts->{searchpath} );  
    if ($cnf) { $file= $cnf;  }
    }
  
  ##print STDERR "Config2::readConfig look at $file\n" if $DEBUG;
  $self->{filename}= $file unless($included);
  
  if (!$file || ($file =~ /\.xml/ && -e $file)) {
    require XML::Simple; ## will attemp to read $0.xml file if no file given
    my $xs = new XML::Simple(%$opts); # (NoAttr => 1, KeepRoot => 1);#options
    $confhash = $xs->XMLin( $file); 
    }
  
  elsif (-f $file) {
    ## handle key-value file OR perl-struct
    open(F,$file); my $confval= join("",<F>); close(F);
    if ($confval =~ m/=>/s && $confval =~ m/[\{\}\(\)]/s) {
      $confhash= eval $confval; 
      if ($@) { warn " error $@"; }
      }
    else {
      #? check for \w+ [:=] lines first ?
      $confhash= $self->readKeyValue($confval, $confhash);
      }
    }
  if (scalar(%$confhash)) { $readConfigOk= 1; }

  print STDERR "Config2: read: $file ok=$readConfigOk\n" if $DEBUG;
  if (ref $self->{showtags} &&  !$self->{showntags}{$file}) {
    $self->{showntags}{$file}=1;
    my $show='';  
    foreach my $tag (@{$self->{showtags}}) { 
      my $showval='';
      my $val= $$confhash{$tag};
      if( ref($val) eq 'HASH') { # hash of hash :(
        my @keys = sort keys %$val;
        foreach my $k (@keys) {
          my $vv= $$val{$k};
          if(ref($vv) eq 'HASH') { $vv= $vv->{content}; }
          $showval .= "\n $k = ". $vv;
          } 
        ##$showval .= join("\n", @{$val}{@keys});
      } elsif( ref($val) eq 'ARRAY') {
        $showval .= join("\n", @{$val});
      } elsif($val) { 
        $showval .="$val"; 
      }
      $show.= "$tag = $showval; " if $showval; 
      }
    print STDERR "Config: $show from $file\n" if $show;
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

sub readConfig
{
  my $self = shift;
  my($file, $opts, $confhash)= @_;
  $readConfigOk= 0;
  
  if(ref $opts) {
    $opts= { %$opts };
    $opts->{Variables}= $Variables unless($opts->{Variables});
  } else {
    $opts= { Variables => $Variables };
  }
  $confhash = $self->{'conf'} unless(ref $confhash); # always exists ?
  $confhash = {} unless(ref $confhash);

  $DEBUG= delete $opts->{debug} if (defined $opts->{debug});
  my $replacekeys= delete $opts->{replace} || 0;
  
  ##print STDERR "Config2::readConfig in=$file\n" if $DEBUG;
  
  unless ($opts->{searchpath}) {
    $opts->{searchpath}= [ @{$self->{'searchpath'}} ];
    }  

  my $conf1 = $self->readConfigFile($file, $opts, 0);
  $self->appendHash($confhash, $conf1, $replacekeys) if ($conf1);
     
  ## $self->{filename}= $file;
  
  if ($self->{read_includes} && $$confhash{include}) {
    ## $self->{read_includes}= 0; ## MUST NOT RECURSE HERE...
    ##? but can we do nested includes ?? need to check each conf1
    my %didinc=();
    my $inc= $$confhash{include};
    my @inc= (ref($inc) =~ /ARRAY/) ? @$inc : ($inc);
    my $saveConfigOk= $readConfigOk;
    foreach $inc (@inc) {
      next if ($didinc{$inc}); $didinc{$inc}++;
      $readConfigOk= 0;
      $conf1= $self->readConfigFile($inc, $opts, 1);
      ## need some warning/die if not found 
      warn "Config2: MISSING include=$inc \n" unless $readConfigOk;
      if ($conf1) {
        my $inc1= delete $$conf1{include};
        if($inc1) { push(@inc, (ref($inc1) =~ /ARRAY/) ? @$inc1 : ($inc1)); }
        $self->appendHash($confhash, $conf1, $replacekeys);
        }
      $saveConfigOk=0 unless($readConfigOk);
      }
    $readConfigOk= $saveConfigOk;
    }
    
  return $confhash;
}


sub updateVariables
{
  my $self = shift;
  my( $confhash, $opts)= @_;
  $DEBUG= delete $opts->{debug} if (defined $opts->{debug});
  $confhash = $self->{'conf'} unless(ref $confhash); # always exists ?
  $confhash = {} unless(ref $confhash);
  my $env= (ref $opts and ref $opts->{Variables}) ? $opts->{Variables} : $Variables;
  _update1Value( $confhash, $env);
  return $confhash;
}


sub _update1Value
{
  my($val,$env)= @_;

  if( ref($val) eq 'HASH') {  
    foreach my $tag (sort keys %$val) { 
      $$val{$tag} = _update1Value( $$val{$tag}, $env);
      }
    
  } elsif( ref($val) eq 'ARRAY') {
     foreach (@$val){  $_= _update1Value( $_, $env); }
     
  } else {
    while ( $val =~ m/\$\{(\w+)\}/g) {
      my $var=$1;
      my $enval= $env->{$var}; #only if defined, leave otherwise
      if (defined $enval) { 
        if($enval =~ m/\$\{(\w+)\}/) { $enval= _update1Value( $enval, $env); }
        print STDERR "UPVAL1: \$\{$var\} => $enval\n" if $DEBUG;
        $val =~ s/\$\{$var\}/$enval/;
        } 
    }
  }
  
  return $val;
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
 note: this can load in things you may not want 
 (e.g. all the .xml.old files...)
 
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
    $self->appendHash( \%ENV, $confhash, 0);
    # -- need to be careful here, DONT replace existing key ?
    # my @keys= keys %$confhash;
    # foreach my $k (@keys) { $ENV{$k}= $$confhash{$k} unless defined $ENV{$k}; } 
    # @ENV{@keys}= @{%$confhash}{@keys};
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

