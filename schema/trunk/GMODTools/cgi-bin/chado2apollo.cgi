#!/usr/local/bin/perl
# chado2apollo.cgi

=head1 chado2apollo.cgi

Chado database lookups with GAME.xml output

=head1 SERVER 
    http://flybase.net/apollo-cgi/chado2apollo.cgi

    (proxies to) 
    http://bugbane.bio.indiana.edu:7092/apollo-cgi/chado2apollo.cgi

=head1 EXAMPLES

    http://flybase.net/apollo-cgi/chado2apollo.cgi?scaffold=AE003650
    
    http://flybase.net/apollo-cgi/chado2apollo.cgi?gene=cact

    http://flybase.net/apollo-cgi/chado2apollo.cgi?range=2L:300000-310000

    http://flybase.net/apollo-cgi/chado2apollo.cgi?band=34A

=head1 USAGE

  You need to request one of these: 
    gene (e.g. ?gene=cact),
    scaffold accession (e.g. ?accession=AE003650),
    range (e.g. ?range=2L:300000-310000),
    cytological band (e.g. ?band=34A)
  Use '&scaffolds=1' option to get speedy access to data chunks.
  Otherwise database exraction of chado/game xml objects can take many minutes!
  Use '&database=chado' option, or no database, for now.
  The 'sequence=AGCT' lookup is not yet supported.
  The 'next' and 'prev' options are not yet supported. 

=head1 Apollo API lookups are 

=head2 GeneURL

    "http://{server}/cgi-bin/get_xml_url.pl?database=%DATABASE%&gene=" ^^^
    needs to look up data by Gene symbol, CG identifier

=head2 RangeURL

    "http://{server}/cgi-bin/get_xml_url.pl?database=%DATABASE%&range=" ^^^
    needs to look up data by range=X:10000-20000; range = chrom:start:end
    (e.g. 2L:162339:264334) chromosome arm start and end

=head2 BandURL

    "http://{server}/cgi-bin/get_xml_url.pl?database=%DATABASE%&band=" ^^^
    cytological band, essential same as Range w/ cyto to seq mapping

=head2 ScaffoldURL

    "http://{server}/cgi-bin/get_xml_url.pl?database=%DATABASE%&accession="
    ^^^ this one just finds proper static scaffold.game.xml file see nomi's
    perl for this: my $url = &find_xml_for_scaffold($scaffold); print
    $cgi->redirect($url);

=head2 SequenceURL

    "http://{server}/cgi-bin/get_xml_url.pl?database=%DATABASE%&sequence="
    ^^ not sure about this; example perl does blast against scaffolds then
    returns scaffold xml for matching scaffold ID.

=head1 NOTES
    -- 1jul04 : need start+1 fix somewhere: chado has 0-based positions
      (but seq starts at 1 :(), i.e. feature.start+1 is visible start value
      but indexing uses start(0).
      game uses 1-based positions(?); 
      fix needed for sequence map_position
  <map_position type="tile" seq="2L:16266112-16329185">
    <arm>2L</arm>
    <span>
      <start>16266112</start>
      <end>16329185</end>
    </span>
  </map_position>
      
      need correct anything else? 
      -- featurelocs are all from game.xml, should not need correcting.

    -- Apr 2004: added fast search/retrieval using 
       LuceGene/Lucene indexed game.xml files. E.g.  15 sec to search and
       retrieve all of 6 MB gene message, versus 10+ minutes on
       same computer using Pg generated gene message.
       
    -- in testing , Mar 2004
    
    -- gene lookups -- want either name (gene name) OR uniqename (CG)
    
    -- direct query to chado-postgres and XORT xml object generation
    takes too look/too much cpu (5 - 10 minutes, running new 2cpu linux
    server to max).

    /usr/bin/time cgi-bin/chado2apollo.cgi gene=cact > ch-cact-game.xml
    467.08 real 51.49 user 6.92 sys ^^^^^^ 8 minutes?
                                          ~~~~~~~~~~~~~

     62.38 user 5.11 system 4:04.05 elapsed 27%CPU (0avgtext+0avgdata 0maxresident)k
    0inputs+0outputs (2545major+16913minor)pagefaults 0swaps

      - 5 - 10 minutes on bugbane
      
      /usr/bin/time ./chado*cgi gene=cact scaffolds=0 > ch-cact.xml

curl -i 'http://flybase.net/apollo-cgi/chado2apollo.cgi?debug=1&scaffold=AE003650'
curl -i 'http://flybase.net/apollo-cgi/chado2apollo.cgi?gene=cact&usedb=1'  

=cut

#-------- begin begin ---------

BEGIN {  
  # set to use conf/ lib/ in cgi local folder
  require File::Basename;
  my $mybbin=  File::Basename::dirname($0);
  unshift(@INC,"$mybbin/lib") if (-d "$mybbin/lib");
  $ENV{GMOD_ROOT}= $mybbin if (-d "$mybbin/conf");
}

##  test
# use lib('/bio/biodb/flybase/lib/perl');
# use lib('/bio/biodb/common/perl/lib');
# use lib('/bio/biodb/common/system-local/perl/lib');
# use warnings;


#-------- real begin ---------

use strict;

use GMOD::Config; # reads conf/gmod.conf, only knows of GMOD_ROOT, not flybase, etc...
#? use Argos::Config; # or use this?

use CGI;
use CGI::Carp 'fatalsToBrowser';
use File::Basename;
use XML::XORT::Util::DbUtil::DB;
use XML::XORT::Dumper::DumperXML;
use POSIX;

my $servicename    = "chado2apollo, http://flybase.net/apollo/";
my $chado2gamejar  = 'GameChadoConv.jar';
my $dump_spec_file = 'dumpspec_apollo.xml';
my $scaffold_type  = 'golden_path_region'; 
   # this one is up in air: golden_path_region  golden_path_fragment databank_scaffold golden_path
my $gene_type      = 'gene';
my $arm_type       = 'chromosome_arm';
my ($java_path, $dump_spec)= (undef,undef);
my $organism       = "Drosophila melanogaster";

my $DEBUG= $ENV{DEBUG} || 0;
my $mybin=  File::Basename::dirname($0);
my $myroot= $ENV{ARGOS_SERVICE_ROOT} || "$mybin/..";
my $outputComment="";

my $tmp=  $ENV{XORT_TMP} || "$myroot/tmp";
$tmp= "/tmp/" unless(-d $tmp);
$ENV{XORT_TMP}= $tmp;

my @xconf= ( $ENV{XORT_CONF}, "$mybin/conf/xort/", "$mybin/conf/", "$myroot/conf/xort/", "$myroot/conf/" );
foreach my $xconf (@xconf) {
  if (-d $xconf && -f "$xconf/$dump_spec_file") {
    $ENV{XORT_CONF}= $xconf; last; 
    }
  }

my @default_dbs= qw( chado gadfly ); # default name for old/new callers
my $dbname= $ENV{CHADO_DB_NAME};
  
my $gameScaffolder= $ENV{APOLLO_DATA};
my $gameScafUrl= $ENV{APOLLO_DATA_URL}; # but these are/will be all .gzipped

my $usePgDb=  0;
my $useLucegene= 1;
my $onlyScaffolds= 1; # xort/pg calls are BIG cpu pigs 5-10 minutes/call
if ( defined $ENV{APOLLO_SCAFFOLDS_ONLY} ) { 
  $onlyScaffolds= $ENV{APOLLO_SCAFFOLDS_ONLY};
  }
if ( defined $ENV{APOLLO_USE_LUCENE} ) { 
  $useLucegene= $ENV{APOLLO_USE_LUCENE};
  }

#adjacent region for mini-xml
my $expand_range= 25000;
my $DID_HEADER=0;
#----------- BEGIN -----------------
my $start_time=time();
my $cgi = new CGI;

$DEBUG = 1 if ($cgi->param('debug'));
if ($DEBUG) {
  httpheader('text/plain'); 
	print "<!-- ***DEBUG MODE*** -->\n";
	## this gets in way of xml parser - needs 1st line = <!xml...>
  }

# ignore database param for now
# $dbname= $cgi->param('database') || $dbname;

# use dbname here?
my $version= $ENV{CHADO_DB_VERSION};
if (!$version && $ENV{CHADO_DB_NAME}) { $version= "Drosophila annotations from $ENV{CHADO_DB_NAME}";}
if (!$version) { $version= "Drosophila annotations release 3.2 from chado"; }

if (defined $cgi->param('useluc')) { 
  $useLucegene= ($cgi->param('useluc') =~ /on|1|yes/i); 
  } 
if (defined $cgi->param('usedb')) { 
  $usePgDb= ($cgi->param('usedb') =~ /on|1|yes/i);
  $onlyScaffolds = 0 if ($usePgDb);
  $useLucegene = 0 if ($usePgDb);
  } 
if (defined $cgi->param('window')) { 
  my $window= $cgi->param('window') ; 
  $expand_range= int($window/2);
  } 


#--- Apollo web services API ------
my ($gene,$scaffold,$sequence,$cytology,$range);

if ($cgi->param('namesearch')) {
    $gene = $cgi->param('namesearch');
}
elsif ($cgi->param('gene')) {
    $gene = $cgi->param('gene');
}
elsif ($cgi->param('scaffold')) {
    $scaffold = $cgi->param('scaffold');
}
elsif ($cgi->param('accession')) {
    $scaffold = $cgi->param('accession');
}
elsif ($cgi->param('cytology')) {
    $cytology = $cgi->param('cytology');
}
elsif ($cgi->param('band')) {
    $cytology = $cgi->param('band');
}
elsif ($cgi->param('range')) {
    $range = $cgi->param('range');
}
elsif ($cgi->param('location')) {
    $range = $cgi->param('location');
}
## not ready yet ..
# elsif ($cgi->param('seq')) {
#     $sequence = $cgi->param('seq');
# }
# elsif ($cgi->param('sequence')) {
#     $sequence = $cgi->param('sequence');
# }
else {
  callErrorExit ( 
  "<h1>Chado database lookups (GAME.xml output)</h1>\n"
  ."You need to request one of these: <br>\n"
  ."  gene (e.g. ?gene=cact),<br>\n"
  ."  scaffold accession (e.g. ?accession=AE003650),<br>\n"
  ."  range (e.g. ?range=2L:300000-310000),<br>\n"
  ."  cytological band (e.g. ?band=34A)<br>\n<br>\n"
  ."Default use provides speedy access to pre-generated GAME XML scaffolds.<br>\n"
  ."Use '&usedb=1' option to have database generate XML at call time.<br>\n"
  ."The generation of  chado/game xml objects currently take many minutes!<br>\n<br>\n"
  ."Use '&database=chado' option, or no database, for now.<br>\n"
  ."The 'next' and 'prev' options are supported for scaffold/accession lookups.<br>\n"
  ."The 'sequence=AGCT' lookup is not yet supported.<br>\n"
  , 'always');
  }

my $step = 0;
if ($cgi->param('next')) {  $step = 1; }
elsif ($cgi->param('prev')) {  $step = -1; }

#--- END Apollo web services API ------

my $ok= 0;
my $saveSql="SQL query: ";

#my $date= POSIX::strftime( "%y-%m-%d:%H:%M,%Z", localtime( $start_time) );
my $date= POSIX::strftime( "%x:%X,%Z", localtime( $start_time) );
my $dbnote="";
if($useLucegene) { $dbnote="Game XML generated from LuceGene object database"; } 
elsif($usePgDb) { $dbnote="Game XML generated from Postgres relational database"; } 
elsif($onlyScaffolds) { $dbnote="Game XML from static scaffold files"; } 

$outputComment= <<"HERE";
  <!-- service: $servicename -->
  <!-- data-version: $version -->
  <!-- data-source: $dbnote -->
  <!-- run-date: $date -->
  <!-- note: seq_relationship query span.start,end coordinates 
       are relative to map_position span.start,end -->
HERE

if ($gene) {
  $ok=dumpGene($gene, $expand_range);
  }
elsif ($range) {
  $ok= dumpLocation($range); #? add $step support?
  }
elsif ($scaffold) {
  $ok= dumpScaffold($scaffold, $step);   # support $next,$prev
  }
elsif ($cytology) {
  $ok= dumpCytology($cytology);
  }
elsif ($sequence) {
  # dumpSequence($sequence);
  callErrorExit("Query by sequence not yet supported");  
  }
else {
  # nothing?
  }

unless($ok) {
  callErrorExit(
   "An error or no result occurred with this query:\n"
   . $saveSql
   );
  }
  
if ($DEBUG) {
  my $end_time=time();
  print "<!--DEBUG run_time = " . ($end_time - $start_time) . "sec -->\n";
  }
  
exit;

#----------------- SUBS -----------------

sub callErrorExit {
  my ($msg, $alwaysprint)= @_;
  if ($alwaysprint || $DEBUG) {
    httpheader("text/plain");
    print $outputComment,"\n" if $outputComment;
    print $msg;
    }
  else {
    # return blank message as per apollo dev instructions
    httpheader("text/plain");
    print "\n";
    }
  exit;
}

sub escapeHtml {
  local $_= shift @_;
  s,<,&lt;,g;
  s,>,&gt;,g;
  s,&,&amp;,g;
  return $_;
}

  # may not need to call, if want/have scaff game xml files
sub callXort2Game {
  my ($appdata)= @_;
  
  unless($dump_spec && -r $dump_spec) {
    $dump_spec= $ENV{XORT_CONF}."/$dump_spec_file";
    die "Missing $dump_spec_file" unless(-r $dump_spec);
    }
  
  unless( $java_path && -r $java_path) {
    my @jlib= ("$mybin/lib", "$myroot/lib/java", "$myroot/lib", $ENV{XORT_CONF}, split(/:/,$ENV{CLASSPATH}||'') );
    foreach my $jlib (@jlib) {
      if (-r "$jlib/$chado2gamejar") { $java_path= "$jlib/$chado2gamejar"; last; }
      }
    die "Missing $chado2gamejar" unless(-r $java_path);
    }

  my $file_chado= "$tmp/chado2apollo$$.chado.xml";
  my $file_game=  "$tmp/chado2apollo$$.game.xml";
  
  my $xml_obj= XML::XORT::Dumper::DumperXML->new( $dbname, 0); ## $DEBUG -- very verbose

  ##print "<!-- XORT::Generate_XML($file_chado, $dump_spec, $appdata) -->\n" if $DEBUG;
   #NOTE Generate_XML ERASES $file_chado each call
  my $ok;
  $ok= eval { $xml_obj->Generate_XML(
          -file=>$file_chado,  
          -format_type=>'no_local_id', 
          -op_type=>'' , 
          -struct_type=>'module', 
          -dump_spec=>$dump_spec,  
          -app_data=>$appdata
          );
    };
  if ($@) { warn "XORT::Generate_XML error: $@\n"; }
  ##print "<!-- done XORT::Generate_XML() -->\n" if $DEBUG;
  
  $ok= 0;
  ## sendXmlToCaller($file_chado);
  if (-e $file_chado) {
    httpheader('text/plain');# text/xml or plain ?
    
    my $JAVA_FLAGS="-Xmx200M -Xms200M";
    my @cmd= ("java", $JAVA_FLAGS, "-cp", $java_path, "CTG", ##$JAVA_APP,
      $file_chado,
      $file_game,
      );
    my $cmd= join(" ",@cmd);

    ##print "<!-- $cmd -->\n" if $DEBUG;
    my $err= `$cmd`;
    unlink($file_chado);
    if (open(F,$file_game)) { while(<F>) {print ;}  close(F); $ok=1; }
    unlink($file_game);
    }
  return $ok;
}

sub httpheader {
  my $ct = shift || 'text/plain';
  print $cgi->header(-type => $ct) unless $DID_HEADER; $DID_HEADER++; 
}

sub sendScafFile {
  my($scafname)= @_;

# $gameScaffolder= $ENV{APOLLO_DATA};
# $gameScafUrl= $ENV{APOLLO_DATA_URL}; # but these are/will be all .gzipped

  my $f= "$gameScaffolder/$scafname.game.xml";
  if (-f $f && open(F,$f)) {
    httpheader(); while(<F>) {print ;}  close(F); return 1;
    }
  elsif (-f "$f.gz" && open(F,"gunzip $f.gz|")) {
    httpheader(); while(<F>) {print ;}  close(F);  return 1;
    }
  elsif (-f "$f.bz2" && open(F,"bzcat $f.bz2|")) {
    httpheader(); while(<F>) {print ;}  close(F); return 1;
    }
  return 0;
}


=item GMOD2XORT_props

Convert GMOD properties to XORT.properties hash

  db_type=postgres
  db=chado_gadfly9_t11 $ENV{CHADO_DB_NAME}
  host=localhost $ENV{CHADO_DB_HOST}
  port=7302 $ENV{CHADO_DB_PORT}
  user=gilbertd $ENV{CHADO_DB_USERNAME}
  password= $ENV{CHADO_DB_PASSWORD}  

=cut

sub GMOD2XORT_props {
  my ($db)= @_;
  my $xort_hash= {
    db_type => 'postgres',
    db   => $ENV{CHADO_DB_NAME},
    host => $ENV{CHADO_DB_HOST},
    port => $ENV{CHADO_DB_PORT},
    user => $ENV{CHADO_DB_USERNAME},
    password => $ENV{CHADO_DB_PASSWORD},
    };
    
  $xort_hash->{db}= $db if ($db && !grep(/^$db$/,@default_dbs) );
  $dbname= $xort_hash->{db}; # need this global
  return $xort_hash;
}

sub openDb {
  my $xortdb= GMOD2XORT_props($dbname); 
  if ($DEBUG) { 
    foreach my $k (sort keys %$xortdb) { 
      if ($k=~/password/i) { print "<!-- openDb: $k=secret -->\n" ; }
      else { print "<!-- openDb: $k=$xortdb->{$k} -->\n" ; }
      }
    }
  
  my $dbh= XML::XORT::Util::DbUtil::DB->_new($xortdb)  ;
  $dbh->open();
  return $dbh;
}


=item showTable - debug only

=cut

sub showTable {
  my ($table,$caller)= @_;
  print "<!--\n";
  if (ref($table) =~ /ARRAY/) {
    print "# $caller: results\n";
    for my $i ( 0 .. $#{$table} ) {
      print "# result-$i\t";
      for my $j ( 0 .. $#{$table->[$i]} ) { print "$table->[$i][$j]\t"; }
      print "\n";
      }
   }
  else {
    print "# $caller: no result\n";
    }
  print "-->\n";
}


=item dumpLocation("X:10000-20000")

=cut

sub dumpLocation {
  #range=X:10000-20000; range = chrom:start:end
  my ($arm,$start,$end)= @_;
  if ($arm =~ m/(\w+):(\d+)[-\.]{1,2}(\d+)/) {
    my $start1; # convert 1-based to 0-based
    $arm=$1; $start1=$2; $end=$3;
    $start= $start1 - 1;
    }
  
  my $ok= 0;
  my $stm_sql= sprintf("select f.feature_id, f.uniquename "
  . " from feature f, cvterm c where f.type_id=c.cvterm_id and c.name='%s' "
  . " and f.uniquename='%s'",  $arm_type, $arm);

  $saveSql .= $stm_sql." ;\n " ;
  print "<!-- dumpLocation: $stm_sql -->\n" if $DEBUG;
  
  my $dbh= openDb();
  my $table = $dbh->get_all_arrayref($stm_sql);
  $dbh->close();
  
  showTable($table,'dumpLocation') if $DEBUG;
  for my $i ( 0 .. $#{$table} ) {
      
    if ($useLucegene) {
      $ok= lucegameAtLoc($table->[$i][1], $start, $end);
      return $ok if ($ok>0);
      }
    if ($onlyScaffolds) {
      return scaffoldAtLoc($table->[$i][1], $start, $end);
      }

   #my $appdata=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][1]." ".$table->[$i][1];
   my $appdata=$table->[$i][0]." ".$start." ".$end." "
    .$table->[$i][1].":".$start."-".$end." ".$table->[$i][1];

   $ok= callXort2Game( $appdata);
   }
  return $ok;
}


=item scaffoldAtLoc($arm,$start,$end)

do lookup of scaffold name given arm:start-end from other queries
return scaf file/url

  select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm  
  from feature f1, cvterm c1, cvterm c2, featureloc fl, feature f2  
  where f1.type_id=c1.cvterm_id and c1.name='golden_path_region' 
  and f1.feature_id=fl.feature_id  
  and f2.type_id=c2.cvterm_id and c2.name='chromosome_arm'  
  and f2.uniquename='2L' 
  and f2.feature_id=fl.srcfeature_id
  and fl.fmin <= 16291112 and fl.fmax >= 16304185
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ bad for spanning scafs; swap min/max here
        
   feature_id |   fmin   |   fmax   |   scaf   | arm 
  ------------+----------+----------+----------+-----
      1695623 | 16066020 | 16339434 | AE003650 | 2L

select f.feature_id, f.uniquename  from feature f, cvterm c where f.type_id=c.cvter
m_id and c.name='chromosome_arm'  and f.uniquename='2L' ;
 select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm  from fea
ture f1, feature f2, cvterm c1, cvterm c2, featureloc fl  where f1.type_id=c1.cvterm_id and c1
.name='golden_path_region' and f1.feature_id=fl.feature_id   and f2.type_id=c2.cvterm_id and c
2.name='chromosome_arm'  and f2.feature_id=fl.srcfeature_id and f2.uniquename='2L' and fl.fmin
 <= 300000 and fl.fmax >= 310000 ;
--- bad range: 
chado_r3.2_18-#   and fl.fmin <= 300000;
 feature_id | fmin |  fmax  |   scaf   | arm 
------------+------+--------+----------+-----
    1273141 |    0 | 305900 | AE003590 | 2L

chado_r3.2_18-#   and fl.fmin <= 3000000 and fl.fmax >= 3100000
 feature_id |  fmin   |  fmax   |   scaf   | arm 
------------+---------+---------+----------+-----
    1200884 | 2822325 | 3137282 | AE003581 | 2L

  select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm  
  from feature f1, cvterm c1, cvterm c2, featureloc fl, feature f2  
  where f1.type_id=c1.cvterm_id and c1.name='golden_path_region' 
  and f1.feature_id=fl.feature_id  
  and f2.type_id=c2.cvterm_id and c2.name='chromosome_arm'  
  and f2.uniquename='2L' 
  and f2.feature_id=fl.srcfeature_id
  and fl.fmin <= 3000000 and fl.fmax >= 3100000


=cut

sub findScafAtLoc {
  my ($arm,$start,$end,$findall)= @_;
  if ($arm =~ m/(\w+):(\d+)[-\.]{1,2}(\d+)/) {
    my $start1; # convert 1-based to 0-based
    $arm=$1; $start1=$2; $end=$3;
    $start= $start1 - 1;
    }

  my $ok= 0;
  my $stm_sql= sprintf( 
     "select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm "
  . " from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl "
  . " where f1.type_id=c1.cvterm_id and c1.name='%s' and f1.feature_id=fl.feature_id  "
  . " and f2.type_id=c2.cvterm_id and c2.name='%s' "
  . " and f2.feature_id=fl.srcfeature_id and f2.uniquename='%s'"
  . " and fl.fmin <= %s and fl.fmax >= %s"
  ,  $scaffold_type, $arm_type, $arm,  $end, $start);
    #was $start, $end - bad for spanning scafs

  $saveSql .= $stm_sql." ;\n " ;
  print "<!-- scaffoldAtLoc: $stm_sql -->\n" if $DEBUG;
  my $dbh= openDb();
  my $table = $dbh->get_all_arrayref($stm_sql);
  $dbh->close();
  ## this can fail due to range not being included in 1 scaffold
  ## need patch for overlapping scafs
  ##  . " ( fl.fmin <= start and fl.fmax >= start ) or (  fl.fmin <= end and fl.fmax >= end)"

  showTable($table,'scaffoldAtLoc') if $DEBUG;
  return @$table if ($findall);
  
  if ($#{$table}>=0) {
    my($scafid, $scafstart, $scafend, $scafname, $scafarm) 
       = @{$table->[0]};
    return ($scafid, $scafstart, $scafend, $scafname, $scafarm);
    }
  return ();
}


sub scaffoldAtLoc {
  my ($arm,$start,$end)= @_;
  
  my ($scafid, $scafstart, $scafend, $scafname, $scafarm)
      = findScafAtLoc($arm,$start,$end);

  if ($scafname && sendScafFile($scafname)) { return 1; }
  else { return 0; }
}



=item dumpNextScaffold

support the next/prev options for moving a step along scaffolds

    if ($step > 0) { # next -- gadfly query
   $sql1 = "select sf2.name from seq_feature sf2, seq_feature sf1 where sf1.name
 = '$scaffold' and sf1.type = 'segment' and sf2.type = 'segment' and sf2.start < sf1.
end and sf2.start > sf1.start and sf2.src_seq_id = sf1.src_seq_id";
    }
    elsif ($step < 0) { # prev
   $sql1 = "select sf2.name from seq_feature sf2, seq_feature sf1 where sf1.name
 = '$scaffold' and sf1.type = 'segment' and sf2.type = 'segment' and sf2.end > sf1.st
art and sf2.end < sf1.end and sf2.src_seq_id = sf1.src_seq_id";
    }
    

=cut

sub dumpNextScaffold {
  my ($step, $scafname, $arm, $start, $end)= @_;
  my ($scafid, $scafstart, $scafend, $scafarm);
  my $stm_sql;

  if ($arm) { #and start/end
    ($scafid, $scafstart, $scafend, $scafname, $scafarm)
      = findScafAtLoc($arm,$start,$end);
    }
  elsif ($scafname) {
    $stm_sql= sqlScafByName($scafname); # select scafid,start,end,scafname,arm
    $saveSql .= $stm_sql." ;\n " ;
    my $dbh= openDb();
    my $table = $dbh->get_all_arrayref($stm_sql);
    $dbh->close();
    
    showTable($table,'sqlScafByName') if $DEBUG;
    if ($#{$table}>=0) {
      ($scafid, $scafstart, $scafend, $scafname, $scafarm) 
        = @{$table->[0]};
      }
    }
  return 0 unless($scafarm && $scafend);

##  next query:  sf2.start < sf1.end and sf2.start > sf1.start
    
  my $ok= 0;
  my $nextsql= sprintf( 
     "select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm "
  . " from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl "
  . " where f1.type_id=c1.cvterm_id and c1.name='%s' and f1.feature_id=fl.feature_id  "
  . " and f2.type_id=c2.cvterm_id and c2.name='%s' "
  . " and f2.feature_id=fl.srcfeature_id and f2.uniquename='%s'"
  . " and fl.fmin > %s and fl.fmin < %s " # newstart > oldstart and newstart < oldend
  ,  $scaffold_type, $arm_type, $scafarm, $scafstart, $scafend);

##  prev query:  sf2.end > sf1.start and sf2.end < sf1.end
  my $prevsql= sprintf( 
     "select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm "
  . " from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl "
  . " where f1.type_id=c1.cvterm_id and c1.name='%s' and f1.feature_id=fl.feature_id  "
  . " and f2.type_id=c2.cvterm_id and c2.name='%s' "
  . " and f2.feature_id=fl.srcfeature_id and f2.uniquename='%s'"
  . " and fl.fmax > %s and fl.fmax < %s " # newend > oldstart and newend < oldend
  ,  $scaffold_type, $arm_type, $scafarm, $scafstart, $scafend);

  if ($step < 0) { $stm_sql= $prevsql; }
  else { $stm_sql = $nextsql; }
  
  $saveSql .= $stm_sql." ;\n " ;
  print "<!-- nextScaffold: $stm_sql -->\n" if $DEBUG;
  my $dbh= openDb();
  my $table = $dbh->get_all_arrayref($stm_sql);
  $dbh->close();
  showTable($table,'nextScaffold') if $DEBUG;
  
  if ($#{$table}>=0) {
    ($scafid, $scafstart, $scafend, $scafname, $scafarm)
        = @{$table->[0]};
    if ($scafname && sendScafFile($scafname)) { return 1; }
   }
  
  return 0;
}


sub sqlScafByName {
  my ($scafname)= @_;

  my $stm_sql= sprintf(
    "select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm"
    ." from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 "
    ." where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id "
    ." and c1.name='%s' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id "
    ." and c2.name='%s' and f1.uniquename='%s'", 
    $scaffold_type, $arm_type, $scafname ); 
  return $stm_sql;
}

=item dumpScaffold("AE0001234")

=cut

sub dumpScaffold {
  my ($scafname, $step)= @_;

 # my $url = &find_xml_for_scaffold($scaffold);
  my $ok= 0;
  if ($step != 0) { return dumpNextScaffold($step,$scafname); }

  if (sendScafFile($scafname)) { return 1; }
  
  my $stm_sql= sqlScafByName($scafname);
  
#   my $stm_sql= sprintf(
#     "select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename "
#     ." from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 "
#     ." where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id "
#     ." and c1.name='%s' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id "
#     ." and c2.name='%s' and f1.uniquename='%s'", 
#     $scaffold_type, $arm_type, $scafname ); 

  $saveSql .= $stm_sql." ;\n " ;
  print "<!-- dumpScaffold: $stm_sql -->\n" if $DEBUG;
  my $dbh= openDb();
  my $table = $dbh->get_all_arrayref($stm_sql);
  $dbh->close();
  showTable($table,'dumpScaffold') if $DEBUG;
  
  for my $i ( 0 .. $#{$table} ) {

    my $start= $table->[$i][1]; ## - $expand_range;
    my $end=   $table->[$i][2]; ## + $expand_range;
    # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
    my $appdata=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][3]." ".$table->[$i][4];

    $ok= callXort2Game( $appdata);
    return $ok; # do only 1?
    }
  return $ok;
}


=item dumpGene("cact")

=cut

sub dumpGene {
  my ($gene, $expand_range)= @_;
  my $ok= 0;
  my $stm_sql= sprintf(
  "select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename "
  ." from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 "
  ." where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='%s' "
  ." and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='%s' "
  ." and (f1.uniquename='%s' or f1.name='%s')", 
   $gene_type, $arm_type, $gene, $gene); 

  $saveSql .= $stm_sql." ;\n " ;
  print "<!-- dumpGene: $stm_sql -->\n" if $DEBUG;

  my $dbh= openDb();
  my $table = $dbh->get_all_arrayref($stm_sql);
  $dbh->close(); # Generate_XML opens own handle !
 
  showTable($table,'dumpGene') if $DEBUG;
  for my $i ( 0 .. $#{$table} ) {

    my $start=$table->[$i][1] - $expand_range;
    my $end=  $table->[$i][2] + $expand_range;
 
    if ($useLucegene) {
      $ok= lucegameAtLoc($table->[$i][4], $start, $end);
      return $ok if ($ok>0);
      }
    if ($onlyScaffolds) {
      return scaffoldAtLoc($table->[$i][4], $start, $end);
      }

   # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
    my $appdata=$table->[$i][0]." ".$start." ".$end." ".$table->[$i][3]." ".$table->[$i][4];
    
    $ok= callXort2Game( $appdata);
    return $ok; # do only 1?
    }
  return $ok; 
}


=item dumpCytology("20A11")

=cut

sub dumpCytology {
  my ($cyto)= @_;

  my $ok= 0;
  my $cyto2= $cyto;
  if ($cyto=~ /(\w+)\-(\w+)/ ){ $cyto=$1; $cyto2= $2; }
  $cyto= "band-".uc($cyto);
  
  my $stm_sql= sprintf("select f.uniquename as cyto_name, fl2.fmin as cyto_fmin, "
  ." fl2.fmax as cyto_fmax, f3.uniquename, f3.feature_id "
  ." from feature f, featureloc fl, feature f2, featureloc fl2, feature f3, cvterm c "
  ." where f.feature_id = fl.srcfeature_id and fl.feature_id = f2.feature_id "
  ." and f2.feature_id = fl2.feature_id and f.type_id =c.cvterm_id and c.name='chromosome_band' "
  ." and fl2.srcfeature_id=f3.feature_id and fl2.rank = 0 and f.is_analysis = 'f' "
  ." and f.uniquename='%s'", $cyto);
  
  $saveSql .= $stm_sql." ;\n " ;
  print "<!-- dumpCytology: $stm_sql -->\n" if $DEBUG;
  
  my $dbh= openDb();
  my $table = $dbh->get_all_arrayref($stm_sql);
  $dbh->close();
  # warn "\nno location information for this location: $cyto\n" 
  #  and return undef if ($#{$table} == 0 );
  
  showTable($table,'dumpCytology') if $DEBUG;
  for my $i ( 0 .. $#{$table} ) {
    my $srcid= $table->[$i][4]; # ARM_ID
    my $start= $table->[$i][1]; # cyto_fmin
    my $end=   $table->[$i][2]; # cyto_fmax
    my $title= $table->[$i][0]; # cyto_name
    my $arm  = $table->[$i][3];

    if ($useLucegene) {
      $ok= lucegameAtLoc($arm, $start, $end);
      return $ok if ($ok>0);
      }
    if ($onlyScaffolds) {
      return scaffoldAtLoc($arm, $start, $end);
      }
    
    # substitute the following value in dumpspec:srcfeature_id, start, end,title(ie. gene_name/region/scaffold_name), arm_name
    my $appdata=$srcid." ".$start." ".$end." ".$title." ".$arm;

    $ok= callXort2Game( $appdata);
    return $ok; # do only 1?
    }
  return $ok; 
}


=item 

-- test apr04 ; use lucegene/lucene indexed game.xml scaffolds to generate
proper game.xml for a given request.

-- command line call example
bin/lucegene-search.sh -l gamexml -p dbs/lucegene/gamexml.properties \
  -c 'format native;arm:2R AND (start:[12329218 12620000] OR end:[12329218 12620000])' \
  > AE003803luc.xml


=cut

sub lucegameAtLoc {
  my ($arm,$start,$end)= @_;
  
    ## start+1 here ?
  my $start1= $start + 1 ;
  my $name= $arm.":".$start1."-".$end; #"$arm:$start-$end";
  httpheader('text/plain');# text/xml or plain ?
  print "<!-- lucegene search name=$name -->\n" if ($DEBUG);
  
  my($scafid, $scafstart, $scafend, $scafname, $scafarm);
    # need scaf loc to adjust contents span.start,end to query
    ## FIXME - this is bad for cytoloc and other queries spanning multiple scaffolds
#  ($scafid, $scafstart, $scafend, $scafname, $scafarm)
#       = findScafAtLoc($arm,$start,$end);
#   if ($scafstart > $scafend) { ($scafstart, $scafend)= ($scafend, $scafstart); }
  
  my %scafhash=();
  my @table = findScafAtLoc($arm,$start,$end,'findall');
  foreach my $trow (@table) {
    ($scafid, $scafstart, $scafend, $scafname, $scafarm) 
       = @$trow;
    $scafhash{$scafname}= $trow;
    }
  
  ## add to gmod.conf variables ??
  # DNA_LIB=$ARGOS_SERVICE_ROOT/data2/fban/current/gnomap
  # LUCEGENE_PROP_FILE=$ARGOS_SERVICE_ROOT/dbs/lucegene/gamexml.properties
  # LUCEGENE_INDEX_ROOT=$ARGOS_SERVICE_ROOT/indices/lucene
  # LUCEGENE_LIB_NAME=gamexml
  # JAVA_LIB=$ARGOS_SERVICE_ROOT/common/java/lib

  my $MY_HOME=$myroot;
  my $lib= $ENV{JAVA_LIB} || "$MY_HOME/common/java/lib";
  my $INDEX_ROOT= $ENV{LUCEGENE_INDEX_ROOT} || "$MY_HOME/indices/lucene";
  my $PROP_FILE= $ENV{LUCEGENE_PROP_FILE} || "$MY_HOME/dbs/lucegene/gamexml.properties";
  my $LIB_NAME= $ENV{LUCEGENE_LIB_NAME} || "gamexml";
  my $DNA_LIB= $ENV{DNA_LIB} || "$MY_HOME/data2/fban/current/gnomap"; # dna-chr.raw files here
  
  # see  flybase/bin/lucegene-search.sh
  my $JAVA_CP = $ENV{LUCEGENE_JAVA_CP} || "$lib/lucegene.jar:$lib/lucene.jar:$lib/readseq.jar";
  my $JAVA_APP= $ENV{LUCEGENE_SEARCH_CLASS} || "org.eugenes.index.LuceneSearch";
  my $JAVA_FLAGS="-Xms10M -Xmx90M";
  
  ## check available parts
  unless(-d $INDEX_ROOT) { 
    warn "Missing INDEX_ROOT=$INDEX_ROOT" if ($DEBUG);
    return 0; 
    }
  unless(-f $PROP_FILE) { 
    warn "Missing PROP_FILE=$PROP_FILE" if ($DEBUG);
    return 0; 
    }
  unless(-f "$lib/lucegene.jar") { 
    warn "Missing $lib/lucegene.jar" if ($DEBUG);
    return 0; 
    }
  unless(-d $DNA_LIB) { 
    warn "Missing DNA_LIB=$DNA_LIB" if ($DEBUG);
    ## return 0; # ok to miss?
    }
  
  my @cmd= ("java", $JAVA_FLAGS, "-cp", $JAVA_CP, $JAVA_APP,
    #($DEBUG ? "debug=1" : ""),
    "PROP_FILE=$PROP_FILE", 
    "INDEX_ROOT=$INDEX_ROOT",
    "LIB_NAME=$LIB_NAME",
    "'command=format native;arm:$arm AND (start:[$start $end] OR end:[$start $end])'"
    );
    
  if ($DEBUG) { print "<!-- ",join(", ",@cmd)," -->\n"; }
  my ($inspan,$indupheader,$ingenspan,$inscaf,$inresultset, $resultset);
  my $curscaf= $scafname;
  my $inbounds=1;
  
  my $nout=0;
  my $cmd=join(" ",@cmd);
  open(F, "$cmd |");  
  while(<F>) { 
    # need to rewrite span.start,end to be relative query start,end
    # for that need scaffold file start,end
    
    my $doccomment=0;
    ## this check for gbunit in native game xml doc streams not good enough
    ## lucene is returning doc parts from various scaffolds that match range quer
    ## but not all these have gbunit field for right scaffold; need to add from doc url/file ?
    ## ? or add xml-comment for this post-processing ?
    if (m,<type>gbunit</type>,) { $inscaf=1; }
    elsif (m,</property>,) { $inscaf=0; }
    elsif ($inscaf && m,<value>(\w+)</value>,) { 
      $curscaf=$1; $inscaf=0;
      my $trow= $scafhash{$curscaf};
      if (ref($trow) =~ /ARRAY/) {
        ($scafid, $scafstart, $scafend, $scafname, $scafarm) 
           = @$trow;
        print "<!-- game gbunit=$scafname, b=$scafstart -->\n" if ($DEBUG);
        }
      else {  print "<!-- game gbunit=$curscaf, NOT IN LIST -->\n" if ($DEBUG); }
      }
      
    elsif (m,<!-- docurl="([^"]+)" -->,) {  #? special case comment from lucegene
      # url:AE003800.game.xml,6717521-6857562 -- may have leading path prefix
      my $docurl=$1;  $doccomment=1;
      s,<!-- docurl=[^>]+>,,;  
      $curscaf = $1 if $docurl =~ m/(AE\d+)/;
      my $trow= $scafhash{$curscaf};
      if (ref($trow) =~ /ARRAY/) {
        ($scafid, $scafstart, $scafend, $scafname, $scafarm) 
           = @$trow;
        print "<!-- doc scaf=$scafname, b=$scafstart -->\n" if ($DEBUG);
        }
      else {  print "<!-- doc scaf=$curscaf, NOT IN LIST -->\n" if ($DEBUG); }
      ## ^^ this is seen for linked docs (no location?); should not be problem 
      ##  here as these have no location?
      }
       
       # quick fix to filter scaffold compuanal by location
       # check each resultset seq_relationship span
    elsif (m,<result_set,) { 
      $inresultset=1; $inbounds= 0; $resultset=''; 
      }
    elsif (m,</result_set,) { 
      print $resultset.$_ if($inbounds >= 0); 
      $inresultset=0; $resultset=''; $_='';
      }
      
       ## need $arm in this test, not just type="query" --
       ## NO - other type=query are genscan/genie with query span == scaffold loc
       #  <seq_relationship type="query" seq="2R">
    ##elsif (m,<seq_relationship type="query" seq="$arm",) { $ingenspan=1; }
    elsif (m,<seq_relationship type="query",) { $ingenspan=1; }
    elsif (m,</seq_relationship,) { $ingenspan=0; }
    elsif ($ingenspan && m,<(start|end)>([\d\-]+)<,) {
      my ($k,$v)=($1,$2);
      # my $absv= $v + $scafstart; my $v= $absv - $start; 
      $v = $v + $scafstart;  # make absolute (wish game did this)
      if ($v >= $start && $v <= $end) { $inbounds= 1; }
      elsif ($inbounds == 0) { $inbounds= -1; }
      $v = $v - $start;
      s,>([\d\-]+)<,>$v<,;
      }
      ## oct04; trap embedded docs that have duplicate top <?xml .. <game .. residues ..
    elsif (m,<.xml\s|<game>, && $nout>0) { 
      $indupheader=1; 
      }
      
    if ($inresultset) {
      $resultset .= $_; $_=''; 
      }
      
#    if (m,<game>|<.xml\s, && $nout>0) { $_=''; } # trap duplicate <game> tags
#<!-- docurl="AE003458.game.xml,0-356792" --> #<game>
# also trap 2nd: <?xml version="1.0" encoding="ISO-8859-1"?>
# -- need to do more - skip on past top of game header/seq
    if ($indupheader) { $_=''; }
    if ($indupheader && (m,</seq>, || $doccomment)) { #? <annotation|
      $indupheader=0; 
      }

    print ;
    
    # need to include <seq ...> <residues> ... for this range 
    if (m,<game>, && $nout==0) { printRawSeq($DNA_LIB, $arm,$start,$end); $nout++; }
    elsif (m,</game>,) { $nout++; last; } # and exit here to keep xml valid ?
    }  
  close(F);  
  return 0 unless($nout>0);
  return 1; 
}


=item

recreate this game.xml genome seq dump from gnomap/dna-chr.raw files

<game> -- range query output from PgChadoXort
  <seq id="2R:12431567-12572930" length="141363" focus="true">
    <name>2R:12431567-12572930</name>
    <residues> ... </residues>
  </seq>
  <map_position type="tile" seq="2R:12431567-12572930">
    <arm>2R</arm>
    <span>
      <start>12431568</start>
      <end>12572930</end>
    </span>
  </map_position>

  <seq id="2R" length="290783" focus="true">
    <name>2R</name>
    <residues>
        AATGACCAGAAAAATATTGCTGCTTTCAGTTTCGAAAAATTTTTCGATGG
        AAGCGGTTCTGTCAGCGGAAAAGTGAATTATACCAGAGCCTGCCTGAAAA
        ACTCAAGAAAACCCCATCAAAGAAATAGCAGCTCTCAGCTAAATAATAAC
        AAACACAATACTTTCTGCTCAGTCACCGCAAACAGAAATAATCACAATTC
        TGCAAAACGCCGTCATCAAAAAAGTTTTAGCCTACAACTCTAGAAACGCG
        GAAAAATTTGTCAAAAATACAACTAAAAAAACAACAACGCGAGTGCACGT
        GTATGTGAGGTGCTCAGTAAGAGTGTTTGCGTGTGTTCGTTTCTGTGTGT
        GACAGATAATAAAAGGAGAAAAAAAGAAGTTGTCGAAAGTCGTTCGTGAA
....
        AATTATTAAAACGAATTGTACTAATTTGTTTGG</residues>
  </seq>
  <map_position type="tile" seq="2R">
    <arm>$5</arm>
    <span>
      <start>12329218</start>
      <end>12620000</end>
    </span>
  </map_position>

=cut

sub printRawSeq {
  my ($DNA_LIB, $arm,$start,$end)= @_;
  
    # start+1 here?
  my $start1= $start + 1 ;
  my $name= $arm.":".$start1."-".$end; #"$arm:$start-$end";
  ## my $seqid= $arm; # this is what rest of game-xml scaf uses; 
  my $seqid= $name;
  ## but apollo devs want full name; will it confuse readers if not changed elswhere?
  print $outputComment if ($outputComment);
  
  my $len=($end-$start); # +1 ?? no, start is 0-based here
  my $t=1;
  print "\t"x$t,"<seq id=\"$seqid\" length=\"$len\" focus=\"true\">\n";
  $t++;
  print "\t"x$t,"<name>$name</name>\n";
  print "\t"x$t,"<organism>$organism</organism>\n";

  my $dnafile="$DNA_LIB/dna-$arm.raw";
  if (-f $dnafile) {
    open(DNA,$dnafile);
    seek(DNA,$start,0);  # start is 0-based here
    print "\t"x$t,"<residues>\n";
    $t++;
    my ($buf,$sz)=('',50); 
    for (my $i=0; $i<$len; $i+=50) {
      if ($sz+$i>=$len) { $sz= $len-$i; }
      read(DNA,$buf,$sz);
      print "\t"x$t,$buf,"\n";
      }
    $t--;
    print "\t"x$t,"</residues>\n";
    close(DNA);
    }
  $t--;
  print "\t"x$t,"</seq>\n";
  
  ##? start+1 fix here? for display only
  print qq(
  <map_position type="tile" seq="$seqid">
    <arm>$arm</arm>
    <span>
      <start>$start1</start>
      <end>$end</end>
    </span>
  </map_position>
);

}

=item FIXME genes spanning scaffs

# dumpGene: 
select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename, f2.uniquename  
from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2  
where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='gene'  
and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id 
and c2.name='chromosome_arm'  
and (f1.uniquename='CG15427' or f1.name='CG15427')

# openDb: db=chado_r3.2_18
# openDb: db_type=postgres
# openDb: host=localhost
# openDb: password=secret
# openDb: port=7302
# openDb: user=gilbertd
# result-0      1       4275719 4313817 CG15427 2L      


select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm  
from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl  
where f1.type_id=c1.cvterm_id 
 and c1.name='golden_path_region' and f1.feature_id=fl.feature_id   and f2.type_id=c2.cvterm_id 
 and c2.name='chromosome_arm'  and f2.feature_id=fl.srcfeature_id and f2.uniquename='2L'

 and fl.fmin <= 4250719 and fl.fmax >= 4338817
                        ^^^ this would be bad for spanning scaff
 -- instead swap min/max --
 and fl.fmin <= 4338817 and  fl.fmax >= 4250719
  
 feature_id | fmin | fmax | scaf | arm 
------------+------+------+------+-----
(0 rows)

 srcfeature_id |   fmin   |   fmax   | uniquename | uniquename 
---------------+----------+----------+------------+------------
             6 | 15120619 | 15135479 | CG9176     | X

select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm  
from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl  
where f1.type_id=c1.cvterm_id 
 and c1.name='golden_path_region' and f1.feature_id=fl.feature_id   and f2.type_id=c2.cvterm_id 
 and c2.name='chromosome_arm'  and f2.feature_id=fl.srcfeature_id and f2.uniquename='2L'
 and fl.fmin <= 15135479 and fl.fmax >= 15120619
 
#bad# and fl.fmin <= 15120619 and fl.fmax >= 15135479
 
 
 
Date: Thu, 8 Apr 2004 14:00:53 -0700
From: Nomi Harris <nomi@fruitfly.org>
To: gilbertd@bio.indiana.edu
Subject: Problem with chado2apollo.cgi queries for genes that span scaffolds

Hi Don,

Sima noticed that if you query chado2apollo.cgi for a gene that happens
to span more than one scaffold, it returns an error, e.g.

http://flybase.net/apollo-cgi/chado2apollo.cgi?gene=CG15427

returns

An error or no result occurred with this query: SQL query: select fl.srcfeature_id, fl
.fmin, fl.fmax, f1.uniquename, f2.uniquename from feature f1, featureloc fl, cvterm c1
, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id 
and c1.name='gene' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and 
c2.name='chromosome_arm' and (f1.uniquename='CG15427' or f1.name='CG15427') ; select f
l.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename as arm from featu
re f1, feature f2, cvterm c1, cvterm c2, featureloc fl where f1.type_id=c1.cvterm_id a
nd c1.name='golden_path_region' and f1.feature_id=fl.feature_id and f2.type_id=c2.cvte
rm_id and c2.name='chromosome_arm' and f2.feature_id=fl.srcfeature_id and f2.uniquenam
e='2L' and fl.fmin <= 4275719 and fl.fmax >= 4313817 ;

Can you look into this?  Here's the list of genes that span scaffolds:

CG15427  << no scaf
CG12673 << no scaf
CG9176  << no scaf
CG32705  << no scaf
CG33175
CG33484
CG31638
CG4551
CG7337 << no scaf
CG5799  

 srcfeature_id |  fmin   |  fmax   | uniquename | uniquename 
---------------+---------+---------+------------+------------
             1 | 1886648 | 1945481 | CG7337     | 2L

# result-0      1       4275719 4313817 CG15427 2L      
# lucegene search 2L:4250719,4338817
# scaffoldAtLoc: select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename a
s arm  from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl  where f1.type_id=c1.cv
term_id and c1.name='golden_path_region' and f1.feature_id=fl.feature_id   and f2.type_id=c2.cv
term_id and c2.name='chromosome_arm'  and f2.feature_id=fl.srcfeature_id and f2.uniquename='2L'
 and fl.fmin <= 4338817 and fl.fmax >= 4250719
# scaffoldAtLoc: results
# result-0      1177912 4023847 4311381 AE003577        2L      
# result-1      1166430 4311321 4603714 AE003576        2L      

# result-0      4       22053393        22160085        CG12673 3L      
# lucegene search 3L:22028393,22185085
# scaffoldAtLoc: select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename a
s arm  from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl  where f1.type_id=c1.cv
term_id and c1.name='golden_path_region' and f1.feature_id=fl.feature_id   and f2.type_id=c2.cv
term_id and c2.name='chromosome_arm'  and f2.feature_id=fl.srcfeature_id and f2.uniquename='3L'
 and fl.fmin <= 22185085 and fl.fmax >= 22028393
# scaffoldAtLoc: results
# result-0      1323181 21791981        22101002        AE003596        3L      
# result-1      1330377 22100942        22406554        AE003597        3L      


# result-0      6       15120619        15135479        CG9176  X       
# lucegene search X:15095619,15160479
# scaffoldAtLoc: select fl.feature_id, fl.fmin, fl.fmax, f1.uniquename as scaf, f2.uniquename a
s arm  from feature f1, feature f2, cvterm c1, cvterm c2, featureloc fl  where f1.type_id=c1.cv
term_id and c1.name='golden_path_region' and f1.feature_id=fl.feature_id   and f2.type_id=c2.cv
term_id and c2.name='chromosome_arm'  and f2.feature_id=fl.srcfeature_id and f2.uniquename='X' 
and fl.fmin <= 15160479 and fl.fmax >= 15095619
# scaffoldAtLoc: results
# result-0      643956  14794461        15135181        AE003498        X       
# result-1      652008  15135121        15436817        AE003499        X       
   -- check chado xml for scaf names 

=cut

__END__

dghome2% curl -L -i 'http://flybase.net/flybase-preview/apollo-cgi/chado2apollo.cgi'

HTTP/1.1 302 Found
Date: Fri, 12 Mar 2004 10:25:08 GMT
Server: Apache/1.3.29
Location: http://flybase.net:8081/flybase-preview/apollo-cgi/chado2apollo.cgi
Connection: close
Transfer-Encoding: chunked
Content-Type: text/html; charset=iso-8859-1

HTTP/1.1 302 Found
Date: Fri, 12 Mar 2004 10:25:08 GMT
Server: Apache/1.3.29
Location: http://bugbane.bio.indiana.edu:7092/apollo-cgi/chado2apollo.cgi
Connection: close
Transfer-Encoding: chunked
Content-Type: text/html; charset=iso-8859-1

HTTP/1.1 200 OK
Date: Fri, 12 Mar 2004 10:24:40 GMT
Server: Apache/1.3.26
Transfer-Encoding: chunked
Content-Type: text/html

<h1>Software error:</h1>
<pre>Chado database lookups (GAME.xml output)
You need to request one of these: 
  gene (e.g. ?gene=cact),
  scaffold accession (e.g. ?accession=AE003650),
  range (e.g. ?range=2L:300000-310000),
  cytological band (e.g. ?band=34A)
Use '&amp;scaffolds=1' option to get speedy access to data chunks.
Otherwise database exraction of chado/game xml objects can take many minutes!
Use '&amp;database=chado' option, or no database, for now.
The 'sequence=AGCT' lookup is not yet supported.
The 'next' and 'prev' options are not yet supported.
</pre>
<p>
For help, please send mail to the webmaster (<a href="mailto:flybase-ng@flybase.bio.indiana.edu">flybase-ng@flybase.bio.indiana.edu</a>), giving this error message 
and the time and date of the error.

</p>
