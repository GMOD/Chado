#!/usr/bin/perl -w
use strict;

use DBI;
use Bio::GMOD::Config;
use Bio::GMOD::DB::Config;
use Getopt::Long;

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

my $dbh = $db_conf->dbh;

my $organism_id = $dbh->prepare("select organism_id from organism
                              where common_name = ?");
$organism_id->execute($ORGANISM);
my $arrayref = $organism_id->fetchrow_arrayref();
$organism_id    = $$arrayref[0];
die "couldn't find $ORGANISM in organism table" unless $organism_id;

my $ref_seq_part = "";
if ($REFSEQ) {
    $ref_seq_part = "and (name = '$REFSEQ' or ref = '$REFSEQ')"; 
}

my $sth = $dbh->prepare("select ref,source,type,fstart,fend,
                                score,strand,phase,attributes,
                                seqlen,name
                         from gff3view
                         where feature_id > ? and feature_id < ? and
                         organism_id = ? $ref_seq_part
                         order by feature_id");

my $max_feature_id = $dbh->prepare("select max(feature_id) from feature
                                    where organism_id = ? $ref_seq_part");
$max_feature_id->execute($organism_id);

$arrayref       = $max_feature_id->fetchrow_arrayref;
$max_feature_id = $$arrayref[0];

my $min_feature_id = $dbh->prepare("select min(feature_id) from feature
                                    where organism_id = ? $ref_seq_part" );
$min_feature_id->execute($organism_id);

$arrayref       = $min_feature_id->fetchrow_arrayref;
$min_feature_id = $$arrayref[0];


my $CHUNK = 1000;
my @ref_seqs;
for (my $i = $min_feature_id; $i<=$max_feature_id;$i = $i + $CHUNK) {
    my $upper = $i+$CHUNK+1;
    warn "start:$i, end:$upper\n";
    $sth->execute($i,$upper,$organism_id);

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
        my $atts   = $$hashref{attributes} || '.';
        
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


