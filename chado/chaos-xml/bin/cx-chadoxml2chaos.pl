#!/usr/local/bin/perl -w
use strict;

use Getopt::Long;
use FileHandle;
use Bio::Chaos::XSLTHelper;

my $expanded;
my $out;
GetOptions(
           "expanded|x"=>\$expanded,
           "out|o"=>\$out,
	   "help|h"=>sub {
	       system("perldoc $0"); exit 0;
	   }
	  );

my $file = shift @ARGV;
if (@ARGV) {
    print STDERR "no more than one file!\n";
    exit 1;
}

my @chain = qw(cx-chado-to-chaos);
unshift @chain, qw(chado-expand-macros) unless $expanded;
Bio::Chaos::XSLTHelper->xsltchain($file, $out, @chain);


exit 0;

__END__

=head1 NAME 

  cx-chadoxml2chaos.pl

=head1 SYNOPSIS

  cx-chadoxml2chaos.pl sample/CG10833.chado-xml

=head1 DESCRIPTION



=head1 REQUIREMENTS

=cut

