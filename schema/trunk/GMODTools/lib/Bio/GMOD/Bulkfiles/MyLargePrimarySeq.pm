package Bio::GMOD::Bulkfiles::MyLargePrimarySeq;
use strict;

=head1 Bio::GMOD::Bulkfiles::MyLargePrimarySeq

  patch to use Bio::Seq::LargePrimarySeq to read
  feature locations from dna.raw files.
   
  my $dnaseq= Bio::GMOD::Bulkfiles::MyLargePrimarySeq->new( -file => $dnafile);
  
  $loc= new Bio::Location::something(...);
  $bases= $dnaseq->subseq($loc);   
  
=cut


use Bio::Seq::LargePrimarySeq;
use base qw(Bio::Seq::LargePrimarySeq);
#use vars qw(@ISA); BEGIN{ @ISA = qw(Bio::Seq::LargePrimarySeq); }

sub new {
  my ($class, %params) = @_;
  my $dnafile = delete $params{'-file'} ;
  my $self = $class->SUPER::new(%params);
  $self->dnafile($dnafile);
  if( $dnafile && -e $dnafile ) {  
    ## $self->_filename($dnafile); # don't change to our name in case StUPER wants to unlink it   
    my $fh= new FileHandle($dnafile);
    $fh->seek(0,2);
    my $flen= $fh->tell();
    $fh->seek(0,0);
    $self->_fh($fh);
    $self->length($flen);
    }
  
  return $self;
}

sub dnafile {
  my $self = shift;  
  if (@_) {  $self->{dnafile}= shift; }
  return $self->{dnafile};
}

## dang this nasty -- DONT unlink
sub DESTROY {
  my $self = shift;
  my $fh = $self->_fh();
  close($fh) if( defined $fh );
  $self->_filename(''); # is unlink '' bad ?    
  
  # this should be handled by Tempfile removal, but we'll unlink anyways.
  ##unlink $self->_filename() if defined $self->_filename() && -e $self->_filename;
  ##$self->SUPER::DESTROY();
}


#-------

1;

