#!/usr/local/bin/perl
use strict;
use lib $ENV{CodeBase};
use XORT::Util::GeneralUtil::Properties;
use XORT::Loader::XMLParser;
use Getopt::Std;

my $CodeBase=$ENV{CodeBase};
   $CodeBase="/users/zhou/work/API" if !(defined $ENV{CodeBase});


#global variables
my $chadoXML_dir=$CodeBase."/XORT/Log/";
my $chadoXML_file;
my $java_dir=$CodeBase."/GameChadoConv/classes";
my $validator=$CodeBase."/XORT/bin/validator.pl";
my $loader=$CodeBase."/XORT/bin/loader.pl";

#set start time
my $start=time();

my %opt;
getopts('h:d:f:d:i:b:', \%opt) or usage() and exit;

usage() and exit if $opt{h};
usage() and exit if (!$opt{d} || !$opt{f});

#default for b:0
$opt{b}=0 if (!$opt{b});

if (!(defined $ENV{CodeBase})) {
    print "\nyou need to setenv for CodeBase, where CodeBase is dir which XORT module locate. you can either add  following line to .cshrc file:\n setenv CodeBase /home/pinglei/schema/XMLTools\nor for bash-likes:\n  export CodeBase=/home/pinglei/schema/XMLTools";
   exit(1);
}

#here to convert GAME xml into Chado XML
my @temp = split(/\//,$opt{f});
my $fname = $temp[$#temp];
system("java -classpath $java_dir  GTC $opt{f}  $chadoXML_dir/$fname -g");

        $chadoXML_file=$chadoXML_dir."/".$fname;
      if (-e sprintf($chadoXML_file)) {
       system("$validator  -v 1 -d $opt{d} -f  $chadoXML_dir/$fname");
       #system("/bin/rm $tmp_dir/$fname");
       my $file_log=$CodeBase."/XORT/Log/validator_".$fname.".log";
       if (-e $file_log && -z $file_log){
          system("$loader  -d $opt{d}  -f $chadoXML_dir/$fname -b $opt{b}");
       }
       else {
         print "\nThere are some problem with chado xml data, we still NOT load any data yet, please check log file:\n$file_log\nfor details information";
       }
     }


my $end=time();
print "\n$0 started:", scalar localtime($start),"\n";
print "\n$0   ended:", scalar localtime($end),"\n";


sub usage()
 {
  print "\nusage: $0 [-d database] [-f file] [-b debug]",

    "\n -h              : this (help) message",
    "\n -d              : database",
    "\n -f xml file     : GAME file",
    "\n -b debug        : 0 for no debug message(default),  1 for debug message",
    "\nexample: $0  -d chado_test -f /users/zhou/work/tmp/AE003828_chadox.xml -i 0 -b 1\n\n";
}
