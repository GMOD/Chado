#!/usr/bin/env perl 
use strict;
use warnings;
use Getopt::Long;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;

#Here's the plan:
# - use gmod_dump_gff3.pl to get a gff3 file
# - use bp_pg_bulk_load_gff.pl to create the db

=head1 NAME
                                                                                
$O - Make materialized views of the GFF schema in chado
                                                                                
=head1 SYNOPSIS
                                                                                
  % $O [--organism human] [--refseq Chr_1] 
                                                                                
=head1 COMMAND-LINE OPTIONS

If no arguments are provided, $0 will create GFF schema tables
for the default organism in the database.  The command line options
are these:

  --organism          specifies the organism for the dump (common name)
  --refseq            reference sequece (eg, chromosome) to dump

If there is no default organism for the database or one is not
specified on the command line, the program will exit with no output.

=head1 AUTHOR

Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2005

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
                                                                                
=cut


my ($ORGANISM,$REFSEQ);

GetOptions(
    'organism:s'  => \$ORGANISM,
    'refseq:s'    => \$REFSEQ,
);

my $gmod_conf = $ENV{'GMOD_ROOT'} ?
                Bio::GMOD::Config->new($ENV{'GMOD_ROOT'}) :
                Bio::GMOD::Config->new();
my $db_conf = Bio::GMOD::DB::Config->new($gmod_conf,'default');

$ORGANISM ||=$db_conf->organism();
my $DB = $db_conf->name();

die unless $ORGANISM;

my $dump_string = "gmod_dump_gff3.pl --organism $ORGANISM";
$dump_string .= " --refseq $REFSEQ" if $REFSEQ;

system("$dump_string > tmp.gff3");
system("bp_pg_bulk_load_gff.pl -c -d $DB tmp.gff3");

