#!/usr/local/bin/perl

# --------------------------
# Chado2GAME.pl
# It will dump data from Chado db into a intermediate chadoXML file in  $CodeBase/XORT/Log/, then call GameChadoConv intoa GAME file, then you can load with whatever editor you prefer.
# Here we couple chado dumper with chadoxml convertor, you can de-couple those two, however, remember that, there are some specific format for chado xml in order to be convert into game xml which can be loaded by Apollo properly. if you already have chadoXML, then you can just call GameChadoConv to convert into Game XML by call:
# java classpath $CodeBase/GameChadoConv/classes CTG -D

# where '-D' is followed by a comma delimited list of START,END,NAME, where START is the start bound of NAME with respect to the ARM coordinates in the Chado file, and the END with respect to the ARM
# ---------------------------

use lib $ENV{CodeBase};
use XORT::Util::GeneralUtil::Properties;
use XORT::Dumper::DumperXML;
use Getopt::Std;
use strict;

#global variables
my $chadoXML_dir=$ENV{CodeBase}."/XORT/Log";
my $chadoXML_file;
# cvterm.name for scaffold in chado
my $scaffold_type="golden_path_region";
#cvterm.name for chromosome arm in chado
my $arm_type="chromosome_arm";
#classpath for GameChadoConv
my $java_path=$ENV{CodeBase}."/GameChadoConf/classes";
#set start time
my $start=time();
#dumpspec which for dumping chadoXML which can convert into Game XML readable for Apollox
my $dump_spec;
my %opt;
getopts('h:d:f:s:i:e:b:', \%opt) or usage() and exit;

#default for b:0
$opt{b}=0 if !($opt{b});
#default for b:0
$opt{e}=1 if !($opt{e});

usage() and exit if $opt{h};
usage() and exit if (!$opt{d} || !$opt{f});

#depend on whether dump evidence or not, use different dumpspec
if ($opt{e}==1){
 $dump_spec=$ENV{CodeBase}."/XORT/Config/dumpspec_scaffold_for_apollo.xml";
}
else {
 $dump_spec=$ENV{CodeBase}."/XORT/Config/dumpspec_scaffold_for_apollo_NE.xml";
}


my $CodeBase=$ENV{CodeBase};
if (!(defined $ENV{CodeBase})) {
    print "\nyou need to setenv for CodeBase, where CodeBase is dir which XORT module locate. you can either add  following line to .cshrc file:\n setenv CodeBase /home/pinglei/schema/XMLTools\nor for bash-likes:\n  export CodeBase=/home/pinglei/schema/XMLTools";
   exit(1);
}

#open connection to the chado db
my $dbh_pro=XORT::Util::GeneralUtil::Properties->new($opt{d});
my    %dbh_hash=$dbh_pro->get_dbh_hash();
my  $dbh=XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh->open();

#query to get all necessary information for this scaffold based on the scaffold name
my $stm_scaffold=sprintf("select fl.srcfeature_id, fl.fmin, fl.fmax, f1.uniquename from feature f1, featureloc fl, cvterm c1, cvterm c2, feature f2 where f1.type_id=c1.cvterm_id and f1.feature_id=fl.feature_id and c1.name='%s' and f2.feature_id=fl.srcfeature_id and f2.type_id=c2.cvterm_id and c2.name='%s' and f1.uniquename='%s'", $scaffold_type, $arm_type, $opt{s});

#depend on whether we want to dump evidence, we will use different dumpspec


       my $table = $dbh->get_all_arrayref($stm_scaffold);
       for my $i ( 0 .. $#{$table} ) {
          for my $j ( 0 .. $#{$table->[$i]} ) {
              print "$table->[$i][$j]\t";
          }
         $chadoXML_file=$chadoXML_dir."/".$table->[$i][3].".chado.xml";
         #my $file_g=$apollo_dir."/".$table->[$i][3].".game.xml";

         my $a=$table->[$i][0]." ".$table->[$i][1]." ".$table->[$i][2]." ".$table->[$i][3];
         my $CTG_a=$table->[$i][1].",".$table->[$i][2].",".$table->[$i][3];

         my $xml_obj=XORT::Dumper::DumperXML->new($opt{d}, $opt{b});
         $xml_obj->Generate_XML(-file=>$chadoXML_file,  -format_type=>'no_local_id', -op_type=>'' , -struct_type=>'module', -dump_spec=>$dump_spec,  -app_data=>$a);
         system("java -classpath $java_path  CTG $chadoXML_file $opt{f} -D$CTG_a");
    }
$dbh->close();

my $end=time();
print "\n$0 started:", scalar localtime($start),"\n";
print   "$0   ended:", scalar localtime($end),"\n";


sub usage()
 {
  print "\nusage: $0 [-d database] [-f file] [-s scaffold name]",

    "\n -h                : this (help) message",
    "\n -d                : database",
    "\n -f xml file       : GAME file name",
    "\n -s scaffold name  : 0 for no recovery 1 for recovery",
    "\n -e evidence       : 0 for NO evidence, 1 for evidence(default)",
    "\n -b debug          : 0 for no debug message(default),  1 for debug message",
    "\nexample: $0  -d chado_gadfly9_fogel -f /users/zhou/work/API/XORT/Log/AE003828_game.xml -s AE003828\n\n";
}
