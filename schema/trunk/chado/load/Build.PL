use strict;
use lib 'lib';
use Chado::Builder;

my $VERSION = 0.01;

my $m = Chado::Builder->new(dist_name => '', dist_version => $VERSION);
$m->conf('load/etc/load.conf');
$m->dispatch('tokenize');

if($m->y_n("would you like to load ontologies from ___?","y")){
  $m->dispatch('ontologies');
}


#$m->create_build_script;
#$m->dispatch('build');
