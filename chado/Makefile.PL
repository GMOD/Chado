use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %O;

$O{GMOD_HOME}      = $ENV{GMOD_HOME} || '/usr/local/gmod';
$O{PACKAGE_HOME}   = $O{GMOD_HOME}.'/lib/schema';
$O{COREDEF}        = 'modules/idb-full.modules';
$O{EXTDEF}         = 'modules/extension.modules';

open CORE, $O{COREDEF} or die "unable to open $O{COREDEF}: $!\n";
my @sqlfiles;
while (<CORE>) {
  chomp;
  push @sqlfiles, 'modules/'.$_;
}
close CORE;

# get available extensions to core and ask if any are to be used.
print "Available extensions to the core schema:\n";
open EXT, $O{EXTDEF} or die "unable to open $O{EXTDEF}: $!\n";
my @extfiles = ( 0 );
my $i = 0;
while (<EXT>) {
  $i++;
  print "[$i] $_";
  chomp;
  push @extfiles, 'modules/'.$_;
}
close EXT;

my $extstr = prompt("What extensions to the core schema do you need (comma delimited)?","0");

if ($extstr) {
  my @extindex = split /,/, $extstr;
  foreach my $index (@extindex) {
    push @sqlfiles, $extfiles[$index];
  }
}

my $sqlout = 'modules/complete.sql';
open OUT, ">$sqlout" or die "couldn't open $sqlout: $!\n";
foreach my $file (@sqlfiles) {
  open IN, $file or die "couldn't open $file: $!\n";
  while (<IN>) {
    print OUT;
  }
  close IN;
}
close OUT;


WriteMakefile(
    'NAME'		=> 'chado',
    'PREREQ_PM'		=> { #SQL::Translator => 0.2,
                             #DBI             => 0,
                             #DBD::Pg         => 0
                            }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);

sub MY::postamble {
  qq{
test_load ::
	\$(SHELL) install/test_load.sh
  };  
}
