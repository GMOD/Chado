# $Id: FeatureUtil.pm,v 1.2 2004-07-23 22:15:43 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::FeatureUtil     - sequence and feature utilities

=head1 SYNOPSIS

  Bio::Chaos::FeatureUtil->blah('xx');

=cut

=head1 DESCRIPTION



=cut

package Bio::Chaos::FeatureUtil;

use Exporter;
use Bio::Chaos::Root;
use Data::Stag;
use Carp;
use Bio::Seq;
use FileHandle;
use Digest::MD5;
use strict qw(subs vars refs);
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Bio::Chaos::Root Exporter);


@EXPORT_OK =
  qw(
     bcmm2ibv
     bcmm2ibmm
     ibv2bcmm
     cutseq
     revcomp
     translate
     md5
    );
%EXPORT_TAGS =
  (all=>[@EXPORT_OK]);


sub BLAST_TYPE_TO_DESCRIPTION {
    return
      {
       tblastx => 'translated_nucleotide_match',
       tblastn => 'translated_nucleotide_match',
       blastn => 'nucleotide_to_nucleotide_match',
       blastx => 'nucleotide_to_protein_match',
       blastp => 'protein_to_proteinmatch',
      };
}

sub SELF {
    my $self = shift;
    if (ref($self)) {
	return $self;
    }
    return $self->new;
}

sub unflattener {
    my $self = shift;
    $self->{_unflattener} = shift if @_;
    if (!$self->{_unflattener} ) {
	$self->load_module("Bio::SeqFeature::Tools::Unflattener");
	$self->{_unflattener} =
	  Bio::SeqFeature::Tools::Unflattener->new;
    }
    return $self->{_unflattener};
}

sub typemapper {
    my $self = shift;
    $self->{_typemapper} = shift if @_;
    if (!$self->{_typemapper} ) {
	$self->load_module("Bio::SeqFeature::Tools::TypeMapper");
	$self->{_typemapper} =
	  Bio::SeqFeature::Tools::TypeMapper->new;
    }
    return $self->{_typemapper};
}

sub chaos_from_genbank_file {
    my $self = SELF(shift);
    my $file = shift;
    my $fmt = shift || 'genbank';
    $self->load_module("Bio::SeqIO");
    my $unflattener = $self->unflattener;
    my $tm = $self->typemapper;
    my $seqio =
      Bio::SeqIO->new(-file=> $file,
                      -format => $fmt);
    my @chaoses = ();
    while (my $seq = $seqio->next_seq()) {
	$unflattener->unflatten_seq(-seq=>$seq,
				    -use_magic=>1);
	$tm->map_types_to_SO(-seq=>$seq);
	my $outio = Bio::SeqIO->new( -format => 'chaos');
	$outio->write_seq($seq);
	my $chaos = $outio->handler->stag;
	push(@chaoses, $chaos);
    }
    return $self->merge_chaos_docs(\@chaoses);
}

sub merge_chaos_docs {
    my $self = shift;
    my $chaoses = shift;
    my $chaos = shift @$chaoses;
    foreach my $chaosI (@$chaoses) {
	my @kids = $chaosI->kids;
	foreach my $kid (@kids) {
	    $chaos->add($kid->name, $kid->data)
	      unless $kid->name eq 'chaos_metadata';
	}
    }
    return $chaos;
}


=head2 COORDINATES

Coordinates are either B<Interbase> or <Base-oriented>.

Interbase coordinates count the B<spaces between bases> and the origin is zero

Base-oriented coordinates count the B<bases> and the origin is 1

To convert between these two, add/subtract 1 from the minimum (low)
coordinate only

Imagine a sequence TCATGCAA
eg
     1 2 3 4 5 6 7 8       BASE
     T C A T G C A A
    0 1 2 3 4 5 6 7 8      INTERBASE

In interbase, the ATG codon is [2,5]; in base it is [3,5]

With interbase, length is high-low

With base, length is (high-low)+1

interbase has the advantages of simpler arithmetic, and the ability to
represent length-zero features (eg insertions)

Beyond the base/interbase distinction, ranges can also be specified as
either min-max-strand triples (directionality explicit) or
begin-end pairs (directionality implicit).



=over

=item bcmm

  (bmin, bmax, strand)

base coordinates with minmax semantics - native to bioperl

=item ibmm

  (imin, imax, strand)

interbase with minmax semantics - native to chado

=item ibv

  (nbeg, nend, ?strand)

interbase vector (in the mathematical sense)

so called natural begin and end - this is the native chaos coordinate system

=back


=cut

sub bcmm2ibv {
    my ($bmin, $bmax, $strand) = @_;
    $strand ||= 0;
    $strand = 1 if ($strand eq '+');
    $strand = -1 if ($strand eq '-');
    $bmin--;
    ($bmin, $bmax) = ($bmax, $bmin) if $strand < 0;
    return ($bmin, $bmax, $strand); 
}
sub bcmm2ibmm {
    my ($bmin, $bmax, $strand) = @_;
    $bmin--;
    return ($bmin, $bmax, $strand); 
}
sub ibv2bcmm {
    my ($nbeg, $nend, $strand) = @_;
    if ($nbeg != $nend) {
	my $strandP = $nbeg < $nend ? -1 : +1;
	if ($strand &&
	    $strand != $strandP) {
	    confess("$nbeg, $nend, $strand is not valid ibv coordinate triple");
	}
	
    }
}

sub cutseq {
    my $res = shift;
    my $nbeg = shift;
    my $nend = shift;
    if ($nbeg <= $nend) {
        return substr($res, $nbeg, $nend-$nbeg);
    }
    else {
        my $cut = substr($res, $nend, $nbeg-$nend);
        $cut = revcomp($cut);
        return $cut;
    }
}

sub revcomp {
    my $res = shift;
    $res =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
    return scalar(CORE::reverse($res));
}

sub translate {
    my $res = shift;
    my $tt = shift || 0;
    my $seq = Bio::Seq->new(-seq=>$res);
    my $tnres = $seq->translate->seq;
    $tnres =~ s/\*.*//;
    return $tnres;
}

sub md5 {
    my $res = shift;
    my $md5 = Digest::MD5->new;
    $md5->add($res);
    return $md5->hexdigest;
}

1;
