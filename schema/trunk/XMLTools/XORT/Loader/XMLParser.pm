#!/usr/local/bin/perl

# Loader for xml file using SAX

package XORT::Loader::XMLParser;
use lib $ENV{CodeBase};
use XML::Parser::PerlSAX;
use XORT::Util::DbUtil::DB;
use strict;

# This one is modified on 1/29/2003 for the dtd: chado_1.0.dtd
# Different from XML_parser1_copy.pm
# 1. use DB.insert/delete/update intead of data_type_checker
# 2. table_element attributes: id/op



# update:
#   1. use unique columns to identify the record
#   2. for non_unique_key col, just update
#   3. for unique_key col, need to save the updated record, cascade for all following records
#   4. how to differentiate the data and data_sub ?

# Parsing algorithmas
# 1. Based on the element name to get the table name
# 2. all data in %hash_data or %hash_data_sub, the key will be parent_element.self_element
# 3. End of Element: if the element is table_id: retrive all the element with parent as table_id from %hash_data_sub into %hash_temp
#        call _replace_id(\%hash_temp, $table_id, '','') to get the id
#        if table_id is col of THIS table, save into %hash_data, otherwise, save back into %hash_data_sub



# --------------------------------------------------------
# global variable
# -------------------------------------------------------
my %hash_ddl;
my $level=1;

my $element_name;
my $table_name;
my $dbh_obj;
my %hash_table_col;
# this hash will have the pair of local_id/db_id, eg. cvterm_99 from xml file, id from cvterm_id 88, the key format: table_name:local_id, value: db_id
# with this format, it can also trace all the deletion because of cascade
my %hash_id;

#  store the 'text' for no 'update', index for array: level, key for hash: table.col,  value: 'text' data
my @AoH_data;
# store the 'text' for 'update', index for array: level, key for hash: table.col,  value: 'text' data
my @AoH_data_new;

# those store the data for db_id/local_id/op/ref, index for array: level, key for hash: element_name
my @AoH_db_id;
my @AoH_local_id;
my @AoH_op;
my @AoH_ref;

# key: $level, value: local_id/element_name/op/ref
my %hash_level_id;
my %hash_level_name;
my %hash_level_op;
my %hash_level_ref;
#this hash use to test whether self has sub_element, start_element: save $level/1, end_element: delete $hash_level_sub_detect{$level-1}
my %hash_level_sub_detect;
#root element, if you use different root , change here
my $root_element='chado';
my $APP_DATA_NODE='_appdata';
my $SQL_NODE='_sql';

# all the operator
my $OP_FORCE='force';
my $OP_UPDATE='update';
my $OP_INSERT='insert';
my $OP_DELETE='delete';
my $OP_lookup='lookup';

# all attribute
my $ATTRIBUTE_ID='id';
my $ATTRIBUTE_OP='op';
my $ATTRIBUTE_REF='ref';

# for some elements, it will be ignored, i.e view, and _app_data,
# algorithms to filter out ignore elements: initiately P_pseudo set to -1, for tables_pseudo, increase by 1 at beginning of start_element,  decrease by 1 at end of end_element
# if P_pseudo >-1, then do nothing for start_element, end_element, character
my $TABLES_PSEUDO='table_pseudo';
my %hash_tables_pseudo;
my $P_pseudo=-1;

# all the table which has dbxref_id, and primary key can be retrieved by accession
my %hash_accession_entry=(
dbxref=>1,
feature=>1,
);

# this hash will contain all the data for the current parsing table(which also is the subelement of root element)
my %hash_trans;
# this indicate whether we start the parsing from beginning or some point in the middle
my $recovery_status=0;
my $log_file;

sub new (){
 my $type=shift;
 my $self={};
 $self->{'db'}=shift;
 $self->{'file'}=shift;
 #load the properties file
 my $pro=XORT::Util::GeneralUtil::Properties->new('ddl');
 %hash_ddl=$pro->get_properties_hash();

 # load the elements which need to be filtered out
 my @array_pseudo=split(/\s+/, $hash_ddl{$TABLES_PSEUDO});
 foreach my $value(@array_pseudo){
   $hash_tables_pseudo{$value}=1;
   print "\npseudo:$value";
 }



 print "\n start to parse xml file .....";
 bless $self, $type;
 return $self;
}


# usage: $dbh_obj->load();
sub load (){
   my $self=shift;

   my ($is_recovery) =
     XORT::Util::GeneralUtil::Structure::rearrange(['is_recovery'], @_);
   if ($is_recovery ==1 || $is_recovery eq '1'){
     $recovery_status=$is_recovery;
   }
   my $file=$self->{file};
   my $db=$self->{db};
   my $dbh_pro=XORT::Util::GeneralUtil::Properties->new($db);
    my %dbh_hash=$dbh_pro->get_dbh_hash();
    $dbh_obj=XORT::Util::DbUtil::DB->_new(\%dbh_hash)  ;
   $dbh_obj->open();
 #  $dbh_obj->set_autocommit();

    my  $API_location=$ENV{CodeBase};
    my @temp=split(/\/+/, $file);
    my $temp_file=$temp[$#temp];
    $log_file=$API_location."/XORT/Log/".'load_'.$temp_file.".log";
    print "\n start to load the  xml file .....\nand write log file to:$log_file";
   my $parser = XML::Parser::PerlSAX->new(Handler=>MyHandler_Parser->_new( ));
  $parser->parse (Source=>{SystemId=>$file});

}



 package MyHandler_Parser;
 use XORT::Util::DbUtil::DB;

# keys: all the foreign keys
my %hash_foreign_key;
my $foreign_keys=$hash_ddl{'foreign_key'};
my @temp=split(/\s+/, $foreign_keys);
for my $i(0..$#temp){
  $hash_foreign_key{$temp[$i]}=1;
}



 sub _new {
  my $type=shift;
  my $self={};
  $self->{'file'}=shift;
  return bless {}, $type;
 }


 sub start_document {
   #all the variable defined in new method is unreachable for all other method
   # so here is good place to initiate some varables
    my (@temp,$is_symbol, $is_fb_id, $db_xref, $op_table, $op_column, %hash_table_col);

    # if recovery from middle of file, load back those information for object referencing
    if (-e $log_file && ($recovery_status eq '1' || $recovery_status ==1)) {
        open (LOG, $log_file) or die "\ncould not open the log file,";
        while (<LOG>){
           my ($local_id, $db_id)=split(/\t+/);
           $hash_id{$local_id}=$db_id;
	}
      close(LOG);
    }
   elsif (!(-e $log_file) && ($recovery_status eq '1' || $recovery_status ==1)) {
      print "\n are you sure you have run this before ?\nif first time parsing, please set the is_recovery=>0\n";
      exit(1);
   }
   else {
        print "\nIf you parse this xml file from the beginning, you can safely delete this file:\n";
        system("delete $log_file");

   }
 }


# start_element: at the beginning of start_element, $level ++, if ELEMENT_PSEUDO,then $P_seudo increase by 1.  
 sub start_element {

     my ($self, $element) = @_;
     #characters() may be called more than once for each element because of entity
     $level++;
     $hash_level_sub_detect{$level}=1;
     $element_name=$element->{'Name'};
     print "\nstart_element:$element_name";

     # here to check whether it is ELEMENT_pseudo
     if (defined $hash_tables_pseudo{$element_name}){
        $P_pseudo++;
     }

 #for those within ELEMENT_PSEUDO, do nothing
 if ($P_pseudo==-1) {
    # store the transaction information
    if (defined $hash_ddl{$element_name} && $hash_level_name{$level-1} eq $root_element){
       $hash_trans{'table'}=$element_name;
    }

     # save the id attributed into local_id
     my $local_id=$element->{'Attributes'}->{$ATTRIBUTE_ID};
     my $db_id;
     my $op=$element->{'Attributes'}->{$ATTRIBUTE_OP};
     my $ref=$element->{'Attributes'}->{$ATTRIBUTE_REF};
    if ($local_id&& $local_id ne ''){
       $local_id =~ s/\&/\&amp;/g;
       $local_id =~ s/</\&lt;/g;
       $local_id =~ s/>/\&gt;/g;
       $local_id =~ s/\"/\&quot;/g;
       $local_id =~ s/\'/\&apos;/g;
       $hash_level_id{$level}=$local_id;
       $AoH_local_id[$level]{$element_name}=$local_id;
    }
    else {
      delete $hash_level_id{$level};
      delete $AoH_local_id[$level]{$element_name};
    }
    if ($op && $op ne ''){
       $op =~ s/\&/\&amp;/g;
       $op =~ s/</\&lt;/g;
       $op =~ s/>/\&gt;/g;
       $op =~ s/\"/\&quot;/g;
       $op =~ s/\'/\&apos;/g;
       $hash_level_op{$level}=$op;
       $AoH_op[$level]{$element_name}=$op;
    }
    else {
       delete $hash_level_op{$level};
       delete $AoH_op[$level]{$element_name};
    }

    if ($ref && $ref ne ''){
       $ref =~ s/\&/\&amp;/g;
       $ref =~ s/</\&lt;/g;
       $ref =~ s/>/\&gt;/g;
       $ref =~ s/\"/\&quot;/g;
       $ref =~ s/\'/\&apos;/g;
       $hash_level_ref{$level}=$ref;
       $AoH_ref[$level]{$element_name}=$ref;
    }
    else {
       delete $hash_level_ref{$level};
       delete $AoH_ref[$level]{$element_name};
    }
    $hash_level_name{$level}=$element_name;


    #here to undef all old data before characters, since it might call characters more than once, it will concantate all previous data????
    # data will be in @AoH_data or @AoH_data_new: index of array: $level, key of hash: $table_name.$column
    my $hash_ref_temp=$AoH_data[$level];
    foreach my $key (keys %$hash_ref_temp){
         my ($junk, $element_name_temp)=split(/\./, $key);
         if ($element_name eq $element_name_temp && $AoH_op[$level]{$element_name} ne 'update'){
           delete $AoH_data[$level]{$key};
	 }
         elsif ($element_name eq $element_name_temp && $AoH_op[$level]{$element_name} eq 'update'){
           delete $AoH_data_new[$level]{$key};
	 }
    }



    # if self is table_element
    if (defined $hash_ddl{$element_name} ){
       # check if parent_element is table_element
       # when come to subordinary table(e.g cvrelationship), and previous sibling element is not table column(if is, it alread out) out it  output primary table(e.g cvterm)
       $table_name=$element_name;
       if (  defined $hash_ddl{$hash_level_name{$level-1}}){
	  print "\nstart to output the module table:$hash_level_name{$level-1}, level:$level before parse sub table:$table_name";
          my  $hash_data_ref;

          $hash_data_ref=&_extract_hash($AoH_data[$level], $hash_level_name{$level-1});

          # if has 'ref' attribute, it will retrieve the data(all non_null cols) from db. 
          # the difference between this and the one using as foreign_obj refering is that, here we may have addition 'update' data to be updated, or to 
          # be deleted, so we need to get real data, then decide how to op it
          if (defined $AoH_ref[$level-1]{$hash_level_name{$level-1}} && !(%$hash_data_ref)){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_ref[$level-1]{$hash_level_name{$level-1}};
               if (defined $hash_id{$hash_id_key}){
                  $hash_data_ref=&_get_ref_data($hash_level_name{$level-1}, $hash_id{$hash_id_key});
		}
               else {
                 my $temp_db_id=&_get_accession( $AoH_ref[$level-1]{$hash_level_name{$level-1}},$hash_level_name{$level-1}, $level-1);
                 if (defined $temp_db_id){
                      $hash_data_ref=&_get_ref_data($element_name, $temp_db_id );
		 }
               }
	  }

          # for empty hash_ref, will do nothing(other way to test undefined hash ? ) if (%hash)  ????
          my @temp;
          foreach my $key (%$hash_data_ref){
            if (defined $key && $key ne '' && $hash_data_ref->{$key} =~/\w|\W/){
               push @temp, $key;
	     }
	  }
	 if ($#temp >-1 ){
          #print "\nthere is data for main module table:$hash_level_name{$level-1}";
          my  $hash_ref=&_data_check($hash_data_ref,  $hash_level_name{$level-1}, $level, \%hash_level_id, \%hash_level_name );

          # here for different type of op, deal with the $hash_data_ref and return the $db_id
          if ($hash_level_op{$level-1} eq 'update'){
             my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level], $hash_level_name{$level-1});
             $db_id=$dbh_obj->db_update(-data_hash=>$hash_ref,-new_hash=>$hash_data_ref_new, -table=>$hash_level_name{$level-1}, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
             #save the pair of local_id/db_id
	     if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               $hash_id{$hash_id_key}=$db_id;
	     }
	     if (defined $db_id){
               $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	     }
             else {
               print "\nyou try to update a record which not exist in db yet";
               &create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
             }
          }
          elsif ($hash_level_op{$level-1} eq 'delete'){
             $db_id=$dbh_obj->db_delete(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1}, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
             #delete from %hash_id
             if (defined $db_id){
               foreach my $key (keys %hash_id){
                 my ($temp_table, $temp)=split(/\:/, $key);
		 if ($hash_id{$key} eq $db_id && $temp_table eq $hash_level_name{$level-1}){
                     delete $hash_id{$key};
                     last;
		 }
	       }
               delete $AoH_db_id[$level-1]{$hash_level_name{$level-1}};
	     }
          }
          elsif ($hash_level_op{$level-1} eq 'insert'){
             $db_id=$dbh_obj->db_insert(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1},-hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
             print "\ndb_id:$db_id:";
             #save the pair of local_id/db_id
	     if (defined $db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               $hash_id{$hash_id_key}=$db_id;
	     }
	     if (defined $db_id){
               $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	     }
          }
          elsif ($hash_level_op{$level-1} eq 'lookup'){
             $db_id=$dbh_obj->db_lookup(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1},-hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);

            #save the pair of local_id/db_id
	    if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               $hash_id{$hash_id_key}=$db_id;
	    }
	    if ($db_id){
               $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	    }
          }
          elsif ($hash_level_op{$level-1} eq 'force'){
             $db_id=$dbh_obj->db_force(-data_hash=>$hash_ref, -table=>$hash_level_name{$level-1}, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);

             #save the pair of local_id/db_id
	     if ($db_id && defined $AoH_local_id[$level-1]{$hash_level_name{$level-1}}){
               my $hash_id_key=$hash_level_name{$level-1}.":".$AoH_local_id[$level-1]{$hash_level_name{$level-1}};
               $hash_id{$hash_id_key}=$db_id;
	     }
	     if ($db_id){
                $AoH_db_id[$level-1]{$hash_level_name{$level-1}}=$db_id;
	     }
          }
 	 }
        }

        my $table_col=$hash_ddl{$table_name};
        my @array_col=split(/\s+/, $table_col);
        undef %hash_table_col;
        foreach my $i(0..$#array_col){
	   $hash_table_col{$array_col[$i]}=1;
         #  print "\ncol:$array_col[$i]";
        }

        #after deal with the primary table, here set the operation of link table, default willl be:force
        if (!(defined $AoH_op[$level]{$element_name})){
            $op=$OP_FORCE;
            $hash_level_op{$level}=$op;
            $AoH_op[$level]{$element_name}=$op;
        }

    } # end of self is table_element
   # otherwise, check if it is column, if not, exit and show error.
   elsif ( $element_name ne  $root_element ) {

     print "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name";
     my $col_ref=&_get_table_columns($hash_level_name{$level-1});
     #not column element name
     if (!(exists $col_ref->{$element_name})){
        print "\n invalid element...... element:$element_name";
        print "\ntable:$hash_level_name{$level-1}:\tcolumn:$element_name";
        &create_log(\%hash_trans, \%hash_id, $log_file);
        exit(1);
     }
     #column element, undef the data, already done before ???
     else {
        my $temp_key=$hash_level_name{$level-1}.".".$element_name;
        if ($AoH_op[$level-1]{$hash_level_name{$level-1}} ne 'update'){
           delete $AoH_data[$level]{$temp_key};
	}
        else {
	  if ($AoH_op[$level]{$hash_level_name{$level}} eq 'update'){
            delete $AoH_data_new[$level]{$temp_key};
	  }
          else {
            delete $AoH_data[$level]{$temp_key};
          }
        }
     }
   }
  } # end of if ($P_pseudo==-1) {
 }

sub characters {
    my( $self, $properties ) = @_;

 if ($P_pseudo==-1 && $element_name ne $APP_DATA_NODE) {
     my $data = $properties->{'Data'};
     #$data =~ s/\&/\&amp;/g;
     #$data =~ s/</\&lt;/g;
     #$data =~ s/>/\&gt;/g;
     #$data =~ s/\"/\&quot;/g;
     #$data =~ s/\'/\&apos;/g;
     #$data =~ s/\\/\\\\/g;


     $data =~ s/\&amp;/\&/g;
     $data =~ s/\&lt;/</g;
     $data =~ s/\&gt;/>/g;
     $data =~ s/\&quot;/\"/g;
     $data =~ s/\&apos;/\'/g;
     $data =~ s/\\\\/\\/g;
     #$data =~ s/\&amp;nbsp;/\s/g;

    chomp($data);
    my $data_length=length $data;

    # data will be in @AoH_data: index of array: $level, key of hash: $table_name.$column
    #my $table_name_id=$table_name."_id";    
    my $parent_element=$hash_level_name{$level-1};

    #my $parent_element_id;
    #if ($parent_element =~ /_id/){
#	$parent_element_id=$parent_element;
#    }
#    else {
#       $parent_element_id=$parent_element."_id";
#   }

    # ----------------------------------------------------------------------------------
    # For any element which is column of table, it will be saved into hash_data(in here every element)
    # ----------------------------------------------------------------------------------
    if (defined $hash_ddl{$parent_element}){
        my $hash_ref_cols=&_get_table_columns($parent_element);
        if  (defined $hash_ref_cols->{$element_name} && ($data =~/\w/ || $data eq '-') && $data ne "\t" ){
        #if  (defined $hash_ref_cols->{$element_name} && $data !~/\t/){
           my  $key=$hash_level_name{$level-1}.".".$element_name;
                # treat differently for update and other operation
                if ($AoH_op[$level-1]{$parent_element} eq 'update'){
		  if ($AoH_op[$level]{$element_name} eq 'update'){
                      $AoH_data_new[$level]{$key}= $AoH_data_new[$level]{$key}.$data;
		  }
                  else {
                      $AoH_data[$level]{$key}= $AoH_data[$level]{$key}.$data;
                  }
		}
                else {
		  if ($AoH_op[$level]{$element_name} ne 'update'){
                      $AoH_data[$level]{$key}= $AoH_data[$level]{$key}.$data;
		    }
                   else {
                      print "\nTry to update a column which the op for table is not update.....";
                      &create_log(\%hash_trans, \%hash_id , $log_file );
                      exit(1);
                  }
	        }
         #print "\n\nin characters key:$key\tvalue:$AoH_data[$level]{$key}:\tlevel:$level";


          #here to save all the currrent transaction information in case of abnormal transaction happen, and undef at end of each trans
           if (!(defined $hash_ddl{$element_name}) && $hash_level_name{$level-2} eq $root_element){
                $hash_trans{$element_name}=$AoH_data[$level]{$key};
            }
       }
     }
   } #if ($P_pseudo==-1) {
}



sub end_element {
  my ($self, $element) = @_;

  my $parent_element=$hash_level_name{$level-1};
  my $element_name=$element->{Name};
  my $table;
  #my $table_name_id=$table_name."_id";
  my $hash_ref;

  print "\nend_element_name:$element_name";
   # come to end of document
  if ($element_name eq $root_element){
    print "\n\nbingo ....you success !....";
    exit(1);
  }

 #do something only when NOT within ELEMENT_PSEUDO
 if ($P_pseudo==-1) {

   if (defined $hash_ddl{$element_name} && $hash_level_name{$level-1} eq $root_element){
      undef %hash_trans;
   }


   # ------------------------------------------------------------
   # here come to the end of table
   # -------------------------------------------------------------
   # self: table_element
   if ($hash_ddl{$element_name}) {
        my $hash_ref=undef;
        my $hash_ref_new=undef;
        my $db_id;
        my $hash_ref_cols=&_get_table_columns($element_name);
        my  $hash_data_ref=&_extract_hash($AoH_data[$level+1], $element_name);
        #here derefer to hash, so can test whether there is any data:if (%hash)
        my %hash_data_temp=\$hash_data_ref;
        # if sub_element is not table_element, and is col of this table, and no 'ref' attribute for this element,  extract data
        # for nesting case, which $hash_level_name{$level+1} is table_element already done in start_element
        if (defined $hash_ref_cols->{$hash_level_name{$level+1}} && !$hash_ddl{$hash_level_name{$level+1}}  && %hash_data_temp){
 
          # for empty hash_ref, do nothing (already test in last step ???)
          if (defined $hash_data_ref){
            my  $hash_ref=&_data_check($hash_data_ref, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
            # here for different type of op, deal with the $hash_data_ref and return the $db_id
            if ($hash_level_op{$level} eq 'update'){
               my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level+1], $element_name);
               $db_id=$dbh_obj->db_update(-data_hash=>$hash_ref,-new_hash=>$hash_data_ref_new, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }
            elsif ($hash_level_op{$level} eq 'delete'){
               $db_id=$dbh_obj->db_delete(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
               #delete from %hash_id
               if ($db_id){
                  foreach my $key (keys %hash_id){
                    my ($temp_table, $temp)=split(/\:/, $key);
	            if ($hash_id{$key} eq $db_id && $element_name eq $temp_table){
                       delete $hash_id{$key};
                       delete $AoH_db_id[$level]{$element_name};
                       last;
	  	    }
	         }
	       }
            }
            elsif ($hash_level_op{$level} eq 'insert'){
               $db_id=$dbh_obj->db_insert(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }
            elsif ($hash_level_op{$level} eq 'lookup'){
               $db_id=$dbh_obj->db_lookup(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }
            elsif ($hash_level_op{$level} eq 'force'){
               $db_id=$dbh_obj->db_force(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
            }

            # save the pair of local_id/db_id
            # if ($hash_level_op{$level} ne 'update' && $db_id && defined $AoH_local_id[$level]{$element_name}){
            if ($db_id && defined $AoH_local_id[$level]{$element_name} && $hash_level_op{$level} ne 'delete'){
               my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
               $hash_id{$hash_id_key}=$db_id;
	    }
            if ($db_id && $hash_level_op{$level} ne 'delete'){
               $AoH_db_id[$level]{$element_name}=$db_id;
	    }
               print "\nend_element:$element_name is table element, and sub element is col of this table";
               print "\nlocal_id:$AoH_local_id[$level]{$element_name}:\tdb_id:$db_id:";
         }
       }
        #for case using ref attribuate to ref object
	elsif (defined $AoH_ref[$level]{$hash_level_name{$level}} && !(%hash_data_temp)){
          my  $hash_id_key=$element_name.":".$AoH_ref[$level]{$hash_level_name{$level}};

          if (defined $hash_id{$hash_id_key}){
              $hash_data_ref=&_get_ref_data($element_name, $hash_id{$hash_id_key});
  	  }
          else {
              my $temp_db_id=&_get_accession($AoH_ref[$level]{$hash_level_name{$level}}, $element_name, $level);
              if (defined $temp_db_id){
                 $hash_data_ref=&_get_ref_data($element_name, $temp_db_id );
	      }
          }

          # for empty hash_ref, do nothing
          if (%hash_data_temp){
            my  $hash_ref=&_data_check($hash_data_ref, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
            # here for different type of op, deal with the $hash_data_ref and return the $db_id
            if ($hash_level_op{$level} eq 'update'){
               my  $hash_data_ref_new=&_extract_hash($AoH_data_new[$level+1], $element_name);
               #  my  $hash_data_ref_new=&_data_check($hash_ref_new_temp, $element_name, $level+1, \%hash_level_id, \%hash_level_name );
               $db_id=$dbh_obj->db_update(-data_hash=>$hash_ref,-new_hash=>$hash_data_ref_new, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
          }
            elsif ($hash_level_op{$level} eq 'delete'){
               $db_id=$dbh_obj->db_delete(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
               #delete from %hash_id
               if ($db_id){
                  foreach my $key (keys %hash_id){
                    my ($temp_table, $temp)=split(/\:/, $key);
	            if ($hash_id{$key} eq $db_id && $element_name eq $temp_table){
                       delete $hash_id{$key};
                       delete $AoH_db_id[$level]{$element_name};
                       last;
	  	    }
	         }
	       }
            }
            elsif ($hash_level_op{$level} eq 'insert'){
               print "\nit is invalid xml to have 'insert' and 'ref' appear together";
               &create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
          }
            elsif ($hash_level_op{$level} eq 'lookup'){
               $db_id=$dbh_obj->db_lookup(-data_hash=>$hash_ref, -table=>$element_name, -hash_local_id=>\%hash_id, -hash_trans=>\%hash_trans, -log_file=>$log_file);
          }
            elsif ($hash_level_op{$level} eq 'force'){
               print "\nit is invalid xml to have 'force' and 'ref' appear together";
               &create_log(\%hash_trans, \%hash_id, $log_file);
               exit(1);
            }

            # save the pair of local_id/db_id
            # if ($hash_level_op{$level} ne 'update' && $db_id && defined $AoH_local_id[$level]{$element_name}){
            if ($db_id && defined $AoH_local_id[$level]{$element_name} && $AoH_op[$level]{$element_name} ne 'delete'){
               my $hash_id_key=$element_name.":".$AoH_local_id[$level]{$element_name};
               $hash_id{$hash_id_key}=$db_id;
	    }
            if ($db_id  && $AoH_op[$level]{$element_name} ne 'delete'){
               $AoH_db_id[$level]{$element_name}=$db_id;
	    }
               print "\nend_element is $element_name table element, and sub element is col of this table";
               print "\nlocal_id:$AoH_local_id[$level]{$element_name}:\tdb_id:$db_id:";
         } # end of if (%hash_data_temp)
	} # end of using ref attribute to refer object


        #if parent: column element, substitute the foreign key value with db_id
	if (!$hash_ddl{$hash_level_name{$level-1}} && $hash_level_name{$level-1} ne $root_element){
           my $key=$hash_level_name{$level-2}.".".$hash_level_name{$level-1};
	   if ($hash_level_op{$level-2} eq 'update'){
               if ($hash_level_op{$level-1} eq 'update'){
                   $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
	       }
               else {
                   $AoH_data_new[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
               }
	    }
           else {
               $AoH_data[$level-1]{$key}=$AoH_db_id[$level]{$element_name};
           }
          print "\nsubstitute it with db_id:$AoH_db_id[$level]{$element_name}:level:$level-1:key:$key:";
	}
   }
   # self: column element
   else {
      my $temp_foreign=$hash_level_name{$level-1}.":".$element_name."_ref_table";
      my $key=$hash_level_name{$level-1}.".".$element_name;
      my $primary_table=$hash_ddl{$temp_foreign};
      print "\n$element_name is column_element";
       #if is foreign key, and next level element is the primary table, it has done in last step, ie. <type_id><cvterm>...</cvterm></type_id>
      if ($hash_ddl{$temp_foreign} eq $hash_level_name{$level+1} && defined $hash_ddl{$temp_foreign} ne '' && (defined $hash_level_sub_detect{$level+1})){
        # my $key=$hash_level_name{$level-1}.".".$element_name;
        # print "\nforeign key, next level element:$hash_level_name{$level+1} is the primary table";
        # print "\nnext level db_id:$AoH_db_id[$level+1]{$primay_table}:";
        # print "\nref_table:$hash_ddl{$temp_foreign}:\tprimary_table: $hash_level_name{$level+1}";

        # already done in the case of: self: table, parent: col
        # if ($hash_level_op{$level-1} eq 'update'){
	#   if ($hash_level_op{$level} eq 'update'){
        #     $AoH_data[$level]{$key}=$AoH_db_id[$level+1]{$primay_table};
	#   }
        #   else {
        #     $AoH_data_new[$level]{$key}=$AoH_db_id[$level+1]{$primay_table};
        #   }
        # }
        # else {
        #    $AoH_data[$level]{$key}=$AoH_db_id[$level+1]{$primay_table};
        # }
      }
      # foreign key, no sub element, but have data, then it is local_id or accession, replace it  with db_id
      elsif (defined $hash_ddl{$temp_foreign} && !(defined $hash_level_sub_detect{$level+1}) &&  ((defined  $AoH_data[$level]{$key}) && ($AoH_data[$level]{$key} ne '')|| (defined  $AoH_data_new[$level]{$key}) && ($AoH_data_new[$level]{$key} ne ''))){
         #table: not update
        if ($hash_level_op{$level-1} ne 'update'){
          my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data[$level]{$key};
	  if (defined $hash_id{$hash_id_key}){
              $AoH_data[$level]{$key}=$hash_id{$hash_id_key};
	    }
          elsif(defined $hash_accession_entry{$primary_table}) {
             my $id=&_get_accession($AoH_data[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data[$level]{$key}=$id;
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print "\n$element_name: can't retrieve the id based on the accession:$AoH_data[$level]{$key}";
                 &create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
             }
           }
          else {
                print "\n$element_name:$AoH_data[$level]{$key}: is not accession, or local_id:$AoH_data[$level]{$key} is not defined yet";
                &create_log(\%hash_trans, \%hash_id , $log_file );
                exit(1);
          }
           print "\nend_element:$element_name is col, table_op:not update";
       	}
        #table:update, col:update
        elsif ($hash_level_op{$level-1} eq 'update' && $hash_level_op{$level} eq 'update' ){
          my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data_new[$level]{$key};
	  if (defined $hash_id{$hash_id_key}){
              $AoH_data_new[$level]{$key}=$hash_id{$hash_id_key};
	  }
          elsif(defined $hash_accession_entry{$primary_table}) {
             my $id=&_get_accession($AoH_data_new[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data_new[$level]{$key}=$id;
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print "\n$element_name: can't retrieve the id based on the accession:$AoH_data_new[$level]{$key}";
                &create_log(\%hash_trans, \%hash_id,  $log_file);
                exit(1);
             }
          }
          else {
                print "\n$element_name:$AoH_data_new[$level]{$key} is not accession, or local_id:$AoH_data_new[$level]{$key} is not defined yet";
                &create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
          }
          print "\nend_element: self:col, table_op:update, col_op:update";
        }
        #table: update, col: not upate
        else {
           my $hash_id_key=$hash_ddl{$temp_foreign}.":".$AoH_data[$level]{$key};
	   if (defined $hash_id{$hash_id_key}){
              $AoH_data[$level]{$key}=$hash_id{$hash_id_key};
	    }
           elsif(defined $hash_accession_entry{$primary_table}) {
             my $id=&_get_accession($AoH_data[$level]{$key}, $primary_table, $level);
             if ($id){
                $AoH_data[$level]{$key}=$id;
                $hash_id{$hash_id_key}=$id;
	     }
             else {
                print "\n$element_name: can't retrieve the id based on the accession:$AoH_data[$level]{$key}";
                &create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
             }
           }
          else {
                print "\n$element_name $AoH_data[$level]{$key} is not accession, or local_id:$AoH_data[$level]{$key} is not defined yet";
                &create_log(\%hash_trans, \%hash_id, $log_file);
                exit(1);
          }
         print "\nend_element: self:col, table_op:update, col_op:not update";
        }
       print "\nprimary table:$hash_ddl{$temp_foreign}:sub element:$hash_level_name{$level+1}";
       print "\n\n$element_name is foreign key, no sub element, has data, db_id:$AoH_data[$level]{$key}";
      }
      # foreign key, no sub element, but NO data, error .......
      elsif ($hash_ddl{$temp_foreign} ne $hash_level_name{$level+1} && $hash_ddl{$temp_foreign} ne '' && !$AoH_db_id[$level+1]{$primary_table} && ($AoH_data[$level]{$key} eq '')) {
        print "\n\n$element_name: is foreign key, no sub element, not data, error .....";
        &create_log(\%hash_trans, \%hash_id, $log_file);
        exit(1);
      }
       # not foreign key, do nothing
      elsif (!$hash_ddl{$temp_foreign}){
        # print "\n$element_name: is not foreign key, do nothing .....:$temp_foreign";
      }

   }
 }  #end of if ($P_pseudo ==-1)

  delete $hash_level_sub_detect{$level+1};
  $level--;
  if (defined $hash_tables_pseudo{$element_name}){
     $P_pseudo --;
  }
}


sub end_document {
    #clean the load.log 

    system(sprintf("delete $log_file")) if (-e $log_file && ($recovery_status eq '0' || $recovery_status ==0));
    $dbh_obj->close();
    print "\n\nbingo ....you success !....";
    exit(1);
}


sub entity_reference {
 my ($self, $properties) = @_;
 #do nothing
}

# this util method will extract all the data from hash which the key of this hash prefix with $element."."
# usage: $hash_ref=&_extract_hash($AoH_data[$level], $element);
sub _extract_hash(){
    my $hash_ref=shift;
    my $element=shift;
    my $result;

    my $content=$element.".";
    foreach my $value (keys %$hash_ref){
            print "\nextract_hash before:key:$value:value:$hash_ref->{$value}:";
	if (index($value, $content) ==0 ){
            my $start=length $content;
            my $key=substr($value, $start);
            print "\nextract_hash:content:$content:value:$value:key:$key:$hash_ref->{$value}:";
           # if ($hash_ref->{$value} =~/\w/){
             $result->{$key}=$hash_ref->{$value};

	   #}
             delete $hash_ref->{$value};
	}
    }



    #foreach my $key (keys %$hash_ref){
      # print "\nleft key:$key:\tvalue:$hash_ref{$key}:";
    #}
    return $result;
}


# this util method will check the missed columns, 
# missed column, if non_null,  non_foreign key, error ...
#  if non_null, foreign key, go to get from parent, grandparent ....
# usage: $hash_ref=&_data_check(\%hash_data, $table, $level, \%hash_level_id, \%hash_level_name);

sub _data_check(){
    my $hash_ref=shift;
    my $table=shift;
    my $level=shift;
    my $hash_level_id=shift;
    my $hash_level_name_ref=shift;
    my %result;

    my $hash_foreign_key;
    my @array_foreign_key=split(/\s+/, $hash_ddl{foreign_key});
    for (@array_foreign_key){
       $hash_foreign_key{$_}++;
    }

    my %hash_non_null_default;
    my $table_non_null_default=$table."_non_null_default";
    my @default=split(/\s+/, $hash_ddl{$table_non_null_default});
    for (@default){
      $hash_non_null_default{$_}++;
    }

    foreach my $key (keys %$hash_ref){
      print "\nin data_check col:$key\tvalue:$hash_ref->{$key}:";
    }

    my $table_non_null=$table."_non_null_cols";
    my @temp=split(/\s+/, $hash_ddl{$table_non_null});
    my $table_id_string=$table."_primary_key";
    my $table_id=$hash_ddl{$table_id_string};
    #my $table_id=$table."_id";
    for my $i(0..$#temp){
      my $foreign_key=$table.":".$temp[$i];
      #not serial id, is not null column, and is foreign key, then retrieved from the nearest outer of hash_level_db_id
      if ($temp[$i] ne $table_id &&  !(defined $hash_ref->{$temp[$i]}) && (defined $hash_foreign_key{$temp[$i]} )){
         my $temp_key=$table.":".$temp[$i]."_ref_table";
         print "\ndata_check temp_key:$temp_key:value:$hash_ddl{$temp_key}";
         my $retrieved_value=&_context_retrieve($level,  $hash_ddl{$temp_key}, $hash_level_name_ref);
         if ($retrieved_value){
            $hash_ref->{$temp[$i]}=$retrieved_value;
	  }
         elsif (!(defined $hash_non_null_default{$temp[$i]})) {
             print "\n\ncan not find the value for required element:$temp[$i] of table:$table from context .....";
             &create_log(\%hash_trans, \%hash_id, $log_file);
             exit(1);
          }
      }
      elsif ($temp[$i] ne $table_id &&  !(defined $hash_ref->{$temp[$i]}) && !(defined $hash_foreign_key{$temp[$i]}) && !(defined $hash_non_null_default{$temp[$i]})) {
          print "\n\nyou missed the required element:$temp[$i] for table:$table, also it is not foreign key";
          &create_log(\%hash_trans, \%hash_id, $log_file);
          exit(1);
      }
    }

    #   delete $hash_ref->{$value};


    return $hash_ref;
}


# This util method will retrieve the missed value based on the context check: nearest outer of correct type
# return: db_id

sub _context_retrieve(){
    my $level=shift;
    my $primary_table=shift;
    my $hash_level_name_ref=shift;
    my $result;
  #  print "\ncontext_retrieve:level:$level:primary_table:$primary_table";
    for ( my $i=$level-1; $i>=0; $i--){
  #    print "\ncontext check hash_level_name:$hash_level_name_ref->{$i}";
      if ($primary_table eq $hash_level_name_ref->{$i}){
        print "\ncontext_retrieve:level:$level:primary_table:$primary_table:value:$AoH_db_id[$i]{$primary_table}"; 
        $result= $AoH_db_id[$i]{$primary_table};
        last;
      }
    }
    print "\nresult is:$result";
    return $result;
}



# This util will return a hash ref which contains all the columns of this table
sub _get_table_columns(){
  my $table=shift;
  my $table_col=$hash_ddl{$table};

  my @array_col=split(/\s+/, $table_col);
  my $hash_table_column_ref;
        foreach my $i(0..$#array_col){
          if ($array_col[$i] ne ''){
	   $hash_table_column_ref->{$array_col[$i]}=1;
	 }
         #  print "\ncol:$array_col[$i]";
        }
  return $hash_table_column_ref;
}

# This util will get id based on the accession
# Format of accession: dbname:accession[.version]
# For dbxref, if not in db, insert it
# For feature/cvterm, if not in db, get the pseudo organism_id(if not in , create one: genus:Drosophila species:melanogaster taxgroup:0
# convenction: uniquename for this case will in format of: db:accession[.version]
sub _get_accession(){
  my $accession=shift;
  my $table=shift;
  my $level=shift;

  my ($dbname, $acc, $version, $db_id, $stm_select, $stm_insert);


  if ($accession =~ /([a-zA-Z]+)\:([a-zA-Z0-9]+)(\.\d)*/){
      my @temp=split(/\:/, $accession);
      $dbname=$temp[0];
      if ($temp[1] =~/\./){
      my @temp1=split(/\./, $temp[1]);
      $acc=$temp1[0];
      $version=$temp1[1];
    }
    else {
      $acc=$temp[1];
      $version='';
    }

    my $organism_id;
    #create a pseudo organism record GAME xml loading
    $organism_id=$dbh_obj->get_one_value("select organism_id from organism where  genus='Drosophila' and  species='melanogaster' and  taxgroup='0'");
    if (! $organism_id) {
      $dbh_obj->execute_sql("insert into organism (genus, species, taxgroup) values('Drosophila', 'melanogaster' , '0')");
      $organism_id=$dbh_obj->get_one_value("select organism_id from organism where  genus='Drosophila' and  species='melanogaster' and  taxgroup='0'");
    }

   my $type_id;
   # create pseudo cvterm record for GAME xml loading
    $type_id=$dbh_obj->get_one_value("select cvterm_id from cvterm, cv where name='curator note' and cvname='pub type' and cv.cv_id=cvterm.cv_id");
    if (! $type_id) {
      my $cv_id;
      $cv_id=$dbh_obj->get_one_value("select cv_id from cv where cvname='pub type'");
      if (!$cv_id) {
          $dbh_obj->execute_sql("insert into cv(cvname) values('pub type')");
          $cv_id=$dbh_obj->get_one_value("select cv_id from cv where cvname='pub type'");
      }
      $dbh_obj->execute_sql(sprintf("insert into cvterm(name, cv_id) values('curator note', $cv_id) "));
      $type_id=$dbh_obj->get_one_value("select cvterm_id from cvterm, cv where name='curator note' and cvname='pub type' and cv.cv_id=cvterm.cv_id");
    }


    # here to figure out eg. feature_id, table will be feature
    if ($table =~/\_id/){
       my @temp2=split(/\_id/, $table);
       $table=$temp2[0];
    }

    #my $table_id=$table."_id";
    my $table_id_string=$table."_primary_key";
    my $table_id=$hash_ddl{$table_id_string};
    my $dbxref_id;
    my $stm_select_dbxref=sprintf("select dbxref_id from dbxref where dbname='%s' and accession='%s' and version='%s'", $dbname, $acc, $version);
    my $stm_insert_dbxref=sprintf("insert into dbxref (dbname, accession, version) values('%s', '%s', '%s')", $dbname, $acc, $version);
    $dbxref_id=$dbh_obj->get_one_value($stm_select_dbxref);
    if (!$dbxref_id){
       $dbh_obj->execute_sql($stm_insert_dbxref);
       $dbxref_id=$dbh_obj->get_one_value($stm_select_dbxref);
    }

    if ($table eq 'dbxref'){
       $db_id=$dbxref_id;
    }
    elsif ($table eq 'feature' ){ 
     my  $stm_select_feature=sprintf("select $table_id from $table where uniquename='%s' and organism_id=%s", $accession, $organism_id);
     my  $stm_insert_feature=sprintf("insert into feature (organism_id, uniquename, type_id) values(%s, '%s', $type_id)", $organism_id, $accession);
       $db_id=$dbh_obj->get_one_value($stm_select_feature);
       if (!$db_id){
          $dbh_obj->execute_sql($stm_insert_feature);
          $db_id=$dbh_obj->get_one_value($stm_select_feature);
       }
    }
  }
  else {
        print "\nsorry, the accession:$accession is not correct format as: db:acc[.version]";
          &create_log(\%hash_trans, \%hash_id, $log_file);
          exit(1);
  }
  return $db_id;
}



# util method serving for get_accession in case of inserting new record based on the accession
sub _get_organism_id(){

    my $level=shift;

    my $result;
  #  print "\ncontext_retrieve:level:$level:primary_table:$primary_table";
    for ( my $i=$level; $i>=0; $i--){
  #    print "\ncontext check hash_level_name:$hash_level_name_ref->{$i}";
     # print "\nhash_level_name:$hash_level_name{$i-1}";
      if ( $hash_level_name{$i} eq 'feature' ){
        my $hash_ref=$AoH_local_id[$i+1];
        foreach my $key (keys %$hash_ref){
           print "\nkey:$key\tvalue:$hash_ref->{$key}";
	}
        $result= $AoH_local_id[$i+1]{'organism_id'};
        print "\n\norganism_id is:$result ........";
        last;
      }
    }
    print "\n\norganism_id is:$result ........";
    return $result;

}

#this util was created because of ref attribute, which ref object by local_id or accession, 
# here the id will the real db id, so each will retrieve at most ONE record
# this method will retrive the real data(only unique keys) from DB, and store in hash
sub _get_ref_data(){
 my $table=shift;
 my $id=shift;

 my $hash_ref;
 #my $table_id=$table."_id";
 my $table_id_string=$table."_primary_key";
 my $table_id=$hash_ddl{$table_id_string};
 my $table_unique=$table."_non_null_cols";
 my @array_table_cols=split(/\s+/, $hash_ddl{$table_unique});
 my $data_list;
 for my $i(0..$#array_table_cols){
   if ($data_list){
       $data_list=$data_list." , ".$array_table_cols[$i];
   }
   else {
       $data_list=$array_table_cols[$i];
   }
 }

 my $stm_select=sprintf("select $data_list from $table where $table_id=$id");
 print "\nget_ref_data stm:$stm_select";
 my $array_ref=$dbh_obj->get_all_arrayref($stm_select);
 if (defined $array_ref){
   for my $i (0..$#{$array_ref->[0]}){
        $hash_ref->{$array_table_cols[$i]}=$array_ref->[0][$i];
        print "\nfrom ref:$table:$array_table_cols[$i]:$array_ref->[0][$i]";
   }
  return $hash_ref;
 }
 return ;
}



sub create_log(){
   my $hash_trans=shift;
   my $hash_local_id=shift;
   my $file=shift;

   print "\nit will use this log_file:$file: to recover the process if you set the -is_recovery=1";
   my $log_file=">".$file;

   print "\nlog file:$log_file";
   open (LOG, $log_file) or die "unable to write to file:$log_file";
   foreach my  $key (keys %$hash_local_id){
      print LOG "$key\t$hash_local_id->{$key}\n";
   }
   print "\nsorry, for some reasons, this process stop before finish the following transaction:$hash_trans->{table}";
   foreach my $key (keys %$hash_trans){
     if ($key ne 'table'){
         print "\nelement:$key\tvalue:$hash_trans->{$key}";
    }
   }
   print "\n\n";
}


1;




