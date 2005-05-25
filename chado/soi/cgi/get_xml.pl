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

my $dbname = $cgi->param('database') || $ENV{DBNAME} || "chado";

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
        #get around arm residues stored problem (wastefull & slow)
        my $GBs = $ad->get_f({range=>$range}, {feature_types=>'golden_path_region',noauxillaries=>1});
        my $arm = SOI::Feature->new({type=>'chromosome_arm',name=>$range->{src}});
        $arm->nodes($GBs);
        my ($fmin, $fmax) = ($range->{fmin},$range->{fmax});
        my ($segs, $new_f) = $arm->stitch_child_segments($fmin,$fmax);
        $arm->hash->{residues} = "";
        my $rsets = $ad->get_results({range=>$range});
        map{$_->transform($new_f)}(@{$features},@{$rsets || []}, @{$segs || []});
        my $ans = $ad->get_analysis();
        my %an_h;
        map{$an_h{$_->analysis_id}=$_}@{$ans || []};
        foreach my $rset (@{$rsets || []}) {
            my $an = $an_h{$rset->analysis_id};
            $an->add_node($rset) if ($an);
        }
        #golden_path is not an analysis in chado, manufacture one
        my $g_an = SOI::Feature->new({program=>'assembly',sourcename=>'path', type=>'companalysis'});
        $g_an->nodes($segs);
        map{
            my $g_path = $_;
            $g_path->residues(undef);
            $g_path->type('match');
            my $span = SOI::Feature->new({%{$g_path->hash}});
            $span->name($span->name.":1");
            $span->uniquename($span->name);
            $span->type('match_part');
            $g_path->nodes([$span]);
            $span->secondary_nodes([SOI::Feature->new({src_seq=>$g_path->name,fmin=>0,fmax=>$g_path->length,strand=>1})]);
        }@{$segs || []};
        push @$ans, $g_an;
        $arm->nodes([@{$arm->nodes || []}, @{$features}, @{$ans || []}]);
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
