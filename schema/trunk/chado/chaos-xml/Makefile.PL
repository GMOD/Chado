# $id$

use ExtUtils::MakeMaker;
require 5.004;
#use Config;

if (system("which xsltproc > /dev/null")) {
    print <<MSG;

WARNING: ** You do not have xsltproc **

This tool is not required for the core of chaos-xml perl lib, but it
is required for certain kinds of format conversion, such as
Chaos<=>ChadoXML

xsltproc is available as part of libxslt. See http://xmlsoft.org/XSLT/
for details

MSG
      
}

$p = "XML::Parser::PerlSAX";
if (!eval "require $p") {
    print <<MSG;

WARNING: ** You do not have XML::Parser::PerlSAX installed **

This tool is not required for the core of chaos-xml perl lib, but it
is required for parsing chaos-xml documents. It is not required for
generating chaos from genbank

MSG
      
}

WriteMakefile(
	      'NAME'         => "Bio-Chaos",
	      'DISTNAME'         => "Bio-Chaos",
	      'ABSTRACT'     => 'Chaos biotools',
	      'AUTHOR'       => 'Chris Mungall <cjm AT fruitfly DOT org>',
	      'VERSION_FROM' => "lib/Bio/Chaos/Root.pm",
	      'PREREQ_PM'    => {
				 'Data::Stag' => '0.07',
				 'Bio::Seq'         => '1.5',
                                 'Graph' => 0,
				},
	      'EXE_FILES'    => [
                                 qw(
                                    bin/cx-chadoxml2chaos.pl
                                    bin/cx-chaos-report.pl
                                    bin/cx-download-enscore.pl
                                    bin/cx-enscore2chaos.pl
                                    bin/cx-genbank2chaos.pl
                                   )
				],
	      'dist'         => { 
				 'SUFFIX'       => ".gz",
				 'DIST_DEFAULT' => 'all tardist',
				 'COMPRESS'     => "gzip -9f" 
				},
	      clean => {
			FILES => 'Bio-Chaos-$(VERSION).tar.gz',
		       },
	     );

