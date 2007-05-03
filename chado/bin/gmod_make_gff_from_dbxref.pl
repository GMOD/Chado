#!/usr/bin/perl
use strict;
use warnings;

use Bio::DB::Fasta;
use File::Temp qw/ tempdir /;
use Getopt::Long;
use File::Copy;
use File::Spec::Functions;

my ( $FASTA_DIR );

GetOptions (
    "fasta_dir"  => \$FASTA_DIR,
);

my %dbxref;
while(<>) {
    chomp;
    my ($db, $acc) = split /\t/;
    $dbxref{$db}{$acc} = 1;
}

my $tmp_dir = tempdir( CLEANUP => 1);
my $tmp_fasta = tempfile();
warn "created tempdir $tmp_dir\n";

opendir(DIR, $FASTA_DIR) or die "couldn't open $FASTA_DIR: $!";
my @fasta_files = readdir(DIR);
closedir(DIR);

my @fasta_save;
for my $fasta_file (@fasta_files) {
    copy($fasta_file, $tmp_dir)
        or die "couldn't move $fasta_file to $tmp_dir (a temp dir): $!";    

    my $db = Bio::DB::Fasta->new($tmp_dir,
                                 -makeid  => \&make_id,
                                 -reindex => 1,);

    for my $db (keys %dbxref) {
        for my $acc (keys %{$dbxref{$db}}) {
            my $seq = $db->seq($acc);
            if ($seq) {
                my $length = length $seq;
                my $ninth  = "ID=$acc;Name=$acc;Dbxref=$db:$acc";
                print join("\t",$acc,".","region",1,$length,".",".",".",$ninth);
                print $tmp_fasta, ">$acc\n$seq\n";
                delete $dbxref{$db}{$acc};
            }
        }
    }
    my (undef, undef, $filename) = splitpath($fasta_file);
    unlink "$tmp_dir/$filename";
}
print "##FASTA\n";
seek $tmp_fasta,0,0;
while(<$tmp_fasta>) {
    print;
}

for my $db (keys %dbxref) {
    for my $acc (keys %{$dbxref{$db}}) {
        warn "$db\t$acc\n";
    }
}
exit(0);

sub make_id {
    my $desc_line = shift;
    if ($desc_line     =~ /\|([^|]+?)\|$/) {
                           #like mi|5419616|mn|TC130707|
        return $1;
    }
    elsif ($desc_line  =~ /gb\|([^|]+)\|/) {                                                               # like gi|34072055|gb|CG180994.1|CG180994
        return $1;
    }
    elsif ($desc_line  =~ /\|([^(]+)\(/) {
                           #like mi|12821100|mn|2_11498(1330441)|
                           #to get 2_11498
        return $1;
    }
    elsif ($desc_line  =~ />(\S+)\s*/) {
        return $1;
    }
    return $desc_line;
}

