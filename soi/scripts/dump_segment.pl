#!/usr/bin/env perl

use FindBin qw($RealBin);
use lib (($ENV{SOI_ROOT}) ||
                     (($INC[0]=~/^\./)?"$RealBin/$INC[0]":"$RealBin/.."));

use strict;

use SOI::Adapter;
use Getopt::Long;
use Carp;
use FileHandle;

my ($ad);
my $h = {};
GetOptions($h,
           "dbname|d=s",
           "program=s@",
           "sourcename=s@",
           "extend=s",
           "format=s",
           "debug",
          );
my $dbname = $h->{dbname};
my $type = 'scaffold';

eval {
    $ad = SOI::Adapter->new($dbname);
};
if ($@) {
    print STDERR "There was an error\n";
    print STDERR $@;
    exit 1;
}

foreach my $seg (@ARGV) {
    my ($features, $range, $t);
    ($range, $features) = &get_type_features($ad, $type, $seg);
    if (@{$features || []}) {
        my $arm = $ad->get_f({range=>$range}, {feature_types=>'chromosome_arm',noauxillaries=>1});
        my ($fmin, $fmax) = ($range->{fmin},$range->{fmax});
        my $new_f = $arm->stitch_child_segments($fmin,$fmax);
        $arm->hash->{residues} = "";
        my $rset_constr = {range=>$range};
        $rset_constr->{program} = $h->{program} if ($h->{program});
        $rset_constr->{sourcename} = $h->{sourcename} if ($h->{sourcename});
        my $rsets = $ad->get_results($rset_constr);
        map{$_->transform($new_f)}(@{$features},@{$rsets || []});
        my $ans = $ad->get_analysis();
        my %an_h;
        map{$an_h{$_->analysis_id}=$_}@{$ans || []};
        foreach my $rset (@{$rsets || []}) {
            my $an = $an_h{$rset->analysis_id};
            $an->add_node($rset) if ($an);
        }
        $arm->nodes([@{$arm->nodes || []},@{$features}, @{$ans || []}]);
        my $format = $h->{format} || "soi";
        my $m = "to_$format"."_xml";
        my $f;
        $f = "$seg.$format.xml" unless (scalar(@ARGV) == 1);
        $arm->$m($f);
    }
    else {
        printf STDERR "did not get any feature for %s=%s\n", $type, $seg
    }
}
$ad->close_handle;
exit;

sub get_type_features {
    my $ad = shift;
    my $by_type = shift;
    my $type = $by_type;
    my $val = shift;

    my $opts = {};
    if ($by_type eq 'gene') {
        $opts->{extend} = $h->{extend} || 50000;
    }
    my $method = "get_features_by_$type";

    if ($ad->can($method)) {
        return ($ad->$method($val, $opts));
    }
    else {
        confess("can not do $method");
    }
}
