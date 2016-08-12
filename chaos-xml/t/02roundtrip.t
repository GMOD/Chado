# -*-Perl-*- mode (to keep my emacs happy)
# $Id: 02roundtrip.t,v 1.3 2005-06-15 16:21:10 cmungall Exp $

use strict;
use vars qw($DEBUG);
use Test;
use Bio::Chaos::XSLTHelper;
use Bio::Chaos::ChaosGraph;
use Bio::Root::IO;

BEGIN {     
    plan tests => 1;
}

my @files = (Bio::Root::IO->catfile("t","data",
                                    "CG10833.with-macros.chado-xml"));

foreach my $file (@files) {

    my $cxfile = "$file-converted.chaos-xml";
    chado2chaos($file,$cxfile);
    check_cx($cxfile, 10);

    my $chfile = "$file-converted.chado-xml";
    chaos2chado($cxfile,$chfile);

    exit;
    chado2chaos($chfile,$cxfile);
    check_cx($cxfile, 10);
}

sub check_cx {
    my $cxfile = shift;
    my $expected_features = 10;

    my $cx = Bio::Chaos::ChaosGraph->new(-file=>$cxfile);
    print $cx->asciitree;

    my $features = $cx->get_features;
    
    ok(scalar(@$features),$expected_features);
    
    foreach my $f (@$features) {
        #print $f->sxpr;
    }
} 

exit 0;

sub chado2chaos {
    convert('chado','chaos',@_);
}
sub chaos2chado {
    convert('chaos','chado',@_);
}

sub convert {
    my ($from,
        $to,
        $infile,
        $outfile) = @_;
    if ($from eq 'chado' && $to eq 'chaos') {
        my @chain = qw(chado-expand-macros cx-chado-to-chaos);
        Bio::Chaos::XSLTHelper->xsltchain($infile, $outfile, @chain);
    }
    elsif ($from eq 'chaos' && $to eq 'chado') {
        my @chain = qw(cx-chaos-to-chado chado-expand-macros chado-insert-macros);
        Bio::Chaos::XSLTHelper->xsltchain($infile, $outfile, @chain);
    }
    else {
        die;
    }
}
