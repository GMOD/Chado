#!/usr/local/bin/perl


# --------------------------------------------------------------------------------
# Usage: $cv_obj=Flybase::Utils::XML::Generator->new('chado');

 package XORT::Dumper::DumperXML;
 use lib $ENV{CodeBase};
 use XORT::Util::DbUtil::DB;
 use XORT::Util::GeneralUtil::Properties;
 use XORT::Dumper::DumperSpec;
 use XML::DOM;
 use strict;

my $unit_indent="       ";
my %hash_ddl;
# this hash contact all pairs of local_id/local_id
my %hash_id;
# this hash using for checking the avail of refer objectect, any object first time define, it will has all the field, after that, only unique
my %hash_object_id;
#here for pseudo table, e.g view, function and _appdata, _sql
my $TABLES_PSEUDO='table_pseudo';
my %hash_tables_pseudo;


my $LOCAL_ID="local_id";
my $NO_LOCAL_ID='xml';
my $MODULE="module";
my $SINGLE="single";
my $dumpspec_obj;


#global variable, attribute of test or dump
my $DUMP_ALL='all';
my $DUMP_COL='cols';
my $DUMP_SELECT='select';
my $DUMP_REF='ref';
my $DUMP_NO='no_dump';
my $DUMP_YES='yes_dump';

my $TEST_YES='yes';
my $TEST_NO='no';
my $TEST_ANY='any';
my $TEST_NONE='none';
my $TEST_GREATER_THAN='gt';
my $TEST_GREATER_EQUAL='ge';
my $TEST_LESS_THAN='lt';
my $TEST_LESS_EQUAL='le';

my $TYPE_DUMP='dump';
my $TYPE_TEST='test';
my $ROOT_NODE='chado';

# switch to set how to dump referenced object: unique_keys or cols
my $REF_OBJ_UNIQUE='0';
my $REF_OBJ_ALL='1';

 sub new (){
  my $type=shift;
  my $self={};
  $self->{'dbname'}=shift;

  bless $self, $type;
  return $self;
 }


sub Generate_XML {

   my $self=shift;

   my ( $table, $file,  $struct_type, $op_type, $format_type, $dump_spec, $ref_obj, $dumpspec_data) =
   XORT::Util::GeneralUtil::Structure::rearrange(['tables', 'file', 'struct_type', 'op_type', 'format_type', 'dump_spec', 'loadable', 'app_data'], @_);
   my $stm;


   my $string_primary_key=$table."_primary_key";
   my $table_id=$hash_ddl{$string_primary_key};

   #if file exist, delete first, then open filehandle for writting
   system("/bin/rm $file") if -e $file;
   $file=">>".$file;
   open (LOG, $file) or die "could not write to log file";
   print LOG "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!-- created by Pinglei Zhou, Flybase Harvard University -->";
   my $app_data=sprintf("\n<$ROOT_NODE>");
   my $temp_dumpspec;

   #load the dump spec and get the dumpspec object to manipulate the object
   my $parser = new XML::DOM::Parser;
   my $doc;
   if (defined $dump_spec) {
     print "\nstart to load dumpspec";
     #my @array_arg=("1", "14473012", "14476172", "AE002603");
     my @array_arg=split(/\s+/, $dumpspec_data);
     &_replace_dumpspec($dump_spec, \@array_arg);
     $temp_dumpspec=$ENV{CodeBase}."/XORT/Log/temp_dumpspec.xml";
     $doc = $parser->parsefile ($temp_dumpspec);
     $dumpspec_obj=XORT::Dumper::DumperSpec->new(-dbname=>$self->{'dbname'});
   }
   my $root;






   #load the propertity information and open the connection with database
   my  $property_file=$self->{'dbname'};
   my $dbh_pro=XORT::Util::GeneralUtil::Properties->new($property_file);
   my    %dbh_hash=$dbh_pro->get_dbh_hash();
   my  $dbh=XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh->open();
   my $ddl_pro=XORT::Util::GeneralUtil::Properties->new('ddl');
   %hash_ddl=$ddl_pro->get_properties_hash();


   # load the elements which need to be filtered out
   my @array_pseudo=split(/\s+/, $hash_ddl{$TABLES_PSEUDO});
   foreach my $value(@array_pseudo){
   $hash_tables_pseudo{$value}=1;
     print "\npseudo:$value";
   }

   # if there is dumpspec to guide the dumper, then use it
   if (defined $dumpspec_obj){
      $root=$doc->getDocumentElement();
      # here to get all app data 
      $app_data=$dumpspec_obj->get_app_data($root);
      print LOG "\n$app_data";

      my $nodes=$root->getChildNodes();
      for my $i(1..$nodes->getLength()){
         my $node=$nodes->item($i-1);
         my $node_type=$node->getNodeType();
         my $node_name=$node->getNodeName();
         print "\nnode_type:$node_type:node_name:$node_name";
         if ($node_type eq ELEMENT_NODE && defined $hash_ddl{$node_name} && !(defined $hash_tables_pseudo{$node_name})){
               print "\nnode name ", $node->getNodeName();
               #the result from get_id($node) is id string separated by '|'
               my $query=$dumpspec_obj->format_sql_id($node);
               my $query_all=$dumpspec_obj->format_sql($node);
               if (defined $query){
                   my $primary_key_string=$node_name."_primary_key";
                   my $table_id=$hash_ddl{$primary_key_string};

                   print "\nstm_dumpspec:$query";
                   my $hash_ref= $dbh->get_all_hashref($query);

                    foreach my $key(keys %$hash_ref){
                        my $hash_ref_sub=$hash_ref->{$key};
                        my $query_join=&_join_sql($query_all, $node_name, $$hash_ref_sub{$table_id});
                        print "\nquery_join:$query_join";
                        my $hash_ref_all= $dbh->get_all_hashref($query_join);
			foreach my $key1(keys %$hash_ref_all){
                            my $hash_ref_sub=$hash_ref_all->{$key1};
                            my $xml=&_table2xml($hash_ref_sub, '     ', $node_name, $op_type, $format_type, $MODULE,  $dbh, $ref_obj, $node);
                            print LOG $xml;
			}
                    }
	       }
         }
      }
   }
   #no dump spec, then use default;
   else {
     print "\nno dumpspec to guide the dumper:$table:";
     my @array_tables; 
     if (defined $table){
        @array_tables=split(/\:/, $table);
     }
     else {
        @array_tables=split(/\s+/, $hash_ddl{'all_table'});
     }
    for my $i(0..$#array_tables) {
       $stm=sprintf("select * from $array_tables[$i]");
       my $hash_ref= $dbh->get_all_hashref($stm);
       # my $hash_ref=$dbh->get_row_hashref($stm);
       foreach my $key(keys %$hash_ref){
         my $hash_ref_sub=$hash_ref->{$key};
         my $xml=&_table2xml($hash_ref_sub, '   ', $array_tables[$i], $op_type, $format_type, $struct_type,  $dbh);
         print LOG $xml;
       }
    }
  }



  print LOG "\n</$ROOT_NODE>";

   $dbh->close();

}


# _table2xml($hash_ref, $indent,$table,  $op_type, $format_type, $struct_type,  $dbh, $node);
# op_type: null/insert/delete/force/updates
# format_type: local_id/XML/default
# struct_type: MODULE/SINGLE
# node: either TABLE_ELEMENT node or null
sub _table2xml(){
 my $hash_ref=shift;
 my $indent=shift;
 my $table=shift;
 my $op_type=shift;
 my $format_type=shift;
 my $struct_type=shift;
 my $dbh=shift;
 my $ref_obj=shift;
 my $node=shift;


 my $attribute;
 my $node_name;

 my $xml_sub;
 if (defined $node){
   $attribute= $dumpspec_obj->get_attribute_value($node);
     print "\nentrance of _table2xml, node name:", $node->getNodeName();
   $node_name=$node->getNodeName();
 }

 my $string_primary_key=$table."_primary_key";
 my $table_id=$hash_ddl{$string_primary_key};

 #combination of table_name with primary key will unique identify any object
 my $id=$table."_".$hash_ref->{$table_id};
 # here if this object has been dumped, then do nothing.
 if (defined $hash_id{$id}){
   return ;
 }

 # we always save all the defined objects, whether using local_id or not
 $hash_object_id{$id}=$id;

 # here to store the local_id if will use local_id mechanism
 if ($format_type eq $LOCAL_ID){
    $hash_id{$id}=$id;
  }

 # here the primary id will become foreign_key value for link table
 my $foreign_id=$hash_ref->{$table_id};

 # clean the orinal data, eg. remove the serial id column
 print "\n\ndata in main table....:$table";
 foreach my $key (keys %$hash_ref){
    #print "\nkey:$key\tvalue:$hash_ref->{$key}";
    if (!(defined $hash_ref->{$key}) || $hash_ref->{$key} eq '' || $key eq $table_id){
      # print "\ndelete key:$key\t$hash_ref->{$key}";
       delete $hash_ref->{$key};
    }
    else {
       my $data=$hash_ref->{$key};
              $data =~ s/\&/\&amp;/g;
              $data =~ s/</\&lt;/g;
              $data =~ s/>/\&gt;/g;
              $data =~ s/\"/\&quot;/g;
              $data =~ s/\'/\&apos;/g;
              $data =~ s/\\/\\\\/g;
              $data =~ s/ /&amp;nbsp;/g if ($data !~/\W|\w|\S/);
         $hash_ref->{$key}=$data;
    }
  # print "\ncol:$key\tvalue:$hash_ref->{$key}";
 }


 my $xml;
 my @array_table_cols=split(/\s+/, $hash_ddl{$table});

 #for columns
 foreach my $key (keys %$hash_ref){
   my $foreign_table_ref=$table.":".$key."_ref_table";
   my $string_foreign_table_primary_key=$hash_ddl{$foreign_table_ref}."_primary_key";
   my $foreign_table_id=$hash_ddl{$string_foreign_table_primary_key};

   if (defined $hash_ddl{$foreign_table_ref} && $key ne $table_id){
     my $key_local_id=$hash_ddl{$foreign_table_ref}."_".$hash_ref->{$key};
     # here to substitute with local_id, if ALLOWED
     if (defined $hash_id{$key_local_id}){
         $hash_ref->{$key}=$hash_id{$key_local_id};
     }
     # here to output foreign id by defining a object
     else {
         my $new_indent=$indent.$unit_indent.$unit_indent;
         my $stm_foreign_object;
         my $local_id_foreign_object=$hash_ddl{$foreign_table_ref}."_".$hash_ref->{$key};
         # the object not output before, then need to output everything
         #if (!(defined $hash_object_id{$local_id_foreign_object})){
         #    $stm=sprintf("select * from $hash_ddl{$foreign_table_ref} where $foreign_table_id=$hash_ref->{$key}");
	 #}
         # the object already exist in file, then only need unique key(s) to represent the object
        # else {

          my $attribute_dump;
          my @array_table_obj_cols;
          my $nest_node;
         #there is $node, then dump this table according to the dumpspec of this node
	 if (defined $node){
            my $path=$table.":".$key.":".$hash_ddl{$foreign_table_ref};

            if (defined $node){
               print "\nstart to retrieve the nest node of node:$node_name:.....path:$path";
               $nest_node=$dumpspec_obj->get_nested_node($node, $path, $TYPE_DUMP);
            }
            if (defined $nest_node){
               $attribute_dump=$nest_node->getAttribute("dump");
               my $nest_node_name=$nest_node->getNodeName();

               if (!(defined $attribute_dump) || $attribute_dump eq ''){
                     $attribute_dump=$DUMP_ALL;
	       }

               if ($attribute_dump eq $DUMP_ALL || $attribute_dump eq $DUMP_COL){
                 @array_table_obj_cols=split(/\s+/, $hash_ddl{$nest_node_name});
               }
               elsif ($attribute_dump eq $DUMP_REF){
                 my $table_unique=$nest_node_name."_unique";
                 @array_table_obj_cols=split(/\s+/, $hash_ddl{$table_unique});
               }
               elsif ($attribute_dump eq $DUMP_SELECT){
                 my $nodes=$nest_node->getChildNodes();
                 my @temp_cols=split(/\s+/, $hash_ddl{$node_name});
                 my %hash_cols;
                 foreach (@temp_cols){
                      $hash_cols{$_}=1;
                 }
                 for my $i (1..$nodes->getLength()){
                   my $child_node=$nodes->item($i-1);
                   my $child_node_name=$child_node->getNodeName();
                   if ($child_node->getNodeType() eq ELEMENT_NODE && defined $hash_cols{$child_node_name}){
                      my $attribute_dump=$dumpspec_obj->get_attribute_value($child_node);
                      if ($attribute_dump eq $DUMP_YES){
                        push @array_table_obj_cols, $child_node_name;
		      }
         	   }
                 }
               }
	    } # end of defined nest_node
            else {
             print "\nno nest node for node:$node_name";
            }
	  } # end of defined node

          # if no dump guide this ref_obj, then either dump unique_keys or cols
          print "\nlocal_id_foreign_object:$local_id_foreign_object\nref_obj:$ref_obj";
	  if (@array_table_obj_cols==0){
            if (!(defined $hash_object_id{$local_id_foreign_object}) && $ref_obj eq $REF_OBJ_ALL){
               @array_table_obj_cols=split(/\s+/, $hash_ddl{$hash_ddl{$foreign_table_ref}});
               print "\nforeign_table_ref:$foreign_table_ref:@array_table_obj_cols";
            }
            else {
              my $unique_key=$hash_ddl{$foreign_table_ref}."_unique";
              print "\nunique_key:$unique_key";
              # my $unique_key=$hash_ddl{$foreign_table_ref}."_non_null_cols";
              @array_table_obj_cols=split(/\s+/, $hash_ddl{$unique_key});
            }
          }

         my $data_list;
         for (@array_table_obj_cols){
             if ($data_list){
                 $data_list=$data_list." , ".$_;
  	     }
             else {
                 $data_list=$_;
             }
	 }
         #also need to add the table_id col, since the link table need it.
         $data_list=$data_list." , ".$foreign_table_id;
         #  print "\n\nunique_key:$unique_key\tdata_list:$data_list";
         my $stm=sprintf("select $data_list from $hash_ddl{$foreign_table_ref} where $foreign_table_id=$hash_ref->{$key}");

         print "\nstm:$stm";
         my $hash_ref_sub=$dbh->get_row_hashref($stm);

         my $object_ref_module;
         if (defined $nest_node && $attribute_dump eq $DUMP_ALL){
           $object_ref_module=$MODULE;
	 }
         else {
           $object_ref_module=$SINGLE;
         }
         print "\nmodel:$object_ref_module";
         my $data_sub=&_table2xml($hash_ref_sub, $new_indent, $hash_ddl{$foreign_table_ref}, $op_type, $format_type, $object_ref_module,  $dbh, $ref_obj, $nest_node);
         $hash_ref->{$key}=$data_sub;
     }

   }
   # ignore the null value
   elsif (!(defined $hash_ref->{$key}) || $key eq $table_id) {
      delete  $hash_ref->{$key};
   }
  }


  # here try to get all the subtable which has foreign key ref to the primary
  if ($struct_type eq $MODULE){
     my $table_module=$table."_module";
     my @temp=split(/\s+/, $hash_ddl{$table_module});
     #  this contains all link tables, will update while dumping link tables
     my %hash_tables_link;
     #this contains a copy of all link tables. keep same records
     my %hash_tables_link_copy;
     foreach my $table_link_temp (@temp){
        my ($table_link, $foreign_key)=split(/\:/, $table_link_temp);
        $hash_tables_link{$table_link}=1;
        $hash_tables_link_copy{$table_link}=1;
     }

     if (defined $node){
         my $child_nodes=$node->getChildNodes();
         for my $i(1..$child_nodes->getLength()){
              my $link_node=$child_nodes->item($i-1);
              my $link_node_name=$link_node->getNodeName();
              if ($link_node->getNodeType()==ELEMENT_NODE && defined $hash_tables_link_copy{$link_node_name}){
                 my $attribute_type=$dumpspec_obj->get_node_type($link_node);
                 my $attribute_link=$dumpspec_obj->get_attribute_value($link_node);
                 if ($attribute_type eq $TYPE_DUMP && $attribute_link ne $DUMP_NO ){
                     delete $hash_tables_link{$link_node_name};
                     my $stm_link_table=$dumpspec_obj->format_sql($link_node);
                     # here assume that name alias no start with '0', check DumperSpec.format_sql
                     my $alias_table_link=$link_node_name."_0";
                     # in case there are more than one join key, it will concat via ':'
                     my $join_key_string=$dumpspec_obj->get_join_foreign_key ($link_node);
                     my @array_join_key=split(/\:/, $join_key_string);
                     for my $j(0..$#array_join_key){
                         my $join_key=$array_join_key[$j];
                         if ($stm_link_table =~/where/){
                              $stm_link_table=$stm_link_table. " and $alias_table_link.$join_key=$foreign_id";
                         }
                         else {
                              $stm_link_table=$stm_link_table. " where $alias_table_link.$join_key=$foreign_id";
                         }
                         print "\nstm_link_table:$stm_link_table";
                         my $hash_ref_subtable=$dbh->get_all_hashref($stm_link_table);
                         # here remove the join_foreign_key which will be implicit retrieved by context
                         if (defined $hash_ref_subtable){
                            foreach my $key (keys %$hash_ref_subtable){
                               my $hash_ref_temp=$hash_ref_subtable->{$key};
                               delete $hash_ref_temp->{$join_key};
                               my $indent_sub=$indent.$unit_indent;
                              #why ???
                              # if ($key ne $foreign_key){
                                   $xml_sub=$xml_sub."\n.$indent_sub".&_table2xml($hash_ref_temp, $indent_sub, $link_node_name, $op_type, $format_type,$SINGLE, $dbh, $ref_obj, $link_node);
                              #  }
	                    }
	                 } # end of 

		     }
		   } # end of test whether this link table is for 'dump' or 'test'
                   elsif ($attribute_link eq $DUMP_NO) { #do nothing for this link table, also get ride of defaut behavior
                     delete $hash_tables_link{$link_node_name};
                   }
	      } # end of test whether it is ELEMENT_NODE and is link table
	 } # end of for my $i

         # for the node, if try to dump all, then it also need to dump all others that do not explicitly state in dumpspec
         if ($attribute eq $DUMP_ALL){
                foreach my $table_sub(keys %hash_tables_link){
                             # dump link table if there is any foreign key refer to parent table, i.e feature_relationship have both objfeature_id and subjfeature_id refer to feature
                        my %hash_join;
                        my @array_cols=split(/\s+/,$hash_ddl{$table_sub});
         	       for my $j(0..$#array_cols){
                           my $temp_key=$table_sub.":".$array_cols[$j]."_ref_table";
                           if (defined $hash_ddl{$temp_key} && $hash_ddl{$temp_key} eq $table){
                               $hash_join{$array_cols[$j]}=1;
         	          }
         	       }
                        foreach my $join_key (keys %hash_join){
                             my $stm_sub=sprintf("select * from $table_sub where $join_key=$foreign_id");
                              print "\nstm_sub:$stm_sub";
                             my $hash_ref_subtable=$dbh->get_all_hashref($stm_sub);
                             # here remove the join_foreign_key which will be implicit retrieved by context
                             if (defined $hash_ref_subtable){
                                foreach my $key (keys %$hash_ref_subtable){
                                   my $hash_ref_temp=$hash_ref_subtable->{$key};
                                   delete $hash_ref_temp->{$join_key};
                                   my $indent_sub=$indent.$unit_indent;
                                  # why ?????
                                  # if ($key ne $foreign_key){
                                       $xml_sub=$xml_sub."\n.$indent_sub".&_table2xml($hash_ref_temp, $indent_sub, $table_sub, $op_type, $format_type,$SINGLE, $dbh,$ref_obj);
                                  #  }
         	               }
         	            }
         	      }
         	  }
              } #end of $attribute eq $DUMP_ALL for $node

     }  # end of defined $node
     # no node, but struct_type is 'module'
     elsif ($attribute eq $DUMP_ALL || !(defined $attribute)){
       #need to remove those pseudo table, i.e feature_evidence
       my @temp=split(/\s+/, $hash_ddl{'tables_pseudo'});
       foreach my $value(@temp){
             delete $hash_tables_link{$value};
       }


       foreach my $table_sub(keys %hash_tables_link){
                    # dump link table if there is any foreign key refer to parent table, i.e feature_relationship have both objfeature_id and subjfeature_id refer to feature
               my %hash_join;
               my @array_cols=split(/\s+/,$hash_ddl{$table_sub});
	       for my $j(0..$#array_cols){
                  my $temp_key=$table_sub.":".$array_cols[$j]."_ref_table";
                  if (defined $hash_ddl{$temp_key} && $hash_ddl{$temp_key} eq $table){
                      $hash_join{$array_cols[$j]}=1;
	          }
	       }
               foreach my $join_key (keys %hash_join){
                    my $stm_sub=sprintf("select * from $table_sub where $join_key=$foreign_id");
                     print "\nstm_sub:$stm_sub";
                    my $hash_ref_subtable=$dbh->get_all_hashref($stm_sub);
                    # here remove the join_foreign_key which will be implicit retrieved by context
                    if (defined $hash_ref_subtable){
                       foreach my $key (keys %$hash_ref_subtable){
                          my $hash_ref_temp=$hash_ref_subtable->{$key};
                          delete $hash_ref_temp->{$join_key};
                          my $indent_sub=$indent.$unit_indent;
                        #  if ($key ne $foreign_key){
                              $xml_sub=$xml_sub."\n.$indent_sub".&_table2xml($hash_ref_temp, $indent_sub, $table_sub, $op_type, $format_type,$SINGLE, $dbh, $ref_obj);
                        #   }
	               }
	            }
	      }
	  }
     } #end of $attribute eq $DUMP_ALL


  } #end of ($struct_type eq $MODULE){






 # here start to output the data into xml format
 #need to change for delete/update/lookup ?

 if ($format_type eq $LOCAL_ID){
   # $hash_id{$id}=$id;
   #  print "\nid: $id";
    if ($op_type ne ''){
        $xml="\n$indent<".$table." id=\"".$id."\" op=\"".$op_type."\">";
    }
    else {
        $xml="\n$indent<".$table." id=\"".$id."\">";
    }
 }
 else {
    if ($op_type ne ''){
        $xml="\n$indent<".$table." op=\"".$op_type."\">";
    }
    else {
        $xml="\n$indent<".$table.">";
    }

}


 foreach my $key (keys %$hash_ref){
   my $data=$hash_ref->{$key};

    my $foreign_table_ref=$table.":".$key."_ref_table";
    my $foreign_table_id=$hash_ddl{$foreign_table_ref}."_id";
    my $key_local_id=$hash_ddl{$foreign_table_ref}."_".$hash_ref->{$key};
  #  print "\nkey_local_id:$key_local_id";
    if ((defined $hash_ddl{$foreign_table_ref} && defined $hash_id{$hash_ref->{$key}}) || !(defined  $hash_ddl{$foreign_table_ref}) ){
       $xml=$xml."\n$indent$unit_indent<".$key.">".$data."</".$key.">";
    }
    else {
       $xml=$xml."\n$indent$unit_indent<".$key.">".$data."\n$indent$unit_indent"."</".$key.">";
    }


 }

 if ($struct_type eq $MODULE){
    $xml=$xml.$xml_sub;
 }

 $xml=$xml."\n$indent</$table>";
#print "\nsub_xml.......\n$xml";

 return $xml;
}


# this will substitute all of args, and create a temp dumpspec file in CodeBase/Log/
#    Given an ordered array of values (eg @vals below) corresponding to 
#    similarly ordered fields (designated like "$1,$2,$3,...) in a 
#    preformatted form, substitute the values into the form fields.
sub _replace_dumpspec (){
  my $file=shift;
  my $array_ref=shift;

  my $temp_spec=">".$ENV{CodeBase}."/XORT/Log/temp_dumpspec.xml";
  my @array_arg=@$array_ref;
  open (IN, $file ) or die "unable to open the dumpspec file";
  open (OUT, $temp_spec) or die "unable to write the temp_dumpspec.xm";
  while (<IN>){
   my $value=$_;
   if ($#array_arg >-1){
     for my $i(1..$#array_arg+1){
       my $new=$array_arg[$i-1];
       $value=~  s/\$$i/$array_arg[$i-1]/g;
      }
   }
   print OUT $value;
  }

  close(IN);
  close(OUT);
}

 # method using to join a query with primary_key value, i.e. "select * from feature" into "select * from feature where feature_id=13"
 # because of difference source, it need to figure out the alias if there is any
 # here we assume that the query already been validated in dumpspec
sub _join_sql(){
  my $sql=shift;
  my $table=shift;
  my $table_id_value=shift;

  my $primary_key_string=$table."_primary_key";
  my $table_id=$hash_ddl{$primary_key_string};
  my ($alias, $what, $from, $join_string, $junk, $result);
  my @array_select=split(/\s*select\s*/, $sql);
  my @array_from=split(/\s*from\s*/, $array_select[1]);
  $what=$array_from[0];
  $from=$array_from[1];
  if ($what eq '*' || $what !~ /\./){
     $join_string=$table_id."=".$table_id_value;
  }
  elsif($what =~/\./) {
     my @temp=split(/\s*\,\s*/, $what);
     for my $i(0..$#temp){
        ($alias, $junk)=split(/\./, $what);
     }
     $join_string=$alias.".".$table_id."=".$table_id_value;
  }
  if ($sql =~/where/){
    $result=$sql." and ".$join_string;
  }
  elsif ($sql !~/where/){
    $result=$sql." where ".$join_string;
  }

  return $result;
}

 1;
