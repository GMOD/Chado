#!/usr/bin/perl
use warnings;
use strict;

use CGI qw/:standard start_div start_span start_pre start_ul/;

my $working_dir = "/var/www/apollo/tmp/";
my $apollo      = "/home/ubuntu/apollo/bin/apollo.headless";
my $hostname    = url(-base=>1);
$ENV{PATH}      = '/usr/local/java/bin:/usr/bin:/bin';

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
      ." to start Apollo and download the file"),
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
<jnlp
spec="1.0+"
codebase="$hostname/apollo"
href="$hostname/apollo/tmp/$filename.jnlp">
<information>
<title>Apollo</title>
<vendor>Stein Lab</vendor>
<description>Apollo, v. 1.6.6 dev (webstart)</description>
<icon href="apollosplash.gerry.jpg" kind="splash"/> 
      <!-- A web page containing more information about the
      application.  This URL will be displayed in
      the JAWS Application Manager -->
<homepage href="http://www.fruitfly.org/annot/apollo/" ></homepage>
  <!-- Declares that the application can run without
         access to the server it was downloaded from -->
<offline-allowed />
</information>
<security>
      <!-- Request that the application be given full
           access to the local (executing) machine,
           as if it were a regular Java application.
           Requires that all JAR files be signed
           by a trusted party -->
<all-permissions />
</security>
<resources>
  <!-- Specify the versions of the Java Runtime Environment
         (JRE) that are supported by the application.
         Multiple entries of this kind are allowed, in which
         case they are considered to be in order of preference -->
<j2se version="1.4+ 1.4.2 1.5" initial-heap-size="64m"
max-heap-size="500m" />
<jar href="jars/apollo.signed.jar" />
<jar href="jars/biojava.signed.jar" />
<jar href="jars/crimson.signed.jar" />
<jar href="jars/ecp1_0beta.signed.jar" />
<jar href="jars/ensj-compatibility-19.0.signed.jar" />
<jar href="jars/ensj.signed.jar" />
<jar href="jars/jakarta-oro-2.0.6.signed.jar" />
<jar href="jars/jaxp.signed.jar" />
<jar href="jars/jnlp.signed.jar" />
<jar href="jars/junit.signed.jar" />
<jar href="jars/log4j-1.2.14.signed.jar" />
<jar href="jars/mysql-connector-java-3.1.8-bin.signed.jar" />
<jar href="jars/org.mortbay.jetty.signed.jar" />
<jar href="jars/patbinfree153.signed.jar" />
<jar href="jars/pg74.213.jdbc3.signed.jar" />
<jar href="jars/psgr2.signed.jar" />
<jar href="jars/servlet-tomcat.signed.jar" />
<jar href="jars/te-common.signed.jar" />
<jar href="jars/xerces.signed.jar" />
</resources>
<application-desc main-class="apollo.main.Apollo">
<!-- Tell Apollo where to get its data from, and what format the data is
in -->
<argument>-i</argument>
<argument>game</argument>
<argument>-f</argument>
<argument>$hostname/apollo/tmp/$filename.xml</argument>
</application-desc>
</jnlp>
END
;
}
