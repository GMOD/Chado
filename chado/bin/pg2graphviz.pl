#!/usr/bin/perl

use SQL::Translator;
use Data::Dumper;   

$SQL::Translator::DEBUG = 0;

my $in = shift;
open(IN,$in) || die "couldn't open $in: $!";

my @create = <IN>;
my $create = join '', @create;

my $tr = SQL::Translator->new(
				from          => "PostgreSQL",
				to            => "GraphViz",
                                producer_args => {
                                                   output_type => 'png',
                                                   width => 10,
                                                   height => 8,
                                                   layout => 'neato',
                                                 }
                             );
                               
print $tr->translate(\$create);
