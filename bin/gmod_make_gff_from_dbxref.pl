#!/usr/bin/env perl 
use strict;
use warnings;

=head1 NAME

gmod_make_gff_from_dbxref.pl - a tool for creating a gff3 file given
a list of dbxrefs and fasta files.

=head1 SYNOPSYS

 % gmod_make_gff_from_dbxref.pl --fasta_dir <directory> --tmp_dir <directory> \
                                <dbxref_list

=head1 COMMAND-LINE OPTIONS

  --fasta_dir          Directory containing fasta files (required)
  --tmp_dir            Temporary directory (default: /tmp)
  --type               SO term to use for created features (default: region)
  --source             Column 2 of the GFF file (default: .)

=head1 DESCRIPTION

This tool takes a list of tab seperated db identifiers and accessions on
the command line (like gmod_extract_dbxref_from_gff.pl would produce)
along with a directory containing fasta files and creates a GFF file.
The script tries several options for identifying the accession in the
fasta description line.  These are the types of things it currently
tries:

=over

=item >mi|5419616|mn|TC130707| 

to get TC130707

=item >gi|34072055|gb|CG180994.1|CG180994

to get CG180994.1

=item >mi|12821100|mn|2_11498(1330441)|

to get 2_11498.

=item >123456

to get 123456 (ie, the entire line, which is the last resort).

=back

If you have a description line that is different from this and would like
help modifying this script to work with your data, please email the 
schema mailing list: gmod-schema@lists.sourceforge.net.  If you modify the
script yourself to work with your data, please also mail the schema mailing
list to report your changes so they can be included.

=head1 AUTHOR

Scott Cain E<lt>cain@cshl.eduE<gt>.

Copyright (c) 2007,2008

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


use Bio::DB::Fasta;
use File::Temp qw/ tempdir tempfile /;
use Getopt::Long;
use File::Copy;
use File::Spec::Functions;

my ( $FASTA_DIR, $TMP_DIR, $TYPE, $SOURCE );

GetOptions (
    "fasta_dir:s"  => \$FASTA_DIR,
    "tmp_dir:s"    => \$TMP_DIR,
    "type:s"       => \$TYPE,
    "source:s"     => \$SOURCE,
);

$TMP_DIR ||= "/tmp";
$TYPE    ||= "region";
$SOURCE  ||= ".";

my %dbxref;
while(<>) {
    chomp;
    my ($db, $acc) = split /\s+/;
    $dbxref{$db}{$acc} = 1;
}

my $tmp_dir = tempdir( CLEANUP => 1, DIR => $TMP_DIR );
my $tmp_fasta = tempfile( DIR => $tmp_dir );
warn "created tempdir $tmp_dir\n";

opendir(DIR, $FASTA_DIR) or die "couldn't open $FASTA_DIR: $!";
my @fasta_files = readdir(DIR);
closedir(DIR);

my @fasta_save;
for my $fasta_file (@fasta_files) {
    next if $fasta_file =~ /^\./;
    $fasta_file = catfile( $FASTA_DIR, $fasta_file);
    warn "Copying $fasta_file to the temp directory\n";
    copy($fasta_file, $tmp_dir) 
        or die "couldn't move $fasta_file to $tmp_dir (a temp dir): $!";    

    my $fasta_db = Bio::DB::Fasta->new($tmp_dir,
                                       -makeid  => \&make_id,
                                       -reindex => 1,);

    for my $db (keys %dbxref) {
        for my $acc (keys %{$dbxref{$db}}) {
            my $seq = $fasta_db->seq($acc);
            if ($seq) {
                my $length = length $seq;
                my $ninth  = "ID=$acc;Name=$acc;Dbxref=$db:$acc";
                print join("\t",$acc,$SOURCE,$TYPE,1,$length,".",".",".",$ninth),"\n";
                $tmp_fasta->print( ">$acc\n$seq\n" );
                delete $dbxref{$db}{$acc};
            }
        }
    }
    my (undef, undef, $filename) = File::Spec->splitpath($fasta_file);
    warn "Finished processing $filename\n";
    unlink "$tmp_dir/$filename";
}
print "##FASTA\n";
seek $tmp_fasta,0,0;
while(<$tmp_fasta>) {
    print;
}

#for my $db (keys %dbxref) {
#    for my $acc (keys %{$dbxref{$db}}) {
#        warn "$db\t$acc\n";
#    }
#}
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

