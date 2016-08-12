#!/usr/bin/env perl 

# generegion_soi.pl

# --------------------------------
# sshu@fruitfly.org
# --------------------------------

use lib $ENV{GMOD_MODULE_PATH};
use FindBin qw($RealBin);
use lib (($ENV{SOI_ROOT}) ||
                     (($INC[0]=~/^\./)?"$RealBin/$INC[0]":"$RealBin/.."));

use Carp;
use strict;

use FileHandle;
use SOI::Adapter;
use SOI::Visitor;

use Getopt::Long;

my $argh = {};
GetOptions($argh,
           "dbname|d=s",
           "outfile|o=s",
           "idfile|file=s",
           "template=s",
           "args|arg=s%",
           "featuretype|type=s",
           "extend|e=s",
           "so_cv_name|so_cv|so=s",
           "help",
          );

if ($argh->{help}) {
    usage();
    exit 0;
}

# set up the database adapter
if (!$argh->{dbname}) {
    print STDERR "You MUST specify a database name; for example -d gadfly3\n\n";
    usage();
    exit 1;
}
my $ad;
eval {
    $ad  =
      SOI::Adapter->new($argh->{dbname});
};
if ($@) {
    print STDERR "There was an error connecting to $argh->dbname}\n\n";
    print STDERR $@;
    exit 1;
}

if ($argh->{so_cv_name}) {
    $ad->SO_cv_name($argh->{so_cv_name});
}

my @cgs = @ARGV;
if ($argh->{template}) {
    my $features = $ad->get_features_by_template($argh->{template}, $argh->{args});
    map{push @cgs, $_->uniquename}@{$features || []};
}
if ($argh->{idfile}) {
    open(R, "<$argh->{idfile}") or die "can not open file: $argh->{idfile}";
    while (<R>) {
        chomp;
        next unless ($_);
        next if (/^\#/);
        my @a = split/\s+/;
        push @cgs, @a;
    }
}
my $out = $argh->{outfile} || ">-";
my $fh = FileHandle->new(">$out");
my $type = $argh->{featuretype} || 'gene';
my $method = "get_features_by_$type";
foreach my $cg (@cgs) {
    my ($range,$genes) =
      $ad->$method($cg, {extend=>0});
    if (!@{$genes || []}) {
        print "NO SUCH FEATURE: $cg\n";
        next;
    }

    #test getting CDS seq
    my ($gene) = grep{$_->uniquename eq $cg}@$genes;
    my @mRNA = grep{$_->type eq 'mRNA'}@{$gene->nodes || []};
    map{SOI::Visitor->make_CDS_feature($_)->to_fasta($fh)}@mRNA;

    next;

    #get around arm residues stored problem for speed
    my $GBs = $ad->get_f({range=>$range}, {feature_types=>'golden_path_region',noauxillaries=>1});
    my $arm = SOI::Feature->new({type=>'chromosome_arm',name=>$range->{src}});
    $arm->nodes($GBs);
    my ($fmin, $fmax) = ($range->{fmin},$range->{fmax});
    my $new_f = $arm->stitch_child_segments($fmin,$fmax, {name=>"$cg-region"});
    $arm->hash->{residues} = "";

    $arm->nodes([$new_f,@{$genes}]);

}


print STDERR "Done!\n";
$ad->close_handle;

sub usage {
    print <<EOM
dump_generegion_soi.pl [-d|dbname <chado DATABASE NAME>] [-extend|e NO OF BASES] [-template <FILE>] [-outfile|o filename to put xml in] [-format <FORMAT>] [-noresults] cg-list

This script will export per-CG xml files. you can specify a list of
CGs on the command line, or you can give it a file of CG ids (just CG
ids, not gene symbols)

If outfile is specified, only a single CG can be exported to the file.

Default format is xml (soi). you can also get chaos xml:

dump_generegion_soi.pl -d chado -format chaos CG6699

you can als get GAME xml:

dump_generegion_soi.pl -d chado -format game CG6699

To get the gene region without evidence:

dump_generegion_soi.pl -d chado -format chaos -noresults CG6699

to use template, here is one example (get genes whose protein has 2 mature_peptides):

dump_generegion_soi.pl -d chado -format chaos -template ../templates/genes_by_child_count.soi -arg ptype=protein -arg ctype=mature_peptide -arg count=2 -arg operator='='


EOM
}






