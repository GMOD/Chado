use strict;
use lib 'lib';
use Chado::Builder;
use Data::Dumper;

my $VERSION = 0.01;

my $conf = shift;

my $m = Chado::Builder->new(dist_name => '', dist_version => $VERSION, load_conf => $conf);
#$m->conf($conf);


#print Dumper $m->properties;

print "initializing load scripts...\n";
#$m->dispatch('tokenize');

#$m->dispatch('ontologies');

$m->create_build_script;
#$m->dispatch('build');
