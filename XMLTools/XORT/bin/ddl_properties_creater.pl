#!/usr/local/bin/perl
use lib $ENV{CodeBase};
use strict;

print "Enter the ddl file:\n: ";
my $ddl_file= <STDIN>;


open (IN, $ddl_file) or die "could not open ddl file";

my $ddl_properties_file=">".$ENV{CodeBase}."/XORT/Config/ddl.properties";


open (OUT, $ddl_properties_file) or die "could not open file";
my $tablename;
my $table_unique;
my $primary_key;

#key: table_name value: all cols, separated by space
my %hash_table;



my $all_tables;
#key: primary_table_name:primary_table_primary_key value: all the foreign_table_name:foreign_key_col_name
my %hash_ref;
my %hash_non_null_cols;
my %hash_non_null_default;
my %hash_default_value;
my %hash_primary_key;

my @tables;
# save those table which are not real tables in db, i.e view, function, or _appdata
my @tables_pseudo;


# key: foreign_table_name:$foreign_key value: primary_table_name
my %hash_foreign_key;


my $table_name;
my $start;
my $table_data_type;
my @foreign_keys;

# here loading ddl.properties
while (<IN>){
 my $input=$_;
  # if create table, get table name
 if ($input =~/create\s+table/){
   $start=1;
   #get the table name
   my @temp=split(/\s+table\s+/, $input);
   my @temp1=split(/\s+\(/, $temp[1]);
   $tablename=$temp1[0];
  # print "\ntable name:$tablename";
   if ($all_tables){
      $all_tables=$all_tables." ".$tablename;
   }
   else {
      $all_tables=$tablename;
   }
   push @tables, $tablename;
 }
 # end of create table, print out all result
 elsif ($input =~/\)\s*\;/ && $input !~/index/){
   my $table_col;
   my $tale_data_type;
   foreach my $key (keys %hash_table){
     my $value=$hash_table{$key};
     if ($value =~/\,/){
       my @temp=split(/\,/, $value);
       $value=$temp[0];
     }
     if ($value =~/\(/){
       my @temp=split(/\(/, $value);
       $value=$temp[0];
     }
     if ($table_col){
         $table_col=$table_col." ".$key;
     }
     else {
         $table_col=$key;
     }
    if ($table_data_type){
       $table_data_type=$table_data_type.";".$key.":".$value;
    }
    else {
        $table_data_type=$key.":".$value;
    }
   }
   my $non_null_cols=undef;
   foreach my $key (keys %hash_non_null_cols){
     if ($non_null_cols){
        $non_null_cols=$non_null_cols." ".$key;
     }
     else {
        $non_null_cols=$key;
     }
   }
  undef  %hash_non_null_cols;

   my $non_null_default=undef;
   foreach my $key (keys %hash_non_null_default){
     if ($non_null_default){
        $non_null_default=$non_null_default." ".$key;
     }
     else {
        $non_null_default=$key;
     }
   }
  undef  %hash_non_null_default;

   print OUT "\n\n$tablename", "=$table_col";
   print OUT "\n\n$tablename","_primary_key=$primary_key";
   print OUT "\n$tablename", "_data_type=","$table_data_type";
   print OUT "\n$tablename", "_unique=","$table_unique";
   print OUT "\n$tablename", "_non_null_cols=", $non_null_cols;
   print OUT "\n$tablename", "_non_null_default=", $non_null_default;
   foreach my $key (keys %hash_default_value){
     print OUT "\n$key", "_default=", $hash_default_value{$key};
   }
   undef %hash_table;
   undef $table_data_type;
   undef $table_unique;
   undef %hash_default_value;
   $start=0;
 }

  # here do all the parsing ....
 if ($start==1){
   if (($input !~/unique|primary|foreign|create/) || ($input =~/uniquename/ && $input =~/text/) ){
     my @temp=split(/\s+/, $input);
     $hash_table{$temp[1]}=$temp[2];
     # here to get all columns which is not null
     my $table_id=$tablename."_id";
     # get all the non null columns
     if ($input =~ /ot/ && $input =~/null/ && ($temp[1] ne $table_id)){
       $hash_non_null_cols{$temp[1]}=1;
      # print "\n$temp[1]:$tablename";
       #get all the non null and has default value
       if ($input =~/default/){
          $hash_non_null_default{$temp[1]}=1;
       }
     }
     if ($input =~/default/){
          my $temp_key=$tablename.":".$temp[1];
          my @temp2=split(/default\s+/, $input);
          my @temp3=split(/\s*\,/, $temp2[1]);
          $hash_default_value{$temp_key}=$temp3[0];
         print "\nkey:$temp_key\tvalue:$temp3[0]:";
     }
   }
   elsif ($input =~/unique/){
     my  @temp=split(/\s*\(\s*/, $input);
     my @temp1=split(/\s*\)\s*/, $temp[1]);
     my @temp2=split(/\s*\,\s*/, $temp1[0]);
     for my $i (0..$#temp2){
       if ($table_unique){
          $table_unique=$table_unique." ".$temp2[$i];
	}
       else {
          $table_unique=$temp2[$i];
       }

     }
   }
   elsif ($input =~/primary/){ #get the primary key
     my  @temp=split(/\s*\(\s*/, $input);
     my @temp1=split(/\s*\)\s*/, $temp[1]);
     $primary_key=$temp1[0];

   }

   # here to get the primary/foreign pair
   # key for hash_ref is table.table_id, value is all the table.colume_names which refer to key
   if ($input =~/references/){
     my @temp=split(/\s*\)\s*references\s*/, $input);
     my @temp2=split(/key\s+\(/, $temp[0]);
     my $value=$tablename.":".$temp2[1];
     push @foreign_keys, $temp2[1];
     my @temp3=split(/\s+\(/, $temp[1]);
     my @temp4=split(/\)/, $temp3[1]);

     $hash_foreign_key{$value}=$temp3[0];

     my $key=$temp3[0].":".$temp4[0];
     if (defined $hash_ref{$key}){
        $hash_ref{$key}=$hash_ref{$key}." ".$value;
     }
     else {
        $hash_ref{$key}=$value;
     }
     if ($tablename eq 'contained_in'){
        print "\n$tablename\tkey:$key:\tvalue:$value";
     }
   }
 }
}
close(IN);

print "\n\nEnter the view_ddl file:\n:";
my $view_file= <STDIN>;
open (IN, $view_file) or die "could not open view file";

# here loading ddl_view.properties
while (<IN>){
 my $input=$_;
  # if create table, get table name
 if ($input =~/create\s+table/){
   $start=1;
   #get the table name
   my @temp=split(/\s+table\s+/, $input);
   my @temp1=split(/\s+\(/, $temp[1]);
   $tablename=$temp1[0];
  # print "\ntable name:$tablename";
   if ($all_tables){
      $all_tables=$all_tables." ".$tablename;
   }
   else {
      $all_tables=$tablename;
   }
   push @tables, $tablename;
   # here add the pseudo table to %hash_table_pseudo
   push @tables_pseudo, $tablename;
 }
 # end of create table, print out all result
 elsif ($input =~/\)\s*\;/ && $input !~/index/){
   my $table_col;
   my $tale_data_type;
   foreach my $key (keys %hash_table){
     my $value=$hash_table{$key};
     if ($value =~/\,/){
       my @temp=split(/\,/, $value);
       $value=$temp[0];
     }
     if ($value =~/\(/){
       my @temp=split(/\(/, $value);
       $value=$temp[0];
     }
     if ($table_col){
         $table_col=$table_col." ".$key;
     }
     else {
         $table_col=$key;
     }
    if ($table_data_type){
       $table_data_type=$table_data_type.";".$key.":".$value;
    }
    else {
        $table_data_type=$key.":".$value;
    }
   }
   my $non_null_cols=undef;
   foreach my $key (keys %hash_non_null_cols){
     if ($non_null_cols){
        $non_null_cols=$non_null_cols." ".$key;
     }
     else {
        $non_null_cols=$key;
     }
   }
  undef  %hash_non_null_cols;

   my $non_null_default=undef;
   foreach my $key (keys %hash_non_null_default){
     if ($non_null_default){
        $non_null_default=$non_null_default." ".$key;
     }
     else {
        $non_null_default=$key;
     }
   }
  undef  %hash_non_null_default;

   print OUT "\n\n$tablename", "=$table_col";
   print OUT "\n\n$tablename","_primary_key=$primary_key";
   print OUT "\n$tablename", "_data_type=","$table_data_type";
   print OUT "\n$tablename", "_unique=","$table_unique";
   print OUT "\n$tablename", "_non_null_cols=", $non_null_cols;
   print OUT "\n$tablename", "_non_null_default=", $non_null_default;
   foreach my $key (%hash_default_value){
     print OUT "\n$key", "_default=", $hash_default_value{$key};
   }
   undef %hash_table;
   undef $table_data_type;
   undef $table_unique;
   undef %hash_default_value;
   $start=0;
 }

  # here do all the parsing ....
 if ($start==1){
   if (($input !~/unique|primary|foreign|create/) || ($input =~/uniquename/ && $input =~/text/) ){
     my @temp=split(/\s+/, $input);
     $hash_table{$temp[1]}=$temp[2];
     # here to get all columns which is not null
     my $table_id=$tablename."_id";
     # get all the non null columns
     if ($input =~ /ot/ && $input =~/null/ && ($temp[1] ne $table_id)){
       $hash_non_null_cols{$temp[1]}=1;
      # print "\n$temp[1]:$tablename";
       #get all the non null and has default value
       if ($input =~/default/){
          $hash_non_null_default{$temp[1]}=1;
       }
     }
     if ($input =~/default/){
          my $temp_key=$tablename.":".$temp[1];
          my @temp2=split(/default\s+/, $input);
          my @temp3=split(/\s*\,/, $temp2[1]);
          $hash_default_value{$temp_key}=$temp3[0];
         print "\nkey:$temp_key\tvalue:$temp3[0]:";
     }
   }
   elsif ($input =~/unique/){
     my  @temp=split(/\s*\(\s*/, $input);
     my @temp1=split(/\s*\)\s*/, $temp[1]);
     my @temp2=split(/\s*\,\s*/, $temp1[0]);
     for my $i (0..$#temp2){
       if ($table_unique){
          $table_unique=$table_unique." ".$temp2[$i];
	}
       else {
          $table_unique=$temp2[$i];
       }

     }
   }
   elsif ($input =~/primary/){ #get the primary key
     my  @temp=split(/\s*\(\s*/, $input);
     my @temp1=split(/\s*\)\s*/, $temp[1]);
     $primary_key=@temp1[0];

   }

   # here to get the primary/foreign pair
   # key for hash_ref is table.table_id, value is all the table.colume_names which refer to key
   if ($input =~/references/){
     my @temp=split(/\s*\)\s*references\s*/, $input);
     my @temp2=split(/key\s+\(/, $temp[0]);
     my $value=$tablename.":".$temp2[1];
     push @foreign_keys, $temp2[1];
     my @temp3=split(/\s+\(/, $temp[1]);
     my @temp4=split(/\)/, $temp3[1]);

     $hash_foreign_key{$value}=$temp3[0];

     my $key=$temp3[0].":".$temp4[0];
     if (defined $hash_ref{$key}){
        $hash_ref{$key}=$hash_ref{$key}." ".$value;
     }
     else {
        $hash_ref{$key}=$value;
     }
     if ($tablename eq 'contained_in'){
        print "\n$tablename\tkey:$key:\tvalue:$value";
     }
   }
 }
}








#here to get summary information
#print OUT "\n\nall_table=$all_tables";
 my $all_tables=join " ", @tables;
 print OUT "\nall_table=", $all_tables;
 my $all_foreign_keys=join " ", @foreign_keys;
 print OUT "\n\nforeign_key=",$all_foreign_keys;

for my $i(0..$#tables){
  my $key=$tables[$i].":".$tables[$i]."_id";
 #  print "\n\n:$key:";
  if (defined $hash_ref{$key}){
    print OUT "\n\n$tables[$i]", "_module=", $hash_ref{$key};
  }

}

# print out all the foreign_table_name:foreign_key in format: cvterm:cv_id_ref_table=cv
foreach my $key (sort keys %hash_foreign_key){
  if (defined $hash_foreign_key{$key}){
     print OUT "\n\n$key", "_ref_table=", $hash_foreign_key{$key};
  }
}

#print out the table_pseudo
my $tables_pseudo_string=join " ", @tables_pseudo;
print OUT "\n\ntable_pseudo=", $tables_pseudo_string;
