#!/usr/local/bin/perl

BEGIN{
    eval{do "config.pl"};
}


use FindBin qw($RealBin);
use lib (($ENV{SOI_ROOT}) ||
                     (($INC[0]=~/^\./)?"$RealBin/$INC[0]":"$RealBin/.."));

use strict;

use SOI::Adapter;
use Getopt::Long;
use Carp;
use FileHandle;
use CGI;

my ($cgi) = new CGI;
my ($ad);

my $dbname = $cgi->param('database') || $ENV{dbname} || "chado";

print $cgi->header(-type=>'text/plain');

my @params = $cgi->param();
my @type = grep{$_ eq 'gene' || $_ eq 'range' || $_ eq 'band' || $_ eq 'accession' || $_ eq 'scaffold'}@params;
my $type = shift @type;
if ($type) {
    my ($features, $range, $t);
    eval {
        $ad = SOI::Adapter->new($dbname);
        ($range, $features) = &get_type_features($ad, $type, $cgi->param($type)) if ($cgi->param($type));
    };
    if ($@) {
        print STDERR "There was an error\n";
        print STDERR $@;
        exit 1;
    }

    if (@{$features || []}) {
        my $arm = $ad->get_f({range=>$range}, {feature_types=>'chromosome_arm',noauxillaries=>1});
        my ($fmin, $fmax) = ($range->{fmin},$range->{fmax});
        my $new_f = $arm->stitch_child_segments($fmin,$fmax);
        $arm->hash->{residues} = "";
        my $rsets = $ad->get_results({range=>$range});
        map{$_->transform($new_f)}(@{$features},@{$rsets || []});
        my $ans = $ad->get_analysis();
        my %an_h;
        map{$an_h{$_->analysis_id}=$_}@{$ans || []};
        foreach my $rset (@{$rsets || []}) {
            my $an = $an_h{$rset->analysis_id};
            $an->add_node($rset) if ($an);
        }
        $arm->nodes([@{$arm->nodes || []},@{$features}, @{$ans || []}]);
        $arm->to_game_xml;
    }
    else {
        printf STDERR "did not get any feature for %s=%s\n", $type, $cgi->param($type);
    }
    $ad->close_handle;
}
else {
    printf STDERR "does not support type: %s\n",join(",",$cgi->param());
}
exit;

sub get_type_features {
    my $ad = shift;
    my $by_type = shift;
    my $type = $by_type;
    my $val = shift;

    my $opts = {};
    if ($by_type eq 'gene') {
        $opts->{extend} = $cgi->param('window') || 50000;
    }
    my $method = "get_features_by_$type";

    if ($ad->can($method)) {
        return ($ad->$method($val, $opts));
    }
    else {
        confess("can not do $method");
    }
}
