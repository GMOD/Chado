#!/usr/local/bin/perl

# --------------------------
# XORTDiff.pl
# usage: XORTDiff.pl -f file1 -s file2 -l all/ref
# ---------------------------

use lib $ENV{CodeBase};

use strict;
use XML::DOM;
use XORT::XML::XORTTreeDiff;
use Getopt::Std;

#set start time
my $start=time();

my $CHECK_LEVEL_ALL="all";
my $CHECK_LEVEL_REF="ref";

my $DIFF_PATERN_DEEP='deep';
my $DIFF_PATERN_SHADOW='shadow';

#set start time
my $start=time();

my %opt;
getopts('h:f:s:l:p:', \%opt) or usage() and exit;

usage() and exit if (!$opt{f} || !$opt{s});

#defalt check level:ref
$opt{l}=$CHECK_LEVEL_REF if (!$opt{l});

#default diff will be shadow(same level diff)
$opt{p}=$DIFF_PATERN_SHADOW if (!$opt{p});

my $parser = new XML::DOM::Parser;

my $doc1 = $parser->parsefile ($opt{f});
my $doc2 = $parser->parsefile ($opt{s});
my $obj=XORT::XML::XORTTreeDiff->new($opt{f}, $opt{s});
my $root1=$doc1->getDocumentElement();
my $nodes1=$root1->getChildNodes();
my $root2=$doc2->getDocumentElement();
my $nodes2=$root2->getChildNodes();

my $subset_f=0;
my $subset_r=0;
if ($opt{p} eq $DIFF_PATERN_DEEP){
    for my $i(1..$nodes1->getLength()){
        my $node1=$nodes1->item($i-1);
        my $node1_type=$node1->getNodeType();
        my $node1_name=$node1->getNodeName();
        if ($node1_type ==ELEMENT_NODE){
           for my $j(1..$nodes2->getLength()){
                my $node2=$nodes2->item($j-1);
                my $node2_type=$node2->getNodeType();
                my $node2_name=$node2->getNodeName();
                if ($node2_type ==ELEMENT_NODE && $node2_name eq $node2_name){
                  my $matched_node=$obj->find_match_node_recursive($node1, $node2);
                  if (defined $matched_node){
                      $obj->diff_nodes($node1, $matched_node);
                      my $subset=$obj->get_subset_flag();
                      $subset_f=$subset if ($subset ==1);
                      last;
	          }
                }
          }
        }
    }
    if ($subset_f==1) {
          print "\nfind match for all objects of $opt{f} from $opt{s}, and also is subset of those in $opt{s}";
     }
    else {
           print "\nunable to find matching for all objects of $opt{f} from $opt{s}";
     }
 }
 else {
    #those two flag to indicate whether really find something
    my $start_f=0;
    my $start_r=0;
    #those two flages to indicate subset relationship between file1 and file2
    my $subset_f=0;
    my $subset_r=0;
    my %hash_xpath_f;
    my %hash_xpath_r;
    for my $i(1..$nodes1->getLength()){
       my $node1=$nodes1->item($i-1);
       my $node1_type=$node1->getNodeType();
       my $node1_name=$node1->getNodeName();
       if ($node1_type ==ELEMENT_NODE){
          my $xpath_node1=$obj->node_xpath($node1);
          $hash_xpath_f{$xpath_node1}=1;
          for my $j(1..$nodes2->getLength()){
              my $node2=$nodes2->item($j-1);
              my $node2_type=$node2->getNodeType();
              my $node2_name=$node2->getNodeName();
              if ($node2_type ==ELEMENT_NODE && $node2_name eq $node2_name){
                 my $matching=$obj->match_nodes($node1, $node2);
                 if ($matching==1) {
                    delete $hash_xpath_f{$xpath_node1};
                    $obj->diff_nodes($node1, $node2, 1,1,$opt{l});
   	         }
              }
          }
       }
    }
    $subset_f=$obj->get_subset_flag();

    $obj=XORT::XML::XORTTreeDiff->new($opt{s}, $opt{f});
    for my $i(1..$nodes2->getLength()){
       my $node2=$nodes2->item($i-1);
       my $node2_type=$node2->getNodeType();
       my $node2_name=$node2->getNodeName();
       if ($node2_type ==ELEMENT_NODE){
          my $xpath_node2=$obj->node_xpath($node2);
          $hash_xpath_r{$xpath_node2}=1;
          for my $j(1..$nodes1->getLength()){
             my $node1=$nodes1->item($j-1);
             my $node1_type=$node1->getNodeType();
             my $node1_name=$node1->getNodeName();
             if ($node1_type ==ELEMENT_NODE && $node2_name eq $node2_name){
                 my $matching=$obj->match_nodes($node1, $node2);
                 if ($matching==1) {
                    delete $hash_xpath_r{$xpath_node2};
                    $obj->diff_nodes($node2, $node1, 1,1,$opt{l});
   	         }
              }
          }
      }
    }
    $subset_r=$obj->get_subset_flag();

    my $f_unmatch=0;
    for my $i(keys %hash_xpath_f){
        $f_unmatch++;
    }
    my $r_unmatch=0;
    for my $i(keys %hash_xpath_r){
        $r_unmatch++;
     }

    if ($subset_f==1 && $subset_r==1 && $f_unmatch==0 && $r_unmatch==0){
         print "\n$opt{f} is equavalent to $opt{s}";
     }
     else {
        print "\n$opt{f} is subset of $opt{s}" if ($subset_f==1 && $f_unmatch==0);
        print "\n$opt{s} is subset of $opt{f}" if ($subset_r==1 && $r_unmatch==0);
        print "\n$opt{s}   diff from  $opt{f}"   if ($f_unmatch!=0 && $r_unmatch!=0);
    }
}

my $end=time();
print "\n$0 started:", scalar localtime($start),"\n";
print "\n$0   ended:", scalar localtime($end),"\n";

sub usage()
 {
  print "\nusage: $0 [-f first_file] [-s second_file] [-i is_recovery]",

    "\n -h              : this (help) message",
    "\n -f xml file     : first file",
    "\n -s xml file     : second file",
    "\n -l level        : all: check all cols of object, ref:only check object identity",
    "\n -p pattern      : shadow: is default, diff object from same depth of tree",
    "\n                   deep: diff root-childrens object of first file with any depth of second file",
    "\nexample: $0   -f /nfs/hershel/export2/zhou/CG14627_cg8_t0_f.xml -s /nfs/hershel/export2/zhou/CG14627_cg8_t2_f.xml\n\n";
}
