#!/usr/bin/env perl
# genomepathmap.pl

=head1 ABOUT

  genomepathmap.pl

  Apache mod_rewrite map handler for common genome data path.
 
  NOTE: RewriteMap is started/attached by mod_rewrite at apache-start-time
  gets NO browser/caller info (unless we send with calling params)

  Add to GMOD Bulkfiles toolset.
 
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

use POSIX;

my $webroot="/data/genomes";
my $realroot="$ENV{ARGOS_ROOT}/flybase/web$webroot";

my $genus="Drosophila"; #? could be regex pattern; check $ENV ? config files?
my $defaultspp="Drosophila_melanogaster"; 

## problem here -- get releases from file path
my %orgrel= ( 
#   dmel => "r4.1", 
#   dpse => "r1.03", 
#   dmelhet => "hetr32b2",
);

my $ok_gzip= 0; ## assume apache map caller knows
$| = 1;  # unbuffer for handleRewriteMap

if ($ENV{GATEWAY_INTERFACE} =~ /CGI/) {  
  if ($ENV{DOCUMENT_ROOT}) { $realroot="$ENV{DOCUMENT_ROOT}$webroot"; }
  handleCgi(); 
  }
else {
  handleRewriteMap();
}



sub handleCgi {

  my $pathinfo= shift @ARGV;
  
  if ($pathinfo =~ /help$/) { notfound($pathinfo); } # shouldn't be here
  elsif ($pathinfo =~/species$/) {  # list
    print STDOUT "Content-Type: text/plain\n\n";
    my @spp=();
    if (opendir(D,$realroot)) { @spp= grep(/Drosophila/i,readdir(D)); closedir(D); }
    print STDOUT join("\n",@spp),"\n";
    exit;
    }

  $ok_gzip= ($ENV{HTTP_ACCEPT_ENCODING} =~ /gzip/);

  my ($path,$file)= getdatapath($pathinfo); # returns relpath/file w/o .gz

  my $pathtrans="$realroot/$path";
  if ($ok_gzip && -f "$pathtrans.gz") {  
    $pathtrans= "$pathtrans.gz";
    } 
  elsif (-f $pathtrans) {  
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

  print STDERR "genomepathmap.cgi $pathinfo => $fdate, $path\n";
  
  if ($ok_gzip && $pathtrans =~ /.gz$/) {
    print STDOUT "Content-Disposition: attachment; filename=$file.gz\n";
    print STDOUT "Last-Modified: $fdate\n";  
    print STDOUT "Content-Length: $flen\n";
    print STDOUT "Content-Encoding: gzip\n";
    print STDOUT "Content-Type: text/plain\n\n";
    if ($doget && open(F, $pathtrans)) {
      $nt= 0;
      while( ($n= read(F,$buf,16384))>0 ) { print STDOUT $buf; $nt += $n;} 
      close(F);
      ##print STDERR "url2gnofile $pathinfo ; nt=$nt\n";
      }
    } 
  else {
    print STDOUT "Content-Disposition: attachment; filename=$file\n";
    print STDOUT "Last-Modified: $fdate\n";
    if ($pathtrans =~ /.gz$/) {
      print STDOUT "Content-type: text/plain\n\n";
      if ($doget && open(F,"gunzip -c $pathtrans|")){  print STDOUT join("",<F>); close(F); }
      }
    else {
      print STDOUT "Content-Length: $flen\n";
      print STDOUT "Content-type: text/plain\n\n";
      if ($doget && open(F,"$pathtrans")){  print STDOUT join("",<F>); close(F); }
      }
    }

}

sub handleRewriteMap {

  open(LOG,">>$realroot/url2file.log"); 
  print LOG "getfile ENV:\n",join("\n ",map{ "$_ => $ENV{$_}" } sort keys %ENV),"\n"; 
  close(LOG);

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
    open(LOG,">>$realroot/url2file.log"); print LOG "url2genomap $_ => $path,$pathtrans\n"; close(LOG);
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


sub getrelease {
  my( $uri, $org, $path, $filepatt, $suff)= @_;
  my $rel;
  if ($uri =~ /hetero/) { $org= $org.'het'; } ## $org eq "dmel" && 
  ##if ($org eq "dmel" && $uri =~ /hetero/) { $rel= $orgrel{$org.'het'}; }
  $rel= $orgrel{$org};
  if ($rel && $rel !~ /^-/) { $rel="-$rel"; }
  
  #check path for $org-release(.*).txt ??
  unless($rel) {
    if(opendir(D,"$realroot/$path")) {
      my ($relf,@rels)=  grep(/^$filepatt/, readdir(D));
      closedir(D);
      $relf =~ s/^$filepatt//;
      $relf =~ s/$suff.*$//;
      $rel= $relf;
      $orgrel{$org}= $rel; 
      }
    }
  return $rel;
}

sub getdatapath {
  my($uri)= @_;
  
  my $format="fasta";
  my $spp= $defaultspp; 
  my $org="dmel";
  my $part="-all";
  my $folder="current";
  
  if ($uri =~ /(${genus}_\w+)/) { $spp= $1; } 
  
  if ($spp =~ /^(\w)[^_]*_(\w{1,3})/) {
    $org= lc("$1$2"); # Gspp 4 letter abbrev.
    }
  
  my $type="-NULL"; ## need to fail if no primary verb: dna,protein,transcript or alias
  if ($uri =~ /(gff|features)$/i) { $format="gff"; $type=""; }
  elsif($uri =~ /(protein|proteome|translation)$/i) { $type="-translation"; }
  elsif($uri =~ /(transcript|transcriptome)$/i) { $type="-transcript"; }
  elsif($uri =~ /(genome|dna|chromosome)$/i) { $type="-chromosome"; }
  ## else error ?
  
  ## fixme - also check $uri for real version-folder 
  ## e.g. if ($uri =~ /(version|release)([\w..])/)
  if ($org eq "dmel" && $uri =~ /hetero/i) { $folder="current_hetchr"; }
  
  my $path = "$spp/$folder/$format";
  my $file = "$org$part$type";
  
  my $rel= getrelease( $uri, $org, $path, $file,".$format"); #, $defaultrelease);
  
  $file = "$file$rel.$format";
  $path = "$path/$file";

  return (wantarray) ? ($path,$file) : $path;
}
