package Bio::FeatureIO::chadobulk;

use strict;
use base qw(Bio::FeatureIO);

use Bio::SeqIO;
use DBI;
use Data::Dumper;

my @TABLES = qw(db dbxref cvterm synonym feature featureloc
                 featureprop feature_cvterm feature_dbxref
                 feature_relationship feature_synonym
                );
#don't need contact,  obj already handed to us
#don't need organism, obj already handed to us
#don't need pub,      obj already handed to us



sub _initialize {
  my($self,%arg) = @_;
  $self->SUPER::_initialize(%arg);

  $self->organism($arg{-organism});
  $self->contact($arg{-contact});
  $self->pub($arg{-pub});

  $self->dbh(DBI->connect('dbi:Pg:host=soleus;dbname=chado_bulktest','allenday',''));
  $self->setup();
}

sub next_feature {
  shift->throw('this class only writes to database');
}

sub write_feature {
  my($self,$feature) = @_;

  my $dbxref_id   = "\\N";

  my $organism_id = 1; #FIXME
#  my $organism_id = $self->organism->id;

  my @names = map {$_->value} $feature->annotation->get_Annotations('Name');
  my $name = $names[0] || '\\N';
  if(scalar(@names) > 1){
    $self->throw('feature can only have one name, but had: '.join(' ',@names));
  }

  my @unames = map {$_->value} $feature->annotation->get_Annotations('ID');
  my $uname = $unames[0] || $feature->seq_id.':'.$feature->start.','.$feature->end;
  if(scalar(@unames) > 1){
    $self->throw('feature can only have one ID, but had: '.join(' ',@unames));
  }

  my @types = map { $self->cvterm($_->name) } $feature->annotation->get_Annotations('feature_type');
  my $type = $types[0];
  if(scalar(@types) > 1){
    $self->throw('feature can only have one type, but had: '.join(' ',@types));
  }
  $self->throw("$feature has undefined feature_type, bailing out") unless $type;

  my $feature_fh = $self->file('feature');
  my $feature_id = $self->seq('feature');

  my $is_analysis = 'F';

  print $feature_fh join("\t",$feature_id,$dbxref_id,$organism_id,$name,$uname,'\\N','\\N','\\N',$type,$is_analysis,$self->now,$self->now),"\n";
}

sub DESTROY {
  my $self = shift;
  $self->bulkload();
  $self->cleanup();
}

=head2 setup

 Title   : setup
 Usage   : $obj->setup()
 Function: 
 Example : 
 Returns : 
 Args    : 


=cut

sub setup {
  my $self = shift;

  my $dbh = $self->dbh();

  $dbh->begin_work();
  $self->setup_seq();
  $self->setup_files();

  $self->now();
}

=head2 cleanup

 Title   : cleanup
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub cleanup{
  my $self = shift;
  $self->cleanup_seq();
  $self->cleanup_files();
  $self->dbh->commit();
}


=head2 bulkload

 Title   : bulkload
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub bulkload{
  my $self = shift;

  foreach my $t(@TABLES){
    $self->file($t,"/tmp/$t.dat",2); #close
  }

  foreach my $t(@TABLES){
    $self->file($t,"/tmp/$t.dat",3); #open for read
  }

}

=head2 now

 Title   : now
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub now{
  my $self = shift;
  if(!$self->{'now'}){
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare('SELECT NOW()');
    $sth->execute();
    my($now) = $sth->fetchrow_array();
    $self->{'now'} = $now;
  }
  return $self->{'now'};
}

=head2 setup_files

 Title   : setup_files
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub setup_files{
   my ($self,@args) = @_;

   foreach my $t(@TABLES){
     $self->file($t,"/tmp/$t.dat",1); #open for write
   }
}

=head2 cleanup_files

 Title   : cleanup_files
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub cleanup_files{
   my ($self,@args) = @_;

   foreach my $t(@TABLES){
     $self->file($t,"/tmp/$t.dat",2); #close
   }
}

=head2 setup_seq

 Title   : setup_seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub setup_seq{
  my $self = shift;
  my $dbh = $self->dbh();

  foreach my $t (@TABLES){
    $dbh->do("LOCK TABLE $t IN SHARE MODE");
    $self->seq($t);
  }
}

=head2 cleanup_seq

 Title   : cleanup_seq
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub cleanup_seq{
  my $self = shift;
  foreach my $t (@TABLES){
    $self->seq($t,$self->seq($t));
  }
}

=head2 seq

 Title   : seq
 Usage   : 
 Function: 
 Example : 
 Returns : 
 Args    : 


=cut

sub seq{
  my($self,$seq,$val) = @_;

  my $seqname = sprintf("%s_%s_id_seq",$seq,$seq);
  my $dbh = $self->dbh();

  if(defined($seq) && defined($val)){
    $dbh->do("SELECT setval('public.$seqname',$val);") or die $dbh->errstr;
  } elsif(defined($seq) && !defined($self->{'seq'}{$seq})){
    my $sth = $dbh->prepare("SELECT nextval(?);") or die $dbh->errstr;
    $sth->execute("public.$seqname");
    my($nextval) = $sth->fetchrow_array();
    $self->{'seq'}{$seq} = $nextval + 1;
    return $nextval;
  } else {
    my $return = $self->{'seq'}{$seq};
    $self->{'seq'}{$seq}++;
    return $return;
  }
}

=head2 file

 Title   : file
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub file{
   my ($self,$table,$file,$action) = @_;

   if(defined($action)){
     if($action == 1){ #open for write
       open(my $h, ">$file") or $self->throw($!);
       $self->{'fh'}{$table} = $h;
     } elsif($action == 2){ #close
       close($self->{'fh'}{$table}) or $self->throw($!);
     } elsif($action == 3){ #open for read
       open(my $h, $file) or $self->throw($!);
       $self->{'fh'}{$table} = $h;
     } else {
       $self->throw('no such action');
     }
   } elsif(defined($table)){
     return $self->{'fh'}{$table};
   } else {
     return undef;
   }
}

=head2 cvterm

 Title   : cvterm
 Usage   : $obj->cvterm()
 Function: 
 Example : 
 Returns : 
 Args    : 


=cut

sub cvterm {
  my $self = shift;
  my $name = shift;

  if(!$self->{'cvterm_sth'}){
    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("select cvterm_id from cvterm c,dbxref d where c.dbxref_id = d.dbxref_id and (c.name = ? or d.accession = ?);");
    $self->{'cvterm_sth'} = $sth;
  }

  if(!$self->{'cvterm'}{$name}){
    $self->{'cvterm_sth'}->execute($name,$name);
    my $id = $self->{'cvterm_sth'}->fetchrow_array();
    $self->throw("couldn't find cvterm for $name") unless defined($id);
    $self->{'cvterm'}{$name} = $id;
  }

  return $self->{'cvterm'}{$name};
}


=head2 dbh

 Title   : dbh
 Usage   : $obj->dbh($newval)
 Function: 
 Example : 
 Returns : value of dbh (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub dbh{
    my $self = shift;

    return $self->{'dbh'} = shift if @_;
    return $self->{'dbh'};
}

=head2 contact

 Title   : contact
 Usage   : $obj->contact($newval)
 Function: 
 Example : 
 Returns : value of contact (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub contact{
    my $self = shift;

    return $self->{'contact'} = shift if @_;
    return $self->{'contact'};
}

=head2 organism

 Title   : organism
 Usage   : $obj->organism($newval)
 Function: 
 Example : 
 Returns : a Chado::Organism object
 Args    : a Chado::Organism object


=cut

sub organism{
    my $self = shift;

    return $self->{'organism'} = shift if @_;
    return $self->{'organism'};
}

=head2 pub

 Title   : pub
 Usage   : $obj->pub($newval)
 Function: 
 Example : 
 Returns : value of pub (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub pub{
    my $self = shift;

    return $self->{'pub'} = shift if @_;
    return $self->{'pub'};
}

1;
