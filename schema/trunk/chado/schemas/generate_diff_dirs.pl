#!/usr/bin/env perl
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use File::Copy;

my $VERSION = $ARGV[0];

die unless $VERSION;

#make this versions directory
mkdir $VERSION;
copy("../modules/default_schema.sql", $VERSION);
system("svn add $VERSION");

#make the diff dirs and skelton diff files
my @add_to_manifest;
my @dirs = <*>;

for my $dir (@dirs) {
    next unless -d $dir;

    if (looks_like_number($dir)) {
        next if ($dir == $VERSION);
        my $newdir = $dir.'-'.$VERSION;
        mkdir $newdir;
        system("touch $newdir/diff.sql");
        push @add_to_manifest, "schemas/$newdir/diff.sql";
        system("svn add $newdir");
    }
}

#add the created files to the MANIFEST
my $manifest = "../MANIFEST";
open(MANIFEST, ">>", $manifest) or die;
print MANIFEST "#the following added by generate_diff_dirs.pl\n";
for (@add_to_manifest) {
    print MANIFEST "$_\n";
}
close MANIFEST;
