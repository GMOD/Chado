#!/usr/local/bin/perl

foreach $f (@ARGV) {
    open(F,$f) || die("no $f");
    while(<F>) {
        next if /^\#/;
        print `cat $_`;
    }
    close(F);
}
