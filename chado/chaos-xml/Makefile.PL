# $id$

use ExtUtils::MakeMaker;
require 5.004;
#use Config;

WriteMakefile(
	      'NAME'         => "Bio-Chaos",
	      'DISTNAME'         => "Bio-Chaos",
	      'ABSTRACT'     => 'Chaos biotools',
	      'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
	      #'VERSION_FROM' => "Bio/Chaos.pm",
	      'PREREQ_PM'    => {
				 'Data::Stag' => 0,
				 'Bio::Seq'         => 0,
                                 'Graph' => 0,
				},
	      'EXE_FILES'    => [
                                 qw(
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

