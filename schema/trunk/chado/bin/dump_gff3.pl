#!/usr/bin/perl -w
use strict;

use DBI;

my $dbh = DBI->connect("dbi:Pg:dbname=chado;host=localhost;port=5432",'','');

my $sth = $dbh->prepare("select ref,source,type,fstart,fend,
                                score,strand,phase,attributes,
                                seqlen,name
                         from gff3view
                         where feature_id > ? and feature_id < ?
                         order by feature_id");

my $max_feature_id = $dbh->prepare("select max(feature_id) from feature");
$max_feature_id->execute;

my ($arrayref) = $max_feature_id->fetchrow_arrayref;
$max_feature_id = $$arrayref[0];

my $CHUNK = 1000;
my @ref_seqs;
for (my $i = 0; $i<=$max_feature_id;$i = $i + $CHUNK) {
    my $upper = $i+$CHUNK+1;
    warn "start:$i, end:$upper\n";
    $sth->execute($i,$upper);

    while (my $hashref = $sth->fetchrow_hashref) {
        my $ref    = $$hashref{ref};
        my $start  = $$hashref{fstart};
        my $end    = $$hashref{fend};
        my $source = $$hashref{source}     || '.';
        my $score  = $$hashref{score}      || '.';
        my $strand = $$hashref{strand}     || '.';
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
    print ">$ref\n";
    while (my $data = $sth->fetchrow_arrayref) {
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


