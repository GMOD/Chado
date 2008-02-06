#!/usr/bin/perl 
use strict;
use warnings;
use File::Temp;
use CGI ':standard';
use CGI::Untaint;
use Modware::Search::Gene;

my $cgi = CGI->new();

my %params = $cgi->Vars;

my $failure = validate_parameters(%params);
handle_error($failure) if $failure;

my $handler = CGI::Untaint->new( {INCLUDE_PATH => 'My::Untaint'}, %params );
my $gene_name_input = $handler->extract(-as_text => 'gene_name');
my $page_template   = $handler->extract(-as_text => 'page_template');
my $table_template  = $handler->extract(-as_text => 'table_template');

$failure = untaint_parameters($gene_name_input,
                              $page_template,
                              $table_template,%params);
handle_error($failure) if $failure;

my $genes = Modware::Search::Gene->Search_by_name( $gene_name_input );

my $fh = File::Temp->new(UNLINK=>0) or $failure = "Opening the temp file failed: $!";
handle_error($failure) if $failure;

while ( my $gene = $genes->next ) {
    my $gene_name   = $gene->name();
    my $description = $gene->description() || 
                      $gene->_get_featureprop('Note') ||
                      '';
    my $synonyms    = $gene->synonyms();
    my $syn_string  = join (", ", @$synonyms) || '';
    my $row_data    = join ("||", $gene_name, $description, $syn_string);
    my $print_string
       = join("\t",$gene_name,$page_template,$table_template,$row_data)."\n";
    $fh->print($print_string) or $failure = "Writing to temp file failed: $!";
    handle_error($failure) if $failure;
}

my $tmpfile = $fh->filename;

my @output = `/usr/bin/php /home/ubuntu/schema/hackathon_2007/wikitrips/loadwiki.php -f $tmpfile -c /home/ubuntu/schema/hackathon_2007/wikitrips/empty.conf`;

$failure = "There was an error running the php loading script.  Here is the output from the script: ".join(", ",@output) if $?;
handle_error($failure) if $failure;

my $base = $cgi->url(-base=>1);
print $cgi->redirect($base . "/wiki/index.php/$gene_name_input");
exit(0);


sub handle_error {
    my $error_string = shift;
    print $cgi->header,
      $cgi->start_html({-style=>"/gbrowse/gbrowse.css"},"Error"),
      $cgi->h1("Sorry, there was a problem"),
      $cgi->p("This is probably not your fault; an error occurred while "
             ."trying to get data out of the Chado database and copy it "
             ."into the wiki database."),
      $cgi->p("Here's what I know about the problem: $error_string"),
      $cgi->end_html;
    exit(0);
}

sub validate_parameters {
    my %params = @_;
    unless ( $params{gene_name} &&
             $params{page_template} &&
             $params{table_template} ) {
        print $cgi->start_html('Error'),
              $cgi->h1('This cgi is unable to continue');

        my $error_msg;
        $error_msg .= 'The gene name was not set. '
            unless ($params{gene_name});
        $error_msg .= 'The wiki page template name was not set. '
            unless ($params{page_template});
        $error_msg .= 'The wiki table template name was not set.'
            unless ($params{table_template});

        return $error_msg;
    }
    return;
}

sub untaint_parameters {
    my ($gene_name_input,$page_template,$table_template,%params) = @_;
    unless ($gene_name_input && $page_template && $table_template) {
        my $err_str = 'This script was given malformed paramters; only alphanumeric and the underscore character are allowed.  This is what was given:'.
              $cgi->start_ul.
                  $cgi->li("gene_name: $params{gene_name}").
                  $cgi->li("page_template: $params{page_template}").
                  $cgi->li("table_template: $params{table_template}").
              $cgi->end_ul.
              $cgi->p('Please go back to the offending page to try to figure out what went wrong or contact the administrator of this website.');
        return $err_str;
    }
    return;
}


package My::Untaint::text;

use base 'CGI::Untaint::object';

sub _untaint_re { qr /^([A-z_0-9*]+)$/ }

1;
