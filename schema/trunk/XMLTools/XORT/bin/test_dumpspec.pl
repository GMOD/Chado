#!/usr/local/bin/perl

# --------------------------
# test the Dumperspec.pm
# ---------------------------

use lib $ENV{CodeBase};

use XORT::Util::GeneralUtil::Properties;
use XORT::Dumper::DumperSpec;
use XORT::Util::DbUtil::DB;
use XML::DOM;

  my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ("/users/zhou/work/API/XORT/Config/dumpspec_test.xml");


 my $dumpspec_obj=XORT::Dumper::DumperSpec->new(-dbname=>'chado_gadfly4');

my $in_query=sprintf("select feature_relationship_0.subjfeature_id from feature_relationship feature_relationship_0 where feature_relationship_0.objfeature_id=47 and feature_relationship_0.subjfeature_id in \(select feature_1.feature_id from feature feature_1, cvterm cvterm_0 where feature_1.type_id=cvterm_0.cvterm_id and cvterm_0.termname='gene'\)");

$in_query=sprintf("select feature_0.feature_id from feature feature_0 where feature_0.uniquename='GR' and feature_0.feature_id in (select feature_1.feature_id from feature feature_1, cvterm cvterm_0 where feature_1.type_id=cvterm_0.cvterm_id and cvterm_0.termname='gene')");

$in_query=sprintf("select feature_id from feature  where uniquename='GR' and feature_id in (select feature_1.feature_id from feature feature_1, cvterm cvterm_0 where feature_1.type_id=cvterm_0.cvterm_id and cvterm_0.termname='gene')");

#my $out_query=$dumpspec_obj->transform_in_query($in_query);
print "\n\n\nout_query:$out_query";


my @array_arg=("1", "10", "1000", "scaffold dump");

#$dumpspec_obj->replace_dumpspec("/users/zhou/work/API/Config/dumpspec_scaffold.xml", \@array_arg);

#exit(1);

my $nodes=$doc->getElementsByTagName('chado');
for my $i(1..$nodes->getLength()){
        my $node=$nodes->item($i-1);
        print "\nnode name:", $node->getNodeName(), "\tattribute :", $attribute;
    #    print "\napp data for :chado\n", $dumpspec_obj->get_app_data($node);
    #exit(1);
}



my $nodes=$doc->getElementsByTagName('feature');
for my $i(1..$nodes->getLength()){
        my $node=$nodes->item($i-1);
        my $attribute=$node->getAttribute('fn_arg');
           print "\nnode name:", $node->getNodeName(), "\tattribute :", $attribute;
        print "\nsql for node:feature\n", $dumpspec_obj->format_sql_id($node), ":\n";
        last;
      }
exit(1);


my $nodes=$doc->getElementsByTagName('scaffold_feature');
for my $i(1..$nodes->getLength()){
        my $node=$nodes->item($i-1);
        print "\nsql for node:feature\n", $dumpspec_obj->format_sql($node);
        exit(1);

        my $child_nodes=$node->getChildNodes();
        for my $j(1..$child_nodes->getLength()){
             my $child_node=$child_nodes->item($j-1);
            if ($child_node->getNodeType() eq ELEMENT_NODE  && $child_node->getNodeName() eq 'feature_evidence'){
            #  print "\n\nformat_sql: ", $dumpspec_obj->format_sql($node), "\n\n";
             print "\nattribute value for this node:", $dumpspec_obj->get_attribute_value($child_node);
             exit(1);
             my $subquery=$dumpspec_obj->format_sql($child_node);

             print "\nquery of feature_evidence node:\n$subquery";

             my $link_table_node=$dumpspec_obj->get_link_table_node ($node, 'feature_evidence', 'dump');
             if (defined $link_table_node){
                 print "\ncan retrieve the link table ....:", $link_table_node->getNodeName();
                 my $join_foreign_key=$dumpspec_obj->get_join_foreign_key ($link_table_node);
                 if (defined $join_foreign_key){
		   print "\nwe can get join_foreign_key:$join_foreign_key";
		 }
                 my $foreign_key_node=$dumpspec_obj->get_foreign_key_node($link_table_node, $TYPE_TEST);
                 if (defined $foreign_key_node){
                    print "\n we can get foreign key node ....";
		 }
                 else {
                    print "\n we can not get foreign key node ....";
                 }
	     }
             last;

	    }
	  }
    #my $node=$dumpspec_obj->get_nested_node($node, 'feature_relationship:subjfeature_id:feature', 'dump');
  # $dumpspec_obj->get_link_table_node($node, 'featureprop',  'test');
    # $dumpspec_obj->format_sql_id($node);
    # print "\nnode type:", $dumpspec_obj->get_node_type($node);
}


exit(1);

 my $root=$doc->getDocumentElement();
print "\nroot is ", $root->getNodeName();
my $nodes=$root->getChildNodes();
for my $i(1..$nodes->getLength()){
  my $node=$nodes->item($i-1);
  my $node_type=$node->getNodeType();
  my $node_name=$node->getNodeName();
  print "\nnode_type:$node_type";
  if ($node_type ==ELEMENT_NODE && $node_name eq 'feature'){
        print "\nnode name ", $node->getNodeName();
       # print "\nget_id",   $dumpspec_obj->get_id($node);
        print "\n\nformat_sql: ", $dumpspec_obj->format_sql($node), "\n\n";
      #  my $link_table_node=$dumpspec_obj->get_link_table_node($node, 'feature');
      #  print "\nlink table_name:", $link_table_node->getNodeName();
         # last;
   }
}

exit(1);

my $nodes=$doc->getElementsByTagName('feature');
for my $i(1..$nodes->getLength()){
  my $node=$nodes->item($i-1);
  my $node_type=$node->getNodeType();
  my $node_name=$node->getNodeName();
  print "\nnode_type:$node_type";
  if ($node_type ==ELEMENT_NODE){
        my $nest_node=$dumpspec_obj->get_nested_node($node, 'feature_relationship:subjfeature_id:feature');
	if (defined $nest_node){
           print "\nnest_node_name:", $nest_node->getNodeName();
        }
        else {
          print "\nunable to retrieve nest_node base on the path\n";
        }
       # print "\nnode name:", $node->getNodeName();
       # print "\n\nget_join_foreign_key:",   $dumpspec_obj->get_join_foreign_key($node);
       # my $foreign_node=$dumpspec_obj->get_foreign_key_node($node);
       # print "\nforeign_key_node_name:", $foreign_node->getNodeName();
       # my $primary_table_node=$dumpspec_obj->get_primary_table_node($foreign_node);
       # print "\nprimary_table_name:", $primary_table_node->getNodeName();
  }
}

sub get_node(){
  my $node=shift;
  print "\nget_node:", $node->getNodeName();
}
