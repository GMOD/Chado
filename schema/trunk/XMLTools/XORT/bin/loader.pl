#!/usr/local/bin/perl

# --------------------------
# loader.pl to load chado xml into chado database
# i.e: loader.pl -d chado_test -f "/users/zhou/work/tmp/AE003828_chadox.xml" -i 0
# ---------------------------

use lib $ENV{CodeBase};
use XORT::Util::GeneralUtil::Properties;
use XORT::Loader::XMLParser;
use Getopt::Std;

my %opt;
getopts('h:d:f:d:i:', \%opt) or usage() and exit;

usage() and exit if $opt{h};

#default for i:0
$opt{i}=0 if !($opt{i});

usage() and exit if (!$opt{d} || !$opt{f});

my $parse_obj=XORT::Loader::XMLParser->new($opt{d}, $opt{f});
   $parse_obj->load(-is_recovery=>$opt{i});

sub usage()
 {
  print "\nusage: $0 [-d database] [-f file] [-i is_recovery]",

    "\n -h              : this (help) message",
    "\n -d              : database",
    "\n -f xml file     : file to be loaded into database",
    "\n -i is_recovery  : 0 for no recovery 1 for recovery",
    "\nexample: $0  -d chado_test -f /users/zhou/work/tmp/AE003828_chadox.xml -i 0\n\n";
}
