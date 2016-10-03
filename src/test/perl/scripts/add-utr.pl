use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 14;
}
use XML::NestArray qw(:all);
use XML::NestArray::ITextParser;
use XML::NestArray::Base;
use Bio::XML::Sequence::Transform;

use FileHandle;
use strict;
use Data::Dumper;

my $nudata = Node([]);
$nudata->parse(@ARGV);
my $T = Bio::XML::Sequence::Transform->new();
$T->data($nudata);

my @sfgenes = grep { $_->sget_ftype eq "gene" } findSubTree($nudata, "feature");
my @sftrs = grep { $_->sget_ftype eq "transcript" } findSubTree($nudata, "feature");
map {$T->get_loc($_)} @sfgenes;
map {my @utr = $T->implicit_utr_from_transcript($_);map {print tree2xml($_)} @utr} @sftrs;
print tree2xml($nudata);



