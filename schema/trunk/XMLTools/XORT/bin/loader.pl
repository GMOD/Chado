#!/usr/local/bin/perl

# --------------------------
# loader.pl to load chado xml into chado database
# i.e: loader.pl -d chado_test -f "/users/zhou/work/tmp/AE003828_chadox.xml" -i 0
# ---------------------------

use lib $ENV{CodeBase};
use XORT::Util::GeneralUtil::Properties;
use XORT::Loader::XMLParser;
use Getopt::Std;

#set start time
my $start=time();

my %opt;
getopts('h:d:f:d:i:b:', \%opt) or usage() and exit;

usage() and exit if $opt{h};

#default for i:0
$opt{i}=0 if !($opt{i});


#default for b:0
$opt{b}=0 if !($opt{b});

usage() and exit if (!$opt{d} || !$opt{f});

my $parse_obj=XORT::Loader::XMLParser->new($opt{d}, $opt{f}, $opt{b});
   $parse_obj->load(-is_recovery=>$opt{i});

my $end=time();
print "\n$0 started:", scalar localtime($start),"\n";
print "\n$0   ended:", scalar localtime($end),"\n";


sub usage()
 {
  print "\nusage: $0 [-d database] [-f file] [-i is_recovery]",

    "\n -h              : this (help) message",
    "\n -d              : database",
    "\n -f xml file     : file to be loaded into database",
    "\n -i is_recovery  : 0 for no recovery 1 for recovery",
    "\n -b debug        : 0 for no debug message(default),  1 for debug message",
    "\nexample: $0  -d chado_test -f /users/zhou/work/tmp/AE003828_chadox.xml -i 0 -b 1\n\n";
}
