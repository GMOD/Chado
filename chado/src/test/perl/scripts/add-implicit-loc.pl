#!/usr/local/bin/perl -w
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
map {$T->get_loc($_)} @sfgenes;
print tree2xml($nudata);



