package XORT::Util::DbUtil::DBHandler ;
 use lib $ENV{CodeBase};
use DBI;
use XORT::Util::GeneralUtil::Structure qw(rearrange);
use XORT::Loader::XMLParser;


sub new {
 $type=shift;
my $self={};
$self->{'db_type'}=shift;
$self->{'database'}=shift;
$self->{'host'}=shift;
$self->{'port'}=shift;
$self->{'user'}=shift;
$self->{'password'}=shift;
bless $self, $type;
return $self;
}

sub load_file_into_db(){
  my $self=shift;
  my $query=undef;
  my $stm=undef;
  my $temp=undef;
  my $data_source="DBI:mysql:$self->{'database'}:$self->{'host'}:$self->{'port'}";
  my $user=$self->{'user'};
my $password=$self->{'password'};
my $dbh=DBI->connect($data_source, $user, $password) or die ":can't connect to $data_source:$dbh->errstr\n";
my ($file, $file_type, $table) =
      Util::GeneralUtil::Structure::rearrange(['file', 'file_type', 'table'], @_);
      if ($file_type eq "text"){
          open (IN, $file) or die "could open file:$file";
          while (<IN>){
            $pair=$_;
            @temp=split(/\t/, $pair);
            if ($temp[0] ne ""  && $temp[1] ne ""){
              $query=$dbh->prepare("insert into $table values('$temp[0]', '$temp[1]')");
              $query->execute or die "Unable to execute query: $dbh->errstr\n";
              $query->finish;
            }
            else {
              print "\n error for reading data";
              $dbh->disconnect;
            }
          }
      }
      elsif ($file_type eq "xml"){
            $sax_handler= Util::GeneralUtil::XMLParser->new($file, $table);
            @result=$sax_handler-> parse_xml();

           for $i (0..$#result) {
             print "\n";
            undef $temp;
             for  $j (0..$#{$result[$i]})     {
                   #   print "\t$result[$i][$j]";
                    $value=  $result[$i][$j];
                    if ( substr($value, length($value)-1, 1) eq " "){
                       chop($value);
                       }
                     if (defined $temp){

                        $temp=sprintf("%s, '%s'",$temp,$value  );
                     }
                     else {
                         $temp = sprintf("'%s'",  $value  );

                     }

                }

            if ($self->{'db_type'} eq "mysql"){
                    $temp=sprintf("insert into $table values(%s)", $temp);

                 }
             print "\ntemp:$temp ";
          #  $query=$dbh->prepare($temp);
          #     $query->execute or die "Unable to execute query: $dbh->errstr\n";
          #     $query->finish;
         }
         $dbh->disconnect;
      }
$dbh->disconnect;
}

sub display_dbh(){
 my $self=shift;
 print "database:$self->{'database'}\thost: $self->{'host'}\tport:$self->{'port'}\tuser:$self->{'user'}\n";
}



1;

