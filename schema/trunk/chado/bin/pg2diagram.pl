#!/usr/bin/perl

use SQL::Translator;
use Data::Dumper;   

$SQL::Translator::DEBUG = 0;

my $in = shift;
open(IN,$in) || die "couldn't open $in: $!";

my @create = <IN>;
my $create = join '', @create;

my $tr = SQL::Translator->new(
				parser   => "PostgreSQL",
				producer => "Diagram"
                             );
                               
print $tr->translate(\$create);
