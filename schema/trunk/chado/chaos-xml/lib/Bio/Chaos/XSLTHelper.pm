# $Id: XSLTHelper.pm,v 1.1 2005-02-02 22:57:30 cmungall Exp $
#
#

=head1 NAME

  Bio::Chaos::XSLTHelper     - chains xslts

=head1 SYNOPSIS

  Bio::Chaos::XSLTHelper->xsltchain($infile,$outfile,@chaos_xslt_name_list)

=cut

=head1 DESCRIPTION

=cut

package Bio::Chaos::XSLTHelper;

use strict;
use XML::LibXSLT;
use base qw(Bio::Chaos::Root);

sub _expand_xslt_name {
    my $name = shift;

    if ($name =~ /\.xsl$/ && -f $name) {
        return $name;
    }

    if (!$ENV{CHAOS_HOME}) {
        printf STDERR <<EOM;

You must set the environment CHAOS_HOME to the location of
your chaos distribution

EOM
        ;
        die;
    }
    my $xf = "$ENV{CHAOS_HOME}/xsl/$name.xsl";
    return $xf;
}

sub xsltchain {
    my $self = shift;
    my $infile = shift;
    my $final_outfile = shift;
    my @chain = @_;

    my $n = 0;
    while (my $xn = shift @chain) {
        my $outfile = 
          scalar(@chain) ? _make_temp_file($infile,$n++) : $final_outfile;

        my $xslt = XML::LibXSLT->new;        
        my $xf = _expand_xslt_name($xn);
        my $ss = $xslt->parse_stylesheet_file($xf);
        print STDERR "Transforming $infile => $outfile [$xf]\n";
        my $results = $ss->transform_file($infile);
        if ($outfile) {
            $ss->output_file($results, $outfile);
        }
        else {
            $ss->output_fh($results, \*STDOUT);
        }
        $infile = $outfile; # cycle
    }
    return;
}

sub _make_temp_file {
    my $base = shift;
    my $n = shift;
    $base =~ s/.*\///;
    $base =~ s/TMP:\d+//;
    my $fn = "TMP:$$:$base.xml";
    return $fn;
}

1;
