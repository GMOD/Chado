package Bio::GMOD::Bulkfiles::BlastWriter;
use strict;

=head1 NAME

  Bio::GMOD::Bulkfiles::BlastWriter  
  
=head1 SYNOPSIS
  
  use Bio::GMOD::Bulkfiles;       
  
  my $sequtil= Bio::GMOD::Bulkfiles->new( # was SeqUtil2
    configfile => 'seqdump-r4', 
    );
    
  my $fwriter= $sequtil->getBlastWriter(); 
    
  my $result= $fwriter->makeFiles( 
    infiles => [ @$fastafiles ], # required
    );
    
=head1 NOTES

  genomic sequence file utilities, part3;
  parts from 
    flybase/work.local/chado_r3_2_26/soft/blastdbupdate.pl
  
=head1 AUTHOR

D.G. Gilbert, 2004, gilbertd@indiana.edu

=head1 METHODS

=cut

#-----------------


# debug
#use lib("/bio/biodb/common/perl/lib", "/bio/biodb/common/system-local/perl/lib");

use POSIX;
use FileHandle;
use File::Spec::Functions qw/ catdir catfile /;
use File::Basename;

use Bio::GMOD::Bulkfiles::BulkWriter;       

use base qw(Bio::GMOD::Bulkfiles::BulkWriter);

our $DEBUG = 0;
my $VERSION = "1.1";
#my $configfile= "blastfiles"; #? BulkFiles/BlastWriter.xml 
use constant BULK_TYPE => 'blast';
use constant CONFIG_FILE => 'blastfiles';

use vars qw/ $formatdb  /;


sub init 
{
	my $self= shift;
  $self->SUPER::init();
  
  $DEBUG= $self->{debug} if defined $self->{debug};
  # $self->{bulktype} =  $self->BULK_TYPE; # dont need hash val?
  # $self->{configfile}= $self->CONFIG_FILE unless defined $self->{configfile};
  # $self->{failonerror}= 0 unless defined $self->{failonerror};
}



=item initData

initialize data from config

=cut

sub initData
{
  my($self)= @_;
  $self->SUPER::initData();
  
  my $config = $self->{config};
#   my $blastdir= $self->handler()->getReleaseSubdir( $self->{finfo}->{path} || 'blast/');
#   $self->{blastdir} = $blastdir;
  
  $config->{isprot_patt} ||= '(translation|aa_)';

  my $blasthome= $config->{blasthome} ; #|| "$oroot/common/servers/blast/Bin";
  $formatdb= $config->{formatdb} || "$blasthome/formatdb";
  unless(-e $formatdb) { 
    #? check ENV{NCBI} ? sys path ? BioPerl.. ?
    #formatdbpath = $self->findExecs('formatdb','blastall');
    warn "Missing formatdb: $formatdb";  # fail *Module*
    $self->status(-1,"missing formatdb"); 
    }
    
  my $formatdbopts= $config->{formatdbopts} || '-o F '; # T - True: Parse SeqId and create indexes. # -t Title
  $config->{formatdbopts}= $formatdbopts;
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

  print STDERR "BlastWriter::makeFiles\n" if $DEBUG; # debug
  my $fileset = $args{infiles};
  my $chromosomes = $args{chromosomes};
  unless(@$fileset) { 
    my $intype= $self->getconfig('informat') || 'fasta'; #? maybe array
    $fileset = $self->handler->getFiles($intype, $chromosomes);  
    unless(@$fileset) { 
      warn "BlastWriter: no input '$intype' files found\n"; 
      return $self->status(-1);  
      }
    }
 
  my @seqfiles= $self->openInput( $fileset );
  my $res= $self->processBlastInput( \@seqfiles);
  
  print STDERR "BlastWriter::makeFiles: done\n" if $DEBUG; 

  return $self->status($res); #what?
}

=item openInput( $fileset )

  handle input files
  
=cut

sub openInput
{
	my $self= shift;
  my( $fileset )= @_; # do per-csome/name
  my @files= ();
  my $inh= undef;
  return undef unless(ref $fileset);

  my $intype = $self->getconfig('informat') || 'fasta'; #? maybe array
  my $featset= $self->getconfig('blastset') || [];
  my @featset= @$featset;
    
  print STDERR "openInput: type=$intype blastset=",join(",",@featset),"\n" if $DEBUG; 
  
  foreach my $fs (@$fileset) {
    my $fp= $fs->{path};
    my $name= $fs->{name};
    my $type= $fs->{type}; 
    
    my ($featn,$format)= split /[\/]/, $type;
    next if( @featset && ! grep({$_ eq $featn} @featset) );
    
    my $ok= ( $type =~ /$intype/ && -e $fp) ;
    print STDERR "openInput: name=$name $featn, type=$type, ok=$ok\n" if $DEBUG;
    next unless $ok;  
    push(@files, $fp); # return full $fs struct w/ $featn ?
    }
    
  return @files;  
}


=item get_filename( $org, $chr, $featn, $rel, $format)

  make standard output file name "${org}_${chr}_${featn}_${rel}.${format}"
  
=cut

sub get_filename
{
  return shift->blastname(@_); ## {sequtil}->get_filename( @_);
}

sub split_filename
{
	my $self= shift;
	my ($fname)= @_;
  my $fndel= $self->getconfig('filepart_delimiter') || '-';
  my @v= split(/$fndel/, $fname, 4); 
  if (@v == 2) {  splice(@v, 1, 0, 'all'); $fname= join($fndel,@v); } #OR# return ( $v[0], "all", $v[1], "", "");
  ## created name w/o -all- chr; fails split
  ##  my $blname= $self->handler->get_filename($org,'',$featn,'',$format);
  return $self->handler()->split_filename( $fname );
}

sub blastname {
	my $self= shift;
  my($dbname)= @_;
  if ($dbname =~ s/(\d[\d\.]*\.\d)/ZYX/) { 
    my $r=$1; $r=~s/\.//g; $dbname =~ s/ZYX/$r/; 
    }
  # squeeze r3.2.1 to r321
  $dbname =~ s/\..*$//;  # drop .fasta.gz etc.
  return $dbname;
}


=item processBlastInput


=cut

sub processBlastInput
{
	my $self= shift;
  my( $rseqfiles )=  @_;
  
  my $blastdir= $self->outputpath();
  my ($doformat, $doconfig)= (1,1);
  my $ndone= 0;
  
  # format only if changed...
  $self->updateformat(  $blastdir, $rseqfiles) if ($doformat);
  
  my @blastfiles=();
  opendir(D, $blastdir);
  @blastfiles= grep(/^\w/,readdir(D));
  closedir(D);
  
  if ($doconfig) {
    my %dbinfo= $self->getDbDirInfoByTitle( $blastdir, \@blastfiles);
    $self->update_blastrc( $blastdir, \@blastfiles);
    $self->update_dbselect( \%dbinfo);
    $self->update_dbhtml( \%dbinfo);
    }

  $ndone= scalar( @blastfiles);
  print STDERR "processBlastInput ndone = $ndone\n" if $DEBUG;
  return $ndone;
}



#-------------
# parts from  flybase/work.local/chado_r3_2_26/soft/blastdbupdate.pl
#-------------

sub update_blastrc 
{
	my $self= shift;
	my($path, $rdir)= @_;
  my $rcdoc= $self->config->{'doc'}->{dbrc};
	my @dir= @$rdir;

	warn "update_blastrc()\n" if $DEBUG;

  my $nalist= join " ", map{ $self->blastname($_) } grep(/\.(nhr|nal)$/,@dir);    
  my $aalist= join " ", map{ $self->blastname($_) } grep(/\.(phr|pal)$/,@dir);    
 
  my @rc= split "\n",$rcdoc->{content};
  push(@rc, qw/blastn blastp blastx tblastn tblastx/) unless(@rc);
  foreach (@rc) {
    s/^blastn.*$/blastn $nalist/;
    s/^tblastn.*$/tblastn $nalist/;
    s/^tblastx.*$/tblastx $nalist/;
    s/^blastp.*$/blastp $aalist/;
    s/^blastx.*$/blastx $aalist/;
    }
  $rcdoc->{content}= join("\n", @rc);
  $rcdoc->{id}= 'dbrc';
  $self->handler()->writeDocs( $rcdoc );
}



sub getDbInfo
{
	my $self= shift;
	my ( $dbhash, $path, $blastfile)= @_;
  my $blname = $self->blastname($blastfile);
  ## >> creates name w/o -all- chr; fails split
  ##  my $blname= $self->handler->get_filename($org,'',$featn,'',$format);
  my ( $org, $chr, $featn, $rel, $format)= $self->split_filename($blname);

  my $db= $dbhash->{$featn}; # probably this
  unless($db) { $db= $dbhash->{$blname}; }
  unless($db) { (my $bl2= $blname) =~s/_r\d+.*//; $db= $dbhash->{$bl2}; } # w/o version
  unless($db) {  
    my $isprot_patt = $self->config->{isprot_patt};
    my $doprot= ($blname =~ m/$isprot_patt/) ? 1 : 0;
    my $tt= (($chr eq 'all') ? "All" : $chr) . " $org $featn " . (($doprot) ? "(AA)" : "(NT)");
    $db= { name => $blname, title => $tt, content => "", };  
    }

  my $ftime= $^T - 24*60*60*(-M $blastfile);
  $db->{date}= POSIX::strftime("%d-%b-%Y", localtime( $ftime ));

  $db->{blname}= $blname;
  $db->{files} = $blname;
  my ($files);
  ## FIXME need to write .nal, .pal from config?
  if (-r "$path/$blname.nal") { open(BL,"$blname.nal");  ($files)=grep(/DBLIST/,<BL>); close(BL);}
  elsif (-r "$path/$blname.pal") { open(BL,"$blname.pal");  ($files)=grep(/DBLIST/,<BL>); close(BL);}
  if ($files) {
    $files =~ s/\s*DBLIST\s*//;
    $db->{files}= $files;
    }
  return $db;
}

sub getDbDirInfoByTitle
{
	my $self= shift;
	my($path, $dirlist)= @_;

  my $dbhash= $self->config->{blastdb};
  my @blf= grep(/\.(nhr|phr|nal|pal)$/, @$dirlist);
  my %dbh=();
  foreach my $blf (@blf) {
    my $db= $self->getDbInfo($dbhash, $path, $blf);
    next if ($db->{skip});
    
    my $title= $db->{title};
    $dbh{$title}= $db;
    }
  return %dbh;  
}

sub update_dbhtml
{
	my $self= shift;
	my($dbh)= @_;
	warn "update_dbhtml\n" if $DEBUG;
    
  my $dbtable= $self->config->{doc}->{dbtable};
  my $content= $dbtable->{header}->{content} || '<html><body><table> ';
  $content  .= $dbtable->{tableheader}->{content} || "<tr bgcolor='#a0a0a0'>
    <td color='white'>Pull-down Menu</td>
    <td color='white'>Database file</td>
    <td color='white'>Update</td>
    <td color='white'>Description</td>
    </tr>\n";
  foreach my $title (sort keys %$dbh) {
    my $db = $dbh->{$title};
    $content .=  "<tr>
    <th>$title</th>
    <th>$db->{files}</th>
    <th>$db->{date}</th>
    <th>$db->{content}</th>
    </tr>\n";
    }
  $content .= $dbtable->{footer}->{content} || ' </table></body></html>';
  $dbtable->{content}= $content;
  $dbtable->{dbtable}= 'dbrc';
  $self->handler()->writeDocs(  $dbtable );
}


sub update_dbselect 
{
	my $self= shift;
	my($dbh)= @_;
	warn "update_dbselect \n" if $DEBUG;
	
  my $dbselect= $self->config->{doc}->{dbselect};
  my $content= $dbselect->{header}->{content} || '';
  $content .= "<select name = \"DATALIB\">\n";
  foreach my $title (sort keys %$dbh) {
    my $db = $dbh->{$title};
    $content .=  " <option VALUE = \"$db->{blname}\"> $title\n";
    }
  $content .= "</select>\n";
  $content .= $dbselect->{footer}->{content} || '';
  $dbselect->{id}= 'dbselect';
  $dbselect->{content}= $content;
  $self->handler()->writeDocs( $dbselect );
}


sub updateformat 
{
	my $self= shift;
  # my($path, $rdir)= @_;
  my ( $blastdir, $datafiles)= @_;
  my  $isprot_patt = $self->config->{isprot_patt};

  my @fastafiles= @$datafiles; ##grep(/\.(gz|Z|fa|fasta)$/, @$datafiles); #? or assume all @files are fasta?
	my %dbset= ();
	
	warn "update formatdb \n" if $DEBUG;
  ## FIXME: input fasta == $org_$chr_$feature_$release
  ## >> cat all $org_{1..n}_feature into one blastdb
  my %alldata=();
  
  foreach my $fa (@fastafiles) {

    my ( $org, $chr, $featn, $rel, $format)= $self->split_filename($fa);

      ## keep release  in blast db name -- ???
      ## check here if have 'all' $chr input, if so skip any other $chr in same set
      ## nov04 - drop release to avoid hassles w/ updates needed all blast config
      ##  to be regenerated -- also leave out 'all'
      
    ##my $blrel=''; #= $rel;  
    ##my $blname= $self->handler->get_filename($org,'all',$featn,$blrel,$format);
    my $blname= $self->handler->get_filename($org,'',$featn,'',$format);
    $blname= $self->blastname($blname);
    $alldata{$blname}= $fa if ($chr eq 'all');
    
    ##my ($sfile, $spath, $ext) = File::Basename::fileparse($fa, '\.[^\.]+');
    ##my $blname = $self->blastname($sfile);
    
    my $blf = $blname . '.nhr';
    unless (-e "$blastdir/$blf") { $blf=  $blname . '.phr'; }
    # $_='' unless ($self->isold( $_, "$blastdir/$blf"));
    # skip current indices
    if ($self->isold( $fa, "$blastdir/$blf")) {
      unless($dbset{$blname}) { $dbset{$blname}= []; }
      push( @{$dbset{$blname}}, $fa);
      }
    }
  warn "BlastWriter: Missing $formatdb" and return -1 unless(-e $formatdb);
  foreach my $blname (keys %dbset) {
    my $doprot= ($blname =~ m/$isprot_patt/) ? 1 : 0;
    my $seqlist= $dbset{$blname};
    if ($alldata{$blname}) { $seqlist= [ $alldata{$blname} ]; }
    $self->formatdb_list( $seqlist, $blastdir, $blname, $doprot); # may chdir  
    }
  
#   foreach my $db (@dbs) {
#     next unless($db && -e $db);
#     my $doprot= ($db =~ m/$isprot_patt/) ? 1 : 0;
#     $self->formatdb($db, $blastdir, $doprot); # may chdir  
#     }

}


sub formatdb_list 
{
	my $self= shift;
	my( $seqlist, $blastdir, $blastname,  $doprot)= @_;
	warn "formatdb( $blastname )\n" if $DEBUG;
	my $opts= $self->getconfig('formatdbopts'); ##$formatdbopts;  
	if ($doprot) { $opts .= ' -p T ';} else { $opts .= ' -p F '; }

  warn("#$blastname:  cat ",join(" ",@$seqlist)," | $formatdb $opts -i stdin \n") if $DEBUG;
	my $olddir= $ENV{'PWD'};  #?? not safe?
  chdir($blastdir); # need for formatdb - no good -out option
  
  foreach (@$seqlist) {
    $_ = catfile($olddir,$_) unless($_ =~ m,^/,);
    }
  my $seqlib = join(" ",@$seqlist);
  my $cat= ($seqlib =~ /\.(gz|Z)/) ? 'gunzip -c' : 'cat';
    
  system("$cat $seqlib | $formatdb $opts -i stdin ");
  opendir(D,"."); my @f= grep(/stdin/,readdir(D)); closedir(D);
  foreach my $f (@f) { (my $t= $f) =~ s/stdin/$blastname/; rename($f,$t); }

  chdir($olddir);
}


sub formatdb 
{
	my $self= shift;
	my($seqlib, $blastdir, $doprot)= @_;
	warn "formatdb($seqlib)\n" if $DEBUG;
  warn "BlastWriter: Missing $formatdb" and return -1 unless(-e $formatdb);
	my $opts= $self->getconfig('formatdbopts'); ##$formatdbopts;  
	if ($doprot) { $opts .= ' -p T ';} else { $opts .= ' -p F '; }

  my ($sfile, $spath, $ext) = File::Basename::fileparse($seqlib, '\.[^\.]+');
  my $blastname = $self->blastname($sfile);
	
	my $olddir= $ENV{'PWD'}; #???
  chdir($blastdir); # need for formatdb - no good -out option
  my $cat= ($seqlib =~ /\.(gz|Z)$/) ? 'gunzip -c' : 'cat';
  $seqlib = catfile($olddir,$seqlib) unless($seqlib =~ m,^/,);
  warn("$cat $seqlib | $formatdb $opts -i stdin \n") if $DEBUG;
  system("$cat $seqlib | $formatdb $opts -i stdin ");
  
  opendir(D,"."); my @f= grep(/stdin/,readdir(D)); closedir(D);
  foreach my $f (@f) { (my $t= $f) =~ s/stdin/$blastname/; rename($f,$t); }

  chdir($olddir);
}


1;

__END__

