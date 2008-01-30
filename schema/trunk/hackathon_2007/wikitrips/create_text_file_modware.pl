#!/usr/bin/perl 
use strict;
use warnings;
use File::Temp;
use CGI ':standard';
use CGI::Untaint;
use Modware::Search::Gene;

my $cgi = CGI->new();
print $cgi->header;

my %params = $cgi->Vars;

validate_parameters(%params);

my $handler = CGI::Untaint->new( {INCLUDE_PATH => 'My::Untaint'}, %params );
my $gene_name_input = $handler->extract(-as_text => 'gene_name');
my $page_template   = $handler->extract(-as_text => 'page_template');
my $table_template  = $handler->extract(-as_text => 'table_template');

untaint_parameters($gene_name_input,$page_template,$table_template,%params);

my $genes = Modware::Search::Gene->Search_by_name( $gene_name_input );

print $cgi->start_html;

my $fh = File::Temp->new(UNLINK=>0);

while ( my $gene = $genes->next ) {
    my $gene_name   = $gene->name();
    my $description = $gene->description() || ''; #$gene->note() || '';
    my @synonyms    = @{$gene->synonyms()};
    my $syn_string  = join ", ", @synonyms || '';
    my $row_data    = join ("||", $gene_name, $description, $syn_string);
    my $print_string
       = join("\t",$gene_name,$page_template,$table_template,$row_data)."\n";
    print $cgi->p($print_string);
    $fh->print($print_string);
}

print $cgi->p('loading gene info via loadwiki.php...');

my $tmpfile = $fh->filename;
system("php /home/ubuntu/schema/hackathon_2007/wikitrips/loadwiki.php -f $tmpfile -c /home/ubuntu/cvs_stuff/schema/hackathon_2007/wikitrips/empty.con");

print $cgi->p('done');

exit(0);

sub validate_parameters {
    my %params = @_;
    unless ( $params{gene_name} &&
             $params{page_template} &&
             $params{table_template} ) {
        print $cgi->start_html('Error'),
              $cgi->h1('This cgi is unable to continue');

        my $error_msg = 'This script was missing required input paramters. ';
        $error_msg .= 'The gene name was not set. '
            unless ($params{gene_name});
        $error_msg .= 'The wiki page template name was not set. '
            unless ($params{page_template});
        $error_msg .= 'The wiki table template name was not set.'
            unless ($params{table_template});

        print $cgi->p($error_msg),
              $cgi->p('Please go back to the offending page to try to figure out what went wrong or contact the administrator of this website.');
        exit(0);
    }
}

sub untaint_parameters {
    my ($gene_name_input,$page_template,$table_template,%params) = @_;
    unless ($gene_name_input && $page_template && $table_template) {
        print $cgi->start_html('Error'),
              $cgi->h1('This cgi is unable to continue'),
              $cgi->p('This script was given malformed paramters; only alphanumeric and the underscore character are allowed.  This is what was given:'),
              $cgi->start_ul,
                  $cgi->li("gene_name: $params{gene_name}"),
                  $cgi->li("page_template: $params{page_template}"),
                  $cgi->li("table_template: $params{table_template}"),
              $cgi->end_ul,
              $cgi->p('Please go back to the offending page to try to figure out what went wrong or contact the administrator of this website.');
        exit(0);
    }
}


package My::Untaint::text;

use base 'CGI::Untaint::object';

sub _untaint_re { qr /^([A-z_0-9*]+)$/ }

1;
