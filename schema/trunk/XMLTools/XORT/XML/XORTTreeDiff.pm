package XORT::XML::XORTTreeDiff;
use lib $ENV{CodeBase};
use strict;
use vars qw/$VERSION/;
use XORT::Util::GeneralUtil::Properties;
use XML::Parser;
use XML::DOM;

my $FIRST_XML="first_xml";
my $SECOND_XML="second_xml";
my %LOG_MSG;
my $LOG="log";
my $NOT_IN_FIRST="not in first, but in second";
my $NOT_IN_SECOND="in first, but not in second";
my $MISMATCH="have element in both, but value different";

my $NODE_EQUAL=1;
my $NODE_NOT_EQUAL=0;
my $SCHEMA_GUIDE=1;
my $SCHEMA_GUIDE_NO=0;
my $CHECK_LEVEL_ALL="all";
my $CHECK_LEVEL_REF="ref";
my $CHECK_LEVEL_MIN="min";
my $CHECK_LEVEL_CUSTOM="custom";
# flag attribute to mark those element went through node matching.
my $MATCH_ATTRIBUTE='match';
my $EQUAL_ATTRIBUTE='equal';
my $DEBUG=0;

#variables for customized level
my %hash_exclude_tables; # excluded_table/1
my %hash_exclude_cols;   #hash of hash, first: table_name/hash_ref,  second: excluded_col/1
my $XORTTreeDiffConfig_file=$ENV{CodeBase}."/XORT/Config/XORTTreeDiffConfig.xml";

#this mark the global equal while diff
my $GLOBAL_EQUAL=1;

$VERSION = '0.95';
my %hash_xpath1;
my %hash_xpath2;

#load the ddl information
my %hash_ddl;


sub new {
    #my ($proto, %args) = @_;
    #my $class = ref($proto) || $proto;
    #my $self = \%args;
    my $class=shift;
    my $self={};
     $self->{'file1'}=shift;
     $self->{'file2'}=shift;

     my $pro=XORT::Util::GeneralUtil::Properties->new('ddl');
     %hash_ddl=$pro->get_properties_hash();
     $GLOBAL_EQUAL=1;

    bless ($self, $class);
    return $self;
}

sub read_xml {
    my $self = shift;
    my $p = XML::Parser->new( Style => 'Stream',
                              Pkg   => 'PathFinder',
                              'Non-Expat-Options' => $self,
                              Namespaces => 1);

    my $doc = $_[0] !~ /\n/g && -f $_[0] ? $p->parsefile($_[0]) : $p->parse($_[0]);

    return $doc;
}

sub diff_nodes(){
  my $self=shift;
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $diff_level=shift;
  if ($schema_guide eq $SCHEMA_GUIDE){
     my $pro=XORT::Util::GeneralUtil::Properties->new('ddl');
     %hash_ddl=$pro->get_properties_hash();
  }
  foreach my $key (keys %hash_ddl){
     #print "\n$key:$hash_ddl{$key}";
  }

  #here load all config information for customized comparison
  if ($diff_level eq $CHECK_LEVEL_CUSTOM){
     my $EXCLUDE_TABLE="exclude_table";
     my $EXCLUDE_COL="exclude_col";
     my $parser = new XML::DOM::Parser;
     my $doc = $parser->parsefile ($XORTTreeDiffConfig_file);
     my $root=$doc->getDocumentElement();
     my $nodes1=$root->getChildNodes();
     for my $i(1..$nodes1->getLength()){
       my $node1=$nodes1->item($i-1);
       my $node1_type=$node1->getNodeType();
       my $node1_name=$node1->getNodeName();
       if ($node1_type ==ELEMENT_NODE && $node1_name eq $EXCLUDE_TABLE){
          my $nodes2=$node1->getChildNodes();
          for my $j(1..$nodes2->getLength()){
            my $node2=$nodes2->item($j-1);
            my $node2_type=$node2->getNodeType();
            my $node2_name=$node2->getNodeName();
            if ($node2_type ==ELEMENT_NODE && $node2_name eq 'table'){
               my $table_name=$node2->getFirstChild()->getData();
               $hash_exclude_tables{$table_name}=1 if ($table_name =~/\w/);
               print "\nnot consider those table:$table_name";
            }
          }
       }    # end of exclude_table
       elsif ($node1_type ==ELEMENT_NODE && $node1_name eq $EXCLUDE_COL){
          my $nodes2=$node1->getChildNodes();
          for my $j(1..$nodes2->getLength()){
            my $node2=$nodes2->item($j-1);
            my $node2_type=$node2->getNodeType();
            my $node2_name=$node2->getNodeName();
    
            if ($node2_type ==ELEMENT_NODE && $node2_name eq 'table'){
                my ($table_name, $col_name, %hash_cols);
                my $nodes3=$node2->getChildNodes();
                for my $k (1..$nodes3->getLength()){
                   my $node3=$nodes3->item($k-1);
                   my $node3_type=$node3->getNodeType();
                   my $node3_name=$node3->getNodeName();
                   #print "\nexclude col:$node3_name" if $node3_type==ELEMENT_NODE;
                   if ($node3_type ==ELEMENT_NODE && $node3_name eq 'name'){
                       $table_name=$node3->getFirstChild()->getData();
                   }
                   elsif ($node3_type ==ELEMENT_NODE && $node3_name eq 'col'){
                       $col_name=$node3->getFirstChild()->getData();
                       $hash_cols{$col_name}=1 if ($col_name =~/\w/);
                       #print "\nignore those cols:$col_name  for table:$table_name";
		   }
		 }

               $hash_exclude_cols{$table_name}=\%hash_cols if ($table_name =~/\w/);
            }
          } #end of:for my $j(1..$nodes2->getLength()){
         } # end of EXCLUDE_COL
      }  # end of:for my $i(1..$nodes1->getLength()){
    } #end of:if ($diff_level eq $CHECK_LEVEL_CUSTOM){



# print "\nnode_name:", $node1->getNodeName(), ":node_name2:", $node2->getNodeName();
  &_diff_nodes($node1, $node2, $self->{'file1'}, $self->{'file2'}, $ignore_attribute, $schema_guide, $diff_level);
 # print "\nnode1\n", $node1->toString(), "\nnode2:\n", $node2->toString();
 # _traverse($node1);
  #print "\n\nnode2\n\n";
  #_traverse($node2);

}

# to compare two nodes whether they are equal: for nodes without children element, check value only. 
# ignore_attribute: 1 or 0
sub _diff_nodes(){
  my $node1=shift;
  my $node2=shift;
  my $file1=shift;
  my $file2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;
  #compare_level:ref(unique_key cols)/mini(all not null cols)/all(default)
  if (!(defined $node1) || !(defined $node2) ){
    print "\nnode not defined\n";
    return;
  }

		            #   if ($node1->getNodeName eq 'alignment_evidence' && $node2->getNodeName){
                            #       print "\n\n\nstart to diff evidence table: ....";
                            #       &_traverse_XORT($node1);
                            #       print "\n";
                            #       &_traverse_XORT($node2);
                            #   }


  #print "\ndiff_nodes:", $node1->getNodeName, ":", $node2->getNodeName(),"\n";
  #default compare_level will be 'all'
  $compare_level=$CHECK_LEVEL_ALL if (!$compare_level);
  my $equal=$NODE_NOT_EQUAL;

  if ($node1->getNodeType ==TEXT_NODE && $node2->getNodeType ==TEXT_NODE){
    if ($node1->getParentNode()->getNodeName() eq $node2->getParentNode()->getNodeName()) {
      my $data1=$node1->getData();
      my $data2=$node2->getData();
      if ($data1 eq $data2 || ($data1 !~/\w/ && $data2 !~ /\w/)){
        return 1;
      }
      elsif ($data1 ne $data2 && ($data1 =~/\w/ || $data2 =~ /\w/)) {
        $GLOBAL_EQUAL=0;
        my $xpath_parent_node1=&_node_xpath($node1->getParentNode());
        my $xpath_parent_node2=&_node_xpath($node2->getParentNode());
        print "\nnodes show different at here:\n$xpath_parent_node1\n$xpath_parent_node2\n:$data1<--->$data2:\n";
        &_traverse_XORT($node1->getParentNode()->getParentNode());
        print "\n\n";
        &_traverse_XORT($node2->getParentNode()->getParentNode());
        return 0;
      }
    }
  }
  elsif ($node1->getNodeType() == ELEMENT_NODE && $node2->getNodeType() == ELEMENT_NODE){
      # if different NodeName, then will be NOT_EQUAL
      if ($node1->getNodeName() ne $node2->getNodeName()){
           $equal=$NODE_NOT_EQUAL;
           return $equal;
      }
      else {
           my $nodes_1=$node1->getChildNodes();
           my $nodes_2=$node2->getChildNodes();
           my ($i,$j);
           my %hash_xpath_1;
           for  $i (1..$nodes_1->getLength()){
              my $child_node_1=$nodes_1->item($i-1);
              my $name_child_node1=$child_node_1->getNodeName();
              my $string_cols_node1;
              my $string_cols_node2;
              my %hash_cols_node1;
	      if ($child_node_1->getNodeType() ==ELEMENT_NODE){
                # link table
		if (defined $hash_ddl{$name_child_node1} && defined $hash_ddl{$node1->getNodeName()}){
                     my $node_matched=&_find_match_node($child_node_1, $node2);
                     if (!(defined $node_matched)){
                          $GLOBAL_EQUAL=0;
                          my $xpath_child_node1=&_node_xpath($child_node_1->getParentNode());
                          print "\n\nunable to find the matched object:",  $child_node_1->getNodeName()," of file:$file1 in file:$file2\nxpath:\n$xpath_child_node1\nobject:\n";
                          &_traverse($child_node_1);
                          next;
		     }
		} # end of link table
                #cols or table which parent is foreign key
                else {
                    if ($compare_level eq $CHECK_LEVEL_REF){
                        #e.g node is feature, then check only unique_key cols
            	       if (defined $hash_ddl{$node1->getNodeName()}){
                           $string_cols_node1=$node1->getNodeName()."_unique";
                            my @array_unique_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                            foreach my $value1(@array_unique_key_node1){
                              $hash_cols_node1{$value1}=1;
      		            }
                        }
                        #e.g node is type_id, then then cvterm
                        elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                           $hash_cols_node1{$name_child_node1}=1;
            		  }
            	    }
                    elsif ($compare_level eq $CHECK_LEVEL_CUSTOM){
                        if (defined $hash_ddl{$node1->getNodeName()}){
                             my $hash_temp=&_get_custom_cols($node1->getNodeName());
                             %hash_cols_node1=%$hash_temp;
                             foreach my $key (keys %hash_cols_node1){
                               #  print "\n:$key: for table", $node1->getNodeName();
			     }
			 }
                        #e.g node is type_id, then then cvterm
                        elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                           $hash_cols_node1{$name_child_node1}=1;
            		 }
			
		    }
                    else {
            	       if (defined $hash_ddl{$node1->getNodeName()}){
                           $string_cols_node1=$node1->getNodeName();
                            my @array_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                            foreach my $value1(@array_key_node1){
                              $hash_cols_node1{$value1}=1;
                              #print "\nunique of table",$node1->getNodeName(),":$value1";
            		      }
                        }
                        elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                           $hash_cols_node1{$name_child_node1}=1;
            	        }
            	    }
                   $hash_xpath_1{&_node_xpath($child_node_1)}=1 if (defined $hash_cols_node1{$child_node_1});

                   next if (!(defined $hash_cols_node1{$name_child_node1}))

                }  # NODE is ELEMENT_NODE, but not link table
	      } #end of child1 is  ELEMENT_NODE

              for  $j (1..$nodes_2->getLength()){
                 my $child_node_2=$nodes_2->item($j-1);
                 my %hash_cols_node2;
                 print "\nnode2:", $node2->getNodeName(),":child:", $child_node_2->getNodeName() if ($DEBUG==1);
                 if ($child_node_1->getNodeType !=$child_node_2->getNodeType()){
                      next;
		 }
                 else {
		     if ($child_node_2->getNodeType() ==ELEMENT_NODE){
                        #same node name
                        my  $name_child_node2=$child_node_2->getNodeName();

                        my $string_cols_node2;
		        if ($child_node_1->getNodeName() eq $child_node_2->getNodeName()){
                            #link table
			   if (defined $hash_ddl{$child_node_2->getNodeName()} && defined $hash_ddl{$node2->getNodeName()}){

                                my $match_flag1=$child_node_1->getAttribute($MATCH_ATTRIBUTE);
                                my $match_flag2=$child_node_2->getAttribute($MATCH_ATTRIBUTE);
                                if ($match_flag1==$match_flag2 && $match_flag1=~/\w/){
                                      &_diff_nodes($child_node_1, $child_node_2,$file1, $file2,  $ignore_attribute, $schema_guide, $compare_level);
				}
                                else {
                                    next;
                                }
		  	   }
                           # not link table
                           else {
                               if ($compare_level eq $CHECK_LEVEL_REF){
                                 #node self is table, then get all cols of this table
                            	   if (defined $hash_ddl{$node2->getNodeName()}){
                                       $string_cols_node2=$node2->getNodeName()."_unique";
                                       my @array_unique_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                                       foreach my $value2(@array_unique_key_node2){
                                           $hash_cols_node2{$value2}=1;
                                           # print "\nunique of table:",$node2->getNodeName(),":$value2";
              		               }
                                  }
                                  #node self is not table(e.g, type_id), but child is table, e.g cvterm
                                  elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                                   $hash_cols_node2{$name_child_node2}=1;
                                  }
              	               }
                               elsif ($compare_level eq $CHECK_LEVEL_CUSTOM){
                                  if (defined $hash_ddl{$node2->getNodeName()}){
                                       my $hash_temp=&_get_custom_cols($node2->getNodeName());
                                       %hash_cols_node2=%$hash_temp;
			           }
                                  #e.g node is type_id, then then cvterm
                                  elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                                       $hash_cols_node2{$name_child_node2}=1;
            		           }			
		               }
                               else {
                                   #node self is table, then get all cols of this table
              		           if (defined $hash_ddl{$node2->getNodeName()}){
                                       $string_cols_node2=$node2->getNodeName();
                                       my @array_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                                       foreach my $value2(@array_key_node2){
                                             $hash_cols_node2{$value2}=1;
                                             # print "\nunique of table:",$node2->getNodeName(),":$value2";
              		               }
                                   }
                                   #node self is not table(e.g, type_id), but child is table, e.g cvterm
                                   elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                                       $hash_cols_node2{$name_child_node2}=1;
              		           }
              	               }
                               if (defined $hash_cols_node2{$name_child_node2}){
                                      delete $hash_xpath_1{&_node_xpath($child_node_1)};
                                      &_diff_nodes($child_node_1, $child_node_2, $file1, $file2, $ignore_attribute, $schema_guide, $compare_level);
			       }
                               else {
                                  next;
                               }
                           } # end of: not link table
		       } #end of:child1 and child2 same NAME, same TYPE
                       #different node name
                       else {
                            next;
                       }
		     }
                     else {
                         &_diff_nodes($child_node_1, $child_node_2, $file1, $file2, $ignore_attribute, $schema_guide, $compare_level) if ($child_node_1->getData()=~/\w/ && $child_node_2->getData() =~/\w/);
                     }
                 } # end of: child1 and child2 have same NODE TYPE


	      }  #end of for  $j (1..$nodes_2->getLength()){ forwared direction


	   } # end of: for  $i (1..$nodes_1->getLength()){ forwared direct
	   foreach my $key (%hash_xpath_1){
	       if ($key !=1){
                  print "\nunable to find this object of $file1 in $file2:\n$key\n";
                  my $node_missed=&_get_node_by_xpath($node1, $key);
                  &traverse($node_missed) if (defined $node_missed);
	       }
	   }

      }  #end of:both ELEMENT_NODE, and same name
  } # end of both node1 and node2 are ELEMENT_NODE

 return $equal;
}


sub _XORTDiff(){
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $diff_level=shift;


#  print "\nnode_name:", $node1->getNodeName(), ":node_name2:", $node2->getNodeName(), "\n";;
  if (!(defined $node1) || !(defined $node2)){
      return;
  }

  my $nodes_1=$node1->getChildNodes();
  my $nodes_2=$node2->getChildNodes();
  my ($child_node_1, $child_node_2);
  my ($i,$j);
   #      print "\nnode number1:", $nodes_1->getLength(), "\nnode number2:", $nodes_2->getLength(), "\n";
  if ($node1->getNodeName ne $node2->getNodeName){
       return;
  }
  else {
          my %hash_node1;
          my %hash_node2;
          my $length1=$nodes_1->getLength();
          for  $i (1..$length1){
             $child_node_1=$nodes_1->item($i-1);
            my $length2=$nodes_2->getLength();
	    if (defined $child_node_1){
              for  $j (1..$length2){
                 $child_node_2=$nodes_2->item($j-1);
                my $equal_temp;
                my $match_flag=&_match_nodes($child_node_1, $child_node_2);
	        if (defined $child_node_2){
                  $equal_temp=&_equal_nodes($child_node_1, $child_node_2, $ignore_attribute,$schema_guide, $diff_level);
                  #print "\n\nequal:$equal_temp:\n", "node1:", $child_node_1->getNodeName,"\n",$child_node_1->toString(), "\nnode2:", $child_node_2->getNodeName(), "\n", $child_node_2->toString(), "\n";
                  #print "\n\nequal:$equal_temp:\n", "node1:", $child_node_1->getNodeName, "\nnode2:", $child_node_2->getNodeName(), "\n";
                  if ($equal_temp ==$NODE_EQUAL && ($child_node_1->getNodeType ==ELEMENT_NODE)){

                    #  my $removed_node1=$node1->removeChild ($child_node_1);
                    #  my $removed_node2=$node2->removeChild ($child_node_2);
                    #  print "\nremove same node:\n", $removed_node1->toString(), "\n\n";
                    my $random1=int(rand(10000000));
                    my $random2=int(rand(10000000));
                    $child_node_1->setAttribute ('deleted',1);
                    $child_node_2->setAttribute ('deleted',1);
                    $hash_node1{$random1}=$child_node_1;

                    $hash_node2{$random2}=$child_node_2;


                    last;
		   }
                   elsif ($child_node_1->getNodeName eq $child_node_2->getNodeName()){
                     #&_diff_node($child_node_1, $child_node_2);
	  	   }
                }
	       }
            }
	 }

        for my $value1(keys %hash_node1){
           print "\nremove child1:$value1";
           print "\nxpath:\n", &_node_xpath($hash_node1{$value1});
           print "\n\n\nrandom1:$value1:\n", $child_node_1->toString(),"\n";
          # $node1->removeChild ($hash_node1{$value1});
        }
        for my $value2(keys %hash_node2){
           print "\nremove child2:$value2";
           print "\nxpath:\n", &_node_xpath($hash_node2{$value2});
           print "\n\n\nrandom2:$value2:\n", $child_node_2->toString(),"\n";
          # $node2->removeChild ($hash_node2{$value2});
        }
        undef %hash_node1;
        undef %hash_node2;

         #if same child_node(name) left in both node, and both only have ONE, then diff those two
         $nodes_1=$node1->getChildNodes();
         $nodes_2=$node2->getChildNodes();
        # print "\nleft node number1:", $nodes_1->getLength(), "\nleft node number2:", $nodes_2->getLength(), "\n";
          for  $i (1..$nodes_1->getLength()){
            my $child_node_1=$nodes_1->item($i-1);
            my $length2=$nodes_2->getLength();
	    if ( $child_node_1->getNodeType==ELEMENT_NODE){
              # print "\n\n", "node1:", $child_node_1->getNodeName,"\n",$child_node_1->toString();
              for  $j (1..$length2){
                my $child_node_2=$nodes_2->item($j-1);
                my $equal_temp1;
	        if ($child_node_2->getNodeType==ELEMENT_NODE){
		  if ($child_node_1->getNodeName() eq $child_node_2->getNodeName()){
                      # my $no_node1=$node1->getElementsByTagName($child_node_1->getNodeName(),0)->getLength();
                      # my $no_node2=$node2->getElementsByTagName($child_node_2->getNodeName(),0)->getLength();
                       my $no_node1=&_number_child_node_with_same_name($node1, $child_node_1 );
                       my $no_node2=&_number_child_node_with_same_name($node2, $child_node_2 );
                       print "\n", $child_node_1->getNodeName(), ":$no_node1:", $child_node_1->getNodeName(), ":$no_node2\n";
                       if ($no_node1==1 && $no_node2==1){
                             &_diff_node($child_node_1, $child_node_2, $ignore_attribute, $schema_guide, $diff_level);
                       }
		  }
                }
	       }
            }
        }
     }

  return;
}


sub get_subset_flag(){
  my $self=shift;
  return $GLOBAL_EQUAL;
}

sub reset_subset_flag(){
  my $self=shift;
  $GLOBAL_EQUAL=1;
}

#in: node1, node2
# return: number of elements in CHILDREN of node1 with the same name as node2
sub _number_child_node_with_same_name(){
   my $node1=shift;
   my $node2=shift;
   my $no=0;

   if (!(defined $node1) ||!(defined $node2)){
     return $no;
   }
   my $nodes_1=$node1->getChildNodes();
   for my $i(1..$nodes_1->getLength()){
     if ($nodes_1->item($i-1)->getNodeName() eq $node2->getNodeName()){
              $no++ if  (($nodes_1->item($i-1)->getAttribute('deleted') !=1) && $node2->getAttribute('deleted')!=1);

     }
   }

  return $no;
}


sub equal_nodes(){
  my $self=shift;
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;

  my $result=&_equal_nodes($node1, $node2,$ignore_attribute,$schema_guide, $compare_level );
  #&_traverse($node1);
  print "\n\n\n";
  #&_traverse($node2);
  return $result;
}

# to compare two nodes whether they are equal: for nodes without children element, check value only. 
# ignore_attribute: 1 or 0
sub _equal_nodes(){
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;
  #compare_level:ref(unique_key cols)/mini(all not null cols)/all(default)

  if (!(defined $node1) || !(defined $node2) ){
    print "\nnode not defined\n";
    return;
  }


#default compare_level will be 'all'
 $compare_level=$CHECK_LEVEL_ALL if (!$compare_level);

  my $equal=$NODE_NOT_EQUAL;

  my ($name_child_node1, $name_child_node2);
  if ($node1->getNodeType ==TEXT_NODE && $node2->getNodeType ==TEXT_NODE){
     my $data1=$node1->getData();
     my $data2=$node2->getData();
     #print "\ndata1:$data1:data2:$data2:\n";
     if ($data1 eq $data2 ||($data1 !~/\w/ && $data2 !~ /\w/)){
     #if ($data1 eq $data2){
        return 1;
     }
     else {
        my $xpath_parent_node1=&_node_xpath($node1->getParentNode());
        my $xpath_parent_node2=&_node_xpath($node2->getParentNode());
        print "\nnodes show different at here:\n$xpath_parent_node1\n$xpath_parent_node1\n";
        return 0;
     }
  }
  elsif ($node1->getNodeType() == ELEMENT_NODE && $node2->getNodeType() == ELEMENT_NODE){

      # if different NodeName, then will be NOT_EQUAL
      if ($node1->getNodeName() ne $node2->getNodeName()){
         $equal=0;
        return $equal;
      }

      my $nodes_1=$node1->getChildNodes();
      my $nodes_2=$node2->getChildNodes();

          #need to compare both directions
          my $equal_f=$NODE_EQUAL;
          my $equal_r=$NODE_EQUAL;
          my ($i,$j);

          #print "\ncheck those two nodes now:\nnode_name1:", $node1->getNodeName, "\nnode_name2:", $node2->getNodeName(), "\n";
          for  $i (1..$nodes_1->getLength()){
              my $child_node_1=$nodes_1->item($i-1);
              $name_child_node1=$child_node_1->getNodeName();
              my $string_cols_node1;
              my $string_cols_node2;
              my %hash_cols_node1;
              my %hash_xpath_f;
              if ($compare_level eq $CHECK_LEVEL_REF){
                  #e.g node is feature, then check only unique_key cols
		  if (defined $hash_ddl{$node1->getNodeName()}){
                     $string_cols_node1=$node1->getNodeName()."_unique";
                      my @array_unique_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                      foreach my $value1(@array_unique_key_node1){
                        $hash_cols_node1{$value1}=1;
                        #print "\nunique of table",$node1->getNodeName(),":$value1";
		      }
                  }
                  #e.g node is type_id, then then cvterm
                  elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                     $hash_cols_node1{$name_child_node1}=1;
		  }
	      }
              else {
		  if (defined $hash_ddl{$node1->getNodeName()}){
                     $string_cols_node1=$node1->getNodeName();
                      my @array_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                      foreach my $value1(@array_key_node1){
                        $hash_cols_node1{$value1}=1;
                        #print "\nunique of table",$node1->getNodeName(),":$value1";
		      }
                  }
                  elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                     $hash_cols_node1{$name_child_node1}=1;
		  }
	      }

              # check whether child_node1 have a matching node in node2
              if ($child_node_1->getNodeType()==ELEMENT_NODE && (defined $hash_cols_node1{$child_node_1->getNodeName()} || defined $hash_ddl{$child_node_1->getNodeName()})){
                   print "\nfind match of:", $child_node_1->getNodeName(), "\n in node:", $node2->getNodeName() if ($DEBUG==1);
                   my $node_matched=&_find_match_node($child_node_1, $node2);
                   if (!(defined $node_matched)){
                     my $xpath_child_node1=&_node_xpath($child_node_1->getParentNode());
                     print "\n\nunable to find the following matching node of file 1:", $child_node_1->getNodeName()," in file 2\n$xpath_child_node1\n";
                     &_traverse($child_node_1);
                     $child_node_1->setAttribute ($MATCH_ATTRIBUTE, '-1');
                     $equal_f=$NODE_NOT_EQUAL;
                     last;
		   }
		 }

              my $equal_sub_f=$NODE_NOT_EQUAL;
              for  $j (1..$nodes_2->getLength()){
                 my $child_node_2=$nodes_2->item($j-1);
                 $name_child_node2=$child_node_2->getNodeName();
                 #print "\nforwared:",$node1->getNodeName, "/name_child_node1:$name_child_node1:", $node2->getNodeName,"/name_child_node2:$name_child_node2";
                 my %hash_cols_node2;
                 if ($compare_level eq $CHECK_LEVEL_REF){
                   #node self is table, then get all cols of this table
		   if (defined $hash_ddl{$node2->getNodeName()}){
                     $string_cols_node2=$node2->getNodeName()."_unique";
                      my @array_unique_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                      foreach my $value2(@array_unique_key_node2){
                        $hash_cols_node2{$value2}=1;
                       # print "\nunique of table:",$node2->getNodeName(),":$value2";
		      }
                   }
                   #node self is not table(e.g, type_id), but child is table, e.g cvterm
                   elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                     $hash_cols_node2{$name_child_node2}=1;
		   }
	         }
                 else {
                   #node self is table, then get all cols of this table
		   if (defined $hash_ddl{$node2->getNodeName()}){
                     $string_cols_node2=$node2->getNodeName();
                      my @array_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                      foreach my $value2(@array_key_node2){
                        $hash_cols_node2{$value2}=1;
                       # print "\nunique of table:",$node2->getNodeName(),":$value2";
		      }
                   }
                   #node self is not table(e.g, type_id), but child is table, e.g cvterm
                   elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                     $hash_cols_node2{$name_child_node2}=1;
		   }
	         }
                #print "\nforward compare node:$name_child_node1:$name_child_node2\n", &_node_xpath($child_node_1), "\n",&_node_xpath($child_node_2), "\n" ;
                my $equal_temp;
                #compare the cols(e.g type_id) and table of foreign key table(e.g cvterm of type_id)
                if ((defined $hash_cols_node1{$name_child_node1} && defined $hash_cols_node2{$name_child_node2}) && $name_child_node1 eq $name_child_node2 ){
                  #print "\nrecursively compare subelement:",$node1->getNodeName(),"/$name_child_node1 with ", $node2->getNodeName(), "/$name_child_node2";
                  $equal_temp=&_equal_nodes($child_node_1, $child_node_2, $ignore_attribute, $schema_guide, $compare_level);
                  $equal_sub_f=$equal_temp;
                  last;
                }
                #compare the link table
		elsif (!(defined $hash_cols_node1{$name_child_node1} || defined $hash_cols_node2{$name_child_node2}) && (defined $hash_ddl{$name_child_node1} && defined $hash_ddl{$name_child_node2} ) ){

                   my $xpath_child_node_1=&_node_xpath($child_node_1);
                   #print "\n\ncompare link table:\n$xpath_child_node_1", "\n", &_node_xpath($child_node_2);
                   $hash_xpath_f{$xpath_child_node_1}=1;
                   my  $match_link_table=0;
                   if ($name_child_node1 eq $name_child_node2){
                      #use a match flag to void repeat node matching, which is very expensive. assign a random number
                      my $match_flag1=$child_node_1->getAttribute ($MATCH_ATTRIBUTE);
                      my $match_flag2=$child_node_2->getAttribute ($MATCH_ATTRIBUTE);
                      #print "\nmatch_flag1:$match_flag1:match_flag2:$match_flag2:" if ($match_flag1 !~/\w/);
                      if ($match_flag1 =~/\w/  && $match_flag1==$match_flag2){
                            $match_link_table=1;
		      }
                      elsif ($match_flag1 =~/\w/  && $match_flag2 =~/\w/  && $match_flag1!=$match_flag2){
                            $match_link_table=0;
		      }
                      elsif ($match_flag1 !~/\w/ || $match_flag2 !~/\w/){
                        $match_link_table= &_match_nodes($child_node_1, $child_node_2, $ignore_attribute);
                        my $random1=int(rand(10000000));
                        my $random2=int(rand(10000000));
                        #print "\nforward match:$name_child_node1:$name_child_node2:match_link_table:$match_link_table:$random1:$random2";
                        if ($match_link_table==1){
			   if ($match_flag1=~/\w/){
                             $random1=$match_flag1;
			   }
                           elsif ($match_flag2=~/\w/){
                             $random1=$match_flag2;
			   }
                           $child_node_1->setAttribute ($MATCH_ATTRIBUTE, $random1);
                           $child_node_2->setAttribute ($MATCH_ATTRIBUTE, $random1);
			}
                        else {
			   if ($match_flag1=~/\w/){
                             $random1=$match_flag1;
			   }
                           if ($match_flag2=~/\w/){
                             $random2=$match_flag2;
			   }
                            $child_node_1->setAttribute ($MATCH_ATTRIBUTE, $random1);
                            $child_node_2->setAttribute ($MATCH_ATTRIBUTE, $random2);
                        }
                      }
                     #print "\nmatch_link_table:$match_link_table:";
                     if ($match_link_table ==1){
                         #use a equal flag to void repeat node equaling. 
                        my $equal_flag1=$child_node_1->getAttribute($EQUAL_ATTRIBUTE);
                        my $equal_flag2=$child_node_2->getAttribute($EQUAL_ATTRIBUTE);
                        my $random3=int(rand(10000000));
                        my $random4=int(rand(10000000));

                        if ( $match_flag1=~/\w/ &&  $match_flag2=~/\w/ && $match_flag1==$match_flag2 && $compare_level eq $CHECK_LEVEL_REF){
                           $equal_sub_f=$NODE_EQUAL;
                           $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                           $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                        }
                        elsif ( $match_flag1=~/\w/ &&  $match_flag2=~/\w/ && $match_flag1!=$match_flag2){
                           $equal_sub_f=$NODE_NOT_EQUAL;
                           $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                           $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random4);
                        }
                        elsif ( $equal_flag1=~/\w/ &&  $equal_flag2=~/\w/ && $equal_flag1==$equal_flag2) {
                           $equal_sub_f=$NODE_EQUAL;
                        }
                        elsif($equal_flag1=~/\w/ &&  $equal_flag2=~/\w/ && $equal_flag1 !=$equal_flag2){
                           $equal_sub_f=$NODE_NOT_EQUAL;
			}
                        else{
                           $equal_temp=&_equal_nodes($child_node_1, $child_node_2, $ignore_attribute, $schema_guide, $compare_level);
                           $equal_sub_f=$equal_temp;
                           if ($equal_temp==$NODE_EQUAL){
                             $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                             $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random3);
			   }
                           else {
                             $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                             $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random4);
                           }
                        }
                        delete $hash_xpath_f{$xpath_child_node_1};
                        last;
		      }
                     else {
                        $equal_sub_f=$NODE_EQUAL;
                     }
		    }
                   else {
                      $equal_sub_f=$NODE_EQUAL;
                   } 
		}
		elsif ( ($child_node_1->getNodeType==TEXT_NODE && $child_node_2->getNodeType==TEXT_NODE) && $node1->getNodeName eq $node2->getNodeName){
                 #print "\nrecursively compare subelement:",$node1->getNodeName(),"/$name_child_node1 with ", $node2->getNodeName(), "/$name_child_node2";
                 $equal_temp=&_equal_nodes($child_node_1, $child_node_2, $ignore_attribute, $schema_guide, $compare_level);

                 $equal_sub_f=$equal_temp;
                 last;
		}
                else {
                   $equal_sub_f=$NODE_EQUAL;
                }
	       }

              #not equal: either unique keys or link table not MATCH
              my $no=0;
              foreach my $value (keys %hash_xpath_f){
		if ($value =~/\w/){
                   $no++;
                   print "\ncan't find matching node of first file in second file:\n$value\n\n";
                   #_traverse($child_node_1);
                   delete $hash_xpath_f{$value};
		}
	      }
              undef %hash_xpath_f;
              if ($equal_sub_f ==$NODE_NOT_EQUAL || $no>0){
                  $equal_f=$NODE_NOT_EQUAL;
                  last;
	      }
	    }

         #compare reverse direction
         for  $i (1..$nodes_2->getLength()){
              my $child_node_2=$nodes_2->item($i-1);
              $name_child_node2=$child_node_2->getNodeName();
              my $string_cols_node1;
              my $string_cols_node2;
              my %hash_cols_node2;
              my %hash_xpath_r;
              if ($compare_level eq $CHECK_LEVEL_REF){
		  if (defined $hash_ddl{$node2->getNodeName()}){
                     $string_cols_node1=$node2->getNodeName()."_unique";
                      my @array_unique_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                      foreach my $value2(@array_unique_key_node2){
                        $hash_cols_node2{$value2}=1;
                       # print "\nunique of table:",$node2->getNodeName(),":$value2";
		      }
                  }
                  elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                     $hash_cols_node2{$name_child_node2}=1;
		  }
	      }
              else {
		  if (defined $hash_ddl{$node2->getNodeName()}){
                     $string_cols_node1=$node2->getNodeName();
                      my @array_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                      foreach my $value2(@array_key_node2){
                        $hash_cols_node2{$value2}=1;
                       # print "\nunique of table:",$node2->getNodeName(),":$value2";
		      }
                  }
                  elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                     $hash_cols_node2{$name_child_node2}=1;
		  }
	      }

              # check whether child_node2 have a matching node in node1
              if ($child_node_2->getNodeType()==ELEMENT_NODE && (defined $hash_cols_node2{$child_node_2->getNodeName()} || defined $hash_ddl{$child_node_2->getNodeName()})){
                   print "\nfind match of:", $child_node_2->getNodeName(), "\n in node:", $node2->getNodeName() if ($DEBUG==1);
                   my $node_matched=&_find_match_node($child_node_2, $node1);
                   if (!(defined $node_matched)){
                     my $xpath_child_node2=&_node_xpath($child_node_2->getParentNode());
                     print "\n\nunable to find the following matching node of file 2:", $child_node_2->getNodeName()," in file 1\n$xpath_child_node2\n";
                     &_traverse($child_node_2);
                     $equal_r=$NODE_NOT_EQUAL;
                     $child_node_2->setAttribute ($MATCH_ATTRIBUTE, '-1');
                     last;
		   }
		 }


              #reverse direction check
              my $equal_sub_r=$NODE_NOT_EQUAL;
              for  $j (1..$nodes_1->getLength()){
                 my $child_node_1=$nodes_1->item($j-1);
                 $name_child_node1=$child_node_1->getNodeName();
                 my %hash_cols_node1;
                 if ($compare_level eq $CHECK_LEVEL_REF){
		   if (defined $hash_ddl{$node1->getNodeName()}){
                     $string_cols_node1=$node1->getNodeName()."_unique";
                      my @array_unique_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                      foreach my $value1(@array_unique_key_node1){
                        $hash_cols_node1{$value1}=1;
                       # print "\nunique of table:",$node1->getNodeName(),":$value1";
		      }
                   }
                   elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                     $hash_cols_node1{$name_child_node1}=1;
		   }
	         }
                 else {
		   if (defined $hash_ddl{$node1->getNodeName()}){
                     $string_cols_node1=$node1->getNodeName();
                      my @array_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                      foreach my $value1(@array_key_node1){
                        $hash_cols_node1{$value1}=1;
                       # print "\nunique of table:",$node1->getNodeName(),":$value1";
		      }
                   }
                   elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                     $hash_cols_node1{$name_child_node1}=1;
		   }
	         }
                 #print "\nreverse compare node:$name_child_node1:$name_child_node2\n", &_node_xpath($child_node_1), "\n",&_node_xpath($child_node_2), "\n" ;
                 my $equal_temp;
                 #compare the cols(e.g type_id) and table of foreign key table(e.g cvterm of type_id)
                 if ((defined $hash_cols_node1{$name_child_node1} && defined $hash_cols_node2{$name_child_node2}) && $name_child_node1 eq $name_child_node2 ){
                   #print "\nrecursively compare subelement:",$node1->getNodeName(),"/$name_child_node1 with ", $node2->getNodeName(), "/$name_child_node2";
                   $equal_temp=&_equal_nodes($child_node_2, $child_node_1, $ignore_attribute, $schema_guide, $compare_level);
                   $equal_sub_r=$equal_temp;
                   last;
                 }
                 #compare the link table
	         elsif (!(defined $hash_cols_node1{$name_child_node1} || defined $hash_cols_node2{$name_child_node2}) && (defined $hash_ddl{$name_child_node1} && defined $hash_ddl{$name_child_node2} ) ){
                   my $xpath_child_node_2=&_node_xpath($child_node_2);
                   $hash_xpath_r{$xpath_child_node_2}=1;
                   my  $match_link_table=0;
                   if ($name_child_node1 eq $name_child_node2){
                      #use a match flag to void repeat node matching, which is very expensive. assign a random number
                      my $match_flag1=$child_node_1->getAttribute ($MATCH_ATTRIBUTE);
                      my $match_flag2=$child_node_2->getAttribute ($MATCH_ATTRIBUTE);
                      if ( $match_flag1 =~/\w/ &&  $match_flag1==$match_flag2){
                            $match_link_table=1;
		      }
                      elsif ( $match_flag1 =~/\w/ && $match_flag2 =~/\w/ &&  $match_flag1!=$match_flag2){
                            $match_link_table=0;
		      }
                      elsif ($match_flag1 !~/\w/ &&  $match_flag2 !~/\w/){
                        $match_link_table= &_match_nodes($child_node_2, $child_node_1, $ignore_attribute);
                        my $random1=int(rand(10000000));
                        my $random2=int(rand(10000000));
                        #print "\nreverse  match:$name_child_node1:$name_child_node2:match_link_table:$match_link_table:$random1:$random2";
                        if ($match_link_table==1){
                            $child_node_1->setAttribute ($MATCH_ATTRIBUTE, $random1);
                            $child_node_2->setAttribute ($MATCH_ATTRIBUTE, $random1);
			}
                        else {
                            $child_node_1->setAttribute ($MATCH_ATTRIBUTE, $random1);
                            $child_node_2->setAttribute ($MATCH_ATTRIBUTE, $random2);
                        }
                      }
                     if ($match_link_table ==1){
                         #use a equal flag to void repeat node equaling. 
                        my $equal_flag1=$child_node_1->getAttribute($EQUAL_ATTRIBUTE);
                        my $equal_flag2=$child_node_2->getAttribute($EQUAL_ATTRIBUTE);
                        my $random3=int(rand(10000000));
                        my $random4=int(rand(10000000));
                        if ($match_flag1 =~/\w/ && $match_flag2 =~/\w/ && $match_flag1==$match_flag2 && $compare_level eq $CHECK_LEVEL_REF){
                           $equal_sub_r=$NODE_EQUAL;
                           $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                           $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                        }
                        elsif ($match_flag1 =~/\w/ && $match_flag2 =~/\w/ && $match_flag1!=$match_flag2){
                           $equal_sub_r=$NODE_NOT_EQUAL;
                           $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                           $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random4);
                        }
                        elsif ($equal_flag1=~/\w/ && $equal_flag2=~/\w/ && $equal_flag1==$equal_flag2) {
                           $equal_sub_r=$NODE_EQUAL;
                        }
                        elsif($equal_flag1=~/\w/ &&  $equal_flag2=~/\w/ && $equal_flag1 !=$equal_flag2){
                           $equal_sub_r=$NODE_NOT_EQUAL;
			}
                        else {
                           $equal_temp=&_equal_nodes($child_node_2, $child_node_1, $ignore_attribute, $schema_guide, $compare_level);
                           $equal_sub_r=$equal_temp;
                           if ($equal_temp==$NODE_EQUAL){
                             $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                             $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random3);
			   }
                           else {
                             $child_node_1->setAttribute ($EQUAL_ATTRIBUTE, $random3);
                             $child_node_2->setAttribute ($EQUAL_ATTRIBUTE, $random4);
                           }
                        }
                        delete $hash_xpath_r{$xpath_child_node_2};
                        last;
		      }
                     else {
                        $equal_sub_r=$NODE_EQUAL;
                     }
		    }
                   else {
                      $equal_sub_r=$NODE_EQUAL;
                   }
	 	 }
	 	 elsif ( ($child_node_1->getNodeType==TEXT_NODE && $child_node_2->getNodeType==TEXT_NODE) && $node1->getNodeName eq $node2->getNodeName){
                   #print "\nrecursively compare subelement:",$node1->getNodeName(),"/$name_child_node1 with ", $node2->getNodeName(), "/$name_child_node2";
                   $equal_temp=&_equal_nodes($child_node_1, $child_node_2, $ignore_attribute, $schema_guide, $compare_level);

                   $equal_sub_r=$equal_temp;
                   last;
	 	 }
                 else {
                   $equal_sub_r=$NODE_EQUAL;
                 }
	       }

              #not equal: either unique keys or link table not MATCH
              my $no=0;
              foreach my $value (keys %hash_xpath_r){
		if ($value =~/\w/){
                   $no++;
                   print "\ncan't find matching node of second file in first file:\n$value\n\n";
                   #_traverse($child_node_2);
                   delete $hash_xpath_r{$value};
		}
	      }
              undef %hash_xpath_r;
              if ($equal_sub_r ==$NODE_NOT_EQUAL || $no>0){
                  $equal_r=$NODE_NOT_EQUAL;
                  last;
	      }
	    }

	  if ($equal_f ==$NODE_EQUAL  && $equal_r ==$NODE_EQUAL){
                $equal=$NODE_EQUAL;
                my $random5=int(rand(10000000));
                $node1->setAttribute ($EQUAL_ATTRIBUTE, $random5);
                $node2->setAttribute ($EQUAL_ATTRIBUTE, $random5);
	  }
          else {
                my $xpath_node1=&_node_xpath($node1);
                my $xpath_node2=&_node_xpath($node2);
                print "\nshow different from those node:", $node1->getNodeName(),":",$node2->getNodeName();
                print "\nshow different from those node:\n$xpath_node1\n";
                 &_traverse_XORT($node1), 
                print "\n$xpath_node2\n";
                &_traverse_XORT($node2);
                my $random5=int(rand(10000000));
                my $random6=int(rand(10000000));
                $node1->setAttribute ($EQUAL_ATTRIBUTE, $random5);
                $node2->setAttribute ($EQUAL_ATTRIBUTE, $random6);

          }


  }

 return $equal;
}


sub  sub_node(){
  my $self=shift;
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;
  return &_sub_node($node1, $node2,  $ignore_attribute, $schema_guide, $compare_level);
}


# node1: super node, node2: subnode
# return: node2 if node2 is CHILD of node1, null otherwise.
sub _sub_node(){
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;
  my $deepth=shift;

  my $i;

  # if node1 ==node2
  if (&_equal_nodes($node1, $node2,  $ignore_attribute,$schema_guide,$compare_level) ==$NODE_EQUAL){
          return $node1;
  }

  # check if node2 is DIRECT CHILDREN of node1
  my $nodes=$node1->getChildNodes();
  for $i (1..$nodes->getLength()){
         my $child_node=$nodes->item($i-1);
         if (&_equal_nodes($child_node, $node2,  $ignore_attribute,$schema_guide,$compare_level) ==$NODE_EQUAL){
            $node1->removeChild($child_node);
            return $child_node;
	 }
  }

  # if not DIRECT children, then check whether is grandchildren ....
  for  $i (1..$nodes->getLength()){
         my $child_node=$nodes->item($i-1);
         if ($child_node->getNodeType ==ELEMENT_NODE) {
            my $node_temp= &_sub_node($child_node, $node2,  $ignore_attribute, $schema_guide, $compare_level);
 	    if (defined $node_temp){
              $child_node->removeChild($node_temp);
              return $node_temp;
 	    }
	 }
  }
  return;
}


sub find_match_node(){
  my $self=shift;
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;
  return &_find_match_node($node1, $node2);
}


#try to find match node of node1 in CHILD of node2
#input: node1, node2
#return: matched node if having match, otherwise, return null;
# if node is table(primary or link table, then using _match_nodes, otherwise, return col node with same name
sub _find_match_node(){
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;

  print "\nmatching node1:", $node1->getNodeName(), "\nupper level:", $node2->getNodeName() if ($DEBUG==1);

 return if ($node1->getNodeType !=ELEMENT_NODE || $node2->getNodeType()!=ELEMENT_NODE);


  my $nodes=$node2->getChildNodes();
  for my  $i (1..$nodes->getLength()){
              my $child_node=$nodes->item($i-1);
              my $name_child_node=$child_node->getNodeName();
              if ($child_node->getNodeType==ELEMENT_NODE && $child_node->getNodeName eq $node1->getNodeName()){
                 my $match=&_match_nodes($node1, $child_node) ;
                 if ($match ==1){
                    #print "\nin find_match_node:", $child_node->getAttribute($MATCH_ATTRIBUTE),"\n";
                    return $child_node;
		 }
              }
  }
  return;

}

#different from find_match_node: whether only check CHILD_LEVEL or go further.
sub find_match_node_recursive(){
  my $self=shift;
  my $node1=shift;
  my $node2=shift;
  return &_find_match_node_recursive($node1, $node2);
}

sub _find_match_node_recursive(){
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  my $schema_guide=shift;
  my $compare_level=shift;

  print "\nmatching node1:", $node1->getNodeName(), "\nupper level:", $node2->getNodeName() if ($DEBUG==1);

  return if ($node1->getNodeType !=ELEMENT_NODE || $node2->getNodeType()!=ELEMENT_NODE);

  my $matched_node;
  my $node1_name=$node1->getNodeName();
  my $nodes=$node2->getChildNodes();
  for my  $i (1..$nodes->getLength()){
              my $child_node=$nodes->item($i-1);
              my $name_child_node=$child_node->getNodeName();
              if ($child_node->getNodeType==ELEMENT_NODE ){
		if ($child_node->getNodeName eq $node1_name){
                   my $match=&_match_nodes($node1, $child_node) ;
                   if ($match ==1){
                      #print "\nfind matching here ....";
                      #&_diff_nodes($node1, $child_node);
                      #&_diff_nodes($child_node, $node1);
                      ##exit(1);
                      return $child_node;
		   }
                   else {
                      $matched_node= &_find_match_node_recursive($node1, $child_node);
                      last if (defined $matched_node);
                   }
		 }
                else {
                   $matched_node= &_find_match_node_recursive($node1, $child_node);
                   last if (defined $matched_node);
                }
              }
  }
  return $matched_node;
}



# this traver version will format the tree, will not print getData under contain 'real' data
sub _traverse {
    my($node, $nest_level)= @_;
    $nest_level=0 if (!$nest_level);
    
    return if (!$node);
    my $indent;
    for my $i(1..$nest_level){
      $indent=$indent."\t";
    }
    $nest_level++;
    if ($node->getNodeType == ELEMENT_NODE) {
      my $flag_indent=0;
      my $att_string="";
      my $attribute_nodes=$node->getAttributes();
      for my $i(1..$attribute_nodes->getLength()){
        my $att=$attribute_nodes->item($i-1);
        my $name=$att->getName();
        if ($name ne $MATCH_ATTRIBUTE && $name ne $EQUAL_ATTRIBUTE){
          my $att_value=$att->getValue();
          $att_string=$att_string." ".$name."=\'".$att_value."\'";
        }
      }

      #print "\n$indent<", $node->getNodeName, $att_id_string,  $att_op_string, ">" ;
      print "\n$indent<", $node->getNodeName, $att_string, ">" ;
      foreach my $child ($node->getChildNodes()) {
        $flag_indent=1 if ($child->getNodeType ==ELEMENT_NODE);
        _traverse($child, $nest_level);
      }
      #no indent for element without sub ELEMENT_NODE
      if ($flag_indent==1){
        print "\n$indent</", $node->getNodeName, ">" ;
      }
      else{
        print "</", $node->getNodeName, ">" ;
      }
    } elsif ($node->getNodeType() == TEXT_NODE) {
      if ($node->getData =~/\w/){
         print $node->getData ;
         #print $node->getData if $node->getParentNode()->getAttribute('deleted') !=1;
       }
    }
  }

sub traverse (){
  my $self=shift;
  my $node=shift;
  &_traverse($node);
}

# differ from _traverse that it only print cols of self, no link table info will be printed
sub traverse_XORT (){
  my $self=shift;
  my $node=shift;
  &_traverse_XORT($node);
}

# differ from _traverse that it only print cols of self, no link table info will be printed
sub _traverse_XORT {
    my($node, $nest_level)= @_;
    $nest_level=0 if (!$nest_level);

    my $indent;
    for my $i(1..$nest_level){
      $indent=$indent."\t";
    }
    $nest_level++;
    if ($node->getNodeType == ELEMENT_NODE) {
      my $flag_indent=0;
      my %hash_cols;
      if (defined $hash_ddl{$node->getNodeName()}){
        my @array_temp=split(/\s+/, $hash_ddl{$node->getNodeName()});
        for my $k(0..$#array_temp){
            $hash_cols{$array_temp[$k]}=1;
	}
      }
      my $att_string="";
      my $attribute_nodes=$node->getAttributes();
      for my $i(1..$attribute_nodes->getLength()){
        my $att=$attribute_nodes->item($i-1);
        my $name=$att->getName();
        if ($name ne $MATCH_ATTRIBUTE && $name ne $EQUAL_ATTRIBUTE){
          my $att_value=$att->getValue();
          $att_string=$att_string." ".$name."=\'".$att_value."\'";
        }
      }

      #print "\n$indent<", $node->getNodeName, $att_id_string,  $att_op_string, ">" ;
      print "\n$indent<", $node->getNodeName, $att_string, ">" ;
      foreach my $child ($node->getChildNodes()) {
        $flag_indent=1 if ($child->getNodeType ==ELEMENT_NODE);
        if (($child->getNodeType==TEXT_NODE) || ($child->getNodeType==ELEMENT_NODE && defined $hash_cols{$child->getNodeName()}) || !defined $hash_ddl{$node->getNodeName()}){
          _traverse_XORT($child, $nest_level);
        }
      }
      #no indent for element without sub ELEMENT_NODE
      if ($flag_indent==1){
        print "\n$indent</", $node->getNodeName, ">" ;
      }
      else{
        print "</", $node->getNodeName, ">" ;
      }
    } elsif ($node->getNodeType() == TEXT_NODE) {
      if ($node->getData =~/\w/){
         print $node->getData ;
         #print $node->getData if $node->getParentNode()->getAttribute('deleted') !=1;
       }
    }
  }

sub node_xpath(){
   my $self=shift;
   my $node=shift;
   return &_node_xpath($node);
}

# which return the node location(xpath)
sub _node_xpath(){
   my $node=shift;
   my $path=shift;
   my $indent="";
   my $depth=&_node_depth($node);
  # print "\ndepth of node:", $node->getNodeName(), ":", $depth,":";

   my $loc=0;
   my $previous_sibling=$node->getPreviousSibling();
   while (defined $previous_sibling ){
      $loc++ if ($previous_sibling->getNodeType==ELEMENT_NODE && $previous_sibling->getNodeName() eq $node->getNodeName());
      $previous_sibling=$previous_sibling->getPreviousSibling();
   }

   for my $i(1..$depth){
     $indent=$indent."\t";
   }
   if (defined $node->getParentNode() && $node->getParentNode()->getNodeType()==ELEMENT_NODE){
       $path=&_node_xpath($node->getParentNode(), $path)."\n$indent".$node->getNodeName()."[$loc]";
   }
   else {
      $path=$node->getNodeName()."[$loc]";
   }
   return $path;
}


#return the node based on the xpath and parent node
sub _get_node_by_xpath(){
   my $node=shift;
   my $xpath=shift;

   my @array_xpath=split(/\n+/, $xpath);
   my ($temp1,$temp2)=split(/\[/, $array_xpath[$#array_xpath]);
   my ($location, $temp3)=split(/\]/, $temp2);
   my ($temp4, $name)=split(/\t+/, $temp1);
   print "\nxpath:$xpath:\nlocation:$location:name:$name:$array_xpath[$#array_xpath]:";
   my $nodes=$node->getChildNodes();
   my $count=0;
   for my $i(1..$nodes->getLength()){
       my $node_child=$nodes->item($i-1);
       if ($node_child->getNodeType==ELEMENT_NODE && $node_child->getNodeName() eq $name) {
	 if ($count==$location){
           #&_traverse($node_child);
           return $node_child;
         }
         $count++;
       }
   }
  return;
}

#input: node
#output: # level from root
sub _node_depth(){
   my $node=shift;
   my $depth=0;
   while (defined $node && $node->getNodeType==ELEMENT_NODE){
      $depth++;
      $node=$node->getParentNode();
   }
   return $depth;
}

# for table elements(e.g feature, featureprop)based on the user custom file, to retrive which cols
#input: table 
# return: hash with all customized cols
sub _get_custom_cols(){
   my $table=shift;
   my $hash_cols;
   if (defined $hash_ddl{$table}){
      my $exclude_cols=$hash_exclude_cols{$table};
      foreach my $key (keys %$exclude_cols){
        #  print "\nexcluded cols:$key for table:$table";
      }

      my @array_cols=split(/\s+/, $hash_ddl{$table});
      for my $i(0..$#array_cols){
         $hash_cols->{$array_cols[$i]}=1 if (!(defined $exclude_cols->{$array_cols[$i]}));
      }
   }

   return $hash_cols;
}


# compare node based on unique cols, ignore the other cols and link table
sub match_nodes(){
  my $self=shift;
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;
  return &_match_nodes($node1, $node2);
}

# compare node based on unique cols, ignore the other cols and link table
sub _match_nodes(){
  my $node1=shift;
  my $node2=shift;
  my $ignore_attribute=shift;

  #compare_level:ref(unique_key cols)/mini(all not null cols)/all(default)

  if (!(defined $node1) || !(defined $node2) ){
    print "\nnode not defined\n";
    return 0;
  }
  #print "\ntry to match those two nodes now:\nnode_name1:", $node1->getNodeName, "\nnode_name2:", $node2->getNodeName();


  my $equal=$NODE_NOT_EQUAL;

  my ($name_child_node1, $name_child_node2);
  if ($node1->getNodeType ==TEXT_NODE && $node2->getNodeType ==TEXT_NODE){
     my $data1=$node1->getData();
     my $data2=$node2->getData();
     if ($data1 eq $data2 ||($data1 !~/\w/ && $data2 !~ /\w/)){
     #if ($data1 eq $data2){
        return 1;
     }
     else {
        my $xpath_parent_node1=&_node_xpath($node1->getParentNode());
        my $xpath_parent_node2=&_node_xpath($node2->getParentNode());
        #print "\nunmatch here:\n$xpath_parent_node1\\n$xpath_parent_node1\n$data1<--->$data2\n";
        #&_traverse_XORT($node1->getParentNode->getParentNode());
        #print "\n\n\n";
        #&_traverse_XORT($node2->getParentNode->getParentNode());
        return 0;
     }
  }
  elsif ($node1->getNodeType() == ELEMENT_NODE && $node2->getNodeType() == ELEMENT_NODE){
      my $parent_name_node1=$node1->getParentNode()->getNodeName();
      my $parent_name_node2=$node2->getParentNode()->getNodeName();

      # if different NodeName, then will be NOT_EQUAL
      if ($node1->getNodeName() ne $node2->getNodeName()){
         $equal=0;
        return $equal;
      }

      my $nodes_1=$node1->getChildNodes();
      my $nodes_2=$node2->getChildNodes();


      #use a match flag to void repeat node matching, which is very expensive. assign a random number
      my $match_flag1=$node1->getAttribute ($MATCH_ATTRIBUTE);
      my $match_flag2=$node2->getAttribute ($MATCH_ATTRIBUTE);


          #need to compare both directions
          my $equal_f=$NODE_EQUAL;
          my $equal_r=$NODE_EQUAL;
          my ($i,$j);

          for  $i (1..$nodes_1->getLength()){
              my $child_node_1=$nodes_1->item($i-1);
              $name_child_node1=$child_node_1->getNodeName();
              my $string_cols_node1;
              my $string_cols_node2;
              my %hash_cols_node1;
		  if (defined $hash_ddl{$node1->getNodeName()}){
                     $string_cols_node1=$node1->getNodeName()."_unique";
                      my @array_unique_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                      foreach my $value1(@array_unique_key_node1){
                        $hash_cols_node1{$value1}=1;
                       # print "\nunique of table",$node1->getNodeName(),":$value1";
		      }
                  }
                  elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                     $hash_cols_node1{$name_child_node1}=1;
		  }
              my $equal_sub_f=$NODE_NOT_EQUAL;
              for  $j (1..$nodes_2->getLength()){
                 my $child_node_2=$nodes_2->item($j-1);
                 $name_child_node2=$child_node_2->getNodeName();
                 my %hash_cols_node2;

		   if (defined $hash_ddl{$node2->getNodeName()}){
                     $string_cols_node2=$node2->getNodeName()."_unique";
                      my @array_unique_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                      foreach my $value2(@array_unique_key_node2){
                        $hash_cols_node2{$value2}=1;
                       # print "\nunique of table:",$node2->getNodeName(),":$value2";
		      }
                   }
                   elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                     $hash_cols_node2{$name_child_node2}=1;
		   }
                my $equal_temp;
                my $child_node_type1=$child_node_1->getNodeType();
                my $child_node_type2=$child_node_2->getNodeType();
                #compare the cols and table of foreign key table(e.g cvterm of type_id)
                if ((defined $hash_cols_node1{$name_child_node1} && defined $hash_cols_node2{$name_child_node2}) && $name_child_node1 eq $name_child_node2 && ($child_node_1->getNodeType()==ELEMENT_NODE && $child_node_2->getNodeType()==ELEMENT_NODE) ){
                 $equal_temp=&_match_nodes($child_node_1, $child_node_2, $ignore_attribute);
                 $equal_sub_f=$equal_temp;
                 last;
                }
		elsif ( ($child_node_1->getNodeType==TEXT_NODE && $child_node_2->getNodeType==TEXT_NODE) && $node1->getNodeName eq $node2->getNodeName){
                 $equal_temp=&_match_nodes($child_node_1, $child_node_2, $ignore_attribute);
                 $equal_sub_f=$equal_temp;
                 last;
		}
                else {
                   $equal_sub_f=$NODE_EQUAL;
                }

	       }  # end of: for  $j (1..$nodes_2->getLength())
              if ($equal_sub_f ==$NODE_NOT_EQUAL){
                  $equal_f=$NODE_NOT_EQUAL;
                  last;
	      }
	    }

         #reverse direction
         for  $i (1..$nodes_2->getLength()){
              my $child_node_2=$nodes_2->item($i-1);
              $name_child_node2=$child_node_2->getNodeName();
              my $string_cols_node1;
              my $string_cols_node2;
              my %hash_cols_node2;

        	  if (defined $hash_ddl{$node2->getNodeName()}){
                     $string_cols_node1=$node2->getNodeName()."_unique";
                      my @array_unique_key_node2=split(/\s/, $hash_ddl{$string_cols_node2});
                      foreach my $value2(@array_unique_key_node2){
                        $hash_cols_node2{$value2}=1;
                       # print "\nunique of table:",$node2->getNodeName(),":$value2";
		      }
                  }
                  elsif (!(defined $hash_ddl{$node2->getNodeName()}) && defined $hash_ddl{$name_child_node2}){
                     $hash_cols_node2{$name_child_node2}=1;
		  }

              my $equal_sub_r=$NODE_NOT_EQUAL;
              for  $j (1..$nodes_1->getLength()){
                 my $child_node_1=$nodes_1->item($j-1);
                 $name_child_node1=$child_node_1->getNodeName();
                 my %hash_cols_node1;
		   if (defined $hash_ddl{$node1->getNodeName()}){
                     $string_cols_node1=$node1->getNodeName()."_unique";
                      my @array_unique_key_node1=split(/\s/, $hash_ddl{$string_cols_node1});
                      foreach my $value1(@array_unique_key_node1){
                        $hash_cols_node1{$value1}=1;
                       # print "\nunique of table:",$node1->getNodeName(),":$value1";
		      }
                   }
                   elsif (!(defined $hash_ddl{$node1->getNodeName()}) && defined $hash_ddl{$name_child_node1}){
                     $hash_cols_node1{$name_child_node1}=1;
		   }

                 my $equal_temp;

                if (defined $hash_cols_node1{$name_child_node1} && defined $hash_cols_node2{$name_child_node2} && ($child_node_1->getNodeType==ELEMENT_NODE && $child_node_2->getNodeType()==ELEMENT_NODE) && $name_child_node1 eq $name_child_node2){
                  $equal_temp=&_match_nodes($child_node_1, $child_node_2, $ignore_attribute);
                   $equal_sub_r=$NODE_EQUAL;
                   last;
                }
		elsif ( ($child_node_1->getNodeType==TEXT_NODE && $child_node_2->getNodeType==TEXT_NODE) && $node1->getNodeName eq $node2->getNodeName){
                   $equal_temp=&_match_nodes($child_node_1, $child_node_2, $ignore_attribute);
                   $equal_sub_r=$equal_temp;
                   last;
		}
                else {
                   $equal_sub_r=$NODE_EQUAL;
                }
	      }

              if ($equal_sub_r ==$NODE_NOT_EQUAL){
                  $equal_r=$NODE_NOT_EQUAL;
                  last;
	      }
	    }



	  if ($equal_f ==$NODE_EQUAL  && $equal_r ==$NODE_EQUAL){
                $equal=$NODE_EQUAL;
                my $random1;
                if ($node1->getAttribute($MATCH_ATTRIBUTE) =~/\w/){
                   print "\nEQUAL, MATCH_ATTRIBUTE for node1:", $node1->getAttribute($MATCH_ATTRIBUTE) if ($DEBUG==1);
                   $random1=$node1->getAttribute($MATCH_ATTRIBUTE);
		}
                elsif ($node2->getAttribute($MATCH_ATTRIBUTE) =~/\w/){
                   print "\nEQUAL, MATCH_ATTRIBUTE for node2:", $node2->getAttribute($MATCH_ATTRIBUTE) if ($DEBUG==1);
                   $random1=$node2->getAttribute($MATCH_ATTRIBUTE);
		}
                else {
                   $random1=int(rand(10000000));
                }
                print "\nEQUAL:random:$random1:" if ($DEBUG==1);
                $node1->setAttribute ($MATCH_ATTRIBUTE, $random1);
                $node2->setAttribute ($MATCH_ATTRIBUTE, $random1);
	  }
          else {
                my $random1=int(rand(10000000));
                my $random2=int(rand(10000000));
                print "\nNOT EQUAL,random1:$random1:random2:$random2:" if ($DEBUG==1);
                print "\nNOT EQUAL, MATCH_ATTRIBUTE for node1:", $node2->getAttribute($MATCH_ATTRIBUTE), ":" if ($DEBUG==1);
                print "\nNOT EQUAL, MATCH_ATTRIBUTE for node2:", $node2->getAttribute($MATCH_ATTRIBUTE), ":" if ($DEBUG==1);
                if ($node1->getAttribute($MATCH_ATTRIBUTE) =~/\w/){
                   $random1=$node1->getAttribute($MATCH_ATTRIBUTE);
		}
                if ($node2->getAttribute($MATCH_ATTRIBUTE) =~/\w/){
                   $random2=$node2->getAttribute($MATCH_ATTRIBUTE);
		}
                $node1->setAttribute ($MATCH_ATTRIBUTE, $random1);
                $node2->setAttribute ($MATCH_ATTRIBUTE, $random2);
          }

  }
 return $equal;
}

1;


