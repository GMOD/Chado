#!/usr/local/bin/perl
package XORT::Util::GeneralUtil::Properties;
 use lib $ENV{CodeBase};
 use strict;

 sub new (){
  my $type=shift;
  my $self={};
  $self->{'name'}=shift;
  bless $self, $type;
  return $self;
 }

 sub get_dbh_hash(){
   my $self=shift;
   my $location= $ENV{CodeBase};
   my $file_name=$location."/XORT/Config/".$self->{'name'}.".properties";
      #  print "\nfilename:$file_name\n";
             open (IN, $file_name) or die "could not open $file_name";
      #     open (IN, 'f:/document/flybase/API/pk.properties') or die "could not open $file_name";
       my  %dbh_hash=undef; ;
       while (<IN>){
           my  $pair=$_;
             chomp $pair;
           if (index($pair, "\#")){
             my @temp=split(/\=/, $pair);
             $dbh_hash{$temp[0]} =$temp[1];
 	   }
       }
    return %dbh_hash;
}

# commment start with  #
 sub get_properties_hash(){
   my $self=shift;
   my $location= $ENV{CodeBase};
   my $file_name=$location."/XORT/Config/".$self->{'name'}.".properties";
      #  print "\nfilename:$file_name\n";
             open (IN, $file_name) or die "couldnot open $file_name";
      #     open (IN, 'f:/document/flybase/API/pk.properties') or die "could not open $file_name";
       my  %dbh_hash=undef; ;
       while (<IN>){
            my  $pair=$_;
            chomp $pair;
            if(index($pair, '\#') ==-1){
              my @temp=split(/\=/, $pair);
	      if ($temp[1] ne ''){
                 $dbh_hash{$temp[0]} =$temp[1];
	      }
	}
       }
    return %dbh_hash;

 }
 
 1;
