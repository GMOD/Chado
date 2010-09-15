#!/usr/bin/perl
use warnings;
use strict;

use CGI qw/:standard start_div start_span start_pre start_ul/;
use Bio::GMOD::CAS::Util;

my $config = Bio::GMOD::CAS::Util->new();

my $working_dir = $config->HTDOCS;
my $apollo      = $config->HEADLESS_APOLLO;
my $hostname    = $config->PROJECT_HOME;
my $web_path    = $config->WEB_PATH;
my $vendor      = $config->VENDOR;
my $apollo_desc = $config->APOLLO_DESC;
my $access_method = $config->ACCESS_METHOD;

unless(param()) { #print the starting page

    print header,
         start_html(-title=>'Script for generating a connection on the fly for apollo',
                    -style=>{src=>'/gbrowse/gbrowse.css'},),
         h1('Request a region from the database'),
         start_form(-method=>'GET'),
         'Chromosome:',
         popup_menu(-name=>'chromosome',
                    -values=>[3]),p,
         'start:',
         textfield('start'),p,
         'end:',
         textfield('end'),p,
         radio_group(
             -name=>'xml_type',
             -values=>['game','chado'],
             -default=>'game',
             -labels=>{'GAME-XML','chadoxml'}
         ),p,
         'or ',
         checkbox(
             -name=>'direct',
             -checked=> $access_method eq 'direct' ? 1 : 0,
             -value=>'ON',
             -label=>'Direct database access',
         ),
         submit,
         end_form,
         end_html;
         exit(0);
}


my ($chromosome,$start,$end,$failure,$xmltype);
my $t_chromosome = param('chromosome');
my $t_start      = param('start');
my $t_end        = param('end');
my $t_selection  = param('selection');
my $t_xmltype    = param('xml_type');
my $t_direct     = param('direct');

if ($t_chromosome and $t_chromosome =~ /^(\d+)$/) {
    $chromosome = $1; 
}
if ($t_start      and $t_start      =~ /^(\d+)$/) {
    $start      = $1;
    if ($start < 1) {
        $start = 1;
    }
}
if ($t_end        and $t_end        =~ /^(\d+)$/) {
    $end        = $1;
}
if ($t_selection  and $t_selection  =~ /^(\w+):(\d+)\.\.(\d+)$/) {
    $chromosome = $1;
    $start      = $2;
    $end        = $3;
    if ($start < 1) {
        $start = 1;
    }
}
if ($t_xmltype and ($t_xmltype =~ /^chado$/ or $t_xmltype =~ /^game$/)) {
    $xmltype = $t_xmltype;
}
 
unless ($chromosome && $start && $end) {
    $failure = p("The parameters used for this script weren't understood; here's what I got:")
              .start_ul  . li("chromosome = $chromosome")
                         . li("start = $start")
                         . li("end = $end")
              .end_ul;
    handle_error($failure);
}

my $filename = "$chromosome:$start\-$end";

if ($t_xmltype and !$t_direct) {
  my $jscript = <<END;
function visibility(id1,id2) {
  var visible = YAHOO.util.Dom.getStyle (id1,'display') == 'none' ? ['inline','none'] : ['none','inline'];
  YAHOO.util.Dom.setStyle(id1,'display',visible[0]);
  YAHOO.util.Dom.setStyle(id2,'display',visible[1]); 
}
END

  my $style = <<END;
.showhide { position:relative; top:0px;}
.output { border:1px solid blue; width:85%; overflow:auto; }
.control { cursor:pointer }
END

  print header,
      start_html(-title=>"Download $filename",
                 -style=>[{src=>'/gbrowse/gbrowse.css'},
                          {code=>$style}],
                 -script=>[{-language=>'JAVASCRIPT',
                            -src=>"/gbrowse/js/yahoo-dom-event.js"},
                           {-code=>$jscript }] 
      ),
      h1("Getting a game file for $filename"),
      p('This may take a while...'),
      start_div(-class=>"output");

  my $javacmd = "$apollo -w $working_dir/$filename.xml -o $xmltype -l $filename -i chadoDB";

  print start_div({-id=>'invisible',
                 -class=>'showhide',
                 -style=>"display:none"}),
      start_span({-onclick=>"visibility('visible','invisible')"}),
      "[-] Hide Apollo output<br>",
      end_span,
      start_pre;
  system($javacmd);
  print end_pre,end_div();
  print start_div({-id=>'visible',
                 -class=>'showhide',}),
      start_span({-onclick=>"visibility('visible','invisible')"}),
      "[+] Show Apollo output<br>",
      end_span(),end_div(),end_div(),"<br clear=all>";

  print start_span(-class=>'position:relative');

  my $error_flag;
  if (-e "$working_dir/$filename.xml") {
    print p("The file $filename.xml has been created");
  }
  else {
    print h3("The file $filename.xml was not created; check the Apollo output for errors");
    $error_flag = 1;
  }

  open OUT, ">$working_dir/$filename.jnlp" 
   or handle_error(
        p("I couldn't open file $working_dir/$filename.jnlp for writing: $!"));

  print OUT write_jnlp();

  close OUT;

  if (-e "$working_dir/$filename.jnlp") {
    print p("Created the file $filename.jnlp.");
  }
  else {
    print h3("The file $filename.jnlp was not created; I don't know why");
    $error_flag = 1;
  }
   
  if (!$error_flag) { 
    print  p("Click on this link: "
      . a({href=>"$hostname$web_path/$filename.jnlp"},
          "$filename.jnlp")
      ." to start Apollo and download the file. Click on the "
      . a({href=>"$hostname/cgi-bin/upload_game.pl"},
          "Upload game-xml")
      ." link to upload your annotations."),
  }

print  end_span, end_html; 
} #end if to give html page to click on xml based jnlp link
elsif ($t_direct) {
  my $file_contents = write_jnlp($t_direct);

  print header(-type => 'application/x-java-jnlp-file'),
        $file_contents ;
}


exit(0);

sub handle_error {
    my $failure = shift;
    print h1("There was a problem"),$failure,end_html;
    exit(0);
}

sub write_jnlp {
    my $direct = shift;

    my $file =<<END
<?xml version="1.0" encoding="UTF-8"?>
<jnlp codebase="$hostname/apollo/webstart" 
href="$hostname$web_path/$filename.jnlp" spec="1.0+">
  <information>
    <title>Apollo</title>
    <vendor>$vendor</vendor>
    <description>$apollo_desc</description>
    <!-- location of your project's web page -->
    <homepage href="$hostname"/>
    <!-- if you want to have WebStart add a specific image as your icon,
            point to the location of the image -->
    <icon href="images/head-of-apollo.gif" kind="shortcut"/>
    <!-- allow users to launch Apollo when offline -->
    <offline-allowed/>
  </information>
  <!-- request all permissions - might be needed since Apollo might write to local
          file system -->
  <security>
    <all-permissions/>
  </security>
  <!-- we require at least Java 1.5, set to start using 64m and up to 500m -->
  <resources>
    <j2se initial-heap-size="64m" max-heap-size="500m" version="1.5+"/>
    <jar href="jars/apollo.jar"/>
    <jar href="jars/bbop.jar"/>
    <jar href="jars/biojava.jar"/>
    <jar href="jars/crimson.jar"/>
    <jar href="jars/ecp1_0beta.jar"/>
    <jar href="jars/ensj-compatibility-19.0.jar"/>
    <jar href="jars/ensj.jar"/>
    <jar href="jars/jakarta-oro-2.0.6.jar"/>
    <jar href="jars/jaxp.jar"/>
    <jar href="jars/jnlp.jar"/>
    <jar href="jars/junit.jar"/>
    <jar href="jars/log4j-1.2.14.jar"/>
    <jar href="jars/macify-1.1.jar"/>
    <jar href="jars/mysql-connector-java-3.1.8-bin.jar"/>
    <jar href="jars/obo.jar"/>
    <jar href="jars/oboedit.jar"/>
    <jar href="jars/org.mortbay.jetty.jar"/>
    <jar href="jars/patbinfree153.jar"/>
    <jar href="jars/pg74.213.jdbc3.jar"/>
    <jar href="jars/psgr2.jar"/>
    <jar href="jars/servlet-tomcat.jar"/>
    <jar href="jars/te-common.jar"/>
    <jar href="jars/xerces.jar"/>
  </resources>
  <!-- where the main method is locate - don't change this -->
  <application-desc main-class="apollo.main.Apollo">
    <!-- we can add arguments when launching Apollo - this particular one allows us to
              load chromosome 1, from 11650000 to 11685000 - great way to have Apollo load
              specific regions -->

END
;

  if ($direct) {
    $file .=<<A_EXTRA
    <argument>-i</argument>
    <argument>chadodb</argument>
    <argument>-l</argument>
    <argument>$filename</argument>
A_EXTRA
; 
  }
  else {
    $file .=<<B_EXTRA
    <argument>-i</argument>
    <argument>game</argument>
    <argument>-f</argument>
    <argument>$hostname$web_path/$filename.xml</argument>
B_EXTRA
;
  }

  $file .=<<FINAL
  </application-desc>
</jnlp>
FINAL
;

  return $file;
}

=pod

=head1 AUTHOR

Scott Cain, cain.cshl@gmail.com

=head1 COPYRIGHT

2008, All rights reserved

=cut
