#!/usr/bin/env perl

use SQL::Translator;
use Data::Dumper;   
use lib './bin';
use Skip_tables qw( @skip_tables );

$SQL::Translator::DEBUG = 0;

my $in = shift;
open(IN,$in) || die "couldn't open $in: $!";

my @create = <IN>;
my $create = join '', @create;

my $tr = SQL::Translator->new(
				parser   => "PostgreSQL",
				producer => "HTML",
                                producer_args => {
                                                   pretty => 1,
                                                 },
                                filters       => [
                                    sub {
                                        my $schema = shift;
                                        foreach (@skip_tables) {
                                            $schema->drop_table($_);
                                        }
                                    },
                                ],
                             );
                               
print $tr->translate(\$create);
