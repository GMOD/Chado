#!/usr/bin/perl
use strict;
use warnings;

my $working_dir = "/var/www/apollo/tmp";
my $keep_days   = 7;

opendir DIR, $working_dir or die $!;
while ( my $file = readdir(DIR)) {
    $file = "$working_dir/$file";
    next unless -f $file;
    warn $file;
    unlink $file if (-M $file > $keep_days);
}

exit(0);
