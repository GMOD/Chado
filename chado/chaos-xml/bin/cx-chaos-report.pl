#!/usr/local/bin/perl -w
use strict;

use Getopt::Long;
use Bio::Chaos::ChaosGraph;

my $expanded;
my $out;
GetOptions(
	   "help|h"=>sub {
	       system("perldoc $0"); exit 0;
	   }
	  );

while (my $file = shift @ARGV) {
    my $cx = Bio::Chaos::ChaosGraph->new(-file=>$file);
    print "** REPORT FOR: $file\n";
    my $ufs = $cx->unlocalized_features;
    printf "number of unlocalized features: %d\n", scalar(@$ufs);
    print $cx->asciitree;
    print "\n";
}

exit 0;

__END__

=head1 NAME 

  cx-chadoxml2chaos.pl

=head1 SYNOPSIS

  cx-chadoxml2chaos.pl sample/CG10833.chado-xml

=head1 DESCRIPTION



=head1 REQUIREMENTS

=cut

