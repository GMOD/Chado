#!/usr/bin/perl -T
use warnings;
use strict;

use CGI qw/:standard/;

my $working_dir = "/var/www/apollo/tmp/";
my $apollo      = "/home/ubuntu/apollo/bin/apollo.headless";
my $hostname    = "gmod.genetics.northwestern.edu";
$ENV{PATH}      = '/usr/local/java/bin:/usr/bin:/bin';

unless(param()) { #print the starting page

    print header,
          start_html(-title=>'Script for generating game on the fly from apollo'),
          h1('Request a GAME-XML file from the database'),
          start_form(-method=>'GET'),
          'Chromosome:',
          popup_menu(-name=>'chromosome',
                     -values=>[3]),p,
          'start:',
          textfield('start'),p,
          'end:',
          textfield('end'),p,
          submit,
          end_form,
          end_html;

}

if (param()) {

    my ($chromosome,$start,$end);
    my $t_chromosome = param('chromosome');
    my $t_start      = param('start');
    my $t_end        = param('end');

    if ($t_chromosome =~ /^(\d+)$/) {
        $chromosome = $1; 
    }
    if ($t_start      =~ /^(\d+)$/) {
        $start      = $1;
    }
    if ($t_end        =~ /^(\d+)$/) {
        $end        = $1;
    }
    
    die unless ($chromosome && $start && $end);

    my $filename = "$chromosome:$start\-$end";

    print header,
          start_html(-title=>"Download $filename",
                     -style=>{src=>'/gbrowse/gbrowse.css'},
                     -script=>{-language=>'JAVASCRIPT',
                               -src=>'/gbrowse/js/yahoo-dom-event.js'},),
,
          h1("Getting a game file for $filename"),
          p('This may take a while...');

    my $javacmd = "$apollo -w $working_dir$filename.xml -o game -l $filename -i chadoDB";

    print a({-href=>'',-onClick=>togDisplay('apollo_out')},"Show Apollo output"),start_div(-id=>'apollo_out');
    system($javacmd) == 0 or die;
    print end_div;

    print p("The file $filename.xml has been created");

    open OUT, ">$working_dir$filename.jnlp" 
       or die "couldn't open file $working_dir$filename.jnlp for writing: $!\n";

    print OUT write_jnlp($hostname, $filename);

    close OUT;

    print p("Created the file $filename.jnlp."),
          p("Click on this link: "
          . a({href=>"http://$hostname/apollo/tmp/$filename.jnlp"},
              "$filename.jnlp")
          ." to start Apollo and download the file"),
          end_html; 
}


sub write_jnlp {
    my $hostname = shift;
    my $filename = shift;

    return <<END;
<?xml version="1.0" encoding="UTF-8"?>
<jnlp
spec="1.0+"
codebase="http://$hostname/apollo"
href="tmp/$filename.jnlp">
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
<argument>http://$hostname/apollo/tmp/$filename.xml</argument>
</application-desc>
</jnlp>
END
;
}
