package Bio::FeatureIO::chadobulk;

use strict;
use base qw(Bio::FeatureIO);

use Bio::SeqIO;
use Bio::GMOD::Config;
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

  #my $config = Bio::GMOD::Config->new();
  #warn Dumper($config);

  $self->dbh(DBI->connect('dbi:Pg:host=soleus;dbname=chado_gec','allenday','allenday'));
  $self->setup();
}

sub next_feature {
  shift->throw('this class only writes to database');
}

sub write_feature {
  my($self,$feature) = @_;

  my $dbxref_id   = "\\N";

  my $organism_id = 1; #FIXME

  my $feature_id = $self->write_row_feature($feature);
  next unless $feature_id;
  $self->write_row_featureloc($feature , $feature_id);
  $self->write_row_feature_relationship($feature,$feature_id);
}

sub DESTROY {
  my $self = shift;
  $self->bulkload();
  $self->cleanup();
}

=head2 write_row_feature

 Title   : write_row_feature
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub write_row_feature{
  my ($self,$feature) = @_;

#      Column      |            Type             | Modifiers
#------------------+-----------------------------+----------
# feature_id       | integer                     | not null

  my $feature_id = $self->seq('feature');

# dbxref_id        | integer                     |

  my $dbxref_id = '\\N';

# organism_id      | integer                     | not null

  my $organism_id = 1; #FIXME
  #my $organism_id = $self->organism->id;

# name             | character varying(255)      |

  my @names = map {$_->value} $feature->annotation->get_Annotations('Name');
  my $name = $names[0];
  if(scalar(@names) > 1){
    $self->throw('feature can only have one Name, (this is a limitation in the loader and/or gff spec, not the file) but had: '.join(' ',@names));
  }

# uniquename       | text                        | not null

  my @unames = map {$_->value} $feature->annotation->get_Annotations('ID');
  my $uname = $unames[0];
  if(defined($uname) and $self->feature_id($uname)){
    my $saw = $self->feature_id($uname);
    $self->warn("already saw $uname, returning previous record $saw.  FIXME we should still try to extract new attributes");
    return $saw;
  } elsif(defined($uname)){
    $self->feature_id($uname,$feature_id);
  } else {
    $uname = $feature->seq_id.':'.$feature->start.','.$feature->end;
  }
  if(scalar(@unames) > 1){
    $self->throw('feature can only have one ID (this is a limitation in the loader and/or gff spec, not the file), but had: '.join(' ',@unames));
  }

  $name ||= $uname;

# residues         | text                        |

  my $residues = '\\N';

# seqlen           | integer                     |

  my $seqlen = '\\N';

# md5checksum      | character(32)               |

  my $md5 = '\\N';

# type_id          | integer                     | not null

  my @types = map { $self->cvterm($_->name) } $feature->annotation->get_Annotations('feature_type');
  my $type = $types[0];
  if(scalar(@types) > 1){
    $self->throw('feature can only have one type, but had: '.join(' ',@types));
  }
  $self->throw("$feature has undefined feature_type, bailing out") unless $type;

# is_analysis      | boolean                     | not null

  my $is_analysis = 'F';

# timeaccessioned  | timestamp without time zone | not null

  my $timeaccessioned = $self->now();

# timelastmodified | timestamp without time zone | not null

  my $timelastmodified = $self->now();

  my $feature_fh = $self->file('feature');
  print $feature_fh join("\t",
                         $feature_id,$dbxref_id,$organism_id,$name,$uname,
                         $residues,$seqlen,$md5,$type,$is_analysis,
                         $timeaccessioned,$timelastmodified),"\n";

  return $feature_id;
}

=head2 write_row_featureloc

 Title   : write_row_featureloc
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub write_row_featureloc{
  my ($self,$feature,$feature_id) = @_;

#     Column      |   Type   |                               Modifiers
#-----------------+----------+-----------------------------------------------------------------------
# featureloc_id   | integer  | not null

  my $featureloc_id = $self->seq('featureloc');

# feature_id      | integer  | not null

  #passed as arg

# srcfeature_id   | integer  |

  my $srcfeature_id = $self->feature_id($feature->seq_id);

  return undef unless defined($srcfeature_id);

# fmin            | integer  |

  my $fmin = $feature->start() || 0;

# is_fmin_partial | boolean  | not null

  my $is_fmin_partial = 'F';

# fmax            | integer  |

  my $fmax = $feature->end() + 1;

# is_fmax_partial | boolean  | not null

  my $is_fmax_partial = 'F';

# strand          | smallint |

  my $strand = $feature->strand();

# phase           | integer  |

  my $phase = $feature->frame();
  $phase = '\\N' if $phase eq '.';

# residue_info    | text     |

  my $residue_info = '\\N';

# locgroup        | integer  | not null

  my $locgroup = 0;

# rank            | integer  | not null

  my $rank = $self->featureloc_rank($feature_id);

  my $featureloc_fh = $self->file('featureloc');
  print $featureloc_fh join("\t",
                            $featureloc_id,$feature_id,$srcfeature_id,$fmin,$is_fmin_partial,
                            $fmax,$is_fmax_partial,$strand,$phase,$residue_info,$locgroup,$rank),"\n";

  return $featureloc_id;

}

=head2 write_row_feature_relationship

 Title   : write_row_feature_relationship
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub write_row_feature_relationship{
  my ($self,$feature,$feature_id) = @_;

  my $parent = ($feature->annotation->get_Annotations('Parent'))[0];
  #warn $parent;
  return undef unless $parent;
  my $parent_id = $self->feature_id($parent->value());
  my $part_of = $self->cvterm('part_of');

  my $feature_relationship_id = $self->seq('feature_relationship');

  my $fh = $self->file('feature_relationship');
  print $fh join("\t",
                 $feature_relationship_id,$feature_id,$parent_id,$part_of,'\\N',0
                ),"\n";
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

=head2 featureloc_rank

 Title   : featureloc_rank
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub featureloc_rank{
   my ($self,$feature_id) = @_;

   if(!$self->{'featureloc_rank'}{$feature_id}){
     $self->{'featureloc_rank'}{$feature_id} = 0;
   }

   my $r = $self->{'featureloc_rank'}{$feature_id};
   $self->{'featureloc_rank'}{$feature_id}++;
   return $r;
}


=head2 feature_id

 Title   : feature_id
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub feature_id{
   my ($self,$id,$feature_id) = @_;

   if(defined($feature_id)){
     $self->{'feature_id'}{$id} = $feature_id;
   } elsif(!defined($self->{'feature_id'}{$id})){
     #do dbi lookup and cache here
     if(!$self->{'feature_id_sth'}){
       my $dbh = $self->dbh();
       $self->{'feature_id_sth'} = $dbh->prepare('select feature_id from feature where name = ?');
     }

     $self->{'feature_id_sth'}->execute($id);

     $self->throw("too many records for $id") if $self->{'feature_id_sth'}->rows() > 1;

     my($x) = $self->{'feature_id_sth'}->fetchrow_array();
     $self->{'feature_id'}{$id} = $x;
   }

   return $self->{'feature_id'}{$id};
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
    #FIXME this does not handle SO:xxxxxxx identifiers from dbxref, which requires an OUTER JOIN query
    my $sth = $dbh->prepare("select cvterm_id from cvterm c,dbxref d where c.name = ?;");
    $self->{'cvterm_sth'} = $sth;
  }

  if(!$self->{'cvterm'}{$name}){
    $self->{'cvterm_sth'}->execute($name);
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
