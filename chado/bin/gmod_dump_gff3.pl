#!/usr/bin/env perl 
use strict;
use warnings;

use DBI;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Getopt::Long;
use URI::Escape;

=head1 NAME
                                                                                
DEPRECATED dump_gff3.pl - Dump gff3 from a chado database.
                                                                                
=head1 SYNOPSIS
                                                                                
  % dump_gff3.pl [--organism human] [--refseq Chr_1] > out.gff
                                                                                
=head1 COMMAND-LINE OPTIONS

WARNING: This script has been DEPRECATED and is no longer supported.
Please use gmod_bulkfiles.pl for getting GFF3 dumps from a Chado database.


If no arguments are provided, dump_gff3.pl will dump all features
for the default organism in the database.  The command line options
are these:

  --organism          specifies the organism for the dump (common name)
  --refseq            reference sequece (eg, chromosome) to dump
  --dbconf            the name of the conf file to use
  --feature_ids       provide the chado feature_ids as attributes

If there is no default organism for the database or one is not
specified on the command line, the program will exit with no output.

=head1 AUTHOR

Scott Cain E<lt>cain@cshl.orgE<gt>

Copyright (c) 2004

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
                                                                                
=cut

print STDERR <<END;

This script is quite old and no longer supported.  Please use 
gmod_bulkfiles.pl for getting GFF out of Chado.

END

exit(0);


my ($ORGANISM,$REFSEQ,$DBCONF,$FEATURE_IDS);

GetOptions(
    'organism:s'  => \$ORGANISM,
    'refseq:s'    => \$REFSEQ,
    'dbconf:s'    => \$DBCONF,
    'feature_ids' => \$FEATURE_IDS,
);

my $gmod_conf = $ENV{'GMOD_ROOT'} ?
                Bio::GMOD::Config->new($ENV{'GMOD_ROOT'}) :
                Bio::GMOD::Config->new();

my $db_conf;
if ($DBCONF) {
    $db_conf = Bio::GMOD::DB::Config->new($gmod_conf,$DBCONF);
} else {
    $db_conf = Bio::GMOD::DB::Config->new($gmod_conf,'default');
}

$ORGANISM ||=$db_conf->organism();

my $dbh = $db_conf->dbh;

my $organism_id = $dbh->prepare("select organism_id from organism
                              where common_name = ?");
$organism_id->execute($ORGANISM);
my $arrayref = $organism_id->fetchrow_arrayref();
$organism_id    = $$arrayref[0];

unless ($organism_id) {
    system( 'pod2text', $0 );
    warn "Organism:$ORGANISM not found in database\n";
    exit 1;
}

my $ref_seq_part = "";
if ($REFSEQ) {
    $ref_seq_part = "and (name = '$REFSEQ' or ref = '$REFSEQ')"; 
}

my $sth = $dbh->prepare("select feature_id,ref,source,type,fstart,fend,
                                score,strand,phase, seqlen,name
                         from gff3view
                         where feature_id > ? and feature_id < ? and
                         organism_id = ? $ref_seq_part
                         order by feature_id") or die $!;

my $attr_query =  $dbh->prepare("select feature_id, type, attribute
                         from gff3atts
                         where feature_id > ? and feature_id < ?
                         order by feature_id, type") or die $!;

my $max_feature_id = $dbh->prepare("select max(feature_id) from feature
                                    where organism_id = ?") or die;
$max_feature_id->execute($organism_id);

$arrayref       = $max_feature_id->fetchrow_arrayref;
$max_feature_id = $$arrayref[0];

my $min_feature_id = $dbh->prepare("select min(feature_id) from feature
                                    where organism_id = ?" ) or die;
$min_feature_id->execute($organism_id);

$arrayref       = $min_feature_id->fetchrow_arrayref;
$min_feature_id = $$arrayref[0] - 1;


my $CHUNK = 1000;
my @ref_seqs;
print "##gff-version   3\n";
for (my $i = $min_feature_id; $i<=$max_feature_id;$i = $i + $CHUNK) {
    my $upper = $i+$CHUNK+1;

    $attr_query->execute($i,$upper,) or die $!;

    my $attstr_hashref = make_attstr_hashref($attr_query);

    $sth->execute($i,$upper,$organism_id) or die $!;

    while (my $hashref = $sth->fetchrow_hashref) {
        my $ref    = $$hashref{ref};
        my $start  = $$hashref{fstart};
        my $end    = $$hashref{fend};
        my $source = $$hashref{source}     || '.';
        my $score  = $$hashref{score}      || '.';
        my $strand; 
        if ($$hashref{strand}) {
            $strand = $$hashref{strand} == 1 ? '+' : '-';
        } else {
            $strand = '.';
        }
        my $phase  = $$hashref{phase}      || '.';
        my $atts   = $$attstr_hashref{$$hashref{feature_id}}
                                           || '.';
        
        unless ($ref) { #must be a reference sequence
            $ref   = $$hashref{name};
            push @ref_seqs, $ref;
            $start = 1;
            $end   = $$hashref{seqlen};
        }

        print join ("\t",($ref,
                          $source,
                          $$hashref{type},
                          $start,
                          $end,
                          $score,
                          $strand,
                          $phase,
                          $atts)),"\n";
    }
}

$sth = $dbh->prepare("select residues from feature 
                      where name=? and residues is not null");
print "##FASTA\n";
foreach my $ref (@ref_seqs) {
    $sth->execute($ref);
    while (my $data = $sth->fetchrow_arrayref) {
        print ">$ref\n";
        my $seq = $$data[0];
        my @seqArr = split //, $seq;
        my $max = 60;
        my $curr = 0;
        foreach my $letter (@seqArr) {
            if($curr < $max) {
                print $letter; $curr++;
            } else {
                $curr = 0;
                print "$letter\n";
            }
        }
    }
    print "\n";
}


sub make_attstr_hashref {
    my $query_handle = shift;

    my $old_id   = 0;
    my $old_type = '';
    my %attstr_hash;
    while (my $hashref = $query_handle->fetchrow_hashref) {
        my $escaped_att = uri_escape($$hashref{attribute}, "^a-zA-Z0-9. :^*$@!+_?-");
        next if ($$hashref{type} eq 'chado_feature_id' and !$FEATURE_IDS);
        if ($old_id    eq $$hashref{feature_id} and
            $old_type  eq $$hashref{type} ) {

            $attstr_hash{$old_id} .= ",$escaped_att"
        }
        elsif ($old_id eq $$hashref{feature_id}) {
            $old_type =$$hashref{type};
            $attstr_hash{$old_id} .= ";$old_type=$escaped_att";
        } 
        else {
            $old_type= $$hashref{type};
            $old_id  = $$hashref{feature_id};
            $attstr_hash{$old_id} = "$old_type=$escaped_att";
        }
    }

    return \%attstr_hash;
} 
