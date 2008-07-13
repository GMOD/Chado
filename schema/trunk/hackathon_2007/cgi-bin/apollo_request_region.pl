#!/usr/bin/perl
use warnings;
use strict;

use CGI qw/:standard start_div start_span start_pre start_ul/;

my $working_dir = "/var/www/html/apollo/tmp/";
my $apollo      = "/home/gmod/downloads/apollo/bin/apollo.headless";
my $hostname    = url(-base=>1);
$ENV{PATH}      = '/usr/java/jdk1.5.0_14/bin:/usr/bin:/bin';

unless(param()) { #print the starting page

    print header,
         start_html(-title=>'Script for generating game on the fly from apollo',
                    -style=>{src=>'/gbrowse/gbrowse.css'},),
         h1('Request a GAME-XML file from the database'),
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

if ($t_chromosome and $t_chromosome =~ /^(\d+)$/) {
    $chromosome = $1; 
}
if ($t_start      and $t_start      =~ /^(\d+)$/) {
    $start      = $1;
}
if ($t_end        and $t_end        =~ /^(\d+)$/) {
    $end        = $1;
}
if ($t_selection  and $t_selection  =~ /^(\w+):(\d+)\.\.(\d+)$/) {
    $chromosome = $1;
    $start      = $2;
    $end        = $3;
}
if ($t_xmltype =~ /^chado$/ or $t_xmltype =~ /^game$/) {
    $xmltype = $t_xmltype;
}
else {
    $xmltype = 'game';
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

my $javacmd = "$apollo -w $working_dir$filename.xml -o $xmltype -l $filename -i chadoDB";

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
if (-e "$working_dir$filename.xml") {
    print p("The file $filename.xml has been created");
}
else {
    print h3("The file $filename.xml was not created; check the Apollo output for errors");
    $error_flag = 1;
}

open OUT, ">$working_dir$filename.jnlp" 
   or handle_error(
        p("I couldn't open file $working_dir$filename.jnlp for writing: $!"));

print OUT write_jnlp($hostname, $filename);

close OUT;

if (-e "$working_dir$filename.jnlp") {
    print p("Created the file $filename.jnlp.");
}
else {
    print h3("The file $filename.jnlp was not created; I don't know why");
    $error_flag = 1;
}
   
if (!$error_flag) { 
    print  p("Click on this link: "
      . a({href=>"$hostname/apollo/tmp/$filename.jnlp"},
          "$filename.jnlp")
      ." to start Apollo and download the file. Click on the "
      . a({href=>"$hostname/cgi-bin/upload_game.pl"},
          "Upload game-xml")
      ." link to upload your annotations."),
}

print  end_span, end_html; 

exit(0);

sub handle_error {
    my $failure = shift;
    print h1("There was a problem"),$failure,end_html;
    exit(0);
}

sub write_jnlp {
    my $hostname = shift;
    my $filename = shift;

    return <<END;
<?xml version="1.0" encoding="UTF-8"?>
<jnlp codebase="$hostname/apollo/webstart" 
href="$hostname/apollo/tmp/$filename.jnlp" spec="1.0+">
  <information>
    <title>Apollo</title>
    <vendor>GMOD Summer School 2008</vendor>
    <description>Apollo Webstart</description>
    <!-- location of your project's web page -->
    <homepage href="http://localhost/apollo"/>
    <!-- if you want to have WebStart add a specific image as your icon,
            point to the location of the image -->
    <icon href="images/head-of-apollo.gif" kind="shortcut"/>
    <!-- create a shortcut on your desktop -->
    <shortcut online="true">
      <desktop/>
    </shortcut>
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
    <argument>-i</argument>
    <argument>game</argument>
    <argument>-f</argument>
    <argument>$hostname/apollo/tmp/$filename.xml</argument>
  </application-desc>
</jnlp>
END
;
}
