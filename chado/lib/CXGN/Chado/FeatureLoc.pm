
=head1 NAME

CXGN::Chado::FeatureLoc - a database wrapper class for the Chado featureloc table

=head1 DESCRIPTION

The featureloc table is used to map features onto other features, for example, exons on genomic sequence, or domains on proteins. The meaning of the database fields in the featureloc table has been reverse engineered to mean the following:

=over 4

=item featureloc_id: primary key

=item feature_id: the feature that is being mapped (let's called f1)

=item srcfeature_id: the feature we're mapping on (let's call it f2)

=item fmin: the start coordinate of f1 on f2

=item is_fmin_partial: is f2 truncated?

=item fmax: the end coordinate of f1 on f2

=item is_fmax_partial: is f2 truncated?

=item strand: either -1,-2,-3,1,2,3

=item phase: the phase for protein coding exons

=item residue_info: this is possibly used for snps (?)

=item locgroup:

=item rank:

=back

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut



use strict;

package CXGN::Chado::FeatureLoc;

use CXGN::DB::Object;

use base "CXGN::DB::Object";


=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    
    if ($id) {
	$self->set_featureloc_id($id);
	$self->fetch();
    }

    return $self;
}

=head2 fetch

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut



sub fetch { 
    my $self = shift;
    my $query = "SELECT featureloc_id, feature_id, srcfeature_id, fmin, is_fmin_partial, famx, is_fmax_partial, strand, phase, residue_info, locgroup, rank FROM 
featureloc WHERE featureloc_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_featureloc_id());
    my ($featureloc_id, $feature_id, $srcfeature_id, $fmin, $is_fmin_partial, $fmax, $is_fmax_partial, $strand, $phase, $residue_info, $locgroup, $rank) = $sth->fetchrow_array();
    $self->set_featureloc_id($featureloc_id);
    $self->set_feature_id($feature_id);
    $self->set_scrfeature_id($srcfeature_id);
    $self->set_fmin($fmin);
    $self->set_is_fmin_partial($is_fmin_partial);
    $self->set_fmax($fmax);
    $self->set_is_fmax_partial($is_fmax_partial);
    $self->set_strand($strand);
    $self->set_phase($phase);
    $self->set_residue_info($residue_info);
    $self->set_locgroup($locgroup);
    $self->set_rank($rank);
}

=head2 store

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub store { 
    my $self = shift;
    if ($self->get_featureloc_id()) { 
	my $query = "UPDATE featureloc SET
                       feature_id=?, srcfeature_id=?, fmin=?, is_fmin_partial=?, fmax=?, is_fmax_partial=?, strand=?, phase=?, residue_info=?, locgroup=?, rank=? WHERE featureloc_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_feature_id(),
		      $self->get_srcfeature_id(),
		      $self->get_fmin(),
		      $self->get_is_fmin_partial(),
		      $self->get_fmax(),
		      $self->get_is_fmax_partial(),
		      $self->get_strand(),
		      $self->get_phase(),
		      $self->get_residue_info(),
		      $self->get_locgroup(),
		      $self->get_rank(),
		      $self->get_featureloc_id(),
		      );
	return $self->get_featureloc_id();
    }
    else { 
	my $query = "INSERT INTO featureloc (feature_id, srcfeature_id, fmin, is_fmin_partial, fmax, is_fmax_partial, strand, phase, residue_info, locgroup, rank) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( $self->get_feature_id(),
		       $self->get_srcfeature_id(),
		       $self->get_fmin(),
		       $self->get_is_fmin_partial(),
		       $self->get_fmax(),
		       $self->get_is_fmax_partial(),
		       $self->get_strand(),
		       $self->get_phase(),
		       $self->get_residue_info(),
		       $self->get_locgroup(),
		       $self->get_rank()
		       );
	my $id = $self->get_currval("featureloc_featureloc_id_seq");
	$self->set_featureloc_id($id);
	return $id;
    }
}

=head2 accessors get_featureloc_id, set_featureloc_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_featureloc_id {
  my $self = shift;
  return $self->{featureloc_id}; 
}

sub set_featureloc_id {
  my $self = shift;
  $self->{featureloc_id} = shift;
}

=head2 accessors get_feature_id, set_feature_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_feature_id {
  my $self = shift;
  return $self->{feature_id}; 
}

sub set_feature_id {
  my $self = shift;
  $self->{feature_id} = shift;
}

=head2 accessors get_srcfeature_id, set_srcfeature_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_srcfeature_id {
  my $self = shift;
  return $self->{srcfeature_id}; 
}

sub set_srcfeature_id {
  my $self = shift;
  $self->{srcfeature_id} = shift;
}

=head2 accessors get_fmin, set_fmin

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_fmin {
  my $self = shift;
  return $self->{fmin}; 
}

sub set_fmin {
  my $self = shift;
  $self->{fmin} = shift;
}

=head2 accessors get_is_fmin_partial, set_is_fmin_partial

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_is_fmin_partial {
  my $self = shift;
  if (!exists($self->{is_fmin_partial}) || !defined($self->{is_fmin_partial})) {  
      $self->{is_fmin_partial}='f'; 
  }
  return $self->{is_fmin_partial}; 
}

sub set_is_fmin_partial {
  my $self = shift;
  $self->{is_fmin_partial} = shift;
}

=head2 accessors get_fmax, set_fmax

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_fmax {
  my $self = shift;
  return $self->{fmax}; 
}

sub set_fmax {
  my $self = shift;
  $self->{fmax} = shift;
}

=head2 accessors get_is_fmax_partial, set_is_fmax_partial

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_is_fmax_partial {
  my $self = shift;
  if (!exists($self->{is_fmax_partial})||!defined($self->{is_fmax_partial})) { 
      $self->{is_fmax_partial}='f'; 
  }
  return $self->{is_fmax_partial}; 
}

sub set_is_fmax_partial {
  my $self = shift;
  $self->{is_fmax_partial} = shift;
}

=head2 accessors get_strand, set_strand

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_strand {
  my $self = shift;
  return $self->{strand}; 
}

sub set_strand {
  my $self = shift;
  $self->{strand} = shift;
}

=head2 accessors get_phase, set_phase

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_phase {
  my $self = shift;
  return $self->{phase}; 
}

sub set_phase {
  my $self = shift;
  $self->{phase} = shift;
}

=head2 accessors get_residue_info, set_residue_info

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_residue_info {
  my $self = shift;
  return $self->{residue_info}; 
}

sub set_residue_info {
  my $self = shift;
  $self->{residue_info} = shift;
}

=head2 accessors get_locgroup, set_locgroup

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_locgroup {
  my $self = shift;
  if (!exists($self->{locgroup}) || !defined($self->{locgroup})) { 
      $self->{locgroup}=0;
  }
  return $self->{locgroup}; 
}

sub set_locgroup {
  my $self = shift;
  $self->{locgroup} = shift;
}

=head2 accessors get_rank, set_rank

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_rank {
  my $self = shift;
  if (!exists($self->{rank}) || !defined($self->{rank})) { 
      $self->{rank} = 0; 
  }
  return $self->{rank}; 
}

sub set_rank {
  my $self = shift;
  $self->{rank} = shift;
}

	
		      
return 1;  
