#!/usr/local/bin/perl

# --------------------------
# XML_Validator
# ---------------------------

use lib $ENV{CodeBase};

use XORT::Util::GeneralUtil::Properties;
use Getopt::Std;
use strict;

#set start time
my $start=time();

my $VALIDATION_NO_DB=0;
my $VALIDATION_DB=1;

my %opt;
getopts('h:d:v:b:f:', \%opt) or usage() and exit;

usage() and exit if $opt{h};

$opt{v}=$VALIDATION_NO_DB if !($opt{v});

$opt{b}=0 if !($opt{b});

foreach my $key(keys %opt){
 print "\nkey:$key, value:$opt{$key}\n";
}
#exit(1);

usage() and exit if ((!$opt{d} && $opt{v} eq $VALIDATION_DB) || !$opt{f});


my $validate_db_obj;
my $validate_no_db_obj;

if ($opt{v} eq $VALIDATION_DB){
   print "\nuse connection......";
   use XORT::Loader::XMLValidator;
   $validate_db_obj=XORT::Loader::XMLValidator->new($opt{d}, $opt{f}, $opt{b});
   $validate_db_obj->validate_db(-validate_level=>$opt{v});
}
elsif ($opt{v} eq $VALIDATION_NO_DB){
   print "\nnot use connection......";

   use XORT::Loader::XMLValidatorNoDB;
   $validate_no_db_obj=XORT::Loader::XMLValidatorNoDB->new($opt{f},$opt{b});
   $validate_no_db_obj->validate(-validate_level=>$opt{v});
}

my $end=time();
print "\nvalidator started:", scalar localtime($start),"\n";
print "\nvalidator   ended:", scalar localtime($end),"\n";

sub usage()
 {
  print "\nusage: $0 [-d database] [-f file]  [-v validate_level]",

    "\n -h                 : this (help) message",
    "\n -d                 : database",
    "\n -f xml file        : file to be valiated",
    "\n -b debug           : 0: no debug message(default), 1: debug message",
    "\n -v validate_level  : 0 no database connection valiation, 1 for DB connection validation",
    "\n\nexample: $0  -d chado_gadfly7 -f /users/zhou/work/tmp/AE003828_chadox.xml -v 0",
    "\n\nexample: $0  -d chado_test -f /users/zhou/work/tmp/AE003828_chadox.xml -v 1\n\n";
}
