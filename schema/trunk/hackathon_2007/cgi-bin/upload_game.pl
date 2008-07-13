#!/usr/bin/perl 
use strict;
use warnings;
use Config::General;
use Bio::GMOD::Config;
use Time::HiRes qw/gettimeofday/; 
use CGI qw/:standard/;

my $GMOD_ROOT = '/usr/local/gmod';
my $gmod_conf = Bio::GMOD::Config->new($GMOD_ROOT);

my $confdir   = $gmod_conf->confdir;
my $webapollo = $confdir . "/webapollo.conf";

my ($conf,%config);
eval {$conf   = new Config::General($webapollo);
      %config = $conf->getall };

my $AUTOLOAD  = $config{'autoload'} || 0;
my $STORE_DIR = $config{'store_dir'} || "/usr/local/gmod/tmp/apollo";

my $cgi = CGI->new();

if (!$cgi->param() ) {
    #print a form to do the uploading
    print $cgi->header,
          $cgi->start_html(-title=>"upload a GAME-XML file",
                           -style=>{src=>'/gbrowse/gbrowse.css'},),
          $cgi->h1("Upload a GAME-XML file"),
          $AUTOLOAD ? p("The uploaded file will go straight into Chado")
                    : p("The uploaded file will be held for approval by site admin"),
          $cgi->start_form,
       
          "Username:<br />", 
          $cgi->textfield(-name=>'username'),
          $cgi->br,
          "Password:<br />",
          $cgi->password_field(-name=>'password'),
          $cgi->br,
          $cgi->filefield(-name=>'fileupload'), 
          $cgi->submit, 
 
          $cgi->end_form,
          $cgi->end_html;
}
else {  #process the uploaded file
    print $cgi->header,
          $cgi->start_html(-title=>"upload a GAME-XML file",
                           -style=>{src=>'/gbrowse/gbrowse.css'},),
          $cgi->h1("result"),
          "username:",
          $cgi->param('username'),
          $cgi->br,
          "password:",
          $cgi->param('password'),
          $cgi->br,

          $cgi->p("Config stuff: autoload:$AUTOLOAD, store_dir:$STORE_DIR"),

          "file contents:",
          $cgi->hr,
          "<pre>\n";

          my $fh = $cgi->upload( 'fileupload' );
          
          while (<$fh>) {
              print;
          }


          if ($AUTOLOAD) {
              print $cgi->p("Autoload is not yet supported");
          }
          else { #save the file for later
              die "ERROR: the store directory isn't configured" unless $STORE_DIR;
              my ($s, $ms) = gettimeofday;
              my $filename = "$s.$ms.".param('fileupload');
              my $fullfilename = $STORE_DIR . "/" . $filename;
              open OUT, ">$fullfilename" or die "couldn't open file: $!";
              seek $fh, 0, 0; #can be removed after debug prints are removed
              while (<$fh>) {
                  print OUT $_;
              }
              close OUT;
              print $cgi->p(param('fileupload')." was written to $fullfilename");

              #now write username and password
              my $userinfofile = $fullfilename.".userinfo";
              open OUT, ">$userinfofile" or die "couldn't open file $!";
              print OUT $cgi->param('username')."\n";
              print OUT $cgi->param('password')."\n";
              close OUT;
          }

          print "</pre>\n",
          $cgi->end_html;
}

exit(0);

=pod

A simple config file is required for this file to work which needs to be in
$GMOD_ROOT/conf/webapollo.conf.  The contents of the file should look something like
this:

#simple config file for the upload_game.pl cgi script

#load automatically, or save for admin approval
autoload=0

#directory to save uploaded game files in (make sure it exists!)
store_dir=/usr/local/gmod/tmp/apollo


=cut
