# -*-Perl-*- mode (to keep my emacs happy)
# $Id: 02roundtrip.t,v 1.1 2005-02-18 20:26:40 cmungall Exp $

use strict;
use vars qw($DEBUG);
use Test;
use Bio::Chaos::XSLTHelper;
use Bio::Chaos::ChaosGraph;
use Bio::Root::IO;

BEGIN {     
    plan tests => 1;
}


my ($file) = (Bio::Root::IO->catfile("t","data",
                                     "CG10833.with-macros.chado-xml"));

my $cxfile = "$file-converted.chaos-xml";
chado2chaos($file,$cxfile);
my $cx = Bio::Chaos::ChaosGraph->new(-file=>$cxfile);
print $cx->asciitree;

my $features = $cx->get_features;

ok(scalar(@$features),10);

foreach my $f (@$features) {
    #print $f->sxpr;
}

exit 0;


sub chado2chaos {
    convert('chado','chaos',@_);
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
        my @chain = qw(cx-chaos-to-chado chado-insert-macros);
        Bio::Chaos::XSLTHelper->xsltchain($infile, $outfile, @chain);
    }
    else {
        die;
    }
}
