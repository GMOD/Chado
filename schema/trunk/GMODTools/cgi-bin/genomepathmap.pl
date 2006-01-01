#!/usr/bin/env perl
# genomepathmap.pl

=head1 ABOUT

  genomepathmap.pl

  Apache mod_rewrite map handler for common genome data path.
 
  NOTE: RewriteMap is started/attached by mod_rewrite at apache-start-time
  gets NO browser/caller info (unless we send with calling params)

  Added to GMOD Bulkfiles toolset.
 
  D. Gilbert, mar 2005

  # --- /genome/README.html ------
  
  Common genome URLS for Model Organism Databases will support automated retrievals:<p>
  /genome/dna  OR /genome/genome   = full genome dna in FastA format of primary organism
    (<i>D. melanogaster</i>). <br>
  /genome/protein OR /genome/proteome  = full genome protein set " <br>
  /genome/transcript OR /genome/transcriptome  = full genome RNA transcript set  "<br>
  /genome/features OR /genome/gff   = full genome RNA feature set (GFF format)<br>
  <br>
  /genome/{species-name}/{dna, protein and trancript}  = full set for that species,
    for the above listed species.  <br>
  <br>
  /genome/species  = list available species
  /genome/help     = information page (i.e., this page, equivalent to /genome/ ). <br>
  <p>
  <i>D. melanogaster</i> heterochromatin currently is handled as
    a separate section: /genome/heterochromatin/{dna,protein,transcript}
    OR  /genome/Drosophila_melanogaster/heterochromatin/{...}
  <p>
  
  Support for alternate versions and formats may be added later. <br>
  
 
  # --- Apache httpd .conf ------
  RewriteEngine on
  
  ## support for GMOD common /genome/ data urls, mar05
  ## NOTE: /genomes/ is now symlink to same data/genomes/ folder
  ## this does something, not right though
  RewriteRule  ^/genome$   /genome/
  RewriteRule  ^/genome/(.*)   /data/genomes/$1  [PT]
  RewriteMap    genomedata-map       prg:/bio/argos/flybase/cgi-bin/genomepathmap.pl
  
  # -- these settings for local .htaccess (path relative)
  # -- change to <Location "/genome/">
  <Directory "/bio/argos/flybase/data/genomes">
  RewriteRule help$   "" [L]
  RewriteRule (species)$  /cgi-bin/genomepathmap.pl?%{REQUEST_URI} [L]
  
  ##RewriteCond %{REQUEST_URI} (dna|features|protein|transcript)$
  RewriteCond %{REQUEST_URI} (dna|chromosome|genome|features|gff|protein|proteome|transcript|transcriptome)$
  RewriteCond %{HTTP:Accept-encoding}  gzip
  RewriteCond ${genomedata-map:%{REQUEST_URI}/gzip}  (.+)
  RewriteRule  . %1 [L]
  
  # this works ok; will handle gzip-enabled and non-gz browsers
  RewriteRule (dna|chromosome|genome|features|gff|protein|proteome|transcript|transcriptome)$ \
   /cgi-bin/genomepathmap.pl?%{REQUEST_URI} 
   
  <IfModule mod_layout.c>
    ## this was problem for .cgi calls !
    LayoutDefaultHandlers Off
    LayoutHandler text/html
    LayoutMerge Off
  </IfModule>
  
  </Directory>

=cut

use strict;
use POSIX;
use constant DEBUG => 0;

#my $webroot="/data/genomes";
my $webroot="/genome";
my $realroot="$ENV{ARGOS_ROOT}/MY_SPECIES/web$webroot";
if ($ENV{DOCUMENT_ROOT}) { $realroot="$ENV{DOCUMENT_ROOT}$webroot"; }

my $genus= $ENV{GENUS} || "MY_GENUS"; #? could be regex pattern; check $ENV ? config files?
my $defaultspp= $ENV{SPECIES} || "MY_SPECIES"; 
my $LOGFILE="$realroot/url2file.log"; # debug only

## problem here -- get releases from file path
my %orgrel= ( 
#   dmel => "r4.1", 
#   dpse => "r1.03", 
);

my $ok_gzip= 0; ## assume apache map caller knows
$| = 1;  # unbuffer for handleRewriteMap

if ($ENV{GATEWAY_INTERFACE} =~ /CGI/) {  
  handleCgi(); 
  }
else {
  ## this call is for use from apache 
  ## RewriteMap    genomedata-map       prg:/bio/argos/flybase/cgi-bin/genomepathmap.pl
  handleRewriteMap();  
}

sub getspecies {
  my @spp=();
  if (opendir(D,$realroot)) { @spp= grep(/[A-Z]\w*_\w+/,readdir(D)); closedir(D); }
  return sort @spp;
}


sub handleCgi {

  ##  add optional params: uri=%{REQUEST_URI} ; config= ; type_map= ? ;  
  my $pathinfo= shift @ARGV;
  
  if ($pathinfo =~ /help$/) { notfound($pathinfo); } # shouldn't be here
  elsif ($pathinfo =~/species$/) {  # list
    print STDOUT "Content-Type: text/plain\n\n";
    print STDOUT "# $pathinfo \n";
    my @spp= getspecies();
    print STDOUT join("\n",@spp),"\n";
    exit;
    }
#   elsif ($pathinfo =~/release$/) {  # list; check for species in pathinfo
#     print STDOUT "Content-Type: text/plain\n\n";
#     print STDOUT "# $pathinfo \n";
#     my @rels=();
#     my @spp= getspecies();
#     foreach my $spp (@spp) {
#       if (opendir(D,"$realroot/$spp")) { 
#         push @rels, map { "$spp/$_"; } grep(/^\w/,readdir(D)); 
#         closedir(D); 
#         }
#       }
#     print STDOUT join("\n",@rels),"\n";
#     exit;
#     }

  $ok_gzip= ($ENV{HTTP_ACCEPT_ENCODING} =~ /gzip/);

  my ($path,$file)= getdatapath($pathinfo); # returns relpath/file w/o .gz

  my $pathtrans="$realroot/$path";
  if ($ok_gzip && -f "$pathtrans.gz") {  
    $pathtrans= "$pathtrans.gz";
    } 
  elsif (-f $pathtrans) {  
    #?? make gzip if $ok_gzip 
    } 
  elsif (-f "$pathtrans.gz") {  
    $pathtrans= "$pathtrans.gz";
    } 
  else { notfound($file); } # exits

  my $doget= ($ENV{'REQUEST_METHOD'} =~ m/GET|POST/);
  my $flen = -s $pathtrans;
  
  my $fdate= -M $pathtrans;
  my @tm= gmtime( $^T - 24*60*60*$fdate );
  $fdate= POSIX::strftime( "%a, %d %b %Y %T GMT", @tm); ## apache is picky about format here
  ## see HTTP::Date: sub time2str (;$)
  ## Last-Modified: Tue, 15 Feb 2005 02:10:15 GMT
  my $contype="text/plain";
  if ($file =~ /fasta/) { $contype="application/x-fasta"; }
  elsif($file =~ /gff/) { $contype="application/x-gff3";  }
  
  print STDERR "genomepathmap.cgi $pathinfo => $fdate, $path\n" if DEBUG;
  
  if ($ok_gzip && $pathtrans =~ /.gz$/) {
    print STDOUT "Content-Disposition: attachment; filename=$file.gz\n";
    print STDOUT "Last-Modified: $fdate\n";  
    print STDOUT "Content-Length: $flen\n";
    print STDOUT "Content-Encoding: gzip\n";
    print STDOUT "Content-Type: $contype\n\n";
    ##print STDOUT "Content-Type: text/plain\n\n";
    # ^^ wormbase spec says: MIME  type is application/x-fasta or application/x-gff3
    if ($doget && open(F, $pathtrans)) {
      my ($n,$buf,$nt);
      binmode(F);
      binmode(STDOUT);
      ## apache-melon is trashing gzip output above; closes after 8 bytes received; read is ok
      # while( ($n= read(F,$buf,16384))>0 ) { print STDOUT $buf; }  # $nt += $n;
      while( ($n= sysread(F,$buf,16384))>0 ) { syswrite STDOUT,$buf,$n; $nt += $n; }
      close(F);
      print STDERR "url2gnofile $pathinfo ; nt=$nt\n";
      }
    } 
  else {
    print STDOUT "Content-Disposition: attachment; filename=$file\n";
    print STDOUT "Last-Modified: $fdate\n";
    if ($pathtrans =~ /.gz$/) {
      print STDOUT "Content-Type: $contype\n\n";
      if ($doget && open(F,"gunzip -c $pathtrans|")){  print STDOUT join("",<F>); close(F); }
      }
    else {
      print STDOUT "Content-Length: $flen\n";
      print STDOUT "Content-Type: $contype\n\n";
      if ($doget && open(F,"$pathtrans")){  print STDOUT join("",<F>); close(F); }
      }
    }

}

sub handleRewriteMap {
  if (DEBUG && $LOGFILE){
  open(LOG,">>$LOGFILE"); 
  print LOG "getfile ENV:\n",join("\n ",map{ "$_ => $ENV{$_}" } sort keys %ENV),"\n"; 
  close(LOG);
  }

  $| = 1;  # unbuffer for handleRewriteMap
  while(<STDIN>) 
  {
    if ($_ =~ s,/gzip$,,) { $ok_gzip= 1; } else { $ok_gzip= 0; } #? tack onto call path
    my $path= getdatapath($_); # returns relpath/file w/o .gz
  
    my $pathtrans="NULL";
    if ($ok_gzip && -f "$realroot/$path.gz") {  
      $pathtrans="$webroot/$path.gz";
      } 
    elsif (-f "$realroot/$path") {  
      $pathtrans= "$webroot/$path";
      } 
  
    print STDOUT "$pathtrans\n";
    if (DEBUG && $LOGFILE){ open(LOG,">>$LOGFILE"); print LOG "genomepath $_ => $path,$pathtrans\n"; close(LOG); }
  }
}


sub notfound {
  my($file)=@_;
  print STDOUT qq{Status: 404 Not Found
Content-Type: text/html

<HTML><HEAD><TITLE>404 Not Found</TITLE> </HEAD><BODY>
<H1>Not Found</H1>
The requested URL $file  was not found on this server.<P>
</BODY></HTML>
   };
  exit(0);
}   



# sub getrelease {
#   my( $uri, $org, $path, $filepatt, $suff)= @_;
#   my $rel;
#   
#   ##hack##if ($uri =~ /hetero/) { $org= $org.'het'; } ## $org eq "dmel" && 
#   ##if ($org eq "dmel" && $uri =~ /hetero/) { $rel= $orgrel{$org.'het'}; }
# 
#   $rel= $orgrel{$org};
#   if ($rel && $rel !~ /^-/) { $rel="-$rel"; }
#   
#   #check path for $org-release(.*).txt ??
#   unless($rel) 
#   {
#     if(opendir(D,"$realroot/$path")) {
#       my ($relf,@rels)=  grep(/^$filepatt/, readdir(D));
#       closedir(D);
#       $relf =~ s/^$filepatt//;
#       $relf =~ s/$suff.*$//;
#       $rel= $relf;
#       $orgrel{$org}= $rel; 
#       }
#   }
#   return $rel;
# }

sub getreleasefile {
  my( $uri, $path, $filepatt, $suff)= @_;
  my($file)=('');
  if(opendir(D,"$realroot/$path")) {
    my @files=  grep(/$filepatt/, readdir(D));
    closedir(D);
    ## need .gz check; more, do what?
    ($file,my @more) = grep(/$suff(.gz)?$/,@files);
    $file=~s/\.gz$//; # handler checks for .gz
    }
  return $file;
}


## FIXME ....
sub getdatapath {
  my($uri)= @_;
  
  my $format="fasta";
  my $spp= $defaultspp; 
  my $org=""; ##"dmel";
  my $part="-all";
  my $folder="current";
  
  if ($uri =~ m,/(${genus}_\w+),) { $spp= $1; } 
  elsif ($uri =~ m,/([A-Z]\w+_\w+),) { $spp= $1; } 
  
  if ($spp =~ m/^(\w)[^_]*_(\w{1,3})/) {
    $org= lc("$1$2"); # Gspp 4 letter abbrev.
    }

  if ($uri =~ m,/$spp/(\w[^/]+)/.+,) { $folder= $1; } 
  
  my $type="NULL"; ## need to fail if no primary verb: dna,protein,transcript or alias
  if ($uri =~ /(gff|feature)$/i) { $format="gff"; $type=""; }
  elsif($uri =~ /(genome|dna|chromosome)$/i) { $type="chromosome"; }
  elsif($uri =~ /(protein|proteome|translation)$/i) { $type="translation"; }
  elsif($uri =~ /(mrna|transcript|transcriptome)$/i) { $type="transcript"; }
  elsif($uri =~ /(ncrna|miscrna)$/i) { $type="miscRNA"; } ## change ot ncRNA
    ## ^^ need to know what fasta labels are being used: ncRNA? miscRNA? tRNA ?
  ## else error ?

  # hack needs some config file... check in $spp/ path ?
  if ($spp =~ /Saccharomyces/) { 
    $type =~ s/transcript/gene/;
    $type =~ s/miscRNA/ncRNA/;
    ## no protein data here ??
  }
  
  ## fixme - also check $uri for real version-folder 
  ## e.g. if ($uri =~ /(version|release)([\w..])/)
  
  my $path = "$spp/$folder/$format";
  my $filepatt = $part;
  $filepatt .= "-$type" if $type;
  
  ## need .gz, no.gz option, check for both
  my $file= getreleasefile( $uri, $path, $filepatt,".$format"); 
  $path = "$path/$file";
  return (wantarray) ? ($path,$file) : $path;
}
