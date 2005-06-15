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

# cx-chado-to-chaos inputs expanded chado-xml
unshift @chain, qw(chado-expand-macros) unless $expanded;
Bio::Chaos::XSLTHelper->xsltchain($file, $out, @chain);

exit 0;

__END__

=head1 NAME 

  cx-chadoxml2chaos.pl

=head1 SYNOPSIS

  cx-chadoxml2chaos.pl sample/CG10833.chado-xml
  cx-chadoxml2chaos.pl -x sample/CG10833.no-macros.chado-xml

=head1 DESCRIPTION

Converts Chado-XML to Chaos-XML

Note that there are different "flavours" of Chado-XML. This includes
both macro-ified and un-macroified flavours. This script will handle both

As a first step, this script will expand all macros in the the input
file to their full expanded form. This step has no effect if the
macros are already expanded.

As a second step, the expanded chado-xml is converted to chaos-xml

Both steps happen via the use of XSL Stylesheet Transforms

=head1 ARGUMENTS

=over

=item -x 

The input chado xml file has no macros; do not call macro-expansion step

You do not need to use this option, but performance may be faster if
you omit the expansion step if it is not required

=back 


=Head1 REQUIREMENTS

You need an XSLT Processor, such as xsltproc, available as part of libxslt

=cut

