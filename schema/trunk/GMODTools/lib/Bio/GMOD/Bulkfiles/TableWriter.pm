package Bio::GMOD::Bulkfiles::TableWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::TableWriter  
  writes summary tables of genome database features
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $bulkf= Bio::GMOD::Bulkfiles->new(  
    configfile => 'seqdump-r4', 
    );
  my $fwriter= $bulkf->getWriter('tables'); 
  my $result = $fwriter->makeFiles();
    

  
=head1 AUTHOR

D.G. Gilbert, 2005, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

use Bio::GMOD::Bulkfiles::BulkWriter;       
use base qw(Bio::GMOD::Bulkfiles::BulkWriter);

use constant RECSIZE => length(pack("NN", 1, 50000));

our $DEBUG = 0;
my $VERSION = "1.0";

use constant BULK_TYPE => 'tables';
use constant CONFIG_FILE => 'tablewriter';

my $kMissingValue= -99999999;
my $kMaxValue= 999999999;
my $kMinValue= $kMissingValue+1;

use vars qw/ $noIDmap $nameIsId $nameIsSpeciesId $cutdbpattern $indexidtype $indexidpattern /;


sub init 
{
	my $self= shift;
  $self->SUPER::init();
  
  ## superclass does these??
  $DEBUG= $self->{debug} if defined $self->{debug};
  # $self->{bulktype} =  $self->BULK_TYPE; # dont need hash val?
  # $self->{configfile}= $self->CONFIG_FILE unless defined $self->{configfile};
}



=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  
  my $reldate= $self->handler()->config->{relfull} || $self->handler()->{date};
  $self->{reldate} = $reldate;
  
#   my $config = $self->{config};
#   my $finfo= $self->{fileinfo} || $self->handler()->getFilesetInfo($self->BULK_TYPE);
#   my $outdir= $self->handler()->getReleaseSubdir( $finfo->{path} || $self->BULK_TYPE);
#   $self->{outdir} = $config->{outdir}= $outdir;
  
  #$self->{summaryfile}= catfile( $self->outputpath(), "feature_map-summary.txt"); 

}


#-------------- subs -------------

=item  makeFiles( %args )

  primary method
  makes  blast indices.
  input file sets are intermediate chado db dump tables.
  
  arguments: 
  infiles => \@fileset,   # required

=cut

sub makeFiles
{
	my $self= shift;
  my %args= @_;  

  my $targets= $self->config->{target};
  my %targets= map{ $_ => 1 } @$targets;
  ## ^^ see Bulkfiles->getDumpFiles()
  ## may want to use this: 
  ##   my $seqsql = handler()->getSeqSql($fdump->{config},$fdump->{ENV});

  print STDERR "TableWriter::makeFiles\n" if $DEBUG; # debug
  my $fileset = $args{infiles};
  my $chromosomes = $args{chromosomes}; #??
  
  unless(@$fileset) { 
    my $intype= $self->config->{informat} || ['fff']; #? maybe array
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    unless(@$fileset) { 
      warn "TableWriter: no input '$intype' files found\n"; 
      return $self->status(-1);  
      }
    }

  #js needs: var csomes= ["X","2L","2R","3L","3R","4"];
  my $chrlist="";
  $chromosomes= $self->handler->getChromosomes(); # want all, not subset ??
  foreach my $chr (@$chromosomes) { $chrlist .= "'$chr', "; }
  $ENV{'chromosomes'}= $chrlist;
 
  $self->readFFF($fileset); # collate feature info
  
  ## chromosome_summary ; do this before in Bulkfiles with others?
  ## this file is named in chadosql entry - fixme
  my $cfile= catfile( $self->outputpath(), "chromosomes-overview.txt"); 
  $self->chromosomeSummary( $cfile, $chromosomes); # always?
    delete $targets{'chromosome_summary'};
  
  ## if doFeatSum  
  my $summaryfile= catfile( $self->outputpath(), "feature_map-summary.txt"); 
  $self->featureSummary( $summaryfile, $self->{featnames})
    if(delete $targets{'feature_map'});

  my @featnames= ();
  if ($self->{featnames}->{all}) { @featnames= sort keys %{$self->{featnames}->{all}}; }
  $self->makeGbrowseConf('gbrowse_conf',\@featnames) # should pass array of feature names !
    if(delete $targets{'gbrowse_conf'});

  if(delete $targets{'overviewhtml'}) {
    my $overviewset  = $self->handler->getFilesetInfo('overview');
    $self->table2html($overviewset);
    }
  
  # handle other targets: id_table; ortho_table; ... using getSeqSql ?
  foreach my $trg (@$targets) {
    if($targets{$trg}) {
      my $fset= $self->handler->getFilesetInfo($trg);
      unless($fset) { warn "TableWriter: No handler for target=$trg\n"; next; }
      # $fset->{path};
      # $fset->{config}; << look for docs to write
      # $fset->{handler}; << see handler()->getWriter($fset->{handler})
      $self->writeTargetDocs($trg,$fset);
      }
    }
  
  print STDERR "TableWriter::makeFiles: done\n" if $DEBUG; 
  return  $self->status(1);
}

sub table2html {
	my $self= shift;
  my( $fsetinfo )= @_; # do per-csome/name

  my $sqlconf = $fsetinfo->{config};
  my $seqsql  = $self->handler->getSeqSql($sqlconf);

  my $outpath= $self->handler->getReleaseSubdir( $fsetinfo->{path} || $self->BULK_TYPE);
  ## $fsetinfo->{'path'}= $outpath; # save for reuse

  my $sqltag  =  $fsetinfo->{tag} || "feature_sql";
  my $sqltype =  $fsetinfo->{type};
  my $targets =  $fsetinfo->{target}; # should be array ?
  unless($targets) { my @tg= sort keys %{$seqsql->{$sqltag}}; $targets= \@tg; }
  unless(ref $targets) { $targets= [ $targets ]; }
  ##print STDERR "TableWriter::table2html: $sqltype $fsetinfo->{config}\n" if $DEBUG; 
  
  foreach my $sname (@$targets) 
  {
    my $fs= $seqsql->{$sqltag}->{$sname};
    unless($fs) { next; } ## FIXME for chromosome_summary
    my $type= $fs->{type};
    my $outn= $fs->{output} || $sname.".txt";
    #?? unless( (!$sqltype || $type =~ m/\b$sqltype\b/)) { next; } #??

    my $outf= catfile($outpath,$outn);
    print STDERR "TableWriter::table2html: $sname, $type, $outf\n" if $DEBUG; 
    if (-e $outf) {
      my $int;
      (my $outh= $outf) =~ s/\.txt$//; 
      $outh .= ".html";
      open(T,$outf); open(H,">$outh");
      print H "<html>\n<title>$sname</title>\n<body>\n";
      while(<T>){
        chomp;
        my @r= split"\t";
        if (@r>1) {
          $int++;
          if($int==1) {
            print H "<table cellpadding='4' border='1'>\n";
            print H "<tr><th>",join("</th><th>",@r),"</th></tr>\n";
            }
          else {
            print H "<tr><td>",join("</td><td>",@r),"</td></tr>\n";
            }
          }
        else {
          print H "</table>" if($int); $int= 0;
          print H "$_<br>\n";
          }
      }
      print H "</body></html>\n";
      close(H); close(T);
      }
  }


}

sub readFFF
{
	my $self= shift;
  my( $fileset )= @_; # do per-csome/name
  my $intype =   'fff';  
  my $outdir= $self->outputpath();
  $self->{featnames}= {};  ## feature summary; add ave; std of feat.length; other stats ?
  print STDERR "readFFF\n" if $DEBUG; 

  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type};  
    my $chr= $fs->{chr};  
    next unless( $fs->{type} =~ /$intype/);  
    unless(-e $fp) { warn "missing $intype file $fp"; next; }
    
    if ($fp =~ m/\.(gz|Z)$/) { open(FF,"gunzip -c $fp|"); }
    else { open(FF,"$fp"); }

    my $ffformat = 0; #? test always; probably is 2
    while(<FF>){
      if (/^\w/ && /\t/) {  
        my @v= split(/\t/); # split /\t/, $_;
        ## format 2 standard now; chrname sort-location featname ...
        if ( $ffformat == 2 || @v > 7 || ($v[0] =~ /^\w/ && $v[1] =~ /^[\d-]+$/)) { 
          $ffformat= 2;
          splice(@v,0,2); 
          }
        my $fname= $v[0];
        $self->{featnames}->{all}->{$fname}++; # save for summary && gbrowse...
        $self->{featnames}->{$chr}->{$fname}++;  
        
        ## keep running mean length ?
        ## my $loc = $v[xxx];  $loc=$self->maxrange($loc); $size= $loc[1-0]..
        ## $runave += $size; $runsd += (sq($size) - xxx); $runn++;
        }
      }
    close(FF);  
    }
    
}

sub writeTargetDocs
{
	my $self= shift;
  my( $targetid, $filesetinfo, $csomefeats )= @_; 
  
  my $configfile= $filesetinfo->{config} || "";
  warn "TableWriter: target=$targetid, config=$configfile\n" if $DEBUG;
  return unless($configfile);
  
  my $tconfig= $self->handler->callReadConfig( $configfile); 

  ## need some fix to writeDocs for doc->path at top level or not-releasedir
  my $docs  = $tconfig->{doc};
  $self->handler()->writeDocs( $docs ) if ($docs);
}

sub chromosomeSummary 
{
	my $self= shift;
  my( $sumfile, $csomelist )= @_; 
  ## chromosome_summary ; do this before in Bulkfiles with others?
  my $ctab= $self->handler->getChromosomeTable();

  my $fh= new FileHandle(">$sumfile");
  my $title = $self->config->{title};
  my $date  = $self->{reldate}; 
  my $org= $self->{org} || $self->handler()->{config}->{org};

  ## Name and ID ?? # make it gff or not? : Source, Attribs
  my @flds= qw(Ref Feature_type Start Length Rank ID Feature_id Species);

  print $fh "# Chromosomes of $org from $title [$date]\n";
  print $fh join("\t",@flds),"\n";
  foreach my $chr (@$csomelist) { #? or use keys of $ctab 
    my $cv= $ctab->{$chr};
    if(!ref $cv) { next; }  #what? print something?
    print $fh join("\t",
      $cv->{arm}, $cv->{type}, 
      $cv->{start}, $cv->{length}, #fmax - fmin + 1
      $cv->{strand}, #== Rank
      $cv->{id}, $cv->{oid}, $cv->{species}, ),"\n";
    my $cparts= $ctab->{$chr}->{parts};
    if (ref $cparts) {
      foreach $cv (@$cparts) {
        print $fh join("\t",
          $cv->{arm}, $cv->{type}, 
          $cv->{start}, $cv->{length}, #fmax - fmin + 1
          $cv->{strand}, #== Rank
          $cv->{id}, $cv->{oid}, $cv->{species}, ),"\n";
        }
      }
   }
  close($fh);
}




sub featureSummary 
{
	my $self= shift;
  my( $sumfile, $csomefeats )= @_; 
  if ( $sumfile && $csomefeats ) {
    my $fh= new FileHandle(">$sumfile");
    my $title = $self->config->{title};
    my $date  = $self->{reldate}; 
    # $date= $self->handler()->config->{relfull} || $self->handler()->{date};
    # $date= $ENV{date} || $self->handler()->{date};

    ##my $org   = $self->{config}->{species} || $self->{config}->{org};
    my $org= $self->{org} || $self->handler()->{config}->{org};
    print $fh "# Genome feature summary of $org from $title [$date]\n";
    my @fl= grep { 'all' ne $_ } sort keys %$csomefeats;
    foreach my $arm ('all', @fl) {
      print $fh (($arm eq 'all') ? "\n# ALL chromosomes\n" : "\n# Chromosome $arm\n");
      foreach my $t (sort keys %{$csomefeats->{$arm}}) {
        my $v= $csomefeats->{$arm}{$t};
        print  $fh "$t\t$v\n";
        }
      print $fh "#","="x50,"\n";
      }  
    close($fh);
    }
}

sub makeGbrowseConf
{
	my $self= shift;
	my($targetid,$featnames)= @_;
	
	warn "makeGbrowseConf $targetid\n" if $DEBUG;

  ## need active feature set from ? feature-summary.txt or fff/ files
  
	my $config={}; # stuff with $self->handler->config && others
	$config= { %{$self->handler->{config}} }; # copy it
  my $gbset= $self->handler->getFilesetInfo($targetid); #('gbrowse_conf');
  my $gbrowseconf= $gbset->{config} || $self->getconfig($targetid);
  
  # add vars to config
  my $outdir= $self->outputpath();
  $config->{outputpath}= $outdir;

  my @dbconf= qw(db_adaptor_class db_adaptor db_dsn db_user db_password);
  foreach my $dbk (@dbconf) {
    $config->{$dbk}= $gbset->{$dbk} || $self->getconfig($dbk);
    }
  if ($config->{db_adaptor_class} =~ /Chado/) {
    my ($chadodsn,$dbuser,$dbpass)= $self->handler->dbiDSN();
    $config->{db_dsn}= $chadodsn;
    $config->{db_user}= $dbuser;
    $config->{db_password}= $dbpass;
   }
    
  my ($loc, $ex)= ('','');
  my $chromosomes= $self->handler->getChromosomes(); 
  foreach my $chr (@$chromosomes) {
     $loc= "$chr:1..100000" unless($loc);
     $ex .= "$chr ";
     }
  $config->{ default_location } = $loc;
  $config->{ examples } = $ex;
  
  my $config2= $self->handler->{config2}; 
  my $gbconf= $config2->readConfig( $gbrowseconf, 
    { Variables => $config, debug => $DEBUG,  }, {} );
#   my $gbxml= $config2->showConfig( $gbconf, { debug => 0 });  
#   if ( $gbxml =~ m/\$\{/ && ref($gbconf->{ENV_default}) ) {
#     my %env= %{$gbconf->{ENV_default}};
#     foreach my $k (keys %env) { $env{$k}= $config->{$k} if($config->{$k}); }
#     $gbconf= $config2->readConfig( $gbrowseconf, {Variables => \%env}, {} ); 
#     }
  print STDERR $config2->showConfig( $gbconf, { debug => $DEBUG })
    if ($self->{showconfig});       
	
  my $doc  = $gbconf->{doc}->{gbrowse};
  my $fdefs= $gbconf->{fdef};
  my $content= $doc->{header}->{content} || '';

  my @featnames=();
  @featnames= @$featnames if (ref $featnames);
  @featnames= sort keys %$fdefs unless(@featnames);
  
  foreach my $fname (@featnames) {
    my $fd = $fdefs->{$fname};
    unless( $fd ) {
      # next; # check all hash {feature} strings for match...
      $fd = $fdefs->{GENERIC};
      my $gct= $fd->{content};
      $gct =~ s/GENERIC/$fname/sg;
      $fd= { name => $fname, content => $gct };
      }
    next if ($fd->{done});
    my $morefeats= $fd->{feature};
    my $ct= $fd->{content};
    $content .=  $ct."\n";
    $fd->{done}=1;
    }
    
  $content .= $doc->{footer}->{content} || '';
  $doc->{content}= $content;
  $doc->{path}= $gbset->{path} if $gbset->{path};   
  $self->handler()->writeDocs( $doc );
}


# =item openInput( $fileset )
# 
#   handle input files
#   
# =cut
# 
# sub openInput
# {
# 	my $self= shift;
#   my( $fileset )= @_; # do per-csome/name
#   my @files= ();
#   my $inh= undef;
#   return undef unless(ref $fileset);
# 
#   my $intype = $self->config->{informat} || 'fff'; #? maybe array
#   my $featset= $self->config->{featset} || [];
#     
#   print STDERR "openInput: type=$intype \n" if $DEBUG; 
#   
#   foreach my $fs (@$fileset) {
#     my $fp= $fs->{path};
#     my $name= $fs->{name};
#     my $type= $fs->{type}; # want also/instead featset type here ? gene,mrna,cds,...
#     next unless( $fs->{type} =~ /$intype/); # could it be 'dna/fasta', 'amino/fasta' ?
#     unless(-e $fp) { warn "missing intype file $fp"; next; }
# 
#     push(@files, $fp);
#     }
#     
#   return @files;  
# }



=item processToOutput


=cut

sub processToOutput
{
	my $self= shift;
  my( $rseqfiles )=  @_;
  

}





sub maxrange {
	my $self= shift;
	my( $range)= @_;
	my ($pre, $suf,$start,$stop, $b, $u);
	$start= $kMissingValue; $stop= $start;
	
	$range =~ s/^([^\d<>-]*)//; $pre= $1;
	$range =~ s/(\D*)$//;  $suf= $1;
	if ($range =~ m/^([<>]*)([\d-]+)/) { $u= $1; $start= $2; $start-- if ($u eq '<'); }
	if ($range =~ m/([<>]*)([\d-]+)$/) { $u= $1; $stop= $2; $stop++ if ($u eq '>'); }
	return ($start,$stop);
}



=item FIXME : id_table ??

sub makeAllIdmaps 
{
	my $self= shift;
  my( $file, $fin, $dir, $csome, $idfh)= @_;
  my ($nd)=(0); my %didid=();
  my $indexidpattern='^[A-Za-z]{2,}';  
  my $indexdbpattern='^[A-Za-z]{2,}';  # FIXME - config
  #die "Can't read $file" unless (open(FIN,$file));
  # my $org   = ucfirst( $self->{config}->{org} || 'Any');
  my $org= $self->{org} || $self->handler()->{config}->{org};
  $org=  'Any' unless($org);
  # fixme for ortholog to_name in $notes
  my($nte,$ste,$ite);

	# warn "makeAllIdmaps: noIdmap.classes='$noIDmap' \n" if $DEBUG;

  while(<$fin>) {
    my ($class,$sym,$map,$range,$idv,$dbx,$notes)= split(/\t/);
    $nte++ if ($class =~/transposable_element/); #DEBUG
    next unless( $range && $range ne '-' );
    next if ($class =~ /$noIDmap/i); ## ?? drop or keep
    
    my @ids= (split(/[,;\s]/,$idv),split(/[,;\s]/,$dbx));  
    if ($class =~ /$nameIsId/) { # fixme for fff output - put in ID field
      $sym =~ s/\-hit$//; # bad BAC names
      unshift(@ids,$sym);
      }
    elsif ($class =~ /$nameIsSpeciesId/) {  
      $sym = "$org\\$sym" unless($sym =~ m,\\,);  
      unshift(@ids,$sym);
      }
    elsif ($notes && $notes =~ /to_name=([^;,\s]+)/ ) {  
      ## added to_name=name, id << keep id?
      my $tosym = $1; $tosym =~ s/\-\w\w$//; # drop prot suffix
      my $toorg = ($notes =~ /to_species=([^;,\s]+)/) ? $1 : $org;
      unshift(@ids,ucfirst($toorg).'\\'.$tosym);
      }
      
      # feb05: getting lots of useless idmap-xxx.tsv for things like
      # polyA_site with symbol name as id/name 
      # gbb-polyA_site-1, Delta88{}su(s)[28] , 
      
    my $needid=1;
    IDINDEX:
    while ($needid && (my $tid = shift @ids)) {
      next if ($tid eq '-');
      
      $ite++ if ($tid =~/FBti/); #DEBUG
      my $db='';
      if ($tid =~ s/$cutdbpattern//i) { $db= $1; } 
      next unless ($db =~ /$indexdbpattern/ || $tid =~ /$indexidpattern/);
      
      my($start, $stop)= $self->maxrange($range);  
      my $idkey="$tid.$csome.$start";
      next if ($didid{$idkey});

      $ste++ if ($tid =~/FBti/); #DEBUG
      my $idf= 'idmap-all.tsv';
      if ( $tid =~ m/^([A-Za-z]+)/ ) { $idf= "idmap-$1.tsv"; }
      my $fh= $idfh->{$idf};
      unless($fh) { 		
        my $sfile= catfile($dir, $idf);
        $fh= new FileHandle(">$sfile"); $idfh->{$idf}= $fh; 
        }
      if ($fh) {
        print $fh "$tid\t$csome\t$start\t$stop\n"; $nd++;
        $didid{$idkey}++;
        }  
      }
  }
  #close(FIN);
  return "makeAllIdmaps n=$nd\n";
}

=cut



1;

__END__

