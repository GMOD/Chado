package Bio::XML::Sequence::Transform;

use XML::NestArray qw(:all);
use base XML::NestArray::NestArrayImpl;
use strict;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless [], $class;
    return $self;
}

sub data {
    my $self = shift;
    my $data = shift || [];
    @$self = @$data;
}

sub to_gffstruct {
    my $tree = shift;
    my @features = $tree->fst("feature");
    my @frs = $tree->fst("feature_relationship");

    my @partofs = grep {$_->sget_type eq "Part-Of"} @frs;
    my %parenth = map {$_->sget_subjfeature => $_->sget_objfeature} @partofs;
    my %childh = reverse %parenth;

    my @groups = ();
    my %groups = ();
    foreach my $f (@features) {
        # don't count grouping features
        next if $childh{$f->sget_dbxref};
        my $parent = $partof{$f->sget_dbxref};
        my $gff =
          [sf=>[
                [src=>$f->sget_source_feature],
                [group=>$parent],
               ]
          ];
    }
}
