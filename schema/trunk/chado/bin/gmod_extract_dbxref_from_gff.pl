#!/usr/bin/perl
use strict;
use warnings;
use URI::Escape;

my %dbxref;
while (<>) {
    chomp;
    my @la = split /\t/;
#    last if ($la[0] eq '##FASTA');
    next unless (scalar @la == 9);
    next unless ($la[2] =~ /match/);
    next unless ($la[8] =~ /Dbxref/);
    next unless ($la[8] =~ /Target/);
   
    my @pairs = split /\;/, $la[8]; 

    my ($db,$acc,$target);
    for (@pairs) {
        my @tagvalue = split /\=/;
        if ($tagvalue[0] eq 'Dbxref') {
            ($db, $acc) = split /\:/, $tagvalue[1];
            $db  = uri_unescape($db);
            $acc = uri_unescape($acc);
        }
        elsif ($tagvalue[0] eq 'Target') {
            ($target) = split /\s/, $tagvalue[1];
            $target   = uri_unescape($target);
        }
    }

    next if ($db =~ /BACend/i);
    if ($db && $acc && $target && $acc eq $target) {
        $dbxref{$db}{$acc} = 1;
    }
}

for my $db (keys %dbxref) {
    for my $acc (keys %{$dbxref{$db}}) {
        print "$db $acc\n";
    }
}
