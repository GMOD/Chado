#!/usr/bin/perl

=head1 NAME 

  gmod_install.pl - install gmod - test cut from installargos.pl
  
=head1 SYNOPSIS

install script test for GMOD, cut
from installargos. for ARGOS, A Replicable Genome infOrmation System, 

   http://flybase.net/argos/install/installargos.pl
   
=head1 DESCRIPTION

Summary of steps to installation of...

Use as install.cgi web form:

  #!/bin/sh
  if [ "x$GMOD_ROOT" = "x" ]; then
    GMOD_ROOT=/usr/local/gmod       
  fi
  
  ## resolve symlinks -- not working...
  PRG="$0"
  PRGDIR=`dirname "$PRG"`
  HERE=`cd "$PRGDIR/.." ; pwd`
  
  perl -e'require "gmodinstall.pl"; GmodInstallForm::installForm();' \ 
    -- -quiet -inroot=$GMOD_ROOT -root=$HERE $@
   
=head1 AUTHORS

  Don Gilbert, etc.

=cut


GmodInstaller::main();

#--------------------------------------------------------------



package GmodInstaller;

use strict;
use Getopt::Long;
use vars qw() ;

use vars qw(
$configFileOk 
%packlist @packlist 
%origconfig %config %configchange
$GMOD_ROOT $DEFAULT_ROOT
$NG_CONF $NG_CONF_DEFAULT $PACKAGE_LIST $CONFIGCHANGE_LIST 
$DEFAULT_PACKAGE $LOCAL_EXCLUDE %INSTALL_PACK %DEFAULT_CONF
$sufLOCAL $sufDEFAULT
$verbose $viewOnly $doinstall $doupdate $dopackinfo $dopacklist $isempty
$isfull $dorun $reconfigure $doHelp   $beQuiet $cleanupd $userroot $installroot
@userpacks @rsyncopts $haversync $skiprequires $program
%runopts     
);


BEGIN {
$NG_CONF = "gmod.conf.local";  
$NG_CONF_DEFAULT = "gmod.conf";
$PACKAGE_LIST = "gmod-packages.conf";
$CONFIGCHANGE_LIST = "reconfigure.conf"; # reconfigure.conf ?
$DEFAULT_ROOT = "/usr/local/gmod";
$DEFAULT_PACKAGE = 'gmod';
$LOCAL_EXCLUDE= "rsync.exclude.local";
$sufLOCAL= ".local";
$sufDEFAULT= ".default"; # was .orig - cvs excludes

%INSTALL_PACK = (
  $DEFAULT_PACKAGE => {
    'package' => $DEFAULT_PACKAGE,
    description => 'installation package',
    url => 'http://www.gmod.org/argos/packages/install/',
    localpath => 'install/',
    },
);

%DEFAULT_CONF = (
  GMOD_ROOT => $DEFAULT_ROOT ,
  PACKAGES => $DEFAULT_PACKAGE,
  );
 
$verbose= 0; ## == echoFlag
$viewOnly= 1;
$doinstall= 0;
$doupdate= 0;
$dopackinfo= 0;
$dopacklist= 0;
$isempty= 0;
$isfull= 0;
$dorun= 1;
$reconfigure= 0;
$doHelp= 0; $beQuiet= 0;
$cleanupd= 0;
$userroot= undef;
$installroot= undef;
@userpacks= ();
@rsyncopts= ();
$skiprequires= 0;
$program = $0;

%runopts= (
'install' => \$doinstall,
'update' => \$doupdate,
'reconfigure' => \$reconfigure,
'info' => \$dopackinfo,
'list' => \$dopacklist,
'verbose' => \$verbose, 
'clean' => \$cleanupd, 
'run!' => \$dorun, # trick for -norun == -n == dryrun 
'help' => \$doHelp,
'quiet' => \$beQuiet,
'skiprequires' => \$skiprequires,
'root=s' => \$userroot,
'inroot=s' => \$installroot, # webroot ??
'package=s' => \@userpacks,
'rsopts=s' => \@rsyncopts,
'program=s' => \$program,
);
}

# --- main ---
sub main {

my $ok= GetOptions(%runopts);

# getConfigs($ok);

# if ($beQuiet) {}
# elsif ($doHelp) { doHelp( $isempty, $isfull, $haversync); } #exit(0); 
# else { doWork(); }

warn "Stub main()...";

}




#-------- subs -----------------------------

# for cgi
sub installRoot {
  return $installroot || $userroot || $config{GMOD_ROOT};
}

sub doHelp {
  my ($isempty,$isfull, $haversync)= @_;
  
my $confroot= $userroot || $config{GMOD_ROOT};
#my $conflist = join(", ", map { "$_=$config{$_}" } sort keys %config );

print <<"HERE";
Usage:
 $0 [ options ] -info|install|list|update|reconfigure 

STUB HELP -- fill in blanks

HERE

}

sub getConfigs {
  my ($ok)= @_;
  
  # -- check configs now (using $userroot if given)
  
#   $haversync=`rsync --version`;
#   @rsyncopts= split(/,/,join(',',@rsyncopts));
  
  my $pg= $program;
  my $instroot= ($pg =~ m,$\-,)?'./':`dirname $pg`; chomp($instroot);  
 
  if ($installroot && $installroot !~ m,^/,) {
    require File::Spec;
    $installroot= File::Spec->rel2abs($installroot);
    } 
  ## if $userroot - need to convert to full path if relative
  if ($userroot && $userroot !~ m,^/,) {
    require File::Spec;
    $userroot= File::Spec->rel2abs($userroot);
    } 
  $instroot= "$userroot/install"
     if ($userroot && -d "$userroot/install");
  
   #? need packlist in original order? not hash order?
  %packlist = readPackages("$instroot/$PACKAGE_LIST",\%INSTALL_PACK);
  $isempty=1 unless($configFileOk);
    
  %origconfig = readConfig("$instroot/$NG_CONF_DEFAULT",\%DEFAULT_CONF);
  $isempty=1 unless($configFileOk);
  
  %config = readConfig("$instroot/$NG_CONF",\%origconfig);
  
  %configchange = readConfig("$instroot/$CONFIGCHANGE_LIST",{});
  
  @packlist = sort keys %packlist;
  # my $conflist = join(", ", map { "$_=$config{$_}" } sort keys %config );
  
  $GMOD_ROOT= $userroot || $config{GMOD_ROOT};
  $isfull= (-e "$GMOD_ROOT/common/servers"); #?
  
#   $doinstall= $doupdate= $reconfigure= 0 
#     unless ($haversync =~ /version/);
  $doHelp= 1 
    unless($ok && ($doinstall || $dopackinfo || $dopacklist || $doupdate || $reconfigure));
  
  # if($doHelp) { doHelp( $isempty, $isfull,  $haversync); exit(0); }

}


sub cleanval {
  local $_= shift;
  s/^\s*//; s/\s*$//; s,\\$,,; #trim ; drop \ continue line flag
  if (s/^(["'])//) { s/$1$//; }
  return $_;
  }

sub readPackages {
  my ($confile, $rdefault, $nopacks)= @_;
  my %packs;
	$configFileOk=0;
  local(*F);
  unless(open(F,"$confile")) {
    warn "config file missing: $confile\n" if $verbose;
    return %$rdefault; ## 
    };
  my ($pack,$k,$v)= ('DEFAULT','','');
  $packs{$pack}= {};
  while(<F>) {
    next if(/^\s*[\#\!]/); # skip comments, etc.
    next unless(/^\s*\S/); # skip comments, etc.
    chomp;
    if (s/^\s+//) {
      # continue variable line
      $_= cleanval($_);
      $packs{$pack}->{$k} .= $_ if ($pack && $k);
      }
    else {
      ($k,$v)= split(/\s*[=:]\s*/,$_,2);
      $v= cleanval($v);
      if (!$nopacks && $k eq 'package') {
        $pack= $v;
        $packs{$pack}= {};
        }
      $packs{$pack}->{$k}= $v;
      # preserve old gmod.conf.local package names
      if ($k eq 'package-alias') { $packs{$v}= $packs{$pack}; }
      }
    }
  close(F); 
	$configFileOk=1;
  return %packs;
}

sub readConfig {
  my ($confile,$rdefault)= @_;
  my %pk= readPackages($confile,{},1);
  return (%pk) ? %{$pk{DEFAULT}} : %$rdefault;
}

# Find System OS and return the name

sub findOS { 
  my $SYSOS=undef;
  my $TARGET_OS = "unknown";
  my $OS = `uname`; chomp($OS);
  if ($OS eq 'SunOS' && (`uname -r` !~ /^[1-4]/)) { $OS = 'Solaris'; }
  local $_= $OS;
  OSCASE: {
    if (/Solaris/){ $TARGET_OS = "sun-sparc-solaris"; last OSCASE; }
    if (/SunOS/)  { $TARGET_OS = "sun4-solaris"; last OSCASE; }
    if (/OSF1/)   { $TARGET_OS = "osf"; last OSCASE; }
    if (/ULTRIX/) { $TARGET_OS = "ultrix"; last OSCASE; }
    if (/IRIX/)   { $TARGET_OS = "sgi-irix"; last OSCASE; }
    if (/Linux/)  { $TARGET_OS = "intel-linux"; last OSCASE; }
    if (/AIX/)    { $TARGET_OS = "ibm-aix"; last OSCASE; }
    if (/HP-UX/)  { $TARGET_OS = "hp-ux";  last OSCASE; }
    if (/Darwin/)   { $TARGET_OS = "macosx";  
      $SYSOS="apple-powerpc-darwin"; last OSCASE; }

    $TARGET_OS = $OS; 
    print "Unsupported operating system: $OS";
  }
  
  ## SYSOS - how system names library path; $TARGET_OS - srs name
  $SYSOS=$TARGET_OS unless($SYSOS);
  
  return (wantarray) ? ($SYSOS, $TARGET_OS) : $SYSOS;
}

#--------------------------------------------------------------

package GmodInstallForm;
use strict;
use Getopt::Long;
## caller may lack CGI.pm on argos bootstrap
#>>ERR>>use CGI qw(:standard  *table *dl *TR *td *th);
BEGIN{eval{require CGI; import CGI qw(:standard  *table *dl *TR *td *th);};} 

use vars qw($title $HTMLHEADER $installer $vers);

BEGIN {
  $title= "GMOD SAMPLE Installation";
  $vers= "GMOD v1.0";
  $installer= 'gmodinstall.pl'; ## FIXME
  $HTMLHEADER= 0;
}

=head1 GmodInstallForm

=cut


sub downloadInstaller {
  my ($cg,$url)= @_;
  my $GMOD_ROOT= $GmodInstaller::GMOD_ROOT;
  my $confile= "$GMOD_ROOT/install/$installer";

  print $cg->header(
    '-X-Layout'=>'<nolayout>',
    -type=>'application/octet-stream',
    -attachment => $installer, 
    );
  local(*F);
  unless(open(F,"$confile")) {
    print "config file missing: $confile <br>\n";
    } 
  else {
    print <F>;
    close(F);
    }
}

# make html page w/ URLs to this and to downloadInstaller?
sub newConfig {
  my ($cg,$url)= @_;
  my $GMOD_ROOT= $GmodInstaller::GMOD_ROOT;
  my $inroot= GmodInstaller::installRoot();

  my $inconf = "$inroot/install/$GmodInstaller::NG_CONF";
  my $confile= "$GMOD_ROOT/install/$GmodInstaller::NG_CONF_DEFAULT";

  # print $cg->header(-type=>'text/plain');
  ## need filename !
  print $cg->header(
    '-X-Layout'=>'<nolayout>',
    -type=>'application/octet-stream',
    -attachment => $GmodInstaller::NG_CONF,
    );
  
  print "# Save As TEXT FILE= $inconf \n";
  print "# Gmod Package local configuration \n";
  print "\n";
    
  local(*F);
  unless(open(F,"$confile")) {
    print "config file missing: $confile <br>\n";
    } 
  else {
    my @confile= <F>; 
    close(F);
    
    # print "<pre>\n";    
    foreach (@confile){ 
      if (/^\s*(\w+)\s*[=:]\s*(.*)$/) {
        my ($k,$v)= ($1,$2);
        if (defined $cg->param($k)) {
          $v= $cg->param($k);
          }
        s/^\s*(\w+)(\s*[=:]\s*)(.*)$/$1$2$v/;
        }
      print;
      }
    # print "</pre><hr>\n";
    }
   print "\n";
}

sub editConfig {
  my ($cg,$url)= @_;
  my $GMOD_ROOT  = $GmodInstaller::GMOD_ROOT;
  my $inroot= GmodInstaller::installRoot();
  my $croot= $GMOD_ROOT;
  
  my $confile= "$GMOD_ROOT/install/$GmodInstaller::NG_CONF_DEFAULT";
  my $inconf= "$inroot/install/$GmodInstaller::NG_CONF";
  htmlHeader($cg);
  print "<h2>Package configuration</h2>\n";
  # print "<b>FILE=</b>$confile  <br><hr>\n";
  
  my @adds= $cg->param("addpack");
  # printConfig($confile); # if (param('Configure'));
  my $table =  TR( {-bgcolor=>'#cccccc'}, th( "Key"), th( "value"), )."\n";

  foreach my $pack (@GmodInstaller::packlist) {
    my $packh= $GmodInstaller::packlist{$pack};
    next if ($pack ne $packh->{'package'} && $packh->{'package-alias'});
    my $isrequired= ($packh->{'is-required'} =~ /true|1/i);
    unshift(@adds,$pack) if ($isrequired && grep(/^$pack$/,@adds) == 0);
    }
      
  local(*F);
  unless(open(F,"$confile")) {
    print "config file missing: $confile <br>\n";
    } 
  else {
    my @confile= <F>; 
    close(F);
    
    # print "<pre>\n"; print @confile;  print "</pre><hr>\n";
    my $notes;
    foreach (@confile){ 
      if (/^#n\w*(.*)$/) {  $notes .= $1." <br>\n"; } 
      next unless(/^\s*(\w+)\s*[=:]\s*(.*)$/);
      if ($notes) {
        #$table .= TR( td({-colspan=>2},"NOTE: ".$notes))."\n";
        $table .= TR({-bgcolor=>'#f0f0f0'}, td({-align=>'right'},'<i>Note</i>'), td($notes))."\n";
        $notes= '';
        }
      my ($k,$v)= ($1,$2);
      if ($k =~ /GMOD_ROOT$/) {
        $croot= $v;
        $v= $inroot;
        }
      elsif ($k =~ /^PACKAGES$/) {
        $v= '"'.join(" ",@adds).'"';
        }
      elsif ($k =~ /^(\w+)_CONF$/) {
        my $pk= lc($1);
        if (grep(/^$pk$/,@adds)) { $v= '';} else { $v= '#'.$k; }
        }
      elsif ($v =~ /^$croot/) { $v =~ s/$croot/$inroot/; } #??
      
      $v= $cg->textfield( -size=>50, -name=>$k,-value=>$v);
      $table .= TR( td($k), td($v))."\n";
      }
    # close(F);
    
    print $cg->start_form(-name=>'gmodconfig', -action=>$url),"\n";
    print "<b>Installation FILE=</b>$inconf",
    " &nbsp;",$cg->submit(-name=>'Create')," <p>\n";
    print table( {-border=>1, -cellpadding=>4, -bgcolor=>'white', width=>'100%' }, $table);
    # print $cg->hidden(-name=>'option',-value=>'edit');
    print $cg->hidden(-name=>'inroot',-value=>$inroot);
    print $cg->hidden(-name=>'config',-value=>$confile);
    print $cg->end_form(),"\n";
    }
  # print $cg->end_html(),"\n";
  print "<hr>\n";
}

sub printInfo {
  my ($cg, $url,@packs)= @_;
  @packs= @GmodInstaller::packlist unless(@packs);

  htmlHeader($cg);
  print "<h2>Package info</h2>\n";
  # print "<pre>\n";
  foreach my $pack (@packs) {
    # GmodInstaller::packageInfo($pack);

    my $table =  TR( {-bgcolor=>'#cccccc'}, th( "Key"), th( "value"), )."\n";
    my $packh= $GmodInstaller::packlist{$pack};
    # print "package: $pack\n";
    $table .= TR( td('Package'), td($pack));
    foreach my $k (sort keys %$packh) {
      next if ($k eq 'package');
      my $v= $packh->{$k};
      $v= reqLink($url, $v) if ($k =~ /^(requires|optional)$/);
      $v= listLink($url, $pack, $v) if ($k =~ /^(url)$/);
      $table .= TR( td($k), td($v))."\n";
     }
    print table( {-border=>1, -cellpadding=>4, -bgcolor=>'white', width=>'100%' }, $table);
    print "<p>\n";
    }
  # print "</pre>\n";
}

sub printList {
  my ($cg, $url,@packs)= @_;
  @packs= @GmodInstaller::packlist unless(@packs);
  htmlHeader($cg);

  $GmodInstaller::viewOnly= 0; #?? FIXME - very slow printing compared to cmdline
  ## is sending info to stderr !
  # $|=1; # unbuffer print
  foreach my $pack (@packs) {
    my $packh= $GmodInstaller::packlist{$pack};
    print "<h2>Package Listing: $pack </h2>\n";
    print "<b>LIST</b> ".$packh->{url}."<br>\n";
    print "<pre>\n";
    ## not working well yet...
    if ($cg->param('debug')) { GmodInstaller::listPackage($pack); } ## Need to trap long lists and page them??
    else { 
        print "<b>Not working properly yet... <br>";
        print "try command-line 'rsync -nav --stats  $packh->{url}'  to list</b>\n"; 
        }
    print "</pre><hr>\n";
    }    
}

sub reqLink {
  my ($url,$req)= @_; # $packh->{'requires'}
  my $rh='';
  my @req= split(" ",$req); # $packh->{'requires'});
  foreach my $r (@req) {
    $rh .= a({-href=>"$url?option=info&package=$r"},$r)." ";
    }
  return $rh;
}

sub listLink {
  my ($url,$pack,$req)= @_; # $packh->{'requires'}
  my $rh='';
  my @req= split(" ",$req); # $packh->{'requires'});
  foreach my $r (@req) {
    $rh .= a({-href=>"$url?option=list&package=$pack"},$r)." ";
    }
  return $rh;
}

sub htmlHeader {
  my $cg = shift;
  
  print $cg->header,"\n",
    $cg->start_html(-title  => $title, ),"\n",
    $cg->h2($title),"\n" unless($HTMLHEADER++);
}

sub instructions {
  my ($cg, $url, $inroot)= @_;

    print <<"EOF";
<big><b><font color="red">This Sample is a test; it doesn't install anything!</font></b></big>
<h2>Requirements</h2>
Unix systems supported are:
 Sun Solaris v8 & v9; Intel Linux (redhat v8, 9 tested); Apple MacOSX v10.2+
<br>   
 These packages are required, and commonly are preinstalled except for Solaris
<ul>
<li>  Perl v5.6 or later  - <a href="http://www.perl.com/">http://www.perl.com/</a>
<li>  Java v1.3 or later  - <a href="http://java.sun.com/">http://java.sun.com/</a>
<li>  ...more goes here...
</ul>
<h2> Installation steps</h2>
EOF
    my $aport= $GmodInstaller::config{APACHE_PORT};
    
    print "<ol>\n<li><b>Download</b>: ", 
      $cg->a({-href=>"$url?option=getinstaller"},$installer)." <p>\n";

    print "<li><b>Bootstrap installation</b>: NOT DONE ... ",
#      " From command line, Run (change $inroot as desired)<br>",
#      " 'perl gmodinstall.pl -root=$inroot -install -v' ",
      " <p>";
    
    print "<li><b>Configure</b>: ",
      " Use Configure form below, or edit $inroot/install/gmod.conf.local <p>\n";
      
    print "<li><b>Install full data, software set</b>:  NOT DONE ...",
#       " Run <br> 'cd $inroot; install/install  -install -v' <br>\n",
#       " This can take a while, use 'install/install -install -v >& log.install &' for background <br>\n",
      " <p>";

    print "<li><b>Check installation, Run web server, Check logs/</b>: NOT DONE ... ",
#       " Run <br> 'install/run-apache start' <br>\n",
#       " The Gmod web server should then be available at http://localhost:$aport/ \n",
#       " with installed packages at configured ports (status in logs/) <br>\n",
      " <p>";
      

    print "</ol>\n";
}



sub installForm {
  my $cg = new CGI;
  
#   print $cg->header,"\n",
#     $cg->start_html(-title  => $title, ),"\n",
#     $cg->h2($title),"\n";

  my @savearg= @ARGV;
  unshift( @ARGV, -root => ($cg->param('webroot') || '..')); #?? installroot ?
  if ($cg->param('inroot')) {
    unshift( @ARGV, -inroot => $cg->param('inroot')); #?? installroot ?
    }
    ## -package => ($cg->param('package') || 'gmod-root'),
    ## ($cg->param('option') || '-info'),
    
    
  my $ok= GetOptions(%GmodInstaller::runopts);
  GmodInstaller::getConfigs($ok);
  
  my $webroot= $GmodInstaller::GMOD_ROOT;
  my $inroot= GmodInstaller::installRoot();
  my $confroot= $GmodInstaller::config{GMOD_ROOT}; #?? which to use?
  my $url= $cg->url(-relative=>1,-path_info=>1);

  if (param('option') eq 'info') {
    printInfo( $cg, $url, param('package') );
    }
    
  elsif (param('option') eq 'list') {
    printList( $cg, $url, param('package') );
    }
  elsif (param('option') eq 'getinstaller') {
    downloadInstaller( $cg, $url);
    }
 
  elsif (param('Configure')) {
    editConfig($cg, $url);
    }
  elsif (param('Create')) {
    newConfig( $cg, $url);
    }
    
  else {
    ## change this - make 1st page = instructions, with steps
    ## 1. 
    htmlHeader($cg);
    
    instructions($cg, $url, $confroot);
        
    print $cg->start_form(-name=>'gmodinstall', -action=>$url),"\n";
    print "<b>Installation path</b>: ", 
      $cg->textfield( -size=>50, -name=>'inroot',-value=>$inroot), # user opt!
      " &nbsp;&nbsp; ",$cg->submit(-name=>'Configure'),"<p>\n";
    print "<b>Main packages to install</b>: ", "\n";
    
    my $table = 
      TR( {-bgcolor=>'#cccccc'},
        th( "Package"),
        th( "Local path"),
        th( "Disk use"),
        th( "Description"),
        th(  { -width=>"25%"}, "Requires"),
      );
    
    foreach my $pack (@GmodInstaller::packlist) {
     
      my $packh= $GmodInstaller::packlist{$pack};
      next unless ($packh->{'is-main'} =~ /true|1/i);
      next if ($pack ne $packh->{'package'} && $packh->{'package-alias'});
      my $isrequired= ($packh->{'is-required'} =~ /true|1/i);
      
      my $rh= reqLink($url, $pack .' '.$packh->{'requires'});
        
      $table .= "\n" . TR(
        td( checkbox(
              -label => $pack,
              -name => 'addpack', -value=>$pack,
              -override => 1,
              -checked  => param($pack) || $isrequired ,
              ($isrequired ? '-disabled' : ''), # this is bad - form doesnt send value?
              )),
        td( $packh->{'localpath'} ),
        td( $packh->{'size'} || $packh->{'est-size'} || '--' ),
        td( $packh->{'description'} ),
        td( { -width=>"30%"}, $rh), #$packh->{'requires'} 
        );
      }  
   
    print table( {-border=>1, -bgcolor=>'white', width=>'100%' }, $table);
    print $cg->end_form(),"\n";
    }
  print $cg->end_html(),"\n" if ($HTMLHEADER);
}



1;

__END__
