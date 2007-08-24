#!/usr/bin/perl -w

use strict;
use warnings;

use XML::DOM;
use WriteChadoMac;
use PrettyPrintDom;
use Getopt::Long;
use Pod::Usage;
use DBI;

my $host          = "localhost";
my $port          = 3306;
my $user          = "mysql";
my $password;
my $db            = "wikibox_db";
my $wikibox_table = "row";
my $help          = 0;
my $man           = 0;

GetOptions(
    'host|h=s'   => \$host,
    'port|P=i'   => \$port,
    'user=s'     => \$user,
    'password=s' => \$password,
    'db=s'       => \$db,
    'table=s'    => \$wikibox_table,
    'help|?'     => \$help,
    'man'        => \$man
  )
  or pod2usage(2);

pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;

#pod2usage("$0: No files given.") if ( ( @ARGV == 0 ) && ( -t STDIN ) );

=head1 NAME
    
wikibox2chadoxml.pl - This script reads a WikiBox table in mysql and outputs the corresponding ChadoXML.
    
=head1 SYNOPSIS
    
wiibox2chadoxml.pl [options] > output
    
  Options:
    -h               The hostname of the mySQL database.  default: localhost
    -P               The mySQL port.  default: 3306
    -u               The mySQL username.  default: mysql
    -p               The mySQL password.
    -d               The mySQL database name.  default: wikibox_db
    -t               The WikiBox database table name.  default: row
    -help            A brief help message
    -man             Full documentation
    
=head1 OPTIONS
    
=over 8

=item B<-h>

    The hostname of the mySQL database that houses the WikiBox table.
    
=item B<-P>

    The port that the mySQL database is running on. 

=item B<-u>

    The mySQL username to use to connect.
    
=item B<-p>

    The mySQL password to use to connect.
	
=item B<-d>

    The mySQL database name to connect to.
	
=item B<-t>

    The WikiBox table name in your MediaWiki database.

=item B<-help>
    
    Print a brief help message and exits.
  
=item B<-man>

    Prints the manual page and exits. 
    
=back
    
=head1 DESCRIPTION
    
B<wikibox2chadoxml.pl> This scripts reads a WikiBox database and parses the information contained within and then
produces ChadoXML from that.  This is a very rough first pass attempt.  You have been warned.
    
=cut

####MAIN####

#Create top level ChadoXML elements
my $doc = new XML::DOM::Document;
my $chxml = $doc->createElement('chado');
$doc->appendChild($chxml);

#Get database connection.
my $dsn = "dbi:mysql:database=$db;host=$host;port=$port";
my $dbh = DBI->connect( $dsn, $user, $password, { RaiseError => 1, AutoCommit => 0 } );

#Fetch box information
my $box_sql = "select box_id,template,page_name,headings from box;";
my $boxes = $dbh->selectall_arrayref($box_sql,{ Slice => {} });

#Loop over all the boxes in all the pages.
foreach my $box (@$boxes) {
    my @headings = split(/\n/,$box->{headings});
    
    #Create the top level feature object for the Gene page.  We assume that the page is a gene.
    #Probably should handle types better than this.
    
    #=================================================================================
    # The code below is HORRIBLY hard coded.  There is still too much up in the air
    # to properly write this in a generic way.
    #=================================================================================
    my $feature = create_ch_feature(
        doc => $doc,
        type => 'gene',
        uniquename => $box->{page_name},
        name => $box->{page_name},
        genus => 'Dictyostelium',
        species => 'discoideum'    
    );
    
    $chxml->appendChild($feature);

    my $row_sql = "select row_id, box_id, row_data from row where box_id = $box->{box_id}";
    my $rows = $dbh->selectall_arrayref($row_sql, {Slice => {} });

    #This needs to be made generic so that it creates different ChadoXML chunks based on
    #the headers found.
    #We are starting simple here.
    foreach my $row (@$rows) {
        my @row_data = split(/\|\|/,$row->{row_data});
        
        for (my $i=0; $i<=$#headings; $i++) {
            my $heading = $headings[$i];
            my $value = $row_data[$i];
            
            if ($value && $heading =~ m/^Description$/) {
                my $featureprop = create_ch_featureprop(
                            doc   => $doc,
                            type  => 'comment',
                            value => $value
                          );
                          
                $feature->appendChild($featureprop);
            }
            elsif ($value && $heading =~ m/^(Synonyms|Gene name)$/) {
                my $type = ($heading eq "Gene name") ? 'symbol' : 'synonym';
                my $is_current = ($heading eq "Synonyms") ? 'f' : 't';
                
                my $synonym = create_ch_feature_synonym(
                    doc          => $doc,
                    is_current   => $is_current,
                    name         => $value,
                    synonym_sgml => $value,
                    type         => $type
                );
                
                $feature->appendChild($synonym);
            }
        }
    }
    
}

pretty_print( $doc, \*STDOUT );
print STDOUT "\n";

$dbh->disconnect();
